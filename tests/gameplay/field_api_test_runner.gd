extends SceneTree

const Service = preload("res://modules/inventory/field_item_service.gd")
const OUT := "res://.godot/field_api_checks/"
const ACTIVITY_KEYS := [
	"native_available", "native_occupied", "traversal_busy", "panel_open",
	"gallery_open", "doubles_open", "bag_open", "can_configure",
	"can_use_items", "can_open_bag",
]

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
			"test_runner": FileAccess.get_sha256("res://tests/gameplay/field_api_test_runner.gd"),
		},
	}
	var file := FileAccess.open(OUT + ("api_legacy.json" if legacy else "api_native.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_API_CONTRACT ", report.status, " profile=", report.profile, " checks=", checks, " errors=", errors.size())
	if scene != null and is_instance_valid(scene): scene.queue_free()
	quit(0 if errors.is_empty() else 1)


func game_state() -> Dictionary:
	var collection: PlayerCollection = scene.field_collection()
	var creatures := []
	if collection != null:
		for creature: CreatureInstance in collection.party.get_creatures(): creatures.append(creature.to_dict())
	return {
		"inventory": JSON.stringify(collection.inventory.to_dict()) if collection != null else "",
		"party": JSON.stringify(creatures),
		"clocks": JSON.stringify(scene._native_battles.clocks) if scene._native_battles != null else "",
		"rng_encounter": scene._director._encounter_rng.state if scene._director != null else -1,
		"rng_capture": scene._capture_rng.state if scene._capture_rng != null else -1,
		"rng_escape": scene._escape_rng.state if scene._escape_rng != null else -1,
		"position": [scene.player.global_position.x, scene.player.global_position.y],
		"config": JSON.stringify(scene._active_config),
	}


func expect_unchanged(label: String, before: Dictionary) -> void:
	var after := game_state()
	for key: String in before:
		check(label + " " + key + " stable", after.get(key) == before.get(key))


func check_activity(label: String) -> void:
	var activity: Dictionary = scene.field_activity_snapshot()
	check(label + " exact keys", activity.size() == ACTIVITY_KEYS.size())
	for key: String in ACTIVITY_KEYS:
		check(label + " key " + key, activity.has(key))
		check(label + " bool " + key, activity.get(key) is bool)
	var native := scene._native_battles != null
	check(label + " native_available", activity.native_available == native)
	check(label + " native_occupied", activity.native_occupied == (native and scene._native_battles.occupied()))
	check(label + " traversal_busy", activity.traversal_busy == scene.traversal_is_busy())
	check(label + " panel_open", activity.panel_open == scene.test_panel.is_panel_open())
	check(label + " gallery_open", activity.gallery_open == (scene._pokemon_gallery != null and scene._pokemon_gallery.visible))
	check(label + " doubles_open", activity.doubles_open == (scene._doubles_demo != null and scene._doubles_demo.visible))
	check(label + " bag_open", activity.bag_open == (scene._item_bag != null and scene._item_bag.visible))
	check(label + " can_configure", activity.can_configure == scene.field_can_configure())
	check(label + " can_use_items", activity.can_use_items == scene.field_can_use_items())
	check(label + " can_open_bag", activity.can_open_bag == scene.field_can_open_item_bag())


func check_activity_is_copy(label: String) -> void:
	var first: Dictionary = scene.field_activity_snapshot()
	var second: Dictionary = scene.field_activity_snapshot()
	check(label + " new dictionary", not is_same(first, second))
	first["can_configure"] = not bool(first["can_configure"])
	first["native_available"] = not bool(first["native_available"])
	first.erase("can_open_bag")
	var third: Dictionary = scene.field_activity_snapshot()
	check(label + " mutation isolated can_configure", third.can_configure == second.can_configure)
	check(label + " mutation isolated native_available", third.native_available == second.native_available)
	check(label + " mutation isolated keys", third.size() == ACTIVITY_KEYS.size())


func check_preboot() -> void:
	var early: Node2D = load("res://scenes/visual/field_demo.gd").new()
	check("preboot collection null", early.field_collection() == null)
	check("preboot definitions null", early.field_definitions() == null)
	check("preboot can_configure false", not early.field_can_configure())
	check("preboot can_use_items false", not early.field_can_use_items())
	check("preboot can_open_bag false", not early.field_can_open_item_bag())
	var service := Service.new()
	check("preboot bind null false", not early.field_bind_item_service(null))
	check("preboot bind service false", not early.field_bind_item_service(service))
	check("preboot bind leaves service unbound", service.owner == null and service.sleep_clocks.is_empty())
	check("preboot is_current null false", not early.field_item_service_is_current(null))
	check("preboot is_current service false", not early.field_item_service_is_current(service))
	var activity: Dictionary = early.field_activity_snapshot()
	check("preboot activity keys", activity.size() == ACTIVITY_KEYS.size())
	for key: String in ACTIVITY_KEYS:
		check("preboot activity bool " + key, activity.get(key) is bool)
	check("preboot native unavailable", not bool(activity.native_available))
	check("preboot no bag", not bool(activity.can_open_bag))
	var encounter: Dictionary = early.field_encounter_snapshot()
	check("preboot encounter disabled", not bool(encounter.get("enabled", true)))
	check("preboot encounter region", encounter.get("region_id") is String and String(encounter.region_id) == "")
	early.field_show_notice("ignored")
	early.free()


func check_encounter_snapshot() -> void:
	var expected: Dictionary = scene.encounter_expectation()
	var snapshot: Dictionary = scene.field_encounter_snapshot()
	check("encounter snapshot new dictionary", not is_same(expected, snapshot))
	check("encounter snapshot adds one key", snapshot.size() == expected.size() + 1)
	for key: String in expected:
		check("encounter snapshot keeps " + key, snapshot.get(key) == expected.get(key))
	check("encounter snapshot region is String", snapshot.get("region_id") is String)
	check("encounter snapshot region matches", String(snapshot.region_id) == String(scene.technical_region_id()))
	var canary: Dictionary = scene.field_encounter_snapshot()
	snapshot["percent"] = 999
	snapshot["region_id"] = "mutated"
	canary = scene.field_encounter_snapshot()
	check("encounter snapshot mutation isolated percent", int(canary.get("percent", -1)) == int(expected.get("percent", -2)))
	check("encounter snapshot mutation isolated region", String(canary.region_id) == String(scene.technical_region_id()))


func check_identity_and_guards() -> void:
	var collection: PlayerCollection = scene.field_collection()
	check("collection is current session player", collection != null and is_same(collection, scene._session.player))
	check("definitions are current catalog", is_same(scene.field_definitions(), scene._catalogs))
	check("collection repeated identity", is_same(scene.field_collection(), collection))
	check("definitions repeated identity", is_same(scene.field_definitions(), scene._catalogs))
	check("can_configure delegates", scene.field_can_configure() == scene._can_configure())
	check("can_use_items delegates", scene.field_can_use_items() == scene._can_use_field_items())
	var native := scene._native_battles != null
	check("can_open_bag native context", scene.field_can_open_item_bag() == (native and scene._can_configure() and not scene.test_panel.is_panel_open()))
	check_activity("idle")
	check_activity_is_copy("idle")

	scene.test_panel._open_config()
	check("panel open observed", scene.field_activity_snapshot().panel_open)
	check("panel can_configure still delegates", scene.field_can_configure() == scene._can_configure())
	check("panel blocks use", not scene.field_can_use_items())
	check("panel blocks bag", not scene.field_can_open_item_bag())
	check_activity("panel")
	scene.test_panel._close_config()

	scene.toggle_pokemon_gallery()
	check("gallery open observed", scene.field_activity_snapshot().gallery_open)
	check("gallery blocks configure", not scene.field_can_configure())
	check("gallery blocks use", not scene.field_can_use_items())
	check("gallery blocks bag", not scene.field_can_open_item_bag())
	check_activity("gallery")
	scene.toggle_pokemon_gallery()

	var notice_before: String = scene._notice_label.text
	var status_before: String = scene.status_label.text
	var recorder_before: int = scene._recorder.entry_count()
	scene.field_show_notice("T005 API notice")
	check("notice text applied", scene._notice_label.text == "T005 API notice")
	check("notice leaves status", scene.status_label.text == status_before)
	check("notice leaves recorder", scene._recorder.entry_count() == recorder_before)
	scene.field_show_notice(notice_before)
	check("notice restored", scene._notice_label.text == notice_before)

	var frequency_before: String = scene._frequency_label.text
	var observed_before: String = scene._observed_label.text
	var collection_before: String = scene._collection_label.text
	var place_before: String = scene._place_label.text
	var chance_before: String = scene._chance_button.text
	var state_before := game_state()
	scene.field_refresh_hud()
	check("hud refresh frequency stable", scene._frequency_label.text == frequency_before)
	check("hud refresh observed stable", scene._observed_label.text == observed_before)
	check("hud refresh collection stable", scene._collection_label.text == collection_before)
	check("hud refresh place stable", scene._place_label.text == place_before)
	check("hud refresh chance stable", scene._chance_button.text == chance_before)
	expect_unchanged("hud refresh", state_before)

	var movement_before: bool = scene.player.movement_enabled
	scene.player.movement_enabled = true
	scene.field_item_bag_opened()
	check("bag opened locks movement", not scene.player.movement_enabled)
	scene.player.movement_enabled = movement_before

	var reset_collection: PlayerCollection = scene.field_collection()
	var reset_clocks = scene._native_battles.clocks if native else null
	scene.restart_field_run()
	check("restart publishes new collection", not is_same(scene.field_collection(), reset_collection))
	check("restart getter follows session", is_same(scene.field_collection(), scene._session.player))
	check("restart definitions current", is_same(scene.field_definitions(), scene._catalogs))
	if native:
		check("restart keeps clocks identity", is_same(scene._native_battles.clocks, reset_clocks))
		check("restart cleared clocks", scene._native_battles.clocks.is_empty())
	check("restart can_configure true", scene.field_can_configure())


func check_binding() -> void:
	var state_before := game_state()
	var collection: PlayerCollection = scene.field_collection()
	var definitions: DefinitionCatalog = scene.field_definitions()
	var service := Service.new()
	check("binding null rejected", not scene.field_bind_item_service(null))
	check("binding plain object rejected", not scene.field_bind_item_service(RefCounted.new()))
	if scene._native_battles == null:
		check("legacy binding rejected without native context", not scene.field_bind_item_service(service))
		check("legacy binding leaves owner null", service.owner == null)
		check("legacy binding leaves clocks empty", service.sleep_clocks.is_empty())
		check("legacy service not current", not scene.field_item_service_is_current(service))
		check("legacy bag remains closed", not scene.field_can_open_item_bag())
		expect_unchanged("legacy binding", state_before)
		return

	var clocks: Dictionary = scene._native_battles.clocks
	check("native binding accepted", scene.field_bind_item_service(service))
	check("binding owner identity", is_same(service.owner, collection))
	check("binding catalog identity", is_same(service.catalogs, definitions))
	check("binding clocks identity", is_same(service.sleep_clocks, clocks))
	check("binding guard set", service.guard.is_valid())
	check("binding guard does not capture service", not is_same(service.guard.get_object(), service))
	check("binding current", scene.field_item_service_is_current(service))
	check("binding idle boundary", service._boundary() == "")
	check("unconfigured service not current", not scene.field_item_service_is_current(Service.new()))
	check("null service not current", not scene.field_item_service_is_current(null))

	scene.test_panel._open_config()
	check("binding sees live panel guard", service._boundary() == "field_locked")
	check("binding identity survives panel", scene.field_item_service_is_current(service))
	scene.test_panel._close_config()
	check("binding recovers after panel", service._boundary() == "")

	scene.toggle_pokemon_gallery()
	check("binding sees live gallery guard", service._boundary() == "field_locked")
	scene.toggle_pokemon_gallery()
	check("binding recovers after gallery", service._boundary() == "")

	var real_clocks: Dictionary = scene._native_battles.clocks
	var equal_content: Dictionary = real_clocks.duplicate(true)
	scene._native_battles.clocks = equal_content
	check("equal clocks content", equal_content == real_clocks)
	check("equal clocks distinct identity", not is_same(equal_content, real_clocks))
	check("equal clocks reject stale link", not scene.field_item_service_is_current(service))
	check("equal clocks stale guard", service._boundary() == "field_locked")
	check("stale clocks untouched", service.sleep_clocks == real_clocks and is_same(service.sleep_clocks, real_clocks))
	check("rebind with current clocks", scene.field_bind_item_service(service))
	check("rebind clocks identity", is_same(service.sleep_clocks, scene._native_battles.clocks))
	check("rebind restores guard", service._boundary() == "")
	check("rebind current", scene.field_item_service_is_current(service))

	expect_unchanged("binding side effects", state_before)


func check_repeated_reads() -> void:
	var before := game_state()
	for index in 5:
		check("repeat " + str(index) + " collection", scene.field_collection() != null)
		check("repeat " + str(index) + " definitions", scene.field_definitions() != null)
		scene.field_can_configure()
		scene.field_can_use_items()
		scene.field_can_open_item_bag()
		scene.field_activity_snapshot()
		scene.field_encounter_snapshot()
		scene.field_refresh_hud()
	expect_unchanged("repeated reads", before)


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
	check("native profile matches bridge", (scene._native_battles != null) != legacy)
	check_identity_and_guards()
	check_encounter_snapshot()
	check_binding()
	check_repeated_reads()
	scene.queue_free()
	await process_frame
	finish()
