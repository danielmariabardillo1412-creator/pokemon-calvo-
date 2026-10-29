extends SceneTree

## T006B integration: real native scene/worker, validated publication, corrupt
## envelopes, rejected candidate restores, atomic write failure and worker loss.

const Service = preload("res://modules/inventory/field_item_service.gd")
const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const OUT := "res://.godot/field_restore_checks/"
const SAVE_PATH := OUT + "restore_integration.json"

var scene: Node2D
var bridge: Node
var view: Control
var bag: Control
var checks := 0
var errors: Array[String] = []
var done := false
var world_baseline: Dictionary = {}


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
		"profile": "native",
		"checks": checks,
		"errors": errors,
		"source_sha256": {
			"field_demo": FileAccess.get_sha256("res://scenes/visual/field_demo.gd"),
			"field_native_bridge": FileAccess.get_sha256("res://scenes/visual/field_native_bridge.gd"),
			"test_runner": FileAccess.get_sha256("res://tests/gameplay/field_restore_integration_test_runner.gd"),
		},
	}
	var file := FileAccess.open(OUT + "integration.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_RESTORE_INTEGRATION ", report.status, " checks=", checks, " errors=", errors.size())
	if scene != null and is_instance_valid(scene):
		if view != null and view.session != null: view.session.stop_now()
		scene.queue_free()
	quit(0 if errors.is_empty() else 1)


func mon(id: String, species: String, level: int, moves: Array) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var creature := CreatureFactory.create(scene._catalogs.species(StringName(species)), level, scene._catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	if creature != null: creature.ability_id = &""
	return creature


func owned(collection: PlayerCollection, id: StringName) -> CreatureInstance:
	return collection.owned_creature(id) if collection != null else null


func quantity(collection: PlayerCollection, id: StringName) -> int:
	return collection.inventory.quantity(id) if collection != null and collection.inventory != null else -1


func collection_state(collection: PlayerCollection) -> Dictionary:
	var party := []
	var stored := []
	if collection != null:
		for creature: CreatureInstance in collection.party.get_creatures(): party.append(creature.to_dict())
		for creature: CreatureInstance in collection.storage.get_all_creatures(): stored.append(creature.to_dict())
	return {
		"party": JSON.stringify(party),
		"storage": JSON.stringify(stored),
		"inventory": JSON.stringify(collection.inventory.to_dict()) if collection != null else "",
	}


func roster_state(owner: TrainerCampaignRosterOwner) -> String:
	if owner == null: return ""
	var rows := []
	for creature: CreatureInstance in owner.roster_for_battle(): rows.append(creature.to_dict())
	return JSON.stringify(rows)


func normalized_json(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)))


func clocks_view(clocks: Dictionary) -> String:
	var keys: Array = clocks.keys(); keys.sort()
	var rows := []
	for key: Variant in keys: rows.append([String(key), normalized_json(clocks[key])])
	return JSON.stringify(rows)


func tables_view(tables: Dictionary) -> String:
	var rows := []
	var keys: Array = tables.keys(); keys.sort()
	for key: Variant in keys:
		var table := tables[key] as WildEncounterTable
		rows.append([String(key), table.to_dict() if table != null else null])
	return JSON.stringify(rows)


func panel_view() -> String:
	return JSON.stringify({
		"species": scene.test_panel._wild_species_input.text,
		"wild_min": int(scene.test_panel._wild_min_level.value),
		"wild_max": int(scene.test_panel._wild_max_level.value),
		"cave_min": int(scene.test_panel._cave_min_level.value),
		"cave_max": int(scene.test_panel._cave_max_level.value),
		"chance": int(scene.test_panel._encounter_chance.value),
	})


func panel_for_config(config: Dictionary) -> String:
	return JSON.stringify({
		"species": String(config.get("wild_species_id", "")),
		"wild_min": int(config.get("wild_min_level", 0)),
		"wild_max": int(config.get("wild_max_level", 0)),
		"cave_min": int(config.get("cave_min_level", 0)),
		"cave_max": int(config.get("cave_max_level", 0)),
		"chance": int(config.get("encounter_chance_percent", 0)),
	})


func state_view() -> Dictionary:
	var collection: PlayerCollection = scene.field_collection()
	return {
		"collection": collection,
		"definitions": scene.field_definitions(),
		"trainer": scene.field_trainer_owner(),
		"session": scene._session,
		"trainer_session": scene._trainer_session,
		"view_session": view.session,
		"position": scene.field_player_position(),
		"movement": scene.field_player_movement_enabled(),
		"config": JSON.stringify(scene._active_config),
		"panel": panel_view(),
		"rng": scene._director._encounter_rng.state,
		"seed": scene._director._next_battle_seed,
		"capture_rng": scene._capture_rng.state,
		"escape_rng": scene._escape_rng.state,
		"tables_ref": scene._director._tables,
		"tables": tables_view(scene._director._tables),
		"clocks_ref": bridge.clocks,
		"clocks": clocks_view(bridge.clocks),
		"kind": bridge.kind,
		"busy": bridge.busy,
		"working": view._working,
		"service_current": scene.field_item_service_is_current(bag.service),
		"inventory": JSON.stringify(collection.inventory.to_dict()) if collection != null else "",
		"party": collection_state(collection).party,
		"storage": collection_state(collection).storage,
		"trainer_roster": roster_state(scene.field_trainer_owner()),
		"records": scene._recorder.entry_count(),
	}


