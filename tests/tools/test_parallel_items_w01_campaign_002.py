"""W01 CAMP_002 / ITER_01: auditoría de fuentes y matriz; NO ejecuta combate.

Este validador solo permite certificar PREPARADO_PENDIENTE_CI.
El runner nativo/Godot y los recibos se incorporarán en ITER_02/03.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_002.json"
VARIANTS = ("active", "none", "reserve")
ITEM_HOOKS = {
    "ability_shield": ("abilityshield", "onSetAbility"),
    "absorb_bulb": ("absorbbulb", "onDamagingHit"),
    "adrenaline_orb": ("adrenalineorb", "onAfterBoost"),
}
REFS = {
    "tools/item_audit/held_effect_sweep_v2.cjs": "c9ba4d7bcddad6ae69f085f4b69983461ad05219",
    "tools/item_audit/held_effect_sweep_v3.cjs": "fd5d9d0b1eecf8b84f14e606631df93b40728586",
    "docs/current/ITEM_INVENTORY.csv": "2aaf18643bb2b071226118a1ad556cffca4707dd",
    "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv": "8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b",
}
# Bloqueo estricto: no se aceptan IDs, disparadores ni semillas nuevas por accidente.
# Tupla: objeto, efecto, habilidad propia, rival, habilidad rival, movimiento rival,
# disparador, condición, activación, consumo, efecto observado esperado, semillas.
CASES = {
    "shield_gastro_acid": ("ability_shield", "ability_suppression", "synchronize", "mew", "", "gastro_acid",
                            "ability_suppression_attempt", "gastro_acid_hit", True, False, "ability_not_suppressed", (19, 23)),
    "shield_no_suppression": ("ability_shield", "ability_suppression", "synchronize", "mew", "", "amnesia",
                               "no_ability_suppression", "no_gastro_acid", False, False, "none", (23,)),
    "bulb_water_hit": ("absorb_bulb", "water_hit_stat_boost", "", "mew", "", "water_gun",
                       "damaging_water_hit", "water_hit", True, True, "spa_plus_one", (19, 23)),
    "bulb_nonwater_hit": ("absorb_bulb", "water_hit_stat_boost", "", "mew", "", "tackle",
                          "damaging_nonwater_hit", "normal_hit", False, False, "none", (23,)),
    "bulb_no_hit": ("absorb_bulb", "water_hit_stat_boost", "", "mew", "", "amnesia",
                    "no_attack_damage", "status_only", False, False, "none", (23,)),
    "orb_intimidate": ("adrenaline_orb", "intimidate_speed_boost", "", "gyarados", "intimidate", "amnesia",
                       "opposing_intimidate", "intimidate_entry", True, True, "speed_plus_one", (19, 23)),
    "orb_no_intimidate": ("adrenaline_orb", "intimidate_speed_boost", "", "mew", "", "amnesia",
                          "opponent_no_intimidate", "no_intimidate", False, False, "none", (23,)),
}
CASE_FIELDS = {
    "stage", "id", "item_id", "mechanic", "actor_species", "actor_ability", "foe_species",
    "foe_ability", "own_move", "foe_move", "trigger", "condition", "expected", "seeds"
}
EXPECT_FIELDS = {"triggered", "consumed", "effect"}
SOURCE_FIELDS = {"path", "blob"}


def ensure(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\x00" + data).hexdigest()


def load_json(path: Path) -> dict:
    obj = json.loads(path.read_text(encoding="utf-8-sig"))
    ensure(type(obj) is dict, f"Objeto JSON obligatorio: {path}")
    return obj


def validate_fixture(f: dict) -> tuple[int, int, int]:
    ensure(set(f) == {"schema_version", "campaign", "worker", "stage", "format",
                      "execution_state", "variants", "sources", "cases"},
           "Cabecera de contrato alterada")
    ensure(f["schema_version"] == 1 and f["campaign"] == "CAMP_002"
           and f["worker"] == "W01" and f["stage"] == "01"
           and f["format"] == "gen9calvounifiedv1"
           and f["execution_state"] == "EXPECTED_ONLY_NO_RUNTIME",
           "No declarar resultados funcionales en ITER_01")
    ensure(f["variants"] == list(VARIANTS), "Faltan controles activo/ninguno/reserva")
    ensure(type(f["sources"]) is list and type(f["cases"]) is list,
           "Fuentes o casos inválidos")
    seen_sources = set()
    for src in f["sources"]:
        ensure(type(src) is dict and set(src) == SOURCE_FIELDS, "Fuente sin contrato")
        path = src["path"]
        ensure(type(path) is str and path in REFS and path not in seen_sources
               and src["blob"] == REFS[path], "SHA o fuente histórica desconocidos")
        seen_sources.add(path)
    ensure(seen_sources == set(REFS), "Faltan fuentes obligatorias")
    found = set()
    seen_pairs = set()
    per_item = {item: 0 for item in ITEM_HOOKS}
    for case in f["cases"]:
        ensure(type(case) is dict and set(case) == CASE_FIELDS,
               "Campos extra o ausentes en un caso")
        cid = case["id"]
        ensure(type(cid) is str and cid in CASES and cid not in found,
               f"Escenario no permitido/repetido: {cid}")
        found.add(cid)
        expected = CASES[cid]
        actual = (case["item_id"], case["mechanic"], case["actor_ability"],
                  case["foe_species"], case["foe_ability"], case["foe_move"],
                  case["trigger"], case["condition"])
        ensure(case["stage"] == "01" and case["actor_species"] == "mew"
               and case["own_move"] == "reflect" and actual == expected[:8],
               f"Especies, habilidades, moves o desencadenantes cambiados: {cid}")
        ensure(type(case["seeds"]) is list and tuple(case["seeds"]) == expected[11]
               and all(type(n) is int and 0 <= n <= 65535 for n in case["seeds"]),
               f"Semillas modificadas: {cid}")
        obs = case["expected"]
        ensure(type(obs) is dict and set(obs) == set(VARIANTS),
               f"Faltan controles: {cid}")
        for mode in VARIANTS:
            result = obs[mode]
            ensure(type(result) is dict and set(result) == EXPECT_FIELDS,
                   f"Expectativa inválida: {cid}/{mode}")
            trig, consume, effect = (expected[8:11] if mode == "active"
                                    else (False, False, "none"))
            ensure(type(result["triggered"]) is bool and type(result["consumed"]) is bool
                   and result == {"triggered": trig, "consumed": consume, "effect": effect},
                   f"Expectativa causal incorrecta: {cid}/{mode}")
        for seed in case["seeds"]:
            ensure((cid, seed) not in seen_pairs, f"Par duplicado: {cid}/{seed}")
            seen_pairs.add((cid, seed))
        per_item[case["item_id"]] += 1
    ensure(found == set(CASES), "Faltan escenarios obligatorios")
    ensure(all(v >= 2 for v in per_item.values()), "Un objeto carece de control negativo")
    ensure(len(seen_pairs) == 10, "Número de pares caso/semilla alterado")
    return (len(found), len(seen_pairs), len(seen_pairs) * len(VARIANTS))


def validate_sources(f: dict) -> None:
    for row in f["sources"]:
        p = ROOT / row["path"]
        ensure(p.is_file() and git_blob_sha(p) == row["blob"],
               f"Fuente ausente o blob diferente: {row['path']}")
    scope = (ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv").read_text(encoding="utf-8-sig")
    inventory = (ROOT / "docs/current/ITEM_INVENTORY.csv").read_text(encoding="utf-8-sig")
    for item, (native, hook) in ITEM_HOOKS.items():
        lines = [line.strip().split(",") for line in scope.splitlines() if line.startswith(item + ",")]
        ensure(len(lines) == 1 and lines[0][2] == "HELD_COMBAT_CANDIDATE"
               and lines[0][4] == "SELECCIONADO",
               f"Objeto no seleccionado en catálogo: {item}")
        candidates = [line.strip().split(",") for line in inventory.splitlines()
                      if line.startswith(item + ",")]
        ensure(len(candidates) == 1 and candidates[0][8] == native
               and hook in candidates[0][9].split("|"),
               f"Hook del inventario distinto: {item}")
    v2 = (ROOT / "tools/item_audit/held_effect_sweep_v2.cjs").read_text(encoding="utf-8")
    v3 = (ROOT / "tools/item_audit/held_effect_sweep_v3.cjs").read_text(encoding="utf-8")
    historical = (
        ("V2 absorb_bulb agua", "'absorb_bulb','water_gun','spa'" in v2),
        ("V2 estadística +1", "assert.equal(own(a).boosts[stat],1)" in v2),
        ("V3 ability_shield supresión", "add('ability_shield','ability_suppression'" in v3),
        ("V3 gastro_acid", "foeMoves:['gastro_acid']" in v3),
        ("V3 adrenalina Intimidate", "add('adrenaline_orb','intimidate_trigger'" in v3),
        ("V3 adrenalina sin Intimidate", "add('adrenaline_orb','no_intimidate'" in v3),
    )
    for label, ok in historical:
        ensure(ok, "Evidencia nativa histórica desaparecida: " + label)


def self_test(f: dict) -> int:
    mutations = (
        lambda x: x["cases"].pop(),
        lambda x: x["cases"][0].update({"item_id": "focus_sash"}),
        lambda x: x["cases"][2]["expected"]["active"].update({"consumed": False}),
        lambda x: x["cases"][5].update({"seeds": [19, 19]}),
        lambda x: x["sources"][0].update({"blob": "0"*40}),
        lambda x: x.update({"variants": ["active", "none"]}),
    )
    rejected = 0
    for fn in mutations:
        broken = copy.deepcopy(f)
        fn(broken)
        try:
            validate_fixture(broken)
        except ValueError:
            rejected += 1
        else:
            raise AssertionError("El contrato aceptó una alteración deliberada")
    ensure(rejected == len(mutations), "Prueba negativa incompleta")
    return rejected


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contracts", action="store_true",
                        help="Solo matriz + referencias reales, NO Godot")
    parser.add_argument("--self-test", action="store_true",
                        help="Rechazar seis mutaciones deliberadas")
    args = parser.parse_args()
    try:
        fixture = load_json(FIXTURE)
        cases, runs, variants = validate_fixture(fixture)
        validate_sources(fixture)
        print(f"W01_CAMP002_ITER01_CONTRACT_PASS cases={cases} runs={runs} variants={variants} sources=4")
        if args.self_test:
            print(f"W01_CAMP002_ITER01_NEGATIVE_PASS rejected={self_test(fixture)}")
        if not args.contracts and not args.self_test:
            print("PREPARADO_PENDIENTE_CI; la ejecución nativa corresponde a ITER_02")
        return 0
    except (OSError, ValueError, KeyError, IndexError, TypeError, AssertionError) as exc:
        print(f"W01_CAMP002_ITER01_CONTRACT_FAIL {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
