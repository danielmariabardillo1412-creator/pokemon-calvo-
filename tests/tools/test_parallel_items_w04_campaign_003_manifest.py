#!/usr/bin/env python3
"""IA6: gate de cola aditiva W04 para CAMP003, sin alterar las 4 ramas activas."""
import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
SIDE = BASE / "CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv"
BASE_QUEUE = BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
OLD = BASE / "CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv"
PROGRESS = BASE / "reports/W04/CAMP_003_PROGRESO.csv"
VALID_STATUS = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}
PREVIOUS_STONES = {"fire_stone", "water_stone", "thunder_stone", "leaf_stone", "ice_stone", "moon_stone"}

def read(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

def validate():
    tasks = read(SIDE)
    all_tasks = read(BASE_QUEUE)
    if len(all_tasks) != 40 or len(tasks) != 10:
        raise ValueError("Drift de la cola original de 40 o ampliacion W04 de 10")
    old_ids = {item for task in all_tasks for item in task["ids"].split(";")}
    ids = [item for task in tasks for item in task["ids"].split(";")]
    if len(old_ids) != 150 or len(ids) != 30 or len(set(ids)) != 30:
        raise ValueError("Censo de reservas W04 inesperado")
    if set(ids) & old_ids:
        raise ValueError("Colision de IDs entre trabajadoras")
    if set(ids) & PREVIOUS_STONES:
        raise ValueError("Se han reasignado las seis piedras de CAMPAÑA_001")
    selected = {x["id"] for x in read(SCOPE) if x["estado_contenido"] == "SELECCIONADO" and x["familia"] == "EVOLUTION"}
    used = {x["id"] for x in read(OLD)}
    if not set(ids) <= selected or set(ids) & used:
        raise ValueError("ID de evolucion no seleccionado o repetido de CAMP001")
    if [row["bloque"] for row in tasks] != [f"{i:02d}" for i in range(1, 11)]:
        raise ValueError("Diez bloques W04 fuera de secuencia")
    for task in tasks:
        if task["trabajadora"] != "W04" or task["familia"] != "EVOLUTION" or len(task["ids"].split(";")) != 3:
            raise ValueError("Fila fuera del contrato de W04")
    done = read(PROGRESS)
    if len(done) > 10:
        raise ValueError("Exceso de microbloques de W04")
    for i, row in enumerate(done):
        if row["bloque"] != tasks[i]["bloque"] or row["ids"] != tasks[i]["ids"]:
            raise ValueError(f"Progreso distinto de la reserva en bloque {i+1}")
        if row["estado"] not in VALID_STATUS:
            raise ValueError("Estado de progreso no autorizado")
    return len(done)

def receipt(n, kind, path):
    txt = Path(path).read_text(encoding="utf-8", errors="replace")
    pattern = "^CAMP003_W04_" + re.escape(kind) + " PASS blocks=([0-9]+) checks=([0-9]+)[ \\t]*$"
    got = re.findall(pattern, txt, re.MULTILINE)
    if not got or int(got[-1][0]) != n or int(got[-1][1]) < 1:
        raise ValueError("Recibo "+kind+" falta o declara bloques/checks incorrectos")
    print(f"CAMP003_W04_GATE_{kind}_PASS blocks={n} checks={got[-1][1]}")

if __name__ == "__main__":
    cli=argparse.ArgumentParser()
    cli.add_argument("--count-only", action="store_true")
    cli.add_argument("--verify-output", choices=("PY", "GODOT"))
    cli.add_argument("--log")
    a=cli.parse_args()
    try:
        n=validate()
        if a.verify_output:
            if n < 1 or not a.log:
                raise ValueError("Sin bloques ni registro de pruebas")
            receipt(n, a.verify_output, a.log)
        elif a.count_only:
            print(n)
        else:
            print(f"CAMP003_W04_MANIFEST_PASS reserved=10 completed={n} ids=30")
            if n==0:
                print("BOOTSTRAP_NO_FUNCIONAL")
    except (ValueError, KeyError, FileNotFoundError) as exc:
        print("CAMP003_W04_MANIFEST_FAIL:", str(exc), file=sys.stderr)
        sys.exit(1)
