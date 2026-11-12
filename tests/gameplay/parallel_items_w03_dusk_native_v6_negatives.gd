extends SceneTree

# Independent W03 V6 negatives: actual cave producer, no fake is_cave switch.
var checks := 0
var errors: Array[String] = []
var scene: Node2D
var bridge: Node
var view: Control
const SAVE := "user://w03_dusk_native_v6_negatives.json"

func ck(label: String, valid: bool) -> void:
	checks += 1
	if not valid:
		errors.append(label)
		push_error("W03_DUSK_V6_NEG: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _done() -> void:
	if view != null and view.session != null: await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty() and checks > 0:
		print("W03_DUSK_V6_NEG PASS checks=" + str(checks) + " cave_source=live fail_rng=real")
		quit(0)
	else:
		print("W03_DUSK_V6_NEG FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("native field available", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _done()
		return
	scene.player.set_physics_process(false)
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "squirtle"
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.cave_min_level = 5
	config.cave_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	ck("Dusk stock available for negative", owner.inventory.add(&"dusk_ball", 2))
	var cave: Vector2 = scene.get_node("CaveEncounterZone").global_position
	var grass: Vector2 = scene.get_node("EncounterZone").global_position
	scene.player.global_position = cave
	ck("physical cave map", scene.zone_at_position(cave) == scene.TECHNICAL_CAVE_ZONE_ID)
	await scene._on_player_step_completed(cave)
	ck("real native cave battle begins", view.session != null and view.session.has_active_battle())
	if view.session == null or not view.session.has_active_battle():
		await _done()
		return
	view._playback.set_process(false)
	var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
	var sid: StringName = target.instance_id
	var species: CreatureSpecies = scene._catalogs.species(target.base_species_id())
	ck("canonical low-rate water target", target.base_species_id() == &"squirtle"
		and species.capture_rate > 0 and species.capture_rate < 255)
	var source: Callable = view.session._native_zone_source
	ck("live cave source bound", source.is_valid() and source.call() == scene.TECHNICAL_CAVE_ZONE_ID)
	ck("foreign target identity cannot bind verified source",
		not view.session.bind_native_field_source(source, &"not_the_original_target"))
	scene.player.global_position = grass
	ck("moving field owner invalidates stale cave source",
		source.call() == &"")
	scene.player.global_position = cave
	ck("restoring real position restores physical source", source.call() == scene.TECHNICAL_CAVE_ZONE_ID)
	var authored_cave_table: WildEncounterTable = scene._director._tables[scene.TECHNICAL_CAVE_ZONE_ID]
	scene._director._tables.erase(scene.TECHNICAL_CAVE_ZONE_ID)
	ck("removing real zone registration invalidates source",
		source.call() == &"")
	var expect := CaptureRuleset.new().catch_probability(species.capture_rate, 1.0, 1.0,
		target.stats.max_hp, target.current_hp)
	var ref_rng := RandomNumberGenerator.new()
	var selected_seed := -1
	for candidate in range(19000, 19100):
		ref_rng.seed = candidate
		if ref_rng.randf() > expect:
			selected_seed = candidate
			break
	ck("deterministic failure seed above honest 1x probability", selected_seed >= 19000)
	if selected_seed < 0:
		await _done()
		return
	view.session._capture_rng.seed = selected_seed
	var before_rng: int = view.session._capture_rng.state
	var before_live_stock := owner.inventory.quantity(&"dusk_ball")
	var before_ledger := owner.caught_base_species_ids.duplicate()
	var failed: Dictionary = await view.session.capture(&"dusk_ball", view.session.revision)
	var outcome: Dictionary = failed.get("capture_result", {})
	ck("missing producer applies 1x and uses actual native capture failure",
		bool(failed.get("accepted", false))
		and outcome.get("status", "") == String(CaptureResult.FAILED)
		and is_equal_approx(float(outcome.get("probability", -1.0)), expect))
	ck("failed ball only stages one stock and advances RNG",
		view.session.inventory.quantity(&"dusk_ball") == before_live_stock - 1
		and owner.inventory.quantity(&"dusk_ball") == before_live_stock
		and view.session._capture_rng.state != before_rng)
	ck("failed catch never writes live ownership or ledger",
		owner.caught_base_species_ids == before_ledger
		and owner.owned_creature(sid) == null)
	scene._director._tables[scene.TECHNICAL_CAVE_ZONE_ID] = authored_cave_table
	ck("registered source recovered without re-binding fake zone",
		source.call() == scene.TECHNICAL_CAVE_ZONE_ID)
	ck("mid-battle native SaveV2 after one failure", bridge.save_game())
	var expected_snapshot: Dictionary = view.session.snapshot()
	var save_bytes := FileAccess.get_file_as_string(SAVE)
	ck("SaveV2 excludes artificial dusk/cave bonus metadata",
		not save_bytes.contains("native_field_zone_id")
		and not save_bytes.contains("_native_zone_source")
		and not save_bytes.contains("is_cave"))
	ck("native restored battle retains spent stage, no live owner",
		await bridge.load_game()
		and view.session.has_active_battle()
		and view.session.snapshot() == expected_snapshot
		and view.session.inventory.quantity(&"dusk_ball") == before_live_stock - 1
		and scene.field_collection().owned_creature(sid) == null)
	ck("native restored Dusk origin is from real cave",
		view.session._native_zone_source.is_valid()
		and view.session._native_zone_source.call() == scene.TECHNICAL_CAVE_ZONE_ID)
	# Domain gate for trainer capture: independent of any ball's bonus.
	var trainer_context := CaptureBattleContext.new()
	trainer_context.is_wild = false
	trainer_context.target_side_id = &"side_b"
	ck("Dusk trainer capture rejected by ordinary CaptureSystem",
		CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"dusk_ball", trainer_context), scene._catalogs)
		== "trainer_battle_not_capturable")
	await _done()
