extends SceneTree

const OUT := "res://.godot/field_hud_render_checks/"
const EXPECTED_KEYS := [
	"region_id", "cave_title_min_level", "cave_title_max_level",
	"encounters_enabled", "encounter_percent", "mean_steps",
	"mean_walking_seconds", "rolls", "encounters", "captures",
	"grass_walking_seconds", "party_size", "poke_balls", "species_label",
	"min_level", "max_level",
]

var checks := 0
var errors: Array[String] = []
var fired: Dictionary = {}
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)


func _record(action: String) -> void:
	fired[action] = int(fired[action]) + 1


func _button_count(node: Node) -> int:
	var total := 1 if node is Button else 0
	for child: Node in node.get_children(): total += _button_count(child)
	return total


func fixture(overrides: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"region_id": "surface",
		"cave_title_min_level": 8,
		"cave_title_max_level": 12,
		"encounters_enabled": false,
		"encounter_percent": 0,
		"mean_steps": 0.0,
		"mean_walking_seconds": 0.0,
		"rolls": 0,
		"encounters": 0,
		"captures": 0,
		"grass_walking_seconds": 0.0,
		"party_size": 1,
		"poke_balls": 5,
		"species_label": "Pool aleatorio",
		"min_level": 4,
		"max_level": 6,
	}
	for key in overrides:
		snapshot[key] = overrides[key]
	return snapshot


func _expect_texts(hud, prefix: String, place: String, chance: String, frequency: String, observed: String, collection: String) -> void:
	check(prefix + " place", hud.place_label.text == place)
	check(prefix + " chance", hud.chance_button.text == chance)
	check(prefix + " frequency", hud.frequency_label.text == frequency)
	check(prefix + " observed", hud.observed_label.text == observed)
	check(prefix + " collection", hud.collection_label.text == collection)


func _render_case(hud, context: Dictionary, prefix: String, snapshot: Dictionary, expected: Dictionary) -> void:
	var before_json := JSON.stringify(snapshot)
	hud.render_snapshot(snapshot)
	_expect_texts(
		hud, prefix,
		String(expected.place), String(expected.chance), String(expected.frequency),
		String(expected.observed), String(expected.collection),
	)
	check(prefix + " input unchanged", JSON.stringify(snapshot) == before_json)
	check(prefix + " notice intact", hud.notice_label.text == String(context.notice))
	check(prefix + " children stable", hud.get_child_count() == int(context.child_count))
	check(prefix + " buttons stable", _button_count(hud) == int(context.button_count))
	for control: String in context.refs:
		check(prefix + " reference " + control, hud.get(control) == context.refs[control])
	for action: String in fired:
		check(prefix + " callback silent " + action, fired[action] == 0)
	check(prefix + " collection position", (hud.collection_label as Control).position == Vector2(20, 53))
	check(prefix + " notice position", (hud.notice_label as Control).position == Vector2(20, 77))


