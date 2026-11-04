#!/usr/bin/env python3
"""W03 CAMP006: strict queue, owned adapter, executable L2/L3 pilot contract."""
from __future__ import annotations
import argparse
import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
FIXTURE = ROOT / "tests/fixtures/parallel_items/w03_campaign_006.json"
PROGRESS = BASE / "reports/W03/CAMP_006_PROGRESO.csv"
QUEUE = BASE / "CAMPAIGN_006_W03_QUEUE_APPROVED.csv"

def read_csv(path: Path) -> list[dict[str,str]]:
    with path.open(encoding="utf-8-sig",newline="") as f:
        return list(csv.DictReader(f))

def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--ci",action="store_true")
    ap.parse_args()
    n=0
    def ck(cond:bool,message:str)->None:
        nonlocal n
        n+=1
        if not cond:raise AssertionError(message)
    try:
        f=json.loads(FIXTURE.read_text(encoding="utf-8"))
        q=read_csv(QUEUE)
        p=read_csv(PROGRESS)
        gd=(ROOT/"tests/gameplay/parallel_items_w03_campaign_006.gd").read_text(encoding="utf-8")
        adapter=(ROOT/"modules/overworld/escape_rope_demo_pilot.gd").read_text(encoding="utf-8")
        world=(ROOT/"modules/overworld/overworld_traversal_controller.gd").read_text(encoding="utf-8")
        demo=(ROOT/"scenes/visual/field_demo.gd").read_text(encoding="utf-8")
        save=(ROOT/"scenes/visual/field_native_bridge.gd").read_text(encoding="utf-8")
        tscn=(ROOT/"scenes/overworld/technical_overworld.tscn").read_text(encoding="utf-8")
        ck(f["campaign"]=="CAMP_006" and f["worker"]=="W03", "identity")
        ck(len(q)==10 and len(p)==len(f["blocks"])==1,"progress not exactly 1/10")
        ids=f["blocks"][0]["ids"]
        ck(ids==["escape_rope"] and p[0]["ids"]=="escape_rope" and q[0]["ids"]=="escape_rope","queue mismatch")
        ck(p[0]["bloque"]=="01" and f["blocks"][0]["bloque"]=="01", "block sequence")
        ck(f["blocks"][0]["functional_level"]=="L2_L3_NAVIGATION_PILOT_ONLY"
           and f["blocks"][0]["item_effect_fully_connected"] is False
           and f["blocks"][0]["inventory_commit"] is False,
           "do not certify bag wiring or consumption")
        ck('"cave":' not in adapter or "SurfaceCaveReturn" in adapter,"source-owned anchor")
        ck("SurfaceCaveReturn" in tscn and "CaveExit" in tscn and
           'destination_path = NodePath("../SurfaceCaveReturn")' in tscn,"valid actual anchor")
        ck("func preview(" in adapter and "func return_to_demo_anchor(" in adapter,
           "positive adapter missing")
        ck("await traversal.traverse_portal(portal)" in adapter,
           "must use real controller, not teleport directly")
        ck("portal.destination_node() != marker" in adapter
           and "return_anchor_occupied" in adapter,
           "anchor guard not source validated")
        ck("func traverse_portal(" in world and
           "destination_occupied" in world and
           "traversal_busy" in world and
           "transition_finished.emit(" in world,
           "actual world traversal contract changed")
        ck("field_native_world_snapshot(" in demo and
           "field_validate_native_loaded_world(" in demo and
           "field_publish_native_loaded_world(" in demo,
           "native world restore contract changed")
        ck("func save_game(" in save and "saves.write(" in save and
           "func load_game(" in save and "saves.read(" in save,
           "actual native disk persistence missing")
        ck('await Pilot.return_to_demo_anchor(scene)' in gd
           and 'await scene.traversal_controller.traverse_portal(enter)' in gd,
           "no real demo entrance/return test")
        ck('save.save_game()' in gd and 'await save.load_game()' in gd,
           "no native disk save/load test")
        ck('stocked == original_quantity + 2' in gd
           and '== stocked' in gd
           and 'field_locked' in gd,
           "rejected use/no-consumption coverage missing")
        ck('"CAMP006_W03_GODOT PASS blocks=" + str(n)' in gd
           and "quit(1)" in gd, "Godot receipt/strict failures missing")
    except (OSError,KeyError,ValueError,TypeError,AssertionError) as exc:
        print("CAMP006_W03_PY FAIL",exc,file=sys.stderr)
        return 1
    print(f"CAMP006_W03_PY PASS blocks={len(p)} checks={n}")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
