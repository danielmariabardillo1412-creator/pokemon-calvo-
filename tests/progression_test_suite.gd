class_name ProgressionTestSuite
extends RefCounted

# FASE 6 tests: per-creature leveling, experience curves, derived stats, IV/EV/nature,
# learnsets, evolution, and the Battle -> Progression boundary. Depends only on the
# imported PokéAPI catalog (no battle simulation internals).

var _check: Callable
var _gd: GameData
var _catalog: DefinitionCatalog


func _init(game_data: GameData) -> void:
	_gd = game_data
	_catalog = game_data.to_definition_catalog()


func run(check_callback: Callable) -> void:
	_check = check_callback
	var tests := [
		"_test_xp_curve_known_values", "_test_xp_level_inverse", "_test_xp_level_cap",
		"_test_stat_calc_neutral", "_test_stat_calc_nature", "_test_hp_recalc_on_levelup",
		"_test_iv_clamp", "_test_ev_clamp", "_test_nature_modifiers",
		"_test_nature_catalog_canonical", "_test_nature_hp_unaffected",
		"_test_nature_modifiable_stats", "_test_nature_instance_field",
		"_test_nature_battle_uses_derived",
		"_test_factory_deterministic_seed", "_test_factory_unique_id", "_test_factory_initial_moves",
		"_test_learnset_queries", "_test_gain_learns_move", "_test_gain_move_choice_required",
		"_test_move_choice_replace", "_test_move_choice_decline",
		"_test_evolution_by_level", "_test_evolution_not_eligible_low_level",
		"_test_evolution_apply_preserves_identity", "_test_evolution_unsupported_deferred",
		"_test_serialization_round_trip", "_test_battle_outcome_from_state",
		"_test_battle_reconcile_grants_xp", "_test_pp_persisted", "_test_volatile_status_not_persisted",
		"_test_evolution_coverage_invariant", "_test_ruleset_policy_id",
	]
	for t in tests:
		print("PROG_TEST %s" % t)
		self.call(t)


func _rs() -> ProgressionRuleset:
	return ProgressionRuleset.new()


func _bulbasaur() -> CreatureSpecies:
	return _gd.species_catalog.get_by_id(&"bulbasaur")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


# --- XP curves ---------------------------------------------------------------

func _test_xp_curve_known_values() -> void:
	var rs := _rs()
	_check.call("xp_medium_l2", rs.experience_for_level("medium", 2) == 8)
	_check.call("xp_medium_l100", rs.experience_for_level("medium", 100) == 1000000)
	_check.call("xp_fast_l100", rs.experience_for_level("fast", 100) == 800000)
	_check.call("xp_slow_l100", rs.experience_for_level("slow", 100) == 1250000)
	_check.call("xp_medium_slow_l2", rs.experience_for_level("medium-slow", 2) == 9)
	var prev := -1
	var mono := true
	for n in range(1, 101):
		var v := rs.experience_for_level("medium", n)
		if v < prev:
			mono = false
		prev = v
	_check.call("xp_medium_monotonic", mono)


func _test_xp_level_inverse() -> void:
	var rs := _rs()
	_check.call("xp_inv_l2", rs.level_for_experience("medium", 8) == 2)
	_check.call("xp_inv_l1_zero", rs.level_for_experience("medium", 0) == 1)
	_check.call("xp_inv_l100", rs.level_for_experience("medium", 1000000) == 100)
	_check.call("xp_inv_l99", rs.level_for_experience("medium", 999999) == 99)
	_check.call("xp_inv_clamp_high", rs.level_for_experience("medium", 999999999) == 100)


func _test_xp_level_cap() -> void:
	var rs := _rs()
	_check.call("xp_cap_min", rs.clamp_level(0) == 1)
	_check.call("xp_cap_max", rs.clamp_level(9999) == 100)


# --- Stat calc ---------------------------------------------------------------

func _test_stat_calc_neutral() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var ivs := {}
	var evs := {}
	for k in ProgressionRuleset.STAT_KEYS:
		ivs[k] = 0
		evs[k] = 0
	var s := StatCalculator.compute(sp.base_stat_block(), ivs, evs, &"hardy", 5)
	_check.call("stat_hp_l5", s.max_hp == 19)
	_check.call("stat_atk_l5", s.attack == 9)