func expect_unchanged(label: String, before: Dictionary) -> void:
	var after := state_view()
	check(label + " collection identity", is_same(after.collection, before.collection))
	check(label + " definitions identity", is_same(after.definitions, before.definitions))
	check(label + " trainer identity", is_same(after.trainer, before.trainer))
	check(label + " field session identity", is_same(after.session, before.session))
	check(label + " trainer session identity", is_same(after.trainer_session, before.trainer_session))
	check(label + " view session identity", is_same(after.view_session, before.view_session))
	check(label + " position", after.position == before.position)
	check(label + " movement", after.movement == before.movement)
	check(label + " config", after.config == before.config)
	check(label + " panel", after.panel == before.panel)
	check(label + " rng", after.rng == before.rng)
	check(label + " seed", after.seed == before.seed)
	check(label + " capture rng", after.capture_rng == before.capture_rng)
	check(label + " escape rng", after.escape_rng == before.escape_rng)
	check(label + " live tables identity", is_same(after.tables_ref, before.tables_ref))
	check(label + " live tables content", after.tables == before.tables)
	check(label + " clocks identity", is_same(after.clocks_ref, before.clocks_ref))
	check(label + " clocks content", after.clocks == before.clocks)
	check(label + " kind", after.kind == before.kind)
	check(label + " busy", after.busy == before.busy)
	check(label + " working", after.working == before.working)
	check(label + " service current", after.service_current == before.service_current)
	check(label + " inventory", after.inventory == before.inventory)
	check(label + " party", after.party == before.party)
	check(label + " storage", after.storage == before.storage)
	check(label + " trainer roster", after.trainer_roster == before.trainer_roster)
	check(label + " records", after.records == before.records)


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
	for key: Variant in expected:
		var actual_table := actual.get(key) as WildEncounterTable
		var expected_table := expected[key] as WildEncounterTable
		check(label + " table " + String(key), actual_table != null and expected_table != null and actual_table.to_dict() == expected_table.to_dict())


func sleep_fixture(collection: PlayerCollection, id: StringName) -> void:
	var creature := owned(collection, id)
	creature.status_state.clear_persistent()
	creature.status_state.persistent_id = &"sleep"
	creature.status_state.turns_remaining = 2
	bridge.clocks[String(id)] = {"version": "0.10.11", "start_time": 3, "time": 2}


func configure_and_party(moves: Array = ["flamethrower", "tackle"], species: String = "mew", level: int = 40, wild_min: int = 4, wild_max: int = 6, cave_min: int = 8, cave_max: int = 12, chance: int = 100) -> void:
	if view.session != null: view._playback.cancel(); await view.session.close()
	view.hide(); bridge.busy = false; bridge.kind = ""; bridge.clocks.clear()
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "pidgey"; config.wild_min_level = wild_min; config.wild_max_level = wild_max
	config.cave_min_level = cave_min; config.cave_max_level = cave_max; config.encounter_chance_percent = chance
	scene._on_configuration_applied(config)
	check("fixture configuration applied", scene.is_demo_ready())
	var collection: PlayerCollection = scene._session.player
	collection.party = CreatureParty.new()
	collection.party.add_creature(mon("own", species, level, moves))
	collection.party.add_creature(mon("reserve", "mew", 50, ["flamethrower", "tackle"]))
	collection.inventory.add(&"potion", 2)
	scene.player.global_position = Vector2(420, 150)
	bridge._unlock_world(); await physics_frame


func close_bag() -> void:
	bag.hide()
	await process_frame


func drain() -> void:
	var count := 0
	while view._playback.is_playing() and count < 2000:
		view._playback.advance(0.25); count += 1
	await process_frame; await process_frame


func end_real_battle() -> void:
	if view._playback != null: view._playback.cancel()
	if view.session != null: await view.session.close()
	view.hide(); view._working = false
	bridge.busy = false; bridge.kind = ""
	bridge._unlock_world()
	await process_frame


func encounter() -> void:
	await scene._on_player_step_completed(scene.player.global_position)
	check("grass starts native battle", scene.has_active_demo_battle() and view.session != null and view.session.has_active_battle())
	view._playback.set_process(false)


func read_envelope() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(bridge.save_path))
	return parsed as Dictionary if parsed is Dictionary else {}


func write_envelope(envelope: Dictionary) -> void:
	var file := FileAccess.open(bridge.save_path, FileAccess.WRITE)
	check("fixture envelope writable", file != null)
	if file != null:
		file.store_string(JSON.stringify(envelope)); file.close()


func seal_envelope(envelope: Dictionary) -> void:
	var normalized: Dictionary = JSON.parse_string(JSON.stringify(envelope.payload))
	envelope.payload = normalized
	envelope.sha256 = JSON.stringify(normalized).sha256_text()
	write_envelope(envelope)


func rewrite_world(mutator: Callable) -> void:
	var envelope := read_envelope()
	if not world_baseline.is_empty(): envelope.payload.world = world_baseline.duplicate(true)
	mutator.call(envelope.payload.world)
	seal_envelope(envelope)


func rewrite_battle(mutator: Callable) -> void:
	var envelope := read_envelope()
	mutator.call(envelope.payload.battle)
	seal_envelope(envelope)


func expect_load_failure(label: String, reason: String) -> void:
	var before := state_view()
	var loaded: bool = await bridge.load_game()
	check(label + " rejected", not loaded)
	check(label + " reason", bridge.last_error == "No se pudo cargar: " + reason)
	check(label + " busy released", not bridge.busy)
	check(label + " working released", not view._working)
	expect_unchanged(label, before)


