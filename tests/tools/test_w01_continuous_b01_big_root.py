#!/usr/bin/env python3
"""W01 B01/04 Big Root: policy/native/historical coverage preflight."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def rows(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:return {x["id"]:x for x in csv.DictReader(f)}
def main():
 assert rows("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")["big_root"]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO")
 assert rows("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["big_root"]["estado_contenido"]=="SELECCIONADO"
 inv=rows("docs/current/ITEM_INVENTORY.csv")["big_root"]
 assert inv["native_entry"]=="True" and "onTryHeal" in inv["native_hooks"]
 assert "big_root" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 old=(R/"tests/tools/test_parallel_items_w01_campaign_001.py").read_text(encoding="utf-8")
 assert '"root_absorb_boost"' in old and '"root_plain_attack_control"' in old
 node=(R/"tests/tools/repro_w01_continuous_b01_big_root_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_continuous_b01_big_root.gd").read_text(encoding="utf-8")
 for x in ("NativeEngine","swampert","absorb","tackle","damaged","healed","restore","W01_B01_NATIVE PASS id=big_root"):assert x in node,x
 for x in ("service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip(","W01_B01_L3_ROW PASS row=04 id=big_root"):assert x in gd,x
 print("W01_B01_ROOT_PY PASS row=04 checks=9")
if __name__=="__main__":main()
