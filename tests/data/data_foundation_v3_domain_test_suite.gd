class_name DataFoundationV3DomainTestSuite
extends RefCounted


func run(check_callback: Callable) -> void:
	_test_learnset_roundtrip(check_callback)
	_test_evolution_roundtrip(check_callback)
	_test_species_metadata_roundtrip(check_callback)
	_test_silk_trap_generated_semantics(check_callback)
	_test_aromatic_mist_generated_semantics(check_callback)
	_test_stuff_cheeks_generated_semantics(check_callback)
	_test_howl_generated_semantics(check_callback)
	_test_coaching_generated_semantics(check_callback)
	_test_gear_up_generated_semantics(check_callback)
	_test_magnetic_flux_generated_semantics(check_callback)
	_test_pure_self_stat_packages(check_callback)


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


func _load_raw_move(move_id: String) -> Dictionary:
	var raw_text := FileAccess.get_file_as_string("res://data/raw/pokemon_api.json")
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {}
	var root: Dictionary = parsed
	for move in root.get("moves", []):
		if move is Dictionary and String(move.get("id", "")) == move_id:
			return move
	return {}


func _test_silk_trap_generated_semantics(check_callback: Callable) -> void:
	var silk_trap := _load_raw_move("silk_trap")
	check_callback.call("data_v3_silk_trap_present", not silk_trap.is_empty())
	if silk_trap.is_empty():
		return
	var specs: Array = silk_trap.get("effect_specs", [])
	check_callback.call("data_v3_silk_trap_target_preserved", silk_trap.get("target", "") == "user")
	check_callback.call("data_v3_silk_trap_is_data_only", silk_trap.get("classification", "") == "DATA_ONLY")
	check_callback.call("data_v3_silk_trap_has_no_false_runtime_effect", specs.is_empty())


func _test_aromatic_mist_generated_semantics(check_callback: Callable) -> void:
	var aromatic_mist := _load_raw_move("aromatic_mist")
	check_callback.call("data_v3_aromatic_mist_present", not aromatic_mist.is_empty())
	if aromatic_mist.is_empty():
		return
	var specs: Array = aromatic_mist.get("effect_specs", [])
	check_callback.call("data_v3_aromatic_mist_target_preserved", aromatic_mist.get("target", "") == "ally")
	check_callback.call("data_v3_aromatic_mist_is_data_only", aromatic_mist.get("classification", "") == "DATA_ONLY")
	check_callback.call("data_v3_aromatic_mist_has_no_false_self_buff", specs.is_empty())


func _test_stuff_cheeks_generated_semantics(check_callback: Callable) -> void:
	var stuff_cheeks := _load_raw_move("stuff_cheeks")
	check_callback.call("data_v3_stuff_cheeks_present", not stuff_cheeks.is_empty())
	if stuff_cheeks.is_empty():
		return
	var specs: Array = stuff_cheeks.get("effect_specs", [])
	check_callback.call("data_v3_stuff_cheeks_target_preserved", stuff_cheeks.get("target", "") == "user")
	check_callback.call("data_v3_stuff_cheeks_is_data_only", stuff_cheeks.get("classification", "") == "DATA_ONLY")
	check_callback.call("data_v3_stuff_cheeks_has_no_unconditional_defense_buff", specs.is_empty())


func _test_howl_generated_semantics(check_callback: Callable) -> void:
	var howl := _load_raw_move("howl")
	check_callback.call("data_v3_howl_present", not howl.is_empty())
	if howl.is_empty():
		return
	var specs: Array = howl.get("effect_specs", [])
	check_callback.call("data_v3_howl_target_preserved", howl.get("target", "") == "user-and-allies")
	check_callback.call("data_v3_howl_is_partial_runtime", howl.get("classification", "") == "PARTIAL_RUNTIME")
	check_callback.call("data_v3_howl_has_one_representable_effect", specs.size() == 1)
	if specs.size() != 1 or not (specs[0] is Dictionary):
		return
	var stage: Dictionary = specs[0]
	check_callback.call("data_v3_howl_effect_is_stat_stage", stage.get("kind", "") == "modify_stat_stage")
	check_callback.call("data_v3_howl_effect_targets_self", stage.get("target", "") == "self")
	check_callback.call("data_v3_howl_effect_is_attack_plus_one", stage.get("stat_id", "") == "attack" and int(stage.get("value", 0)) == 1)
	check_callback.call("data_v3_howl_effect_is_unconditional", int(stage.get("chance_basis_points", 0)) == 10000)


