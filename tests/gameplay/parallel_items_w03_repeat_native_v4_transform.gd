extends SceneTree

## IA3/W03 TANDA04 QA05/09: Transform is executed by the native worker
## before Repeat Ball; compare a real distinct-species native capture attempt.
var checks := 0
var errors: Array[String] = []
var scene: Node2D
var bridge: Node
var view: Control
const SAVE := "user://w03_repeat_native_v4_transform.json"

func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("W03_REPEAT_NATIVE_V4_TRANSFORM: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _set_encounter(species_id: String) -> void:
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = species_id
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)

func _encounter() -> bool:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	if view.session != null and view.session.has_active_battle():
		view._playback.set_process(false)
		return true
	return false

func _leave() -> void:
	if view._playback.is_playing():
		view._playback.set_process(false)
		var count := 0
		while view._playback.is_playing() and count < 200:
			view._playback.advance(0.5)
			count += 1
	if view.session != null and not view.session.has_active_battle():
		await bridge.leave_battle()

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("native map ready for Transform", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish()
		return
	scene.player.set_physics_process(false)
	_set_encounter("pidgey")
	var owner: PlayerCollection = scene.field_collection()
	owner.party = CreatureParty.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 45004
	var lead: CreatureInstance = CreatureFactory.create(scene._catalogs.species(&"mew"), 50, scene._catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"w03v4_transform_lead", "moves": ["transform", "tackle"], "nature_id": &"hardy"})
	lead.ability_id = &""
	ck("Mew can enter native battle with Transform", owner.party.add_creature(lead))
	ck("first Pidgey native encounter", await _encounter())
	if view.session == null or not view.session.has_active_battle():
		await _finish()
		return
	var first: Dictionary = view.session.capture(&"master_ball", view.session.revision)
	ck("first Pidgey captured with a genuine master ball",
		bool(first.get("accepted", false))
		and owner.caught_base_species_ids == [&"pidgey"])
	await _leave()
	ck("stock three Repeat Balls between encounters", owner.inventory.add(&"repeat_ball", 3))
	ck("save Pidgey ledger before Transform trial", bridge.save_game())
	ck("Pidgey ledger survives map reload", await bridge.load_game()
		and scene.field_collection().caught_base_species_ids == [&"pidgey"])
	owner = scene.field_collection()
	ck("second wild Pidgey battle opened", await _encounter())
	if view.session == null or not view.session.has_active_battle():
		await _finish()
		return
	var transform: Dictionary = await view.session.submit("move 1", view.session.revision)
	ck("real native Transform command accepted", bool(transform.get("accepted", false)))
	var transformed: CreatureInstance = view.session.battle_state().active_for_side(&"side_a")
	ck("native projection exposes temporary Transform, not a dummy move",
		transformed != null and not transformed.battle_transform_original.is_empty())
	ck("Transform does not mutate persistent owner before settlement",
		owner.party.get_creature(&"w03v4_transform_lead").species_id == &"mew")
	var before_repeat := owner.inventory.quantity(&"repeat_ball")
	var repeat: Dictionary = view.session.capture(&"repeat_ball", view.session.revision)
	var capture: Dictionary = repeat.get("capture_outcome", {}).get("capture", {}).get("result", {})
	ck("Repeat after native Transform uses captured target base species",
		bool(repeat.get("accepted", false))
		and capture.get("status") == String(CaptureResult.SUCCESS)
		and float(capture.get("probability", 0.0)) >= 0.95)
	ck("Transform/Repeat spends exactly one and records only Pidgey",
		owner.inventory.quantity(&"repeat_ball") == before_repeat - 1
		and owner.caught_base_species_ids == [&"pidgey"]
		and owner.party.get_creature(&"w03v4_transform_lead").species_id == &"mew")
	await _leave()
	ck("native Transform/Repeat state can be saved", bridge.save_game())
	ck("native Transform/Repeat restores original identity",
		await bridge.load_game() and scene.field_collection().caught_base_species_ids == [&"pidgey"]
		and scene.field_collection().party.get_creature(&"w03v4_transform_lead").species_id == &"mew")
	owner = scene.field_collection()
	_set_encounter("caterpie")
	ck("distinct-species wild battle opened", await _encounter())
	if view.session == null or not view.session.has_active_battle():
		await _finish()
		return
	var other: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
	var catalog_species: CreatureSpecies = scene._catalogs.species(&"caterpie")
	var expected := CaptureRuleset.new().catch_probability(catalog_species.capture_rate, 1.0, 1.0,
		other.stats.max_hp, other.current_hp)
	ck("distinct Caterpie not previously caught", owner.caught_base_species_ids == [&"pidgey"]
		and not owner.has_previously_caught(&"caterpie", scene._catalogs))
	var other_stock := owner.inventory.quantity(&"repeat_ball")
	var third: Dictionary = await view.session.capture(&"repeat_ball", view.session.revision)
	var third_capture: Dictionary = third.get("capture_outcome", {}).get("capture", {}).get("result", {})
	ck("distinct native species receives neutral x1 rather than x3.5",
		bool(third.get("accepted", false))
		and is_equal_approx(float(third_capture.get("probability", -1.0)), expected)
		and expected < 0.95)
	ck("distinct native attempt spends one ball in live or staged inventory",
		view.session.inventory.quantity(&"repeat_ball") == other_stock - 1)
	await _finish()

func _finish() -> void:
	if view != null and view.session != null:
		await view.session.close()
	if scene != null:
		scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty():
		print("W03_REPEAT_NATIVE_V4_TRANSFORM PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_REPEAT_NATIVE_V4_TRANSFORM FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
