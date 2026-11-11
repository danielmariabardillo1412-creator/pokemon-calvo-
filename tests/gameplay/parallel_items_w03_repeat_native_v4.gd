extends SceneTree

## IA3/W03 TANDA04: independent L3 regression of full-party PC routing,
## no-stock rollback, and deterministic Repeat Ball checkpoint continuity.
## This tests real ShowdownAdventureSession.capture, not a mocked resolver.
var errors: Array[String] = []
var checks := 0
var scene: Node2D
var bridge: Node
var view: Control

func ck(label: String, yes: bool) -> void:
	checks += 1
	if not yes:
		errors.append(label)
		push_error("W03_REPEAT_NATIVE_V4: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _enter_grass() -> bool:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	return bridge != null and view.session != null and view.session.has_active_battle()

func _leave_captured_battle() -> void:
	if view._playback.is_playing():
		view._playback.set_process(false)
		var i := 0
		while view._playback.is_playing() and i < 200:
			view._playback.advance(0.5)
			i += 1
	if view.session != null and not view.session.has_active_battle():
		await bridge.leave_battle()

func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	ck("canonical catalog available", raw is Dictionary)
	if not raw is Dictionary:
		await _finish()
		return
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = "user://w03_repeat_native_v4.json"
	ck("field native session ready", scene.is_demo_ready() and bridge != null)
	if not scene.is_demo_ready():
		await _finish()
		return
	scene.player.set_physics_process(false)
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "pidgey"
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var initial_box_count := owner.storage.box_count()
	var rng := RandomNumberGenerator.new()
	rng.seed = 40104
	for i in 8:
		if owner.party.is_full():
			break
		var filler: CreatureInstance = CreatureFactory.create(scene._catalogs.species(&"mew"), 40, scene._catalogs, ProgressionRuleset.new(), rng,
			{"instance_id": StringName("w03v4_filler_%d" % i), "moves": ["tackle"], "nature_id": &"hardy"})
		filler.ability_id = &""
		ck("six-member native roster setup " + str(i), owner.party.add_creature(filler))
	ck("party genuinely full before wild battle", owner.party.is_full() and owner.party.size() == 6)
	ck("ledger is empty before first battle", owner.caught_base_species_ids.is_empty())
	ck("first native battle starts", await _enter_grass())
	if view.session == null or not view.session.has_active_battle():
		await _finish()
		return
	view._playback.set_process(false)
	view.session._capture_rng.seed = 41004
	var prior: Dictionary = view.session.snapshot()
	var original_rng: int = view.session._capture_rng.state
	var original_master := owner.inventory.quantity(&"master_ball")
	var original_party: Dictionary = owner.party.to_dict()
	var missing: Dictionary = view.session.capture(&"repeat_ball", view.session.revision)
	ck("no-stock Repeat rejected without changing checkpoint or RNG",
		not missing.get("accepted", false)
		and view.session.snapshot() == prior
		and view.session._capture_rng.state == original_rng
		and not owner.inventory.has(&"repeat_ball")
		and view.session.inventory.quantity(&"master_ball") == original_master)
	ck("no-stock preserves live party and caught ledger",
		owner.party.to_dict() == original_party and owner.caught_base_species_ids.is_empty())
	var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
	var target_id: StringName = target.instance_id
	var before_pc := owner.storage.get_all_creatures().size()
	var first: Dictionary = view.session.capture(&"master_ball", view.session.revision)
	ck("first native Master Ball capture committed",
		bool(first.get("accepted", false)) and view.session.completion_reason == "CAPTURED"
		and owner.inventory.quantity(&"master_ball") == original_master - 1)
	ck("full party routes captured identity to PC exactly once",
		bool(first.get("stored", false)) and owner.party.size() == 6
		and owner.storage.contains_instance_id(target_id)
		and owner.storage.get_all_creatures().size() == before_pc + 1
		and owner.location_of(target_id) == &"STORAGE")
	ck("successful PC capture records one canonical base species",
		owner.caught_base_species_ids == [&"pidgey"])
	ck("PC auto-allocation has no fixed storage ceiling",
		owner.storage.box_count() >= initial_box_count)
	await _leave_captured_battle()
	ck("Repeat Ball stock added between battles", owner.inventory.add(&"repeat_ball", 2))
	ck("first native battle saved to SaveV2", bridge.save_game())
	ck("settled save reloads ledger and storage", await bridge.load_game()
		and scene.field_collection().caught_base_species_ids == [&"pidgey"]
		and scene.field_collection().storage.contains_instance_id(target_id))
	owner = scene.field_collection()
	ck("second native encounter starts with persisted ledger", await _enter_grass())
	if view.session == null or not view.session.has_active_battle():
		await _finish()
		return
	view._playback.set_process(false)
	view.session._capture_rng.seed = 42004
	var before_checkpoint: Dictionary = view.session.snapshot()
	var before_rng: int = view.session._capture_rng.state
	var before_stock: int = owner.inventory.quantity(&"repeat_ball")
	ck("save active native fight before Repeat", bridge.save_game())
	ck("active native restore preserves seed, state and inventory",
		await bridge.load_game()
		and view.session != null and view.session.has_active_battle()
		and view.session.snapshot() == before_checkpoint
		and view.session._capture_rng.state == before_rng
		and scene.field_collection().inventory.quantity(&"repeat_ball") == before_stock)
	view._playback.set_process(false)
	owner = scene.field_collection()
	var second: Dictionary = view.session.capture(&"repeat_ball", view.session.revision)
	var outcome: Dictionary = second.get("capture_outcome", {}).get("capture", {})
	var result: Dictionary = outcome.get("result", {})
	ck("second native capture applies true prior-catch Repeat bonus",
		bool(second.get("accepted", false))
		and result.get("status") == String(CaptureResult.SUCCESS)
		and float(result.get("probability", 0.0)) >= 0.95)
	ck("Repeat spends exactly one and never duplicates base history",
		owner.inventory.quantity(&"repeat_ball") == before_stock - 1
		and owner.caught_base_species_ids == [&"pidgey"])
	ck("second full-party capture remains uniquely owned by PC",
		bool(second.get("stored", false)) and owner.party.size() == 6
		and owner.storage.get_all_creatures().size() == before_pc + 2)
	await _leave_captured_battle()
	ck("second settled native battle saves", bridge.save_game())
	ck("second settled save reloads same caught ledger",
		await bridge.load_game() and scene.field_collection().caught_base_species_ids == [&"pidgey"])
	await _finish()

func _finish() -> void:
	if view != null and view.session != null and view.session.has_active_battle():
		await view.session.close()
	if scene != null:
		scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://w03_repeat_native_v4.json"))
	if errors.is_empty():
		print("W03_REPEAT_NATIVE_V4 PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_REPEAT_NATIVE_V4 FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