func owner_function_source(name: String) -> String:
	var source := FileAccess.get_file_as_string("res://scenes/visual/field_demo.gd")
	var marker := "\nfunc " + name + "("
	var start := source.find(marker)
	if start < 0: return ""
	var next := source.find("\nfunc ", start + marker.length())
	return source.substr(start + 1, next - start - 1) if next >= 0 else source.substr(start + 1)


func check_architecture_limits() -> void:
	var source := FileAccess.get_file_as_string("res://scenes/visual/field_native_bridge.gd")
	for token: String in ["field._", "field.player", "field.test_panel", "field.traversal_controller"]:
		check("bridge has no " + token, not source.contains(token))
	var publisher := owner_function_source("field_publish_native_loaded_world")
	check("publisher source present", not publisher.is_empty())
	for token: String in ["await", "call_deferred", "create_timer", "FileAccess", "ResourceLoader", "connect("]:
		check("publisher has no " + token, not publisher.contains(token))
	var refresh := owner_function_source("field_refresh_legacy_presentations")
	check("refresh source present", refresh.contains("_configure_presentations()"))
	check("refresh has no await", not refresh.contains("await"))


func step_one_field_roundtrip() -> void:
	await configure_and_party(["flamethrower", "tackle"], "mew", 40, 7, 9, 11, 13, 30)
	var collection: PlayerCollection = scene.field_collection()
	collection.inventory.add(&"ether", 2)
	collection.inventory.add(&"awakening", 1)
	collection.inventory.add(&"oran_berry", 2)
	var starter := owned(collection, &"own")
	starter.current_hp = starter.stats.max_hp - 17
	starter.moveset[0].current_pp = starter.moveset[0].max_pp - 2
	sleep_fixture(collection, &"reserve")
	scene._director._encounter_rng.state = 987654321
	scene._director._next_battle_seed = 43210
	scene.player.global_position = Vector2(420, 150)
	check("field fixture service opens", bag.open_bag() and bag.visible)
	var old_service: RefCounted = bag.service
	await close_bag()
	var old_collection := collection
	var old_trainer: TrainerCampaignRosterOwner = scene.field_trainer_owner()
	var old_session: RefCounted = scene._session
	var old_trainer_session: RefCounted = scene._trainer_session
	var old_clocks: Dictionary = bridge.clocks
	var old_tables: Dictionary = scene._director._tables
	var old_config := normalized_json(scene._active_config)
	var old_party := String(collection_state(collection).party)
	var old_inventory := String(collection_state(collection).inventory)
	var old_roster := roster_state(old_trainer)
	var old_clock_view := clocks_view(old_clocks)
	var capture_state: int = scene._capture_rng.state
	var escape_state: int = scene._escape_rng.state
	check("field fixture idle", bridge._idle_boundary())
	check("field save accepted", bridge.save_game())
	var envelope := read_envelope()
	check("field envelope format", envelope.get("format") == "calvo_field_native_v1" and envelope.get("schema") == 1)
	check("field envelope checksum", envelope.get("sha256") == JSON.stringify(envelope.get("payload")).sha256_text())
	var payload: Dictionary = envelope.get("payload", {})
	for key: String in ["collection", "world", "trainer", "sleep_clocks", "battle", "data_sha256", "policy_sha256"]:
		check("field envelope payload " + key, payload.has(key))
	check("field envelope data sha", payload.get("data_sha256") == FileAccess.get_sha256(Policy.DATA_PATH))
	check("field envelope policy sha", payload.get("policy_sha256") == FileAccess.get_sha256(Policy.CONFIG_PATH))
	check("field envelope empty battle", payload.get("battle") is Dictionary and payload.battle.is_empty())
	var world: Dictionary = payload.get("world", {})
	var world_keys: Array = world.keys(); world_keys.sort()
	check("field world keys", world_keys == ["config", "format", "next_seed", "position", "region", "rng"])
	check("field world position", world.get("position") == [420.0, 150.0])
	check("field world region", world.get("region") == String(scene.technical_region_id()))
	check("field world config", normalized_json(world.get("config")) == normalized_json(scene._active_config))
	check("field world rng", world.get("rng") == str(987654321))
	check("field world seed", world.get("next_seed") == 43210)
	check("field world format", world.get("format") == bridge.format_id)
	check("field envelope trainer", payload.get("trainer", {}).get("id") == String(old_trainer.trainer_id))
	check("field envelope trainer roster", payload.get("trainer", {}).get("roster", []).size() == old_trainer.roster_for_battle().size())
	check("field envelope sleep clock", payload.get("sleep_clocks", {}).has("reserve"))
	var decoded: Dictionary = bridge.saves.read(bridge.save_path, scene.field_definitions())
	check("field save decodes", bool(decoded.get("ok", false)))
	check("bridge tables delegation", tables_view(bridge._tables_for(scene._active_config)) == tables_view(reference_tables(scene._active_config)))

	var loaded: bool = await bridge.load_game()
	check("field load accepted", loaded)
	var current: PlayerCollection = scene.field_collection()
	check("field load publishes new collection", current != null and not is_same(current, old_collection) and is_same(current, scene._session.player))
	check("field load shares trainer session collection", is_same(scene._trainer_session.player, current))
	check("field load view collection", is_same(view.player, current))
	check("field load catalog identity", is_same(scene.field_definitions(), scene._catalogs))
	check("field load trainer replaced", not is_same(scene.field_trainer_owner(), old_trainer))
	check("field load trainer roster", roster_state(scene.field_trainer_owner()) == old_roster)
	check("field load retired session inactive", not is_same(scene._session, old_session) and not old_session.has_active_battle())
	check("field load retired trainer session inactive", not is_same(scene._trainer_session, old_trainer_session) and not old_trainer_session.has_active_battle())
	check("field load position", scene.field_player_position() == Vector2(420, 150))
	check("field load movement", scene.field_player_movement_enabled())
	check("field load config", normalized_json(scene._active_config) == old_config)
	check("field load panel", panel_view() == panel_for_config(world.config))
	check("field load rng", scene._director._encounter_rng.state == 987654321)
	check("field load seed", scene._director._next_battle_seed == 43210)
	check("field load capture rng untouched", scene._capture_rng.state == capture_state)
	check("field load escape rng untouched", scene._escape_rng.state == escape_state)
	check("field load director session", is_same(scene._director.session, scene._session))
	check("field load clocks identity replaced", not is_same(bridge.clocks, old_clocks))
	check("field load clocks content", clocks_view(bridge.clocks) == old_clock_view)
	check("field load tables identity replaced", not is_same(scene._director._tables, old_tables))
	expect_tables("field load tables", scene._director._tables, scene._active_config)
	check("field load collection content", collection_state(current).party == old_party)
	check("field load inventory content", collection_state(current).inventory == old_inventory)
	check("field load retired collection untouched", collection_state(old_collection).party == old_party and collection_state(old_collection).inventory == old_inventory)

	check("stale T005 service rejected", not scene.field_item_service_is_current(old_service))
	check("stale T005 guard", old_service._boundary() == "field_locked")
	var current_before := collection_state(current)
	var stale: Dictionary = old_service.use_item(&"potion", &"own")
	check("stale T005 use denied", not bool(stale.get("accepted", true)) and String(stale.get("reason", "")) == "field_locked")
	check("stale T005 current untouched", collection_state(current).party == current_before.party and collection_state(current).inventory == current_before.inventory)
	check("stale T005 retired untouched", collection_state(old_collection).party == old_party and collection_state(old_collection).inventory == old_inventory)
	check("T005 rebind accepted", scene.field_bind_item_service(old_service))
	check("T005 rebind owner", is_same(old_service.owner, current))
	check("T005 rebind catalog", is_same(old_service.catalogs, scene.field_definitions()))
	check("T005 rebind clocks", is_same(old_service.sleep_clocks, bridge.clocks))
	check("T005 rebind current", scene.field_item_service_is_current(old_service))
	var potions := quantity(current, &"potion")
	var old_potions := quantity(old_collection, &"potion")
	var hp := owned(current, &"own").current_hp
	var healed: Dictionary = old_service.use_item(&"potion", &"own")
	check("T005 rebound use accepted", bool(healed.get("accepted", false)))
	check("T005 rebound consumes once", quantity(current, &"potion") == potions - 1)
	check("T005 rebound heals current", owned(current, &"own").current_hp == mini(owned(current, &"own").stats.max_hp, hp + 20))
	check("T005 rebound leaves retired", quantity(old_collection, &"potion") == old_potions)


