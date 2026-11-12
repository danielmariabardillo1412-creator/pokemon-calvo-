#!/usr/bin/env python3
"""W03 V6 strict boundaries and RED source provenance; requires real Godot tests too."""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = "3ea669de00750cc2bc7950ed83783aec77237ac7"
checks = 0

def ck(ok, label):
    global checks
    checks += 1
    if not ok:
        raise AssertionError("W03_V6_SOURCE: " + label)

def src(path):
    return (ROOT / path).read_text(encoding="utf-8")

def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()

def sha(path):
    return git("hash-object", path)

def run():
    protected = (
        "scenes/visual/field_item_bag.gd",
        "modules/creatures/domain/creature_instance.gd",
        "modules/battle/backends/showdown/native_engine.cjs",
        "config/item_selection_v1.json",
        "modules/inventory/field_item_service.gd",
        "modules/save/field_native_save.gd",
        "modules/save/save_game_data.gd",
        "modules/gameplay/wild_adventure_session.gd",
    )
    for path in protected:
        ck(sha(path) == git("rev-parse", f"{BASE}:{path}"), "immutable protected source changed " + path)
    selection = json.loads(src("config/item_selection_v1.json"))
    ck("dynamax_candy" in selection["excluded_ids"], "Dynamax Candy MUST stay excluded")
    ck("dusk_ball" not in selection["excluded_ids"], "Dusk already selected")
    allowed = {
        "docs/coordination/items_parallel_v1/integration/OPENAGENT_PILOT.md",
        "modules/capture/capture_battle_context.gd",
        "modules/capture/capture_context_ball_effects.gd",
        "modules/gameplay/showdown_adventure_session.gd",
        "scenes/visual/field_demo.gd",
        "scenes/visual/field_native_bridge.gd",
        "tests/gameplay/ia6_regional_level_field.gd",
        "tests/gameplay/parallel_items_w03_dusk_native_v6.gd",
        "tests/gameplay/parallel_items_w03_dusk_native_v6_negatives.gd",
        "tests/tools/test_openagent_dusk_source_guard.py",
        ".github/workflows/openagent-pilot.yml",
    }
    changed = set(git("diff", "--name-only", BASE).splitlines())
    changed.update(git("ls-files", "--others", "--exclude-standard").splitlines())
    ck(changed <= allowed, "paths outside pilot permission: " + str(sorted(changed - allowed)))
    base_context = git("show", BASE + ":modules/capture/capture_context_ball_effects.gd")
    ck('dusk_ball' not in base_context, "RED baseline Dusk absent from contextual rules")
    base_bridge = git("show", BASE + ":scenes/visual/field_native_bridge.gd")
    ck("field_native_capture_zone" not in base_bridge and "bind_native_field_source" not in base_bridge,
       "RED baseline authentic cave producer not wired")
    effects = src("modules/capture/capture_context_ball_effects.gd")
    ck(re.search(r'&"moon_ball"\s*,\s*&"dusk_ball"', effects) is not None,
       "Dusk must be a contextual CaptureRuleset ball")
    ck('3.0 if context.native_field_zone_id == &"technical_cave_floor" else 1.0' in effects,
       "Gen VII+ exact cave x3/normal x1 required")
    context = src("modules/capture/capture_battle_context.gd")
    ck('var native_field_zone_id: StringName = &""' in context,
       "unknown source context must default empty")
    field = src("scenes/visual/field_demo.gd")
    ck("func field_native_capture_zone(" in field
       and "zone_at_position(position) != expected_zone" in field
       and "_director.has_zone(expected_zone)" in field
       and "player.global_position.is_equal_approx(position)" in field
       and "technical_region_id()" in field, "authored physical field validation missing")
    bridge = src("scenes/visual/field_native_bridge.gd")
    ck("await _open(encounter.creature" in bridge
       and "bind_native_field_source(Callable(field, \"field_native_capture_zone\").bind(" in bridge,
       "real native encounter must install dynamic physical source")
    ck("loaded.battle.get(\"origin\"" in bridge
       and "field.field_publish_native_loaded_world" in bridge
       and "field.zone_at_position(position)" in bridge, "restore source must derive from live validated position")
    session = src("modules/gameplay/showdown_adventure_session.gd")
    ck("func bind_native_field_source(" in session
       and "target.instance_id == _native_zone_target_id" in session
       and "context.native_field_zone_id = actual_zone" in session,
       "native attempt must validate original target and live source")
    ck('"native_field_zone_id"' not in src("modules/save/save_game_data.gd")
       and "dusk" not in src("modules/save/field_native_save.gd").lower(),
       "do not persist artificial Dusk bonus to SaveV2")
    for name in ["parallel_items_w03_dusk_native_v6", "parallel_items_w03_dusk_native_v6_negatives"]:
        test = src("tests/gameplay/" + name + ".gd")
        ck('res://scenes/visual/field_demo.tscn' in test
           and "_on_player_step_completed" in test
           and 'capture(&"dusk_ball"' in test,
           "test needs real field -> native capture, not mocked context " + name)
    positive = src("tests/gameplay/parallel_items_w03_dusk_native_v6.gd")
    ck('get_node("CaveEncounterZone")' in positive
       and 'get_node("EncounterZone")' in positive
       and 'bridge.load_game()' in positive,
       "positive must compare authored cave/grass and native SaveV2")
    negative = src("tests/gameplay/parallel_items_w03_dusk_native_v6_negatives.gd")
    ck('"capture_result"' in negative and "source.call() == &\"\"" in negative,
       "missing producer/actual capture RNG negative proof required")
    print(f"W03_V6_SOURCE PASS checks={checks} protected={len(protected)} baseline_red=2 dusk_factor=3 veto_dynamax=true")

if __name__ == "__main__":
    run()
