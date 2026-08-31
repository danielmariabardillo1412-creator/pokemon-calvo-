class_name DataFoundationV3DomainTestSuite
extends RefCounted


func run(check_callback: Callable) -> void:
	_test_learnset_roundtrip(check_callback)
	_test_evolution_roundtrip(check_callback)
	_test_species_metadata_roundtrip(check_callback)
	_test_silk_trap_generated_semantics(check_callback)


func _test_learnset_roundtrip(check_callback: Callable) -> void:
	var legacy := LearnSetEntry.new(15, &"tackle", "level_up")
	check_callback.call(
		"data_v3_learnset_legacy_shape_unchanged",
		legacy.to_dict() == {"level": 15, "move_id": "tackle", "method": "level_up"},
	)
	var rich := LearnSetEntry.new(42, &"shadow_ball", "level_up", &"scarlet_violet", 17)
	var copy := LearnSetEntry.from_dict(rich.to_dict())
	check_callback.call("data_v3_learnset_version_group_roundtrip", copy.version_group == &"scarlet_violet")
	check_callback.call("data_v3_learnset_order_roundtrip", copy.order == 17)
	check_callback.call("data_v3_learnset_core_fields_roundtrip", copy.level == 42 and copy.move_id == &"shadow_ball" and copy.method == "level_up")


func _test_evolution_roundtrip(check_callback: Callable) -> void:
	var legacy := EvolutionRecord.new(&"ivysaur", 16, &"level_up", &"")
	check_callback.call(
		"data_v3_evolution_legacy_shape_unchanged",
		legacy.to_dict() == {"species_id": "ivysaur", "min_level": 16, "trigger": "level_up", "item_id": ""},
	)
	var conditions := {
		"min_happiness": 220,
		"time_of_day": "day",
		"known_move": "ancient_power",
	}
	var rich := EvolutionRecord.new(&"target", 0, &"level_up", &"", &"sun_moon", false, conditions)
	var copy := EvolutionRecord.from_dict(rich.to_dict())
	check_callback.call("data_v3_evolution_version_group_roundtrip", copy.version_group == &"sun_moon")
	check_callback.call("data_v3_evolution_default_flag_roundtrip", not copy.is_default)
	check_callback.call("data_v3_evolution_conditions_roundtrip", copy.conditions == conditions)
	conditions["min_happiness"] = 1
	check_callback.call("data_v3_evolution_conditions_are_independent", int(copy.conditions.get("min_happiness", 0)) == 220)


func _test_species_metadata_roundtrip(check_callback: Callable) -> void:
	var species := CreatureSpecies.new()
	species.id = &"bulbasaur"
	species.display_name = "Bulbasaur"
	species.type_ids = [&"grass", &"poison"]
	species.base_hp = 45
	species.base_attack = 49
	species.base_defense = 49
	species.base_speed = 45
	species.base_special_attack = 65
	species.base_special_defense = 65
	species.ability_ids = [&"overgrow", &"chlorophyll"]
	species.ability_slots = [
		{"ability_id": "overgrow", "slot": 1, "is_hidden": false},
		{"ability_id": "chlorophyll", "slot": 3, "is_hidden": true},
	]
	species.source_metadata = {
		"source_pokemon_id": "bulbasaur",
		"learnset_version_group": "scarlet_violet",
		"learnset_selection_reason": "mainline_priority",
		"egg_groups": ["monster", "grass"],
	}
	var copy := CreatureSpecies.from_dict(species.to_dict())
	check_callback.call("data_v3_species_ability_slots_roundtrip", copy.ability_slots == species.ability_slots)
	check_callback.call("data_v3_species_source_metadata_roundtrip", copy.source_metadata == species.source_metadata)
	species.ability_slots[0]["slot"] = 99
	species.source_metadata["learnset_version_group"] = "broken"
	check_callback.call("data_v3_species_metadata_is_independent", int(copy.ability_slots[0].get("slot", 0)) == 1 and copy.source_metadata.get("learnset_version_group") == "scarlet_violet")


func _test_silk_trap_generated_semantics(check_callback: Callable) -> void:
	var raw_text := FileAccess.get_file_as_string("res://data/raw/pokemon_api.json")
	var parsed = JSON.parse_string(raw_text)
	check_callback.call("data_v3_silk_trap_raw_json_parses", parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var root: Dictionary = parsed
	var silk_trap: Dictionary = {}
	for move in root.get("moves", []):
		if move is Dictionary and String(move.get("id", "")) == "silk_trap":
			silk_trap = move
			break
	check_callback.call("data_v3_silk_trap_present", not silk_trap.is_empty())
	if silk_trap.is_empty():
		return
	check_callback.call("data_v3_silk_trap_target_preserved", silk_trap.get("target", "") == "user")
	check_callback.call("data_v3_silk_trap_is_data_only", silk_trap.get("classification", "") == "DATA_ONLY")
	check_callback.call("data_v3_silk_trap_has_no_false_runtime_effect", (silk_trap.get("effect_specs", []) as Array).is_empty())