func step_two_load_failures() -> void:
	check("failure fixture idle", bridge._idle_boundary())
	check("failure fixture save", bridge.save_game())
	var good := FileAccess.get_file_as_bytes(bridge.save_path)
	check("failure fixture good bytes", not good.is_empty())
	var baseline_envelope := read_envelope()
	world_baseline = (baseline_envelope.payload.world as Dictionary).duplicate(true)
	check("failure fixture world baseline", not world_baseline.is_empty())

	var raw := FileAccess.open(bridge.save_path, FileAccess.WRITE)
	raw.store_string("{\"format\": \"bogus\", \"schema\": 1, \"payload\": {}}"); raw.close()
	await expect_load_failure("envelope", "field_save_format")

	var file := FileAccess.open(bridge.save_path, FileAccess.WRITE)
	file.store_buffer(good); file.close()
	var envelope := read_envelope()
	envelope.payload.world.position = [100, 100]
	write_envelope(envelope)
	await expect_load_failure("checksum", "field_save_checksum")

	for raw_region: Variant in [null, false, true, 1, 1.5, [], {}]:
		rewrite_world(func(w: Dictionary): w.region = raw_region)
		await expect_load_failure("world region type " + str(raw_region), "world_shape")
	rewrite_world(func(w: Dictionary): w.erase("region"))
	await expect_load_failure("world region missing", "world_shape")
	rewrite_world(func(w: Dictionary): w.position = [1])
	await expect_load_failure("world shape", "world_shape")
	rewrite_world(func(w: Dictionary): w.position = [1, 180])
	await expect_load_failure("world position bounds", "world_position")
	rewrite_world(func(w: Dictionary): w.position = [280, 180]; w.region = "surface")
	await expect_load_failure("world position collision", "world_position")
	rewrite_world(func(w: Dictionary): w.region = "cave")
	await expect_load_failure("world position region", "world_position")
	rewrite_world(func(w: Dictionary): w.next_seed = 0)
	await expect_load_failure("world seed", "world_seed")
	rewrite_world(func(w: Dictionary): w.next_seed = 1.5)
	await expect_load_failure("world seed fractional", "world_seed")
	rewrite_world(func(w: Dictionary): w.config.wild_min_level = 0)
	await expect_load_failure("world encounters", "world_encounters")
	rewrite_world(func(w: Dictionary): w.position = [1, 180]; w.next_seed = 0; w.config.wild_min_level = 0)
	await expect_load_failure("world position priority", "world_position")
	rewrite_world(func(w: Dictionary): w.next_seed = 0; w.config.wild_min_level = 0)
	await expect_load_failure("world seed priority", "world_seed")

	file = FileAccess.open(bridge.save_path, FileAccess.WRITE)
	file.store_buffer(good); file.close()
	var before_atomic := collection_state(scene.field_collection())
	var before_roster := roster_state(scene.field_trainer_owner())
	bridge.saves.serializer.rename_failure_inject = func(a: String, b: String):
		if a.ends_with(".tmp"): return ERR_CANT_CREATE
		return DirAccess.rename_absolute(ProjectSettings.globalize_path(a), ProjectSettings.globalize_path(b))
	check("atomic save failure rejected", not bridge.save_game())
	check("atomic failure keeps last good file", FileAccess.get_file_as_bytes(bridge.save_path) == good)
	bridge.saves.serializer.rename_failure_inject = Callable()
	check("last good file remains loadable", await bridge.load_game())
	check("atomic failure keeps inventory", collection_state(scene.field_collection()).inventory == before_atomic.inventory)
	check("atomic failure keeps trainer", roster_state(scene.field_trainer_owner()) == before_roster)
	check("post-failure field movement", scene.field_player_movement_enabled())

	var equal: Dictionary = bridge.clocks.duplicate(true)
	var current_clocks: Dictionary = bridge.clocks
	var current_service: RefCounted = bag.service
	check("equal clocks fixture", equal == current_clocks and not is_same(equal, current_clocks))
	bridge.clocks = equal
	check("equal clocks stale service", not scene.field_item_service_is_current(current_service))
	check("equal clocks stale guard", current_service._boundary() == "field_locked")
	var service_before := collection_state(scene.field_collection())
	var denied_equal: Dictionary = current_service.use_item(&"potion", &"own")
	check("equal clocks use denied", String(denied_equal.get("reason", "")) == "field_locked")
	check("equal clocks leaves collection", collection_state(scene.field_collection()).party == service_before.party)
	bridge.clocks = current_clocks
	check("equal clocks rebind", scene.field_bind_item_service(current_service))
	check("equal clocks rebind identity", is_same(current_service.sleep_clocks, bridge.clocks))


