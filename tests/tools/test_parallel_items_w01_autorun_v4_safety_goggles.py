#!/usr/bin/env python3
"""W01 TANDA04/08 effective selected Goggles and L2/L3 test integrity."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:
  return {row["id"]:row for row in csv.DictReader(f)}
def main():
 f=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert f["items"][7]=={"row":"08","id":"safety_goggles"}
 assert table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["safety_goggles"]["estado_contenido"]=="SELECCIONADO"
 inventory=table("docs/current/ITEM_INVENTORY.csv")["safety_goggles"]
 assert inventory["native_entry"]=="True"
 assert "onImmunity" in inventory["native_hooks"] and "onTryHit" in inventory["native_hooks"]
 assert "safety_goggles" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 prior=(R/"tests/tools/test_parallel_items_w01_campaign_001.py").read_text(encoding="utf-8")
 for word in ('"goggles_spore"','"goggles_sandstorm"','"goggles_normal"'):assert word in prior
 node=(R/"tests/tools/repro_w01_autorun_v4_safety_goggles_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_autorun_v4_safety_goggles.gd").read_text(encoding="utf-8")
 for word in ("NativeEngine","spore","sandstorm","amnesia","snapshot.native.log","status","W01_V4_NATIVE PASS id=safety_goggles"):assert word in node,word
 for word in ("service.equip(", "FieldSession.new(","settle_finished_battle(","_roundtrip(","spore","sandstorm","W01_V4_L3_ROW PASS row=08 id=safety_goggles"):assert word in gd,word
 print("W01_V4_GOG_PY PASS row=08 checks=10")
if __name__=="__main__":main()
