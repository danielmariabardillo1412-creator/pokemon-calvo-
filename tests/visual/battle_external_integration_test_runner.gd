extends SceneTree

const Pilot = preload("res://scenes/visual/battle_external_damage_pilot.gd")
const Plan = preload("res://scenes/visual/battle_timeline_plan.gd")
const Visuals = preload("res://scenes/visual/battle_move_visuals.gd")
const Context = preload("res://scenes/visual/move_external_context.gd")
const OUTPUT := "res://.godot/battle_external_integration/"
var checks := 0
var errors: Array[String] = []
var catalog: DefinitionCatalog
var core_cases: Array = []
var screenshots: Array = []
var native_hits := 0
var gpu := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok and errors.size() < 40:
		errors.append(label)


func _run() -> void:
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	catalog = GameData.from_dict(data).to_definition_catalog()
	var arena := Control.new()
	root.add_child(arena)
	var pilot := Pilot.new()
	root.add_child(pilot)
	pilot.configure(arena)
	check("ten reviewed damage clips available", pilot.available and pilot._indices.size() == 10)
	if not pilot.available:
		_finish()
		return
	_audit_engine(pilot)
	_semantic_gates(pilot)
	await _real_presentations()
	var hashes := {}
	for path: String in ["scenes/visual/battle_external_damage_pilot.gd", "scenes/visual/battle_animation_playback.gd", "scenes/visual/field_demo.gd", "scenes/visual/community_move_preview.gd", "data/normalized/pokemon_api.json", "data/raw/pokemon_api.json", ".godot/move_batch_catalog/index.json", "tests/visual/battle_external_integration_test_runner.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report := {"version": 1, "status": "PASS" if errors.is_empty() else "FAIL", "checks": checks,
		"errors": errors, "gpu": gpu, "core_cases": core_cases, "native_hits": native_hits,
		"screenshots": screenshots, "source_sha256": hashes,
		"binding_pack_sha256": FileAccess.get_sha256(Pilot.EXTERNAL_PACK),
		"full_special_effects_completed": 0, "pending_full_effect_ids": Context.REQUIREMENTS.keys(),
		"scope": "Real engine audit of 19 moves; five confirmed-damage-only visual bindings. No pivot/phaze/weather/substitute/transform/doubles mechanics added."}
	var file := FileAccess.open(OUTPUT + ("gpu_result.json" if gpu else "headless_result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ", true) + "\n")
	file.close()
	_finish()


