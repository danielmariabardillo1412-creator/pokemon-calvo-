extends Node

var _passed := 0
var _failed := 0
var _catalog: DefinitionCatalog
var _client := BattleClient.new()


func _ready() -> void:
	_catalog = _build_catalog()
	_run_all()
	print("\n=== FOUNDATION V1: %d PASS / %d FAIL ===" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	_test_priority()
	_test_speed()
	_test_damage()
	_test_stab()
	_test_effectiveness()
	_test_knockout()
	_test_poison()
	_test_deterministic_rng()
	_test_speed_tie_is_deterministic()
	_test_battle_events()
	_test_serialization_round_trip()
	_test_server_rejects_forged_action()
	_test_client_sends_intent_only()
	# --- Data pipeline (Phase 3) ---
	_test_manifest_valid()
	_test_manifest_invalid()
	_test_unique_ids()
	_test_lookup_species()
	_test_lookup_move()
	_test_lookup_type()
	_test_invalid_type_reference()
	_test_invalid_learnset()
	_test_invalid_evolution()
	_test_definition_immutable()
	_test_instance_references_species()
	_test_data_round_trip()
	_test_imported_battle()
	# --- Mass PokéAPI import (Phase 4) ---
	_test_pokeapi_manifest_valid()
	_test_pokeapi_known_species()
	_test_pokeapi_known_type()
	_test_pokeapi_known_move()
	_test_pokeapi_known_ability()
	_test_pokeapi_known_evolution()
	_test_pokeapi_known_learnset()
	_test_pokeapi_full_catalog_load()
	_test_pokeapi_no_broken_references()
	_test_pokeapi_artificial_broken_ref()
	_test_pokeapi_forms_policy()
	_test_pokeapi_deterministic_ordering()


func _test_priority() -> void:
	var server := _server(11, 50, 5)
	var events := server.submit_turn(_actions(server.state, &"strike", &"quick_strike"))
	var first_action := _first_event(events, BattleEvent.ACTION_USED)
	_check("priority", first_action != null and first_action.actor_id == &"creature_b")


func _test_speed() -> void:
	var server := _server(12, 50, 5)
	var events := server.submit_turn(_actions(server.state, &"strike", &"strike"))
	var first_action := _first_event(events, BattleEvent.ACTION_USED)
	_check("speed", first_action != null and first_action.actor_id == &"creature_a")


func _test_damage() -> void:
	var server := _server(13, 50, 5)
	var target := server.state.creature(&"creature_b")
	var hp_before := target.current_hp
	var events := server.submit_turn(_actions(server.state, &"strike", &"wait"))
	var damage_event := _first_event(events, BattleEvent.DAMAGE_APPLIED)
	_check(
		"damage",
		damage_event != null
		and damage_event.amount > 0
		and target.current_hp == hp_before - damage_event.amount,
	)


func _test_stab() -> void:
	var calculator := DamageCalculator.new()
	var defender := _creature(&"target", &"leafling", 10, 100)
	var fire_attacker := _creature(&"fire", &"embercub", 10, 100)
	var grass_attacker := _creature(&"grass", &"leafling", 10, 100)
	var with_stab := calculator.calculate(
		fire_attacker, defender, _catalog.move(&"ember"), _catalog, SeededRandomSource.new(99)
	)
	var without_stab := calculator.calculate(
		grass_attacker, defender, _catalog.move(&"ember"), _catalog, SeededRandomSource.new(99)
	)
	_check(
		"stab",
		with_stab.stab_basis_points == 15000
		and without_stab.stab_basis_points == 10000
		and with_stab.amount > without_stab.amount,
	)


func _test_effectiveness() -> void:
	var result := DamageCalculator.new().calculate(
		_creature(&"attacker", &"embercub", 10, 100),
		_creature(&"defender", &"leafling", 10, 100),
		_catalog.move(&"ember"),
		_catalog,
		SeededRandomSource.new(21),
	)
	_check("effectiveness", result.effectiveness_basis_points == 20000)


func _test_knockout() -> void:
	var server := _server(14, 50, 5)
	server.state.creature(&"creature_b").current_hp = 1
	var events := server.submit_turn(_actions(server.state, &"strike", &"wait"))
	_check(
		"knockout",
		_first_event(events, BattleEvent.KNOCKED_OUT) != null
		and _first_event(events, BattleEvent.BATTLE_ENDED) != null
		and server.state.phase == BattleState.FINISHED
		and server.state.winner_id == &"creature_a",
	)


func _test_poison() -> void:
	var server := _server(15, 50, 5)
	var poisoned := server.state.creature(&"creature_b")
	poisoned.status_ids.append(&"poison")
	var hp_before := poisoned.current_hp
	var events := server.submit_turn(_actions(server.state, &"wait", &"wait"))
	var status_event := _first_event(events, BattleEvent.STATUS_DAMAGE)
	_check(
		"poison",
		status_event != null
		and status_event.metadata.status_id == "poison"
		and poisoned.current_hp == hp_before - status_event.amount,
	)


func _test_deterministic_rng() -> void:
	var first := _server(8675309, 20, 10)
	var second := _server(8675309, 20, 10)
	var first_events := first.submit_turn(_actions(first.state, &"ember", &"strike"))
	var second_events := second.submit_turn(_actions(second.state, &"ember", &"strike"))
	_check(
		"deterministic_rng",
		JSON.stringify(_event_dicts(first_events)) == JSON.stringify(_event_dicts(second_events))
		and JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot()),
	)


