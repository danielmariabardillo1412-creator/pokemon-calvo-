#!/usr/bin/env python3
"""W01 V4 row05 Choice Scarf: policy+coverage, never asserts live combat PASS."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:
  return {x["id"]:x for x in csv.DictReader(f)}
def main():
 f=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert f["items"][4]=={"row":"05","id":"choice_scarf"}
 assert table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["choice_scarf"]["estado_contenido"]=="SELECCIONADO"
 inv=table("docs/current/ITEM_INVENTORY.csv")["choice_scarf"]
 assert inv["native_entry"]=="True" and "onModifySpe" in inv["native_hooks"] and "onModifyMove" in inv["native_hooks"]
 profile=json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
 assert "choice_scarf" in profile["holdable_ids"]
 node=(R/"tests/tools/repro_w01_autorun_v4_choice_scarf_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_autorun_v4_choice_scarf.gd").read_text(encoding="utf-8")
 for word in ("getStat('spe')","quick_attack","priority","speed","assert.deepEqual(order",
              "assert.throws","state_hash","restore","Choice Scarf"):
  assert word in node,word
 for word in ("service.equip(","FieldSession.new(","_switch_choice(", "settle_finished_battle(",
              "_roundtrip(","jolteon","earth_power","W01_V4_L3_ROW PASS row=05 id=choice_scarf"):
  assert word in gd,word
 print("W01_V4_SCARF_PY PASS row=05 checks=10")
if __name__=="__main__":main()
