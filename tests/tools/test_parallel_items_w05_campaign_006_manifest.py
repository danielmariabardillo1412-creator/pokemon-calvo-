#!/usr/bin/env python3
"""IA5/W05 CAMP006: gate de 49 máquinas SV, bloques reales y recibos CI."""
from __future__ import annotations
import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
WORKER = "W05"
QUEUE = BASE / "CAMPAIGN_006_W05_QUEUE_APPROVED.csv"
PROGRESS = BASE / "reports/W05/CAMP_006_PROGRESO.csv"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w05_campaign_006.json"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
PREVIOUS = (
    BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv",
    BASE / "CAMPAIGN_004_W05_QUEUE_APPROVED.csv",
    BASE / "CAMPAIGN_005_W05_QUEUE_APPROVED.csv",
)
STATES = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
          "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}


def read_csv(path: Path) -> list[dict]:
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def validate() -> int:
    rows = read_csv(QUEUE)
    if len(rows) != 10 or [r["bloque"] for r in rows] != [f"{i:02d}" for i in range(1, 11)]:
        raise ValueError("Cola CAMP006 debe contener diez bloques ordenados")
    if any(r["trabajadora"] != WORKER or r["tipo"] != "NEW_IDS"
           or r["familia"] != "MACHINE_SV" for r in rows):
        raise ValueError("Identidad o familia ajena en cola")
    scope = {r["id"]: r["familia"] for r in read_csv(SCOPE)
             if r["estado_contenido"] == "SELECCIONADO"}
    previous: set[str] = set()
    for path in PREVIOUS:
        previous.update(x for r in read_csv(path) if r["trabajadora"] == WORKER
                        for x in r["ids"].split(";"))
    data = json.loads(PROFILE.read_text(encoding="utf-8"))
    if data.get("active_machine_version") != "scarlet-violet":
        raise ValueError("Perfil de máquinas no activo SV")
    mappings = data["machine_rows"]
    unique: set[str] = set()
    for i, row in enumerate(rows, 1):
        ids = row["ids"].split(";")
        needed = 4 if i == 10 else 5
        if len(ids) != needed or len(set(ids)) != needed:
            raise ValueError(f"Cuota/duplicados incorrectos bloque {i:02d}")
        for item in ids:
            if item in unique or item in previous or scope.get(item) != "MACHINE":
                raise ValueError("ID duplicado, ya cubierto o no seleccionado: " + item)
            if not mappings.get(item, {}).get("scarlet-violet"):
                raise ValueError("MT inactiva o sin mapeo SV: " + item)
            unique.add(item)
    if len(unique) != 49:
        raise ValueError(f"Se esperaban 49 MT y aparecen {len(unique)}")

    fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
    if (fixture.get("schema_version") != 1 or fixture.get("campaign") != "CAMP_006"
            or fixture.get("worker") != WORKER or fixture.get("kind") != "NEW_IDS"
            or fixture.get("active_version") != "scarlet-violet"):
        raise ValueError("Fixture W05 CAMP006 ajeno o inválido")
    blocks = fixture.get("blocks")
    done = read_csv(PROGRESS)
    if not isinstance(blocks, list) or len(done) != len(blocks) or len(done) > 10:
        raise ValueError("El progreso no coincide con los bloques de fixture")
    for index, (r, group) in enumerate(zip(done, blocks, strict=True)):
        authorized = rows[index]
        ids = authorized["ids"].split(";")
        if (r["bloque"] != authorized["bloque"] or r["ids"] != authorized["ids"]
                or r["estado"] not in STATES or group.get("block") != authorized["bloque"]):
            raise ValueError("Progreso no autorizado en " + authorized["bloque"])
        cases = group.get("items")
        if not isinstance(cases, list) or [c.get("item_id") for c in cases] != ids:
            raise ValueError("Fixture distinto a la fila IA6 en " + authorized["bloque"])
        for case in cases:
            if mappings[case["item_id"]]["scarlet-violet"] != case.get("move_id"):
                raise ValueError("Movimiento no canónico: " + case["item_id"])
    return len(done)


def receipt(n: int, kind: str, logpath: str) -> None:
    log = Path(logpath).read_text(encoding="utf-8", errors="replace")
    pairs = re.findall(
        rf"^CAMP006_{WORKER}_{re.escape(kind)} PASS blocks=(\d+) checks=(\d+)\s*$",
        log, flags=re.MULTILINE)
    if not pairs or int(pairs[-1][0]) != n or int(pairs[-1][1]) <= 0:
        raise ValueError("Falta recibo real " + kind)
    print(f"CAMP006_GATE_{kind}_PASS worker={WORKER} blocks={n} checks={pairs[-1][1]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--count-only", action="store_true")
    parser.add_argument("--verify-output", choices=("PY", "GODOT"))
    parser.add_argument("--log")
    args = parser.parse_args()
    try:
        n = validate()
        if args.verify_output:
            if not args.log or n == 0:
                raise ValueError("No se validan recibos de bootstrap")
            receipt(n, args.verify_output, args.log)
        elif args.count_only:
            print(n)
        else:
            print(f"CAMP006_W05_MANIFEST_PASS reserved=10 completed={n} ids=49 kind=NEW_IDS")
            if n == 0:
                print("BOOTSTRAP_NO_FUNCIONAL")
        return 0
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(f"CAMP006_W05_MANIFEST_FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
