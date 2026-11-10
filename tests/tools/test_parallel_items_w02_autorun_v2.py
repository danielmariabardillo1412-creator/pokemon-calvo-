#!/usr/bin/env python3
"""Strict W02 AUTORUN V2 source checks; Godot performs actual red/green tests."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
f=json.loads((root/"tests/fixtures/parallel_items/w02_autorun_v2.json").read_text(encoding="utf-8"))
assert f["worker"]=="W02" and f["tanda"]=="02"
assert len(f["rows"])==10 and [x["row"] for x in f["rows"]]==[f"{i:02d}" for i in range(1,11)]
gd=(root/"tests/gameplay/parallel_items_w02_autorun_v2.gd").read_text(encoding="utf-8")
for mark in ["GrowthV2.validation_error(now, catalogs)","MochiV2.validation_error(now, -1, catalogs)","svc.use_growth_item(item, &\"own\")","svc.use_item(item, &\"own\")","SaveV2","W02_AUTORUN_V2_GODOT"]:
    assert mark in gd,mark
print("W02_AUTORUN_V2_PY PASS rows=10 checks=10")
