extends SceneTree

## W03 CONTINUOUS_V3: Moon Ball Gen VII+ on live canonical species, not
## family names. Two actual map -> native Showdown captures (one boosted, one
## neutral); authentic EvolutionRecord, real inventory, owner and SaveV2.
const Source = preload("res://modules/capture/capture_source_w03_v3.gd")
const SAVE := "user://w03_continuous_v3_moon.json"
const CASES: Array[Dictionary] = [
	{"species": &"clefairy", "bonus": 4.0, "evolves": true},
	{"species": &"goldeen", "bonus": 1.0, "evolves": false},
]
var checks := 0
var errors: Array[String] = []
var passed := 0
var scene: Node2D
var bridge: Node
var view: Control

func ck(label: String, yes: bool) -> void:
	checks += 1
	if not yes:
		errors.append(label)
		push_error("W03_V3_MOON: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _mon(id: StringName) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 102040
	var c := CreatureFactory.create(scene._catalogs.species(&"mew"), 50, scene._catalogs,
		ProgressionRuleset.new(), rng,
		{"instance_id": id, "moves": ["reflect", "tackle"], "nature_id": &"hardy"})
	c.ability_id = &""
	return c

func _seed_for(p: float, succeed: bool) -> int:
	var rng := RandomNumberGenerator.new()
	for candidate in range(99000, 119000):
		rng.seed = candidate
		if (rng.randf() < p) == succeed:
			return candidate
	return -1

func _enter() -> bool:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	if view.session != null and view.session.has_active_battle():
		view._playback.set_process(false)
		return true
	print("W03_V3_MOON_DIAG error=", bridge.last_error)
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

func _source_negatives() -> void:
	var definitions: DefinitionCatalog = scene._catalogs
	ck("Moon Stone item is a real catalog definition", definitions.item(&"moon_stone") != null)
	ck("Moon Ball itself is registered only after V3 authorization",
		CaptureRuleset.new().is_known_ball(&"moon_ball"))
	ck("Source profile pinned to modern Moon Stone semantics",
		Source.RULE_PROFILE == "moon_ball_gen7_plus_v1")
	var matched := 0
	for sid in [&"nidorina", &"nidorino", &"clefairy", &"jigglypuff", &"skitty", &"munna"]:
		var row: Dictionary = Source.moon_context(sid, definitions)
		ck(String(sid) + " authentic Moon Stone evolution valid",
			bool(row.get("ok", false)) and bool(row.get("eligible", false))
			and not String(row.get("version_group", "")).is_empty()
			and definitions.species(StringName(row.get("target_species", ""))) != null)
		if row.get("eligible", false): matched += 1
	ck("Six positive source species; no pre-evolution family shortcut", matched == 6)
	for sid in [&"clefable", &"wigglytuff", &"mewtwo", &"goldeen"]:
		var row: Dictionary = Source.moon_context(sid, definitions)
		ck(String(sid) + " is NOT boosted by its name/family/type",
			bool(row.get("ok", false)) and not bool(row.get("eligible", true)))
	ck("Unknown species provenance explicitly fails",
		not bool(Source.moon_context(&"w03_missing_species", definitions).get("ok", true)))
	ck("Missing catalog source explicitly fails",
		not bool(Source.moon_context(&"clefairy", null).get("ok", true)))
	var invalid := CaptureBattleContext.new()
	var target: CreatureInstance = _mon(&"w03v3_moon_untrusted")
	ck("Untrusted default Moon context rejects without a capture roll",
		CaptureSystem.validate_attempt(CaptureAttempt.new(target, &"moon_ball", invalid), definitions)
		== "capture_moon_stone_context_missing")
	invalid.moon_stone_context_known = true
	invalid.target_evolves_with_moon_stone = false
	ck("Explicit trusted negative case remains neutral",
		is_equal_approx(CaptureRuleset.ContextBallEffects.multiplier(
			&"moon_ball", target, definitions.species(&"mew"), invalid), 1.0))

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("native map and catalog ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _done()
		return
	scene.player.set_physics_process(false)
	_source_negatives()
	for case_data: Dictionary in CASES:
		var species_id: StringName = case_data.species
		var bonus: float = case_data.bonus
		var label: String = String(species_id)
		var cfg: Dictionary = scene._active_config.duplicate(true)
		cfg.wild_species_id = label
		cfg.wild_min_level = 5
		cfg.wild_max_level = 5
		cfg.encounter_chance_percent = 100
		scene._on_configuration_applied(cfg)
		var owner: PlayerCollection = scene.field_collection()
		owner.party = CreatureParty.new()
		ck(label + " native player leader", owner.party.add_creature(_mon(StringName("w03v3_" + label))))
		owner.inventory.set_quantity(&"moon_ball", 3)
		ck(label + " real owned Moon Balls stock 3", owner.inventory.quantity(&"moon_ball") == 3)
		ck(label + " native wild map encounter starts", await _enter())
		if view.session == null or not view.session.has_active_battle():
			continue
		var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
		var target_id: StringName = target.instance_id
		var canonical: CreatureSpecies = scene._catalogs.species(species_id)
		var context: Dictionary = Source.moon_context(target.base_species_id(), scene._catalogs)
		ck(label + " genuinely canonical target species", canonical != null
			and target.base_species_id() == species_id and target.level == 5
			and bool(context.get("ok", false))
			and bool(context.get("eligible", not case_data.evolves)) == bool(case_data.evolves))
		var expected: float = CaptureRuleset.new().catch_probability(
			canonical.capture_rate, bonus, 1.0, target.stats.max_hp, target.current_hp)
		ck(label + " independent 4x/1x catch odds are nontrivial",
			expected > 0.0 and expected < 1.0)
		var fail_seed := _seed_for(expected, false)
		var success_seed := _seed_for(expected, true)
		ck(label + " both real success and failed RNG seeds", fail_seed > 0 and success_seed > 0)
		# Negative capture genuinely passes through the native reaction before a
		# successful second throw. Owner stock is staged until battle settlement.
		if label == "clefairy":
			view.session._capture_rng.seed = fail_seed
			var failed: Dictionary = await view.session.capture(&"moon_ball", view.session.revision)
			var result_fail: Dictionary = failed.get("capture_outcome", {}).get("capture", {}).get("result", {})
			ck("Moon x4 native RNG failure spends one staged ball without ownership",
				bool(failed.get("accepted", false))
				and result_fail.get("status", "") == String(CaptureResult.FAILED)
				and is_equal_approx(float(result_fail.get("probability", -1.0)), expected)
				and view.session.inventory.quantity(&"moon_ball") == 2
				and owner.inventory.quantity(&"moon_ball") == 3
				and owner.caught_base_species_ids.is_empty())
			# After the failed reaction the enemy may have attacked/changed HP.
			target = view.session.battle_state().active_for_side(&"side_b")
			var updated_context: Dictionary = Source.moon_context(target.base_species_id(), scene._catalogs)
			ck("Moon evolution context survives genuine native reaction",
				bool(updated_context.get("ok", false)) and bool(updated_context.get("eligible", false)))
			expected = CaptureRuleset.new().catch_probability(
				canonical.capture_rate, bonus,
				CaptureRuleset.new().status_bonus(target.status_state.persistent_id),
				target.stats.max_hp, target.current_hp)
			success_seed = _seed_for(expected, true)
		view.session._capture_rng.seed = success_seed
		var stock_before: int = owner.inventory.quantity(&"moon_ball")
		var accepted: Dictionary = await view.session.capture(&"moon_ball", view.session.revision)
		var result: Dictionary = accepted.get("capture_outcome", {}).get("capture", {}).get("result", {})
		ck(label + " native Moon Ball correct 4x or 1x probability",
			bool(accepted.get("accepted", false))
			and result.get("status", "") == String(CaptureResult.SUCCESS)
			and is_equal_approx(float(result.get("probability", -1.0)), expected))
		var spent: int = 2 if label == "clefairy" else 1
		ck(label + " exactly spent attempts are committed and owner routes identity",
			owner.inventory.quantity(&"moon_ball") == stock_before - spent
			and owner.party.contains_instance_id(target_id)
			and owner.caught_base_species_ids == [species_id])
		await _leave()
		ck(label + " real native SaveV2 accepted", bridge.save_game())
		ck(label + " real Moon Ball owner and ledger survive SaveV2",
			await bridge.load_game()
			and scene.field_collection().inventory.quantity(&"moon_ball") == stock_before - spent
			and scene.field_collection().party.contains_instance_id(target_id)
			and scene.field_collection().caught_base_species_ids == [species_id])
		print("W03_V3_MOON_ROW species=" + label + " multiplier=" + str(bonus)
			+ " probability=" + str(expected) + " attempts=" + str(spent))
		passed += 1
	await _done()

func _done() -> void:
	if view != null and view.session != null: await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty() and passed == 2:
		print("W03_V3_MOON PASS native=2 checks=" + str(checks))
		quit(0)
	else:
		print("W03_V3_MOON FAIL native=" + str(passed)
			+ " checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
