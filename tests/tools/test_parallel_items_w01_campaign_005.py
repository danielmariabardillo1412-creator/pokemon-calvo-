#!/usr/bin/env python3
"""IA1/W01 CAMP005 — contrato acumulativo autorizado para 5 bloques funcionales.

No atribuye PASS de Godot: el recibo de efecto positivo corresponde al runner
real tests/gameplay/parallel_items_w01_campaign_005.gd y a CI del mismo SHA.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_005_W01_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W01/CAMP_005_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_005.json"
INVENTORY = ROOT / "docs/current/ITEM_INVENTORY.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
PRIOR_PROGRESS = BASE / "reports/W01/CAMP_004_PROGRESO.csv"
PARENT_RUNNER = ROOT / "tests/gameplay/parallel_items_w01_campaign_004.gd"
PARENT_FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_004.json"
RUNNER = ROOT / "tests/gameplay/parallel_items_w01_campaign_005.gd"
HISTORY = ROOT / "tools/item_audit/held_effect_sweep_v2.cjs"
FLINCH_HISTORY = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"

# ID, tipo, ataque positivo y clave nativa; misma referencia ya probada en CAMP004.
ITEMS = {
    "black_glasses": ("dark", "dark_pulse", "blackglasses"),
    "dragon_fang": ("dragon", "dragon_pulse", "dragonfang"),
    "hard_stone": ("rock", "smack_down", "hardstone"),
    "miracle_seed": ("grass", "energy_ball", "miracleseed"),
    "mystic_water": ("water", "surf", "mysticwater"),
    "never_melt_ice": ("ice", "ice_beam", "nevermeltice"),
    "poison_barb": ("poison", "sludge_bomb", "poisonbarb"),
    "sharp_beak": ("flying", "aerial_ace", "sharpbeak"),
    "silk_scarf": ("normal", "tackle", "silkscarf"),
    "silver_powder": ("bug", "bug_buzz", "silverpowder"),
    "soft_sand": ("ground", "earth_power", "softsand"),
    "spell_tag": ("ghost", "shadow_ball", "spelltag"),
    "twisted_spoon": ("psychic", "psychic", "twistedspoon"),
    "metal_coat": ("steel", "flash_cannon", "metalcoat"),
    "kings_rock": ("flinch", "tackle", "kingsrock"),
}
MODES = ["active", "none", "reserve"]
STATES = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
          "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}
CHECKS = 0


def check(condition: bool, reason: str) -> None:
    global CHECKS
    CHECKS += 1
    if not condition:
        raise ValueError(reason)


def rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def validate() -> int:
    queue = rows(QUEUE)
    check(len(queue) == 10, "Cola CAMP005 W01 debe contener 10 bloques")
    check([r["bloque"] for r in queue] == [f"{i:02d}" for i in range(1, 11)],
          "Orden de bloques no autorizado")
    check(all(r["trabajadora"] == "W01" and r["tipo"] == "NEW_IDS"
              and r["familia"] == "HELD_COMBAT" and r["estado"] == "AUTORIZADO_NO_EJECUTADO"
              for r in queue), "Cola no coincide con autoridad IA6")
    all_ids = [x for r in queue for x in r["ids"].split(";")]
    check(len(all_ids) == len(set(all_ids)) == 30, "Cola CAMP005 duplica objetos")
    check(queue[0]["ids"] == "black_glasses;dragon_fang;hard_stone",
          "Primer bloque fuera de encargo de IA6")
    check(queue[1]["ids"] == "miracle_seed;mystic_water;never_melt_ice",
          "Segundo bloque fuera de encargo de IA6")
    check(queue[2]["ids"] == "poison_barb;sharp_beak;silk_scarf",
          "Tercer bloque fuera de encargo de IA6")
    check(queue[3]["ids"] == "silver_powder;soft_sand;spell_tag",
          "Cuarto bloque fuera de encargo de IA6")
    check(queue[4]["ids"] == "twisted_spoon;metal_coat;kings_rock",
          "Quinto bloque fuera de encargo de IA6")

    progress = rows(PROGRESS)
    check(len(progress) == 5, "Bloque 05 exige progreso exacto 5/10")
    first = progress[0]
    check(first["bloque"] == "01" and first["ids"] == queue[0]["ids"],
          "La fila 01 no pertenece a W01")
    check(first["estado"] == "CI_PASS_VERIFICADO"
          and first["sha_pruebas"] == "bd33aeb3f993804c3c85217b81892356af39aac5"
          and first["ci_run"] == "41767517526",
          "Bloque 01 sin certificado GitHub Actions real")
    second = progress[1]
    check(second["bloque"] == "02" and second["ids"] == queue[1]["ids"]
          and second["estado"] == "CI_PASS_VERIFICADO"
          and second["sha_pruebas"] == "69438bfb81921456a87eb7da18b3442f50c79873"
          and second["ci_run"] == "41778911208",
          "Bloque 02 no tiene el certificado de CI oficial")
    third = progress[2]
    check(third["bloque"] == "03" and third["ids"] == queue[2]["ids"]
          and third["estado"] == "CI_PASS_VERIFICADO"
          and third["sha_pruebas"] == "67d0fe6041e690cc8059fd626eea7cdd4a840db2"
          and third["ci_run"] == "41783664400",
          "Bloque 03 sin certificado de CI oficial")
    fourth = progress[3]
    check(fourth["bloque"] == "04" and fourth["ids"] == queue[3]["ids"]
          and fourth["estado"] == "CI_PASS_VERIFICADO"
          and fourth["sha_pruebas"] == "814943eb7445acee0161763eff85eb87285ed3ec"
          and fourth["ci_run"] == "41954611857",
          "Bloque 04 sin certificado de CI oficial")
    fifth = progress[4]
    check(fifth["bloque"] == "05" and fifth["ids"] == queue[4]["ids"]
          and fifth["estado"] in STATES,
          "Estado o propiedad de fila 05 incorrectos")
    check(bool(first["sha_pruebas"]) and bool(first["ci_run"]),
          "Progreso sin trazabilidad de estado pendiente")

    previous = rows(PRIOR_PROGRESS)
    check(len(previous) == 10 and all(r["estado"] == "CI_PASS_VERIFICADO" for r in previous),
          "Se han perdido las diez certificaciones CAMP004")
    check(previous[9]["ids"] == "black_belt;charcoal;magnet"
          and previous[9]["ci_run"] == "41733777992"
          and previous[9]["sha_pruebas"] ==
          "9770b71a7f7c6d5e9b6e93eeaef81e96d42a094b",
          "CI final CAMP004 no está anclada al SHA certificado")
    check(git_blob_sha(PARENT_RUNNER) ==
          "67849ef12762919172e6297cdc242f1fcea6d13e",
          "Runner heredado CAMP004 ha cambiado: revisar regresión")
    check(git_blob_sha(PARENT_FIXTURE) ==
          "f1a094395cc83d55fefbf9a1c27fe235cb5193d7",
          "Fixture heredado CAMP004 ha cambiado: revisar regresión")

    scope = {r["id"]: r for r in rows(SCOPE)}
    inventory = {r["id"]: r for r in rows(INVENTORY)}
    history = HISTORY.read_text(encoding="utf-8")
    flinch_history = FLINCH_HISTORY.read_text(encoding="utf-8")
    check("kings_rock" in flinch_history and "flinch_rng" in flinch_history
          and "l.includes('|flinch')" in flinch_history,
          "Falta referencia histórica nativa de retroceso Roca del Rey")
    check("for(const [family,table] of [['type_boost',booster]" in history,
          "No hay escenario histórico nativo positivo de potenciadores de tipo")
    check("family+'_nonmatching'" in history
          and "foe(a).hp<foe(b).hp" in history,
          "Falta control histórico positivo/negativo de daño")
    for item, (kind, move, native) in ITEMS.items():
        check(item in ";".join(r["ids"] for r in queue[:5]).split(";"),
              "Objeto fuera de bloques 01/02/03/04/05 " + item)
        check(scope[item]["estado_contenido"] == "SELECCIONADO"
              and scope[item]["familia"] == "HELD_COMBAT_CANDIDATE",
              "Objeto no seleccionado: " + item)
        check(inventory[item]["family"] == "HELD_COMBAT_CANDIDATE"
              and inventory[item]["native_entry"] == "True"
              and inventory[item]["native_id"] == native
              and ("onModifyMove" if item == "kings_rock" else "onBasePower")
                  in inventory[item]["native_hooks"],
              "Objeto sin soporte nativo funcional: " + item)
        if item != "kings_rock":
            check(f"{kind}:'{item}'" in history and f"{kind}:'{move}'" in history,
                  "Referencias de tipo y ataque incoherentes: " + item)

    data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    check(data["schema_version"] == 1 and data["worker"] == "W01"
          and data["campaign"] == "CAMP_005" and data["kind"] == "NEW_IDS"
          and data["format"] == "gen9calvounifiedv1", "Fixture CAMPAÑA_005 inválido")
    check(data["variants"] == MODES, "Falta un modo activo, sin objeto o reserva")
    check(len(data["blocks"]) == 5
          and [b["block"] for b in data["blocks"]] == ["01", "02", "03", "04", "05"]
          and all(data["blocks"][i]["ids"] == list(ITEMS)[i*3:(i+1)*3]
                  for i in range(5)),
          "Fixture no sigue los bloques 01/02/03/04/05 exactos de IA6")
    cases = data["cases"]
    check(len(cases) == 45 and len({c["id"] for c in cases}) == 45,
          "Se exigen 45 escenarios distintos")
    for i, block in enumerate(data["blocks"]):
        check(set(block["cases"]) == {c["id"] for c in cases
                                       if c["block"] == f"{i+1:02d}"},
              "Escenarios fuera del bloque oficial " + block["block"])
    pairs = 0
    seen = set()
    for index, (item, (_, matching_move, _)) in enumerate(ITEMS.items()):
        wrong_move = "water_gun" if item == "silk_scarf" else "tackle"
        plans = ((
            ("flinch", "kings_rock_flinch", "tackle", list(range(1, 65))),
            ("immune", "kings_rock_immune", "tackle", [19]),
            ("status", "kings_rock_status", "reflect", [19]),
        ) if item == "kings_rock" else (
            ("matching", "matching_type_boost", matching_move, [19, 23]),
            ("nonmatching", "nonmatching_control", wrong_move, [19]),
            ("status", "status_control", "reflect", [19]),
        ))
        for suffix, op, move, seeds in plans:
            label = f"{item}_{suffix}"
            found = [c for c in cases if c["id"] == label]
            check(len(found) == 1, "Caso funcional ausente " + label)
            c = found[0]
            check(c["block"] == f"{index // 3 + 1:02d}"
                  and c["item_id"] == item and c["op"] == op,
                  "Operación o propietario incorrecto: " + label)
            target = ("gengar" if suffix == "immune" else "snorlax") if item == "kings_rock" else "mew"
            target_move = "tackle" if item == "kings_rock" else "amnesia"
            check(c["actor_species"] == "mew" and c["foe_species"] == target
                  and c["own_move"] == move and c["foe_move"] == target_move,
                  "Pokémon y movimiento real alterado: " + label)
            check(c["seeds"] == seeds and all(type(i) is int and i > 0 for i in seeds),
                  "Semillas de control alteradas: " + label)
            reference = ("tools/item_audit/held_effect_sweep_v3.cjs:flinch_rng"
                         if item == "kings_rock" else
                         "tools/item_audit/held_effect_sweep_v2.cjs:type_boost")
            check(c["history"] == reference,
                  "Sin trazabilidad a prueba nativa: " + label)
            seen.add(label)
            pairs += len(seeds)
    check(seen == {c["id"] for c in cases} and pairs == 122,
          "No hay 122 pares caso-semilla autorizados")

    runner = RUNNER.read_text(encoding="utf-8")
    for token in (
        'extends "res://tests/gameplay/parallel_items_w01_campaign_004.gd"',
        'call_deferred("_w01_c004_probe_lane"',
        '_compare_c005(row, observed)',
        'x.get("restored", false)',
        'x.get("owner_unchanged", false)',
        'a.damage > n.damage',
        'a.damage == n.damage',
        'not a.after.own_consumed',
        'CAMP005_W01_GODOT PASS blocks=',
    ):
        check(token in runner, "Runner carece de contrato funcional: " + token)
    for token in ("kings_rock_flinch", "kings_rock_immune", "kings_rock_status",
                  "c005_king_rock_activated", "c005_king_rock_not_activated",
                  "flinched", "super._probe_w01_c004"):
        check(token in runner, "Falta verificación positiva nativa Roca del Rey: " + token)
    check("await _restore_probe(" in PARENT_RUNNER.read_text(encoding="utf-8"),
          "Falta restauración real SaveV2 heredada")

    return len(progress)


def main() -> int:
    argparse.ArgumentParser(description=__doc__).add_argument("--ci", action="store_true")
    try:
        n = validate()
    except (ValueError, KeyError, OSError, json.JSONDecodeError, TypeError) as exc:
        print("CAMP005_W01_PY FAIL:", exc)
        return 1
    print(f"CAMP005_W01_PY PASS blocks={n} checks={CHECKS}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
