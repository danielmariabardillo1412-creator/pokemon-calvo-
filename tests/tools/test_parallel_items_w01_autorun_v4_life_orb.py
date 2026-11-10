#!/usr/bin/env python3
"""W01 V4 Life Orb row02 preflight; no runtime PASS without Node and Godot."""
import csv
import json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def rows(name):
    with (R/name).open(encoding="utf-8-sig",newline="") as f:
        return list(csv.DictReader(f))
def main():
    n=0
    def check(ok,label):
        nonlocal n
        n+=1
        if not ok: raise AssertionError(label)
    fixture=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
    check(fixture["items"][1]=={"row":"02","id":"life_orb"},"row02 fixed")
    check(fixture["format"]=="gen9calvounifiedv1","native format")
    scope={x["id"]:x for x in rows("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
    inv={x["id"]:x for x in rows("docs/current/ITEM_INVENTORY.csv")}
    check(scope["life_orb"]["estado_contenido"]=="SELECCIONADO","policy")
    check(inv["life_orb"]["native_entry"]=="True","native item")
    check("onModifyDamage" in inv["life_orb"]["native_hooks"]
          and "onAfterMoveSecondarySelf" in inv["life_orb"]["native_hooks"],"genuine hooks")
    held=json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    check("life_orb" in held["holdable_ids"],"real field service holds")
    existing=(R/"tools/item_audit/held_pilot.cjs").read_text(encoding="utf-8")
    check("life_orb:{run:" in existing,"prior native pilot is not new implementation")
    node=(R/"tests/tools/repro_w01_autorun_v4_life_orb_native.cjs").read_text(encoding="utf-8")
    gd=(R/"tests/gameplay/parallel_items_w01_autorun_v4_life_orb.gd").read_text(encoding="utf-8")
    for needle in ("NativeEngine","prepare","commit","restore","immune","status",
                   "W01_V4_NATIVE PASS id=life_orb"):
        check(needle in node,"missing independent native assertion "+needle)
    for needle in ("service.equip(", "FieldSession.new(", "session.submit(",
                   "session.settle_finished_battle(", "_roundtrip(", "life_orb",
                   "W01_V4_L3_ROW PASS row=02 id=life_orb"):
        check(needle in gd,"missing real L3 probe "+needle)
    progress=rows("docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V4_PROGRESS.csv")
    check(len(progress)==10 and progress[1]["id"]=="life_orb", "progress row02")
    check(progress[1]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA",
          "CERTIFICADO","YA_CERTIFICADO","PARCIAL","BLOQUEADO"),"audit status")
    check(progress[1]["objetos_nuevos"]=="0","no false implementation credit")
    print(f"W01_V4_LIFE_PY PASS row=02 checks={n}")
if __name__=="__main__": main()
