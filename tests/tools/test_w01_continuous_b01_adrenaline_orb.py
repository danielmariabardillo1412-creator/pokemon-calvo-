#!/usr/bin/env python3
"""W01 continuous B01/03 Adrenaline Orb contract preflight, distinct from runtime."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(path):
 with (R/path).open(encoding="utf-8-sig",newline="") as f:return {r["id"]:r for r in csv.DictReader(f)}
def main():
 progress=table("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")
 assert progress["adrenaline_orb"]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO")
 assert table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["adrenaline_orb"]["estado_contenido"]=="SELECCIONADO"
 entry=table("docs/current/ITEM_INVENTORY.csv")["adrenaline_orb"]
 assert entry["native_entry"]=="True" and "onAfterBoost" in entry["native_hooks"]
 assert "adrenaline_orb" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 legacy=(R/"tools/item_audit/held_effect_sweep_v3.cjs").read_text(encoding="utf-8")
 assert "add('adrenaline_orb','intimidate_trigger'" in legacy
 node=(R/"tests/tools/repro_w01_continuous_b01_adrenaline_orb_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_continuous_b01_adrenaline_orb.gd").read_text(encoding="utf-8")
 for token in ("NativeEngine","intimidate","synchronize","boosts.spe","restore","W01_B01_NATIVE PASS id=adrenaline_orb"):assert token in node,token
 for token in ("FieldSession.new(","service.equip(","stat_stages.get_stage","settle_finished_battle(","_roundtrip(","held_item_consumed","W01_B01_L3_ROW PASS row=03 id=adrenaline_orb"):assert token in gd,token
 print("W01_B01_ORB_PY PASS row=03 checks=9")
if __name__=="__main__":main()
