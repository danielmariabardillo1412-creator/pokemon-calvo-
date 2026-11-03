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
OPERATIONS = {r[1] for r in SCENARIOS_01.values()}
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
    cases = document["cases"]
    require(type(cases) is list and len(cases) >= 7, "Sin casos suficientes")
    found, pairs = set(), set()
    per_id = {}
    stage_map = {r["bloque"]: set(r["ids"].split(";")) for r in tasks[:len(progress)]}
    for case in cases:
        require(type(case) is dict and set(case) == REQUIRED_CASE_FIELDS, "Caso con forma inválida")
        name, stage, item = case["id"], case["block"], case["item_id"]
        require(type(name) is str and name not in found and stage in stage_map
                and item in stage_map[stage], "Caso duplicado/fuera de encargo")
        found.add(name)
        require(case["actor_species"] == "mew" and type(case["history"]) is str
                and len(case["history"]) >= 8, "Especie/historial no justificado")
        require(case["op"] in OPERATIONS, "Operacion no implementada por runner: "+case["op"])
        require(type(case["seeds"]) is list and 1 <= len(case["seeds"]) <= 4,
                "Semillas ausentes o excesivas")
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
    for stage, ids in stage_map.items():
        for item in ids:
            require((stage,item) in per_id, "Objeto sin caso de test: "+item)
    require(set(SCENARIOS_01) <= found, "Faltan 7 casos obligatorios del bloque 01")
    if len(progress) == 1:
        require(len(cases) == 7 and len(pairs) == 10, "Matriz inicial 7/10 alterada")
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
