extends SceneTree

const OUT := "res://.godot/field_bridge_checks/"
const SAVE_PATH := OUT + "runtime_save.json"

var scene: Node2D
var bridge: Node
var view: Control
var checks := 0
var errors: Array[String] = []
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)
		if bridge != null: printerr(bridge.last_error)


func finish() -> void:
	if done: return
	done = true
	if view != null and view.session != null: view.session.stop_now()
	var report := {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"profile": "native",
		"checks": checks,
		"errors": errors,
		"source_sha256": {
			"field_demo": FileAccess.get_sha256("res://scenes/visual/field_demo.gd"),
			"field_native_bridge": FileAccess.get_sha256("res://scenes/visual/field_native_bridge.gd"),
			"test_runner": FileAccess.get_sha256("res://tests/gameplay/field_bridge_runtime_test_runner.gd"),
		},
	}
	var file := FileAccess.open(OUT + "runtime.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_BRIDGE_RUNTIME ", report.status, " checks=", checks, " errors=", errors.size())
	if scene != null and is_instance_valid(scene): scene.queue_free()
	quit(0 if errors.is_empty() else 1)


func mon(id: String, species: String, level: int, moves: Array) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var creature := CreatureFactory.create(scene._catalogs.species(StringName(species)), level, scene._catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	if creature != null: creature.ability_id = &""
	return creature


func metrics_view() -> Dictionary:
	var current: Dictionary = scene.technical_audit_summary().get("current_run", {})
	var overworld: Dictionary = current.get("overworld", {})
	var encounters: Dictionary = current.get("encounters", {})
	var battles: Dictionary = current.get("battles", {})
	return {
		"steps": int(overworld.get("steps_total", -1)),
		"rolls": int(encounters.get("rolls", -1)),
		"encounters": int(encounters.get("encounters", -1)),
		"misses": int(encounters.get("misses", -1)),
		"wild_started": int(battles.get("wild_started", -1)),
		"trainer_started": int(battles.get("trainer_started", -1)),
	}


func collection_view() -> String:
	var collection: PlayerCollection = scene.field_collection()
	if collection == null:
		return ""
	var party: Array = []
	for creature: CreatureInstance in collection.party.get_creatures():
		party.append(creature.to_dict())
	return JSON.stringify({"party": party, "inventory": collection.inventory.to_dict()})


func state_view() -> Dictionary:
	return {
		"collection": collection_view(),
		"clocks": JSON.stringify(bridge.clocks),
		"rng": scene._director._encounter_rng.state,
		"seed": scene._director._next_battle_seed,
		"records": scene._recorder.entry_count(),
		"metrics": JSON.stringify(metrics_view()),
	}


func expect_unchanged(label: String, before: Dictionary) -> void:
	var after := state_view()
	for key: String in before:
		check(label + " " + key + " stable", after.get(key) == before.get(key))


func last_entry() -> Dictionary:
	var entries: Array = scene._recorder._entries
	return entries.back() as Dictionary if not entries.is_empty() else {}


func entries(category: String, event_name: String) -> Array:
	var out: Array = []
	for entry: Dictionary in scene._recorder._entries:
		if String(entry.get("category")) == category and String(entry.get("event")) == event_name:
			out.append(entry)
	return out


func configure_world(species: String = "pidgey", chance: int = 100, min_level: int = 5, max_level: int = 5) -> void:
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = species
	config.wild_min_level = min_level
	config.wild_max_level = max_level
	config.encounter_chance_percent = chance
	scene._on_configuration_applied(config)


func setup_party(moves: Array = ["flamethrower"], species: String = "mew", level: int = 40) -> void:
	if view.session != null:
		view._playback.cancel()
		await view.session.close()
	view.hide(); bridge.busy = false; bridge.kind = ""; bridge.clocks.clear()
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "pidgey"; config.wild_min_level = 5; config.wild_max_level = 5; config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	scene.field_collection().party = CreatureParty.new()
	scene.field_collection().party.add_creature(mon("own", species, level, moves))
	scene.field_collection().party.add_creature(mon("reserve", "mew", 50, ["flamethrower", "tackle"]))
	scene.player.global_position = Vector2(420, 150)
	bridge._unlock_world()
	await physics_frame


func drain() -> void:
	var count := 0
	while view._playback.is_playing() and count < 2000:
		view._playback.advance(0.25); count += 1
	await process_frame; await process_frame
	view._refresh_view()
	check("native timeline completes", not view._playback.is_playing())


func reference_resolve(zone: StringName) -> Dictionary:
	var staged := RandomNumberGenerator.new()
	staged.state = scene._director._encounter_rng.state
	var table := scene._director._tables[zone] as WildEncounterTable
	var result := WildEncounterSystem.resolve(table, staged, scene._catalogs, scene._session.progression_ruleset)
	return {"result": result, "next_rng": staged.state}


func find_miss_state(zone: StringName) -> Dictionary:
	var probe := RandomNumberGenerator.new()
	var table := scene._director._tables[zone] as WildEncounterTable
	for seed_value in range(1, 20000):
		probe.seed = seed_value
		var initial := probe.state
		var staged := RandomNumberGenerator.new()
		staged.state = initial
		var result := WildEncounterSystem.resolve(table, staged, scene._catalogs, scene._session.progression_ruleset)
		if result.status == WildEncounterResult.NONE:
			return {"state": initial, "next": staged.state}
	return {}


func check_boot(clocks_ref: Dictionary) -> void:
	var collection: PlayerCollection = scene.field_collection()
	check("scene ready", scene.is_demo_ready())
	check("native bridge exists", bridge != null and bridge == scene._native_battles)
	check("native view exists", view != null and view.visible == false)
	check("view parent is CanvasLayer", view.get_parent() == scene.get_node("CanvasLayer"))
	check("view catalogs are current", is_same(view.catalogs, scene.field_definitions()))
	check("view owner bridge", view.owner_bridge == bridge)
	check("bridge field current", bridge.field == scene)
	check("collection current", collection != null and is_same(collection, scene._session.player))
	check("definitions current", is_same(scene.field_definitions(), scene._catalogs))
	check("trainer owner current", is_same(scene.field_trainer_owner(), scene._trainer_campaign_owner) and scene.field_trainer_owner().is_ready())
	check("legacy wild session idle", scene._session != null and not scene._session.has_active_battle())
	check("legacy trainer session idle", scene._trainer_session != null and not scene._trainer_session.has_active_battle())
	check("presence is idle", not bridge.occupied() and not scene.has_active_demo_battle() and not scene.has_active_demo_trainer_battle())
	check("clocks identity at boot", is_same(bridge.clocks, clocks_ref) and clocks_ref.is_empty())
	check("window idle size", scene.get_window().content_scale_size == Vector2i(960, 540))
	check("save path local", bridge.save_path == SAVE_PATH)


func check_notify_field() -> void:
	var notice_before: String = scene._notice_label.text
	var records_before: int = scene._recorder.entry_count()
	bridge.notify("Aviso de campo")
	check("field notify notice", scene._notice_label.text == "Aviso de campo")
	check("field notify last error", bridge.last_error == "Aviso de campo")
	check("field notify no log while hidden", not view._event_log.get_parsed_text().contains("Aviso de campo"))
	check("field notify no record", scene._recorder.entry_count() == records_before)
	scene._notice_label.text = notice_before


func check_outside_zone() -> void:
	var before := state_view()
	var metrics_before := metrics_view()
	await scene._on_player_step_completed(Vector2(96, 180))
	var after := state_view()
	var metrics_after := metrics_view()
	check("outside step leaves rng and seed", after.rng == before.rng and after.seed == before.seed)
	check("outside step notes one step", int(metrics_after.steps) == int(metrics_before.steps) + 1)
	check("outside step notes no roll", int(metrics_after.rolls) == int(metrics_before.rolls))
	check("outside step records once", int(after.records) == int(before.records) + 1)
	check("outside step record payload", String(last_entry().get("event")) == "step_completed" and last_entry().get("payload", {}).get("backend") == "native")
	check("outside step stays idle", not bridge.occupied())


func check_overlays() -> void:
	scene.test_panel._open_config()
	var before := state_view()
	await scene._on_player_step_completed(Vector2(420, 150))
	expect_unchanged("panel step", before)
	scene.test_panel._close_config()

	scene.toggle_pokemon_gallery()
	before = state_view()
	await scene._on_player_step_completed(Vector2(420, 150))
	expect_unchanged("gallery step", before)
	scene.toggle_pokemon_gallery()

	check("bag opens for overlay fixture", scene.toggle_item_bag())
	before = state_view()
	await scene._on_player_step_completed(Vector2(420, 150))
	expect_unchanged("bag step", before)
	scene.toggle_item_bag()
	bridge._unlock_world()


func check_no_living() -> void:
	configure_world()
	for creature: CreatureInstance in scene.field_collection().party.get_creatures():
		creature.current_hp = 0
	var before := state_view()
	var metrics_before := metrics_view()
	await scene._on_player_step_completed(Vector2(420, 150))
	var after := state_view()
	var metrics_after := metrics_view()
	check("no living leaves rng and seed", after.rng == before.rng and after.seed == before.seed)
	check("no living notes one step", int(metrics_after.steps) == int(metrics_before.steps) + 1)
	check("no living notes no roll", int(metrics_after.rolls) == int(metrics_before.rolls))
	check("no living records one step", int(after.records) == int(before.records) + 1)
	check("no living record payload", String(last_entry().get("event")) == "step_completed")
	check("no living stays idle", not bridge.occupied())
	configure_world()
	check("no living fixture reset", scene.field_has_living_party())


func check_none_attempt() -> void:
	configure_world("pidgey", 5)
	var miss := find_miss_state(&"technical_grass")
	check("none miss fixture", not miss.is_empty())
	if miss.is_empty(): return
	scene._director._encounter_rng.state = int(miss.state)
	var before := state_view()
	var metrics_before := metrics_view()
	var reference := reference_resolve(&"technical_grass")
	var reference_result := reference.result as WildEncounterResult
	check("none reference misses", reference_result.status == WildEncounterResult.NONE)
	await scene._on_player_step_completed(Vector2(420, 150))
	var after := state_view()
	var metrics_after := metrics_view()
	check("none publishes reference rng", after.rng == int(reference.next_rng))
	check("none leaves seed", after.seed == before.seed)
	check("none notes one step and one roll", int(metrics_after.steps) == int(metrics_before.steps) + 1 and int(metrics_after.rolls) == int(metrics_before.rolls) + 1)
	check("none notes miss once", int(metrics_after.misses) == int(metrics_before.misses) + 1)
	check("none notes no encounter", int(metrics_after.encounters) == int(metrics_before.encounters))
	check("none records one step", int(after.records) == int(before.records) + 1)
	check("none last record is step", String(last_entry().get("event")) == "step_completed")
	check("none starts no battle", not bridge.occupied() and not scene.has_active_demo_battle())
	check("none starts no battle record", entries("wild", "battle_started").is_empty())


func check_candidate_timing() -> void:
	configure_world()
	var before := state_view()
	var reference := reference_resolve(&"technical_grass")
	var prepared: Dictionary = scene.field_prepare_native_encounter(&"technical_grass")
	var result := prepared.get("result") as WildEncounterResult
	check("candidate is encounter", result != null and result.status == WildEncounterResult.ENCOUNTER)
	check("candidate stays unpublished", scene._director._encounter_rng.state == before.rng)
	check("candidate matches reference rng", int(prepared.get("next_rng", -1)) == int(reference.next_rng))
	check("candidate leaves seed", scene.field_native_seed() == before.seed)
	check("candidate is not owned", scene.field_collection().owned_creature(result.creature.instance_id) == null)
	configure_world()


func check_wild_battle(clocks_ref: Dictionary) -> void:
	configure_world()
	check("wild fixture living", scene.field_has_living_party())
	var before := state_view()
	var metrics_before := metrics_view()
	var reference := reference_resolve(&"technical_grass")
	var reference_result := reference.result as WildEncounterResult
	await scene._on_player_step_completed(Vector2(420, 150))
	var after := state_view()
	var metrics_after := metrics_view()
	check("wild battle occupied", bridge.occupied() and bridge.kind == "wild" and view.visible)
	check("wild session is native authority", view.session != null and view.session.has_active_battle() and view.session.battle_kind == "wild")
	check("legacy wild session stays idle", not scene._session.has_active_battle())
	check("legacy trainer session stays idle", not scene._trainer_session.has_active_battle())
	check("wild presentation parent", view.get_parent() == scene.get_node("CanvasLayer"))
	check("wild window size", scene.get_window().content_scale_size == Vector2i(1280, 720))
	check("wild hud hidden", not scene._hud.visible)
	check("wild world locked", not scene.player.movement_enabled)
	check("wild clocks identity", is_same(bridge.clocks, clocks_ref))
	check("wild catalogs current", is_same(view.catalogs, scene.field_definitions()))
	check("wild rng published after begin", after.rng == int(reference.next_rng))
	check("wild seed advances once", after.seed == before.seed + 1)
	check("wild notes one encounter", int(metrics_after.encounters) == int(metrics_before.encounters) + 1)
	check("wild notes one battle", int(metrics_after.wild_started) == int(metrics_before.wild_started) + 1)
	check("wild uses candidate", view.session.battle_state().active_for_side(&"side_b").instance_id == reference_result.creature.instance_id)
	var started := entries("wild", "battle_started")
	check("wild battle record once", started.size() == 1)
	check("wild battle record payload", started.size() == 1 and started[0].get("payload") == {"backend": "native", "format": "gen9calvounifiedv1", "seed": before.seed})
	check("wild opened diagnostic", entries("wild_ui", "battle_opened").size() == 1)
	view._playback.set_process(false)

	var records_before_notify: int = scene._recorder.entry_count()
	bridge.notify("Aviso de combate")
	check("battle notify notice", scene._notice_label.text == "Aviso de combate")
	check("battle notify log once", view._event_log.get_parsed_text().count("Aviso de combate") == 1)
	check("battle notify no record", scene._recorder.entry_count() == records_before_notify)

	var party_before: int = scene.demo_party_size()
	var balls_before: int = scene.demo_inventory_quantity(&"master_ball")
	var captured: Dictionary = await view.adventure_command("master")
	check("wild capture accepted", bool(captured.get("accepted", false)))
	await drain()
	check("wild capture settled", view.session.completion_reason == "CAPTURED")
	check("wild capture routed once", scene.demo_party_size() == party_before + 1)
	check("wild capture spent ball", scene.demo_inventory_quantity(&"master_ball") == balls_before - 1)
	check("wild settlement keeps clocks", is_same(bridge.clocks, clocks_ref))
	check("wild settlement keeps legacy idle", not scene._session.has_active_battle() and not scene._trainer_session.has_active_battle())
	var started_after_capture := entries("wild", "battle_started").size()
	check("wild capture does not duplicate start", started_after_capture == 1)
	await bridge.leave_battle()
	check("wild close releases view", not view.visible and not bridge.occupied() and bridge.kind == "")
	check("wild close unlocks world", scene.player.movement_enabled)
	check("wild close restores window", scene.get_window().content_scale_size == Vector2i(960, 540))
	check("wild close notice", scene._notice_label.text == "Pokémon capturado.")
	var closed := entries("native", "battle_closed")
	check("wild close records once", closed.size() == 1)
	check("wild close payload", closed.size() == 1 and closed[0].get("payload") == {"reason": "CAPTURED"})
	check("wild close keeps start once", entries("wild", "battle_started").size() == 1)
	await process_frame
	await process_frame
	check("wild close restores hud", scene._hud.visible)


func check_failed_begin(clocks_ref: Dictionary) -> void:
	await setup_party()
	var before := state_view()
	var metrics_before := metrics_view()
	var seed_before: int = scene.field_native_seed()
	var rng_before: int = scene._director._encounter_rng.state
	var starts_before := entries("wild", "battle_started").size()
	bridge.busy = true; bridge.kind = "wild"; bridge._lock_world()
	await bridge._open(null, 987654)
	check("failed begin reports session error", view.session != null and view.session.last_error == "no_available_creature")
	check("failed begin notices unchanged", bridge.last_error == "No se pudo iniciar el combate: no_available_creature")
	check("failed begin releases flags", not bridge.busy and bridge.kind == "" and not bridge.occupied())
	check("failed begin hides view", not view.visible)
	check("failed begin unlocks world", scene.player.movement_enabled and scene.get_window().content_scale_size == Vector2i(960, 540))
	check("failed begin leaves rng", scene._director._encounter_rng.state == rng_before)
	check("failed begin leaves seed", scene.field_native_seed() == seed_before)
	check("failed begin leaves collection", state_view().collection == before.collection)
	check("failed begin leaves clocks", is_same(bridge.clocks, clocks_ref))
	check("failed begin leaves metrics", state_view().metrics == before.metrics)
	check("failed begin records no start", entries("wild", "battle_started").size() == starts_before)
	check("failed begin records nothing", scene._recorder.entry_count() == before.records)


func check_trainer_battle(clocks_ref: Dictionary) -> void:
	await setup_party(["flamethrower"])
	var opponent := mon("bridge_trainer", "caterpie", 5, ["tackle"])
	var owner: TrainerCampaignRosterOwner = scene.field_trainer_owner()
	check("trainer owner fixture", owner.configure(scene.TECHNICAL_TRAINER_ID, [opponent] as Array[CreatureInstance]))
	var before := state_view()
	var metrics_before := metrics_view()
	var seed_before: int = scene.field_native_seed()
	var rng_before: int = scene._director._encounter_rng.state
	check("trainer starts", scene.start_demo_trainer_battle())
	while bridge.busy: await process_frame
	await process_frame
	check("trainer uses native session", view.session != null and view.session.has_active_battle() and view.session.battle_kind == "trainer")
	check("trainer owner current", is_same(scene.field_trainer_owner(), owner))
	check("trainer legacy sessions idle", not scene._session.has_active_battle() and not scene._trainer_session.has_active_battle())
	check("trainer rng untouched", scene._director._encounter_rng.state == rng_before)
	check("trainer seed advances once", scene.field_native_seed() == seed_before + 1)
	check("trainer notes one battle", int(metrics_view().trainer_started) == int(metrics_before.trainer_started) + 1)
	var started := entries("trainer", "battle_started")
	check("trainer battle record once", started.size() == 1)
	check("trainer battle payload", started.size() == 1 and started[0].get("payload") == {"backend": "native", "format": "gen9calvounifiedv1", "seed": seed_before})
	check("trainer clocks identity", is_same(bridge.clocks, clocks_ref))
	view._playback.set_process(false)
	var player_move: Dictionary = await view.choose("move 1")
	check("trainer move accepted", bool(player_move.get("accepted", false)))
	await drain()
	check("trainer victory", view.session.completion_reason == "VICTORY")
	check("trainer roster keeps identity", is_same(owner.owned_creature(&"bridge_trainer"), opponent))
	check("trainer roster settlement", opponent.current_hp == 0)
	var closed_before := entries("native", "battle_closed").size()
	await bridge.leave_battle()
	check("trainer close releases view", not view.visible and not bridge.occupied())
	check("trainer close notice", scene._notice_label.text == "¡Victoria!")
	check("trainer close unlocks", scene.player.movement_enabled)
	var closed := entries("native", "battle_closed")
	check("trainer close records once", closed.size() == closed_before + 1)
	check("trainer close records victory", closed.size() == closed_before + 1 and last_entry().get("payload") == {"reason": "VICTORY"})
	check("trainer start remains once", entries("trainer", "battle_started").size() == 1)
	check("defeated trainer cannot restart", not scene.start_demo_trainer_battle())
	check("trainer close keeps clocks", is_same(bridge.clocks, clocks_ref))
	check("trainer close keeps collection", scene.field_collection() != null and is_same(scene.field_collection(), scene._session.player))
	check("trainer close permits T005 items", scene.field_can_use_items())
	check("T005 bag opens after battles", scene.toggle_item_bag())
	check("T005 bag service current", scene.field_item_service_is_current(scene._item_bag.service))
	scene.toggle_item_bag()
	bridge._unlock_world()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(300).timeout.connect(func():
		if not done:
			check("watchdog", false); finish())
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE_PATH
	var clocks_ref: Dictionary = bridge.clocks
	check_boot(clocks_ref)
	check_notify_field()
	await check_outside_zone()
	await check_overlays()
	await check_no_living()
	await check_none_attempt()
	await check_candidate_timing()
	await check_wild_battle(clocks_ref)
	await check_failed_begin(clocks_ref)
	await check_trainer_battle(clocks_ref)
	await setup_party()
	if view.session != null: await view.session.close()
	scene.queue_free()
	await process_frame
	finish()
