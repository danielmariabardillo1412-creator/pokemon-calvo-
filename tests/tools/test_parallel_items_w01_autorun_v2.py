#!/usr/bin/env python3
"""W01 AUTORUN V2 TANDA02 preflight; proves policy, all 18 IDs, native behavior."""
from __future__ import annotations

import csv
import json
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/"docs/coordination/items_parallel_v1/reports/W01"
FIXTURE=ROOT/"tests/fixtures/parallel_items/w01_autorun_v2.json"
PROGRESS=BASE/"AUTORUN_V2_PROGRESS.csv"
V1_FIXTURE=ROOT/"tests/fixtures/parallel_items/w01_autorun_v1.json"
V1_PROGRESS=BASE/"AUTORUN_V1_PROGRESS.csv"
V1_FINAL=BASE/"AUTORUN_V1_FINAL.md"
C005_PROGRESS=BASE/"CAMP_005_PROGRESO.csv"
INVENTORY=ROOT/"docs/current/ITEM_INVENTORY.csv"
SCOPE=ROOT/"docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
NATIVE=ROOT/"tests/tools/repro_w01_autorun_v2_native.cjs"
GODOT=ROOT/"tests/gameplay/parallel_items_w01_autorun_v2.gd"
EXPECTED=[
("ghost_gem","ghost","shadow_ball","tackle","spite"),
("dragon_gem","dragon","dragon_pulse","tackle","dragon_dance"),
("dark_gem","dark","dark_pulse","tackle","nasty_plot"),
("steel_gem","steel","flash_cannon","tackle","iron_defense"),
("fairy_gem","fairy","moonblast","tackle","misty_terrain"),
]
OTHER=[
"normal_gem","fire_gem","water_gem",
"electric_gem","grass_gem","ice_gem","fighting_gem","poison_gem",
"ground_gem","flying_gem","psychic_gem","bug_gem","rock_gem"
]
MILESTONES=["ghost_gem","dragon_gem","dark_gem","steel_gem","fairy_gem",
             "matrix","consumption","SaveV2","backend","CI"]
CHECKS=0

def check(flag:bool,label:str)->None:
    global CHECKS
    CHECKS+=1
    if not flag:
        raise AssertionError(label)

def rows(path:Path)->list[dict[str,str]]:
    with path.open(encoding="utf-8-sig",newline="") as f:
        return list(csv.DictReader(f))

