extends SceneTree

const OUT := "res://.godot/field_bridge_world_checks/"

var scene: Node2D
var checks := 0
var errors: Array[String] = []
var done := false
var legacy := false


func _initialize() -> void:
	legacy = "--legacy-field" in OS.get_cmdline_user_args()
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)


func finish() -> void:
	if done: return
	done = true
	var report := {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"profile": "legacy" if legacy else "native",
		"checks": checks,
		"errors": errors,
		"source_sha256": {
			"field_demo": FileAccess.get_sha256("res://scenes/visual/field_demo.gd"),
			"field_native_bridge": FileAccess.get_sha256("res://scenes/visual/field_native_bridge.gd"),
			"test_runner": FileAccess.get_sha256("res://tests/gameplay/field_bridge_world_test_runner.gd"),
		},
	}
	var file := FileAccess.open(OUT + ("world_legacy.json" if legacy else "world_native.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_BRIDGE_WORLD ", report.status, " profile=", report.profile, " checks=", checks, " errors=", errors.size())
	if scene != null and is_instance_valid(scene): scene.queue_free()
	quit(0 if errors.is_empty() else 1)


func collection_view() -> String:
	var collection: PlayerCollection = scene.field_collection()
	if collection == null:
		return ""
	var party: Array = []
	for creature: CreatureInstance in collection.party.get_creatures():
		party.append(creature.to_dict())
	return JSON.stringify({"party": party, "inventory": collection.inventory.to_dict()})


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
		"invalid": int(encounters.get("invalid", -1)),
		"wild_started": int(battles.get("wild_started", -1)),
		"trainer_started": int(battles.get("trainer_started", -1)),
	}


