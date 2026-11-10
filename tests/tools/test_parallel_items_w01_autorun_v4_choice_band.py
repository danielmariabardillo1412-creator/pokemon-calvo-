#!/usr/bin/env python3
"""W01/03 Choice Band provenance, not runtime pass."""
import json,csv
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def items(path):
 with (R/path).open(encoding="utf-8-sig",newline="") as f: return {r["id"]:r for r in csv.DictReader(f)}
def main():
 fixture=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert fixture["items"][2]=={"row":"03","id":"choice_band"}
 assert items("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["choice_band"]["estado_contenido"]=="SELECCIONADO"
 assert "onModifyMove" in items("docs/current/ITEM_INVENTORY.csv")["choice_band"]["native_hooks"]
 assert "choice_band" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 assert "choice_band:{run:" in (R/"tools/item_audit/held_pilot.cjs").read_text(encoding="utf-8")
 for path,checks in {
  "tests/tools/repro_w01_autorun_v4_choice_band_native.cjs":["NativeEngine","assert.throws","switch","restore","W01_V4_NATIVE PASS"],
  "tests/gameplay/parallel_items_w01_autorun_v4_choice_band.gd":["service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip(","W01_V4_L3_ROW PASS"]
 }.items():
  text=(R/path).read_text(encoding="utf-8")
  assert all(x in text for x in checks),path
 print("W01_V4_CHOICE_PY PASS row=03 checks=9")
if __name__=="__main__": main()
