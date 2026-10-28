extends SceneTree

const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
const Plan = preload("res://scenes/visual/battle_timeline_plan.gd")
var _passed := 0
var _failures: Array[String] = []
var _capture := false
var _captures := 0
var _catalog: DefinitionCatalog
var _executed := 0


func _initialize() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	_catalog = scene._catalogs
	_test_metadata()
	_test_semantics()
	var representatives := {"normal": "swift", "fire": "ember", "water": "water_gun", "electric": "thunder_shock",
		"grass": "vine_whip", "ice": "ice_beam", "fighting": "karate_chop", "poison": "acid", "ground": "mud_slap",
		"flying": "gust", "psychic": "confusion", "bug": "bug_bite", "rock": "rock_throw", "ghost": "shadow_ball",
		"dragon": "dragon_breath", "dark": "bite", "steel": "metal_claw", "fairy": "fairy_wind"}
	for type: String in representatives:
		var move := _catalog.move(StringName(representatives[type]))
		_check("representative_exists/" + type, move != null and String(move.type_id) == type and move.classification == "RUNTIME_SUPPORTED")
		if move == null or String(move.type_id) != type or move.classification != "RUNTIME_SUPPORTED":
			continue
		await _real_turn(scene, move)
	for id: StringName in [&"growl", &"recover"]:
		await _real_turn(scene, _catalog.move(id))
	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed, "failures": _failures,
		"metadata_moves": _catalog.move_catalog.size(), "visual_types": Visuals.TYPES.size(),
		"executed_move_samples": _executed, "captures": _captures,
		"scope": "Visual metadata/semantic gates, eighteen type representatives plus two status move turns, HUD/RNG/state invariants and GPU samples. Not implementation or certification of all 919 move mechanics or bespoke animations."}
	DirAccess.make_dir_recursive_absolute("res://.godot/move_vfx_checks")
	var output := FileAccess.open("res://.godot/move_vfx_checks/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t") + "\n")
	output.close()
	print("MOVE_VISUALS_RESULT " + JSON.stringify(result))
	scene.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _bindings(move: MoveDefinition) -> Dictionary:
	var a := {"instance_id": "a", "species": "charizard", "side": "back", "hp": 100, "max_hp": 100, "level": 50, "visible": true}
	var b := {"instance_id": "b", "species": "wailord", "side": "front", "hp": 100, "max_hp": 100, "level": 50, "visible": true}
	return {"views": {"back": a.duplicate(), "front": b.duplicate()}, "creatures": {"a": a, "b": b}, "moves": {String(move.id): Visuals.metadata(move)}}


func _event(kind: StringName, move: String, actor: String = "a", target: String = "b", amount: int = 0) -> Dictionary:
	return {"kind": String(kind), "move_id": move, "actor_id": actor, "target_id": target, "amount": amount}


func _test_metadata() -> void:
	_check("eighteen_visual_type_recipes", Visuals.TYPES.size() == 18)
	_check("919_definitions_present_not_runtime_claim", _catalog.move_catalog.size() == 919)
	var types: Dictionary = {}
	for id: StringName in _catalog.move_catalog.all_ids():
		var move := _catalog.move(id)
		var original := move.to_dict().duplicate(true)
		var before := _bindings(move)
		var action := _event(BattleEvent.ACTION_USED, String(id))
		var visual := Visuals.describe(action, before.moves, before.creatures, before.views, action)
		_check("definition_has_visual_recipe/" + String(id), not visual.is_empty())
		if not visual.is_empty():
			_check("actual_move_type_not_creature_type/" + String(id), visual.type_id == String(move.type_id))
			_check("actual_category/" + String(id), visual.category == move.damage_class)
			_check("status_does_not_launch_at_opponent/" + String(id), move.damage_class != "status" or visual.target_side == "back")
			types[visual.type_id] = true
		_check("definition_immutable/" + String(id), move.to_dict() == original)
	_check("all_eighteen_types_in_metadata", types.size() == 18)
	for radius: float in [8.0, 50.0, 150.0, 400.0]:
		var source := Vector2(100, 200)
		var target := Vector2(500, 100)
		var endpoint := Visuals.cast_endpoint(source, target, radius, 1.0)
		_check("projectile_stays_outside_target/%s" % radius, endpoint.distance_to(target) >= radius + 10.0)
	_check("coincident_points_safe", Visuals.cast_endpoint(Vector2.ZERO, Vector2.ZERO, 20, 1) == Vector2.ZERO)