func _test_stat_calc_nature() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var ivs := {}
	var evs := {}
	for k in ProgressionRuleset.STAT_KEYS:
		ivs[k] = 0
		evs[k] = 0
	var neutral := StatCalculator.compute(sp.base_stat_block(), ivs, evs, &"hardy", 50)
	var adamant := StatCalculator.compute(sp.base_stat_block(), ivs, evs, &"adamant", 50)
	_check.call("stat_neutral_atk_l50", neutral.attack == 54)
	_check.call("stat_adamant_atk_up", adamant.attack == 59)
	_check.call("stat_adamant_spatk_down", adamant.special_attack < neutral.special_attack)


func _test_hp_recalc_on_levelup() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c := CreatureInstance.new(&"c1", &"bulbasaur", 5, StatBlock.new(), [])
	c.recalculate_stats(sp, rs)
	var hp5 := c.stats.max_hp
	c.level = 50
	c.recalculate_stats(sp, rs)
	_check.call("hp_increases_on_levelup", c.stats.max_hp > hp5)
	c.current_hp = c.stats.max_hp


func _test_iv_clamp() -> void:
	var rs := _rs()
	_check.call("iv_clamp_low", rs.clamp_iv(-5) == 0)
	_check.call("iv_clamp_high", rs.clamp_iv(99) == 31)
	_check.call("iv_in_range", rs.clamp_iv(17) == 17)


func _test_ev_clamp() -> void:
	var rs := _rs()
	_check.call("ev_clamp_high", rs.clamp_ev(999) == 252)
	_check.call("ev_clamp_low", rs.clamp_ev(-3) == 0)


func _test_nature_modifiers() -> void:
	_check.call("nature_neutral", ProgressionRuleset.nature_multiplier(&"hardy", "attack") == 1.0)
	_check.call("nature_up", ProgressionRuleset.nature_multiplier(&"adamant", "attack") == 1.1)
	_check.call("nature_down", ProgressionRuleset.nature_multiplier(&"adamant", "special_attack") == 0.9)
	_check.call("nature_invalid", not ProgressionRuleset.is_valid_nature(&"not_a_nature"))


# Canonical nature representation: 25 natures, stable StringName IDs, valid stat keys.
func _test_nature_catalog_canonical() -> void:
	var table := ProgressionRuleset.NATURE_MODIFIERS
	_check.call("nature_count_25", table.size() == ProgressionRuleset.NATURE_COUNT and table.size() == 25)
	_check.call("nature_neutral_present", table.has(ProgressionRuleset.NEUTRAL_NATURE))
	var all_valid := true
	var all_ids_string := true
	for nid in table.keys():
		if typeof(nid) != TYPE_STRING_NAME:
			all_ids_string = false
		if not ProgressionRuleset.is_valid_nature(nid):
			all_valid = false
		var mod: Array = table[nid]
		if mod.size() != 2:
			all_valid = false
		if mod[0] != "" and not ProgressionRuleset.STAT_KEYS.has(mod[0]):
			all_valid = false
		if mod[1] != "" and not ProgressionRuleset.STAT_KEYS.has(mod[1]):
			all_valid = false
	_check.call("nature_all_valid_ids", all_valid)
	_check.call("nature_stable_ids", all_ids_string)


# HP must never be affected by nature.
func _test_nature_hp_unaffected() -> void:
	var sp := _bulbasaur()
	var ivs := {}
	var evs := {}
	for k in ProgressionRuleset.STAT_KEYS:
		ivs[k] = 0
		evs[k] = 0
	var base_hp := StatCalculator.compute(sp.base_stat_block(), ivs, evs, &"hardy", 50).max_hp
	var ok := true
	for nid in ProgressionRuleset.NATURE_MODIFIERS.keys():
		if StatCalculator.compute(sp.base_stat_block(), ivs, evs, nid, 50).max_hp != base_hp:
			ok = false
	_check.call("nature_hp_unaffected", ok)