func _run_isolated() -> void:
	var hud_script = load("res://scenes/visual/field_hud.gd")
	check("hud script loads", hud_script != null)
	if hud_script == null: return
	var hud = hud_script.new()
	var theme := Theme.new()
	var actions := {}
	for action: String in ["tera", "elemental", "external", "frequency", "restart", "settings", "geometry", "gallery", "report"]:
		fired[action] = 0
		actions[action] = _record.bind(action)
	var built = hud.build(theme, actions)
	check("build returns same view", built == hud)
	var context := {
		"notice": "Aviso de acción intacto",
		"child_count": hud.get_child_count(),
		"button_count": _button_count(hud),
		"refs": {
			"place_label": hud.place_label,
			"frequency_label": hud.frequency_label,
			"observed_label": hud.observed_label,
			"collection_label": hud.collection_label,
			"chance_button": hud.chance_button,
			"notice_label": hud.notice_label,
		},
	}
	hud.notice_label.text = String(context.notice)

	var route_zero := fixture()
	_render_case(hud, context, "route zero", route_zero, {
		"place": "RUTA 01 · CLARO DE PRUEBAS",
		"chance": "Frecuencia: 0 %",
		"frequency": "Sin encuentros: frecuencia 0 %.",
		"observed": "0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"collection": "Equipo 1/6   ·   Poké Balls 5   ·   Pool aleatorio Nv. 4–6",
	})

	var route_full := fixture({
		"encounters_enabled": true,
		"encounter_percent": 100,
		"mean_steps": 2.5,
		"mean_walking_seconds": 4.5,
		"rolls": 7,
		"encounters": 2,
		"captures": 1,
		"grass_walking_seconds": 3.5,
		"party_size": 2,
		"poke_balls": 9,
		"species_label": "Pikachu",
		"min_level": 5,
		"max_level": 9,
	})
	_render_case(hud, context, "route full", route_full, {
		"place": "RUTA 01 · CLARO DE PRUEBAS",
		"chance": "Frecuencia: 100 %",
		"frequency": "Media teórica: 2.5 pasos / 4.5 s en zona · no es un plazo garantizado",
		"observed": "7 tiradas · 2 encuentros · 1 capturas · 3.5 s andando en zona",
		"collection": "Equipo 2/6   ·   Poké Balls 9   ·   Pikachu Nv. 5–9",
	})

	var cave := fixture({
		"region_id": "cave",
		"cave_title_min_level": 9,
		"cave_title_max_level": 11,
		"encounters_enabled": true,
		"encounter_percent": 100,
		"mean_steps": 1.0,
		"mean_walking_seconds": 0.3,
		"rolls": 12,
		"encounters": 4,
		"captures": 3,
		"grass_walking_seconds": 9.5,
		"party_size": 3,
		"poke_balls": 4,
		"species_label": "Pool aleatorio",
		"min_level": 7,
		"max_level": 10,
	})
	var cave_expected := {
		"place": "CUEVA · ENCUENTROS Nv. 9–11",
		"chance": "Frecuencia: 100 %",
		"frequency": "Media teórica: 1.0 pasos / 0.3 s en zona · no es un plazo garantizado",
		"observed": "12 tiradas · 4 encuentros · 3 capturas · 9.5 s andando en zona",
		"collection": "Equipo 3/6   ·   Poké Balls 4   ·   Pool aleatorio Nv. 7–10",
	}
	_render_case(hud, context, "cave", cave, cave_expected)

	var building := fixture({
		"region_id": "building",
		"encounters_enabled": false,
		"encounter_percent": 0,
		"mean_steps": 0.0,
		"mean_walking_seconds": 0.0,
		"rolls": 5,
		"encounters": 0,
		"captures": 2,
		"grass_walking_seconds": 6.5,
		"party_size": 4,
		"poke_balls": 0,
		"species_label": "Pikachu",
		"min_level": 1,
		"max_level": 2,
	})
	var building_expected := {
		"place": "REFUGIO · ZONA SEGURA",
		"chance": "Frecuencia: 0 %",
		"frequency": "Sin encuentros: frecuencia 0 %.",
		"observed": "5 tiradas · 0 encuentros · 2 capturas · 6.5 s andando en zona",
		"collection": "Equipo 4/6   ·   Refugio sin encuentros",
	}
	_render_case(hud, context, "building", building, building_expected)

	var cave_defaults := {"region_id": "cave", "species_label": "Pool aleatorio"}
	_render_case(hud, context, "cave defaults", cave_defaults, {
		"place": "CUEVA · ENCUENTROS Nv. 8–12",
		"chance": "Frecuencia: 0 %",
		"frequency": "Sin encuentros: frecuencia 0 %.",
		"observed": "0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"collection": "Equipo 0/6   ·   Poké Balls 0   ·   Pool aleatorio Nv. 4–6",
	})
	var route_defaults := {"region_id": "surface", "species_label": "Pikachu"}
	_render_case(hud, context, "route defaults", route_defaults, {
		"place": "RUTA 01 · CLARO DE PRUEBAS",
		"chance": "Frecuencia: 0 %",
		"frequency": "Sin encuentros: frecuencia 0 %.",
		"observed": "0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"collection": "Equipo 0/6   ·   Poké Balls 0   ·   Pikachu Nv. 4–6",
	})

	var transition := [
		{"name": "route", "snapshot": route_zero, "expected": {
			"place": "RUTA 01 · CLARO DE PRUEBAS", "chance": "Frecuencia: 0 %",
			"frequency": "Sin encuentros: frecuencia 0 %.",
			"observed": "0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
			"collection": "Equipo 1/6   ·   Poké Balls 5   ·   Pool aleatorio Nv. 4–6",
		}},
		{"name": "building", "snapshot": building, "expected": building_expected},
		{"name": "cave", "snapshot": cave, "expected": cave_expected},
		{"name": "route return", "snapshot": route_full, "expected": {
			"place": "RUTA 01 · CLARO DE PRUEBAS", "chance": "Frecuencia: 100 %",
			"frequency": "Media teórica: 2.5 pasos / 4.5 s en zona · no es un plazo garantizado",
			"observed": "7 tiradas · 2 encuentros · 1 capturas · 3.5 s andando en zona",
			"collection": "Equipo 2/6   ·   Poké Balls 9   ·   Pikachu Nv. 5–9",
		}},
	]
	for step in transition:
		_render_case(hud, context, "transition " + String(step.name), step.snapshot, step.expected)

	var before_press: Dictionary = fired.duplicate()
	hud.chance_button.pressed.emit()
	check("frequency button still wired", int(fired.frequency) == int(before_press.frequency) + 1)
	for action: String in fired:
		if action == "frequency": continue
		check("manual press only fires frequency " + action, fired[action] == int(before_press[action]))
	check("notice survives manual button", hud.notice_label.text == String(context.notice))
	check("theme preserved", hud.theme == theme)
	hud.free()


