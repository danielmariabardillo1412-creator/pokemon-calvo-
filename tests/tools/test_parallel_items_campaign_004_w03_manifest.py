#!/usr/bin/env python3
"""IA6: puerta de identidad, reserva y contabilidad W03 CAMP004.
No certifica efectos; los tests funcionales son runners de cada bloque.
"""
from __future__ import annotations
import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W03_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W03/CAMP_004_PROGRESO.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
OLDQUEUE = BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv"
OLDOVERLAY = BASE / "CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv"
STATES = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI", "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}

def load(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as file:
        return list(csv.DictReader(file))

def validate(worker: str) -> int:
    if worker != "W03":
        raise ValueError("Identidad no autorizada: " + worker)
    queue = load(QUEUE)
    if len(queue) != 10 or [(r["trabajadora"], r["bloque"]) for r in queue] != [
            ("W03", f"{i:02d}") for i in range(1, 11)]:
        raise ValueError("Deriva en cola W03: deben existir diez bloques consecutivos")
    scope = {r["id"]: r["familia"] for r in load(SCOPE)}
    previously_assigned = {id for r in load(OLDQUEUE) for id in r["ids"].split(";")}
    previously_covered = {r["id"] for r in load(OLDOVERLAY) if r["trabajador"] == "W03"}
    expected = ["CAPTURE_BALL"] + ["FIELD_USE"] * 5 + ["TERA_MATERIAL"] * 4
    amounts = [3] + [3] * 5 + [5, 5, 4, 4]
    seen = set()
    for i, row in enumerate(queue):
        ids = row["ids"].split(";")
        if row["familia"] != expected[i] or len(ids) != amounts[i]:
            raise ValueError(f"Familia o cuota incorrecta en bloque {i+1:02d}")
        for id in ids:
            if not id or id in seen or id in previously_assigned or id in previously_covered:
                raise ValueError("ID duplicado o historico: " + id)
            if scope.get(id) != expected[i]:
                raise ValueError("ID no seleccionado en familia: " + id)
            seen.add(id)
    if len(seen) != 36:
        raise ValueError("Censo diferente de 36 IDs")
    progress = load(PROGRESS)
    if len(progress) > 10:
        raise ValueError("Mas de diez bloques en progreso")
    for i, r in enumerate(progress):
        if r["bloque"] != queue[i]["bloque"] or r["ids"] != queue[i]["ids"]:
            raise ValueError("Progreso fuera de orden/autorizacion")
        if r["estado"] not in STATES:
            raise ValueError("Estado de progreso invalido")
    return len(progress)

def check_receipt(worker: str, n: int, kind: str, log: str) -> None:
    content = Path(log).read_text(encoding="utf-8", errors="replace")
    found = re.findall(rf"^CAMP004_{re.escape(worker)}_{re.escape(kind)} PASS blocks=(\d+) checks=(\d+)\s*$", content, re.MULTILINE)
    if not found or int(found[-1][0]) != n or int(found[-1][1]) < 1:
        raise ValueError("No hay recibo funcional valido en SHA actual")
    print(f"CAMP004_GATE_{kind}_PASS worker={worker} blocks={n} checks={found[-1][1]}")

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--worker", required=True)
    p.add_argument("--count-only", action="store_true")
    p.add_argument("--verify-output", choices=("PY", "GODOT"))
    p.add_argument("--log")
    args = p.parse_args()
    try:
        blocks = validate(args.worker)
        if args.verify_output:
            if not args.log or not blocks:
                raise ValueError("Recibo requiere >= 1 bloque")
            check_receipt(args.worker, blocks, args.verify_output, args.log)
        elif args.count_only:
            print(blocks)
        else:
            print(f"CAMP004_MANIFEST_VALID worker={args.worker} approved=10 completed={blocks}")
            if blocks == 0:
                print("BOOTSTRAP_NO_FUNCIONAL")
        return 0
    except (OSError, ValueError, KeyError) as error:
        print("CAMP004_GATE_FAIL: " + str(error), file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
