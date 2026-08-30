class_name SpanishTypesFoundationTestSuite
extends TrainerTeamCompositionTestSuite


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_canonical_standard_type_chart()
	_test_dual_type_effectiveness_products()
	_test_pokeapi_runtime_overlay_is_hardened()
	_test_custom_type_catalog_is_not_rewritten()
	_test_spanish_player_facing_text()
	_test_executable_scene_uses_spanish_presentation()
	_test_committed_runtime_dataset_has_canonical_chart()


func _test_canonical_standard_type_chart() -> void:
	var ids := PokemonTypeChart.STANDARD_TYPE_IDS
	var unique: Dictionary = {}
	for type_id in ids:
		unique[String(type_id)] = true
	_check.call("types_standard_count_is_18", ids.size() == 18)
	_check.call("types_standard_ids_are_unique", unique.size() == 18)

	var catalog := TypeCatalog.new()
	PokemonTypeChart.apply_to_catalog(catalog)
	_check.call("types_empty_catalog_receives_all_18", catalog.size() == 18)
	var validation := PokemonTypeChart.validate_catalog(catalog)
	_check.call("types_canonical_catalog_validates", bool(validation.get("valid", false)))

	var all_spanish_names := true
	for type_id in ids:
		var definition := catalog.get_by_id(type_id)
		if definition == null or definition.display_name.is_empty() or definition.display_name == String(type_id).capitalize():
			if type_id != &"normal":
				all_spanish_names = false
	_check.call("types_all_standard_display_names_present", all_spanish_names)
	_check.call("types_fire_name_is_spanish", catalog.get_by_id(&"fire").display_name == "Fuego")
	_check.call("types_electric_name_is_spanish", catalog.get_by_id(&"electric").display_name == "Eléctrico")
	_check.call("types_fairy_name_is_spanish", catalog.get_by_id(&"fairy").display_name == "Hada")

	_check.call("types_electric_ground_immunity", is_zero_approx(catalog.get_by_id(&"electric").multiplier_against(&"ground")))
	_check.call("types_normal_ghost_immunity", is_zero_approx(catalog.get_by_id(&"normal").multiplier_against(&"ghost")))
	_check.call("types_fighting_ghost_immunity", is_zero_approx(catalog.get_by_id(&"fighting").multiplier_against(&"ghost")))
	_check.call("types_dragon_fairy_immunity", is_zero_approx(catalog.get_by_id(&"dragon").multiplier_against(&"fairy")))
	_check.call("types_poison_steel_immunity", is_zero_approx(catalog.get_by_id(&"poison").multiplier_against(&"steel")))
	_check.call("types_ground_flying_immunity", is_zero_approx(catalog.get_by_id(&"ground").multiplier_against(&"flying")))
	_check.call("types_psychic_dark_immunity", is_zero_approx(catalog.get_by_id(&"psychic").multiplier_against(&"dark")))
	_check.call("types_ghost_normal_immunity", is_zero_approx(catalog.get_by_id(&"ghost").multiplier_against(&"normal")))
	_check.call("types_fire_grass_super_effective", is_equal_approx(catalog.get_by_id(&"fire").multiplier_against(&"grass"), 2.0))
	_check.call("types_water_fire_super_effective", is_equal_approx(catalog.get_by_id(&"water").multiplier_against(&"fire"), 2.0))
	_check.call("types_grass_water_super_effective", is_equal_approx(catalog.get_by_id(&"grass").multiplier_against(&"water"), 2.0))
	_check.call("types_ice_dragon_super_effective", is_equal_approx(catalog.get_by_id(&"ice").multiplier_against(&"dragon"), 2.0))
	_check.call("types_fairy_dragon_super_effective", is_equal_approx(catalog.get_by_id(&"fairy").multiplier_against(&"dragon"), 2.0))
	_check.call("types_steel_fairy_super_effective", is_equal_approx(catalog.get_by_id(&"steel").multiplier_against(&"fairy"), 2.0))


func _test_dual_type_effectiveness_products() -> void:
	var catalog := TypeCatalog.new()
	PokemonTypeChart.apply_to_catalog(catalog)
	_check.call("types_dual_fire_vs_grass_steel_is_4x", is_equal_approx(_product(catalog, &"fire", [&"grass", &"steel"]), 4.0))
	_check.call("types_dual_water_vs_fire_rock_is_4x", is_equal_approx(_product(catalog, &"water", [&"fire", &"rock"]), 4.0))
	_check.call("types_dual_electric_vs_water_ground_is_immune", is_zero_approx(_product(catalog, &"electric", [&"water", &"ground"])))
	_check.call("types_dual_fire_vs_water_dragon_is_quarter", is_equal_approx(_product(catalog, &"fire", [&"water", &"dragon"]), 0.25))


