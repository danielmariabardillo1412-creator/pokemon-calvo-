#!/usr/bin/env python3
"""IA6: gate estricto de identidad y reservas W01 CAMPAÑA_004.
No certifica la mecánica. Los runners Python/Godot funcionales deben ejecutarse con N >= 1.
"""
from __future__ import annotations
import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W01_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W01/CAMP_004_PROGRESO.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
OVERLAY = BASE / "CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv"
QUEUES = [BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv",
          BASE / "CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv"] + [
    BASE / f"CAMPAIGN_004_{worker}_QUEUE_APPROVED.csv"
    for worker in ("W02", "W03", "W04", "W05")]
PREVIOUS_CAMP002_W01 = {"ability_shield", "absorb_bulb", "adrenaline_orb"}
STATES = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
          "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}

def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

def validate(worker: str) -> int:
    if worker != "W01":
        raise ValueError("Identidad incorrecta. Esta rama pertenece a W01.")
    queue = read_csv(QUEUE)
    if len(queue) != 10 or [(row["bloque"], row["trabajadora"]) for row in queue] != [
            (f"{i:02d}", "W01") for i in range(1, 11)]:
        raise ValueError("Se exigen exactamente 10 filas W01 consecutivas")
    selected = {r["id"]: r["familia"] for r in read_csv(SCOPE)
                if r["estado_contenido"] == "SELECCIONADO"}
    old = {r["id"] for r in read_csv(OVERLAY) if r["trabajador"] == "W01"}
    old |= PREVIOUS_CAMP002_W01
    for path in QUEUES:
        for row in read_csv(path):
            old.update(row["ids"].split(";"))
    seen = set()
    for task in queue:
        ids = task["ids"].split(";")
        if task["familia"] != "HELD_COMBAT_CANDIDATE" or len(ids) != 3 or len(set(ids)) != 3:
            raise ValueError("Alcance de tres equipables no respetado: " + task["bloque"])
        for item in ids:
            if selected.get(item) != "HELD_COMBAT_CANDIDATE":
                raise ValueError("Objeto no seleccionado o fuera de familia: " + item)
            if item in old or item in seen:
                raise ValueError("Duplicado/histórico en reserva W01: " + item)
            seen.add(item)
    if len(seen) != 30:
        raise ValueError("No hay exactamente treinta objetos únicos")
    progress = read_csv(PROGRESS)
    if len(progress) > 10:
        raise ValueError("Se ha excedido el límite de diez bloques")
    for i, row in enumerate(progress):
        if row["bloque"] != queue[i]["bloque"] or row["ids"] != queue[i]["ids"]:
            raise ValueError("Progreso fuera de orden o asignación en fila " + str(i + 1))
        if row["estado"] not in STATES:
            raise ValueError("Estado de progreso incorrecto en fila " + str(i + 1))
    return len(progress)

def verify(worker: str, blocks: int, kind: str, logfile: str) -> None:
    text = Path(logfile).read_text(encoding="utf-8", errors="replace")
    pattern = rf"^CAMP004_{re.escape(worker)}_{re.escape(kind)} PASS blocks=(\d+) checks=(\d+)\s*$"
    found = re.findall(pattern, text, flags=re.MULTILINE)
    if not found or int(found[-1][0]) != blocks or int(found[-1][1]) <= 0:
        raise ValueError("No existe recibo funcional coherente con CI " + kind)
    print(f"CAMP004_GATE_{kind}_PASS worker={worker} blocks={blocks} checks={found[-1][1]}")

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--worker", default="W01")
    p.add_argument("--count-only", action="store_true")
    p.add_argument("--verify-output", choices=("PY", "GODOT"))
    p.add_argument("--log")
    args = p.parse_args()
    try:
        n = validate(args.worker)
        if args.verify_output:
            if n < 1 or not args.log:
                raise ValueError("Recibo funcional sin bloques completos o sin log")
            verify(args.worker, n, args.verify_output, args.log)
        elif args.count_only:
            print(n)
        else:
            print(f"CAMP004_W01_MANIFEST_PASS reserved=10 completed={n} ids=30")
            if n == 0:
                print("BOOTSTRAP_NO_FUNCIONAL")
        return 0
    except (ValueError, KeyError, OSError) as exc:
        print("CAMP004_W01_MANIFEST_FAIL:", str(exc), file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
