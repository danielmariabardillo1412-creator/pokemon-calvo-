#!/usr/bin/env python3
"""W01 Eviolite row07 audit: authentic evolving and final species tests required."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:
  return {x["id"]:x for x in csv.DictReader(f)}
def main():
 fixture=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert fixture["items"][6]=={"row":"07","id":"eviolite"}
 assert table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["eviolite"]["estado_contenido"]=="SELECCIONADO"
 inv=table("docs/current/ITEM_INVENTORY.csv")["eviolite"]
 assert "onModifyDef" in inv["native_hooks"] and "onModifySpD" in inv["native_hooks"]
 assert "eviolite" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 prior=(R/"tests/tools/test_parallel_items_w01_campaign_001.py").read_text(encoding="utf-8")
 assert '"eviolite_pre_physical"' in prior and '"eviolite_final_special"' in prior
 native=(R/"tests/tools/repro_w01_autorun_v4_eviolite_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_autorun_v4_eviolite.gd").read_text(encoding="utf-8")
 for marker in ("NativeEngine","pidgeotto","pidgeot","tackle","psychic","pre[0].dealt<pre[1].dealt","snapshot"):
  assert marker in native,marker
 for marker in ("FieldSession.new(","service.equip(","settle_finished_battle(","_roundtrip(","pidgeotto","pidgeot","W01_V4_L3_ROW PASS row=07 id=eviolite"):
  assert marker in gd,marker
 print("W01_V4_EVI_PY PASS row=07 checks=9")
if __name__=="__main__":main()
