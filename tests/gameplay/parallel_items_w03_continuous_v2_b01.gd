extends SceneTree

## IA3/W03 CONTINUOUS_V2 B01: ten existing ball IDs, one real field/native
## WildEncounterSystem -> Showdown capture for each. Deterministic seed is
## chosen by the harness, never a fabricated capture resolution.
const IDS: Array[StringName] = [
	&"poke_ball", &"great_ball", &"ultra_ball", &"master_ball",
	&"nest_ball", &"fast_ball", &"dream_ball", &"heal_ball",
	&"premier_ball", &"friend_ball"
]
const SAVE := "user://w03_continuous_v2_b01.json"
var checks := 0
var errors: Array[String] = []
var scene: Node2D
var bridge: Node
var view: Control
var audited := 0
var captured := 0

func ck(label: String, yes: bool) -> void:
	checks += 1
	if not yes:
		errors.append(label)
		push_error("W03_CONT_V2_B01: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _mon(id: StringName) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 62001
	var c := CreatureFactory.create(scene._catalogs.species(&"mew"), 50,
		scene._catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": id, "moves": ["spore", "tackle"], "nature_id": &"hardy"})
	c.ability_id = &""
	return c

func _encounter() -> bool:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	if view.session != null and view.session.has_active_battle():
		view._playback.set_process(false)
		return true
	print("W03_CONT_V2_B01_DIAG error=", bridge.last_error, " zone=",
		scene.field_note_native_step(scene.player.global_position))
	return false

func _leave_captured() -> void:
	if view._playback.is_playing():
		view._playback.set_process(false)
		var n := 0
		while view._playback.is_playing() and n < 200:
			view._playback.advance(0.5)
			n += 1
	if view.session != null and not view.session.has_active_battle():
		await bridge.leave_battle()

func _seed_for(p: float, want_success: bool) -> int:
	var probe := RandomNumberGenerator.new()
	for candidate in range(62001, 67001):
		probe.seed = candidate
		if (probe.randf() < p) == want_success:
			return candidate
	return -1

func _expected_multiplier(id: StringName, target: CreatureInstance) -> float:
	match id:
		&"great_ball": return 1.5
		&"ultra_ball": return 2.0
		&"nest_ball": return maxf(1.0, (41.0 - target.level) / 10.0)
		&"dream_ball": return 4.0 if target.status_state.persistent_id == &"sleep" else 1.0
	return 1.0

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("real native field is ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish()
		return
	scene.player.set_physics_process(false)
	for i in IDS.size():
		var id: StringName = IDS[i]
		var name := String(id)
		var config: Dictionary = scene._active_config.duplicate(true)
		config.wild_species_id = "goldeen"
		config.wild_min_level = 5
		config.wild_max_level = 5
		config.encounter_chance_percent = 100
		scene._on_configuration_applied(config)
		var owner: PlayerCollection = scene.field_collection()
		owner.party = CreatureParty.new()
		ck(name + " create real Mew leader", owner.party.add_creature(_mon(StringName("w03v2_b01_" + name))))
		owner.inventory.set_quantity(id, 3)
		# Each ball is checked without stock in the PREVIOUS row. No test
		# changes inventory after a native encounter has begun.
		var absent_id: StringName = IDS[(i + 1) % IDS.size()]
		owner.inventory.set_quantity(absent_id, 0)
		ck(name + " stock 3 and next ID unowned", owner.inventory.quantity(id) == 3
			and owner.inventory.quantity(absent_id) == 0)
		var definition: CaptureBallDefinition = CaptureRuleset.new().ball(id)
		ck(name + " registered ball and real catalog item", definition != null
			and scene._catalogs.item(id) != null)
		ck(name + " native Goldeen encounter", await _encounter())
		if view.session == null or not view.session.has_active_battle():
			continue
		var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
		var species: CreatureSpecies = scene._catalogs.species(target.base_species_id())
		var target_id: StringName = target.instance_id
		ck(name + " canonical wild target", target.base_species_id() == &"goldeen"
			and species != null and target.level == 5)
		var before_absent_rng: int = view.session._capture_rng.state
		var before_owner: Dictionary = owner.party.to_dict()
		var absent: Dictionary = view.session.capture(absent_id, view.session.revision)
		ck(String(absent_id) + " genuine out-of-stock attempt is rejected",
			not bool(absent.get("accepted", false))
			and view.session._capture_rng.state == before_absent_rng
			and owner.inventory.quantity(absent_id) == 0
			and view.session.has_active_battle()
			and owner.party.to_dict() == before_owner)
		if id in [&"dream_ball", &"heal_ball"]:
			var sleep_result: Dictionary = await view.session.submit("move 1", view.session.revision)
			target = view.session.battle_state().active_for_side(&"side_b")
			ck(name + " Spore applied by real native battle", bool(sleep_result.get("accepted", false))
				and target.status_state.persistent_id == &"sleep")
		var mult := _expected_multiplier(id, target)
		var status_mult := CaptureRuleset.new().status_bonus(target.status_state.persistent_id)
		var p := CaptureRuleset.new().catch_probability(species.capture_rate, mult, status_mult,
			target.stats.max_hp, target.current_hp)
		ck(name + " independently expected capture odds",
			p > 0.0 and p <= 1.0
			and is_equal_approx(definition.base_multiplier
				* CaptureRuleset.BallEffects.multiplier(id, target, species), mult))
		var before_stock := owner.inventory.quantity(id)
		var before_friendship := target.friendship
		var seed := 0
		if not definition.guaranteed:
			seed = _seed_for(p, true)
		ck(name + " reproducible real success seed", definition.guaranteed or seed > 0)
		view.session._capture_rng.seed = seed if seed > 0 else 62001
		var capture_rng_before: int = view.session._capture_rng.state
		var response: Dictionary = await view.session.capture(id, view.session.revision)
		var outcome: Dictionary = response.get("capture_outcome", {}).get("capture", {}).get("result", {})
		ck(name + " native capture succeeded with real RNG/guaranteed profile",
			bool(response.get("accepted", false))
			and outcome.get("status", "") == String(CaptureResult.SUCCESS)
			and is_equal_approx(float(outcome.get("probability", -1.0)), 0.0 if definition.guaranteed else p))
		ck(name + " Master bypasses RNG; other balls draw",
			(view.session._capture_rng.state == capture_rng_before) == definition.guaranteed)
		ck(name + " exactly one stock unit spent and owned party contains captured identity",
			owner.inventory.quantity(id) == before_stock - 1
			and owner.party.contains_instance_id(target_id)
			and owner.party.size() == 2
			and owner.location_of(target_id) == &"PARTY")
		ck(name + " base caught ledger has one Goldeen", owner.caught_base_species_ids == [&"goldeen"])
		var caught: CreatureInstance = owner.owned_creature(target_id)
		ck(name + " real captured creature keeps canonical species", caught != null
			and caught.base_species_id() == &"goldeen")
		if caught != null:
			if id == &"friend_ball":
				ck("Friend Ball sets 200 instead of previous friendship",
					caught.friendship == 200 and before_friendship != 200)
			if id == &"heal_ball":
				ck("Heal Ball cures native sleep, HP and PP",
					caught.status_state.persistent_id == &""
					and caught.current_hp == caught.stats.max_hp
					and caught.moveset.all(func(slot: BattleMoveSlot): return slot.current_pp == slot.max_pp))
			if id == &"dream_ball":
				ck("Dream Ball captures a genuinely sleeping target",
					caught.status_state.persistent_id == &"sleep" and mult == 4.0)
		await _leave_captured()
		ck(name + " real native settled SaveV2 writes", bridge.save_game())
		ck(name + " SaveV2 restores owner, stock and base ledger",
			await bridge.load_game()
			and scene.field_collection().party.contains_instance_id(target_id)
			and scene.field_collection().inventory.quantity(id) == before_stock - 1
			and scene.field_collection().caught_base_species_ids == [&"goldeen"])
		print("W03_CONT_V2_B01_ROW id=" + name + " native=true expected_multiplier=" + str(mult)
			+ " seed=" + str(seed) + " probability=" + str(p))
		audited += 1
		if response.get("accepted", false) and outcome.get("status", "") == String(CaptureResult.SUCCESS):
			captured += 1
	await _finish()

func _finish() -> void:
	if view != null and view.session != null: await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty() and audited == 10 and captured == 10:
		print("W03_CONT_V2_B01 PASS ids=10 captured=10 checks=" + str(checks))
		quit(0)
	else:
		print("W03_CONT_V2_B01 FAIL ids=" + str(audited) + " captured=" + str(captured)
			+ " checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
