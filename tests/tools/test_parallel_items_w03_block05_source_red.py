#!/usr/bin/env python3
"""Intentional RED contract test: no fabricated water/fishing capture provenance."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
session=(ROOT/"modules/gameplay/wild_adventure_session.gd").read_text()
context=(ROOT/"modules/capture/capture_battle_context.gd").read_text()
director=(ROOT/"modules/overworld/overworld_encounter_director.gd").read_text()
demo=(ROOT/"scenes/visual/field_demo.gd").read_text()
# This test MUST fail until IA6 delivers a trusted, real source-to-session seam.
assert "encounter_origin" in session and "encounter_origin" in context, (
    "RED: no authenticated encounter origin reaches CaptureBattleContext from live session"
)
assert "encounter_origin" in director or "encounter_origin" in demo, (
    "RED: no live encounter producer supplies fishing/surf/dive origin"
)
print("CAMP006_W03_BLOCK05_SOURCE CONTRACT PRESENT (not a full functional PASS)")