func _finish() -> void:
	print("EXTERNAL_INTEGRATION ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " engine_cases=", core_cases.size(), " native_hits=", native_hits, " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _fixture(move: String, origin: String = "back") -> Dictionary:
	var a := CreatureInstance.new(&"a", &"eevee", 50, StatBlock.new(2000, 100, 100, 200, 100, 100), [StringName(move) if origin == "back" else &"tackle"])
	var b := CreatureInstance.new(&"b", &"wailord", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [StringName(move) if origin == "front" else &"tackle"])
	var a2 := CreatureInstance.new(&"a2", &"pikachu", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [&"tackle"])
	var b2 := CreatureInstance.new(&"b2", &"pikachu", 50, StatBlock.new(2000, 100, 100, 100, 100, 100), [&"tackle"])
	var state := BattleState.create_with_parties(&"external_audit", [a, a2], [b, b2], 7)
	var server := AuthoritativeBattleServer.new(state, catalog)
	var actor: CreatureInstance = a if origin == "back" else b
	var target: CreatureInstance = b if origin == "back" else a
	actor.stat_stages.change(StatStages.ACCURACY, 6)
	target.stat_stages.change(StatStages.EVASION, -6)
	return {"state": state, "server": server, "actor": actor, "target": target, "origin": origin}


func _before(state: BattleState) -> Dictionary:
	var result := {"views": {}, "creatures": {}, "moves": {}}
	for side: BattleSide in state.sides:
		var image_side := "back" if side.side_id == &"side_a" else "front"
		for id: StringName in side.party_ids:
			var c := state.creature(id)
			var row := {"instance_id": String(id), "species": String(c.species_id), "side": image_side, "name": String(c.species_id), "level": c.level, "hp": c.current_hp, "max_hp": c.stats.max_hp, "visible": not c.is_knocked_out()}
			result.creatures[String(id)] = row
			if id == side.active_id:
				result.views[image_side] = row.duplicate(true)
			for slot: BattleMoveSlot in c.moveset:
				result.moves[String(slot.move_id)] = Visuals.metadata(catalog.move(slot.move_id))
	return result


func _serialize(events: Array[BattleEvent]) -> Array:
	var rows: Array = []
	for event: BattleEvent in events:
		rows.append(event.to_dict())
	return rows


func _reaction(f: Dictionary, move: String) -> Array[BattleEvent]:
	return f.server.submit_reaction_turn(BattleAction.new(f.state.turn + 1, f.actor.instance_id, StringName(move), f.target.instance_id, BattleAction.MOVE, &"side_a" if f.origin == "back" else &"side_b"), &"side_b" if f.origin == "back" else &"side_a")


func _audit_engine(pilot: Node) -> void:
	var registry := BattleEffectRegistry.new()
	for move: String in Context.REQUIREMENTS:
		for origin: String in ["back", "front"]:
			var f := _fixture(move, origin)
			var before := _before(f.state)
			var active_before: Array = f.state.active_ids.duplicate()
			var hp: int = f.target.current_hp
			var events := _reaction(f, move)
			var kinds: Array = []
			var damage := 0
			var switched := false
			for event: BattleEvent in events:
				kinds.append(String(event.kind))
				switched = switched or event.kind == BattleEvent.SWITCHED
				if event.kind == BattleEvent.DAMAGE_APPLIED and event.actor_id == f.actor.instance_id:
					damage += event.amount
			check("engine action executes " + move + origin, String(BattleEvent.ACTION_USED) in kinds and String(BattleEvent.ACTION_REJECTED) not in kinds)
			check("engine observed damage boundary " + move + origin, (damage > 0) == Pilot.DAMAGE_PROFILES.has(move))
			check("no special switch event currently exists " + move, not switched and f.state.active_ids == active_before)
			check("applied damage is authoritative " + move, hp - f.target.current_hp == damage)
			var snapshot: Dictionary = f.state.to_dict().duplicate(true)
			var sequence: Array[Dictionary] = pilot.decorate(Plan.build(_serialize(events), before), before)
			check("binding follows real damage " + move, _native_count(sequence) == (1 if damage > 0 else 0))
			check("binding does not mutate engine " + move, snapshot == f.state.to_dict())
			var specs: Array = []
			for spec: BattleEffectSpec in registry.effects_for_move(catalog.move(StringName(move))):
				specs.append(String(spec.kind))
			core_cases.append({"move_id": move, "side": origin, "classification": catalog.move(StringName(move)).classification, "registered_effect_kinds": specs,
				"damage": damage, "switched": switched, "full_special_effect_resolved": false,
				"native_damage_binding": damage > 0, "requirement": Context.REQUIREMENTS[move], "events": _serialize(events)})
	check("all 19 engine cases in both directions", core_cases.size() == 38)
	# Real ordinary switch: neither move IDs nor animation completion select it.
	var f := _fixture("u_turn")
	var before := _before(f.state)
	var events: Array[BattleEvent] = f.server.submit_reaction_turn(BattleAction.new(1, &"a", &"", &"", BattleAction.SWITCH, &"side_a", &"a2"), &"side_b")
	var sequence: Array[Dictionary] = pilot.decorate(Plan.build(_serialize(events), before), before)
	check("real switch event uses existing withdrawal/entry", _native_count(sequence) == 0 and sequence.size() == 2 and sequence.back().after_views.back.instance_id == "a2")
	# A KO does cause replacement; it must never be mistaken for pivoting.
	f = _fixture("u_turn")
	f.target.current_hp = 1
	before = _before(f.state)
	events = _reaction(f, "u_turn")
	sequence = pilot.decorate(Plan.build(_serialize(events), before), before)
	check("KO replacement remains on defeated side", f.state.sides[0].active_id == &"a" and f.state.sides[1].active_id == &"b2" and _native_count(sequence) == 1)
	check("KO incoming view correct", sequence.back().after_views.front.instance_id == "b2")
	# Actual Electric immunity produces no damage clip.
	f = _fixture("volt_switch")
	f.target.species_id = &"diglett"
	before = _before(f.state)
	events = _reaction(f, "volt_switch")
	sequence = pilot.decorate(Plan.build(_serialize(events), before), before)
	check("real immunity has no impact or pivot", f.target.current_hp == 2000 and _native_count(sequence) == 0 and f.state.sides[0].active_id == &"a")


func _semantic_gates(pilot: Node) -> void:
	for move: String in Pilot.DAMAGE_PROFILES:
		var f := _fixture(move)
		var before := _before(f.state)
		var action := {"kind": String(BattleEvent.ACTION_USED), "move_id": move, "actor_id": "a", "target_id": "b"}
		for row: Array in [[BattleEvent.DAMAGE_APPLIED, 20, "a", "b", true], [BattleEvent.DAMAGE_APPLIED, 0, "a", "b", false], [BattleEvent.MOVE_MISSED, 0, "a", "b", false], [BattleEvent.DAMAGE_APPLIED, 20, "b", "a", false], [BattleEvent.RECOIL_DAMAGE, 20, "a", "a", false]]:
			var raw := {"kind": String(row[0]), "move_id": move, "actor_id": row[2], "target_id": row[3], "amount": row[1]}
			var plan := Plan.build([action, raw], before)
			var original := plan.duplicate(true)
			check("semantic damage gate " + move, (_native_count(pilot.decorate(plan, before)) > 0) == row[4])
			check("detached projection preserves its input", plan == original)
		for field: Array in [["classification", "DATA_ONLY"], ["category", "status"], ["type_id", "ghost"], ["power", 999], ["target", "user"], ["effects_empty", false]]:
			var metadata: Dictionary = before.moves[move].duplicate(true)
			metadata[field[0]] = field[1]
			check("metadata contract cannot be widened", not pilot._accepts(move, metadata))
	var missing := Pilot.new()
	root.add_child(missing)
	var arena := Control.new()
	root.add_child(arena)
	missing.configure(arena, "res://.godot/battle_external_damage/missing.json")
	check("missing cache remains optional", not missing.available)
	missing.queue_free()
	arena.queue_free()


func _native_count(sequence: Array) -> int:
	var result := 0
	for step: Dictionary in sequence:
		result += int(step.get("external_damage_only", false))
	return result


func _real_presentations() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	for move: String in Pilot.DAMAGE_PROFILES:
		_configure(scene)
		check("manual preset available " + move, scene.prepare_visual_move_test(StringName(move)))
		check("manual preset labelled damage only", "SOLO DAÑO" in scene._notice_label.text)
		if gpu and move == "circle_throw":
			await process_frame
			await process_frame
			check("preset HUD names actual encounter", "Wailord" in scene._collection_label.text)
			check("preset HUD reports configured frequency", "100" in scene._chance_button.text)
			RenderingServer.force_draw(false)
			check("preset map screenshot", root.get_texture().get_image().save_png(OUTPUT + "map_partial_preset.png") == OK)
			screenshots.append({"path": "map_partial_preset.png", "sha256": FileAccess.get_sha256(OUTPUT + "map_partial_preset.png")})
		await _encounter(scene)
		var ui = scene.battle_presentation
		var state: BattleState = ui.session.battle_state()
		check("preset blocked while battle open", not scene.cycle_external_damage_test())
		_fixture_moves(state, move)
		ui._refresh_view()
		var events: Array[BattleEvent] = ui.submit_player_move(StringName(move))
		check("both real hit directions " + move, not events.is_empty() and _native_count(ui._playback._sequence) == 2)
		var snapshot := state.to_dict().duplicate(true)
		var capture_rng: int = scene._capture_rng.state
		var escape_rng: int = scene._escape_rng.state
		check("input locked in external playback", ui.submit_player_move(StringName(move)).is_empty() and ui._move_buttons[0].disabled)
		await _drain(ui, move)
		check("replay never changes resolved battle " + move, state.to_dict() == snapshot)
		check("replay never consumes other RNG", scene._capture_rng.state == capture_rng and scene._escape_rng.state == escape_rng)
		check("source disappearance cannot hide live bodies", ui._arena._player_visible and ui._arena._enemy_visible)
		check("native layer cleared", not ui._playback._external_damage.preview.visible and ui._playback._external_damage.preview.visible_cells() == 0)
		ui.submit_player_move(StringName(move))
		while ui._playback.is_playing() and not ui._playback._sequence[ui._playback._index].get("external_damage_only", false):
			ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		check("cancellation reaches native clip", ui._playback.is_playing())
		snapshot = state.to_dict().duplicate(true)
		ui.hide()
		check("cancel cleans both layers and preserves domain", not ui._playback.is_playing() and not ui._playback._external_damage.preview.visible and snapshot == state.to_dict())
		ui.open_for_active_battle()
		ui.submit_capture_ball(&"master_ball")
		await _drain(ui, "capture_cleanup")
		check("return to route", ui.continue_after_completion())
	# Trainer path and KO settlement use the same authoritative replay seam.
	_configure(scene)
	check("trainer session starts", scene.start_demo_trainer_battle())
	var trainer = scene.trainer_battle_presentation
	trainer._playback.set_process(false)
	_fixture_moves(trainer.session.battle_state(), "volt_switch")
	trainer.session.opponent_active().current_hp = 1
	trainer._refresh_view()
	var events: Array[BattleEvent] = trainer.submit_player_move(&"volt_switch")
	check("trainer KO damage clip survives released state", not events.is_empty() and trainer.session.battle_state() == null and _native_count(trainer._playback._sequence) == 1)
	await _drain(trainer, "trainer_ko")
	check("KO does not resurrect the target", not trainer._arena._enemy_visible and not trainer._playback._external_damage.preview.visible)
	check("trainer return to route", trainer.continue_after_completion())
	scene.queue_free()
	await process_frame


func _configure(scene: Node) -> void:
	for field: LineEdit in scene.test_panel._player_species_inputs:
		field.text = ""
	for field: LineEdit in scene.test_panel._trainer_species_inputs:
		field.text = ""
	scene.test_panel._player_species_inputs[0].text = "ogerpon"
	scene.test_panel._player_level_inputs[0].value = 50
	scene.test_panel._trainer_species_inputs[0].text = "wailord"
	scene.test_panel._trainer_level_inputs[0].value = 50
	scene.test_panel._wild_species_input.text = "wailord"
	scene.test_panel._wild_min_level.value = 50
	scene.test_panel._wild_max_level.value = 50
	scene.test_panel._encounter_chance.value = 100
	scene.restart_field_run()
	# This report remains the explicit historical/default-mechanics comparison.
	# Live game integration has its own full-catalog/session/AI suite.
	scene._session.live_moves_enabled = false
	scene._trainer_session.live_moves_enabled = false
	scene.player.set_physics_process(false)
	scene.battle_presentation._playback.set_process(false)
	scene.battle_presentation._arena.set_process(false)


func _encounter(scene: Node) -> void:
	scene.player.global_position = Vector2(420, 150)
	scene.player.reset_step_meter()
	await physics_frame
	for n in 24:
		scene.player.apply_motion(Vector2.RIGHT, 1.0 / 60.0)
		await physics_frame
		if scene.has_active_demo_battle():
			break
	check("real grass encounter", scene.has_active_demo_battle())


func _fixture_moves(state: BattleState, move: String) -> void:
	for id: StringName in state.participant_ids:
		var c := state.creature(id)
		c.moveset.assign([BattleMoveSlot.new(StringName(move), 20, 20)])
		c.move_ids.assign([StringName(move)])
		c.stats.max_hp = 2000
		c.current_hp = 2000
		c.stats.speed = 10000 if state.sides[0].owns(id) else 100
		c.stat_stages.change(StatStages.ACCURACY, 6)
		c.stat_stages.change(StatStages.EVASION, -6)


func _drain(ui: Control, label: String) -> void:
	var iterations := 0
	while ui._playback.is_playing() and iterations < 120:
		var step: Dictionary = ui._playback._sequence[ui._playback._index]
		if step.get("external_damage_only", false):
			native_hits += 1
			var side := String(step.side)
			var initial := int(step.views[side].hp)
			var final := int(step.after_views[side].hp)
			ui._playback.advance(maxf(0.0, float(step.community_impact) - 0.01))
			var hp: int = ui.displayed_player_hp() if side == "back" else ui.displayed_enemy_hp()
			check("HP waits for native impact " + label, hp == initial)
			check("special effect is explicitly still pending", step.special_effect_implemented == false)
			ui._playback.advance(0.09)
			var preview: Control = ui._playback._external_damage.preview
			var recipient: Dictionary = preview._actors[side]
			var nearest := INF
			for sprite: Sprite2D in preview._sprites:
				if sprite.visible:
					nearest = minf(nearest, sprite.position.distance_to(recipient.center))
			check("impact reaches actual recipient " + label, nearest <= maxf(28.0, float(recipient.half_height) * 1.4))
			check("no native bodies or plates", preview.effects_only and not preview._arena.visible and not preview._sprites[0].visible and not preview._sprites[1].visible and not preview._layers.back.visible and not preview._layers.front.visible)
			check("no duplicate generic hit", ui._arena._move_visual.is_empty())
			if gpu:
				await process_frame
				RenderingServer.force_draw(false)
				var name := label + "_" + String(step.community_clip).replace("/", "_") + ".png"
				check("GPU screenshot", root.get_texture().get_image().save_png(OUTPUT + name) == OK)
				screenshots.append({"path": name, "sha256": FileAccess.get_sha256(OUTPUT + name)})
			ui._playback.advance(maxf(0.0, float(step.community_hp_end) - (float(step.duration) - float(ui._playback._remaining))))
			hp = ui.displayed_player_hp() if side == "back" else ui.displayed_enemy_hp()
			check("HP follows actual resolved amount " + label, hp == final)
		ui._playback.advance(float(ui._playback._remaining) + 0.000001)
		iterations += 1
	check("bounded playback ends", not ui._playback.is_playing())
