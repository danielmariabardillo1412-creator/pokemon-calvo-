extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Doubles = preload("res://modules/battle/backends/showdown/doubles_backend.gd")
const Adapter = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const SINGLE := "gen9calvounifiedv1"
const DOUBLE := "gen9calvounifieddoublesv1"
const OUT := "res://.godot/unified_profile_checks/"
var catalog: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var projections: Array = []
var captures: Array = []
var active: RefCounted
var scene: Node
var view: Control
var done := false


func _initialize() -> void: call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label); printerr(active.last_error if active != null else "")


func mon(id: String, moves: Array, item: String = "") -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(catalog.species(&"mew"), 50, catalog, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""; c.held_item_id = StringName(item); return c


func _run() -> void:
	create_timer(240).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			if view != null and view.session != null: view.session.stop_now()
			check("watchdog", false); _finish())
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	active = Backend.new(catalog, SINGLE)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "z/manifest.json"))
	for filename: String in manifest.batches:
		for row: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(OUT + "z/" + filename)):
			_project(row, active)
	active = Doubles.new(catalog, DOUBLE)
	for row: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(OUT + "doubles/cases.json")):
		_project(row, active)
	var output := FileAccess.open(OUT + "special_projection.json", FileAccess.WRITE); output.store_string(JSON.stringify(projections)); output.close()
	await _live()
	await _field()
	_finish()


func _project(row: Dictionary, backend: RefCounted) -> void:
	backend._origin = row.origin
	var before: BattleState = backend._mirror(row.before)
	var after: BattleState = backend._mirror(row.after)
	var result := Adapter.project(row.before, row.after, backend._moves, backend._policy, backend._species)
	var ok: bool = before != null and after != null and result.ok
	check("projection " + row.case_id + " " + str(result.unknown), ok)
	if after != null:
		for side: Dictionary in row.after.roster:
			for p: Dictionary in side.pokemon:
				var c := after.creature(StringName(p.instance_id))
				check("exact HP/PP " + row.case_id + "/" + p.instance_id, c.current_hp == int(p.hp) and c.moveset[0].current_pp == int(p.moves[0].pp))
	projections.append({"id": row.id, "case_id": row.case_id, "ok": ok, "unknown": result.unknown})


func _live() -> void:
	active = Backend.new(catalog, SINGLE)
	var a := [mon("own", ["torch_song", "protect"]), mon("z", ["tackle"], "normalium_z_held")] as Array[CreatureInstance]
	var b := [mon("foe", ["reflect"]), mon("reserve", ["reflect"])] as Array[CreatureInstance]
	check("live unified opens", await active.open(self, a, b))
	check("live offers Max", active.request().active[0].get("canDynamax", false))
	var initial: Dictionary = active.snapshot()
	var result: Dictionary = await active.submit("move 1 dynamax", active.revision)
	check("Gen9 slot emits real Max Flare", result.accepted and result.events.any(func(e): return e.kind == BattleEvent.ACTION_USED and e.move_id == &"max_flare"))
	check("max mirror has doubled HP and sources unchanged", active.presentation_state.creature(&"own").stats.max_hp == a[0].stats.max_hp * 2 and a[0].current_hp == a[0].stats.max_hp)
	var saved: Dictionary = active.snapshot()
	var restored := Backend.new(catalog, SINGLE)
	check("live checkpoint exact", await restored.restore_saved(self, saved) and restored.snapshot() == saved)
	await restored.close()
	var old := Backend.new(catalog)
	check("old Gen9 cannot misread unified checkpoint", not await old.restore_saved(self, saved) and old._client == null)
	var now := Backend.new(catalog, SINGLE)
	check("initial native checkpoint exact", await now.restore_saved(self, initial) and now.snapshot() == initial)
	await now.close(); await active.close()
	active = Doubles.new(catalog, DOUBLE)
	a = [mon("one", ["tackle", "protect"]), mon("two", ["tackle"], "normalium_z_held")]
	check("live combined doubles opens", await active.open(self, a, b))
	check("Z offer resolves for second active", active.z_move_id(0, "p1", 1) == "breakneck_blitz_physical" and active.z_move_id(0).is_empty())
	result = await active.submit_pair({"p1": "move 2, move 1 1 zmove", "p2": "move 1, move 1"}, active.revision)
	check("second-active Z and four mirror slots", result.accepted and active.presentation_state.active_ids.size() == 4 and result.events.any(func(e): return e.kind == BattleEvent.ACTION_USED and e.actor_id == &"two" and e.move_id == &"breakneck_blitz_physical"))
	await active.close()
	active = Doubles.new(catalog, DOUBLE)
	a[1] = mon("two", ["conversion", "tackle"], "normalium_z_held")
	check("status Z fixture opens", await active.open(self, a, b))
	saved = active.snapshot()
	check("second-active status Z rolls back both sides", not (await active.submit_pair({"p1": "move 2, move 1 zmove", "p2": "move 1, move 1"}, active.revision)).accepted and active.snapshot() == saved)
	check("double Max resolves with independent ally", (await active.submit_pair({"p1": "move 1 1 dynamax, move 2 1", "p2": "move 1, move 1"}, active.revision)).accepted and active.presentation_state.creature(&"one").stats.max_hp == a[0].stats.max_hp * 2)
	await active.close()


