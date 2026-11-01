#!/usr/bin/env python3
"""Recalcula A: comprobar las 2.222 filas con fuentes V27, sin declarar efectos."""
from __future__ import annotations
import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
path = ROOT / "tools/item_audit/item_closure_v3.py"
spec = importlib.util.spec_from_file_location("item_closure_v3", path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
report = mod.generate()
rows = report["rows"]
by_id = {x["id"]: x for x in rows}
assert len(rows) == 2222 and len(by_id) == 2222
assert sum(x["excluded"] for x in rows) == 44
assert sum(x["equip_permitted"] for x in rows) == 624
assert sum(x["native_descriptor_v27_documented"] for x in rows) == 621
assert report["explicit_missing_native"] == ["amulet_coin", "exp_share", "luck_incense"]
assert sum(x["scenario_executed_at_v3"] for x in rows) == 0
assert all(x["historical_snapshot"]["not_current_assertion"] for x in rows)
assert all(by_id[i]["effect_current_status"] == "IMPLEMENTED_UNVERIFIED_AT_V3_CHECKPOINT" for i in mod.POWER)
assert by_id["linking_cord"]["excluded"]
assert all(not by_id[i]["excluded"] for i in ["metal_coat", "dragon_scale", "electirizer"])
assert by_id["exp_share"]["dependency"] == "XP_EV_RECIPIENT_PROFILE"
assert all(by_id[i]["dependency"] == "ECONOMY" for i in ["amulet_coin", "luck_incense"])
assert not report.get("all_item_effects_certified", False)
print("ITEM_CLOSURE_V3_AUDIT PASS checks=15 ids=2222")
