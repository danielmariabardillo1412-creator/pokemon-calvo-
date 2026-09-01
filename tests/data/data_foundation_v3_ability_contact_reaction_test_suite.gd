class_name DataFoundationV3AbilityContactReactionTestSuite
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
	check.call(
		"data_v3_contact_reaction_move_metadata",
		tackle != null and tackle.makes_contact
		and water_gun != null and not water_gun.makes_contact,
	)

	# Flame Body and Poison Point: find a deterministic seed where the existing 30%
	# chance succeeds, then verify the real battle status transaction and owner event.
	for case in [
		[&"flame_body", &"burn", "data_v3_flame_body_real_battle_contact_status"],
		[&"poison_point", &"poison", "data_v3_poison_point_real_battle_contact_status"],
	]:
		var ability_id := StringName(case[0])
		var status_id := StringName(case[1])
		var seed := _find_status_seed(ability_id, status_id)
		var success := seed > 0
		if success:
			var server := _server(seed, &"tackle", ability_id)
			var events := server.submit_turn(_actions(server.state, &"tackle"))
			success = (
				server.state.creature(&"a").status_state.persistent_id == status_id
				and _source_triggered(events, String(ability_id), &"b")
			)
		check.call(str(case[2]), success)

	# The same abilities are inert for a damaging move that does not make contact.
	for case in [
		[&"flame_body", "data_v3_flame_body_real_battle_noncontact_inert"],
		[&"poison_point", "data_v3_poison_point_real_battle_noncontact_inert"],
	]:
		var ability_id := StringName(case[0])
		var server := _server(8510, &"water_gun", ability_id)
		var events := server.submit_turn(_actions(server.state, &"water_gun"))
		check.call(
			str(case[1]),
			server.state.creature(&"a").status_state.persistent_id == &""
			and not _source_triggered(events, String(ability_id), &"b"),
		)

	# Gooey: ordinary surviving contact lowers the attacker's Speed by exactly one
	# stage and emits a defender-owned ability event.
	var gooey_contact := _server(8520, &"tackle", &"gooey")
	var gooey_contact_events := gooey_contact.submit_turn(_actions(gooey_contact.state, &"tackle"))
	check.call(
		"data_v3_gooey_real_battle_contact_speed_drop",
		gooey_contact.state.creature(&"a").stat_stages.get_stage(StatStages.SPEED) == -1
		and _source_triggered(gooey_contact_events, "gooey", &"b"),
	)

	# Non-contact damage must leave Speed unchanged and emit no Gooey trigger.
	var gooey_noncontact := _server(8521, &"water_gun", &"gooey")
	var gooey_noncontact_events := gooey_noncontact.submit_turn(
		_actions(gooey_noncontact.state, &"water_gun")
	)
	check.call(
		"data_v3_gooey_real_battle_noncontact_inert",
		gooey_noncontact.state.creature(&"a").stat_stages.get_stage(StatStages.SPEED) == 0
		and not _source_triggered(gooey_noncontact_events, "gooey", &"b"),
	)

	# Explicit partial boundary shared with Static: if the contact hit KOs the
	# ability owner, TurnExecutor does not request defender AFTER_DAMAGE and Gooey
	# cannot react. This test intentionally preserves the known missing behavior.
	var fatal := _server(8522, &"tackle", &"gooey")
	fatal.state.creature(&"b").current_hp = 1
	var fatal_events := fatal.submit_turn(_actions(fatal.state, &"tackle"))
	check.call(
		"data_v3_contact_reaction_fatal_hit_partial_boundary",
		fatal.state.creature(&"b").is_knocked_out()
		and fatal.state.creature(&"a").stat_stages.get_stage(StatStages.SPEED) == 0
		and not _source_triggered(fatal_events, "gooey", &"b"),
	)


func _find_status_seed(ability_id: StringName, status_id: StringName) -> int:
	for seed in range(8500, 8564):
		var server := _server(seed, &"tackle", ability_id)
		var events := server.submit_turn(_actions(server.state, &"tackle"))
		if (
			server.state.creature(&"a").status_state.persistent_id == status_id
			and _source_triggered(events, String(ability_id), &"b")
		):
			return seed
	return -1


func _server(seed: int, move_a: StringName, target_ability: StringName) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"data_v3_contact_reaction", [
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
	for event in events:
		if (
			event.kind == BattleEvent.ABILITY_TRIGGERED
			and event.actor_id == owner_id
			and event.metadata.get("source_id", "") == source_id
		):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