func step_three_candidate_failure() -> void:
	await configure_and_party(["reflect", "tackle"], "mew", 40)
	var collection: PlayerCollection = scene.field_collection()
	sleep_fixture(collection, &"reserve")
	await encounter()
	var saved: Dictionary = view.session.snapshot()
	check("battle checkpoint save", bridge.save_game())
	var good := FileAccess.get_file_as_bytes(bridge.save_path)
	var baseline_envelope := read_envelope()
	world_baseline = (baseline_envelope.payload.world as Dictionary).duplicate(true)
	var old_view_session: RefCounted = view.session
	var old_collection := collection
	var old_clocks: Dictionary = bridge.clocks
	var old_config := JSON.stringify(scene._active_config)
	var old_position: Vector2 = scene.field_player_position()
	check("world failure fixture has live battle", view.session.has_active_battle() and bridge.kind == "wild")
	rewrite_world(func(w: Dictionary): w.region = 1)
	await expect_load_failure("live battle region type", "world_shape")
	check("live battle region rejection keeps worker checkpoint", is_same(view.session, old_view_session) and view.session.has_active_battle() and view.session.snapshot() == saved)
	rewrite_world(func(w: Dictionary): w.position = [1, 180])
	await expect_load_failure("live battle world failure", "world_position")
	check("live battle preserved after world failure", is_same(view.session, old_view_session) and view.session.has_active_battle() and view.session.snapshot() == saved)
	check("live battle collection preserved after world failure", is_same(scene.field_collection(), old_collection))
	check("live battle clocks preserved after world failure", is_same(bridge.clocks, old_clocks))
	check("live battle config preserved after world failure", JSON.stringify(scene._active_config) == old_config)
	check("live battle position preserved after world failure", scene.field_player_position() == old_position)
	var action: Dictionary = await view.choose("move 1")
	check("old battle accepts after world failure", bool(action.get("accepted", false)))
	await drain()

	var file := FileAccess.open(bridge.save_path, FileAccess.WRITE)
	file.store_buffer(good); file.close()
	var checkpoint: Dictionary = view.session.snapshot()
	var before_candidate := state_view()
	rewrite_battle(func(b: Dictionary): b.adventure.campaign_stamp = "incompatible_contract_stamp")
	var rejected: bool = await bridge.load_game()
	check("candidate restore rejected", not rejected)
	check("candidate restore reason", bridge.last_error == "No se pudo cargar: adventure_snapshot_contract")
	check("candidate keeps old session", is_same(view.session, old_view_session))
	check("candidate keeps checkpoint", view.session.snapshot() == checkpoint)
	check("candidate keeps field sessions", is_same(scene._session, before_candidate.session) and is_same(scene._trainer_session, before_candidate.trainer_session))
	check("candidate keeps collection", is_same(scene.field_collection(), before_candidate.collection))
	check("candidate keeps trainer", is_same(scene.field_trainer_owner(), before_candidate.trainer))
	check("candidate keeps clocks", is_same(bridge.clocks, before_candidate.clocks_ref))
	check("candidate keeps config", JSON.stringify(scene._active_config) == before_candidate.config)
	check("candidate keeps position", scene.field_player_position() == before_candidate.position)
	check("candidate keeps kind", bridge.kind == before_candidate.kind and bridge.kind == "wild")
	check("candidate releases busy", not bridge.busy and not view._working)
	var after_candidate: Dictionary = await view.choose("move 1")
	check("old battle accepts after candidate failure", bool(after_candidate.get("accepted", false)))
	await drain()

	file = FileAccess.open(bridge.save_path, FileAccess.WRITE); file.store_buffer(good); file.close()
	check("good battle reload after candidate failure", await bridge.load_game())
	check("good battle reload snapshot", view.session.snapshot() == saved)
	check("good battle reload collection identity", is_same(view.session.player, scene.field_collection()))
	check("good battle shared clocks", is_same(bridge.clocks, view.session.native_sleep_clocks))
	var capture: Dictionary = await view.adventure_command("master")
	check("candidate failure cleanup capture", bool(capture.get("accepted", false))); await drain()
	check("candidate failure cleanup settled", view.session.completion_reason == "CAPTURED")
	check("candidate failure settled save", bridge.save_game())
	await bridge.leave_battle()
	check("candidate failure settled load", await bridge.load_game() and not bridge.occupied())


