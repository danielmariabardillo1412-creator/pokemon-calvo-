#!/usr/bin/env python3
"""One-shot DATA V3 repair helper for PR #105.

This file is temporary. It applies source/test edits with exact anchors. The
GitHub Actions helper that invokes it also regenerates canonical DATA V3 outputs
from the immutable PokeAPI snapshot. Remove this file before final certification.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected exactly one anchor in {path}, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def patch_adapter() -> None:
    path = ROOT / "tools" / "pokeapi_adapter.py"
    helper_anchor = "\ndef generate_move_specs(m: dict, contact_set: set):\n"
    helper = r'''

def _retarget_damage_user_stat_subtrees(specs: list[dict]) -> bool:
    """Retarget stat-change branches to SELF and report whether subtree contains one."""
    subtree_has_stage = False
    for spec in specs:
        children = spec.get("children") or []
        child_has_stage = False
        if isinstance(children, list):
            child_has_stage = _retarget_damage_user_stat_subtrees(children)
        if spec.get("kind") == "modify_stat_stage":
            spec["target"] = "self"
            subtree_has_stage = True
        elif child_has_stage:
            # The legacy converter wraps probabilistic stat changes in CHANCE and
            # copied the same false target onto that wrapper. It is execution-neutral
            # today, but keeping the complete branch semantically coherent prevents
            # later consumers from reading a contradictory target.
            if spec.get("kind") == "chance":
                spec["target"] = "self"
            subtree_has_stage = True
    return subtree_has_stage


def _repair_damage_user_stat_family(m: dict, specs: list[dict], sid: str) -> None:
    """Source-audit and repair PokeAPI move-category damage-raise stat targets.

    In PokeAPI this category means a damaging move whose stat_changes belong to
    the user. The move's general target still describes who receives DAMAGE, so
    deriving stat target from move.target is invalid (e.g. Close Combat,
    Superpower, Overheat, Metal Claw, Flame Charge).
    """
    meta = m.get("meta") or {}
    category = (meta.get("category") or {}).get("name")
    if category != "damage-raise":
        return

    damage_class = (m.get("damage_class") or {}).get("name")
    power = int(m.get("power") or 0)
    source_changes: list[tuple[str, int]] = []
    for change in m.get("stat_changes") or []:
        source_name = (change.get("stat") or {}).get("name")
        stat_id = _legacy.STAT_MAP.get(source_name)
        if stat_id is None:
            raise RuntimeError(
                f"DATA V3 damage-user-stat family has unmapped stat for {sid}: {source_name}"
            )
        source_changes.append((str(stat_id), int(change.get("change", 0))))

    if damage_class not in ("physical", "special") or power <= 0 or not source_changes:
        raise RuntimeError(
            f"DATA V3 damage-user-stat source shape changed for {sid}: "
            f"class={damage_class} power={power} changes={source_changes}"
        )

    stages = _matching_effects(specs, "modify_stat_stage")
    generated_changes = sorted(
        (str(stage.get("stat_id", "")), int(stage.get("value", 0)))
        for stage in stages
    )
    if generated_changes != sorted(source_changes):
        raise RuntimeError(
            f"DATA V3 damage-user-stat generated changes mismatch for {sid}: "
            f"source={source_changes} generated={generated_changes}"
        )
    if any(stage.get("target") not in ("opponent", "self") for stage in stages):
        raise RuntimeError(
            f"DATA V3 damage-user-stat unexpected generated target for {sid}: {stages}"
        )

    _retarget_damage_user_stat_subtrees(specs)
    repaired = _matching_effects(specs, "modify_stat_stage", "self")
    if len(repaired) != len(source_changes):
        raise RuntimeError(
            f"DATA V3 damage-user-stat repair incomplete for {sid}: {specs}"
        )
'''
    replace_once(path, helper_anchor, helper + helper_anchor)

    call_anchor = '    sid = _legacy.slug(str(m.get("name", "")))\n\n    if sid in _SIMPLE_SELF_HEALS:\n'
    call_replacement = (
        '    sid = _legacy.slug(str(m.get("name", "")))\n\n'
        '    _repair_damage_user_stat_family(m, specs, sid)\n\n'
        '    if sid in _SIMPLE_SELF_HEALS:\n'
    )
    replace_once(path, call_anchor, call_replacement)


def patch_data_workflow() -> None:
    path = ROOT / ".github" / "workflows" / "data-foundation-v3-tests.yml"
    anchor = "          assert moves['tackle']['display_name'] in ('Placaje', 'Tackle')\n\n"
    insertion = r'''          assert moves['tackle']['display_name'] in ('Placaje', 'Tackle')

          # DATA V3 regression — PokeAPI move-category/7 (damage-raise) stores
          # stat_changes that apply to the USER even though the damaging move's
          # general target is the opponent. Never derive these stat targets from
          # move.target. Audit the whole immutable category, not hand-picked moves.
          damage_user_category = json.load(open(
              'data/api/v2/move-category/7/index.json', encoding='utf-8'))
          damage_user_ids = []
          for entry in damage_user_category['moves']:
              source_numeric_id = entry['url'].rstrip('/').split('/')[-1]
              source_move = json.load(open(
                  f'data/api/v2/move/{source_numeric_id}/index.json', encoding='utf-8'))
              move_id = source_move['name'].replace('-', '_')
              source_changes = sorted(
                  (change['stat']['name'].replace('-', '_'), int(change['change']))
                  for change in source_move.get('stat_changes', [])
              )
              assert source_changes, (move_id, source_move.get('stat_changes'))
              generated_stages = matching_effects(
                  moves[move_id]['effect_specs'], 'modify_stat_stage')
              generated_changes = sorted(
                  (stage['stat_id'], int(stage['value'])) for stage in generated_stages)
              assert generated_changes == source_changes, (
                  move_id, source_changes, generated_changes)
              assert all(stage['target'] == 'self' for stage in generated_stages), (
                  move_id, generated_stages)
              damage_user_ids.append(move_id)
          assert len(damage_user_ids) == 28, damage_user_ids
          assert {'close_combat', 'superpower', 'hammer_arm', 'overheat', 'draco_meteor'}.issubset(
              set(damage_user_ids))

'''
    replace_once(path, anchor, insertion)


def write_runtime_suite() -> None:
    path = ROOT / "tests" / "data" / "data_v3_damage_user_stat_target_test_suite.gd"
    if path.exists():
        raise RuntimeError(f"Runtime regression suite already exists: {path}")
    path.write_text(r'''class_name DataV3DamageUserStatTargetTestSuite
extends RefCounted

var _check: Callable
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	var file := FileAccess.open("res://data/normalized/pokemon_api.json", FileAccess.READ)
	_expect("data_v3_self_debuff_dataset_open", file != null)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	_expect("data_v3_self_debuff_dataset_parse", parsed is Dictionary)
	if not (parsed is Dictionary):
		return
	var game_data := GameData.from_dict(parsed)
	var catalog := game_data.to_definition_catalog()
	var move := catalog.move(&"close_combat")
	_expect("data_v3_close_combat_present", move != null)
	if move == null:
		return

	var stages: Array[BattleEffectSpec] = []
	_collect_stat_stages(move.effect_specs, stages)
	_expect("data_v3_close_combat_has_two_stat_changes", stages.size() == 2)
	var all_self := stages.size() == 2
	var has_defense := false
	var has_special_defense := false
	for stage in stages:
		all_self = all_self and stage.target == BattleEffectSpec.SELF
		if stage.stat_id == &"defense" and stage.value == -1:
			has_defense = true
		if stage.stat_id == &"special_defense" and stage.value == -1:
			has_special_defense = true
	_expect("data_v3_close_combat_specs_target_self", all_self)
	_expect("data_v3_close_combat_specs_match_cost", has_defense and has_special_defense)

	# End-to-end Battle Core regression: executing the real DATA V3 move must lower
	# the user's stages and must not debuff the target.
	var state := BattleState.new(&"data_v3_self_debuff", [
		CreatureInstance.new(
			&"a", &"charmander", 30,
			StatBlock.new(220, 80, 70, 40, 60, 70),
			[&"close_combat"],
		),
		CreatureInstance.new(
			&"b", &"squirtle", 30,
			StatBlock.new(1000, 60, 120, 20, 60, 120),
			[&"tackle"],
		),
	], 91021)
	var server := AuthoritativeBattleServer.new(state, catalog)
	var events := server.submit_turn([
		_client.request_move(1, &"a", &"close_combat", &"b", &"side_a"),
		_client.request_move(1, &"b", &"tackle", &"a", &"side_b"),
	])
	var actor := server.state.creature(&"a")
	var target := server.state.creature(&"b")
	_expect(
		"data_v3_close_combat_runtime_lowers_user",
		actor.stat_stages.get_stage(&"defense") == -1
		and actor.stat_stages.get_stage(&"special_defense") == -1,
	)
	_expect(
		"data_v3_close_combat_runtime_does_not_debuff_target",
		target.stat_stages.get_stage(&"defense") == 0
		and target.stat_stages.get_stage(&"special_defense") == 0,
	)
	var self_stage_events := 0
	var target_stage_events := 0
	for event in events:
		if event.kind == BattleEvent.STAT_STAGE_CHANGED and event.target_id == &"a":
			self_stage_events += 1
		if event.kind == BattleEvent.STAT_STAGE_CHANGED and event.target_id == &"b":
			target_stage_events += 1
	_expect("data_v3_close_combat_runtime_emits_two_self_stage_events", self_stage_events == 2)
	_expect("data_v3_close_combat_runtime_emits_no_target_stage_event", target_stage_events == 0)


func _collect_stat_stages(
	specs: Array[BattleEffectSpec], out: Array[BattleEffectSpec]
) -> void:
	for spec in specs:
		if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
			out.append(spec)
		_collect_stat_stages(spec.children, out)


func _expect(name: String, condition: bool) -> void:
	_check.call(name, condition)
''', encoding="utf-8")


def patch_runtime_runner() -> None:
    path = ROOT / "tests" / "data" / "spanish_types_foundation_test_runner.gd"
    anchor = '\tSpanishTypeResourcesTestSuite.new().run(Callable(self, "_check"))\n'
    replacement = (
        '\tSpanishTypeResourcesTestSuite.new().run(Callable(self, "_check"))\n'
        '\tDataV3DamageUserStatTargetTestSuite.new().run(Callable(self, "_check"))\n'
    )
    replace_once(path, anchor, replacement)


def main() -> None:
    patch_adapter()
    patch_data_workflow()
    write_runtime_suite()
    patch_runtime_runner()
    print("DATA V3 damage-user-stat source/test patch applied")


if __name__ == "__main__":
    main()