def validate()->None:
    fixture=json.loads(FIXTURE.read_text(encoding="utf-8"))
    check(fixture.get("schema_version")==1 and fixture.get("kind")=="AUTORUN_V2_W01_GEMS"
          and fixture.get("worker")=="W01" and fixture.get("tanda")=="02"
          and fixture.get("format")=="gen9calvounifiedv1", "TANDA02 identity/format")
    check(fixture["modes"]==["active","none","reserve"], "All 3 ownership modes")
    check(fixture["historical"]=={
        "c005_sha":"5303578448d909cf1b4e2c3c60c7d3e231203f98",
        "c005_ci":42717306543,
        "v1_sha":"9d1a9dae8b9d9abed09a12b082f7a719aa047981",
        "v1_ci":42730773059}, "Historical SHA+CI references immutable")
    check(len(fixture["items"])==5 and len(fixture["milestones"])==10,
          "Exactly five Gem tasks plus five cross-cutting milestones")
    check(fixture["other_gems"]==OTHER,"The thirteen earlier gems remain unchanged")
    progress=rows(PROGRESS)
    check(len(progress)==10,"Ten progress entries required")
    check([r["hito"] for r in progress]==MILESTONES,
          "TANDA02 milestone labels drift")
    for i,r in enumerate(progress):
        check(r["fila"]==f"{i+1:02d}" and r["estado"] in
              {"EN_CI_AUTOMATICA","PENDIENTE","CERTIFICADO","BLOQUEADO","NO_APLICA","DIFERIDO","PARCIAL"},
              "Invalid TANDA02 progress row "+str(i+1))
    v1=rows(V1_PROGRESS)
    check(len(v1)==10 and all(r["estado"]=="CERTIFICADO" and
          r["ci_run"]=="42730773059" and
          r["sha_pruebas"]=="9d1a9dae8b9d9abed09a12b082f7a719aa047981" for r in v1),
          "Do not forget or reassign certified TANDA01")
    final=V1_FINAL.read_text(encoding="utf-8")
    check("TANDA 01 FINALIZADA" in final and "42730773059" in final,
          "Old finished report must remain anchored")
    c005=rows(C005_PROGRESS)
    check(len(c005)==10 and all(r["estado"]=="CI_PASS_VERIFICADO" for r in c005)
          and c005[-1]["ci_run"]=="42717306543",
          "CAMP005 frozen complete")
    inv={r["id"]:r for r in rows(INVENTORY)}
    scope={r["id"]:r for r in rows(SCOPE)}
    allids=OTHER+[r[0] for r in EXPECTED]
    check(len(allids)==len(set(allids))==18,
          "Must have exactly 18 distinct elemental Gems")
    oldids={v["id"] for v in json.loads(V1_FIXTURE.read_text(encoding="utf-8"))["items"]}
    check(oldids==set(OTHER[3:]),"TANDA01 10 items must be exactly old set")
    camp_ids=";".join(v["ids"] for v in c005).split(";")
    check(set(OTHER[:3]).issubset(camp_ids),"Original 3 Gems were in CAMP005")
    for i,(id,typ,attack,wrong,status) in enumerate(EXPECTED):
        itm=fixture["items"][i]
        check((itm["row"],itm["id"],itm["type"],itm["attack"],itm["wrong"],itm["status"])==
              (f"{i+1:02d}",id,typ,attack,wrong,status),
              "TANDA02 only approved item and exact type/move: "+id)
        check(itm["cases"]==[
              {"op":"matching","move":attack,"seeds":[19,23]},
              {"op":"wrong_type","move":wrong,"seeds":[19]},
              {"op":"status_same_type","move":status,"seeds":[19]}],
              "No weakening positive/negative/scoped case for "+id)
        check(inv[id]["native_entry"]=="True" and inv[id]["native_id"]==id.replace("_","")
              and inv[id]["family"]=="HELD_COMBAT_CANDIDATE"
              and "onSourceTryPrimaryHit" in inv[id]["native_hooks"],
              "Native item inventory not traceable "+id)
        check(scope[id]["estado_contenido"]=="SELECCIONADO" and
              scope[id]["familia"]=="HELD_COMBAT_CANDIDATE",
              "Not selected in canonical Randomlock policy "+id)
        check(id not in camp_ids and id not in oldids,
              "Do not repeat item from certified historic campaign "+id)
        check(progress[i]["hito"]==id, "Progress ID not owned "+id)
    runner=GODOT.read_text(encoding="utf-8")
    for token in ["extends \"res://tests/gameplay/parallel_items_w01_campaign_005.gd\"",
                  "func _run_autorun_v2(", "_w01_c004_probe_lane",
                  "gem_first_consumed","gem_mid_save","gem_final_save",
                  "active","reserve","SaveV2","W01_V2_GODOT_ROW PASS"]:
        check(token in runner,"No Godot functional gate: "+token)
    root=(ROOT/"tests/gameplay/parallel_items_w01_campaign_005.gd").read_text(encoding="utf-8")
    check("func _probe_c005_gem_matching(" in root and "func _probe_w01_c004(" in root,
          "Historic positive L3 SaveV2 probe was modified or missing")
    source=NATIVE.read_text(encoding="utf-8")
    for token in ["NativeEngine","onSourceTryPrimaryHit","W01_V2_MATRIX PASS",
                  "W01_V2_IMMUNITY PASS","W01_V2_MISS PASS",
                  "W01_V2_SLOTS PASS","W01_V2_TRANSFORM PASS",
                  "W01_V2_NATIVE_ROW PASS","restore","moveSlots","switch 2"]:
        check(token in source,"L2 native coverage missing: "+token)

def main()->int:
    try:
        validate()
        result=subprocess.run(["node",str(NATIVE)],cwd=ROOT,capture_output=True,
                              text=True,check=True)
        print(result.stdout.strip())
        for token in ("W01_V2_MATRIX PASS types=18",
                      "W01_V2_IMMUNITY PASS cases=2",
                      "W01_V2_MISS PASS hits=",
                      "W01_V2_SLOTS PASS",
                      "W01_V2_TRANSFORM PASS",
                      "W01_V2_NATIVE PASS rows=5"):
            check(token in result.stdout, "Native gate not met: "+token)
        check(result.stdout.count("W01_V2_NATIVE_ROW PASS row=")==5,
              "All five real damage/ownership/SaveV2 gates must pass")
    except (OSError,ValueError,KeyError,AssertionError,subprocess.CalledProcessError) as ex:
        if isinstance(ex,subprocess.CalledProcessError):
            print("W01_V2_NATIVE_STDOUT:",ex.stdout)
            print("W01_V2_NATIVE_STDERR:",ex.stderr)
        print("W01_V2_PY FAIL:",str(ex))
        return 1
    print(f"W01_V2_PY PASS rows=5 checks={CHECKS}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