func _test_semantics() -> void:
	var before := _bindings(_catalog.move(&"ember"))
	var action := _event(BattleEvent.ACTION_USED, "ember")
	var hit := _event(BattleEvent.DAMAGE_APPLIED, "ember", "a", "b", 10)
	var plan := Plan.build([action, hit], before, ["acción", "daño"])
	_check("real_damage_has_elemental_hit", plan.size() == 2 and plan[1].move_visual.phase == "hit" and plan[1].move_visual.type_id == "fire")
	var miss := Plan.build([action, _event(BattleEvent.MOVE_MISSED, "ember")], before, ["acción", "fallo"])
	_check("miss_cast_but_no_hit", miss[0].has("move_visual") and not miss[1].has("move_visual"))
	var zero := Plan.build([action, _event(BattleEvent.DAMAGE_APPLIED, "ember", "a", "b", 0)], before, ["acción", "cero"])
	_check("immunity_zero_does_not_create_hit", zero.size() == 1 and zero[0].move_visual.phase == "cast")
	_check("blocked_action_has_no_visual", Visuals.describe(_event(BattleEvent.ACTION_PREVENTED, "ember"), before.moves, before.creatures, before.views, {}).is_empty())
	_check("recoil_not_recast_as_fire", Visuals.describe(_event(BattleEvent.RECOIL_DAMAGE, "ember", "a", "a", 10), before.moves, before.creatures, before.views, action).is_empty())
	_check("reactive_ability_damage_not_recast_as_fire", Visuals.describe(_event(BattleEvent.DAMAGE_APPLIED, "ember", "b", "a", 10), before.moves, before.creatures, before.views, action).is_empty())
	_check("unknown_move_not_guessed", Visuals.describe(_event(BattleEvent.ACTION_USED, "not_a_move"), before.moves, before.creatures, before.views, {}).is_empty())
	before.creatures["bench"] = {"instance_id": "bench", "species": "charizard", "side": "back"}
	_check("bench_not_used_as_effect_origin", Visuals.describe(_event(BattleEvent.ACTION_USED, "ember", "bench", "b"), before.moves, before.creatures, before.views, {}).is_empty())
	var reversed := _event(BattleEvent.ACTION_USED, "ember", "b", "a")
	var reverse_visual := Visuals.describe(reversed, before.moves, before.creatures, before.views, reversed)
	_check("opponent_direction_uses_instance_ownership", reverse_visual.source_side == "front" and reverse_visual.target_side == "back")
	var growl := _catalog.move(&"growl")
	before = _bindings(growl)
	action = _event(BattleEvent.ACTION_USED, "growl")
	var support := Plan.build([action, _event(BattleEvent.STAT_STAGE_CHANGED, "growl", "a", "b", -1)], before, ["acción", "efecto"])
	_check("support_on_actual_recipient_not_damage", support.size() == 2 and support[1].move_visual.phase == "support" and support[1].move_visual.target_side == "front")
	_check("failed_status_does_not_show_success", Visuals.describe(_event(BattleEvent.STATUS_FAILED, "growl"), before.moves, before.creatures, before.views, action).is_empty())
	_check("zero_stage_change_has_no_effect", Visuals.describe(_event(BattleEvent.STAT_STAGE_CHANGED, "growl", "a", "b", 0), before.moves, before.creatures, before.views, action).is_empty())
	before = _bindings(_catalog.move(&"recover"))
	action = _event(BattleEvent.ACTION_USED, "recover")
	var self_heal := Visuals.describe(_event(BattleEvent.HP_RECOVERED, "recover", "a", "a", 10), before.moves, before.creatures, before.views, action)
	_check("self_heal_does_not_target_opponent", self_heal.phase == "support" and self_heal.target_side == "back")
	var invalid := before.duplicate(true)
	invalid.moves.recover.type_id = "not_a_type"
	_check("unknown_type_not_guessed", Visuals.describe(action, invalid.moves, invalid.creatures, invalid.views, action).is_empty())


