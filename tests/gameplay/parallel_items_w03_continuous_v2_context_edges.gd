extends SceneTree

## W03 CONTINUOUS_V2: three genuinely native conditional ball branches not
## distinguishable from neutral multiplier at a generic Goldeen encounter:
## Fast on native speedy Mewtwo, Quick AFTER Reflect turn, uncapped Level on
## native low-catch-rate Mewtwo. Do not silently count as new item IDs.
const SAVE := "user://w03_continuous_v2_edges.json"
const CASES: Array[Dictionary] = [
	{"ball": &"fast_ball", "wild": &"mewtwo", "mult": 4.0, "turn": 0},
	{"ball": &"quick_ball", "wild": &"goldeen", "mult": 1.0, "turn": 1},
	{"ball": &"level_ball", "wild": &"mewtwo", "mult": 8.0, "turn": 0}
]
var checks := 0
var errors: Array[String] = []
var passed := 0
var scene: Node2D
var bridge: Node
var view: Control

func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("W03_V2_CONTEXT_EDGES: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _mon(id: StringName) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 654321
	var c := CreatureFactory.create(scene._catalogs.species(&"mew"), 50, scene._catalogs,
		ProgressionRuleset.new(), rng, {"instance_id": id,
		"moves": ["reflect", "tackle"], "nature_id": &"hardy"})
	c.ability_id = &""
	return c

func _seed_for(p: float) -> int:
	var rng := RandomNumberGenerator.new()
	for candidate in range(71000, 101000):
		rng.seed = candidate
		if rng.randf() < p:
			return candidate
	return -1

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
		var n := 0
		while view._playback.is_playing() and n < 200:
			view._playback.advance(0.5)
			n += 1
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
	ck("native map boots", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _done()
		return
	scene.player.set_physics_process(false)
	for case_data: Dictionary in CASES:
		var ball: StringName = case_data.ball
		var sid: StringName = case_data.wild
		var label := String(ball) + "/" + String(sid)
		var config: Dictionary = scene._active_config.duplicate(true)
		config.wild_species_id = String(sid)
		config.wild_min_level = 5
		config.wild_max_level = 5
		config.encounter_chance_percent = 100
		scene._on_configuration_applied(config)
		var owner: PlayerCollection = scene.field_collection()
		owner.party = CreatureParty.new()
		ck(label + " real level-50 catcher", owner.party.add_creature(_mon(StringName("w03_v2_edges_" + String(ball)))))
		owner.inventory.set_quantity(ball, 2)
		var species: CreatureSpecies = scene._catalogs.species(sid)
		ck(label + " real catalog species and target speed",
			species != null and (ball != &"fast_ball" or species.base_speed >= 100)
			and (ball != &"level_ball" or species.capture_rate <= 45))
		ck(label + " live native WildEncounterSystem starts",
			await _encounter())
		if view.session == null or not view.session.has_active_battle():
			continue
		var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
		var captured_id: StringName = target.instance_id
		ck(label + " canonical target identity", target.base_species_id() == sid
			and target.level == 5)
		if ball == &"quick_ball":
			var action: Dictionary = await view.session.submit("move 1", view.session.revision)
			ck("Quick Ball later-turn native Reflect accepted", bool(action.get("accepted", false))
				and view.session.battle_state().turn >= 1)
			target = view.session.battle_state().active_for_side(&"side_b")
		var context := CaptureBattleContext.new()
		context.completed_turns = view.session.battle_state().turn
		var catcher: CreatureInstance = view.session.battle_state().active_for_side(&"side_a")
		context.catcher_level = catcher.level
		context.previously_caught_base_species = owner.has_previously_caught(target.base_species_id(), scene._catalogs)
		var expected_multiplier := float(case_data.mult)
		var actual_multiplier := CaptureRuleset.new().ball(ball).base_multiplier
		actual_multiplier *= CaptureRuleset.BallEffects.multiplier(ball, target, species)
		actual_multiplier *= CaptureRuleset.ContextBallEffects.multiplier(ball, target, species, context)
		ck(label + " 4x/1x/8x native context not neutralized by rate cap",
			is_equal_approx(actual_multiplier, expected_multiplier)
			and (ball != &"quick_ball" or context.completed_turns > 0)
			and (ball != &"level_ball" or context.catcher_level >= target.level * 4))
		var expected_p := CaptureRuleset.new().catch_probability(species.capture_rate,
			expected_multiplier, CaptureRuleset.new().status_bonus(target.status_state.persistent_id),
			target.stats.max_hp, target.current_hp)
		ck(label + " expected probability nontrivial and RNG required", expected_p > 0.0 and expected_p < 1.0)
		var seed := _seed_for(expected_p)
		ck(label + " deterministic success RNG seed exists", seed > 0)
		view.session._capture_rng.seed = seed if seed > 0 else 71000
		var prev_qty := owner.inventory.quantity(ball)
		var response: Dictionary = await view.session.capture(ball, view.session.revision)
		var result: Dictionary = response.get("capture_outcome", {}).get("capture", {}).get("result", {})
		ck(label + " actual native branch captures at expected probability",
			bool(response.get("accepted", false))
			and result.get("status", "") == String(CaptureResult.SUCCESS)
			and is_equal_approx(float(result.get("probability", -1.0)), expected_p))
		ck(label + " owned target and exactly one Ball spent",
			owner.inventory.quantity(ball) == prev_qty - 1
			and owner.party.contains_instance_id(captured_id)
			and owner.caught_base_species_ids == [sid])
		await _leave()
		ck(label + " native SaveV2 persists", bridge.save_game())
		ck(label + " SaveV2 loads original identity and stock",
			await bridge.load_game()
			and scene.field_collection().party.contains_instance_id(captured_id)
			and scene.field_collection().inventory.quantity(ball) == prev_qty - 1)
		print("W03_V2_CONTEXT_EDGE id=" + String(ball) + " wild=" + String(sid)
			+ " mult=" + str(expected_multiplier) + " p=" + str(expected_p) + " seed=" + str(seed))
		passed += 1
	await _done()

func _done() -> void:
	if view != null and view.session != null: await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty() and passed == 3:
		print("W03_V2_CONTEXT_EDGES PASS branches=3 checks=" + str(checks))
		quit(0)
	else:
		print("W03_V2_CONTEXT_EDGES FAIL branches=" + str(passed)
			+ " checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