# Every modifiable stat gets 1.1x up / 0.9x down; HP always 1.0x; all 5 stats appear as an up stat.
func _test_nature_modifiable_stats() -> void:
	var table := ProgressionRuleset.NATURE_MODIFIERS
	var up_ok := true
	var down_ok := true
	var hp_ok := true
	for nid in table.keys():
		for sk in ProgressionRuleset.STAT_KEYS:
			var m := ProgressionRuleset.nature_multiplier(nid, sk)
			if sk == "hp":
				if m != 1.0:
					hp_ok = false
			elif table[nid][0] == sk:
				if m != 1.1:
					up_ok = false
			elif table[nid][1] == sk:
				if m != 0.9:
					down_ok = false
			else:
				if m != 1.0:
					up_ok = false
	_check.call("nature_up_1_1", up_ok)
	_check.call("nature_down_0_9", down_ok)
	_check.call("nature_hp_1_0", hp_ok)
	var ups := {}
	for nid in table.keys():
		if table[nid][0] != "":
			ups[table[nid][0]] = true
	_check.call("nature_all_stats_modifiable",
		ups.has("attack") and ups.has("defense") and ups.has("speed")
		and ups.has("special_attack") and ups.has("special_defense"))


# nature_id is a real field on CreatureInstance and drives derived stats.
func _test_nature_instance_field() -> void:
	var c := CreatureInstance.new(&"x", &"bulbasaur", 50, StatBlock.new(), [])
	_check.call("nature_default_hardy", c.nature_id == &"hardy")
	c.nature_id = &"jolly"
	_check.call("nature_field_settable", c.nature_id == &"jolly")
	var sp := _bulbasaur()
	var rs := _rs()
	c.recalculate_stats(sp, rs)
	var neutral := CreatureInstance.new(&"n", &"bulbasaur", 50, StatBlock.new(), [])
	neutral.recalculate_stats(sp, rs)
	_check.call("nature_instance_affects_stats",
		c.stats.speed > neutral.stats.speed and c.stats.special_attack < neutral.stats.special_attack)


# Battle reads already-derived stats; it does not own/derive nature.
func _test_nature_battle_uses_derived() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c := CreatureFactory.create(sp, 50, _catalog, rs, _rng(7), {"nature_id": &"adamant"})
	var neutral := CreatureFactory.create(sp, 50, _catalog, rs, _rng(7), {"nature_id": &"hardy"})
	_check.call("nature_derived_at_instance", c.stats.attack > neutral.stats.attack)
	var state := BattleState.create_with_parties(&"b", [c], [neutral])
	var in_battle := state.creature(c.instance_id)
	_check.call("nature_battle_reads_derived", in_battle.stats.attack == c.stats.attack)


# --- Factory -----------------------------------------------------------------

func _test_factory_deterministic_seed() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c1 := CreatureFactory.create(sp, 5, _catalog, rs, _rng(42))
	var c2 := CreatureFactory.create(sp, 5, _catalog, rs, _rng(42))
	_check.call("factory_seed_deterministic", c1.ivs == c2.ivs and c1.nature_id == c2.nature_id)


func _test_factory_unique_id() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c1 := CreatureFactory.create(sp, 5, _catalog, rs, _rng(1))
	var c2 := CreatureFactory.create(sp, 5, _catalog, rs, _rng(2))
	_check.call("factory_unique_id", c1.instance_id != c2.instance_id)


func _test_factory_initial_moves() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c := CreatureFactory.create(sp, 10, _catalog, rs, _rng(7))
	_check.call("factory_moves_within_cap", c.moveset.size() >= 1 and c.moveset.size() <= ProgressionRuleset.MOVE_SLOTS_MAX)
	_check.call("factory_full_hp", c.current_hp == c.stats.max_hp)


# --- Learnset ----------------------------------------------------------------

