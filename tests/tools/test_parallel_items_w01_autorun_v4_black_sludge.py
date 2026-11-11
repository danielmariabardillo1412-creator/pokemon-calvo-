#!/usr/bin/env python3
"""Black Sludge W01 row09 canonical inventory + old coverage + test integrity."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def read(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:return {row["id"]:row for row in csv.DictReader(f)}
def main():
 f=json.loads((R/"tests/fixtures/parallel_items/w01_autorun_v4.json").read_text(encoding="utf-8"))
 assert f["items"][8]=={"row":"09","id":"black_sludge"}
 assert read("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["black_sludge"]["estado_contenido"]=="SELECCIONADO"
 inv=read("docs/current/ITEM_INVENTORY.csv")["black_sludge"]
 assert inv["native_entry"]=="True"
 assert "onResidual" in inv["native_hooks"]
 assert "black_sludge" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 old=(R/"tests/tools/test_parallel_items_w01_campaign_001.py").read_text(encoding="utf-8")
 assert '"sludge_poison_heal"' in old and '"sludge_nonpoison_damage"' in old
 native=(R/"tests/tools/repro_w01_autorun_v4_black_sludge_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_autorun_v4_black_sludge.gd").read_text(encoding="utf-8")
 for word in ("NativeEngine","gengar","caterpie","1/16","1/8","restore","W01_V4_NATIVE PASS id=black_sludge"):assert word in native,word
 for word in ("service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip(","W01_V4_L3_ROW PASS row=09 id=black_sludge"):assert word in gd,word
 print("W01_V4_SLUDGE_PY PASS row=09 checks=9")
if __name__=="__main__":main()
