#!/usr/bin/env python3
"""IA6: gate de W04 CAMPAÑA_004; identidad/reserva e integridad, NO función."""
from __future__ import annotations
import argparse
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
QUEUE = BASE / "CAMPAIGN_004_W04_QUEUE_APPROVED.csv"
OLD_W04 = BASE / "CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv"
OLD_GLOBAL = BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv"
OLD_W02 = BASE / "CAMPAIGN_004_W02_QUEUE_APPROVED.csv"
OLD_W03 = BASE / "CAMPAIGN_004_W03_QUEUE_APPROVED.csv"
OLD_W05 = BASE / "CAMPAIGN_004_W05_QUEUE_APPROVED.csv"
OLD_OVERLAY = BASE / "CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
PROGRESS = BASE / "reports/W04/CAMP_004_PROGRESO.csv"
STATES = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
          "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}
FAMILIES = (
    {"EVOLUTION"}, {"EVOLUTION"}, {"EVOLUTION", "FOOD_OR_PICNIC_ACTIVITY"},
    *({"STORY_KEY_OR_FORM_REVIEW"} for _ in range(5)),
    {"LEGACY_OR_CATEGORY_REVIEW"}, {"TREASURE_OR_COLLECTIBLE"},
)
COUNTS = (3, 3, 3, 3, 3, 3, 3, 3, 5, 7)

def read(path: Path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))

def validate() -> int:
    queue = read(QUEUE)
    if len(queue) != 10 or [(r["bloque"], r["trabajadora"]) for r in queue] != [
            (f"{i:02d}", "W04") for i in range(1, 11)]:
        raise ValueError("Cola W04 no tiene 10 bloques ordenados")
    selected = {r["id"]: r["familia"] for r in read(SCOPE) if r["estado_contenido"] == "SELECCIONADO"}
    previous = set()
    for source in (OLD_W04, OLD_GLOBAL, OLD_W02, OLD_W03, OLD_W05):
        for row in read(source):
            previous.update(row["ids"].split(";"))
    previous.update(r["id"] for r in read(OLD_OVERLAY) if r["trabajador"] == "W04")
    seen = set()
    for n, row in enumerate(queue):
        ids = row["ids"].split(";")
        if len(ids) != COUNTS[n] or not ids or len(set(ids)) != len(ids):
            raise ValueError(f"Cuota inválida en {n+1:02d}")
        actual_families = {selected.get(item) for item in ids}
        if not actual_families <= FAMILIES[n] or None in actual_families:
            raise ValueError(f"Familia incorrecta en {n+1:02d}")
        for item in ids:
            if item in seen or item in previous:
                raise ValueError("Duplicado o reserva antigua: " + item)
            seen.add(item)
    if len(seen) != 36:
        raise ValueError("La cola no contiene 36 IDs únicos")
    progress = read(PROGRESS)
    if len(progress) > 10:
        raise ValueError("Se publicaron más de diez bloques")
    for n, row in enumerate(progress):
        if row["bloque"] != queue[n]["bloque"] or row["ids"] != queue[n]["ids"]:
            raise ValueError(f"Progreso fuera de orden en {n+1:02d}")
        if row["estado"] not in STATES:
            raise ValueError(f"Estado no autorizado en {n+1:02d}")
    return len(progress)

def verify(n: int, kind: str, logfile: str):
    actual = Path(logfile).read_text(encoding="utf-8", errors="replace")
    got = re.findall(rf"^CAMP004_W04_{re.escape(kind)} PASS blocks=(\d+) checks=(\d+)\s*$",
                     actual, re.MULTILINE)
    if not got or int(got[-1][0]) != n or int(got[-1][1]) <= 0:
        raise ValueError("Recibo real no coincide con el bloque, clase o comprobaciones")
    print(f"CAMP004_W04_GATE_{kind}_PASS blocks={n} checks={got[-1][1]}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--count-only", action="store_true")
    parser.add_argument("--verify-output", choices=("PY", "GODOT"))
    parser.add_argument("--log")
    a = parser.parse_args()
    try:
        n = validate()
        if a.verify_output:
            if n < 1 or not a.log:
                raise ValueError("Sin bloque o ruta de registros para verificar funcionalidad")
            verify(n, a.verify_output, a.log)
        elif a.count_only:
            print(n)
        else:
            print(f"CAMP004_W04_MANIFEST_PASS reserved=10 completed={n} ids=36")
            if n == 0:
                print("BOOTSTRAP_NO_FUNCIONAL")
        return 0
    except (ValueError, KeyError, OSError) as exc:
        print("CAMP004_W04_MANIFEST_FAIL:", exc, file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