func step_four_wild_checkpoint() -> void:
	await configure_and_party(["flamethrower", "tackle"], "mew", 40)
	var collection: PlayerCollection = scene.field_collection()
	collection.inventory.add(&"master_ball", 1)
	sleep_fixture(collection, &"reserve")
	var starter := owned(collection, &"own")
	starter.current_hp = 20
	starter.status_state.clear_persistent()
	starter.status_state.persistent_id = &"burn"
	starter.moveset[0].current_pp = starter.moveset[0].max_pp - 4
	await encounter()
	check("wild battle has live worker", view.session._client != null and view.session._client.pid > 0)
	var potions := quantity(collection, &"potion")
	var starter_hp := starter.current_hp
	var active: CreatureInstance = view.session.battle_state().active_for_side(&"side_a")
	var hp_before := active.current_hp
	view.open_medicine_bag()
	for i in view._medicine_items.item_count:
		if view._medicine_items.get_item_metadata(i) == "potion": view._medicine_items.select(i)
	for i in view._medicine_targets.item_count:
		if view._medicine_targets.get_item_metadata(i) == "own": view._medicine_targets.select(i)
	view._refresh_medicine_moves()
	var medicine: Dictionary = await view.use_selected_medicine()
	check("wild medicine accepted", bool(medicine.get("accepted", false))); await drain()
	check("wild medicine staged until settlement", quantity(collection, &"potion") == potions)
	check("wild medicine shares session inventory", view.session.inventory.quantity(&"potion") == potions - 1)
	check("wild medicine heals battle copy", view.session.battle_state().active_for_side(&"side_a").current_hp > hp_before)
	check("wild medicine leaves live owner untouched", starter.current_hp == starter_hp)
	var saved: Dictionary = view.session.snapshot()
	var old_view_session: RefCounted = view.session
	var old_field_session: RefCounted = scene._session
	var old_trainer_session: RefCounted = scene._trainer_session
	var old_clocks: Dictionary = bridge.clocks
	var old_tables: Dictionary = scene._director._tables
	var old_party := String(collection_state(collection).party)
	var old_inventory := String(collection_state(collection).inventory)
	var opened_before := 0
	for entry: Dictionary in scene._recorder._entries:
		if entry.get("event") == "battle_opened": opened_before += 1
	check("wild checkpoint save", bridge.save_game())
	var envelope := read_envelope()
	check("wild envelope battle present", envelope.payload.battle is Dictionary and not envelope.payload.battle.is_empty())
	check("wild envelope battle kind", envelope.payload.battle.get("adventure", {}).get("kind") == "wild")
	check("wild checkpoint load", await bridge.load_game())
	check("wild load snapshot", view.session.snapshot() == saved)
	check("wild load new session", not is_same(view.session, old_view_session))
	check("wild load old session inactive", not old_view_session.has_active_battle())
	check("wild load field sessions retired", not is_same(scene._session, old_field_session) and not is_same(scene._trainer_session, old_trainer_session) and not old_field_session.has_active_battle() and not old_trainer_session.has_active_battle())
	check("wild load kind", bridge.kind == "wild" and view.session.battle_kind == "wild")
	check("wild load collection identity", is_same(scene.field_collection(), view.session.player) and is_same(scene._session.player, view.session.player))
	check("wild load view collection", is_same(view.player, scene.field_collection()))
	check("wild load shared clocks", is_same(bridge.clocks, view.session.native_sleep_clocks))
	check("wild load clocks content", clocks_view(bridge.clocks) == clocks_view(old_clocks))
	check("wild load tables", not is_same(scene._director._tables, old_tables) and tables_view(scene._director._tables) == tables_view(reference_tables(scene._active_config)))
	check("wild load collection content", collection_state(scene.field_collection()).party == old_party and collection_state(scene.field_collection()).inventory == old_inventory)
	check("wild load medicine persists once", view.session.inventory.quantity(&"potion") == potions - 1 and quantity(scene.field_collection(), &"potion") == potions)
	check("wild load old collection untouched", collection_state(collection).party == old_party and collection_state(collection).inventory == old_inventory)
	var opened_after := 0
	for entry: Dictionary in scene._recorder._entries:
		if entry.get("event") == "battle_opened": opened_after += 1
	check("wild load publishes one battle_opened", opened_after == opened_before + 1)
	check("wild load initial phase", view.session.phase() == "move")
	var enemy: CreatureInstance = view.session.battle_state().active_for_side(&"side_b") if view.session.battle_state() != null else null
	check("wild loaded enemy identity", enemy != null and not String(enemy.instance_id).is_empty())
	var enemy_id := String(enemy.instance_id) if enemy != null else ""
	var balls := quantity(scene.field_collection(), &"master_ball")
	var capture: Dictionary = await view.adventure_command("master")
	check("wild loaded capture accepted", bool(capture.get("accepted", false))); await drain()
	check("wild loaded capture settled once", view.session.completion_reason == "CAPTURED")
	check("wild loaded capture spent one ball", quantity(scene.field_collection(), &"master_ball") == balls - 1)
	var captured_ids := []
	for creature: CreatureInstance in scene.field_collection().party.get_creatures(): captured_ids.append(String(creature.instance_id))
	for creature: CreatureInstance in scene.field_collection().storage.get_all_creatures(): captured_ids.append(String(creature.instance_id))
	check("wild loaded capture routed once", captured_ids.size() == 3 and captured_ids.count(enemy_id) == 1 and captured_ids.count("own") == 1 and captured_ids.count("reserve") == 1)
	check("wild loaded capture identity", scene.field_collection().owned_creature(StringName(enemy_id)) != null)
	check("wild loaded capture applies staged item", quantity(scene.field_collection(), &"potion") == potions - 1)
	var settled_state := collection_state(scene.field_collection())
	var settled_balls := quantity(scene.field_collection(), &"master_ball")
	check("wild settled save", bridge.save_game())
	check("wild settled envelope has no battle", read_envelope().payload.battle.is_empty())
	await bridge.leave_battle()
	check("wild settled reload", await bridge.load_game() and not bridge.occupied())
	check("wild settle no double capture", collection_state(scene.field_collection()).party == settled_state.party and collection_state(scene.field_collection()).storage == settled_state.storage)
	check("wild settle no double ball", quantity(scene.field_collection(), &"master_ball") == settled_balls)
	check("wild settle no double item", quantity(scene.field_collection(), &"potion") == potions - 1)
	check("wild settle movement", scene.field_player_movement_enabled())


