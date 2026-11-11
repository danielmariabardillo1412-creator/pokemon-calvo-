#!/usr/bin/env python3
"""W01 continuous B01/02 Absorb Bulb selected provenance; not runtime PASS."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:return {x["id"]:x for x in csv.DictReader(f)}
def main():
 q=table("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")
 assert q["absorb_bulb"]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO")
 assert table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["absorb_bulb"]["estado_contenido"]=="SELECCIONADO"
 native=table("docs/current/ITEM_INVENTORY.csv")["absorb_bulb"]
 assert native["native_entry"]=="True" and "onDamagingHit" in native["native_hooks"]
 assert "absorb_bulb" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 node=(R/"tests/tools/repro_w01_continuous_b01_absorb_bulb_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_continuous_b01_absorb_bulb.gd").read_text(encoding="utf-8")
 for word in ("NativeEngine","water_gun","tackle","boosts.spa","restore","state_hash","W01_B01_NATIVE PASS id=absorb_bulb"):assert word in node,word
 for word in ("FieldSession.new(","service.equip(","stat_stages.get_stage","settle_finished_battle(","_roundtrip(","held_item_consumed","W01_B01_L3_ROW PASS row=02 id=absorb_bulb"):assert word in gd,word
 print("W01_B01_BULB_PY PASS row=02 checks=9")
if __name__=="__main__":main()
