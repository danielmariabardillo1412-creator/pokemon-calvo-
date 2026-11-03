#!/usr/bin/env python3
"""IA6: W02 CAMP004, identidad/reservas/progreso. No certifica comportamiento."""
from __future__ import annotations
import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W02_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W02/CAMP_004_PROGRESO.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
OLD_QUEUE = BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv"
OLD_OVERLAY = BASE / "CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv"
VALID = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
         "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}

def read(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

def validate(worker):
    if worker != "W02":
        raise ValueError("Identidad no autorizada: " + worker)
    queue = read(QUEUE)
    if len(queue) != 10 or [(r["trabajadora"], r["bloque"]) for r in queue] != [
        ("W02", f"{n:02d}") for n in range(1, 11)]:
        raise ValueError("La cola W02 no contiene 10 bloques ordenados")
    selected = {r["id"]: r["familia"] for r in read(SCOPE)}
    old_ids = {id for row in read(OLD_QUEUE) for id in row["ids"].split(";")}
    old_ids |= {r["id"] for r in read(OLD_OVERLAY) if r["trabajador"] == "W02"}
    seen = set()
    for i, row in enumerate(queue):
        family = "BERRY" if i < 2 else "MEDICINE"
        ids = row["ids"].split(";")
        if row["familia"] != family or len(ids) != 4:
            raise ValueError("Familia/cuota incorrecta en bloque " + row["bloque"])
        for item in ids:
            if item in seen or item in old_ids:
                raise ValueError("ID duplicado o previamente cubierto: " + item)
            if selected.get(item) != family:
                raise ValueError("ID fuera del alcance seleccionado: " + item)
            seen.add(item)
    if len(seen) != 40:
        raise ValueError("Se requieren exactamente 40 IDs únicos")
    progress = read(PROGRESS)
    if len(progress) > 10:
        raise ValueError("Más de diez bloques entregados")
    for i, row in enumerate(progress):
        if row["bloque"] != queue[i]["bloque"] or row["ids"] != queue[i]["ids"]:
            raise ValueError("Drift de progreso en bloque " + str(i+1))
        if row["estado"] not in VALID:
            raise ValueError("Estado inválido")
    return len(progress)

def verify(worker, blocks, kind, logfile):
    content = Path(logfile).read_text(encoding="utf-8", errors="replace")
    matches = re.findall(rf"^CAMP004_{re.escape(worker)}_{re.escape(kind)} PASS blocks=(\d+) checks=(\d+)\s*$",
                         content, re.MULTILINE)
    if not matches or int(matches[-1][0]) != blocks or int(matches[-1][1]) < 1:
        raise ValueError("No existe recibo real para bloque y tipo solicitado")
    print(f"CAMP004_GATE_{kind}_PASS worker={worker} blocks={blocks} checks={matches[-1][1]}")

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--worker", required=True)
    p.add_argument("--count-only", action="store_true")
    p.add_argument("--verify-output", choices=("PY", "GODOT"))
    p.add_argument("--log")
    a = p.parse_args()
    try:
        n = validate(a.worker)
        if a.verify_output:
            if not a.log or n < 1:
                raise ValueError("Recibo funcional requiere al menos un bloque")
            verify(a.worker, n, a.verify_output, a.log)
        elif a.count_only:
            print(n)
        else:
            print(f"CAMP004_MANIFEST_VALID worker={a.worker} approved=10 completed={n}")
            if n == 0:
                print("BOOTSTRAP_NO_FUNCIONAL")
        return 0
    except (ValueError, KeyError, OSError) as e:
        print("CAMP004_GATE_FAIL: " + str(e), file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