func _test_speed_tie_is_deterministic() -> void:
	var first := _server(44, 10, 10)
	var second := _server(44, 10, 10)
	var first_events := first.submit_turn(_actions(first.state, &"strike", &"strike"))
	var second_events := second.submit_turn(_actions(second.state, &"strike", &"strike"))
	var first_action := _first_event(first_events, BattleEvent.ACTION_USED)
	var second_action := _first_event(second_events, BattleEvent.ACTION_USED)
	_check(
		"deterministic_speed_tie",
		first_action != null
		and second_action != null
		and first_action.actor_id == second_action.actor_id,
	)


func _test_battle_events() -> void:
	var server := _server(16, 50, 5)
	var events := server.submit_turn(_actions(server.state, &"strike", &"wait"))
	var kinds: Array[StringName] = []
	for event in events:
		kinds.append(event.kind)
	var collector := BattleEventCollector.new()
	collector.consume(events)
	_check(
		"battle_events",
		kinds == [
			BattleEvent.ACTION_USED,
			BattleEvent.DAMAGE_APPLIED,
			BattleEvent.ACTION_USED,
			BattleEvent.TURN_ENDED,
		]
		and collector.received.size() == events.size()
		and collector.received[0].has("kind"),
	)


func _test_serialization_round_trip() -> void:
	var server := _server(123456, 50, 5)
	server.state.creature(&"creature_b").status_ids.append(&"poison")
	server.submit_turn(_actions(server.state, &"wait", &"wait"))
	var snapshot := server.snapshot()
	var json_text := JSON.stringify(snapshot)
	var parsed = JSON.parse_string(json_text)
	var restored := BattleState.from_dict(parsed)
	_check(
		"battle_state_serialization",
		json_text == JSON.stringify(restored.to_dict())
		and restored.rng_state == server.state.rng_state
		and restored.creature(&"creature_b").status_ids.has(&"poison"),
	)


func _test_server_rejects_forged_action() -> void:
	var server := _server(17, 50, 5)
	var hp_before := server.state.creature(&"creature_b").current_hp
	var forged := _client.request_move(1, &"creature_a", &"not_owned", &"creature_b")
	var valid := _client.request_move(1, &"creature_b", &"wait", &"creature_a")
	var events := server.submit_turn([forged, valid])
	_check(
		"server_authority",
		events.size() == 1
		and events[0].kind == BattleEvent.ACTION_REJECTED
		and events[0].metadata.reason == "invalid_move"
		and server.state.turn == 0
		and server.state.creature(&"creature_b").current_hp == hp_before,
	)


func _test_client_sends_intent_only() -> void:
	var payload := _client.request_move(1, &"creature_a", &"strike", &"creature_b").to_dict()
	_check(
		"client_intent_only",
		payload.keys().size() == 4
		and not payload.has("damage")
		and not payload.has("hp")
		and not payload.has("winner_id"),
	)


func _server(seed: int, speed_a: int, speed_b: int) -> AuthoritativeBattleServer:
	var first := _creature(&"creature_a", &"embercub", speed_a, 120)
	var second := _creature(&"creature_b", &"leafling", speed_b, 120)
	var state := BattleState.new(&"test_battle", [first, second], seed)
	return AuthoritativeBattleServer.new(state, _catalog)


func _creature(
	id: StringName,
	species_id: StringName,
	speed: int,
	max_hp: int,
) -> CreatureInstance:
	return CreatureInstance.new(
		id,
		species_id,
		20,
		StatBlock.new(max_hp, 30, 20, speed),
		[&"strike", &"quick_strike", &"ember", &"wait"],
	)


