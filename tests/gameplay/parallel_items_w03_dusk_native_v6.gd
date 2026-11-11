extends SceneTree

# W03 V6: a real cave encounter travels through FieldDemo -> native Bridge ->
# ShowdownAdventureSession.capture. No manually injected is_cave flag or fake battle.
var checks := 0
var errors: Array[String] = []
var scene: Node2D
var bridge: Node
var view: Control
const SAVE := "user://w03_dusk_native_v6.json"

func ck(label: String, yes: bool) -> void:
	checks += 1
	if not yes:
		errors.append(label)
		push_error("W03_DUSK_V6: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _enter(place: Vector2, expected_zone: StringName) -> bool:
	scene.player.global_position = place
	ck("authored zone at genuine position " + String(expected_zone),
		scene.zone_at_position(place) == expected_zone)
	await scene._on_player_step_completed(place)
	return view.session != null and view.session.has_active_battle()

func _leave() -> void:
	if view._playback.is_playing(): view._playback.cancel()
	if view.session != null and not view.session.has_active_battle():
		await bridge.leave_battle()

func _cleanup() -> void:
	if view != null and view.session != null:
		await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty() and checks > 0:
		print("W03_DUSK_V6 PASS checks=" + str(checks) + " native=2 producer=real_cave_and_grass savev2=true")
		quit(0)
	else:
		print("W03_DUSK_V6 FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("technical field and native bridge ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _cleanup()
		return
	scene.player.set_physics_process(false)
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "pidgey"
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.cave_min_level = 5
	config.cave_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	ck("Dusk Ball registered in actual capture rules", CaptureRuleset.new().is_known_ball(&"dusk_ball"))
	ck("Dusk Ball stock acquired", owner.inventory.add(&"dusk_ball", 4))
	var cave: Vector2 = scene.get_node("CaveEncounterZone").global_position
	var grass: Vector2 = scene.get_node("EncounterZone").global_position
	ck("authored cave node and physical region", scene.technical_region_id() != &"cave"
		and scene.zone_at_position(cave) == scene.TECHNICAL_CAVE_ZONE_ID
		and scene.zone_at_position(grass) == scene.TECHNICAL_ZONE_ID)
	ck("first real native cave battle", await _enter(cave, scene.TECHNICAL_CAVE_ZONE_ID))
	if view.session == null or not view.session.has_active_battle():
		await _cleanup()
		return
	view._playback.set_process(false)
	var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
	var species: CreatureSpecies = scene._catalogs.species(target.base_species_id())
	ck("cave native target pidgey level 5", target != null and target.level == 5 and target.base_species_id() == &"pidgey")
	ck("real field origin callback gives cave (never test-injected flag)",
		view.session._native_zone_source.is_valid()
		and view.session._native_zone_source.call() == scene.TECHNICAL_CAVE_ZONE_ID)
	var source_id: StringName = target.instance_id
	var missing: Dictionary = view.session.capture(&"dusk_ball", view.session.revision + 1)
	ck("stale revision rejects without inventory or capture RNG loss",
		not missing.get("accepted", false) and owner.inventory.quantity(&"dusk_ball") == 4)
	ck("active native cave SaveV2", bridge.save_game())
	ck("active native cave SaveV2 restored", await bridge.load_game()
		and view.session != null and view.session.has_active_battle())
	view._playback.set_process(false)
	ck("restored native session derives cave from restored real world",
		view.session._native_zone_source.is_valid()
		and view.session._native_zone_source.call() == scene.TECHNICAL_CAVE_ZONE_ID)
	var restored_target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
	ck("restored cave target identity unchanged", restored_target != null and restored_target.instance_id == source_id)
	var rate: float = float(species.capture_rate) / 255.0
	var cave_expect: float = CaptureRuleset.new().catch_probability(species.capture_rate,
		3.0, 1.0, restored_target.stats.max_hp, restored_target.current_hp)
	view.session._capture_rng.seed = 120612
	var cave_capture: Dictionary = await view.session.capture(&"dusk_ball", view.session.revision)
	var cave_result: Dictionary = cave_capture.get("capture_outcome", {}).get("capture", {}).get("result", {})
	ck("real native cave uses exactly x3, does not just show metadata",
		cave_capture.get("accepted", false)
		and is_equal_approx(float(cave_result.get("probability", -1.0)), cave_expect)
		and cave_result.get("status", "") == String(CaptureResult.SUCCESS))
	ck("real cave success commits stock and ownership once",
		owner.inventory.quantity(&"dusk_ball") == 3
		and owner.location_of(source_id) != &""
		and owner.caught_base_species_ids.has(&"pidgey"))
	await _leave()
	ck("cave settled owner can save manually", bridge.save_game())
	ck("cave settled SaveV2 restores owner and stock", await bridge.load_game()
		and scene.field_collection().inventory.quantity(&"dusk_ball") == 3
		and scene.field_collection().owned_creature(source_id) != null)
	owner = scene.field_collection()
	ck("second real native grass battle", await _enter(grass, scene.TECHNICAL_ZONE_ID))
	if view.session == null or not view.session.has_active_battle():
		await _cleanup()
		return
	view._playback.set_process(false)
	var grass_target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
	ck("same species level and status on native grass", grass_target != null
		and grass_target.base_species_id() == &"pidgey" and grass_target.level == 5
		and grass_target.status_state.persistent_id == restored_target.status_state.persistent_id)
	ck("real field source callback does not claim cave in grass",
		view.session._native_zone_source.is_valid()
		and view.session._native_zone_source.call() == scene.TECHNICAL_ZONE_ID)
	var grass_expect: float = CaptureRuleset.new().catch_probability(species.capture_rate,
		1.0, 1.0, grass_target.stats.max_hp, grass_target.current_hp)
	var old_stock := owner.inventory.quantity(&"dusk_ball")
	view.session._capture_rng.seed = 120612
	var grass_capture: Dictionary = await view.session.capture(&"dusk_ball", view.session.revision)
	var grass_result: Dictionary = grass_capture.get("capture_outcome", {}).get("capture", {}).get("result", {})
	ck("genuine grass native x1 with same RNG, no cave bonus",
		grass_capture.get("accepted", false)
		and is_equal_approx(float(grass_result.get("probability", -1.0)), grass_expect)
		and cave_expect > grass_expect)
	ck("grass spends staged inventory once on accepted attempt",
		view.session.inventory.quantity(&"dusk_ball") == old_stock - 1)
	await _cleanup()
