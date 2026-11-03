#!/usr/bin/env python3
"""W01 CAMP004: contrato auditable de especies, fixtures y fuentes nativas.
Las aserciones de batalla y SaveV2 se ejecutan separadamente en Godot.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W01_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W01/CAMP_004_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w01_campaign_004.json"
NATIVE = ROOT / "tools/item_audit/held_effect_sweep_v3.cjs"
REFS = {
    "docs/current/ITEM_INVENTORY.csv": "2aaf18643bb2b071226118a1ad556cffca4707dd",
    "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv": "8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b",
    "tools/item_audit/held_effect_sweep_v3.cjs": "fd5d9d0b1eecf8b84f14e606631df93b40728586",
    "tools/item_audit/held_effect_sweep_v2.cjs": "c9ba4d7bcddad6ae69f085f4b69983461ad05219",
    "tools/item_audit/held_pilot.cjs": "c8a59a18f546d772ff34e4f8640a4246a00a822b",
}
EXPECTED = {
    "ball_pikachu_special": ("light_ball", "damage_boost_compatible", "pikachu", "thunder_shock", "", (19, 23)),
    "ball_pikachu_physical": ("light_ball", "damage_boost_compatible", "pikachu", "tackle", "", (19, 23)),
    "ball_wrong_species": ("light_ball", "wrong_holder_no_damage_boost", "mew", "thunder_shock", "", (19,)),
    "club_cubone_physical": ("thick_club", "damage_boost_compatible", "cubone", "tackle", "", (19, 23)),
    "club_marowak_physical": ("thick_club", "damage_boost_compatible", "marowak", "tackle", "", (19, 23)),
    "club_wrong_species": ("thick_club", "wrong_holder_no_damage_boost", "mew", "tackle", "", (19,)),
    "punch_chansey_critical": ("lucky_punch", "critical_ratio_compatible", "chansey", "focus_energy", "tackle", tuple(range(1, 17))),
    "punch_wrong_species": ("lucky_punch", "wrong_holder_no_critical_ratio", "mew", "focus_energy", "tackle", tuple(range(1, 9))),
    "rain_duration": ("damp_rock", "weather_duration", "mew", "rain_dance", "", (19, 23)),
    "rain_no_weather": ("damp_rock", "no_weather", "mew", "reflect", "", (19,)),
    "snow_duration": ("icy_rock", "weather_duration", "mew", "snowscape", "", (19, 23)),
    "snow_no_weather": ("icy_rock", "no_weather", "mew", "reflect", "", (19,)),
    "weight_grass_knot": ("float_stone", "weight_damage_reduced", "garchomp", "reflect", "", (19, 23)),
    "weight_tackle_control": ("float_stone", "fixed_power_control", "garchomp", "reflect", "", (19,)),
    "dice_bullet_seed": ("loaded_dice", "loaded_dice_multihit", "mew", "bullet_seed", "", tuple(range(1, 13))),
    "dice_tackle_control": ("loaded_dice", "loaded_dice_single_hit", "mew", "tackle", "", (19,)),
    "misty_seed_trigger": ("misty_seed", "misty_seed_terrain", "mew", "reflect", "", (19, 23)),
    "misty_seed_wrong_terrain": ("misty_seed", "misty_seed_no_trigger", "mew", "reflect", "", (19,)),
    "power_herb_solar_beam": ("power_herb", "power_herb_skip_charge", "mew", "solar_beam", "", (19, 23)),
    "power_herb_noncharge": ("power_herb", "power_herb_no_charge_control", "mew", "tackle", "", (19,)),
}
NEW_CASE_IDS = {"rain_duration", "rain_no_weather", "snow_duration", "snow_no_weather",
                "weight_grass_knot", "weight_tackle_control"}
BLOCK_03_CASES = {"dice_bullet_seed", "dice_tackle_control", "misty_seed_trigger",
                  "misty_seed_wrong_terrain", "power_herb_solar_beam", "power_herb_noncharge"}
EXPECTED_FOE_MOVES = {"weight_grass_knot": "grass_knot", "weight_tackle_control": "tackle",
                      "misty_seed_trigger": "misty_terrain", "misty_seed_wrong_terrain": "electric_terrain"}
MODES = ("active", "none", "reserve")
CHECKS = 0

def require(test: bool, message: str):
    global CHECKS
    CHECKS += 1
    if not test:
        raise ValueError(message)

def read_rows(path: Path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))

def blob_sha(path: Path):
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()

def validate():
    queue = read_rows(QUEUE)
    progress = read_rows(PROGRESS)
    require(len(queue) == 10 and all(x["trabajadora"] == "W01" for x in queue), "Cola de W01 inválida")
    require(len(progress) == 3, "El contrato exige exactamente los bloques 01 a 03")
    require(progress[0]["bloque"] == "01" and progress[0]["ids"] == "light_ball;lucky_punch;thick_club", "Progreso distinto a W01/01")
    require(progress[0]["ids"] == queue[0]["ids"], "Bloque 01 distinto de cola árbitra")
    require(progress[0]["estado"] == "CI_PASS_VERIFICADO" and progress[0]["ci_run"] == "41580332632",
            "Bloque 01 sin certificado CI oficial")
    require(progress[1]["bloque"] == "02" and progress[1]["ids"] == queue[1]["ids"],
            "Bloque 02 no coincide con la cola autorizada")
    require(progress[1]["estado"] == "CI_PASS_VERIFICADO"
            and progress[1]["ci_run"] == "41584708689"
            and progress[1]["sha_pruebas"] == "970db4c7696364cc1c5ebaf51719405d60430af0",
            "Bloque 02 sin certificado CI oficial")
    require(progress[2]["bloque"] == "03" and progress[2]["ids"] == queue[2]["ids"],
            "Bloque 03 fuera de cola W01")
    require(progress[2]["estado"] in ("EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "CI_PASS_VERIFICADO"),
            "Estado del bloque 03 inválido")
    require(all(row["sha_pruebas"] and row["ci_run"] for row in progress), "Progreso sin trazabilidad")
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    require(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_004" and fixture["worker"] == "W01", "Identidad de fixture incorrecta")
    require(fixture["scope"] == "HELD_COMBAT_CANDIDATE" and fixture["format"] == "gen9calvounifiedv1", "Motor o familia no permitidos")
    require(tuple(fixture["variants"]) == MODES, "Faltan los tres controles activo/ausente/reserva")
    require(len(fixture["blocks"]) == 3 and [b["block"] for b in fixture["blocks"]] == ["01", "02", "03"],
            "Fixture debe contener exactamente los bloques 01 a 03")
    require(fixture["blocks"][0]["ids"] == queue[0]["ids"].split(";"), "Propiedad de IDs alterada")
    require(fixture["blocks"][1]["ids"] == queue[1]["ids"].split(";"), "IDs del bloque 02 alterados")
    require(set(fixture["blocks"][1]["cases"]) == NEW_CASE_IDS, "Casos del bloque 02 incompletos")
    require(fixture["blocks"][2]["ids"] == queue[2]["ids"].split(";"), "IDs del bloque 03 alterados")
    require(set(fixture["blocks"][2]["cases"]) == BLOCK_03_CASES, "Casos del bloque 03 incompletos")
    require(len(fixture["cases"]) == len(EXPECTED) == 20, "Se exigen veinte casos, no duplicados")
    require(set(fixture["blocks"][0]["cases"]) == set(EXPECTED) - NEW_CASE_IDS - BLOCK_03_CASES,
            "Falta caso original del bloque 01")
    require(len(fixture["sources"]) == len(REFS), "Fuentes añadidas o omitidas")
    for source in fixture["sources"]:
        path = source["path"]
        require(path in REFS, "Fuente fuera de inventario: " + path)
        require(source["git_blob_sha"] == REFS[path], "Hash declarado incorrecto: " + path)
        require(blob_sha(ROOT / path) == REFS[path], "Fuente canónica cambiada: " + path)
    scope = {r["id"]: r for r in read_rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
    inventory = {r["id"]: r for r in read_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    canonical = {"light_ball": "lightball", "lucky_punch": "luckypunch",
                 "thick_club": "thickclub", "damp_rock": "damprock",
                 "float_stone": "floatstone", "icy_rock": "icyrock",
                 "loaded_dice": "loadeddice", "misty_seed": "mistyseed", "power_herb": "powerherb"}
    for stage in queue[:3]:
        for item in stage["ids"].split(";"):
            require(scope[item]["estado_contenido"] == "SELECCIONADO", "Item no seleccionado: " + item)
            require(inventory[item]["family"] == "HELD_COMBAT_CANDIDATE", "Familia incompatible: " + item)
            require(inventory[item]["native_id"] == canonical[item], "Clave nativa incorrecta: " + item)
    require("onModifyWeight" in inventory["float_stone"]["native_hooks"],
            "Piedra Pómez sin gancho nativo de peso")
    require("onModifyMove" in inventory["loaded_dice"]["native_hooks"],
            "Dado Trucado sin gancho nativo de golpes múltiples")
    require("onTerrainChange" in inventory["misty_seed"]["native_hooks"],
            "Semilla Bruma sin gancho nativo de terreno")
    require("onChargeMove" in inventory["power_herb"]["native_hooks"],
            "Hierba Única sin gancho nativo de carga")
    historical_v2 = (ROOT / "tools/item_audit/held_effect_sweep_v2.cjs").read_text(encoding="utf-8")
    pilot = (ROOT / "tools/item_audit/held_pilot.cjs").read_text(encoding="utf-8")
    require("add('loaded_dice','multi_hit_bound'" in historical_v2
            and "['bullet_seed']" in historical_v2 and "'|-hitcount|'" in historical_v2,
            "Sin referencia nativa de Dado Trucado y su contador de impactos")
    require("power_herb:{moves:['solar_beam']" in pilot,
            "Sin referencia nativa de Hierba Única que evita carga")
    historical = NATIVE.read_text(encoding="utf-8")
    for fragment in (
        "['light_ball','pikachu','thunder_shock']",
        "['light_ball','pikachu','tackle']",
        "['thick_club','cubone','tackle']",
        "['thick_club','marowak','tackle']",
        "id==='lucky_punch'?'chansey'",
        "moves:['focus_energy','tackle']",
        "add(id,'wrong_species'",
        "add(id,'wrong_holder_",
        "add('float_stone','weight_threshold'",
        "add('float_stone','fixed_power_control'",
        "['damp_rock','rain_dance']",
        "['icy_rock','snowscape']",
    ):
        require(fragment in historical, "Referencia histórica sin contrato: " + fragment)
    seen = set()
    pairs = 0
    for case in fixture["cases"]:
        name = case["id"]
        require(name in EXPECTED and name not in seen, "Caso no autorizado o duplicado: " + name)
        seen.add(name)
        expected_block = "03" if name in BLOCK_03_CASES else ("02" if name in NEW_CASE_IDS else "01")
        require(case["block"] == expected_block, "Caso fuera de bloque " + expected_block)
        actual = (case["item_id"], case["op"], case["actor_species"], case["own_move"],
                  case.get("follow_move", ""), tuple(case["seeds"]))
        require(actual == EXPECTED[name], "Condiciones de mecánica y semillas alteradas: " + name)
        require(case["foe_species"] == "mew" and
                case["foe_move"] == EXPECTED_FOE_MOVES.get(name, "amnesia"),
                "Rival o movimiento alterado: " + name)
        origin = ("held_effect_sweep_v2:" if case["item_id"] == "loaded_dice" else
                  "held_pilot:" if case["item_id"] == "power_herb" else "held_effect_sweep_v3:")
        require(case["history"].startswith(origin), "Sin referencia de origen: " + name)
        require(all(type(i) is int and 1 <= i <= 65535 for i in case["seeds"]), "Semilla inválida: " + name)
        require(len(case["seeds"]) == len(set(case["seeds"])), "Semillas repetidas: " + name)
        if case["item_id"] == "lucky_punch":
            require(case["follow_move"] == "tackle" and case["own_move"] == "focus_energy",
                    "Puño Suerte sin secuencia de crítico real")
        else:
            require("follow_move" not in case, "Secuencia extra no permitida")
        pairs += len(case["seeds"])
    require(len(seen) == 20 and pairs == 62, "Matriz debe tener 20 casos y 62 pares")
    runner = (ROOT / "tests/gameplay/parallel_items_w01_campaign_004.gd").read_text(encoding="utf-8")
    for fragment in ("Native.new(catalogs, owner, automation.format)",
                     "await _restore_probe(", "session.submit(", "session._checkpoint",
                     "_compare_c004(", "CAMP004_W01_GODOT PASS"):
        require(fragment in runner, "Falta ruta de validación real: " + fragment)
    return len(progress)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    parser.parse_args()
    global CHECKS
    try:
        blocks = validate()
    except (KeyError, OSError, ValueError, TypeError, json.JSONDecodeError) as error:
        print("CAMP004_W01_PY FAIL:", str(error))
        return 1
    print(f"CAMP004_W01_PY PASS blocks={blocks} checks={CHECKS}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
