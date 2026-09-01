class_name DataFoundationV3AbilityContactRetaliationTestSuite
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

	var tackle := _catalog.move(&"tackle")
	var water_gun := _catalog.move(&"water_gun")
	var double_kick := _catalog.move(&"double_kick")
	var double_kick_multi := false
	if double_kick != null:
		for spec in double_kick.effect_specs:
			if (
				spec.kind == BattleEffectSpec.MULTI_HIT
				and spec.min_hits == 2
				and spec.max_hits == 2
			):
				double_kick_multi = true
	check.call(
		"data_v3_contact_retaliation_move_metadata",
		tackle != null and tackle.makes_contact
		and water_gun != null and not water_gun.makes_contact
		and double_kick != null and double_kick.makes_contact and double_kick_multi,
	)

	# MAX_HP_DAMAGE is a generic serializable effect primitive rather than a hidden
	# Iron Barbs special case.
	var original := BattleEffectSpec.new(
		BattleEffectSpec.MAX_HP_DAMAGE, BattleEffectSpec.OPPONENT, 0, 1250
	)
	var restored := BattleEffectSpec.from_dict(original.to_dict())
	check.call(
		"data_v3_contact_retaliation_effect_roundtrip",
		restored.kind == BattleEffectSpec.MAX_HP_DAMAGE
		and restored.target == BattleEffectSpec.OPPONENT
		and restored.ratio_basis_points == 1250,
	)

	# Ordinary surviving contact: attacker has 240 max HP, so Iron Barbs must remove
	# exactly floor(240 / 8) = 30 HP and emit a defender-owned ability event.
	var contact := _server(8600, &"tackle", &"iron_barbs")
	var contact_events := contact.submit_turn(_actions(contact.state, &"tackle"))
	check.call(
		"data_v3_iron_barbs_real_battle_contact_exact_damage",
		contact.state.creature(&"a").current_hp == 210
		and _source_triggered(contact_events, "iron_barbs", &"b")
		and _fraction_damage_event(contact_events, &"b", &"a", 30, 1250),
	)

	# A damaging non-contact move must not activate the ability or damage the attacker.
	var noncontact := _server(8601, &"water_gun", &"iron_barbs")
	var noncontact_events := noncontact.submit_turn(_actions(noncontact.state, &"water_gun"))
	check.call(
		"data_v3_iron_barbs_real_battle_noncontact_inert",
		noncontact.state.creature(&"a").current_hp == 240
		and not _source_triggered(noncontact_events, "iron_barbs", &"b")
		and not _has_fraction_damage_event(noncontact_events),
	)

	# The generic max-HP damage effect can KO the attacker when the defender survives.
	# This is a useful supported subset even though double-KO ordering is not yet covered.
	var attacker_ko := _server(8602, &"tackle", &"iron_barbs")
	attacker_ko.state.creature(&"a").current_hp = 20
	var attacker_ko_events := attacker_ko.submit_turn(_actions(attacker_ko.state, &"tackle"))
	check.call(
		"data_v3_iron_barbs_can_ko_attacker",
		attacker_ko.state.creature(&"a").is_knocked_out()
		and _source_triggered(attacker_ko_events, "iron_barbs", &"b")
		and _fraction_damage_event(attacker_ko_events, &"b", &"a", 20, 1250),
	)

	# Explicit fatal-owner partial boundary: a contact hit that KOs the Iron Barbs
	# holder never requests defender AFTER_DAMAGE, so no reactive damage occurs.
	var fatal_owner := _server(8603, &"tackle", &"iron_barbs")
	fatal_owner.state.creature(&"b").current_hp = 1
	var fatal_owner_events := fatal_owner.submit_turn(
		_actions(fatal_owner.state, &"tackle")
	)
	check.call(
		"data_v3_iron_barbs_fatal_owner_partial_boundary",
		fatal_owner.state.creature(&"b").is_knocked_out()
		and fatal_owner.state.creature(&"a").current_hp == 240
		and not _source_triggered(fatal_owner_events, "iron_barbs", &"b")
		and not _has_fraction_damage_event(fatal_owner_events),
	)

	# Explicit multi-hit partial boundary: main-series Iron Barbs activates once per
	# contact strike, but current TurnExecutor requests defender AFTER_DAMAGE only
	# after the completed move. Double Kick therefore removes only one 1/8 chunk here.
	var multi := _server(8604, &"double_kick", &"iron_barbs")
	var multi_events := multi.submit_turn(_actions(multi.state, &"double_kick"))
	check.call(
		"data_v3_iron_barbs_multihit_partial_boundary",
		multi.state.creature(&"a").current_hp == 210
		and _source_trigger_count(multi_events, "iron_barbs", &"b") == 1
		and _fraction_damage_event(multi_events, &"b", &"a", 30, 1250),
	)

	# Rough Skin is intentionally non-executable despite sharing current 1/8 prose:
	# the pinned source also preserves a historical 1/16 battle value and the current
	# runtime has no version-aware ability multiplier contract.
	var rough := _server(8605, &"tackle", &"rough_skin")
	var rough_events := rough.submit_turn(_actions(rough.state, &"tackle"))
	check.call(
		"data_v3_rough_skin_version_sensitive_blocker_inert",
		rough.state.creature(&"a").current_hp == 240
		and not _source_triggered(rough_events, "rough_skin", &"b")
		and not _has_fraction_damage_event(rough_events),
	)


func _server(seed: int, move_a: StringName, target_ability: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_contact_retaliation", [
		_creature(&"a", &"squirtle", [move_a], 30),
		_creature(&"b", &"eevee", [&"growl"], 20),
	], seed)
	state.creature(&"b").ability_id = target_ability
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


func _source_triggered(
	events: Array[BattleEvent],
	source_id: String,
	owner_id: StringName,
) -> bool:
	return _source_trigger_count(events, source_id, owner_id) > 0


func _source_trigger_count(
	events: Array[BattleEvent],
	source_id: String,
	owner_id: StringName,
) -> int:
	var count := 0
	for event in events:
		if (
			event.kind == BattleEvent.ABILITY_TRIGGERED
			and event.actor_id == owner_id
			and event.metadata.get("source_id", "") == source_id
		):
			count += 1
	return count


func _fraction_damage_event(
	events: Array[BattleEvent],
	actor_id: StringName,
	target_id: StringName,
	amount: int,
	ratio_bp: int,
) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.DAMAGE_APPLIED
			and event.actor_id == actor_id
			and event.target_id == target_id
			and event.amount == amount
			and event.metadata.get("cause", "") == "max_hp_fraction"
			and int(event.metadata.get("ratio_basis_points", 0)) == ratio_bp
		):
			return true
	return false


func _has_fraction_damage_event(events: Array[BattleEvent]) -> bool:
	for event in events:
		if (
			event.kind == BattleEvent.DAMAGE_APPLIED
			and event.metadata.get("cause", "") == "max_hp_fraction"
		):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
