extends SceneTree

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Layout = preload("res://scenes/visual/battle_sprite_layout.gd")
var _passed := 0
var _failures: Array[String] = []
var _capture := false
var _clips := 0
var _sampled_frames := 0


func _initialize() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	_check("existing_game_boots", scene.is_demo_ready())
	var config: Dictionary = scene._active_config.duplicate(true)
	var capture_rng_state: int = scene._capture_rng.state
	var escape_rng_state: int = scene._escape_rng.state
	var party_size: int = scene.demo_party_size()
	var balls: int = scene.demo_inventory_quantity(&"poke_ball")
	scene.toggle_pokemon_gallery()
	var gallery = scene._pokemon_gallery
	gallery._arena.set_process(false)
	var keys: Array[String] = []
	for key: String in Catalog.species_rows():
		if bool(Catalog.species_rows()[key].provisional):
			keys.append(key)
	_check("fourteen_custom_species", keys.size() == 14)
	for key: String in keys:
		gallery._filter(key)
		gallery._select(gallery._keys.find(key))
		_check("honest_reference_label/" + key, "sin referencia externa" in gallery._detail.text)
		var fixed_projection: Dictionary = {}
		for state: String in ["reposo", "ataque", "dano"]:
			_choose_state(gallery, state)
			for side: String in ["front", "back"]:
				var clip: Dictionary = Catalog.animation(StringName(key), side, state)
				_check("clip/%s/%s/%s" % [key, state, side], not clip.is_empty())
				if clip.is_empty():
					continue
				_clips += 1
				var envelope := Catalog.presentation_bounds(StringName(key), side, clip)
				var state_projection: Dictionary = Layout.placement(Vector2(674, 359), side, envelope)
				if not fixed_projection.has(side):
					fixed_projection[side] = state_projection
				_check("same_projection_across_body_states", state_projection == fixed_projection[side])
				for elapsed: float in [0.0, float(clip.seconds) * 0.5, float(clip.seconds) - 0.000001]:
					var frame := Catalog.frame_index(clip, elapsed)
					_sampled_frames += 1
					_check("frame_in_range", frame >= 0 and frame < clip.regions.size())
					# Frame/animation state is deliberately absent from the layout input.
					var placement: Dictionary = Layout.placement(Vector2(674, 359), side, envelope)
					_check("stable_projection", placement == Layout.placement(Vector2(674, 359), side, envelope))
				_check("one_custom_conversion", is_equal_approx(float(clip.unit_scale), Catalog.presentation_scale(StringName(key), side)))
				_check("loop_semantics", bool(clip.loop) == (state == "reposo"))
			var mid_clip: Dictionary = Catalog.animation(StringName(key), "front", state)
			gallery._arena._player_time = float(mid_clip.seconds) * 0.5
			gallery._arena._enemy_time = float(mid_clip.seconds) * 0.5
			gallery._arena.queue_redraw()
			await _snapshot(key + "_" + state)
		# Compare against an existing catalog species, without assigning body attacks to it.
		gallery._compare_with("charizard")
		_check("comparison_front/" + key, gallery._arena.enemy_species == StringName(key) and gallery._arena.player_species == &"charizard")
		_check("reference_idle_not_fake_attack/" + key, gallery._arena.player_preview_state == "reposo")
		_choose_state(gallery, "reposo")
		await _snapshot(key + "_frente_comparado")
		gallery._swap_comparison()
		_check("comparison_back/" + key, gallery._arena.player_species == StringName(key) and gallery._arena.enemy_species == &"charizard")
		_check("opposite_reference_idle/" + key, gallery._arena.enemy_preview_state == "reposo")
		await _snapshot(key + "_espalda_comparada")
		gallery._clear_comparison()
		_check("same_species_restored/" + key, gallery._arena.player_species == StringName(key) and gallery._arena.enemy_species == StringName(key))
	gallery._compare_with("Pikachu")
	_check("spanish_name_lookup", gallery._arena.player_species == &"pikachu")
	var previous_reference: StringName = gallery._comparison_species
	gallery._compare_with("not_a_pokemon")
	_check("unknown_reference_does_not_substitute", gallery._comparison_species == previous_reference)
	gallery._filter("not_a_pokemon")
	_check("empty_search_clears_both_views", gallery._arena.player_species == &"" and gallery._arena.enemy_species == &"")
	gallery._clear_comparison()
	scene.toggle_pokemon_gallery()
	_check("gameplay_config_unchanged", scene._active_config == config)
	_check("capture_rng_unchanged", scene._capture_rng.state == capture_rng_state)
	_check("escape_rng_unchanged", scene._escape_rng.state == escape_rng_state)
	_check("party_unchanged", scene.demo_party_size() == party_size)
	_check("inventory_unchanged", scene.demo_inventory_quantity(&"poke_ball") == balls)
	_check("movement_restored", scene.player.movement_enabled)
	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed, "failures": _failures,
		"custom_species": keys.size(), "clips_checked": _clips, "frame_samples": _sampled_frames,
		"art_approved": false, "external_scale_reference_for_custom_renders": false}
	DirAccess.make_dir_recursive_absolute("res://.godot/custom_sprite_checks")
	var output := FileAccess.open("res://.godot/custom_sprite_checks/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t") + "\n")
	output.close()
	print("CUSTOM_SPRITE_REVIEW_RESULT " + JSON.stringify(result))
	scene.queue_free()
	Catalog.clear_cache()
	await process_frame
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _choose_state(gallery: Control, state: String) -> void:
	for index in gallery._states.item_count:
		if String(gallery._states.get_item_metadata(index)) == state:
			gallery._states.select(index)
			gallery._repeat()
			return
	_check("state_in_ui/" + state, false)


func _snapshot(label: String) -> void:
	if not _capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.godot/custom_sprite_checks/"
	DirAccess.make_dir_recursive_absolute(path)
	_check("capture/" + label, root.get_texture().get_image().save_png(path + label + ".png") == OK)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
