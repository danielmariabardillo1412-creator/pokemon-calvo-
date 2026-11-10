#!/usr/bin/env python3
"""W01 TANDA03: immutable provenance and 18 genuine L3 inventory-to-settlement cases."""
from __future__ import annotations
import csv
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
FIXTURE=ROOT/"tests/fixtures/parallel_items/w01_autorun_v3.json"
PROGRESS=ROOT/"docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V3_PROGRESS.csv"
INVENTORY=ROOT/"docs/current/ITEM_INVENTORY.csv"
SCOPE=ROOT/"docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
RUNNER=ROOT/"tests/gameplay/parallel_items_w01_autorun_v3.gd"
V1=ROOT/"tests/fixtures/parallel_items/w01_autorun_v1.json"
V2=ROOT/"tests/fixtures/parallel_items/w01_autorun_v2.json"
TESTS=0
def check(ok:bool,message:str)->None:
    global TESTS
    TESTS+=1
    if not ok:
        raise AssertionError(message)
def rows(file:Path)->list[dict[str,str]]:
    with file.open(encoding="utf-8-sig",newline="") as io:
        return list(csv.DictReader(io))
def run()->None:
    data=json.loads(FIXTURE.read_text(encoding="utf-8"))
    check(data["schema_version"]==1 and data["worker"]=="W01"
          and data["tanda"]=="03" and data["kind"]=="AUTORUN_V3_W01_L3_GEMS"
          and data["format"]=="gen9calvounifiedv1","TANDA03 fixture identity")
    check(data["scope"]["new_items"]==0,"There are no new Gem items this batch")
    check(data["scope"]["group_counts"]=={"C005":3,"V1":10,"V2":5},"Historical group counts")
    check(data["source_history"]=={
        "camp005":{"sha":"5303578448d909cf1b4e2c3c60c7d3e231203f98","ci":42717306543},
        "tanda01":{"sha":"9d1a9dae8b9d9abed09a12b082f7a719aa047981","ci":42730773059},
        "tanda02":{"sha":"0871aa6751faecb7342376134ddbcaa5acf1ce5a","ci":42869207766}},
        "Frozen true SHA provenance")
    items=data["items"]
    check(len(items)==18 and len({x["id"] for x in items})==18
          and len({x["type"] for x in items})==18,"One and only one of every canonical type")
    old3=["normal_gem","fire_gem","water_gem"]
    v1=json.loads(V1.read_text(encoding="utf-8"))["items"]
    v2=json.loads(V2.read_text(encoding="utf-8"))["items"]
    check([x["id"] for x in items[:3]]==old3,"CAMP005 originals not replaced")
    check([x["id"] for x in items[3:13]]==[x["id"] for x in v1],"TANDA01 unchanged")
    check([x["id"] for x in items[13:]]==[x["id"] for x in v2],"TANDA02 unchanged")
    check([x["batch"] for x in items]==["C005"]*3+["V1"]*10+["V2"]*5,
          "Provenance cannot be reassigned")
    inventory={r["id"]:r for r in rows(INVENTORY)}
    scope={r["id"]:r for r in rows(SCOPE)}
    for row in items:
        id=row["id"]
        check(inventory[id]["native_id"]==id.replace("_","")
              and inventory[id]["native_entry"]=="True"
              and "onSourceTryPrimaryHit" in inventory[id]["native_hooks"],
              "Item not rooted in real native hook "+id)
        check(scope[id]["estado_contenido"]=="SELECCIONADO"
              and scope[id]["familia"]=="HELD_COMBAT_CANDIDATE",
              "Gem excluded by policy "+id)
        check(row["attack"] and row["type"],"Missing matching move/type "+id)
    prog=rows(PROGRESS)
    check(len(prog)==10 and [r["fila"] for r in prog]==[f"{i:02d}" for i in range(1,11)],
          "Ten independent milestone slots required")
    check([r["hito"] for r in prog]==data["milestones"],"Progress mismatches queue")
    check(all(r["objetos_nuevos"]=="0" for r in prog),"No new items minted")
    check(all(r["estado"] in {"PENDIENTE","EN_CI_AUTOMATICA","CERTIFICADO","BLOQUEADO","DIFERIDO","NO_APLICA","PARCIAL"} for r in prog),"Progress status valid")
    runner=RUNNER.read_text(encoding="utf-8")
    for marker in ("FieldItemService","service.equip(","SaveGameRepository",
                   "FieldNativeSession","settle_finished_battle","held_item_consumed",
                   "func _real_cycle(", "func _rejections(", "func _legacy(",
                   "W01_V3_L3_ROW PASS","W01_V3_GODOT PASS"):
        check(marker in runner, "Real L3 integration missing code marker "+marker)
    for path,markers in {
        "modules/inventory/field_item_service.gd":["func equip(","func unequip(","func holdable("],
        "modules/creatures/storage/player_collection.gd":["func owned_creature("],
        "modules/inventory/player_inventory.gd":["func quantity(","func remove("],
        "modules/gameplay/field_native_session.gd":["func _init(","func _finish("],
        "modules/gameplay/showdown_adventure_session.gd":["func settle_finished_battle(","func _finish("],
        "modules/save/save_game_repository.gd":["func save_collection(","func load(","func decode_snapshot("],
        "modules/save/save_game_migration.gd":["calvo_save_v1","migrated"],
        "scenes/visual/field_native_bridge.gd":["const Session = preload(\"res://modules/gameplay/field_native_session.gd\")"]
    }.items():
        content=(ROOT/path).read_text(encoding="utf-8")
        for marker in markers:
            check(marker in content,"Read-only real integration seam missing: "+path+" "+marker)
def main()->int:
    try: run()
    except (AssertionError,KeyError,OSError,ValueError) as ex:
        print("W01_V3_PY FAIL:",str(ex))
        return 1
    print(f"W01_V3_PY PASS items=18 milestones=10 checks={TESTS}")
    return 0
if __name__=="__main__":
    raise SystemExit(main())