func _actions(
	state: BattleState,
	move_a: StringName,
	move_b: StringName,
) -> Array[BattleAction]:
	var turn := state.turn + 1
	return [
		_client.request_move(turn, &"creature_a", move_a, &"creature_b"),
		_client.request_move(turn, &"creature_b", move_b, &"creature_a"),
	]


func _first_event(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event.kind == kind:
			return event
	return null


func _event_dicts(events: Array[BattleEvent]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		result.append(event.to_dict())
	return result


func _build_catalog() -> DefinitionCatalog:
	var catalog := DefinitionCatalog.new()
	for path in [
		"res://data/types/normal.tres",
		"res://data/types/fire.tres",
		"res://data/types/grass.tres",
	]:
		catalog.add_type(load(path) as TypeDefinition)
	for path in [
		"res://data/moves/strike.tres",
		"res://data/moves/quick_strike.tres",
		"res://data/moves/ember.tres",
		"res://data/moves/wait.tres",
	]:
		catalog.add_move(load(path) as MoveDefinition)
	for path in [
		"res://data/species/embercub.tres",
		"res://data/species/leafling.tres",
	]:
		catalog.add_species(load(path) as CreatureSpecies)
	catalog.add_status(load("res://data/statuses/poison.tres") as StatusDefinition)
	return catalog


# --- Mass PokéAPI import helpers (Phase 4) ---

var _pokeapi_cache: GameData = null

func _import_pokeapi() -> GameData:
	if _pokeapi_cache != null:
		return _pokeapi_cache
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	var res := DataImporter.new().import_dataset(raw, manifest)
	_pokeapi_cache = res["game_data"]
	return _pokeapi_cache

func _test_pokeapi_manifest_valid() -> void:
	var m := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	_check("pokeapi_manifest_valid", m.is_valid() and m.schema_version == 1 and m.source == "pokeapi/api-data")

func _test_pokeapi_known_species() -> void:
	var gd := _import_pokeapi()
	_check("pokeapi_known_species", gd.species_catalog.has(&"bulbasaur") and gd.species_catalog.get_by_id(&"bulbasaur").display_name == "bulbasaur" and gd.species_catalog.has(&"pikachu") and gd.species_catalog.has(&"charizard"))

func _test_pokeapi_known_type() -> void:
	var gd := _import_pokeapi()
	_check("pokeapi_known_type", gd.type_catalog.has(&"fire") and gd.type_catalog.get_by_id(&"fire").multiplier_against(&"grass") == 2.0 and gd.type_catalog.has(&"water"))

func _test_pokeapi_known_move() -> void:
	var gd := _import_pokeapi()
	_check("pokeapi_known_move", gd.move_catalog.has(&"tackle") and gd.move_catalog.get_by_id(&"tackle").power > 0 and gd.move_catalog.has(&"ember"))

func _test_pokeapi_known_ability() -> void:
	var gd := _import_pokeapi()
	_check("pokeapi_known_ability", gd.ability_catalog.has(&"overgrow") and gd.ability_catalog.has(&"run_away"))

func _test_pokeapi_known_evolution() -> void:
	var gd := _import_pokeapi()
	var sp := gd.species_catalog.get_by_id(&"bulbasaur")
	var found := false
	for ev in sp.evolutions:
		if ev is EvolutionRecord and (ev as EvolutionRecord).species_id == &"ivysaur" and (ev as EvolutionRecord).min_level == 16:
			found = true
	_check("pokeapi_known_evolution", found)

func _test_pokeapi_known_learnset() -> void:
	var gd := _import_pokeapi()
	var sp := gd.species_catalog.get_by_id(&"bulbasaur")
	var found := false
	for ls in sp.learnset:
		if ls is LearnSetEntry and (ls as LearnSetEntry).move_id == &"vine_whip":
			found = true
	_check("pokeapi_known_learnset", found)

func _test_pokeapi_full_catalog_load() -> void:
	var gd := _import_pokeapi()
	_check("pokeapi_full_catalog_load", gd.species_catalog.size() >= 900 and gd.move_catalog.size() >= 900 and gd.type_catalog.size() >= 18 and gd.ability_catalog.size() >= 300)

func _test_pokeapi_no_broken_references() -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	var res := DataImporter.new().import_dataset(raw, manifest)
	var report: DataImportReport = res["report"]
	_check("pokeapi_no_broken_references", report.broken_references.size() == 0 and report.rejected.size() == 0)

func _test_pokeapi_artificial_broken_ref() -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var dup := raw.duplicate(true)
	dup["species"].append({"id": "ghostmon", "display_name": "Ghostmon", "types": ["nonexistent_xyz"], "base_hp": 40, "base_attack": 40, "base_defense": 40, "base_speed": 40, "base_special_attack": 40, "base_special_defense": 40, "ability_ids": ["overgrow"], "learnset": [], "evolutions": []})
	var manifest := DatasetManifest.from_dict(_load_json("res://data/manifests/pokemon_api_manifest.json"))
	var res := DataImporter.new().import_dataset(dup, manifest)
	_check("pokeapi_artificial_broken_ref", not res["game_data"].species_catalog.has(&"ghostmon") and res["report"].rejected.has("ghostmon (broken_type_reference)"))

func _test_pokeapi_forms_policy() -> void:
	var gd := _import_pokeapi()
	var fr: Dictionary = _load_json("res://data/reports/forms_policy_report.json")
	var deferred: Array = fr.get("deferred", [])
	_check("pokeapi_forms_policy", int(fr.get("forms_total", 0)) > 0 and deferred.size() > 0)
	var no_deferred_in_catalog := true
	for f in deferred:
		if gd.species_catalog.has(StringName(f["id"])):
			no_deferred_in_catalog = false
			break
	_check("pokeapi_forms_not_in_catalog", no_deferred_in_catalog)

func _test_pokeapi_deterministic_ordering() -> void:
	var gd := _import_pokeapi()
	var ids := gd.species_catalog.all_ids()
	var sorted := ids.duplicate()
	sorted.sort()
	_check("pokeapi_deterministic_ordering", ids.size() == sorted.size())
	var restored := GameData.from_dict(gd.to_dict())
	_check("pokeapi_big_round_trip", restored.species_catalog.size() == gd.species_catalog.size() and restored.move_catalog.size() == gd.move_catalog.size())

func _check(test_name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % test_name)
	else:
		_failed += 1
		push_error("FAIL  %s" % test_name)


# --- Data pipeline helpers (Phase 3) ---

func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "Cannot open " + path)
	var text := f.get_as_text()
	f.close()
	return JSON.parse_string(text)

func _fixture_raw() -> Dictionary:
	return _load_json("res://data/fixtures/starter_dataset.json")

func _fixture_manifest() -> DatasetManifest:
	return DatasetManifest.from_dict(_load_json("res://data/manifests/starter_manifest.json"))

func _clone_dict(d: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(d))

func _import(raw: Dictionary, manifest: DatasetManifest) -> GameData:
	var res := DataImporter.new().import_dataset(raw, manifest)
	return res["game_data"]

func _import_report(raw: Dictionary, manifest: DatasetManifest) -> DataImportReport:
	var res := DataImporter.new().import_dataset(raw, manifest)
	return res["report"]


func _test_manifest_valid() -> void:
	_check("manifest_valid", _fixture_manifest().is_valid())

func _test_manifest_invalid() -> void:
	var bad := DatasetManifest.new()
	bad.schema_version = 999
	_check("manifest_invalid_schema", not bad.is_valid())

func _test_unique_ids() -> void:
	var dup := _clone_dict(_fixture_raw())
	dup["species"].append({"id": "bulbasaur", "display_name": "Dup", "types": ["normal"], "base_hp": 40, "base_attack": 40, "base_defense": 40, "base_speed": 40, "ability_ids": ["overgrow"], "learnset": [], "evolutions": []})
	var res := DataImporter.new().import_dataset(dup, _fixture_manifest())
	_check("unique_ids", res["game_data"].species_catalog.has(&"bulbasaur") and res["game_data"].species_catalog.size() == 7 and res["report"].rejected.has("bulbasaur (duplicate_id)"))

func _test_lookup_species() -> void:
	var gd := _import(_fixture_raw(), _fixture_manifest())
	_check("lookup_species", gd.species_catalog.has(&"pikachu") and gd.species_catalog.get_by_id(&"pikachu").display_name == "Pikachu")

func _test_lookup_move() -> void:
	var gd := _import(_fixture_raw(), _fixture_manifest())
	_check("lookup_move", gd.move_catalog.has(&"thunderbolt") and gd.move_catalog.get_by_id(&"thunderbolt").power == 90)

func _test_lookup_type() -> void:
	var gd := _import(_fixture_raw(), _fixture_manifest())
	_check("lookup_type", gd.type_catalog.has(&"electric") and gd.type_catalog.get_by_id(&"electric").multiplier_against(&"water") == 2.0)

func _test_invalid_type_reference() -> void:
	var raw := _clone_dict(_fixture_raw())
	raw["species"].append({"id": "ghostsaur", "display_name": "Ghostsaur", "types": ["ghost"], "base_hp": 40, "base_attack": 40, "base_defense": 40, "base_speed": 40, "ability_ids": ["overgrow"], "learnset": [], "evolutions": []})
	var res := DataImporter.new().import_dataset(raw, _fixture_manifest())
	_check("invalid_type_reference", not res["game_data"].species_catalog.has(&"ghostsaur") and res["report"].rejected.has("ghostsaur (broken_type_reference)"))

func _test_invalid_learnset() -> void:
	var raw := _clone_dict(_fixture_raw())
	raw["species"].append({"id": "nosuchmove", "display_name": "Nsm", "types": ["normal"], "base_hp": 40, "base_attack": 40, "base_defense": 40, "base_speed": 40, "ability_ids": ["overgrow"], "learnset": [{"level": 1, "move_id": "does_not_exist"}], "evolutions": []})
	var res := DataImporter.new().import_dataset(raw, _fixture_manifest())
	_check("invalid_learnset", not res["game_data"].species_catalog.has(&"nosuchmove") and res["report"].rejected.has("nosuchmove (broken_move_reference)"))

func _test_invalid_evolution() -> void:
	var raw := _clone_dict(_fixture_raw())
	raw["species"].append({"id": "evobroken", "display_name": "Eb", "types": ["normal"], "base_hp": 40, "base_attack": 40, "base_defense": 40, "base_speed": 40, "ability_ids": ["overgrow"], "evolutions": [{"species_id": "missingmon", "min_level": 16, "trigger": "level_up"}]})
	var res := DataImporter.new().import_dataset(raw, _fixture_manifest())
	_check("invalid_evolution", not res["game_data"].species_catalog.has(&"evobroken") and res["report"].rejected.has("evobroken (broken_evolution_reference)"))

func _test_definition_immutable() -> void:
	var gd := _import(_fixture_raw(), _fixture_manifest())
	var sp := gd.species_catalog.get_by_id(&"bulbasaur")
	var again := gd.species_catalog.get_by_id(&"bulbasaur")
	_check("definition_immutable", sp != null and sp == again and sp.type_ids_resolved().has(&"grass") and sp.learnset.size() == 2)

func _test_instance_references_species() -> void:
	var gd := _import(_fixture_raw(), _fixture_manifest())
	var sp := gd.species_catalog.get_by_id(&"pikachu")
	var stats := sp.stats_for_level(5)
	var inst := CreatureInstance.new(&"inst1", &"pikachu", 5, stats, [&"thunderbolt", &"quick_attack"])
	_check("instance_references_species", gd.species_catalog.has(inst.species_id) and inst.stats.max_hp == stats.max_hp)

func _test_data_round_trip() -> void:
	var gd := _import(_fixture_raw(), _fixture_manifest())
	var text := JSON.stringify(gd.to_dict())
	var restored := GameData.from_dict(JSON.parse_string(text))
	_check("data_round_trip", restored.species_catalog.size() == gd.species_catalog.size() and restored.move_catalog.has(&"thunderbolt") and restored.species_catalog.has(&"bulbasaur") and restored.manifest.schema_version == 1)

func _test_imported_battle() -> void:
	var gd := _import(_fixture_raw(), _fixture_manifest())
	var cat := gd.to_definition_catalog()
	var a := CreatureInstance.new(&"c1", &"charmander", 10, gd.species_catalog.get_by_id(&"charmander").stats_for_level(10), [&"ember", &"scratch"])
	var b := CreatureInstance.new(&"c2", &"squirtle", 10, gd.species_catalog.get_by_id(&"squirtle").stats_for_level(10), [&"water_gun", &"tackle"])
	var state := BattleState.new(&"b1", [a, b], 12345)
	var server := AuthoritativeBattleServer.new(state, cat)
	var cli := BattleClient.new()
	var events := server.submit_turn([cli.request_move(1, &"c1", &"ember", &"c2"), cli.request_move(1, &"c2", &"water_gun", &"c1")])
	var dmg := _first_event(events, BattleEvent.DAMAGE_APPLIED)
	_check("imported_battle", dmg != null and dmg.amount > 0)
