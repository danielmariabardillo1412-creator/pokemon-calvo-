#!/usr/bin/env python3
"""W01 B02/10 Flame Plate has only type-boost authorization; no W04 forms."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
def rows(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f:return {x["id"]:x for x in csv.DictReader(f)}
def main():
 assert rows("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")["flame_plate"]["estado"] in ("PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO")
 assert rows("docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")["flame_plate"]["estado_contenido"]=="SELECCIONADO"
 inv=rows("docs/current/ITEM_INVENTORY.csv")["flame_plate"]
 assert inv["native_entry"]=="True" and "onBasePower" in inv["native_hooks"]
 assert "flame_plate" in json.loads((R/"modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))["holdable_ids"]
 node=(R/"tests/tools/repro_w01_continuous_b02_flame_plate_native.cjs").read_text(encoding="utf-8")
 gd=(R/"tests/gameplay/parallel_items_w01_continuous_b02_flame_plate.gd").read_text(encoding="utf-8")
 for x in ("NativeEngine","flamethrower","tackle","mew","restore","W01_B02_NATIVE PASS id=flame_plate"):assert x in node,x
 for x in ("service.equip(","FieldSession.new(","settle_finished_battle(","_roundtrip(","species_id==&\"mew\"","W01_B02_L3_ROW PASS row=14 id=flame_plate"):assert x in gd,x
 print("W01_B02_FLAME_PY PASS row=14 checks=9")
if __name__=="__main__":main()
