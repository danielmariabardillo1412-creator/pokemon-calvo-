#!/usr/bin/env python3
"""W01 TANDA04/04 metadata gate, distinct from runtime PASS."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:
  return {x["id"]:x for x in csv.DictReader(f)}
def main():
 f=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert f["items"][3]=={"row":"04","id":"choice_specs"}
 assert table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["choice_specs"]["estado_contenido"]=="SELECCIONADO"
 inv=table("docs/current/ITEM_INVENTORY.csv")["choice_specs"]
 assert inv["native_entry"]=="True" and "onModifySpA" in inv["native_hooks"] and "onModifyMove" in inv["native_hooks"]
 profile=json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
 assert "choice_specs" in profile["holdable_ids"]
 scripts={
  "tests/tools/repro_w01_autorun_v4_choice_specs_native.cjs":["NativeEngine","water_gun","shadow_ball","assert.throws","state_hash","disabled","restore"],
  "tests/gameplay/parallel_items_w01_autorun_v4_choice_specs.gd":["service.equip(","FieldSession.new(","_switch_choice(","settle_finished_battle(","_roundtrip(","water_gun","shadow_ball"]
 }
 for path,needles in scripts.items():
  data=(R/path).read_text(encoding="utf-8")
  assert all(x in data for x in needles),path
 print("W01_V4_SPECS_PY PASS row=04 checks=9")
if __name__=="__main__": main()
