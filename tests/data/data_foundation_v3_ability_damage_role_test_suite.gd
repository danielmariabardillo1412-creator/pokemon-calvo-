class_name DataFoundationV3AbilityDamageRoleTestSuite
extends RefCounted

var _catalog: DefinitionCatalog
var _client := BattleClient.new()


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(
		_load_json("res://data/manifests/pokemon_api_manifest.json")
	)
	var imported := DataImporter.new().import_dataset(raw, manifest)
	var game_data: GameData = imported.get("game_data")
	_catalog = game_data.to_definition_catalog()
	var by_id := _by_id(raw.get("abilities", []))
	var registry := BattleEffectRegistry.new()

	var ember := _catalog.move(&"ember")
	var tackle := _catalog.move(&"tackle")
	var water_gun := _catalog.move(&"water_gun")
	var will_o_wisp := _catalog.move(&"will_o_wisp")
	check.call(
		"data_v3_damage_role_move_metadata",
		ember != null and ember.type_id == &"fire"
		and tackle != null and tackle.damage_class == "physical"
		and water_gun != null and water_gun.type_id == &"water"
		and will_o_wisp != null and will_o_wisp.power == 0,
	)

	# Every ability damage modifier must opt into exactly one side. An omitted role
	# is deliberately inert in BattleTriggerSystem so future registrations fail safe.
	var all_roles_explicit := true
	var damage_spec_count := 0
	for ability_id in registry.implemented_ability_ids():
		for spec in registry.triggers_for_ability(ability_id, BattleTriggerSpec.MODIFY_DAMAGE):
			damage_spec_count += 1
			var role := String(spec.conditions.get("damage_role", ""))
			all_roles_explicit = all_roles_explicit and role in ["actor", "target"]
	check.call(
		"data_v3_damage_role_all_modifier_specs_explicit",
		damage_spec_count > 0 and all_roles_explicit,
	)

	# Regression for the pre-#88 bug: Blaze is actor-owned. A low-HP defender with
	# Blaze must not amplify an incoming Fire move.
	var blaze_target := _server(9301, &"ember", &"", &"blaze", 160)
	var blaze_target_events := blaze_target.submit_turn(_actions(blaze_target.state, &"ember"))
	var plain_low_target := _server(9301, &"ember", &"", &"", 160)
	var plain_low_target_events := plain_low_target.submit_turn(
		_actions(plain_low_target.state, &"ember")
	)
	check.call(
		"data_v3_damage_role_offensive_ability_defender_inert",
		_damage_to(blaze_target_events, &"b") == _damage_to(plain_low_target_events, &"b")
		and not _source_triggered(blaze_target_events, "blaze", &"b"),
	)

	# Mirror regression: Fur Coat is target-owned. Giving it to the attacker must
	# not halve that attacker's own physical damage.
	var fur_actor := _server(9302, &"tackle", &"fur_coat", &"")
	var fur_actor_events := fur_actor.submit_turn(_actions(fur_actor.state, &"tackle"))
	var plain_actor := _server(9302, &"tackle", &"", &"")
	var plain_actor_events := plain_actor.submit_turn(_actions(plain_actor.state, &"tackle"))
	check.call(
		"data_v3_damage_role_defensive_ability_attacker_inert",
		_damage_to(fur_actor_events, &"b") == _damage_to(plain_actor_events, &"b")
		and not _source_triggered(fur_actor_events, "fur_coat", &"a"),
	)

	# Water Bubble partial: outgoing Water damage is doubled.
	var bubble_water := _server(9303, &"water_gun", &"water_bubble", &"")
	var bubble_water_events := bubble_water.submit_turn(_actions(bubble_water.state, &"water_gun"))
	var plain_water := _server(9303, &"water_gun", &"", &"")
	var plain_water_events := plain_water.submit_turn(_actions(plain_water.state, &"water_gun"))
	check.call(
		"data_v3_water_bubble_outgoing_water_double",
		_damage_to(bubble_water_events, &"b") > _damage_to(plain_water_events, &"b")
		and _source_triggered(bubble_water_events, "water_bubble", &"a"),
	)

	# Water Bubble partial: incoming Fire damage is halved.
	var bubble_fire_target := _server(9304, &"ember", &"", &"water_bubble")
	var bubble_fire_target_events := bubble_fire_target.submit_turn(
		_actions(bubble_fire_target.state, &"ember")
	)
	var plain_fire_target := _server(9304, &"ember", &"", &"")
	var plain_fire_target_events := plain_fire_target.submit_turn(
		_actions(plain_fire_target.state, &"ember")
	)
	check.call(
		"data_v3_water_bubble_incoming_fire_half",
		_damage_to(bubble_fire_target_events, &"b") > 0
		and _damage_to(bubble_fire_target_events, &"b") < _damage_to(plain_fire_target_events, &"b")
		and _source_triggered(bubble_fire_target_events, "water_bubble", &"b"),
	)

	# The two Water Bubble specs must not leak into the opposite role.
	var bubble_actor_fire := _server(9305, &"ember", &"water_bubble", &"")
	var bubble_actor_fire_events := bubble_actor_fire.submit_turn(
		_actions(bubble_actor_fire.state, &"ember")
	)
	var plain_actor_fire := _server(9305, &"ember", &"", &"")
	var plain_actor_fire_events := plain_actor_fire.submit_turn(
		_actions(plain_actor_fire.state, &"ember")
	)
	var bubble_target_water := _server(9306, &"water_gun", &"", &"water_bubble")
	var bubble_target_water_events := bubble_target_water.submit_turn(
		_actions(bubble_target_water.state, &"water_gun")
	)
	var plain_target_water := _server(9306, &"water_gun", &"", &"")
	var plain_target_water_events := plain_target_water.submit_turn(
		_actions(plain_target_water.state, &"water_gun")
	)
	check.call(
		"data_v3_water_bubble_opposite_roles_inert",
		_damage_to(bubble_actor_fire_events, &"b") == _damage_to(plain_actor_fire_events, &"b")
		and _damage_to(bubble_target_water_events, &"b") == _damage_to(plain_target_water_events, &"b")
		and not _source_triggered(bubble_actor_fire_events, "water_bubble", &"a")
		and not _source_triggered(bubble_target_water_events, "water_bubble", &"b"),
	)

	# Burn prevention/cure is source-required but deliberately absent from this
	# partial runtime contract. Pin the gap so it cannot be mistaken for full support.
	var bubble_burn := _server(9307, &"will_o_wisp", &"", &"water_bubble")
	var bubble_burn_events := bubble_burn.submit_turn(_actions(bubble_burn.state, &"will_o_wisp"))
	check.call(
		"data_v3_water_bubble_burn_prevention_gap_explicit",
		bubble_burn.state.creature(&"b").status_state.persistent_id == StatusSystem.BURN
		and not _source_triggered(bubble_burn_events, "water_bubble", &"b"),
	)

	# Dry Skin partial: exact 1.25x incoming Fire vulnerability.
	var dry_fire_target := _server(9308, &"ember", &"", &"dry_skin")
	var dry_fire_target_events := dry_fire_target.submit_turn(_actions(dry_fire_target.state, &"ember"))
	var dry_plain_fire := _server(9308, &"ember", &"", &"")
	var dry_plain_fire_events := dry_plain_fire.submit_turn(_actions(dry_plain_fire.state, &"ember"))
	check.call(
		"data_v3_dry_skin_incoming_fire_vulnerability",
		_damage_to(dry_fire_target_events, &"b") > _damage_to(dry_plain_fire_events, &"b")
		and _source_triggered(dry_fire_target_events, "dry_skin", &"b"),
	)

	# Dry Skin is target-only; it must not strengthen an attacker's own Fire move.
	var dry_actor_fire := _server(9309, &"ember", &"dry_skin", &"")
	var dry_actor_fire_events := dry_actor_fire.submit_turn(_actions(dry_actor_fire.state, &"ember"))
	var dry_plain_actor := _server(9309, &"ember", &"", &"")
	var dry_plain_actor_events := dry_plain_actor.submit_turn(_actions(dry_plain_actor.state, &"ember"))
	check.call(
		"data_v3_dry_skin_actor_fire_inert",
		_damage_to(dry_actor_fire_events, &"b") == _damage_to(dry_plain_actor_events, &"b")
		and not _source_triggered(dry_actor_fire_events, "dry_skin", &"a"),
	)

	# Water absorption/heal and weather are not represented in this tranche. A Water
	# move therefore still deals the ordinary damage and does not trigger Dry Skin.
	var dry_water_target := _server(9310, &"water_gun", &"", &"dry_skin")
	var dry_water_target_events := dry_water_target.submit_turn(
		_actions(dry_water_target.state, &"water_gun")
	)
	var dry_plain_water := _server(9310, &"water_gun", &"", &"")
	var dry_plain_water_events := dry_plain_water.submit_turn(
		_actions(dry_plain_water.state, &"water_gun")
	)
	check.call(
		"data_v3_dry_skin_water_absorption_gap_explicit",
		_damage_to(dry_water_target_events, &"b") > 0
		and _damage_to(dry_water_target_events, &"b") == _damage_to(dry_plain_water_events, &"b")
		and not _source_triggered(dry_water_target_events, "dry_skin", &"b"),
	)

	# Pinned snapshot does not contain numeric boost values for these two records;
	# source guards deliberately keep them non-executable until provenance improves.
	var prose_only_blockers_ok := true
	for ability_id in ["gorilla_tactics", "steely_spirit"]:
		prose_only_blockers_ok = prose_only_blockers_ok and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE).is_empty()
		)
	check.call("data_v3_prose_only_boosts_stay_data_only", prose_only_blockers_ok)

	check.call(
		"data_v3_compound_partial_classifications",
		str((by_id.get("water_bubble", {}) as Dictionary).get("classification", "")) == "PARTIAL_RUNTIME"
		and str((by_id.get("dry_skin", {}) as Dictionary).get("classification", "")) == "PARTIAL_RUNTIME",
	)


