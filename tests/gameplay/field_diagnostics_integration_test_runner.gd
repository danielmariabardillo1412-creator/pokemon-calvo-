extends SceneTree

const OUT := "res://.godot/field_diagnostics_checks/"
const SAVE_PATH := OUT + "save.json"
const ELEMENTAL := [&"flamethrower", &"thunderbolt", &"ice_beam"]
const EXTERNAL := [&"circle_throw", &"dragon_tail", &"flip_turn", &"u_turn", &"volt_switch"]
const STATUS_SWITCH := [&"roar", &"whirlwind", &"teleport", &"baton_pass", &"parting_shot"]
const WEATHER := [&"rain_dance", &"hail", &"sandstorm", &"snowscape", &"chilly_reception"]
const SUBSTITUTE := [&"substitute", &"shed_tail"]
const TRANSFORM := [&"wailord", &"pikachu", &"charizard"]

var scene: Node2D
var checks := 0
var errors: Array[String] = []
var done := false
var legacy := false


func _initialize() -> void:
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
		"save_path": SAVE_PATH,
		"source_sha256": {
			"field_diagnostics": FileAccess.get_sha256("res://scenes/visual/field_diagnostics.gd"),
			"field_demo": FileAccess.get_sha256("res://scenes/visual/field_demo.gd"),
			"integration_runner": FileAccess.get_sha256("res://tests/gameplay/field_diagnostics_integration_test_runner.gd"),
		},
	}
	var file := FileAccess.open(OUT + ("legacy.json" if legacy else "native.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_DIAGNOSTICS_INTEGRATION ", report.status, " profile=", report.profile, " checks=", checks, " errors=", errors.size())
	if scene != null and is_instance_valid(scene): scene.queue_free()
	quit(0 if errors.is_empty() else 1)


func indices() -> Array:
	return [
		scene._elemental_test_index,
		scene._external_test_index,
		scene._switch_test_index,
		scene._status_switch_index,
		scene._weather_index,
		scene._substitute_index,
		scene._transform_index,
	]


func snapshot() -> Dictionary:
	var active: CreatureInstance = scene._session.player.party.get_active()
	return {
		"session": scene._session,
		"collection": scene._session.player,
		"party": scene._session.player.party,
		"active": active,
		"moves": active.move_ids.duplicate(),
		"config": JSON.stringify(scene._active_config),
		"notice": scene._notice_label.text if scene._notice_label != null else "",
		"recorder": scene._recorder.entry_count(),
		"rng_encounter": scene._director._encounter_rng.state,
		"rng_capture": scene._capture_rng.state,
		"rng_escape": scene._escape_rng.state,
		"indices": indices(),
		"flags": [
			scene._session.live_moves_enabled,
			scene._session.switch_move_rules_enabled,
			scene._session.weather_rules_enabled,
			scene._session.substitute_rules_enabled,
			scene._session.transform_rules_enabled,
		],
		"party_size": scene.demo_party_size(),
		"panel_open": scene.test_panel.is_panel_open(),
		"gallery_visible": scene._pokemon_gallery != null and scene._pokemon_gallery.visible,
		"bag_visible": scene._item_bag != null and scene._item_bag.visible,
		"doubles_visible": scene._doubles_demo != null and scene._doubles_demo.visible,
		"movement": scene.player.movement_enabled,
	}


func expect_unchanged(label: String, before: Dictionary) -> void:
	var after := snapshot()
	for key: String in before:
		check(label + " " + key + " stable", after.get(key) == before.get(key))


func reject(label: String, action: Callable) -> void:
	var before := snapshot()
	check(label + " rejected", not bool(action.call()))
	expect_unchanged(label, before)


func key_event(keycode: int, pressed: bool = true, echo: bool = false, ctrl: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = echo
	event.ctrl_pressed = ctrl
	return event


func push_key(keycode: int, pressed: bool = true, echo: bool = false, ctrl: bool = false) -> void:
	root.gui_release_focus()
	root.push_input(key_event(keycode, pressed, echo, ctrl))
	await process_frame


func repeat(value: Variant, count: int) -> Array:
	var result := []
	for i in count: result.append(value)
	return result


func check_flags(label: String, switch_rules: bool, weather_rules: bool, substitute_rules: bool, transform_rules: bool) -> void:
	check(label + " live moves off", not scene._session.live_moves_enabled)
	check(label + " switch flag", scene._session.switch_move_rules_enabled == switch_rules)
	check(label + " weather flag", scene._session.weather_rules_enabled == weather_rules)
	check(label + " substitute flag", scene._session.substitute_rules_enabled == substitute_rules)
	check(label + " transform flag", scene._session.transform_rules_enabled == transform_rules)


func check_config(label: String, species: Array, wild_species: StringName) -> void:
	var rows: Array = scene._active_config.get("player_team", [])
	var actual: Array = []
	var levels: Array = []
	for row: Dictionary in rows:
		actual.append(StringName(String(row.get("species_id", ""))))
		levels.append(int(row.get("level", 0)))
	check(label + " party species", actual == species)
	check(label + " party levels", levels == repeat(50, species.size()))
	check(label + " real party size", scene.demo_party_size() == species.size())
	check(label + " wild species", StringName(String(scene._active_config.get("wild_species_id", ""))) == wild_species)
	check(label + " wild pool fixed", not bool(scene._active_config.get("wild_random_pool", true)))
	check(label + " wild levels", int(scene._active_config.get("wild_min_level", 0)) == 50 and int(scene._active_config.get("wild_max_level", 0)) == 50)
	check(label + " chance", int(scene._active_config.get("encounter_chance_percent", 0)) == 100)


func visual_event(start: int, event_name: StringName) -> Dictionary:
	var entries: Array = scene._recorder._entries.slice(start)
	for entry: Dictionary in entries:
		if String(entry.get("category", "")) == "visual_test" and String(entry.get("event", "")) == String(event_name):
			return entry
	return {}


func event_count(start: int, event_name: StringName) -> int:
	var total := 0
	for entry: Dictionary in scene._recorder._entries.slice(start):
		if String(entry.get("category", "")) == "visual_test" and String(entry.get("event", "")) == String(event_name):
			total += 1
	return total


func check_visual_event(label: String, start: int, move: StringName, scope: String) -> void:
	var entry := visual_event(start, &"visual_move_preset")
	check(label + " visual_move_preset recorded", not entry.is_empty())
	if entry.is_empty(): return
	var payload: Dictionary = entry.get("payload", {})
	check(label + " temporary move", String(payload.get("temporary_move", "")) == String(move))
	check(label + " mechanics scope", String(payload.get("mechanics_scope", "")) == scope)
	check(label + " reset restores learnset", bool(payload.get("reset_restores_learnset", false)))


func check_specific_event(label: String, start: int, event_name: StringName, payload_key: String, payload_value: String) -> void:
	var entry := visual_event(start, event_name)
	check(label + " " + String(event_name) + " recorded", not entry.is_empty())
	if entry.is_empty(): return
	var payload: Dictionary = entry.get("payload", {})
	check(label + " " + payload_key, String(payload.get(payload_key, "")) == payload_value)


func check_active_moves(label: String, expected: Array) -> void:
	check(label + " active moveset", scene._session.player.party.get_active().move_ids == expected)


func check_initial_catalog() -> void:
	check("diagnostics component present", scene._diagnostics != null and scene._diagnostics is RefCounted and not scene._diagnostics is Node)
	check("elemental alias", scene.ELEMENTAL_TEST_MOVES == ELEMENTAL)
	check("external alias", scene.EXTERNAL_DAMAGE_TEST_MOVES == EXTERNAL)
	check("status switch alias", scene.STATUS_SWITCH_TEST_MOVES == STATUS_SWITCH)
	check("weather alias", scene.WEATHER_TEST_MOVES == WEATHER)
	check("substitute alias", scene.SUBSTITUTE_TEST_MOVES == SUBSTITUTE)
	check("transform alias", scene.TRANSFORM_TEST_SPECIES == TRANSFORM)
	check("seven cursors start at zero", indices() == [0, 0, 0, 0, 0, 0, 0])
	check("elemental getter delegates", scene._elemental_test_index == scene._diagnostics.index_for(&"elemental"))
	check("external getter delegates", scene._external_test_index == scene._diagnostics.index_for(&"external"))
	check("switch getter delegates", scene._switch_test_index == scene._diagnostics.index_for(&"switch"))
	check("status getter delegates", scene._status_switch_index == scene._diagnostics.index_for(&"status_switch"))
	check("weather getter delegates", scene._weather_index == scene._diagnostics.index_for(&"weather"))
	check("substitute getter delegates", scene._substitute_index == scene._diagnostics.index_for(&"substitute"))
	check("transform getter delegates", scene._transform_index == scene._diagnostics.index_for(&"transform"))


func check_rejections() -> void:
	reject("unknown move", func(): return scene.prepare_visual_move_test(&"max_flare"))
	reject("status without switch rules", func(): return scene.prepare_visual_move_test(&"baton_pass"))
	reject("weather without weather rules", func(): return scene.prepare_visual_move_test(&"rain_dance", true))
	reject("substitute without substitute rules", func(): return scene.prepare_visual_move_test(&"substitute", true))
	reject("shed tail without substitute rules", func(): return scene.prepare_visual_move_test(&"shed_tail", true))
	reject("transform without transform rules", func(): return scene.prepare_visual_move_test(&"transform", true, true, true, false))

	scene.test_panel._open_config()
	check("panel open for rejection", scene.test_panel.is_panel_open())
	reject("panel blocks visual preset", func(): return scene.prepare_visual_move_test(&"flamethrower"))
	reject("panel blocks cycle wrapper", func(): return scene.cycle_elemental_visual_test())
	scene.test_panel._close_config()

	scene.toggle_pokemon_gallery()
	check("gallery opens for rejection", scene._pokemon_gallery.visible)
	check("gallery visible for rejection", scene._pokemon_gallery.visible)
	reject("gallery blocks cycle wrapper", func(): return scene.cycle_external_damage_test())
	scene.toggle_pokemon_gallery()
	check("gallery closed after rejection", not scene._pokemon_gallery.visible)
	check("rejections kept cursors", indices() == [0, 0, 0, 0, 0, 0, 0])


func check_input_priorities() -> void:
	var base := indices()
	await push_key(KEY_F5, false)
	check("release does not advance", indices() == base)
	await push_key(KEY_F5, true, true)
	check("echo does not advance", indices() == base)

	await push_key(KEY_F1)
	check("F1 opens config panel", scene.test_panel.is_panel_open())
	if scene.test_panel.is_panel_open():
		await push_key(KEY_F5)
		check("panel keeps diagnostic cursor", indices() == base)
		check("panel F5 still handled", root.is_input_handled())
		check("panel stays open after F5", scene.test_panel.is_panel_open())
		await push_key(KEY_ESCAPE)
		check("Escape closes config panel", not scene.test_panel.is_panel_open())

	await push_key(KEY_F3)
	check("F3 opens gallery", scene._pokemon_gallery.visible)
	if scene._pokemon_gallery.visible:
		await push_key(KEY_F5)
		check("gallery keeps diagnostic cursor", indices() == base)
		check("gallery F5 still handled", root.is_input_handled())
		check("gallery stays open after F5", scene._pokemon_gallery.visible)
		await push_key(KEY_F3)
		check("F3 closes gallery", not scene._pokemon_gallery.visible)

	var overlay: bool = scene._geometry_overlay.visible
	await push_key(KEY_F2)
	check("F2 toggles geometry overlay", scene._geometry_overlay.visible != overlay)
	await push_key(KEY_F2)
	check("F2 toggles geometry overlay back", scene._geometry_overlay.visible == overlay)
	check("F2 keeps diagnostic cursor", indices() == base)

	if scene._native_battles != null:
		await push_key(KEY_B)
		check("B opens item bag", scene._item_bag.visible)
		if scene._item_bag.visible:
			await push_key(KEY_F5)
			check("bag keeps diagnostic cursor", indices() == base)
			check("bag F5 still handled", root.is_input_handled())
			check("bag stays open after F5", scene._item_bag.visible)
			await push_key(KEY_B)
			check("B closes item bag", not scene._item_bag.visible)
	else:
		check("legacy has no native bag/save bridge", legacy and scene._native_battles == null)

	await push_key(KEY_F12)
	var doubles = scene._doubles_demo
	check("F12 opens doubles overlay", doubles != null and doubles.visible)
	if doubles != null and doubles.visible:
		var doubles_indices := indices()
		reject("doubles blocks cycle wrapper", func(): return scene.cycle_weather_test())
		await push_key(KEY_F5)
		check("doubles keeps diagnostic cursor", indices() == doubles_indices)
		check("doubles stays open after F5", doubles.visible)
		await push_key(KEY_F12)
		var frames := 0
		while doubles.visible and frames < 1200:
			await process_frame
			frames += 1
		check("F12 closes doubles overlay", not doubles.visible)
		check("doubles keeps cursors after close", indices() == base)
	check("priorities kept all cursors", indices() == base)


func check_presets() -> void:
	var start: int = scene._recorder.entry_count()
	await push_key(KEY_F4)
	check("F4 handled by viewport", root.is_input_handled())
	check("F4 has no cursor", indices() == [0, 0, 0, 0, 0, 0, 0])
	check_active_moves("F4", [&"tera_blast"])
	check("F4 species", scene._session.player.party.get_active().species_id == &"charizard")
	check_flags("F4", false, false, false, false)
	check_config("F4", [&"charizard"], &"wailord")
	check("F4 notice", scene._notice_label.text.begins_with("ENSAYO TERA NORMAL"))
	check_visual_event("F4", start, &"tera_blast", "existing_rules_only")
	check("F4 single action", event_count(start, &"visual_move_preset") == 1)

	start = scene._recorder.entry_count()
	await push_key(KEY_F5)
	check("F5 handled by viewport", root.is_input_handled())
	check("F5 advances only elemental", indices() == [1, 0, 0, 0, 0, 0, 0])
	check("F5 next request", scene._diagnostics.request_for(&"elemental")["move_id"] == &"thunderbolt")
	check_active_moves("F5", [&"flamethrower"])
	check("F5 species", scene._session.player.party.get_active().species_id == &"charizard")
	check_flags("F5", false, false, false, false)
	check_config("F5", [&"charizard"], &"wailord")
	check("F5 notice", scene._notice_label.text.begins_with("ENSAYO ") and scene._notice_label.text.contains("movimiento temporal"))
	check_visual_event("F5", start, &"flamethrower", "existing_rules_only")
	check("F5 single action", event_count(start, &"visual_move_preset") == 1)

	start = scene._recorder.entry_count()
	await push_key(KEY_F6)
	check("F6 handled by viewport", root.is_input_handled())
	check("F6 advances only external", indices() == [1, 1, 0, 0, 0, 0, 0])
	check_active_moves("F6", [&"circle_throw"])
	check_flags("F6", false, false, false, false)
	check_config("F6", [&"charizard"], &"wailord")
	check("F6 notice", scene._notice_label.text.begins_with("SOLO DAÑO") and scene._notice_label.text.contains("Reiniciar restaura el learnset"))
	check_visual_event("F6", start, &"circle_throw", "damage_only_special_effect_pending")
	check("F6 single action", event_count(start, &"visual_move_preset") == 1)

	start = scene._recorder.entry_count()
	await push_key(KEY_F7)
	check("F7 handled by viewport", root.is_input_handled())
	check("F7 independent switch cursor", indices() == [1, 1, 1, 0, 0, 0, 0])
	check_active_moves("F7", [&"circle_throw"])
	check_flags("F7", true, false, false, false)
	check_config("F7", [&"charizard", &"pikachu", &"blastoise"], &"wailord")
	check("F7 notice", scene._notice_label.text.begins_with("F7 · ") and scene._notice_label.text.contains("SALVAJE"))
	check_visual_event("F7", start, &"circle_throw", "damage_only_special_effect_pending")
	check("F7 single action", event_count(start, &"visual_move_preset") == 1)
	check_specific_event("F7", start, &"switch_move_preset", "move_id", "circle_throw")
	check_specific_event("F7", start, &"switch_move_preset", "mechanics_scope", "singles_switch_moves_v1")

	start = scene._recorder.entry_count()
	await push_key(KEY_F8)
	check("F8 handled by viewport", root.is_input_handled())
	check("F8 advances only status switch", indices() == [1, 1, 1, 1, 0, 0, 0])
	check_active_moves("F8", [&"roar"])
	check_flags("F8", true, false, false, false)
	check_config("F8", [&"charizard", &"pikachu", &"blastoise"], &"wailord")
	check("F8 notice", scene._notice_label.text.begins_with("F8 · "))
	check_visual_event("F8", start, &"roar", "existing_rules_only")
	check("F8 single action", event_count(start, &"visual_move_preset") == 1)
	check_specific_event("F8", start, &"status_switch_preset", "move_id", "roar")

	for i in 3:
		check("F8 additional preset " + str(i), scene.cycle_status_switch_test())
	check("F8 baton pass selected", scene._session.player.party.get_active().move_ids == [&"baton_pass"])
	check("F8 baton pass cursor", indices() == [1, 1, 1, 4, 0, 0, 0])
	check("F8 baton pass attack +2", scene._session.player.party.get_active().stat_stages.get_stage(StatStages.ATTACK) == 2)
	check("F8 baton pass speed +1", scene._session.player.party.get_active().stat_stages.get_stage(StatStages.SPEED) == 1)
	var reset_session = scene._session
	var reset_indices := indices()
	scene.restart_field_run()
	check("reset after baton pass replaced session", scene._session != reset_session)
	check("reset after baton pass keeps cursors", indices() == reset_indices)
	check("reset after baton pass live moves", scene._session.live_moves_enabled)
	check("reset after baton pass flags", not scene._session.switch_move_rules_enabled and not scene._session.weather_rules_enabled and not scene._session.substitute_rules_enabled and not scene._session.transform_rules_enabled)
	check("reset after baton pass clears notice", scene._notice_label.text == "")
	check("reset after baton pass clears stages", scene._session.player.party.get_active().stat_stages.get_stage(StatStages.ATTACK) == 0 and scene._session.player.party.get_active().stat_stages.get_stage(StatStages.SPEED) == 0)

	start = scene._recorder.entry_count()
	await push_key(KEY_F9)
	check("F9 handled by viewport", root.is_input_handled())
	check("F9 advances only weather", indices() == [1, 1, 1, 4, 1, 0, 0])
	check_active_moves("F9", [&"rain_dance", &"water_gun", &"flamethrower", &"tackle"])
	check_flags("F9", true, true, false, false)
	check_config("F9", [&"charizard", &"lapras", &"golem"], &"wailord")
	check("F9 notice", scene._notice_label.text.begins_with("F9 · ") and scene._notice_label.text.contains("Clima persistente"))
	check_visual_event("F9", start, &"rain_dance", "existing_rules_only")
	check("F9 single action", event_count(start, &"visual_move_preset") == 1)
	check_specific_event("F9", start, &"weather_preset", "move_id", "rain_dance")

	reset_session = scene._session
	reset_indices = indices()
	scene.restart_field_run()
	check("reset after weather replaced session", scene._session != reset_session)
	check("reset after weather keeps cursors", indices() == reset_indices)
	check("reset after weather live moves", scene._session.live_moves_enabled)
	check("reset after weather flags", not scene._session.switch_move_rules_enabled and not scene._session.weather_rules_enabled and not scene._session.substitute_rules_enabled and not scene._session.transform_rules_enabled)
	check("reset after weather clears notice", scene._notice_label.text == "")
	check_config("reset after weather keeps config", [&"charizard", &"lapras", &"golem"], &"wailord")

	start = scene._recorder.entry_count()
	await push_key(KEY_F10)
	check("F10 handled by viewport", root.is_input_handled())
	check("F10 advances only substitute", indices() == [1, 1, 1, 4, 1, 1, 0])
	check_active_moves("F10", [&"substitute", &"tackle", &"flamethrower", &"baton_pass"])
	check_flags("F10", true, false, true, false)
	check_config("F10", [&"charizard", &"pikachu", &"blastoise"], &"wailord")
	check("F10 notice", scene._notice_label.text.begins_with("F10 · ") and scene._notice_label.text.contains("Sustituto"))
	check_visual_event("F10", start, &"substitute", "existing_rules_only")
	check("F10 single action", event_count(start, &"visual_move_preset") == 1)
	check_specific_event("F10", start, &"substitute_preset", "move_id", "substitute")

	start = scene._recorder.entry_count()
	await push_key(KEY_F11)
	check("F11 handled by viewport", root.is_input_handled())
	check("F11 advances only transform", indices() == [1, 1, 1, 4, 1, 1, 1])
	check("F11 next transform target", scene._diagnostics.request_for(&"transform")["target_species"] == &"pikachu")
	check_active_moves("F11", [&"transform"])
	check("F11 ditto active", scene._session.player.party.get_active().species_id == &"ditto")
	check_flags("F11", true, true, true, true)
	check_config("F11", [&"ditto", &"lapras", &"golem"], &"wailord")
	var wailord_name: String = SpanishGameText.species_name(&"wailord", scene._catalogs)
	check("F11 notice", scene._notice_label.text.begins_with("F11 · Transformación · Ditto frente a ") and wailord_name in scene._notice_label.text)
	check_visual_event("F11", start, &"transform", "existing_rules_only")
	check("F11 single action", event_count(start, &"visual_move_preset") == 1)
	check_specific_event("F11", start, &"transform_preset", "target_species", "wailord")
	check_specific_event("F11", start, &"transform_preset", "mechanics_scope", "transform_singles_v1")

	reset_session = scene._session
	reset_indices = indices()
	scene.restart_field_run()
	check("reset after transform replaced session", scene._session != reset_session)
	check("reset after transform keeps cursors", indices() == reset_indices)
	check("reset after transform live moves", scene._session.live_moves_enabled)
	check("reset after transform flags", not scene._session.switch_move_rules_enabled and not scene._session.weather_rules_enabled and not scene._session.substitute_rules_enabled and not scene._session.transform_rules_enabled)
	check("reset after transform clears notice", scene._notice_label.text == "")
	check("reset after transform keeps configured party", scene.demo_party_size() == 3)


func normalized_config(config: Dictionary) -> Dictionary:
	var result := {
		"wild_random_pool": bool(config.get("wild_random_pool", false)),
		"wild_species_id": String(config.get("wild_species_id", "")),
		"trainer_profile_id": String(config.get("trainer_profile_id", "")),
		"trainer_expertise_id": String(config.get("trainer_expertise_id", "")),
	}
	for key: String in ["wild_min_level", "wild_max_level", "cave_min_level", "cave_max_level", "encounter_chance_percent"]:
		result[key] = int(config.get(key, 0))
	for team: String in ["player_team", "trainer_team"]:
		var rows: Array = []
		for row: Dictionary in config.get(team, []):
			rows.append({"species_id": String(row.get("species_id", "")), "level": int(row.get("level", 0))})
		result[team] = rows
	return result


func check_save_load() -> void:
	var before_indices := indices()
	if scene._native_battles != null:
		await push_key(KEY_S, true, false, true)
		check("Ctrl+S handled by viewport", root.is_input_handled())
		check("Ctrl+S writes isolated save", FileAccess.file_exists(SAVE_PATH))
		check("Ctrl+S notice", scene._notice_label.text == "Partida guardada.")
		var config_before: Dictionary = scene._active_config.duplicate(true)
		var session_before = scene._session
		await push_key(KEY_L, true, false, true)
		check("Ctrl+L handled by viewport", root.is_input_handled())
		var frames := 0
		while scene._native_battles.busy and frames < 1200:
			await process_frame
			frames += 1
		check("Ctrl+L loads isolated save", not scene._native_battles.busy and scene._notice_label.text == "Partida recuperada.")
		check("Ctrl+L replaces session", scene._session != session_before)
		check("Ctrl+L restores config", normalized_config(scene._active_config) == normalized_config(config_before))
		check("save/load keep cursors", indices() == before_indices)
		check("save path stays isolated", scene._native_battles.save_path == SAVE_PATH)
	else:
		var notice_before: String = scene._notice_label.text
		await push_key(KEY_S, true, false, true)
		check("legacy Ctrl+S stays inert", not FileAccess.file_exists(SAVE_PATH) and scene._notice_label.text == notice_before)
		check("legacy save path unused", scene._native_battles == null)
		check("legacy profile flag", legacy)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	legacy = "--legacy-field" in OS.get_cmdline_user_args()
	var timer := create_timer(300.0)
	timer.timeout.connect(func():
		if not done:
			check("watchdog", false)
			finish())
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame
	check("real field scene ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		finish(); return
	check("profile matches requested backend", legacy == (scene._native_battles == null))
	if scene._native_battles != null:
		scene._native_battles.save_path = SAVE_PATH
		check("native save path isolated", scene._native_battles.save_path == SAVE_PATH and not scene._native_battles.save_path.begins_with("user://"))
	check_initial_catalog()
	check_rejections()
	await check_input_priorities()
	await check_presets()
	await check_save_load()
	finish()
