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
}
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
    require(len(progress) == 1, "Esta versión del contrato solo admite bloque 01 autorizado")
    require(progress[0]["bloque"] == "01" and progress[0]["ids"] == "light_ball;lucky_punch;thick_club", "Progreso distinto a W01/01")
    require(progress[0]["ids"] == queue[0]["ids"], "Bloque 01 distinto de cola árbitra")
    require(progress[0]["estado"] in ("EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "CI_PASS_VERIFICADO"), "Estado inválido")
    require(progress[0]["sha_pruebas"] and progress[0]["ci_run"], "Progreso sin trazabilidad")
    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    require(fixture["schema_version"] == 1 and fixture["campaign"] == "CAMP_004" and fixture["worker"] == "W01", "Identidad de fixture incorrecta")
    require(fixture["scope"] == "HELD_COMBAT_CANDIDATE" and fixture["format"] == "gen9calvounifiedv1", "Motor o familia no permitidos")
    require(tuple(fixture["variants"]) == MODES, "Faltan los tres controles activo/ausente/reserva")
    require(len(fixture["blocks"]) == 1 and fixture["blocks"][0]["block"] == "01", "Fixture contiene bloque ajeno")
    require(fixture["blocks"][0]["ids"] == queue[0]["ids"].split(";"), "Propiedad de IDs alterada")
    require(len(fixture["cases"]) == len(EXPECTED) == 8, "Se exigen ocho casos, no duplicados")
    require(set(fixture["blocks"][0]["cases"]) == set(EXPECTED), "Falta caso del manifiesto")
    require(len(fixture["sources"]) == len(REFS), "Fuentes añadidas o omitidas")
    for source in fixture["sources"]:
        path = source["path"]
        require(path in REFS, "Fuente fuera de inventario: " + path)
        require(source["git_blob_sha"] == REFS[path], "Hash declarado incorrecto: " + path)
        require(blob_sha(ROOT / path) == REFS[path], "Fuente canónica cambiada: " + path)
    scope = {r["id"]: r for r in read_rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
    inventory = {r["id"]: r for r in read_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    for item in queue[0]["ids"].split(";"):
        require(scope[item]["estado_contenido"] == "SELECCIONADO", "Item no seleccionado: " + item)
        require(inventory[item]["family"] == "HELD_COMBAT_CANDIDATE", "Familia incompatible: " + item)
        require(inventory[item]["native_id"] in ("lightball", "luckypunch", "thickclub"), "Clave nativa ausente: " + item)
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
    ):
        require(fragment in historical, "Referencia histórica sin contrato: " + fragment)
    seen = set()
    pairs = 0
    for case in fixture["cases"]:
        name = case["id"]
        require(name in EXPECTED and name not in seen, "Caso no autorizado o duplicado: " + name)
        seen.add(name)
        require(case["block"] == "01", "Caso fuera de bloque 01")
        actual = (case["item_id"], case["op"], case["actor_species"], case["own_move"],
                  case.get("follow_move", ""), tuple(case["seeds"]))
        require(actual == EXPECTED[name], "Condiciones de mecánica y semillas alteradas: " + name)
        require(case["foe_species"] == "mew" and case["foe_move"] == "amnesia", "Rival alterado: " + name)
        require(case["history"].startswith("held_effect_sweep_v3:"), "Sin referencia de origen: " + name)
        require(all(type(i) is int and 1 <= i <= 65535 for i in case["seeds"]), "Semilla inválida: " + name)
        require(len(case["seeds"]) == len(set(case["seeds"])), "Semillas repetidas: " + name)
        if case["item_id"] == "lucky_punch":
            require(case["follow_move"] == "tackle" and case["own_move"] == "focus_energy",
                    "Puño Suerte sin secuencia de crítico real")
        else:
            require("follow_move" not in case, "Secuencia extra no permitida")
        pairs += len(case["seeds"])
    require(len(seen) == 8 and pairs == 34, "Matriz debe tener 8 casos y 34 pares")
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
