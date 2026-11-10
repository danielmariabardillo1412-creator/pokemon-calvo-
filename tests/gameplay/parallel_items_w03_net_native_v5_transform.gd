extends SceneTree

## W03 TANDA05 H07: switch to a different player party member, use real
## native Transform, and catch canonical Water with Net Ball (not display form).
var checks := 0
var errors: Array[String] = []
var scene: Node2D
var bridge: Node
var view: Control
const SAVE := "user://w03_net_native_v5_transform.json"

func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("W03_NET_NATIVE_V5_TRANSFORM: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _mon(id: StringName, moves: Array) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55005
	var c := CreatureFactory.create(scene._catalogs.species(&"mew"), 50, scene._catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": id, "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""
	return c

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("native map is ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish()
		return
	scene.player.set_physics_process(false)
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "goldeen"
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	owner.party = CreatureParty.new()
	ck("lead Mew registered", owner.party.add_creature(_mon(&"w03net_lead", ["reflect", "tackle"])))
	ck("reserve Transform Mew registered", owner.party.add_creature(_mon(&"w03net_transform", ["transform", "tackle"])))
	ck("native Net Ball stocked", owner.inventory.add(&"net_ball", 2))
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	ck("live Water encounter launched", view.session != null and view.session.has_active_battle())
	if view.session == null or not view.session.has_active_battle():
		await _finish()
		return
	view._playback.set_process(false)
	var catalog: CreatureSpecies = scene._catalogs.species(&"goldeen")
	ck("target canonical catalog is Water only", catalog.has_type(&"water") and not catalog.has_type(&"bug"))
	var initial_owner_species := owner.party.get_creature(&"w03net_transform").species_id
	var switch_response: Dictionary = await view.session.submit("switch 2", view.session.revision)
	ck("real native switch to reserve succeeded", bool(switch_response.get("accepted", false))
		and view.session.battle_state().active_for_side(&"side_a").instance_id == &"w03net_transform")
	var transform: Dictionary = await view.session.submit("move 1", view.session.revision)
	var shown: CreatureInstance = view.session.battle_state().active_for_side(&"side_a")
	ck("real native Transform executes after switch",
		bool(transform.get("accepted", false)) and shown != null
		and not shown.battle_transform_original.is_empty())
	ck("Transform does not change original owned Mew species",
		owner.party.get_creature(&"w03net_transform").species_id == initial_owner_species
		and initial_owner_species == &"mew")
	var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
	ck("native target remains original Water species after player Transform",
		target.base_species_id() == &"goldeen")
	var before_qty := owner.inventory.quantity(&"net_ball")
	var before_ledger := owner.caught_base_species_ids.duplicate()
	var attempted: Dictionary = await view.session.capture(&"net_ball", view.session.revision)
	var resolved: Dictionary = attempted.get("capture_outcome", {}).get("capture", {})
	var result: Dictionary = resolved.get("result", {})
	var expected := CaptureRuleset.new().catch_probability(catalog.capture_rate, 3.5,
		1.0, target.stats.max_hp, target.current_hp)
	ck("native Net capture after Transform uses canonical Water x3.5",
		bool(attempted.get("accepted", false))
		and result.get("status") == String(CaptureResult.SUCCESS)
		and is_equal_approx(float(result.get("probability", -1.0)), expected))
	ck("exactly one Net consumed and only actual Water base recorded",
		owner.inventory.quantity(&"net_ball") == before_qty - 1
		and owner.caught_base_species_ids == [&"goldeen"]
		and before_ledger.is_empty())
	ck("both player Mew identities retained after native settlement",
		owner.party.get_creature(&"w03net_lead").species_id == &"mew"
		and owner.party.get_creature(&"w03net_transform").species_id == &"mew")
	if view._playback.is_playing():
		view._playback.set_process(false)
		var n := 0
		while view._playback.is_playing() and n < 200:
			view._playback.advance(0.5)
			n += 1
	if view.session != null and not view.session.has_active_battle():
		await bridge.leave_battle()
	ck("native settled Transform+Net state saves", bridge.save_game())
	ck("SaveV2 roundtrip retains owner species, Net stock and Water ledger",
		await bridge.load_game()
		and scene.field_collection().party.get_creature(&"w03net_transform").species_id == &"mew"
		and scene.field_collection().inventory.quantity(&"net_ball") == before_qty - 1
		and scene.field_collection().caught_base_species_ids == [&"goldeen"])
	await _finish()

func _finish() -> void:
	if view != null and view.session != null:
		await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty():
		print("W03_NET_NATIVE_V5_TRANSFORM PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_NET_NATIVE_V5_TRANSFORM FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
