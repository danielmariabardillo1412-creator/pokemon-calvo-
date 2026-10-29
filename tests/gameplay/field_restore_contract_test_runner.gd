extends SceneTree

## T006B owner persistence contract: getters, world snapshot, encounter tables
## and the validated-world result. The integration runner exercises publication.

const OUT := "res://.godot/field_restore_checks/"

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
			"test_runner": FileAccess.get_sha256("res://tests/gameplay/field_restore_contract_test_runner.gd"),
		},
	}
	var file := FileAccess.open(OUT + ("contract_legacy.json" if legacy else "contract_native.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_RESTORE_CONTRACT ", report.status, " profile=", report.profile, " checks=", checks, " errors=", errors.size())
	if scene != null and is_instance_valid(scene): scene.queue_free()
	quit(0 if errors.is_empty() else 1)


func clocks_view() -> String:
	if scene._native_battles == null: return ""
	var keys: Array = scene._native_battles.clocks.keys(); keys.sort()
	var rows := []
	for key: Variant in keys: rows.append([String(key), JSON.stringify(scene._native_battles.clocks[key])])
	return JSON.stringify(rows)


func tables_view(tables: Dictionary) -> String:
	var rows := []
	var keys: Array = tables.keys(); keys.sort()
	for key: Variant in keys:
		var table := tables[key] as WildEncounterTable
		rows.append([String(key), table.to_dict() if table != null else null])
	return JSON.stringify(rows)


func state_view() -> Dictionary:
	return {
		"collection": scene.field_collection(),
		"definitions": scene.field_definitions(),
		"trainer": scene.field_trainer_owner(),
		"session": scene._session,
		"trainer_session": scene._trainer_session,
		"position": scene.player.global_position,
		"movement": scene.player.movement_enabled,
		"config": JSON.stringify(scene._active_config),
		"rng": scene._director._encounter_rng.state,
		"seed": scene._director._next_battle_seed,
		"tables_ref": scene._director._tables,
		"tables": tables_view(scene._director._tables),
		"clocks_ref": scene._native_battles.clocks if scene._native_battles != null else null,
		"clocks": clocks_view(),
		"records": scene._recorder.entry_count(),
	}


func expect_unchanged(label: String, before: Dictionary) -> void:
	var after := state_view()
	check(label + " collection identity", is_same(after.collection, before.collection))
	check(label + " definitions identity", is_same(after.definitions, before.definitions))
	check(label + " trainer identity", is_same(after.trainer, before.trainer))
	check(label + " field session identity", is_same(after.session, before.session))
	check(label + " trainer session identity", is_same(after.trainer_session, before.trainer_session))
	check(label + " position", after.position == before.position)
	check(label + " movement", after.movement == before.movement)
	check(label + " config", after.config == before.config)
	check(label + " rng", after.rng == before.rng)
	check(label + " seed", after.seed == before.seed)
	check(label + " live tables identity", is_same(after.tables_ref, before.tables_ref))
	check(label + " live tables content", after.tables == before.tables)
	check(label + " clocks identity", is_same(after.clocks_ref, before.clocks_ref))
	check(label + " clocks content", after.clocks == before.clocks)
	check(label + " recorder", after.records == before.records)


func reference_tables(config: Dictionary) -> Dictionary:
	var tables := {}
	var species := String(config.get("wild_species_id", "")).trim_suffix("__shiny")
	for row: Array in [[scene.TECHNICAL_ZONE_ID, "wild_min_level", "wild_max_level"], [scene.TECHNICAL_CAVE_ZONE_ID, "cave_min_level", "cave_max_level"]]:
		var built := TechnicalEncounterPoolBuilder.build(scene._catalogs, row[0], int(config.encounter_chance_percent), int(config[row[1]]), int(config[row[2]]), StringName(species))
		if built.ok: tables[row[0]] = built.table
	return tables


func expect_tables(label: String, actual: Dictionary, config: Dictionary) -> void:
	var expected := reference_tables(config)
	check(label + " table count", actual.size() == expected.size() and actual.size() == 2)
	var keys: Array = expected.keys(); keys.sort()
	var actual_keys: Array = actual.keys(); actual_keys.sort()
	check(label + " table keys", JSON.stringify(actual_keys) == JSON.stringify(keys))
	for key: Variant in keys:
		var actual_table := actual.get(key) as WildEncounterTable
		var expected_table := expected[key] as WildEncounterTable
		check(label + " table " + String(key), actual_table != null and expected_table != null and actual_table.to_dict() == expected_table.to_dict())


func find_clear(region: StringName, step: int) -> Vector2:
	for y in range(16, 851, step):
		for x in range(16, 1281, step):
			var point := Vector2(x, y)
			if String(scene._region_at_position(point)) != String(region): continue
			if scene.traversal_controller._destination_is_clear(point): return point
	return Vector2.ZERO


func check_preboot() -> void:
	var early: Node2D = load("res://scenes/visual/field_demo.gd").new()
	check("preboot movement false", not early.field_player_movement_enabled())
	check("preboot position zero", early.field_player_position() == Vector2.ZERO)
	early.free()


func check_getters_and_snapshot() -> void:
	var before := state_view()
	check("player position getter", scene.field_player_position() == scene.player.global_position)
	check("movement getter agrees", scene.field_player_movement_enabled() == scene.player.movement_enabled)
	scene.player.movement_enabled = not scene.player.movement_enabled
	check("movement getter tracks live flag", scene.field_player_movement_enabled() == scene.player.movement_enabled)
	scene.player.movement_enabled = before.movement
	expect_unchanged("getters", before)

	var world: Dictionary = scene.field_native_world_snapshot("gen9customgame")
	check("snapshot key order", world.keys() == ["position", "region", "config", "rng", "next_seed", "format"])
	check("snapshot position shape", world.position is Array and world.position.size() == 2)
	check("snapshot position x", world.position[0] == scene.player.global_position.x)
	check("snapshot position y", world.position[1] == scene.player.global_position.y)
	check("snapshot region", world.region is String and world.region == String(scene.technical_region_id()))
	check("snapshot config content", world.config == scene._active_config)
	check("snapshot config is a copy", not is_same(world.config, scene._active_config))
	check("snapshot rng", world.rng is String and world.rng == str(scene._director._encounter_rng.state) and world.rng.is_valid_int())
	check("snapshot seed", world.next_seed == scene._director._next_battle_seed)
	check("snapshot format", world.format == "gen9customgame")
	check("snapshot alternate format", scene.field_native_world_snapshot("gen8customgame").format == "gen8customgame")
	check("snapshot unified format", scene.field_native_world_snapshot("gen9calvounifiedv1").format == "gen9calvounifiedv1")
	expect_unchanged("snapshot", before)

	var isolated: Dictionary = scene.field_native_world_snapshot("gen9customgame")
	var live_before := JSON.stringify(scene._active_config)
	isolated.config.wild_min_level = 99
	check("snapshot config mutation isolated", JSON.stringify(scene._active_config) == live_before)
	scene._active_config["__contract_probe"] = true
	check("snapshot config not a live alias", not isolated.config.has("__contract_probe"))
	scene._active_config.erase("__contract_probe")
	check("snapshot state leaves rng", scene._director._encounter_rng.state == before.rng)
	check("snapshot state leaves seed", scene._director._next_battle_seed == before.seed)
	check("snapshot state leaves records", scene._recorder.entry_count() == before.records)


func check_builder() -> void:
	var config: Dictionary = scene._active_config.duplicate(true)
	var before := state_view()
	var config_before := JSON.stringify(config)
	var tables: Dictionary = scene.field_build_native_encounter_tables(config)
	check("builder returns both zones", tables.size() == 2 and tables.has(scene.TECHNICAL_ZONE_ID) and tables.has(scene.TECHNICAL_CAVE_ZONE_ID))
	check("builder does not mutate config", JSON.stringify(config) == config_before)
	check("builder does not publish live tables", not is_same(tables, scene._director._tables))
	check("builder tables are new", not is_same(tables.get(scene.TECHNICAL_ZONE_ID), scene._director._tables.get(scene.TECHNICAL_ZONE_ID)))
	expect_tables("builder reference", tables, config)
	expect_unchanged("builder", before)

	var fresh: Dictionary = scene.field_build_native_encounter_tables(config)
	check("builder fresh dictionary", not is_same(fresh, tables))
	check("builder fresh tables", not is_same(fresh.get(scene.TECHNICAL_ZONE_ID), tables.get(scene.TECHNICAL_ZONE_ID)))
	check("builder fresh content", tables_view(fresh) == tables_view(tables))
	expect_unchanged("builder repeat", before)

	var rejections := [
		["player team missing", func(c: Dictionary): c.erase("player_team")],
		["player team empty", func(c: Dictionary): c.player_team = []],
		["player team oversized", func(c: Dictionary): c.player_team = [c.player_team[0], c.player_team[0], c.player_team[0], c.player_team[0], c.player_team[0], c.player_team[0], c.player_team[0]]],
		["trainer team not array", func(c: Dictionary): c.trainer_team = {}],
		["row not dictionary", func(c: Dictionary): c.player_team = ["pidgey"]],
		["species not string", func(c: Dictionary): c.player_team = [{"species_id": 5, "level": 5}]],
		["level not numeric", func(c: Dictionary): c.player_team = [{"species_id": "pidgey", "level": "5"}]],
		["level fractional", func(c: Dictionary): c.player_team = [{"species_id": "pidgey", "level": 5.5}]],
		["level zero", func(c: Dictionary): c.player_team = [{"species_id": "pidgey", "level": 0}]],
		["level above max", func(c: Dictionary): c.trainer_team = [{"species_id": "pidgey", "level": 101}]],
		["wild species not string", func(c: Dictionary): c.wild_species_id = 5],
		["wild min not numeric", func(c: Dictionary): c.wild_min_level = "4"],
		["wild max fractional", func(c: Dictionary): c.wild_max_level = 6.5],
		["cave min negative", func(c: Dictionary): c.cave_min_level = -1],
		["chance above max", func(c: Dictionary): c.encounter_chance_percent = 101],
		["wild levels inverted", func(c: Dictionary): c.wild_min_level = 10; c.wild_max_level = 9],
		["wild min zero", func(c: Dictionary): c.wild_min_level = 0],
		["cave levels inverted", func(c: Dictionary): c.cave_min_level = 20; c.cave_max_level = 10],
		["cave min zero", func(c: Dictionary): c.cave_min_level = 0],
	]
	for row: Array in rejections:
		var candidate: Dictionary = config.duplicate(true)
		(row[1] as Callable).call(candidate)
		var rejected: Dictionary = scene.field_build_native_encounter_tables(candidate)
		check("builder rejects " + String(row[0]), rejected.is_empty())
	expect_unchanged("builder rejections", before)

	var unknown: Dictionary = config.duplicate(true); unknown.wild_species_id = "missing_contract_species"
	check("builder rejects unknown fixed species", scene.field_build_native_encounter_tables(unknown).is_empty())
	var random: Dictionary = config.duplicate(true); random.wild_species_id = ""
	var random_tables: Dictionary = scene.field_build_native_encounter_tables(random)
	check("builder accepts random pool", random_tables.size() == 2)
	if random_tables.size() == 2:
		var random_slots: int = (random_tables[scene.TECHNICAL_ZONE_ID] as WildEncounterTable).slots.size()
		check("builder random pool is a real pool", random_slots >= 1)
	expect_unchanged("builder random", before)

	var shiny_allowed := ""
	var shiny_denied := ""
	for raw_id: Variant in scene._catalogs.species_catalog.all_ids():
		var species_id := String(raw_id)
		var probe: Dictionary = config.duplicate(true)
		probe.wild_species_id = species_id
		probe.wild_min_level = 5; probe.wild_max_level = 5
		if scene.field_build_native_encounter_tables(probe).is_empty(): continue
		if scene._catalogs.shiny_species_ids.has(species_id) and shiny_allowed.is_empty(): shiny_allowed = species_id
		if not scene._catalogs.shiny_species_ids.has(species_id) and shiny_denied.is_empty(): shiny_denied = species_id
		if not shiny_allowed.is_empty() and not shiny_denied.is_empty(): break
	check("builder fixture has shiny allowed species", not shiny_allowed.is_empty())
	check("builder fixture has shiny denied species", not shiny_denied.is_empty())
	if not shiny_allowed.is_empty():
		var allowed: Dictionary = config.duplicate(true); allowed.wild_species_id = shiny_allowed + "__shiny"
		var allowed_tables: Dictionary = scene.field_build_native_encounter_tables(allowed)
		check("builder accepts allowed shiny", allowed_tables.size() == 2)
		if allowed_tables.size() == 2:
			var slot := (allowed_tables[scene.TECHNICAL_ZONE_ID] as WildEncounterTable).slots[0]
			check("builder trims shiny suffix", String(slot.species_id) == shiny_allowed)
	if not shiny_denied.is_empty():
		var denied: Dictionary = config.duplicate(true); denied.wild_species_id = shiny_denied + "__shiny"
		check("builder rejects denied shiny", scene.field_build_native_encounter_tables(denied).is_empty())
	expect_unchanged("builder shiny", before)


func valid_world(format_id: String = "gen9customgame") -> Dictionary:
	return scene.field_native_world_snapshot(format_id)


func expect_world_unchanged(label: String, world: Dictionary, text: String) -> void:
	check(label + " world unchanged", JSON.stringify(world) == text)


func accepts_world(label: String, world: Dictionary, config: Dictionary) -> Dictionary:
	var before := state_view()
	var text := JSON.stringify(world)
	var result: Dictionary = scene.field_validate_native_loaded_world(world)
	check(label + " accepted", bool(result.get("ok", false)))
	check(label + " result keys", result.keys() == ["ok", "position", "tables"])
	check(label + " position type", result.get("position") is Vector2)
	check(label + " tables type", result.get("tables") is Dictionary)
	check(label + " position value", result.get("position") == Vector2(world.position[0], world.position[1]))
	expect_tables(label + " tables", result.get("tables", {}), config)
	expect_world_unchanged(label, world, text)
	expect_unchanged(label, before)
	return result


func rejects_world(label: String, world: Dictionary, reason: String) -> void:
	var before := state_view()
	var text := JSON.stringify(world)
	var result: Dictionary = scene.field_validate_native_loaded_world(world)
	check(label + " rejected", not bool(result.get("ok", true)))
	check(label + " reason", String(result.get("error", "")) == reason)
	check(label + " keys", result.size() == 2 and result.has("ok") and result.has("error"))
	expect_world_unchanged(label, world, text)
	expect_unchanged(label, before)


func check_validator_valid() -> void:
	var world := valid_world()
	var result := accepts_world("valid default", world, world.config)
	check("valid position type", result.position == scene.player.global_position)
	check("valid tables are fresh", not is_same(result.tables, scene._director._tables))

	for format_id: String in ["gen8customgame", "gen9customgame", "gen9calvounifiedv1"]:
		accepts_world("valid format " + format_id, valid_world(format_id), scene._active_config)

	for seed_value: int in [1, 2147483646]:
		var seed_world := valid_world(); seed_world.next_seed = seed_value
		var accepted := accepts_world("valid seed " + str(seed_value), seed_world, scene._active_config)
		check("valid seed result", accepted.get("position") == scene.player.global_position)
	var float_seed := valid_world(); float_seed.next_seed = 1.0
	accepts_world("valid float seed", float_seed, scene._active_config)

	for region: StringName in [&"surface", &"building", &"cave"]:
		var point := find_clear(region, 4 if legacy else 2)
		if point == Vector2.ZERO:
			check("valid region fixture " + String(region), false); continue
		var region_world := valid_world()
		region_world.position = [point.x, point.y]; region_world.region = String(region)
		var accepted := accepts_world("valid region " + String(region), region_world, scene._active_config)
		check("valid region position " + String(region), accepted.get("position") == point)

	var config_copy := valid_world()
	var config_text := JSON.stringify(config_copy.config)
	accepts_world("valid config isolation", config_copy, config_copy.config)
	check("validator leaves config unchanged", JSON.stringify(config_copy.config) == config_text)


func check_validator_rejections() -> void:
	var shape_world := valid_world(); shape_world.position = [96, 180, 0]
	rejects_world("shape position size", shape_world, "world_shape")
	shape_world = valid_world(); shape_world.position = "x"
	rejects_world("shape position type", shape_world, "world_shape")
	shape_world = valid_world(); shape_world.config = []
	rejects_world("shape config type", shape_world, "world_shape")
	shape_world = valid_world(); shape_world.format = "bogus"
	rejects_world("shape format", shape_world, "world_shape")
	shape_world = valid_world(); shape_world.rng = "abc"
	rejects_world("shape rng", shape_world, "world_shape")
	shape_world = valid_world(); shape_world.next_seed = "1"
	rejects_world("shape seed type", shape_world, "world_shape")
	shape_world = valid_world(); shape_world.erase("next_seed")
	rejects_world("shape seed missing", shape_world, "world_shape")
	shape_world = valid_world(); shape_world.position = [96]; shape_world.format = "bogus"; shape_world.rng = "abc"
	rejects_world("shape priority", shape_world, "world_shape")

	for raw_position: Array in [[1, 180], [96, 14], [1290, 180], [96, 860], ["96", 180], [NAN, 180], [INF, 180], [-INF, 180]]:
		var position_world := valid_world(); position_world.position = raw_position.duplicate()
		rejects_world("position " + str(raw_position), position_world, "world_position")
	var region_world := valid_world(); region_world.region = "cave"
	rejects_world("position wrong region", region_world, "world_position")
	var collision_world := valid_world(); collision_world.position = [280, 180]; collision_world.region = "surface"
	rejects_world("position collision", collision_world, "world_position")
	var priority_world := valid_world(); priority_world.position = [1, 180]; priority_world.next_seed = 0
	rejects_world("position before seed", priority_world, "world_position")

	for seed_value: Variant in [0, -1, 2147483647, 1.5]:
		var seed_world := valid_world(); seed_world.next_seed = seed_value
		rejects_world("seed " + str(seed_value), seed_world, "world_seed")
	var seed_priority := valid_world(); seed_priority.next_seed = 0; seed_priority.config.wild_min_level = 0
	rejects_world("seed before encounters", seed_priority, "world_seed")

	var encounters_world := valid_world(); encounters_world.config.player_team = []
	rejects_world("encounters empty team", encounters_world, "world_encounters")
	encounters_world = valid_world(); encounters_world.config.wild_min_level = 0
	rejects_world("encounters min zero", encounters_world, "world_encounters")
	encounters_world = valid_world(); encounters_world.config.wild_min_level = 3.5
	rejects_world("encounters fractional", encounters_world, "world_encounters")
	encounters_world = valid_world(); encounters_world.config.cave_min_level = 20; encounters_world.config.cave_max_level = 10
	rejects_world("encounters inverted cave", encounters_world, "world_encounters")
	encounters_world = valid_world(); encounters_world.config.wild_species_id = "missing_contract_species"
	rejects_world("encounters unknown species", encounters_world, "world_encounters")
	encounters_world = valid_world(); encounters_world.config.encounter_chance_percent = 101
	rejects_world("encounters chance", encounters_world, "world_encounters")


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
	check("scene ready", scene.is_demo_ready())
	check("profile matches", (scene._native_battles != null) != legacy)
	check_getters_and_snapshot()
	check_builder()
	check_validator_valid()
	check_validator_rejections()
	scene.queue_free()
	await process_frame
	finish()