func _check_snapshot_boundary(snapshot: Dictionary, prefix: String) -> void:
	check(prefix + " snapshot key count", snapshot.size() == EXPECTED_KEYS.size())
	for key: String in EXPECTED_KEYS:
		check(prefix + " snapshot key " + key, snapshot.has(key))
		if snapshot.has(key):
			var value_type := typeof(snapshot[key])
			check(prefix + " snapshot scalar " + key, value_type in [TYPE_STRING, TYPE_BOOL, TYPE_INT, TYPE_FLOAT])


func _check_five(hud, prefix: String, place: String, chance: String, frequency: String, observed: String, collection: String) -> void:
	check(prefix + " place", hud.place_label.text == place)
	check(prefix + " chance", hud.chance_button.text == chance)
	check(prefix + " frequency", hud.frequency_label.text == frequency)
	check(prefix + " observed", hud.observed_label.text == observed)
	check(prefix + " collection", hud.collection_label.text == collection)


func _run_real_scene() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var packed := load("res://scenes/visual/field_demo.tscn")
	check("real scene loads", packed != null)
	if packed == null: return
	var scene: Node2D = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var frames := 0
	while not scene.is_demo_ready() and frames < 120:
		await process_frame
		frames += 1
	check("real scene ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		scene.queue_free()
		await process_frame
		return

	var bridge = scene._native_battles
	check("real scene native bridge", bridge != null)
	if bridge != null:
		bridge.save_path = OUT + "save.json"

	var snapshot: Dictionary = scene._hud_snapshot()
	_check_snapshot_boundary(snapshot, "real initial")
	check("initial region surface", String(snapshot.region_id) == "surface")
	check("initial cave title defaults", int(snapshot.cave_title_min_level) == 8 and int(snapshot.cave_title_max_level) == 12)
	check("initial encounters enabled", bool(snapshot.encounters_enabled) and int(snapshot.encounter_percent) == 15)
	check("initial mean steps literal", is_equal_approx(float(snapshot.mean_steps), 6.6666667))
	check("initial mean seconds literal", is_equal_approx(float(snapshot.mean_walking_seconds), 2.2222223))
	check("initial counters zero", int(snapshot.rolls) == 0 and int(snapshot.encounters) == 0 and int(snapshot.captures) == 0)
	check("initial grass zero", is_equal_approx(float(snapshot.grass_walking_seconds), 0.0))
	check("initial party size", int(snapshot.party_size) == 2)
	check("initial poke balls", int(snapshot.poke_balls) == 3)
	check("initial species", String(snapshot.species_label) == "Pidgey")
	check("initial wild levels", int(snapshot.min_level) == 4 and int(snapshot.max_level) == 6)
	check("initial region matches owner", String(snapshot.region_id) == String(scene.technical_region_id()))
	var expectation: Dictionary = scene.encounter_expectation()
	check("initial enabled matches owner", bool(snapshot.encounters_enabled) == bool(expectation.get("enabled", false)))
	check("initial percent matches owner", int(snapshot.encounter_percent) == int(expectation.get("percent", 0)))
	check("initial means match owner", is_equal_approx(float(snapshot.mean_steps), float(expectation.get("mean_steps", 0.0))) and is_equal_approx(float(snapshot.mean_walking_seconds), float(expectation.get("mean_walking_seconds", 0.0))))
	check("initial party matches owner", int(snapshot.party_size) == scene.demo_party_size())
	check("initial balls match owner", int(snapshot.poke_balls) == scene.demo_inventory_quantity(&"poke_ball"))
	check("initial species matches owner", String(snapshot.species_label) == SpanishGameText.species_name(&"pidgey", scene._catalogs))
	check("initial wild levels match owner", int(snapshot.min_level) == int(scene._active_config.get("wild_min_level", -1)) and int(snapshot.max_level) == int(scene._active_config.get("wild_max_level", -1)))
	check("initial cave title matches owner", int(snapshot.cave_title_min_level) == int(scene._active_config.get("cave_min_level", -1)) and int(snapshot.cave_title_max_level) == int(scene._active_config.get("cave_max_level", -1)))
	scene._refresh_hud()
	_check_five(
		scene._hud, "real initial",
		"RUTA 01 · CLARO DE PRUEBAS", "Frecuencia: 15 %",
		"Media teórica: 6.7 pasos / 2.2 s en zona · no es un plazo garantizado",
		"0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"Equipo 2/6   ·   Poké Balls 3   ·   Pidgey Nv. 4–6",
	)

	var config: Dictionary = scene.test_panel.current_configuration().duplicate(true)
	config.encounter_chance_percent = 100
	config.wild_species_id = "pikachu"
	config.wild_min_level = 5
	config.wild_max_level = 9
	config.cave_min_level = 9
	config.cave_max_level = 11
	scene._on_configuration_applied(config)
	await process_frame
	check("configuration applied", int(scene._active_config.get("encounter_chance_percent", -1)) == 100 and String(scene._active_config.get("wild_species_id", "")) == "pikachu")

	snapshot = scene._hud_snapshot()
	_check_snapshot_boundary(snapshot, "real configured")
	check("configured region surface", String(snapshot.region_id) == "surface")
	check("configured chance 100", bool(snapshot.encounters_enabled) and int(snapshot.encounter_percent) == 100)
	check("configured mean steps literal", is_equal_approx(float(snapshot.mean_steps), 1.0))
	check("configured mean seconds literal", is_equal_approx(float(snapshot.mean_walking_seconds), 0.33333334))
	check("configured species", String(snapshot.species_label) == "Pikachu")
	check("configured wild levels", int(snapshot.min_level) == 5 and int(snapshot.max_level) == 9)
	check("configured cave title", int(snapshot.cave_title_min_level) == 9 and int(snapshot.cave_title_max_level) == 11)
	check("configured party and balls", int(snapshot.party_size) == 2 and int(snapshot.poke_balls) == 3)
	scene._refresh_hud()
	_check_five(
		scene._hud, "real configured route",
		"RUTA 01 · CLARO DE PRUEBAS", "Frecuencia: 100 %",
		"Media teórica: 1.0 pasos / 0.3 s en zona · no es un plazo garantizado",
		"0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"Equipo 2/6   ·   Poké Balls 3   ·   Pikachu Nv. 5–9",
	)

	scene._grass_walking_seconds = 7.5
	scene._refresh_hud()
	check("observed fixture snapshot", is_equal_approx(float(scene._hud_snapshot().grass_walking_seconds), 7.5))
	_check_five(
		scene._hud, "real configured observed",
		"RUTA 01 · CLARO DE PRUEBAS", "Frecuencia: 100 %",
		"Media teórica: 1.0 pasos / 0.3 s en zona · no es un plazo garantizado",
		"0 tiradas · 0 encuentros · 0 capturas · 7.5 s andando en zona",
		"Equipo 2/6   ·   Poké Balls 3   ·   Pikachu Nv. 5–9",
	)

	scene.player.global_position = Vector2(940, 214)
	scene._refresh_hud()
	snapshot = scene._hud_snapshot()
	check("building snapshot region", String(snapshot.region_id) == "building")
	_check_five(
		scene._hud, "real building",
		"REFUGIO · ZONA SEGURA", "Frecuencia: 100 %",
		"Media teórica: 1.0 pasos / 0.3 s en zona · no es un plazo garantizado",
		"0 tiradas · 0 encuentros · 0 capturas · 7.5 s andando en zona",
		"Equipo 2/6   ·   Refugio sin encuentros",
	)

	config.encounter_chance_percent = 0
	scene._on_configuration_applied(config)
	await process_frame
	snapshot = scene._hud_snapshot()
	check("disabled chance zero", not bool(snapshot.encounters_enabled) and int(snapshot.encounter_percent) == 0)
	check("disabled means zero", is_equal_approx(float(snapshot.mean_steps), 0.0) and is_equal_approx(float(snapshot.mean_walking_seconds), 0.0))
	scene._refresh_hud()
	_check_five(
		scene._hud, "real disabled route",
		"RUTA 01 · CLARO DE PRUEBAS", "Frecuencia: 0 %",
		"Sin encuentros: frecuencia 0 %.",
		"0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"Equipo 2/6   ·   Poké Balls 3   ·   Pikachu Nv. 5–9",
	)

	scene.player.global_position = Vector2(320, 654)
	scene._refresh_hud()
	snapshot = scene._hud_snapshot()
	check("cave snapshot region", String(snapshot.region_id) == "cave")
	check("cave snapshot title", int(snapshot.cave_title_min_level) == 9 and int(snapshot.cave_title_max_level) == 11)
	check("cave snapshot collection levels", int(snapshot.min_level) == 9 and int(snapshot.max_level) == 11)
	_check_five(
		scene._hud, "real cave",
		"CUEVA · ENCUENTROS Nv. 9–11", "Frecuencia: 0 %",
		"Sin encuentros: frecuencia 0 %.",
		"0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"Equipo 2/6   ·   Poké Balls 3   ·   Pikachu Nv. 9–11",
	)

	scene.player.global_position = Vector2(96, 180)
	scene._refresh_hud()
	snapshot = scene._hud_snapshot()
	check("route return region", String(snapshot.region_id) == "surface")
	_check_five(
		scene._hud, "real route return",
		"RUTA 01 · CLARO DE PRUEBAS", "Frecuencia: 0 %",
		"Sin encuentros: frecuencia 0 %.",
		"0 tiradas · 0 encuentros · 0 capturas · 0.0 s andando en zona",
		"Equipo 2/6   ·   Poké Balls 3   ·   Pikachu Nv. 5–9",
	)

	if bridge != null:
		var save_absolute := ProjectSettings.globalize_path(bridge.save_path)
		if FileAccess.file_exists(bridge.save_path):
			DirAccess.remove_absolute(save_absolute)
		check("invariance save fixture", bridge.save_game())
		var save_before := FileAccess.get_file_as_bytes(bridge.save_path)
		var collection_before: PlayerCollection = scene._session.player
		var party_before: CreatureParty = collection_before.party
		var inventory_before: PlayerInventory = collection_before.inventory
		var session_before = scene._session
		var party_before_json := JSON.stringify(party_before.to_dict())
		var inventory_before_json := JSON.stringify(inventory_before.to_dict())
		var config_before_json := JSON.stringify(scene._active_config)
		var position_before: Vector2 = scene.player.global_position
		var grass_before: float = scene._grass_walking_seconds
		var encounter_rng_before: int = scene._director._encounter_rng.state
		var capture_rng_before: int = scene._capture_rng.state
		var escape_rng_before: int = scene._escape_rng.state
		var next_seed_before: int = scene._director._next_battle_seed
		for i in 3:
			scene._refresh_hud()
		check("refresh keeps session", scene._session == session_before)
		check("refresh keeps collection", scene._session.player == collection_before)
		check("refresh keeps party", collection_before.party == party_before)
		check("refresh keeps inventory", collection_before.inventory == inventory_before)
		check("refresh keeps party data", JSON.stringify(party_before.to_dict()) == party_before_json)
		check("refresh keeps inventory data", JSON.stringify(inventory_before.to_dict()) == inventory_before_json)
		check("refresh keeps config", JSON.stringify(scene._active_config) == config_before_json)
		check("refresh keeps position", scene.player.global_position == position_before)
		check("refresh keeps grass accumulator", is_equal_approx(scene._grass_walking_seconds, grass_before))
		check("refresh keeps encounter RNG", int(scene._director._encounter_rng.state) == encounter_rng_before)
		check("refresh keeps capture RNG", int(scene._capture_rng.state) == capture_rng_before)
		check("refresh keeps escape RNG", int(scene._escape_rng.state) == escape_rng_before)
		check("refresh keeps next seed", int(scene._director._next_battle_seed) == next_seed_before)
		check("refresh keeps save bytes", FileAccess.get_file_as_bytes(bridge.save_path) == save_before)
		check("refresh keeps party size", scene.demo_party_size() == 2)
		check("refresh keeps poke balls", scene.demo_inventory_quantity(&"poke_ball") == 3)

	scene.queue_free()
	await process_frame
	await process_frame


func _run() -> void:
	_run_isolated()
	create_timer(120.0).timeout.connect(_on_watchdog)
	await _run_real_scene()
	_finish()


func _on_watchdog() -> void:
	if done: return
	check("real scene watchdog", false)
	_finish()


func _finish() -> void:
	if done: return
	done = true
	if errors.is_empty():
		print("FIELD_HUD_RENDER PASS checks=%d" % checks)
		quit(0)
	else:
		for e in errors: printerr(e)
		quit(1)
