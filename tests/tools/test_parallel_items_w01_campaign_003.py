#!/usr/bin/env python3
"""CAMP003 W01: contrato acumulativo de la cola + evidencia real existente (no simula combate).

El gate Godot separado contrasta todos los efectos y SaveV2. Este script no
afirma que se hayan ejecutado los casos nativos.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUEUE = ROOT / "docs/coordination/items_parallel_v1/CAMPAIGN_003_QUEUE_APPROVED.csv"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W01/CAMP_003_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_003.json"
REFS = {
    "docs/current/ITEM_INVENTORY.csv": "2aaf18643bb2b071226118a1ad556cffca4707dd",
    "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv": "8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b",
    "tests/gameplay/parallel_items_w01_held_v1.gd": "d9551db1ec5e08b1213e04829d031e3a6720188f",
    "tools/item_audit/held_effect_sweep_v3.cjs": "fd5d9d0b1eecf8b84f14e606631df93b40728586",
    "tools/item_audit/held_effect_sweep_v2.cjs": "c9ba4d7bcddad6ae69f085f4b69983461ad05219",
    "tools/item_audit/held_pilot.cjs": "c8a59a18f546d772ff34e4f8640a4246a00a822b",
}
BLOCK_01 = ("air_balloon", "assault_vest", "binding_band")
SCENARIOS_01 = {
    "balloon_ground_immune": ("air_balloon", "ground_immunity", "garchomp", "earthquake", "reflect", (19,23)),
    "balloon_pop_normal": ("air_balloon", "normal_hit_pops", "snorlax", "tackle", "reflect", (23,)),
    "balloon_no_hit": ("air_balloon", "no_hit_retained", "mew", "amnesia", "reflect", (23,)),
    "vest_lock_restore": ("assault_vest", "status_lock", "mew", "amnesia", "tackle", (19,23)),
    "vest_physical_control": ("assault_vest", "physical_control", "snorlax", "tackle", "tackle", (23,)),
    "band_trap_residual": ("binding_band", "trap_residual", "snorlax", "amnesia", "infestation", (19,23)),
    "band_plain_control": ("binding_band", "non_trap_control", "snorlax", "amnesia", "tackle", (23,)),
}
SCENARIOS_02 = {
    "blunder_accuracy_event": ("blunder_policy", "accuracy_miss_trigger", "mew", "",
        "mew", "amnesia", "zap_cannon", (1,2,3,4,5,6,7,8)),
    "blunder_never_miss": ("blunder_policy", "accuracy_control", "mew", "",
        "mew", "amnesia", "tackle", (19,)),
    "booster_protosynthesis": ("booster_energy", "paradox_activation", "great_tusk",
        "protosynthesis", "mew", "amnesia", "reflect", (19,23)),
    "booster_quark_drive": ("booster_energy", "paradox_activation", "iron_hands",
        "quark_drive", "mew", "amnesia", "reflect", (19,23)),
    "booster_wrong_ability": ("booster_energy", "wrong_ability_control", "mew", "",
        "mew", "amnesia", "reflect", (19,)),
    "battery_electric_hit": ("cell_battery", "electric_damage_boost", "mew", "",
        "mew", "thunder_shock", "reflect", (19,23)),
    "battery_non_electric_hit": ("cell_battery", "non_electric_control", "mew", "",
        "mew", "tackle", "reflect", (19,)),
    "battery_no_hit": ("cell_battery", "no_hit_control", "mew", "",
        "mew", "amnesia", "reflect", (19,)),
}
SCENARIOS_03 = {
    "amulet_charm_block": ("clear_amulet", "opponent_drop_block", "mew", "",
        "mew", "charm", "reflect", (19,23)),
    "amulet_no_drop": ("clear_amulet", "no_drop_control", "mew", "",
        "mew", "amnesia", "reflect", (19,)),
    "cloak_nuzzle_secondary": ("covert_cloak", "secondary_status_block", "mew", "",
        "mew", "nuzzle", "reflect", (19,23)),
    "cloak_plain_hit": ("covert_cloak", "normal_damage_control", "mew", "",
        "mew", "tackle", "reflect", (19,)),
    "eject_on_hit": ("eject_button", "hit_forces_switch", "mew", "",
        "snorlax", "tackle", "reflect", (19,23)),
    "eject_without_hit": ("eject_button", "no_hit_no_switch", "mew", "",
        "mew", "amnesia", "reflect", (19,)),
}
SCENARIOS_04 = {
    "eject_pack_self_drop": ("eject_pack", "own_stat_drop_forces_switch", "mew", "", "",
        "snorlax", "amnesia", "close_combat", (19,23)),
    "eject_pack_no_drop": ("eject_pack", "own_no_drop_control", "mew", "", "",
        "snorlax", "amnesia", "tackle", (19,)),
    "electric_seed_field": ("electric_seed", "electric_field_defense", "mew", "", "",
        "mew", "electric_terrain", "reflect", (19,23)),
    "electric_seed_wrong_field": ("electric_seed", "non_electric_field", "mew", "", "",
        "mew", "misty_terrain", "reflect", (19,)),
    "electric_seed_no_field": ("electric_seed", "no_terrain_control", "mew", "", "",
        "mew", "amnesia", "reflect", (19,)),
    "focus_band_lethal_rng": ("focus_band", "random_lethal_survival", "mew", "", "one",
        "mew", "seismic_toss", "reflect", tuple(range(1,25))),
    "focus_band_nonlethal": ("focus_band", "nonlethal_control", "mew", "", "",
        "mew", "tackle", "reflect", (19,)),
}
SCENARIOS_05 = {
    "flame_burn_end_turn": ("flame_orb", "end_turn_burn", "mew", "", "", 100,
        "mew", 100, "amnesia", "reflect", (19,23)),
    "flame_fire_type_immune": ("flame_orb", "fire_type_immunity", "charizard", "", "", 100,
        "mew", 100, "amnesia", "scratch", (19,)),
    "sash_full_hp_lethal": ("focus_sash", "focus_sash_full_hp", "pikachu", "", "", 1,
        "mew", 100, "seismic_toss", "growl", (1,19)),
    "sash_partial_hp_lethal": ("focus_sash", "focus_sash_not_full", "pikachu", "",
        "minus_one", 1, "mew", 100, "seismic_toss", "growl", (19,)),
    "sash_nonlethal": ("focus_sash", "focus_sash_nonlethal", "mew", "", "", 100,
        "mew", 1, "tackle", "growl", (23,)),
    "grassy_seed_field": ("grassy_seed", "grassy_field_defense", "mew", "", "", 100,
        "mew", 100, "grassy_terrain", "reflect", (19,23)),
    "grassy_seed_wrong_field": ("grassy_seed", "grassy_wrong_terrain", "mew", "", "", 100,
        "mew", 100, "electric_terrain", "reflect", (19,)),
    "grassy_seed_no_field": ("grassy_seed", "grassy_no_terrain", "mew", "", "", 100,
        "mew", 100, "amnesia", "reflect", (19,)),
}
SCENARIOS_06 = {
    "grip_trap_seven_turns": ("grip_claw", "trap_extended_duration", "mew", "", "", 100,
        "snorlax", 100, "amnesia", "infestation", (19,23)),
    "grip_no_trapping_move": ("grip_claw", "trap_no_activation", "mew", "", "", 100,
        "snorlax", 100, "amnesia", "tackle", (19,)),
    "heat_sun_duration": ("heat_rock", "sun_eight_turns", "mew", "", "", 100,
        "mew", 100, "amnesia", "sunny_day", (19,23)),
    "heat_no_sun": ("heat_rock", "no_sunny_day", "mew", "", "", 100,
        "mew", 100, "amnesia", "reflect", (19,)),
    "boots_rock_switch": ("heavy_duty_boots", "boots_rock_reentry", "mew", "", "", 100,
        "mew", 100, "stealth_rock", "reflect", (19,23)),
    "boots_no_rock_switch": ("heavy_duty_boots", "boots_no_rock_control", "mew", "", "", 100,
        "mew", 100, "amnesia", "reflect", (19,)),
}
OPERATIONS = ({r[1] for r in SCENARIOS_01.values()}
              | {r[1] for r in SCENARIOS_02.values()}
              | {r[1] for r in SCENARIOS_03.values()}
              | {r[1] for r in SCENARIOS_04.values()}
              | {r[1] for r in SCENARIOS_05.values()}
              | {r[1] for r in SCENARIOS_06.values()})
REQUIRED_CASE_FIELDS = {"block", "id", "item_id", "op", "actor_species", "foe_species",
                        "foe_move", "own_move", "seeds", "history"}
TOTAL_CHECKS = 0

def require(ok, message):
    global TOTAL_CHECKS
    TOTAL_CHECKS += 1
    if not ok:
        raise ValueError(message)

def csv_rows(path):
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))

def git_blob_sha(path):
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()

def validate() -> int:
    queue = csv_rows(QUEUE)
    progress = csv_rows(PROGRESS)
    require(len(queue) == 40 and len(progress) in range(1,11), "Cola/progreso no válidos")
    tasks = [r for r in queue if r["trabajadora"] == "W01"]
    require(len(tasks) == 10 and [x["bloque"] for x in tasks] == [f"{i:02}" for i in range(1,11)],
            "Diez bloques W01 autorizados no contiguos")
    for index, done in enumerate(progress):
        require(done["bloque"] == tasks[index]["bloque"] and done["ids"] == tasks[index]["ids"],
                f"Progreso fuera de secuencia {index+1}")
        require(done["estado"] in {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
                                  "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"},
                "Estado del progreso no permitido")
        require(bool(done["sha_pruebas"]) and bool(done["notas"]), "SHA/notas ausentes")
    document = json.loads(FIXTURE.read_text(encoding="utf-8"))
    require(type(document) is dict
            and set(document) == {"schema_version", "campaign", "worker", "format",
                                  "variants", "sources", "cases"}, "Cabecera de fixture alterada")
    require(document["schema_version"] == 1 and document["campaign"] == "CAMP_003"
            and document["worker"] == "W01" and document["format"] == "gen9calvounifiedv1",
            "Familia/version ajena")
    require(document["variants"] == ["active", "none", "reserve"], "Controles faltantes")
    require(type(document["sources"]) is list and len(document["sources"]) == len(REFS),
            "Fuentes históricas incompletas")
    sources = set()
    for source in document["sources"]:
        require(set(source) == {"path", "git_blob_sha"}, "Fuente no declarativa")
        path = source["path"]
        require(path in REFS and path not in sources and source["git_blob_sha"] == REFS[path],
                "Origen/identificador SHA ajeno")
        sources.add(path)
        require(git_blob_sha(ROOT / path) == source["git_blob_sha"],
                f"Referencia histórica alterada: {path}")
    require(sources == set(REFS), "Faltan fuentes")
    scope = (ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv").read_text(encoding="utf-8-sig")
    inventory = (ROOT / "docs/current/ITEM_INVENTORY.csv").read_text(encoding="utf-8-sig")
    for task in tasks[:len(progress)]:
        for item in task["ids"].split(";"):
            scope_lines = [line.split(",") for line in scope.splitlines() if line.startswith(item + ",")]
            inv_lines = [line.split(",") for line in inventory.splitlines() if line.startswith(item + ",")]
            require(len(scope_lines) == 1 and scope_lines[0][2] == "HELD_COMBAT_CANDIDATE"
                    and scope_lines[0][4] == "SELECCIONADO", "Objeto no autorizado en selección: "+item)
            require(len(inv_lines) == 1 and inv_lines[0][3] == "HELD_COMBAT_CANDIDATE"
                    and inv_lines[0][7] == "True" and bool(inv_lines[0][8]),
                    "Objeto sin entrada nativa: "+item)
    old_w01 = (ROOT / "tests/gameplay/parallel_items_w01_held_v1.gd").read_text(encoding="utf-8")
    old_v3 = (ROOT / "tools/item_audit/held_effect_sweep_v3.cjs").read_text(encoding="utf-8")
    require('"status_gate"' in old_w01 and '"special_resistance"' in old_w01,
            "Chaleco Asalto: prueba histórica desaparecida")
    require("add('binding_band','partial_trap_residual'" in old_v3
            and "moves:['infestation']" in old_v3, "Banda Atadura: referencia nativa ausente")
    require("HELD_PILOT_VERIFIED" in next(x for x in inventory.splitlines()
                                         if x.startswith("air_balloon,")),
            "Globo Helio: historial nativo ausente")
    old_v2 = (ROOT / "tools/item_audit/held_effect_sweep_v2.cjs").read_text(encoding="utf-8")
    if len(progress) >= 3:
        require("add('clear_amulet','opponent_drop_protection'" in old_v2
                and "foeMoves:['charm']" in old_v2,
                "Amuleto Puro: prueba histórica de descenso ausente")
        require("add('covert_cloak','secondary_protection'" in old_v2
                and "foeMoves:['nuzzle']" in old_v2,
                "Capa Furtiva: control de Nuzzle ausente")
        require("HELD_PILOT_VERIFIED" in next(x for x in inventory.splitlines()
                                             if x.startswith("eject_button,")),
                "Botón Escape: evidencia piloto ausente")
    if len(progress) >= 4:
        require("add('eject_pack','self_drop'" in old_v3
                and "moves:['close_combat']" in old_v3
                and "add('eject_pack','no_drop'" in old_v3,
                "Mochila Escape: referencia nativa de bajada propia ausente")
        require("['electric_seed','electric_terrain','def']" in old_v3
                and "add(id,'wrong_terrain'" in old_v3,
                "Semilla Electro: terreno efectivo y terreno equivocado no acreditados")
        require("add('focus_band','survival_rng'" in old_v3
                and "foeMoves:['seismic_toss']" in old_v3,
                "Cinta Aguante: fuente RNG de supervivencia ausente")
    if len(progress) >= 5:
        require("add('flame_orb','end_turn_status'" in old_v2
                and "own(a).status_id,'burn'" in old_v2,
                "Llamasfera: referencia nativa de quemadura residual ausente")
        require("['grassy_seed','grassy_terrain','def']" in old_v3
                and "add(id,'wrong_terrain'" in old_v3,
                "Semilla Hierba: referencia de terreno y control ausente")
        require("HELD_PILOT_VERIFIED" in next(x for x in inventory.splitlines()
                                             if x.startswith("focus_sash,")),
                "Banda Aguante: piloto histórico sin evidencia")
        require('"lethal_full"' in old_w01 and "lethal_partial" in old_w01
                and "nonlethal_control" in old_w01,
                "Banda Aguante: escenarios históricos de PS y KO ausentes")
    if len(progress) >= 6:
        native_pilot = (ROOT / "tools/item_audit/held_pilot.cjs").read_text(encoding="utf-8")
        require("add('grip_claw','partial_trap_duration'" in old_v3
                and "Array.from({length:6}" in old_v3
                and "moves:['infestation','reflect']" in old_v3,
                "Garra Garfio: siete turnos de atrapamiento sin fuente nativa")
        require("['heat_rock','sunny_day']" in old_v3
                and "weatherState.duration" in old_v3,
                "Roca Calor: origen de prolongacion solar no verificado")
        require("heavy_duty_boots:{foe:['stealth_rock']" in native_pilot
                and "switch '+slot" in native_pilot,
                "Botas Gruesas: piloto de salida/entrada ante Trampa Rocas ausente")
        require("HELD_PILOT_VERIFIED" in next(x for x in inventory.splitlines()
                                             if x.startswith("heavy_duty_boots,")),
                "Botas Gruesas: historico piloto no acreditado")
    cases = document["cases"]
    require(type(cases) is list and len(cases) >= 7, "Sin casos suficientes")
    found, pairs = set(), set()
    per_id = {}
    stage_map = {r["bloque"]: set(r["ids"].split(";")) for r in tasks[:len(progress)]}
    for case in cases:
        require(type(case) is dict and REQUIRED_CASE_FIELDS <= set(case)
                and set(case) <= REQUIRED_CASE_FIELDS | {"actor_ability", "actor_hp", "actor_level", "foe_level"},
                "Caso con forma inválida")
        name, stage, item = case["id"], case["block"], case["item_id"]
        require(type(name) is str and name not in found and stage in stage_map
                and item in stage_map[stage], "Caso duplicado/fuera de encargo")
        found.add(name)
        require(type(case["actor_species"]) is str and bool(case["actor_species"]) and type(case["history"]) is str
                and len(case["history"]) >= 8, "Especie/historial no justificado")
        require(case["op"] in OPERATIONS, "Operacion no implementada por runner: "+case["op"])
        require(type(case["seeds"]) is list and 1 <= len(case["seeds"]) <=
                (24 if name == "focus_band_lethal_rng" else 8 if name == "blunder_accuracy_event" else 4),
                "Semillas ausentes o excesivas para el caso")
        for seed in case["seeds"]:
            require(type(seed) is int and 0 <= seed <= 65535
                    and (name, seed) not in pairs, "Semilla no entera o par duplicado")
            pairs.add((name, seed))
        per_id.setdefault((stage, item), []).append(case)
        if stage == "01":
            require(name in SCENARIOS_01, "Caso nuevo de bloque 01 no autorizado")
            item0, op, foe, foe_move, own_move, seeds = SCENARIOS_01[name]
            require((item, case["op"], case["foe_species"], case["foe_move"],
                     case["own_move"], tuple(case["seeds"])) ==
                    (item0, op, foe, foe_move, own_move, seeds),
                    "Semillas o mecanismo del bloque 01 desviados: "+name)
        elif stage == "02":
            require(name in SCENARIOS_02, "Caso nuevo no autorizado de bloque 02")
            item0, op, actor, ability, foe, foe_move, own_move, seeds = SCENARIOS_02[name]
            actual = (item, case["op"], case["actor_species"], case.get("actor_ability", ""),
                      case["foe_species"], case["foe_move"], case["own_move"],
                      tuple(case["seeds"]))
            require(actual == (item0, op, actor, ability, foe, foe_move, own_move, seeds),
                    "Cambio no autorizado de causa/semilla: "+name)
        elif stage == "03":
            require("actor_hp" not in case, "Stage03 sin condiciones de HP ajenas")
            require(name in SCENARIOS_03, "Caso ajeno a bloque W01/03")
            expected = SCENARIOS_03[name]
            actual = (item, case["op"], case["actor_species"], case.get("actor_ability", ""),
                      case["foe_species"], case["foe_move"], case["own_move"],
                      tuple(case["seeds"]))
            require(actual == expected, "Desvío de causas/semillas W01/03: "+name)
        elif stage == "04":
            require("actor_level" not in case and "foe_level" not in case, "Stage04 sin niveles adicionales")
            require(name in SCENARIOS_04, "Caso ajeno al bloque W01/04")
            expected = SCENARIOS_04[name]
            actual = (item, case["op"], case["actor_species"], case.get("actor_ability", ""),
                      case.get("actor_hp", ""), case["foe_species"], case["foe_move"],
                      case["own_move"], tuple(case["seeds"]))
            require(actual == expected, "Mecánica o semilla desviada W01/04: "+name)
        elif stage == "05":
            require(name in SCENARIOS_05, "Caso no autorizado W01/05")
            expected = SCENARIOS_05[name]
            actual = (item, case["op"], case["actor_species"],
                      case.get("actor_ability", ""), case.get("actor_hp", ""),
                      case.get("actor_level", 100), case["foe_species"],
                      case.get("foe_level", 100), case["foe_move"], case["own_move"],
                      tuple(case["seeds"]))
            require(actual == expected, "Condición o semilla alterada W01/05: " + name)
        elif stage == "06":
            require(name in SCENARIOS_06, "Caso ajeno al bloque W01/06")
            expected = SCENARIOS_06[name]
            actual = (item, case["op"], case["actor_species"], case.get("actor_ability", ""),
                      case.get("actor_hp", ""), case.get("actor_level", 100),
                      case["foe_species"], case.get("foe_level", 100), case["foe_move"],
                      case["own_move"], tuple(case["seeds"]))
            require(actual == expected, "Condición de evento o semilla desviada W01/06: "+name)
        elif stage not in {"01", "02", "03", "04", "05", "06"}:
            raise ValueError("Stage no implementado por validador W01")
    for stage, ids in stage_map.items():
        for item in ids:
            require((stage,item) in per_id, "Objeto sin caso de test: "+item)
    require(set(SCENARIOS_01) <= found, "Faltan 7 casos obligatorios del bloque 01")
    if len(progress) == 1:
        require(len(cases) == 7 and len(pairs) == 10, "Matriz inicial 7/10 alterada")
    if len(progress) == 2:
        require(len(cases) == 15 and len(pairs) == 28, "Matriz acumulativa 15/28 alterada")
        require(set(SCENARIOS_02) <= found, "Faltan 8 casos del bloque 02")
    if len(progress) == 3:
        require(len(cases) == 21 and len(pairs) == 37,
                "Matriz acumulativa W01 03 incorrecta: esperados 21 casos/37 corridas")
        require(set(SCENARIOS_03) <= found, "Faltan 6 casos autorizados del bloque 03")
    if len(progress) == 4:
        require(len(cases) == 28 and len(pairs) == 69,
                "Matriz W01/04 debe tener 28 escenarios y 69 pares")
        require(set(SCENARIOS_04) <= found,
                "Faltan 7 casos positivos/negativos del bloque W01/04")
    if len(progress) == 5:
        require(len(cases) == 36 and len(pairs) == 80,
                "Matriz W01/05 debe preservar 36 escenarios y 80 pares")
        require(set(SCENARIOS_05) <= found, "Faltan escenarios W01/05")
    if len(progress) == 6:
        require(len(cases) == 42 and len(pairs) == 89,
                "Matriz W01/06 exige 42 escenarios y 89 pares")
        require(set(SCENARIOS_06) <= found,
                "Faltan 6 positivos/negativos de Garra Garfio, Roca Calor y Botas Gruesas")
    return len(progress)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true", help="Exigir alcance y fuentes reales")
    args = parser.parse_args()
    try:
        blocks = validate()
    except (OSError, ValueError, KeyError, TypeError, StopIteration, json.JSONDecodeError) as exc:
        print("CAMP003_W01_PY FAIL "+str(exc), file=sys.stderr)
        return 1
    if args.ci:
        print(f"CAMP003_W01_PY PASS blocks={blocks} checks={TOTAL_CHECKS}")
    else:
        print(f"W01 fixture/sources valid: blocks={blocks} checks={TOTAL_CHECKS}; Godot pendiente")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