func _test_learnset_queries() -> void:
	var sp := _bulbasaur()
	var target_level := _level_up_move_level(sp, &"vine_whip")
	var previous_level := maxi(1, target_level - 1)
	var crossed := LearnsetSystem.level_up_moves_between(sp, previous_level, target_level)
	var has_vine := false
	for e in crossed:
		if (e as LearnSetEntry).move_id == &"vine_whip":
			has_vine = true
	_check.call("learnset_vine_whip_at_source_level", target_level > 1 and has_vine)
	var init := LearnsetSystem.initial_moves(sp, 1)
	_check.call("learnset_initial_not_over_cap", init.size() <= ProgressionRuleset.MOVE_SLOTS_MAX)
	_check.call("learnset_moves_learned_at_level", LearnsetSystem.moves_learned_at_level(sp, target_level).has(&"vine_whip"))

func _test_gain_learns_move() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var target_level := _level_up_move_level(sp, &"vine_whip")
	var previous_level := target_level - 1
	var c := CreatureInstance.new(&"c", &"bulbasaur", previous_level, StatBlock.new(), [])
	c.recalculate_stats(sp, rs)
	c.moveset.clear()
	c.move_ids.clear()
	c.experience = rs.experience_for_level("medium-slow", previous_level)
	var need := rs.experience_for_level("medium-slow", target_level) - c.experience
	var events := ProgressionSystem.gain_experience(c, need, sp, _catalog, rs)
	var learned := false
	for ev in events:
		if (ev as ProgressionEvent).kind == ProgressionEvent.MOVE_LEARNED and (ev as ProgressionEvent).data.get("move_id") == &"vine_whip":
			learned = true
	_check.call("gain_learns_vine_whip", learned and c.has_move(&"vine_whip"))
	_check.call("gain_reaches_source_move_level", c.level == target_level)

func _test_gain_move_choice_required() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var target_level := _level_up_move_level(sp, &"vine_whip")
	var previous_level := target_level - 1
	var filler := _four_valid_moves_excluding(&"vine_whip")
	var c := CreatureInstance.new(&"c", &"bulbasaur", previous_level, StatBlock.new(), filler)
	c.recalculate_stats(sp, rs)
	c.initialize_move_pp(_catalog)
	c.experience = rs.experience_for_level("medium-slow", previous_level)
	var need := rs.experience_for_level("medium-slow", target_level) - c.experience
	var events := ProgressionSystem.gain_experience(c, need, sp, _catalog, rs)
	var choice := false
	for ev in events:
		if (ev as ProgressionEvent).kind == ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED and (ev as ProgressionEvent).data.get("new_move_id") == &"vine_whip":
			choice = true
	_check.call("gain_move_choice_required", choice)
	_check.call("gain_moveset_full", c.moveset.size() == ProgressionRuleset.MOVE_SLOTS_MAX)

func _test_move_choice_replace() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var target_level := _level_up_move_level(sp, &"vine_whip")
	var previous_level := target_level - 1
	var filler := _four_valid_moves_excluding(&"vine_whip")
	var c := CreatureInstance.new(&"c", &"bulbasaur", previous_level, StatBlock.new(), filler)
	c.recalculate_stats(sp, rs)
	c.initialize_move_pp(_catalog)
	c.experience = rs.experience_for_level("medium-slow", previous_level)
	var need := rs.experience_for_level("medium-slow", target_level) - c.experience
	var events := ProgressionSystem.gain_experience(c, need, sp, _catalog, rs)
	var choice: ProgressionEvent = null
	for ev in events:
		if (ev as ProgressionEvent).kind == ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED and (ev as ProgressionEvent).data.get("new_move_id") == &"vine_whip":
			choice = ev as ProgressionEvent
	var old_move: StringName = c.move_ids[0]
	var ok := ProgressionSystem.apply_move_choice(c, choice, ProgressionSystem.REPLACE_MOVE, _catalog, old_move)
	_check.call("move_choice_replace_ok", ok and c.has_move(&"vine_whip") and not c.has_move(old_move))