func step_five_trainer_checkpoint() -> void:
	await configure_and_party(["flamethrower"], "mew", 40)
	var opponent := mon("trainer_owned", "caterpie", 5, ["tackle"])
	check("trainer fixture owner", scene._trainer_campaign_owner.configure(scene.TECHNICAL_TRAINER_ID, [opponent] as Array[CreatureInstance]))
	check("trainer fixture starts", scene.start_demo_trainer_battle())
	while bridge.busy: await process_frame
	view._playback.set_process(false)
	check("trainer fixture active", bridge.kind == "trainer" and view.session.battle_kind == "trainer" and scene.has_active_demo_trainer_battle())
	var saved: Dictionary = view.session.snapshot()
	var old_view_session: RefCounted = view.session
	var old_owner: TrainerCampaignRosterOwner = scene._trainer_campaign_owner
	var old_roster := roster_state(old_owner)
	var old_collection: PlayerCollection = scene.field_collection()
	var old_collection_state := collection_state(old_collection)
	var xp_before: int = owned(old_collection, &"own").experience
	check("trainer checkpoint save", bridge.save_game())
	check("trainer checkpoint load", await bridge.load_game())
	check("trainer load snapshot", view.session.snapshot() == saved)
	check("trainer load kind", bridge.kind == "trainer" and view.session.battle_kind == "trainer")
	check("trainer load new owner", not is_same(scene._trainer_campaign_owner, old_owner))
	check("trainer load owner identity", is_same(scene._trainer_campaign_owner, view.session.trainer_owner) and scene._trainer_campaign_owner.trainer_id == old_owner.trainer_id)
	check("trainer load roster", roster_state(scene._trainer_campaign_owner) == old_roster)
	check("trainer load collection identity", is_same(scene.field_collection(), view.session.player) and is_same(scene._trainer_session.player, view.session.player))
	check("trainer load collection content", collection_state(scene.field_collection()).party == old_collection_state.party and collection_state(scene.field_collection()).inventory == old_collection_state.inventory)
	check("trainer load shared clocks", is_same(bridge.clocks, view.session.native_sleep_clocks))
	check("trainer load old session inactive", not old_view_session.has_active_battle())
	check("trainer load old collection untouched", collection_state(old_collection).party == old_collection_state.party and collection_state(old_collection).inventory == old_collection_state.inventory)
	var loaded_opponent: CreatureInstance = scene._trainer_campaign_owner.owned_creature(&"trainer_owned")
	check("trainer load opponent present", loaded_opponent != null and not loaded_opponent.is_knocked_out())
	check("trainer load roster size", scene._trainer_campaign_owner.roster_for_battle().size() == 1)
	check("trainer load xp baseline", owned(scene.field_collection(), &"own").experience == xp_before)
	var victory: Dictionary = await view.choose("move 1")
	check("trainer loaded move accepted", bool(victory.get("accepted", false))); await drain()
	check("trainer loaded victory", view.session.completion_reason == "VICTORY")
	var owner_creature: CreatureInstance = scene._trainer_campaign_owner.owned_creature(&"trainer_owned")
	check("trainer loaded owner KO", owner_creature != null and owner_creature.current_hp == 0)
	var xp_after: int = owned(scene.field_collection(), &"own").experience
	check("trainer loaded victory pays XP once", xp_after > xp_before)
	var settled_state := collection_state(scene.field_collection())
	var settled_roster := roster_state(scene._trainer_campaign_owner)
	check("trainer settled save", bridge.save_game())
	await bridge.leave_battle()
	check("trainer settled reload", await bridge.load_game() and not bridge.occupied())
	check("trainer settle no double XP", owned(scene.field_collection(), &"own").experience == xp_after)
	check("trainer settle no reset", collection_state(scene.field_collection()).party == settled_state.party and roster_state(scene.field_trainer_owner()) == settled_roster)
	check("trainer settle blocks restart", not scene.start_demo_trainer_battle())


