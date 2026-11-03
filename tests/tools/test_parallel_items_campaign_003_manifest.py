#!/usr/bin/env python3
"""IA6: contrato no funcional, por rama, de la cola autorizada CAMP_003."""
import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUEUE = ROOT / "docs/coordination/items_parallel_v1/CAMPAIGN_003_QUEUE_APPROVED.csv"
VALID = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}
WORKERS = ("W01", "W02", "W03", "W05")

def read_csv(path):
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))

def validate(worker):
    if worker not in WORKERS:
        raise ValueError("Identidad no autorizada: " + worker)
    rows = read_csv(QUEUE)
    if len(rows) != 40 or len({(r["trabajadora"], r["bloque"]) for r in rows}) != 40:
        raise ValueError("Drift en cola global de 40 tareas")
    ids = [x for row in rows for x in row["ids"].split(";")]
    if len(ids) != len(set(ids)) or len(ids) != 150:
        raise ValueError("IDs duplicados o censo desviado")
    tasks = [r for r in rows if r["trabajadora"] == worker]
    if [r["bloque"] for r in tasks] != [f"{i:02d}" for i in range(1, 11)]:
        raise ValueError("Los diez bloques de la trabajadora no son contiguos")
    progress = ROOT / f"docs/coordination/items_parallel_v1/reports/{worker}/CAMP_003_PROGRESO.csv"
    done = read_csv(progress)
    if len(done) > 10:
        raise ValueError("Más de diez bloques entregados")
    for i, row in enumerate(done):
        task = tasks[i]
        if row["bloque"] != task["bloque"] or row["ids"] != task["ids"]:
            raise ValueError(f"Progreso no coincide con la reserva de bloque {i+1}")
        if row["estado"] not in VALID:
            raise ValueError(f"Estado de progreso inválido en bloque {i+1}")
    return len(done)

def verify_output(worker, blocks, kind, logfile):
    actual = Path(logfile).read_text(encoding="utf-8", errors="replace")
    pattern = rf"^CAMP003_{re.escape(worker)}_{re.escape(kind)} PASS blocks=(\d+) checks=(\d+)\s*$"
    matches = re.findall(pattern, actual, re.MULTILINE)
    if not matches:
        raise ValueError(f"Falta recibo explícito de {kind} — no se puede declarar PASS")
    if int(matches[-1][0]) != blocks or int(matches[-1][1]) <= 0:
        raise ValueError(f"Recibo de {kind} no corresponde a {blocks} bloques con comprobaciones reales")
    print(f"CAMP003_GATE_{kind}_PASS worker={worker} blocks={blocks} checks={matches[-1][1]}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--worker", required=True)
    p.add_argument("--count-only", action="store_true")
    p.add_argument("--verify-output", choices=("PY", "GODOT"))
    p.add_argument("--log")
    args = p.parse_args()
    try:
        n = validate(args.worker)
        if args.verify_output:
            if not args.log or n < 1:
                raise ValueError("Se requieren bloques entregados y ruta de registro")
            verify_output(args.worker, n, args.verify_output, args.log)
        elif args.count_only:
            print(n)
        else:
            print(f"CAMP003_MANIFEST_VALID worker={args.worker} approved=10 completed={n}")
            if n == 0:
                print("BOOTSTRAP_ONLY_NO_FUNCTIONAL_CI")
    except (ValueError, KeyError, FileNotFoundError) as exc:
        print("CAMP003_GATE_FAIL: " + str(exc), file=sys.stderr)
        sys.exit(1)
