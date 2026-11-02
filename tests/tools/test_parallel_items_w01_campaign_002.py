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



def validate_native_report(path: Path, fixture: dict) -> tuple[int, int]:
    """Exige Godot real + snapshots nativos + evidencias exactas y SHA-256."""
    ensure(path.is_file(), f"SIN_EJECUTAR: no existe evidencia nativa {path}")
    report = load_json(path)
    fields = {"schema_version", "campaign", "worker", "execution_mode",
              "descriptor_sha256", "status", "checks", "errors", "rows", "limits"}
    ensure(set(report) == fields, "Forma de reporte Godot desconocida")
    ensure(report["schema_version"] == 1 and report["campaign"] == "CAMP_002"
           and report["worker"] == "W01" and report["execution_mode"] == "godot_4_7_native",
           "Reporte de familia, worker o motor incorrecto")
    ensure(report["descriptor_sha256"] == hashlib.sha256(FIXTURE.read_bytes()).hexdigest(),
           "Hash SHA-256 del descriptor no coincide")
    ensure(report["status"] == "PASS" and report["errors"] == [],
           "Godot no informo PASS sin errores")
    ensure(type(report["checks"]) is int and report["checks"] >= 150,
           "Pocas aserciones ejecutadas")
    ensure(type(report["limits"]) is list and len(report["limits"]) >= 3,
           "Limitaciones de verificación ausentes")
    ensure(type(report["rows"]) is list, "Faltan filas del runner")
    allowed = {(r["id"], seed) for r in fixture["cases"] for seed in r["seeds"]}
    spec_by_id = {r["id"]: r for r in fixture["cases"]}
    seen = set()
    sample_fields = {"valid", "start", "after", "owner_unchanged", "physical_units",
                     "evidence", "sha256"}
    frame_fields = {"valid", "hp", "spe", "spa", "atk", "ability", "gastro_acid",
                    "native_item", "native_bench_item", "active_has_item",
                    "reserve_has_item", "consumed", "reserve_consumed", "log_markers"}

    for row in report["rows"]:
        ensure(type(row) is dict and set(row) == {"id", "item_id", "seed", "checks",
                   "status", "observed"}, "Fila del runner incompatible")
        key = (row["id"], row["seed"])
        ensure(key in allowed and key not in seen, "Par caso-semilla ajeno o repetido")
        seen.add(key)
        spec = spec_by_id[row["id"]]
        ensure(row["item_id"] == spec["item_id"] and row["status"] == "PASS"
               and type(row["checks"]) is int and row["checks"] >= 15,
               f"No PASS o fila fuera de contrato: {key}")
        observations = row["observed"]
        ensure(type(observations) is dict and set(observations) == set(VARIANTS),
               f"Faltan variantes: {key}")
        for mode in VARIANTS:
            obs = observations[mode]
            ensure(type(obs) is dict and set(obs) == sample_fields and obs["valid"] is True
                   and obs["owner_unchanged"] is True, f"Observación invalida: {key}/{mode}")
            ensure(type(obs["physical_units"]) is int, "Cantidad física no entera")
            start, after = obs["start"], obs["after"]
            ensure(type(start) is dict and type(after) is dict
                   and set(start) == frame_fields and set(after) == frame_fields,
                   f"Fotograma nativo incompleto: {key}/{mode}")
            ensure(start["valid"] is True and after["valid"] is True,
                   f"No existen filas nativas: {key}/{mode}")
            ensure(type(start["log_markers"]) is list and type(after["log_markers"]) is list,
                   "No se incluyeron eventos nativos")
            ensure(type(after["spe"]) is int and type(after["spa"]) is int
                   and type(after["hp"]) is int, "Valores nativos no enteros")
            consumed = spec["expected"][mode]["consumed"]
            ensure(after["consumed"] is consumed
                   and after["reserve_consumed"] is False
                   and start["active_has_item"] is (mode == "active")
                   and start["reserve_has_item"] is (mode == "reserve")
                   and after["reserve_has_item"] is (mode == "reserve")
                   and obs["physical_units"] == (1 if consumed else 2),
                   f"Propiedad/consumo/stock alterados: {key}/{mode}")
            name = f"{row['id']}_{row['seed']}_{mode}.json"
            ensure(obs["evidence"] == name and type(obs["sha256"]) is str
                   and len(obs["sha256"]) == 64, "Recibo declarado incorrecto")
            file = path.parent / name
            ensure(file.is_file() and hashlib.sha256(file.read_bytes()).hexdigest() == obs["sha256"],
                   f"Evidencia ausente o hash modificado: {name}")
            raw = load_json(file)
            ensure(raw.get("id") == row["id"] and raw.get("item_id") == row["item_id"]
                   and raw.get("seed") == row["seed"] and raw.get("mode") == mode
                   and raw.get("start") == start and raw.get("after") == after
                   and raw.get("owner_unchanged") is True
                   and raw.get("physical_units") == obs["physical_units"]
                   and type(raw.get("initial")) is dict and type(raw.get("final")) is dict
                   and bool(raw["initial"]) and bool(raw["final"]),
                   "Recibo nativo sin snapshots o divergente del informe")

        a = observations["active"]
        n = observations["none"]
        r = observations["reserve"]
        if spec["item_id"] == "ability_shield":
            ensure(a["after"]["ability"] == "synchronize"
                   and n["after"]["ability"] == "synchronize",
                   "Habilidad base no conservada")
            if spec["trigger"] == "ability_suppression_attempt":
                passed = (not a["after"]["gastro_acid"]
                          and n["after"]["gastro_acid"] and r["after"]["gastro_acid"])
            else:
                passed = not any(x["after"]["gastro_acid"] for x in (a, n, r))
        elif spec["item_id"] == "absorb_bulb":
            if spec["trigger"] == "damaging_water_hit":
                passed = (a["after"]["spa"] == 1 and n["after"]["spa"] == r["after"]["spa"] == 0
                          and a["after"]["hp"] < a["start"]["hp"]
                          and n["after"]["hp"] < n["start"]["hp"])
            else:
                passed = all(x["after"]["spa"] == 0 for x in (a, n, r))
        elif spec["item_id"] == "adrenaline_orb":
            if spec["trigger"] == "opposing_intimidate":
                passed = (a["start"]["spe"] == 1
                          and n["start"]["spe"] == r["start"]["spe"] == 0
                          and a["after"]["spe"] == 1
                          and n["after"]["spe"] == r["after"]["spe"] == 0)
            else:
                passed = all(x["after"]["spe"] == 0 for x in (a, n, r))
        else:
            raise ValueError("Objeto ajeno al lote")
        ensure(passed, f"Observación causal nativa incumplida: {key}")
    ensure(seen == allowed and len(seen) == 10, "Faltan ejecuciones reales")
    return len(seen), len(seen) * len(VARIANTS)

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contracts", action="store_true",
                        help="Solo matriz + referencias reales, NO Godot")
    parser.add_argument("--self-test", action="store_true",
                        help="Rechazar seis mutaciones deliberadas")
    parser.add_argument("--native", action="store_true", help="Validar pruebas reales Godot y recibos SHA")
    parser.add_argument("--report", type=Path, default=ROOT / ".godot/parallel_items/w01_campaign_002/report.json")
    args = parser.parse_args()
    try:
        fixture = load_json(FIXTURE)
        cases, runs, variants = validate_fixture(fixture)
        validate_sources(fixture)
        print(f"W01_CAMP002_ITER01_CONTRACT_PASS cases={cases} runs={runs} variants={variants} sources=4")
        if args.self_test:
            print(f"W01_CAMP002_ITER01_NEGATIVE_PASS rejected={self_test(fixture)}")
        if args.native:
            checked, modes = validate_native_report(args.report, fixture)
            print(f"W01_CAMP002_NATIVE_EVIDENCE_PASS runs={checked} variants={modes}")
        elif not args.contracts and not args.self_test:
            print("PREPARADO_PENDIENTE_CI; invoque --native para exigir reporte Godot real")
        return 0
    except (OSError, ValueError, KeyError, IndexError, TypeError, AssertionError) as exc:
        print(f"W01_CAMP002_ITER01_CONTRACT_FAIL {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