func _test_move_choice_decline() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var target_level := _level_up_move_level(sp, &"vine_whip")
	var previous_level := target_level - 1
	var filler := _four_valid_moves_excluding(&"vine_whip")
	var c := CreatureInstance.new(&"c", &"bulbasaur", previous_level, StatBlock.new(), filler)
	c.recalculate_stats(sp, rs)
	c.initialize_move_pp(_catalog)
	c.experience = rs.experience_for_level("medium-slow", previous_level)
	var need := rs.experience_for_level("medium-slow", target_level) - c.experience
	var events := ProgressionSystem.gain_experience(c, need, sp, _catalog, rs)
	var choice: ProgressionEvent = null
	for ev in events:
		if (ev as ProgressionEvent).kind == ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED and (ev as ProgressionEvent).data.get("new_move_id") == &"vine_whip":
			choice = ev as ProgressionEvent
	var before := c.moveset.size()
	var ok := ProgressionSystem.apply_move_choice(c, choice, ProgressionSystem.DECLINE_MOVE, _catalog)
	_check.call("move_choice_decline_ok", ok and c.moveset.size() == before and not c.has_move(&"vine_whip"))

func _test_evolution_by_level() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var cands := EvolutionSystem.evolution_candidates(sp, {"level": 16}, _catalog)
	var found := false
	for rec in cands:
		if (rec as EvolutionRecord).species_id == &"ivysaur":
			found = true
	_check.call("evolution_by_level", found)


func _test_evolution_not_eligible_low_level() -> void:
	var sp := _bulbasaur()
	var cands := EvolutionSystem.evolution_candidates(sp, {"level": 5}, _catalog)
	_check.call("evolution_low_level_none", cands.is_empty())


func _test_evolution_apply_preserves_identity() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c := CreatureFactory.create(sp, 20, _catalog, rs, _rng(11))
	var ev_avail := ProgressionEvent.new(
		ProgressionEvent.EVOLUTION_AVAILABLE, c.instance_id,
		{"species_id": "ivysaur", "trigger": "level_up", "min_level": 16},
	)
	var evolved := ProgressionSystem.apply_evolution(c, ev_avail, _catalog, rs)
	_check.call("evolution_applied", evolved != null and evolved.species_id == &"ivysaur")
	_check.call("evolution_keeps_id", evolved.instance_id == c.instance_id)
	_check.call("evolution_keeps_level", evolved.level == c.level)
	_check.call("evolution_keeps_ivs", evolved.ivs == c.ivs)
	_check.call("evolution_keeps_nature", evolved.nature_id == c.nature_id)
	_check.call("evolution_recalc_stats", evolved.stats.max_hp > 0)


func _test_evolution_unsupported_deferred() -> void:
	var rs := _rs()
	var sp := CreatureSpecies.new()
	sp.id = &"test_mon"
	sp.evolutions.append(EvolutionRecord.new(&"other_mon", 0, &"other"))
	var cls := EvolutionSystem.classify_record(sp.evolutions[0], _catalog)
	_check.call("evolution_unsupported_class", cls == EvolutionSystem.UNSUPPORTED)
	var cands := EvolutionSystem.evolution_candidates(sp, {"level": 99}, _catalog)
	_check.call("evolution_unsupported_no_candidate", cands.is_empty())


# --- Serialization -----------------------------------------------------------

func _test_serialization_round_trip() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c := CreatureFactory.create(sp, 25, _catalog, rs, _rng(5))
	c.experience = 12345
	c.current_hp = 5
	var d := c.to_dict()
	var restored := CreatureInstance.from_dict(d)
	_check.call("serial_level", restored.level == c.level)
	_check.call("serial_exp", restored.experience == c.experience)
	_check.call("serial_nature", restored.nature_id == c.nature_id)
	_check.call("serial_ivs", restored.ivs == c.ivs)
	_check.call("serial_moveset", restored.moveset.size() == c.moveset.size())
	_check.call("serial_id", restored.instance_id == c.instance_id)


# --- Battle -> Progression boundary -----------------------------------------

func _test_battle_outcome_from_state() -> void:
	var rs := _rs()
	var winner := CreatureFactory.create(_bulbasaur(), 50, _catalog, rs, _rng(1))
	var loser := CreatureFactory.create(_bulbasaur(), 5, _catalog, rs, _rng(2))
	loser.current_hp = 0
	var state := BattleState.create_with_parties(&"b", [winner], [loser])
	state.winner_id = winner.instance_id
	state.phase = BattleState.FINISHED
	var outcome := BattleOutcome.from_battle_state(state, _catalog)
	_check.call("outcome_winner", outcome.winner_side_id == &"side_a")
	_check.call("outcome_defeated", outcome.defeated.size() == 1)
	_check.call("outcome_defeated_species", String(outcome.defeated[0].get("species_id")) == "bulbasaur")


