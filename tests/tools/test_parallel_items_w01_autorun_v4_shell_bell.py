#!/usr/bin/env python3
"""W01 TANDA04 row06 Shell Bell: selected/native/harness, not a combat result."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def table(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:
  return {x["id"]:x for x in csv.DictReader(f)}
def main():
 f=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert f["items"][5]=={"row":"06","id":"shell_bell"}
 assert table("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["shell_bell"]["estado_contenido"]=="SELECCIONADO"
 inv=table("docs/current/ITEM_INVENTORY.csv")["shell_bell"]
 assert inv["native_entry"]=="True" and "onAfterMoveSecondarySelf" in inv["native_hooks"]
 profile=json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
 assert "shell_bell" in profile["holdable_ids"]
 legacy=(R/"tests/tools/test_parallel_items_w01_campaign_001.py").read_text(encoding="utf-8")
 assert '"bell_attack_heal": ("shell_bell"' in legacy
 node=(R/"tests/tools/repro_w01_autorun_v4_shell_bell_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_autorun_v4_shell_bell.gd").read_text(encoding="utf-8")
 for needle in ("NativeEngine","1/8","immune","status","restore","state_hash","W01_V4_NATIVE PASS id=shell_bell"):
  assert needle in node,needle
 for needle in ("service.equip(", "FieldSession.new(", "settle_finished_battle(", "_roundtrip(",
                "maxi(1", "W01_V4_L3_ROW PASS row=06 id=shell_bell"):
  assert needle in gd,needle
 print("W01_V4_BELL_PY PASS row=06 checks=10")
if __name__=="__main__":main()