func _real_turn(scene: Node, move: MoveDefinition) -> void:
	print("MOVE_VISUAL_AUDIT " + String(move.type_id) + "/" + String(move.id))
	scene.test_panel._player_species_inputs[0].text = "charizard"
	scene.test_panel._player_level_inputs[0].value = 50
	scene.test_panel._player_species_inputs[1].text = "pikachu"
	scene.test_panel._player_level_inputs[1].value = 50
	scene.test_panel._wild_species_input.text = "wailord"
	scene.test_panel._wild_min_level.value = 50
	scene.test_panel._wild_max_level.value = 50
	scene.test_panel._encounter_chance.value = 100
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
	_check("real_encounter/" + String(move.id), scene.has_active_demo_battle())
	if not scene.has_active_demo_battle():
		return
	var ui = scene.battle_presentation
	ui._playback.set_process(false)
	ui._arena.set_process(false)
	for id: StringName in ui.session.battle_state().participant_ids:
		var creature: CreatureInstance = ui.session.battle_state().creature(id)
		creature.moveset.assign([BattleMoveSlot.new(move.id, move.pp, move.pp)])
		creature.move_ids.assign([move.id])
		if move.id == &"recover":
			creature.current_hp = maxi(1, creature.stats.max_hp / 2)
	ui._refresh_view()
	var events: Array[BattleEvent] = ui.submit_player_move(move.id)
	_check("real_turn/" + String(move.id), not events.is_empty())
	var resolved: Dictionary = ui.session.battle_state().to_dict().duplicate(true) if ui.session.battle_state() != null else {}
	var rng: int = scene._capture_rng.state
	var escape_rng: int = scene._escape_rng.state
	var casts := 0
	var supports := 0
	var limit := 0
	while ui._playback.is_playing() and limit < 60:
		var entry: Dictionary = ui._playback._sequence[ui._playback._index]
		# Native body clips can be longer than the elemental cast window. Sample
		# the middle of the actual overlay, not the middle of the body clip.
		var duration := float(ui._playback._remaining)
		var sample_at := duration * 0.5
		if entry.get("move_visual", {}).get("phase", "") == "cast":
			sample_at = duration - minf(0.6, duration) * 0.5
		ui._playback.advance(sample_at)
		if entry.get("community_preparation", false):
			casts += 1
			_check("community_preparation_replaces_generic_cast/" + String(move.id), entry.event_kind == String(BattleEvent.ACTION_USED) and not entry.has("move_visual"))
		if entry.has("move_visual"):
			var visual: Dictionary = entry.move_visual
			_check("real_recipe_matches_move/" + String(move.id), visual.type_id == String(move.type_id))
			_check("overlay_active_at_sample/" + String(move.id), ui._arena._move_progress > 0.0 and ui._arena._move_progress < 1.0)
			if visual.phase == "cast":
				casts += 1
			if visual.phase == "support":
				supports += 1
			if _capture and (visual.source_side == "back" or move.id in [&"ember", &"water_gun", &"thunder_shock"]):
				await process_frame
				await process_frame
				RenderingServer.force_draw(false)
				DirAccess.make_dir_recursive_absolute("res://.godot/move_vfx_checks")
				var path := "res://.godot/move_vfx_checks/%s_%02d_%s_%s.png" % [move.id, limit, visual.phase, visual.source_side]
				var saved := root.get_texture().get_image().save_png(path) == OK
				_check("gpu_capture/" + path, saved)
				if saved:
					_captures += 1
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		limit += 1
	_check("real_move_has_cast/" + String(move.id), casts > 0)
	if move.damage_class == "status":
		_check("real_status_has_support/" + String(move.id), supports > 0)
	_check("bounded_sequence/" + String(move.id), not ui._playback.is_playing())
	_check("visual_does_not_replay_rng/" + String(move.id), scene._capture_rng.state == rng and scene._escape_rng.state == escape_rng)
	_check("visual_is_cleared/" + String(move.id), ui._arena._move_visual.is_empty())
	if not resolved.is_empty():
		_check("visual_does_not_change_battle/" + String(move.id), ui.session.battle_state().to_dict() == resolved)
		ui.submit_capture_ball(&"master_ball")
		var cleanup := 0
		while ui._playback.is_playing() and cleanup < 60:
			ui._playback.advance(float(ui._playback._remaining) + 0.000001)
			cleanup += 1
	_check("return_after_real_turn/" + String(move.id), ui.continue_after_completion())
	_executed += 1


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