func _server(
	seed: int,
	move_a: StringName,
	actor_ability: StringName,
	target_ability: StringName,
	target_pre_damage: int = 0,
) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_damage_role", [
		_creature(&"a", &"charmander", [move_a], 30),
		_creature(&"b", &"squirtle", [&"growl"], 20),
	], seed)
	state.creature(&"a").ability_id = actor_ability
	state.creature(&"b").ability_id = target_ability
	if target_pre_damage > 0:
		state.creature(&"b").apply_damage(target_pre_damage)
	return AuthoritativeBattleServer.new(state, _catalog)


func _creature(
	id: StringName,
	species_id: StringName,
	moves: Array[StringName],
	speed: int,
) -> CreatureInstance:
	return CreatureInstance.new(
		id,
		species_id,
		30,
		StatBlock.new(240, 60, 55, speed, 60, 55),
		moves,
	)


func _actions(state: BattleState, move_a: StringName) -> Array[BattleAction]:
	return [
		_client.request_move(
			state.turn + 1, &"a", move_a, state.opponent_of(&"a").instance_id, &"side_a"
		),
		_client.request_move(
			state.turn + 1, &"b", &"growl", state.opponent_of(&"b").instance_id, &"side_b"
		),
	]


func _damage_to(events: Array[BattleEvent], target_id: StringName) -> int:
	for event in events:
		if event.kind == BattleEvent.DAMAGE_APPLIED and event.target_id == target_id:
			return event.amount
	return 0


func _source_triggered(
	events: Array[BattleEvent],
	source_id: String,
	owner_id: StringName,
) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.ABILITY_TRIGGERED
			and event.actor_id == owner_id
			and event.metadata.get("source_id", "") == source_id
		):
			return true
	return false


func _by_id(records: Array) -> Dictionary:
	var result := {}
	for record in records:
		if record is Dictionary:
			result[str(record.get("id", ""))] = record
	return result


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