func _test_battle_reconcile_grants_xp() -> void:
	var rs := _rs()
	var winner := CreatureFactory.create(_bulbasaur(), 50, _catalog, rs, _rng(1))
	var loser := CreatureFactory.create(_bulbasaur(), 5, _catalog, rs, _rng(2))
	loser.current_hp = 0
	var state := BattleState.create_with_parties(&"b", [winner], [loser])
	state.winner_id = winner.instance_id
	state.phase = BattleState.FINISHED
	var outcome := BattleOutcome.from_battle_state(state, _catalog)
	var before := winner.experience
	var events := ProgressionSystem.reconcile_battle_result([winner], outcome, _catalog, rs)
	_check.call("reconcile_grants_xp", winner.experience > before)
	var gained := false
	for ev in events:
		if (ev as ProgressionEvent).kind == ProgressionEvent.EXPERIENCE_GAINED:
			gained = true
	_check.call("reconcile_experience_event", gained)


func _test_pp_persisted() -> void:
	var rs := _rs()
	var c := CreatureFactory.create(_bulbasaur(), 20, _catalog, rs, _rng(3))
	c.initialize_move_pp(_catalog)
	var slot := c.moveset[0] as BattleMoveSlot
	slot.current_pp = 1
	var d := c.to_dict()
	var restored := CreatureInstance.from_dict(d)
	_check.call("pp_persisted", (restored.moveset[0] as BattleMoveSlot).current_pp == 1)


func _test_volatile_status_not_persisted() -> void:
	var rs := _rs()
	var sp := _bulbasaur()
	var c := CreatureFactory.create(sp, 20, _catalog, rs, _rng(4))
	c.status_state.add_volatile(&"flinch", {"turns": 1})
	c.status_state.persistent_id = &"burn"
	c.reconcile_post_battle()
	_check.call("volatile_cleared", c.status_state.volatile.is_empty())
	_check.call("persistent_kept", c.status_state.persistent_id == &"burn")


# --- Coverage + ruleset ------------------------------------------------------

func _test_evolution_coverage_invariant() -> void:
	var report := EvolutionSystem.coverage_report(_catalog)
	var expected_total := 0
	for sid in _catalog.species_catalog.all_ids():
		expected_total += _catalog.species_catalog.get_by_id(sid).evolutions.size()
	_check.call("evo_coverage_total", report["edges_total"] == expected_total)
	var counts: Dictionary = report["counts"]
	var sum := 0
	for k in counts.keys():
		sum += int(counts[k])
	_check.call("evo_coverage_sum", sum == expected_total)
	_check.call("evo_coverage_has_unsupported", int(counts[EvolutionSystem.UNSUPPORTED]) > 0)
	_check.call("evo_coverage_has_runtime", int(counts[EvolutionSystem.RUNTIME_SUPPORTED]) > 0)

func _test_ruleset_policy_id() -> void:
	_check.call("ruleset_policy_id", ProgressionRuleset.POLICY_ID == "calvo_progression_v1")
	_check.call("ruleset_id", ProgressionRuleset.ID == &"calvo_progression_v1")


# --- helpers -----------------------------------------------------------------

func _level_up_move_level(species: CreatureSpecies, move_id: StringName) -> int:
	for entry in species.learnset:
		if entry is LearnSetEntry and (entry as LearnSetEntry).method == LearnsetSystem.LEVEL_UP and (entry as LearnSetEntry).move_id == move_id:
			return (entry as LearnSetEntry).level
	return -1

func _four_valid_moves_excluding(exclude: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for mid in _catalog.move_catalog.all_ids():
		if mid == exclude:
			continue
		var def := _catalog.move(mid)
		if def != null and def.pp > 0:
			out.append(mid)
		if out.size() >= 4:
			break
	return out