func _test_pokeapi_runtime_overlay_is_hardened() -> void:
	var deliberately_incomplete := {
		"manifest": _manifest("pokeapi/api-data"),
		"types": {
			"normal": {"id": "normal", "display_name": "Normal", "effectiveness": {}},
		},
		"moves": {},
		"abilities": {},
		"items": {},
		"statuses": {},
		"species": {},
	}
	var game_data := GameData.from_dict(deliberately_incomplete)
	var all_present := true
	for type_id in PokemonTypeChart.STANDARD_TYPE_IDS:
		if game_data.type_catalog.get_by_id(type_id) == null:
			all_present = false
			break
	_check.call("types_pokeapi_overlay_restores_all_standard_types", all_present)
	_check.call("types_pokeapi_overlay_validates_full_chart", bool(PokemonTypeChart.validate_catalog(game_data.type_catalog).get("valid", false)))


func _test_custom_type_catalog_is_not_rewritten() -> void:
	var custom := {
		"manifest": _manifest("test-fixture"),
		"types": {
			"normal": {"id": "normal", "display_name": "Custom", "effectiveness": {"water": 0.25}},
		},
		"moves": {},
		"abilities": {},
		"items": {},
		"statuses": {},
		"species": {},
	}
	var game_data := GameData.from_dict(custom)
	_check.call("types_custom_fixture_keeps_authored_relations", is_equal_approx(game_data.type_catalog.get_by_id(&"normal").multiplier_against(&"water"), 0.25))


func _test_spanish_player_facing_text() -> void:
	_check.call("locale_type_fire_is_fuego", SpanishGameText.type_name(&"fire") == "Fuego")
	_check.call("locale_move_quick_attack_is_spanish", SpanishGameText.move_name(&"quick_attack") == "Ataque Rápido")
	_check.call("locale_item_poke_ball_is_spanish", SpanishGameText.item_name(&"poke_ball") == "Poké Ball")
	_check.call("locale_super_effective_message_spanish", SpanishGameText.effectiveness_text(2.0) == "¡Es supereficaz!")
	_check.call("locale_not_very_effective_message_spanish", SpanishGameText.effectiveness_text(0.5) == "No es muy eficaz...")
	_check.call("locale_immunity_message_spanish", SpanishGameText.effectiveness_text(0.0) == "No afecta al objetivo.")
	_check.call("locale_run_success_message_spanish", SpanishGameText.translate_runtime_message("Got away safely.") == "¡Has escapado sin problemas!")
	var appearance := SpanishGameText.translate_runtime_message("A wild Pikachu Lv.4 appeared.")
	_check.call("locale_wild_appearance_message_spanish", appearance.contains("salvaje") and appearance.contains("Nv.4"))


func _test_executable_scene_uses_spanish_presentation() -> void:
	var packed := load("res://scenes/overworld/technical_overworld.tscn") as PackedScene
	_check.call("locale_executable_scene_loads", packed != null)
	if packed == null:
		_check.call("locale_executable_battle_controller_is_spanish", false)
		return
	var root := packed.instantiate()
	var presentation := root.get_node_or_null("CanvasLayer/BattlePresentation")
	_check.call("locale_executable_battle_controller_is_spanish", presentation is SpanishBattlePresentationController)
	root.free()


func _test_committed_runtime_dataset_has_canonical_chart() -> void:
	var file := FileAccess.open("res://data/normalized/pokemon_api.json", FileAccess.READ)
	_check.call("types_committed_runtime_dataset_exists", file != null)
	if file == null:
		_check.call("types_committed_runtime_dataset_chart_valid", false)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	var game_data := GameData.from_dict(parsed as Dictionary if parsed is Dictionary else {})
	_check.call("types_committed_runtime_dataset_chart_valid", bool(PokemonTypeChart.validate_catalog(game_data.type_catalog).get("valid", false)))


func _product(catalog: TypeCatalog, attack_type: StringName, defender_types: Array[StringName]) -> float:
	var attack := catalog.get_by_id(attack_type)
	if attack == null:
		return 1.0
	var out := 1.0
	for defend_type in defender_types:
		out *= attack.multiplier_against(defend_type)
	return out


func _manifest(source: String) -> Dictionary:
	return {
		"schema_version": DatasetManifest.CURRENT_SCHEMA_VERSION,
		"dataset_version": "test",
		"source": source,
		"generated_at": "",
		"ruleset": "",
		"provenance": {},
	}
