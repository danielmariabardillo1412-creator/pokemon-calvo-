#!/usr/bin/env python3
"""V5 W03: pin protected IA6/V4 blobs and verify in-scope Repel wiring.

The historical W03 CAMP006 test has the only IA6-authorized one-line
zone fixture correction. Reconstruct the original Git blob to verify that
every other byte and assertion stays unchanged. The independent V5 test
still exercises the actual grass zone separately.
"""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
checks = 0


def ck(ok, reason):
    global checks
    checks += 1
    if not ok:
        raise AssertionError(reason)


def body(path):
    return (ROOT / path).read_text(encoding="utf-8")


def git_blob(path):
    return subprocess.check_output(
        ["git", "hash-object", str(ROOT / path)],
        cwd=ROOT, text=True).strip()


def function(text, name):
    key = "func " + name + "("
    i = text.find(key)
    ck(i >= 0, "missing function " + name)
    j = text.find("\nfunc ", i + len(key))
    return text[i:j if j >= 0 else len(text)]


def main():
    protected = {
        "modules/creatures/domain/creature_instance.gd": "bd70d1ce2ff6b78129525ba3bda34667f62c12d4",
        "modules/save/field_native_save.gd": "f89118f8fb702399c46fdfe0a8ddf27383daef4e",
        "modules/save/save_game_data.gd": "0b8bf57c53a06a26d006d2b08206dbfcab60972e",
        "modules/gameplay/showdown_adventure_session.gd": "e4bb33dffef5a40ce6e8c55cf7f5960a3a85d5be",
        "modules/gameplay/wild_adventure_session.gd": "f8aacfdeb24a317d865717c98add76712a3b8196",
        "modules/battle/backends/showdown/native_engine.cjs": "073e5c8523f47a477735b98a766437392c201e33",
        "config/item_selection_v1.json": "bf76a361b30e158f613f31ef275006862562cea8",
    }
    for path, sha in protected.items():
        ck(git_blob(path) == sha, "protected IA6/V4 blob drift: " + path)
    # IA6 one-line authorization: restore the exact old line and hash the
    # reconstructed original Git blob. This rejects any other test mutation,
    # including added/removed assertions, whitespace changes or weak waivers.
    original_line = "var zone: StringName = scene._director.registered_zone_ids()[0]"
    approved_line = "var zone: StringName = scene.TECHNICAL_ZONE_ID"
    historical = body("tests/gameplay/parallel_items_w03_repel_l3.gd")
    ck(historical.count(approved_line) == 1 and original_line not in historical,
       "the one-line corrected real-grass historical fixture is required")
    restored_original = historical.replace(approved_line, original_line, 1)
    original_blob = subprocess.check_output(
        ["git", "hash-object", "--stdin"], input=restored_original,
        cwd=ROOT, text=True).strip()
    ck(original_blob == "318ee45f60d9ee046bcb048019337524acfb4844",
       "historical fixture differs beyond the sole authorized zone replacement")
    ck(git_blob("modules/overworld/field_repel_step_effect.gd")
       == "7dbd62dd8238191e2101f25687d3e12d5d61a693",
       "canonical existing real-steps helper was changed")
    cfg = json.loads(body("config/item_selection_v1.json"))
    ck("dynamax_candy" in cfg["excluded_ids"], "Dynamax Candy exclusion lost")
    ck("rare_candy" not in cfg["excluded_ids"], "other Candies wrongly excluded")
    bag = body("scenes/visual/field_item_bag.gd")
    refresh = function(bag, "_refresh_choices")
    apply = function(bag, "_apply")
    repel = function(bag, "_apply_repel")
    book = function(bag, "_open_machine_books")
    book_cb = function(bag, "_on_book_teaching_finished")
    rope = function(bag, "_apply_escape_rope")
    ck("field._repel_effect.remaining_steps > 0" in refresh,
       "repel UI does not honor active effect")
    ck("return _apply_repel()" in apply and "return await _apply_escape_rope()" in apply,
       "repel dispatch or Rope dispatch missing")
    ck("field.field_can_use_items()" in repel and "_ensure_binding()" in repel,
       "repel preflight lost")
    ck("effect.restore(previous)" in repel and "if not inv.remove(item_id, 1):" in repel,
       "repel failed inventory commit must rollback effect")
    ck("not inv.has(item_id)" in repel and "effect.remaining_steps > 0" in repel,
       "repel stale stock / active duplicate guard lost")
    ck("bind_existing_service(service)" in book and "select_book(item_id)" in book
       and "_books_panel.show()" in book, "W05 book panel integration lost")
    ck("service.teach(" not in book_cb and "field.field_refresh_hud()" in book_cb,
       "W05 callback must not teach or double spend")
    ck("_world_item_tx.prepare(field, service.owner)" in rope
       and "_world_item_tx.execute(field, prepared)" in rope,
       "real Escape Rope world transaction lost")
    world = body("scenes/visual/field_demo.gd")
    bridge = body("scenes/visual/field_native_bridge.gd")
    ck("var _repel_effect := FieldRepel.new()" in world
       and "_repel_effect.attach(player)" in world,
       "real player step signal is not bound")
    encounter = function(world, "field_prepare_native_encounter")
    ck("WildEncounterSystem.resolve" in encounter
       and "_repel_effect.blocks_level(encounter.creature.level, leader.level)" in encounter,
       "wild repulsion must use real rolled creature and leader level")
    ck('return {"blocked_by_repel": true, "next_rng": staged.state}' in encounter,
       "suppression must stage only encounter RNG and skip native spawn")
    ck("field_commit_repelled_encounter_rng" in world
       and "_director._encounter_rng.state = next_rng" in world,
       "suppressed encounter must commit the real one-time RNG")
    ck('"repel": _repel_effect.to_dict()' in function(world, "field_native_world_snapshot"),
       "repel SaveV2 world snapshot absent")
    validate = function(world, "field_validate_native_loaded_world")
    ck("world_repel_shape" in validate and "world_repel_range" in validate
       and "FieldRepel.DURATIONS.has(sid)" in validate,
       "hostile optional Repel SaveV2 source should be validated before publication")
    ck('_repel_effect.restore(world.get("repel", {"schema_version": 1, "active_id": "", "remaining_steps": 0}))'
       in function(world, "field_publish_native_loaded_world"),
       "legacy SaveV2 missing-field fallback must reset effect")
    on_step = function(bridge, "on_step")
    ck("if bool(prepared.get(\"blocked_by_repel\", false)):" in on_step
       and "field.field_commit_repelled_encounter_rng" in on_step,
       "bridge must intercept repelled encounters before creating native battle")
    corrected = body("tests/gameplay/parallel_items_w03_v5_repel_grass.gd")
    ck("scene.TECHNICAL_ZONE_ID" in corrected
       and "scene._director.registered_zone_ids()[0]" not in corrected,
       "new independent V5 grass fixture still picks alphabetically-first cave")
    director = body("modules/overworld/overworld_encounter_director.gd")
    ck("func registered_zone_ids()" in director and "out.sort()" in director,
       "historical fixture root cause changed without authority")
    ck('zone_id = &"technical_grass"' in body("scenes/overworld/technical_overworld.tscn")
       and 'zone_id = &"technical_cave_floor"' in body("scenes/overworld/technical_overworld.tscn"),
       "original world zone identities unavailable")
    print(f"W03_V5_SOURCE PASS checks={checks} protected={len(protected)} "
          f"historical_fixture_one_line=true actual_grass_fixture=true dynamax_veto=true")


if __name__ == "__main__":
    main()