func _test_coaching_generated_semantics(check_callback: Callable) -> void:
	var coaching := _load_raw_move("coaching")
	check_callback.call("data_v3_coaching_present", not coaching.is_empty())
	if coaching.is_empty():
		return
	var specs: Array = coaching.get("effect_specs", [])
	check_callback.call("data_v3_coaching_target_preserved", coaching.get("target", "") == "user-and-allies")
	check_callback.call("data_v3_coaching_is_data_only", coaching.get("classification", "") == "DATA_ONLY")
	check_callback.call("data_v3_coaching_has_no_false_opponent_buffs", specs.is_empty())


func _test_gear_up_generated_semantics(check_callback: Callable) -> void:
	var gear_up := _load_raw_move("gear_up")
	check_callback.call("data_v3_gear_up_present", not gear_up.is_empty())
	if gear_up.is_empty():
		return
	var specs: Array = gear_up.get("effect_specs", [])
	check_callback.call("data_v3_gear_up_target_preserved", gear_up.get("target", "") == "user-and-allies")
	check_callback.call("data_v3_gear_up_is_data_only", gear_up.get("classification", "") == "DATA_ONLY")
	check_callback.call("data_v3_gear_up_has_no_false_opponent_buffs", specs.is_empty())


func _test_magnetic_flux_generated_semantics(check_callback: Callable) -> void:
	var magnetic_flux := _load_raw_move("magnetic_flux")
	check_callback.call("data_v3_magnetic_flux_present", not magnetic_flux.is_empty())
	if magnetic_flux.is_empty():
		return
	var specs: Array = magnetic_flux.get("effect_specs", [])
	check_callback.call("data_v3_magnetic_flux_target_preserved", magnetic_flux.get("target", "") == "user-and-allies")
	check_callback.call("data_v3_magnetic_flux_is_data_only", magnetic_flux.get("classification", "") == "DATA_ONLY")
	check_callback.call("data_v3_magnetic_flux_has_no_false_opponent_buffs", specs.is_empty())


func _test_pure_self_stat_packages(check_callback: Callable) -> void:
	var expected := {
		"bulk_up": {"attack": 1, "defense": 1},
		"calm_mind": {"special_attack": 1, "special_defense": 1},
		"coil": {"attack": 1, "defense": 1, "accuracy": 1},
		"cosmic_power": {"defense": 1, "special_defense": 1},
		"defend_order": {"defense": 1, "special_defense": 1},
		"dragon_dance": {"attack": 1, "speed": 1},
		"hone_claws": {"attack": 1, "accuracy": 1},
		"quiver_dance": {"special_attack": 1, "special_defense": 1, "speed": 1},
		"shift_gear": {"attack": 1, "speed": 2},
		"work_up": {"attack": 1, "special_attack": 1},
	}
	for move_id in expected:
		var move := _load_raw_move(move_id)
		check_callback.call("data_v3_%s_present" % move_id, not move.is_empty())
		if move.is_empty():
			continue
		check_callback.call("data_v3_%s_target_is_user" % move_id, move.get("target", "") == "user")
		check_callback.call("data_v3_%s_runtime_supported" % move_id, move.get("classification", "") == "RUNTIME_SUPPORTED")
		var specs: Array = move.get("effect_specs", [])
		var expected_stats: Dictionary = expected[move_id]
		check_callback.call("data_v3_%s_effect_count" % move_id, specs.size() == expected_stats.size())
		var generated := {}
		var shape_ok := true
		for spec in specs:
			if not (spec is Dictionary):
				shape_ok = false
				continue
			if spec.get("kind", "") != "modify_stat_stage" or spec.get("target", "") != "self" or int(spec.get("chance_basis_points", 0)) != 10000:
				shape_ok = false
			generated[String(spec.get("stat_id", ""))] = int(spec.get("value", 0))
		check_callback.call("data_v3_%s_effect_shape" % move_id, shape_ok)
		check_callback.call("data_v3_%s_effect_package" % move_id, generated == expected_stats)
