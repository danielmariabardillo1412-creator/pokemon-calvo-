extends SceneTree

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
var _passed := 0
var _failures: Array[String] = []
var _frames := 0
var _atlases := 0
var _creatures := 0
var _capture := false


func _initialize() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	_check("real_demo_ready", scene.is_demo_ready())
	var rows: Dictionary = Catalog.species_rows()
	_check("1025_base_and_57_regional_entries", rows.size() == 1082)
	_check("all_1025_presentation_metrics", Catalog.presentation_metrics().size() == 1025)
	_check("all_1025_scale_entries", Catalog.scale_references().size() == 1025)
	if rows.size() != 1082:
		await _finish(scene)
		return
	var rules := ProgressionRuleset.new()
	var index := 0
	for key: String in rows:
		var definition = scene._catalogs.species_catalog.get_by_id(StringName(key))
		_check("catalog_identity/" + key, definition != null)
		var creature: CreatureInstance = scene._build_creature(StringName(key), 50, "visual_audit", index, rules)
		if not scene._catalogs.variant_allowed_species.has(key):
			_check("excluded_species_not_playable/" + key, creature == null)
		else:
			_check("factory_level_50/" + key, creature != null and creature.species_id == StringName(key) and creature.current_hp > 0 and not creature.moveset.is_empty())
		if creature != null:
			_creatures += 1
			for slot: BattleMoveSlot in creature.moveset:
				_check("move_reference/%s/%s" % [key, slot.move_id], scene._catalogs.move(slot.move_id) != null)
		var row: Dictionary = rows[key]
		_check("front_and_back/" + key, row.states.reposo.has("front") and row.states.reposo.has("back"))
		for state: String in row.states:
			for side: String in row.states[state]:
				var view: Dictionary = row.states[state][side]
				var label := "%s/%s/%s" % [key, state, side]
				var pack_root: String = Catalog.VARIANT_ROOT if row.has("metrics") else Catalog.PACK_ROOT
				_check("pinned_sha/" + label, FileAccess.get_sha256(pack_root + String(view.atlas)) == String(view.sha256))
				var clip: Dictionary = Catalog.animation(StringName(key), side, state)
				_check("load/" + label + "/" + Catalog.last_error, not clip.is_empty())
				if clip.is_empty():
					continue
				var scale_entry: Dictionary = Catalog.scale_references().get(key, {}).get(side, {})
				_check("scale_reference_or_measured_regional_bounds/" + label, not scale_entry.is_empty() or row.has("metrics"))
				if scale_entry.get("status", "") == "reference_dimensions_match":
					_check("native_reference_scale/" + label, is_equal_approx(float(clip.unit_scale), 1.0))
				_atlases += 1
				_frames += clip.regions.size()
				_check("first_frame/" + label, Catalog.frame_index(clip, 0) == 0)
				if clip.regions.size() > 1:
					_check("advances_frame/" + label, Catalog.frame_index(clip, float(clip.ends[0]) + 0.000001) == 1)
				_check("last_frame/" + label, Catalog.frame_index(clip, float(clip.seconds) - 0.000001) == clip.regions.size() - 1)
				_check("loop_or_hold/" + label, Catalog.frame_index(clip, float(clip.seconds) + 0.000001) == (0 if bool(clip.loop) else clip.regions.size() - 1))
				var stats: Dictionary = Catalog.cache_stats()
				_check("bounded_cache/" + label, stats.entries <= Catalog.MAX_CACHE_ENTRIES and stats.bytes <= Catalog.MAX_CACHE_BYTES)
		index += 1
		if index % 100 == 0:
			print("CATALOG_AUDIT %d/1082 atlases=%d" % [index, _atlases])
			await process_frame
	_check("no_unknown_species_substitution", Catalog.animation(&"not_a_pokemon", "front").is_empty())
	_check("no_invented_attack", Catalog.animation(&"bulbasaur", "front", "ataque").is_empty())
	_check("no_invalid_side_substitution", Catalog.animation(&"bulbasaur", "missing_back").is_empty())
	scene.toggle_pokemon_gallery()
	_check("gallery_opens_and_pauses", scene._pokemon_gallery.visible and not scene.player.movement_enabled)
	_check("gallery_full_catalog", scene._pokemon_gallery._keys.size() == 1082)
	_check("configuration_locked_in_gallery", not scene._can_configure())
	for key: String in ["bulbasaur", "pikachu", "castform", "wailord", "iron_moth", "miraidon", "terapagos", "pecharunt", "ursaluna", "joltik", "charizard", "kyogre"]:
		scene._pokemon_gallery._filter(key)
		_check("gallery_exact_search/" + key, key in scene._pokemon_gallery._keys)
		if key in scene._pokemon_gallery._keys:
			scene._pokemon_gallery._select(scene._pokemon_gallery._keys.find(key))
			_check("gallery_identity/" + key, scene._pokemon_gallery._arena.player_species == StringName(key) and scene._pokemon_gallery._arena.enemy_species == StringName(key))
			await _snapshot("gallery_" + key)
	scene._pokemon_gallery._filter("not_a_pokemon")
	_check("empty_search_clears_preview", scene._pokemon_gallery._arena.player_species == &"")
	scene._pokemon_gallery._repeat()
	scene.toggle_pokemon_gallery()
	_check("gallery_close_restores_movement", not scene._pokemon_gallery.visible and scene.player.movement_enabled)
	# These are genuine configured encounters, not battles fabricated by the gallery.
	for key: String in ["vulpix_alola", "iron_moth", "terapagos", "pecharunt", "wailord"]:
		scene.test_panel._wild_species_input.text = key
		scene.test_panel._wild_min_level.value = 50
		scene.test_panel._wild_max_level.value = 50
		scene.test_panel._encounter_chance.value = 100
		scene.test_panel._player_species_inputs[0].text = "miraidon"
		scene.test_panel._player_level_inputs[0].value = 50
		scene.restart_field_run()
		scene.player.set_physics_process(false)
		scene.player.global_position = Vector2(420, 150)
		scene.player.reset_step_meter()
		await physics_frame
		for step in 24:
			scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
			await physics_frame
			if scene.has_active_demo_battle():
				break
		_check("real_encounter/" + key, scene.has_active_demo_battle())
		if scene.has_active_demo_battle():
			var ui = scene.battle_presentation
			_check("real_battle_sprite_identity/" + key, ui._arena.enemy_species == StringName(key) and ui._arena.player_species == &"miraidon")
			await _snapshot("battle_" + key)
			var result: WildBattleCommandResult = ui.submit_capture_ball(&"master_ball")
			_check("real_capture/" + key, result.accepted and result.session_completed)
			var capture_steps := 0
			while ui._playback.is_playing() and capture_steps < 40:
				ui._playback.advance(float(ui._playback._remaining) + 0.000001)
				capture_steps += 1
			_check("capture_visual_finishes/" + key, not ui._playback.is_playing())
			_check("real_capture_return/" + key, ui.continue_after_completion())
	# The trainer path shares the same renderer but keeps its original AI/controller.
	scene.test_panel._trainer_species_inputs[0].text = "iron_moth"
	scene.test_panel._trainer_level_inputs[0].value = 50
	scene.restart_field_run()
	_check("trainer_starts", scene.start_demo_trainer_battle())
	if scene.has_active_demo_trainer_battle():
		var trainer_ui = scene.trainer_battle_presentation
		_check("trainer_sprite_identity", trainer_ui._arena.enemy_species == trainer_ui.session.opponent_active().species_id and trainer_ui._arena.player_species == trainer_ui.session.player_active().species_id)
		await _snapshot("trainer_battle")
		var moves: Array[StringName] = trainer_ui.available_move_ids()
		_check("trainer_moves_available", not moves.is_empty())
		if not moves.is_empty():
			var events: Array[BattleEvent] = trainer_ui.submit_player_move(moves[0])
			_check("trainer_real_turn_resolves", not events.is_empty())
	await _finish(scene)


func _snapshot(label: String) -> void:
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var folder := "res://.godot/catalog_checks"
	DirAccess.make_dir_recursive_absolute(folder)
	_check("screenshot/" + label, root.get_texture().get_image().save_png(folder.path_join(label + ".png")) == OK)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)


func _finish(scene: Node) -> void:
	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed,
		"failures": _failures, "loaded_atlases": _atlases, "regions": _frames,
		"creatures_constructed_at_level_50": _creatures,
		"scope": "1025 base species and 57 regional forms: visual load, SHA, timing, regions, allowed factory/move references, five encounter/capture samples and trainer presentation. Shiny coverage has its separate pokemon_variant_test_runner gate.",
		"not_certified": ["all battle mechanics", "all moves", "other alternate forms", "final artistic quality"]}
	DirAccess.make_dir_recursive_absolute("res://.godot/catalog_checks")
	var output := FileAccess.open("res://.godot/catalog_checks/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t") + "\n")
	output.close()
	print("CATALOG_INTEGRATION_RESULT " + JSON.stringify(result))
	scene.queue_free()
	Catalog.clear_cache()
	await process_frame
	await process_frame
	quit(0 if _failures.is_empty() else 1)
