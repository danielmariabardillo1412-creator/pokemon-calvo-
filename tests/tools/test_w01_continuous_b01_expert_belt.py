#!/usr/bin/env python3
"""W01 CONTINUOUS_V2/B01-05 Expert Belt selected, native pilot exists, L3 gate."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def rows(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:return {x["id"]:x for x in csv.DictReader(f)}
def main():
 progress=rows("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")
 assert progress["expert_belt"]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO")
 assert rows("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["expert_belt"]["estado_contenido"]=="SELECCIONADO"
 entry=rows("docs/current/ITEM_INVENTORY.csv")["expert_belt"]
 assert entry["native_entry"]=="True" and entry["connection"]=="HELD_PILOT_VERIFIED"
 assert "onModifyDamage" in entry["native_hooks"]
 assert "expert_belt" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 prior=(R/"tools/item_audit/held_pilot.cjs").read_text(encoding="utf-8")
 assert "expert_belt:{moves:['thunder_shock']" in prior
 node=(R/"tests/tools/repro_w01_continuous_b01_expert_belt_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_continuous_b01_expert_belt.gd").read_text(encoding="utf-8")
 for needle in ("NativeEngine","gyarados","thunder_shock","tackle","restore","W01_B01_NATIVE PASS id=expert_belt"):assert needle in node,needle
 for needle in ("service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip(","W01_B01_L3_ROW PASS row=05 id=expert_belt"):assert needle in gd,needle
 print("W01_B01_BELT_PY PASS row=05 checks=9")
if __name__=="__main__":main()
