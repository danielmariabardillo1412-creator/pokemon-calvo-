#!/usr/bin/env python3
"""W01 Sitrus held item QA only. W02 remains owner of field-berry implementation."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def read(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:return {row["id"]:row for row in csv.DictReader(f)}
def main():
 f=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert f["items"][9]=={"row":"10","id":"sitrus_berry"}
 assert read("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["sitrus_berry"]["estado_contenido"]=="SELECCIONADO"
 inv=read("docs/current/ITEM_INVENTORY.csv")["sitrus_berry"]
 assert inv["native_entry"]=="True" and inv["effect_status"]=="HELD_PILOT_VERIFIED"
 assert "onEat" in inv["native_hooks"] and "onUpdate" in inv["native_hooks"]
 assert "sitrus_berry" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 pilot=(R/"tools/item_audit/held_pilot.cjs").read_text(encoding="utf-8")
 assert "sitrus_berry:{moves:['protect']" in pilot
 node=(R/"tests/tools/repro_w01_autorun_v4_sitrus_berry_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_autorun_v4_sitrus_berry.gd").read_text(encoding="utf-8")
 for marker in ("NativeEngine","active_at_half","active_above_half","max_hp/2","max_hp/4","snapshot","W01_V4_NATIVE PASS id=sitrus_berry"):assert marker in node,marker
 for marker in ("service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip(","held_item_consumed","unequip(","W01_V4_L3_ROW PASS row=10 id=sitrus_berry"):assert marker in gd,marker
 print("W01_V4_SITRUS_PY PASS row=10 checks=10")
if __name__=="__main__":main()
