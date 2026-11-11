#!/usr/bin/env python3
"""W01 B02/10 Iron Plate has only type-boost authorization; no W04 forms."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def rows(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:return {x["id"]:x for x in csv.DictReader(f)}
def main():
 assert rows("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")["iron_plate"]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO")
 assert rows("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["iron_plate"]["estado_contenido"]=="SELECCIONADO"
 inv=rows("docs/current/ITEM_INVENTORY.csv")["iron_plate"]
 assert inv["native_entry"]=="True" and "onBasePower" in inv["native_hooks"]
 assert "iron_plate" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 node=(R/"tests/tools/repro_w01_continuous_b02_iron_plate_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_continuous_b02_iron_plate.gd").read_text(encoding="utf-8")
 for x in ("NativeEngine","flash_cannon","tackle","mew","restore","W01_B02_NATIVE PASS id=iron_plate"):assert x in node,x
 for x in ("service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip(","species_id==&\"mew\"","W01_B02_L3_ROW PASS row=17 id=iron_plate"):assert x in gd,x
 print("W01_B02_IRON_PY PASS row=17 checks=9")
if __name__=="__main__":main()
