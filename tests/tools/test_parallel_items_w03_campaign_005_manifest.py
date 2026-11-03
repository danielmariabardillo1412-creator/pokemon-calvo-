#!/usr/bin/env python3
"""IA6: gate CAMP005 W03. Solo identidad, reserva, progreso y recibos ejecutados."""
from __future__ import annotations
import argparse
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
WORKER = "W03"
KIND = "FUNCTIONAL_BACKLOG"
EXPECTED_IDS = 28
QUEUE = BASE / f"CAMPAIGN_005_{WORKER}_QUEUE_APPROVED.csv"
PROGRESS = BASE / f"reports/{WORKER}/CAMP_005_PROGRESO.csv"
SCOPE = ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
OLD_GLOBAL = BASE / "CAMPAIGN_003_QUEUE_APPROVED.csv"
OLD_ADDENDUM = BASE / "CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv"
OLD_W04 = BASE / "CAMPAIGN_004_W04_QUEUE_APPROVED.csv"
OLD_OWN = BASE / f"CAMPAIGN_004_{WORKER}_QUEUE_APPROVED.csv"
OVERLAY = BASE / "CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv"
STATES = {"EN_CI_AUTOMATICA", "ENTREGADO_PENDIENTE_CI",
          "DEPENDENCIA_DOCUMENTADA", "CI_PASS_VERIFICADO"}

def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))

def listed(path, worker):
    return {item for r in read_csv(path) if r.get("trabajadora") == worker
            for item in r["ids"].split(";")}

def validate():
    rows = read_csv(QUEUE)
    if len(rows) != 10 or [(r["trabajadora"], r["bloque"]) for r in rows] != [
            (WORKER, f"{n:02d}") for n in range(1,11)]:
        raise ValueError("Identidad o secuencia de CAMPAÑA_005 incorrecta")
    scope = {r["id"]:r["familia"] for r in read_csv(SCOPE)
             if r["estado_contenido"] == "SELECCIONADO"}
    own_previous = listed(OLD_OWN, WORKER)
    if WORKER == "W04":
        own_previous |= listed(OLD_ADDENDUM, WORKER)
    else:
        own_previous |= listed(OLD_GLOBAL, WORKER)
    previous_in_overlay = {r["id"] for r in read_csv(OVERLAY)
                           if r["trabajador"] == WORKER}
    seen=set()
    for row in rows:
        ids = row["ids"].split(";")
        if not ids or any(not x for x in ids):
            raise ValueError("Bloque con IDs vacíos")
        if KIND == "NEW_IDS" and len(ids) != (4 if WORKER=="W02" else 6):
            raise ValueError("Cantidad de IDs nueva incorrecta")
        for item in ids:
            if item in seen or item not in scope:
                raise ValueError("Duplicado o no seleccionado: "+item)
            if KIND=="NEW_IDS":
                expected_family = "TRAINING" if WORKER=="W02" else "MACHINE"
                if scope[item] != expected_family or item in own_previous or item in previous_in_overlay:
                    raise ValueError("Familia incorrecta o ID ya usado: "+item)
            else:
                if item not in own_previous and item not in previous_in_overlay:
                    raise ValueError("ID no pertenece al backlog anterior: "+item)
            seen.add(item)
    if len(seen) != EXPECTED_IDS:
        raise ValueError(f"Se esperaban {EXPECTED_IDS} IDs únicos, hay {len(seen)}")
    if WORKER=="W05":
        data=json.loads((ROOT/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
        mappings=data["machine_rows"]
        for item in seen:
            if not mappings.get(item,{}).get("scarlet-violet"):
                raise ValueError("MT sin mapeo SV activo: "+item)
    done=read_csv(PROGRESS)
    if len(done)>10:
        raise ValueError("Se excedieron diez bloques")
    for n,row in enumerate(done):
        if row["bloque"]!=rows[n]["bloque"] or row["ids"]!=rows[n]["ids"]:
            raise ValueError("Progreso fuera de cola en bloque "+str(n+1))
        if row["estado"] not in STATES:
            raise ValueError("Estado de bloque no autorizado")
    return len(done)

def receipt(n, kind, logfile):
    text=Path(logfile).read_text(encoding="utf-8",errors="replace")
    pattern=rf"^CAMP005_{WORKER}_{re.escape(kind)} PASS blocks=(\d+) checks=(\d+)\s*$"
    got=re.findall(pattern,text,flags=re.MULTILINE)
    if not got or int(got[-1][0])!=n or int(got[-1][1])<=0:
        raise ValueError("Falta recibo real válido: "+kind)
    print(f"CAMP005_GATE_{kind}_PASS worker={WORKER} blocks={n} checks={got[-1][1]}")

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--count-only",action="store_true")
    p.add_argument("--verify-output",choices=("PY","GODOT"))
    p.add_argument("--log")
    args=p.parse_args()
    try:
        n=validate()
        if args.verify_output:
            if not args.log or n==0:
                raise ValueError("Recibo requiere bloque funcional real y fichero de log")
            receipt(n,args.verify_output,args.log)
        elif args.count_only:
            print(n)
        else:
            print(f"CAMP005_{WORKER}_MANIFEST_PASS reserved=10 completed={n} ids={EXPECTED_IDS} kind={KIND}")
            if n==0: print("BOOTSTRAP_NO_FUNCIONAL")
        return 0
    except (OSError,ValueError,KeyError) as e:
        print(f"CAMP005_{WORKER}_MANIFEST_FAIL: {e}",file=sys.stderr)
        return 1

if __name__=="__main__":
    sys.exit(main())
