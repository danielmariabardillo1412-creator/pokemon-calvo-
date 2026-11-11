#!/usr/bin/env python3
"""W01 B01/01 Ability Shield policy and independent native/L3 tests preflight."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(path):
 with (R/path).open(encoding="utf-8-sig",newline="") as f:
  return {x["id"]:x for x in csv.DictReader(f)}
def main():
 q=table("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")
 assert q["ability_shield"]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO")
 scope=table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")
 inv=table("docs/current/ITEM_INVENTORY.csv")
 assert scope["ability_shield"]["estado_contenido"]=="SELECCIONADO"
 assert inv["ability_shield"]["native_entry"]=="True" and "onSetAbility" in inv["ability_shield"]["native_hooks"]
 assert "ability_shield" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 previous=(R/"tools/item_audit/held_effect_sweep_v3.cjs").read_text(encoding="utf-8")
 assert "add('ability_shield','ability_suppression'" in previous
 native=(R/"tests/tools/repro_w01_continuous_b01_ability_shield_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_continuous_b01_ability_shield.gd").read_text(encoding="utf-8")
 for needle in ("NativeEngine","gastro_acid","ignoringAbility()","restore","state_hash","W01_B01_NATIVE PASS"):
  assert needle in native,needle
 for needle in ("service.equip(","FieldSession.new(","ability_protected","settle_finished_battle(","_roundtrip(","W01_B01_L3_ROW PASS"):
  assert needle in gd,needle
 print("W01_B01_SHIELD_PY PASS row=01 checks=9")
if __name__=="__main__":main()