func _field() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var bridge: Node = scene._native_battles; view = bridge.view
	check("ordinary map defaults to versioned combined profile", bridge.format_id == SINGLE)
	bridge.save_path = OUT + "field.json"
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "snorlax"; config.wild_min_level = 50; config.wild_max_level = 50; config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	scene._session.player.party = CreatureParty.new(); scene._session.player.party.add_creature(mon("field_own", ["torch_song", "protect"]))
	scene._session.player.inventory.add(&"master_ball", 1)
	scene.player.global_position = Vector2(420, 150); bridge._unlock_world(); await physics_frame
	await scene._on_player_step_completed(scene.player.global_position)
	check("unified enters same ordinary map", view.session != null and view.session.format_id == SINGLE and scene.has_active_demo_battle())
	view._playback.set_process(false); view._refresh_view()
	check("map offers actual Max control", view._dynamax_toggle.visible and not view._dynamax_toggle.disabled)
	view._dynamax_toggle.set_pressed_no_signal(true)
	check("map Max move resolves", (await view.choose("move 1")).accepted)
	await _drain()
	check("Max Flare sunlight is named in the presentation", view._event_log.text.contains("Sol intenso") and not preload("res://modules/battle/application/weather_rules.gd").label(view.session.battle_state().weather).is_empty())
	await _capture("map_unified_max")
	check("mid-Max map save", bridge.save_game())
	var saved: Dictionary = view.session.snapshot()
	check("mid-Max map reload", await bridge.load_game() and view.session.snapshot() == saved and bridge.format_id == SINGLE)
	view._playback.set_process(false)
	check("capture in combined profile", (await view.adventure_command("master")).accepted); await _drain()
	var own: CreatureInstance = scene._session.player.party.get_creature(&"field_own")
	check("settlement restores canonical base HP and preserves PP cost", scene.demo_party_size() == 2 and own.stats.max_hp == mon("field_own", ["torch_song", "protect"]).stats.max_hp and own.moveset[0].current_pp == catalog.move(&"torch_song").pp - 1)
	await bridge.leave_battle()
	check("return to real map", not scene.has_active_demo_battle() and scene.player.movement_enabled)
	await _capture("map_unified_captured")
	if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame


func _drain() -> void:
	var n := 0
	while view._playback.is_playing() and n < 2000: view._playback.advance(0.25); n += 1
	await process_frame; await process_frame; view._refresh_view()
	check("presentation completes", not view._playback.is_playing())


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame; await RenderingServer.frame_post_draw
	var p := OUT + label + ".png"; check("GPU capture " + label, root.get_texture().get_image().save_png(p) == OK)
	captures.append({"path": p.trim_prefix("res://"), "sha256": FileAccess.get_sha256(p)})


func _finish() -> void:
	if done: return
	done = true
	var file := FileAccess.open(OUT + ("live.json" if DisplayServer.get_name() == "headless" else "gpu.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "captures": captures}, "  ")); file.close()
	print("UNIFIED_GODOT ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size()); quit(0 if errors.is_empty() else 1)