func state_view() -> Dictionary:
	var clocks: Dictionary = scene._native_battles.clocks if scene._native_battles != null else {}
	return {
		"collection": collection_view(),
		"clocks": JSON.stringify(clocks),
		"rng": scene._director._encounter_rng.state if scene._director != null else -1,
		"seed": scene._director._next_battle_seed if scene._director != null else -1,
		"capture_rng": scene._capture_rng.state if scene._capture_rng != null else -1,
		"escape_rng": scene._escape_rng.state if scene._escape_rng != null else -1,
		"position": [scene.player.global_position.x, scene.player.global_position.y],
		"config": JSON.stringify(scene._active_config),
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


func apply_config(species: String = "pidgey", chance: int = 100, min_level: int = 5, max_level: int = 5) -> void:
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = species
	config.wild_min_level = min_level
	config.wild_max_level = max_level
	config.encounter_chance_percent = chance
	scene._on_configuration_applied(config)


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


func check_preboot() -> void:
	var early: Node2D = load("res://scenes/visual/field_demo.gd").new()
	check("preboot trainer owner null", early.field_trainer_owner() == null)
	check("preboot living party false", not early.field_has_living_party())
	check("preboot overlay false", not early.field_has_world_overlay())
	check("preboot native seed sentinel", early.field_native_seed() == -1)
	check("preboot prepare empty", early.field_prepare_native_encounter(&"technical_grass").is_empty())
	check("preboot step empty", early.field_note_native_step(Vector2.ZERO) == &"")
	check("preboot collection null", early.field_collection() == null)
	check("preboot definitions null", early.field_definitions() == null)
	early.free()


func check_identity_and_queries() -> void:
	var collection: PlayerCollection = scene.field_collection()
	var definitions: DefinitionCatalog = scene.field_definitions()
	var owner: TrainerCampaignRosterOwner = scene.field_trainer_owner()
	check("scene ready", scene.is_demo_ready())
	check("native bridge profile", (scene._native_battles != null) != legacy)
	check("collection is current session player", collection != null and is_same(collection, scene._session.player))
	check("definitions are current catalog", is_same(definitions, scene._catalogs))
	check("trainer owner is current owner", owner != null and is_same(owner, scene._trainer_campaign_owner) and owner.is_ready())
	check("trainer owner is not cached copy", is_same(scene.field_trainer_owner(), owner))
	check("living party true by default", scene.field_has_living_party())
	check("overlay closed by default", not scene.field_has_world_overlay())
	check("native seed follows director", scene.field_native_seed() == scene._director._next_battle_seed)

	var before := state_view()
	for index in 5:
		check("repeat " + str(index) + " owner", scene.field_trainer_owner() == owner)
		check("repeat " + str(index) + " living", scene.field_has_living_party())
		check("repeat " + str(index) + " overlay", not scene.field_has_world_overlay())
		check("repeat " + str(index) + " seed", scene.field_native_seed() == before.seed)
		check("repeat " + str(index) + " collection", is_same(scene.field_collection(), collection))
		check("repeat " + str(index) + " definitions", is_same(scene.field_definitions(), definitions))
	expect_unchanged("pure queries", before)


func check_overlays() -> void:
	scene.test_panel._open_config()
	check("panel is world overlay", scene.field_has_world_overlay())
	scene.test_panel._close_config()
	check("panel close clears overlay", not scene.field_has_world_overlay())

	scene.toggle_pokemon_gallery()
	check("gallery is world overlay", scene.field_has_world_overlay())
	scene.toggle_pokemon_gallery()
	check("gallery close clears overlay", not scene.field_has_world_overlay())

	if scene._native_battles != null:
		check("bag opens on native profile", scene.toggle_item_bag())
		check("bag is world overlay", scene.field_has_world_overlay())
		scene.toggle_item_bag()
	else:
		scene._item_bag.show()
		check("bag visibility is world overlay", scene.field_has_world_overlay())
		scene._item_bag.hide()
	check("bag close clears overlay", not scene.field_has_world_overlay())

	var doubles := Control.new()
	scene._doubles_demo = doubles
	check("doubles is world overlay", scene.field_has_world_overlay())
	scene._doubles_demo = null
	doubles.free()
	check("doubles close clears overlay", not scene.field_has_world_overlay())


func check_step_and_empty_cases() -> void:
	var before := state_view()
	var zone: StringName = scene.field_note_native_step(Vector2(96, 180))
	var after := state_view()
	check("outside zone returns empty", zone == &"")
	check("step notes exactly once", int(JSON.parse_string(after.metrics).steps) == int(JSON.parse_string(before.metrics).steps) + 1)
	check("step records exactly once", int(after.records) == int(before.records) + 1)
	check("step record category", last_entry().get("category") == "overworld")
	check("step record event", last_entry().get("event") == "step_completed")
	var step_payload: Dictionary = last_entry().get("payload", {})
	check("step record payload x", step_payload.get("x") == 96.0)
	check("step record payload y", step_payload.get("y") == 180.0)
	check("step record payload zone", step_payload.get("zone_id") == "")
	check("step record payload backend", step_payload.get("backend") == "native")
	check("step leaves RNG", after.rng == before.rng)
	check("step leaves seed", after.seed == before.seed)
	check("step leaves collection", after.collection == before.collection)
	check("step leaves clocks", after.clocks == before.clocks)

	before = state_view()
	var empty: Dictionary = scene.field_prepare_native_encounter(&"")
	check("empty zone returns empty", empty.is_empty())
	expect_unchanged("empty zone", before)
	var unknown: Dictionary = scene.field_prepare_native_encounter(&"missing_zone")
	check("unknown zone returns empty", unknown.is_empty())
	expect_unchanged("unknown zone", before)

	for creature: CreatureInstance in scene.field_collection().party.get_creatures():
		creature.current_hp = 0
	check("fainted party reported empty", not scene.field_has_living_party())
	before = state_view()
	var fainted: Dictionary = scene.field_prepare_native_encounter(&"technical_grass")
	check("fainted party prepare empty", fainted.is_empty())
	expect_unchanged("fainted party", before)
	apply_config()
	check("fixture reset living party", scene.field_has_living_party())


func check_none_publication() -> void:
	apply_config("pidgey", 5)
	check("chance fixture applied", scene.is_demo_ready())
	var miss := find_miss_state(&"technical_grass")
	check("deterministic miss fixture found", not miss.is_empty())
	if miss.is_empty():
		return
	scene._director._encounter_rng.state = int(miss.state)
	var pre_state: int = scene._director._encounter_rng.state
	var reference := reference_resolve(&"technical_grass")
	var reference_result := reference.result as WildEncounterResult
	check("reference miss is NONE", reference_result.status == WildEncounterResult.NONE and reference_result.reason == "chance_miss")
	check("reference miss consumes rng", int(reference.next_rng) != pre_state)
	var before := state_view()
	var metrics_before := metrics_view()
	var prepared: Dictionary = scene.field_prepare_native_encounter(&"technical_grass")
	var result := prepared.get("result") as WildEncounterResult
	var after := state_view()
	var metrics_after := metrics_view()
	check("none prepared keys", prepared.size() == 2 and prepared.has("result") and prepared.has("next_rng"))
	check("none status", result != null and result.status == WildEncounterResult.NONE)
	check("none reason", result != null and result.reason == "chance_miss")
	check("none next rng matches reference", int(prepared.get("next_rng", -1)) == int(reference.next_rng))
	check("none publishes staged rng", scene._director._encounter_rng.state == int(reference.next_rng))
	check("none leaves seed", after.seed == before.seed)
	check("none leaves collection", after.collection == before.collection)
	check("none leaves clocks", after.clocks == before.clocks)
	check("none leaves recorder", after.records == before.records)
	check("none notes roll once", int(metrics_after.rolls) == int(metrics_before.rolls) + 1)
	check("none notes miss once", int(metrics_after.misses) == int(metrics_before.misses) + 1)
	check("none notes no encounter", int(metrics_after.encounters) == int(metrics_before.encounters))
	check("none notes no invalid", int(metrics_after.invalid) == int(metrics_before.invalid))


func check_encounter_candidate() -> void:
	apply_config("pidgey", 100)
	var before := state_view()
	var metrics_before := metrics_view()
	var reference := reference_resolve(&"technical_grass")
	var reference_result := reference.result as WildEncounterResult
	check("reference encounter is ENCOUNTER", reference_result.status == WildEncounterResult.ENCOUNTER)
	check("reference encounter is candidate", reference_result.creature != null)
	var prepared: Dictionary = scene.field_prepare_native_encounter(&"technical_grass")
	var result := prepared.get("result") as WildEncounterResult
	var after := state_view()
	var metrics_after := metrics_view()
	check("encounter prepared keys", prepared.size() == 2 and prepared.has("result") and prepared.has("next_rng"))
	check("encounter status", result != null and result.status == WildEncounterResult.ENCOUNTER)
	check("encounter zone", result != null and result.zone_id == &"technical_grass")
	check("encounter species", result != null and result.species_id == &"pidgey")
	check("encounter level", result != null and result.level == 5)
	check("encounter creature candidate", result != null and result.creature != null)
	check("encounter rng matches reference", int(prepared.get("next_rng", -1)) == int(reference.next_rng))
	check("encounter creature matches reference", result != null and result.creature.to_dict() == reference_result.creature.to_dict())
	check("encounter does not publish rng", scene._director._encounter_rng.state == before.rng)
	check("encounter next rng advances", int(prepared.get("next_rng", -1)) != before.rng)
	check("encounter leaves seed", after.seed == before.seed)
	check("encounter leaves collection", after.collection == before.collection)
	check("encounter leaves clocks", after.clocks == before.clocks)
	check("encounter leaves recorder", after.records == before.records)
	check("encounter candidate is not owned", scene.field_collection().owned_creature(result.creature.instance_id) == null)
	check("encounter notes roll once", int(metrics_after.rolls) == int(metrics_before.rolls) + 1)
	check("encounter notes encounter once", int(metrics_after.encounters) == int(metrics_before.encounters) + 1)
	check("encounter notes no miss", int(metrics_after.misses) == int(metrics_before.misses))
	check("encounter notes no invalid", int(metrics_after.invalid) == int(metrics_before.invalid))

	var seed_before: int = scene.field_native_seed()
	var commit_before := state_view()
	var commit_metrics := metrics_view()
	scene.field_commit_native_battle_start(int(prepared.next_rng), &"wild", "gen9customgame")
	var commit_after := state_view()
	var commit_metrics_after := metrics_view()
	check("commit publishes prepared rng", scene._director._encounter_rng.state == int(prepared.next_rng))
	check("commit increments seed once", scene.field_native_seed() == seed_before + 1)
	check("commit leaves collection", commit_after.collection == commit_before.collection)
	check("commit leaves clocks", commit_after.clocks == commit_before.clocks)
	check("commit leaves capture rng", commit_after.capture_rng == commit_before.capture_rng)
	check("commit records once", int(commit_after.records) == int(commit_before.records) + 1)
	check("commit record category", last_entry().get("category") == "wild")
	check("commit record event", last_entry().get("event") == "battle_started")
	check("commit record payload", last_entry().get("payload") == {"backend": "native", "format": "gen9customgame", "seed": seed_before})
	check("commit notes battle once", int(commit_metrics_after.wild_started) == int(commit_metrics.wild_started) + 1)
	check("commit notes no trainer battle", int(commit_metrics_after.trainer_started) == int(commit_metrics.trainer_started))
	apply_config("pidgey", 100)
	check("commit fixture reset", scene.field_native_seed() == 12003)


func check_force_shiny() -> void:
	apply_config("pidgey__shiny", 100)
	check("shiny fixture applied", scene.is_demo_ready() and scene._session.force_shiny_encounters)
	var reference := reference_resolve(&"technical_grass")
	var prepared: Dictionary = scene.field_prepare_native_encounter(&"technical_grass")
	var result := prepared.get("result") as WildEncounterResult
	check("force shiny candidate", result != null and result.creature != null and result.creature.is_shiny)
	check("force shiny keeps species", result != null and result.creature.species_id == &"pidgey")
	check("force shiny rng order", int(prepared.get("next_rng", -1)) == int(reference.next_rng))
	apply_config()
	check("shiny fixture reset", not scene._session.force_shiny_encounters)


func check_world_effects() -> void:
	var dummy := Control.new()
	scene.field_attach_battle_view(dummy)
	check("view attached to CanvasLayer", dummy.get_parent() == scene.get_node("CanvasLayer"))
	check("view attached at end", scene.get_node("CanvasLayer").get_child(scene.get_node("CanvasLayer").get_child_count() - 1) == dummy)
	dummy.get_parent().remove_child(dummy)
	dummy.free()

	scene.player.movement_enabled = true
	scene.player.velocity = Vector2(7, 9)
	scene.field_lock_battle_world()
	check("lock disables movement", not scene.player.movement_enabled)
	check("lock clears velocity", scene.player.velocity == Vector2.ZERO)

	var shown := Control.new()
	scene._hud.show()
	scene.field_show_battle_view(shown)
	check("show resizes window", scene.get_window().content_scale_size == Vector2i(1280, 720))
	check("show displays view", shown.visible)
	check("show hides hud", not scene._hud.visible)
	shown.free()

	scene._hud.show()
	scene.player.movement_enabled = false
	scene.player._distance_since_step = 9.0
	scene.test_panel._open_config()
	scene.field_unlock_battle_world()
	check("unlock restores window", scene.get_window().content_scale_size == Vector2i(960, 540))
	check("unlock resets step meter", scene.player._distance_since_step == 0.0)
	check("unlock respects open panel", not scene.player.movement_enabled)
	scene.test_panel._close_config()
	scene.field_unlock_battle_world()
	check("unlock restores movement", scene.player.movement_enabled)

	var before := state_view()
	scene.field_record_native_battle_closed("CAPTURED")
	var after := state_view()
	check("closed record once", int(after.records) == int(before.records) + 1)
	check("closed record category", last_entry().get("category") == "native")
	check("closed record event", last_entry().get("event") == "battle_closed")
	check("closed record payload", last_entry().get("payload") == {"reason": "CAPTURED"})
	check("closed leaves rng", after.rng == before.rng)
	check("closed leaves seed", after.seed == before.seed)


func check_diagnostic_forwarding() -> void:
	var before := state_view()
	var wild_entry := {"event": "bridge_probe", "kind": "contract"}
	scene.field_forward_battle_diagnostic("wild", wild_entry)
	check("wild diagnostic records once", int(state_view().records) == int(before.records) + 1)
	check("wild diagnostic category", last_entry().get("category") == "wild_ui")
	check("wild diagnostic event", last_entry().get("event") == "bridge_probe")
	check("wild diagnostic payload keeps entry", last_entry().get("payload") == wild_entry)

	var trainer_entry := {"event": "turn_resolved", "last_error": ""}
	before = state_view()
	scene.field_forward_battle_diagnostic("trainer", trainer_entry)
	check("trainer diagnostic records once", int(state_view().records) == int(before.records) + 1)
	check("trainer diagnostic category", last_entry().get("category") == "trainer_ui")
	check("trainer diagnostic event", last_entry().get("event") == "turn_resolved")
	check("trainer diagnostic payload keeps entry", last_entry().get("payload") == trainer_entry)


func check_bridge_notify() -> void:
	if scene._native_battles == null:
		check("legacy profile has no bridge notify", true)
		return
	var bridge: Node = scene._native_battles
	var view: Control = bridge.view
	var notice_before: String = scene._notice_label.text
	var records_before: int = scene._recorder.entry_count()
	view.hide()
	bridge.notify("Aviso de campo")
	check("field notify updates notice", scene._notice_label.text == "Aviso de campo")
	check("field notify updates last error", bridge.last_error == "Aviso de campo")
	check("field notify leaves records", scene._recorder.entry_count() == records_before)
	check("field notify leaves hidden log", not view._event_log.get_parsed_text().contains("Aviso de campo"))
	view.show()
	bridge.notify("Aviso de combate")
	check("battle notify updates notice", scene._notice_label.text == "Aviso de combate")
	check("battle notify appends once", view._event_log.get_parsed_text().count("Aviso de combate") == 1)
	check("battle notify leaves records", scene._recorder.entry_count() == records_before)
	view.hide()
	scene._notice_label.text = notice_before


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(180).timeout.connect(func():
		if not done:
			check("watchdog", false); finish())
	check_preboot()
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check_identity_and_queries()
	check_overlays()
	check_step_and_empty_cases()
	check_none_publication()
	check_encounter_candidate()
	check_force_shiny()
	check_world_effects()
	check_diagnostic_forwarding()
	check_bridge_notify()
	scene.queue_free()
	await process_frame
	finish()