func step_six_worker_recovery() -> void:
	await configure_and_party(["reflect", "tackle"], "mew", 40)
	await encounter()
	var saved: Dictionary = view.session.snapshot()
	var old_session: RefCounted = view.session
	OS.kill(view.session._client.pid); await create_timer(0.04).timeout
	check("dead worker rejects action", not (await view.choose("move 1")).accepted and view.session.needs_recovery)
	check("dead worker keeps checkpoint", view.session.snapshot() == saved)
	var opened_before := 0
	for entry: Dictionary in scene._recorder._entries:
		if entry.get("event") == "battle_opened": opened_before += 1
	check("real worker recovery", await bridge.recover_battle())
	check("recovery keeps checkpoint", view.session.snapshot() == saved)
	check("recovery replaces session", not is_same(view.session, old_session) and not old_session.has_active_battle())
	check("recovery shares clocks", is_same(bridge.clocks, view.session.native_sleep_clocks))
	var opened_after := 0
	for entry: Dictionary in scene._recorder._entries:
		if entry.get("event") == "battle_opened": opened_after += 1
	check("recovery publishes once", opened_after == opened_before + 1)
	check("recovered action accepted", (await view.choose("move 1")).accepted); await drain()
	view.session.busy = true
	check("busy session blocks save", not bridge.save_game())
	check("busy session blocks load", not await bridge.load_game())
	view.session.busy = false

	OS.kill(view.session._client.pid); await create_timer(0.04).timeout
	check("second dead worker rejects action", not (await view.choose("move 1")).accepted and view.session.needs_recovery)
	var checkpoint: Dictionary = view.session.snapshot()
	var rejected_session: RefCounted = view.session
	var collection: PlayerCollection = scene.field_collection()
	check("rejected recovery campaign fixture", collection.inventory.add(&"potion", 1))
	var rejected: bool = await bridge.recover_battle()
	check("rejected recovery refused", not rejected)
	check("rejected recovery keeps old session", is_same(view.session, rejected_session) and view.session.needs_recovery)
	check("rejected recovery keeps checkpoint", view.session.snapshot() == checkpoint)
	check("rejected recovery releases busy", not bridge.busy and not view._working)
	check("rejected recovery restores fixture", collection.inventory.remove(&"potion", 1))
	check("recovery after restore", await bridge.recover_battle() and view.session.snapshot() == checkpoint)
	check("recovered after rejected action", (await view.choose("move 1")).accepted); await drain()


func step_seven_guards() -> void:
	await configure_and_party(["reflect"], "mew", 40)
	bridge.busy = true
	check("busy blocks save", not bridge.save_game())
	check("busy blocks load", not await bridge.load_game())
	bridge.busy = false
	view._working = true
	check("working blocks save", not bridge.save_game())
	check("working blocks load", not await bridge.load_game())
	view._working = false
	view._playback._index = 0
	check("playback blocks save", not bridge.save_game())
	check("playback blocks load", not await bridge.load_game())
	view._playback._index = -1
	scene.test_panel._open_config()
	check("panel blocks save", not bridge.save_game())
	check("panel blocks load", not await bridge.load_game())
	scene.test_panel._close_config()
	scene.toggle_pokemon_gallery()
	check("gallery blocks save", not bridge.save_game())
	check("gallery blocks load", not await bridge.load_game())
	scene.toggle_pokemon_gallery()
	scene.traversal_controller._busy = true
	check("transition blocks save", not bridge.save_game())
	check("transition blocks load", not await bridge.load_game())
	scene.traversal_controller._busy = false
	scene.player.movement_enabled = false
	check("disabled movement blocks field save", not bridge.save_game())
	scene.player.movement_enabled = true
	check("guard fixture idle", bridge._idle_boundary())


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(600).timeout.connect(func():
		if not done:
			if view != null and view.session != null: view.session.stop_now()
			check("watchdog", false); finish())
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	bag = scene._item_bag
	check("native bridge available", bridge != null)
	if bridge == null:
		finish(); return
	view = bridge.view
	bridge.save_path = SAVE_PATH
	check("scene ready", scene.is_demo_ready())
	check("native profile", scene._native_battles != null)
	check("save path isolated", bridge.save_path == SAVE_PATH and SAVE_PATH.begins_with("res://.godot/field_restore_checks/"))
	check_architecture_limits()
	await step_one_field_roundtrip()
	await step_two_load_failures()
	await step_three_candidate_failure()
	await step_four_wild_checkpoint()
	await step_five_trainer_checkpoint()
	await step_six_worker_recovery()
	await step_seven_guards()
	await end_real_battle()
	finish()
