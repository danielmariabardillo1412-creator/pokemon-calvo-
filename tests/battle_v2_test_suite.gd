class_name BattleV2TestSuite
extends RefCounted

var _check: Callable
var _catalog: DefinitionCatalog
var _client := BattleClient.new()


func _init(game_data: GameData) -> void:
	_catalog = game_data.to_definition_catalog()
	_add_test_definitions()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_test_phase_order()
	_test_pp_runtime()
	_test_zero_pp_rejected()
	_test_pp_snapshot()
	_test_accuracy_hit_and_miss()
	_test_accuracy_evasion_stages()
	_test_stat_stage_changes_and_caps()
	_test_physical_and_special_damage()
	_test_type_effectiveness_events()
	_test_critical_determinism()
	_test_burn()
	_test_poison_and_badly_poisoned()
	_test_paralysis()
	_test_sleep()
	_test_status_immunity()
	_test_heal_recoil_and_drain()
	_test_secondary_effect_chance()
	_test_representative_move_mappings()
	_test_additional_effect_primitives()
	_test_intimidate()
	_test_levitate()
	_test_blaze()
	_test_other_pinch_abilities()
	_test_static()
	_test_leftovers_and_sitrus()
	_test_switching()
	_test_switch_validation()
	_test_server_validation()
	_test_snapshot_round_trip_v2()
	_test_snapshot_rng_continuation()
	_test_same_seed_same_result()
	_test_trigger_order()
	_test_semantic_events()
	_test_golden_damage_scenario()
	_test_golden_status_scenario()
	_test_runtime_coverage_contract()
	_test_fase5_multi_hit()
	_test_fase5_static_contact()


func _test_phase_order() -> void:
	_expect("v2_phase_order", BattlePhase.ORDER == [
		BattlePhase.VALIDATE_ACTIONS,
		BattlePhase.SELECT_ORDER,
		BattlePhase.BEFORE_ACTION,
		BattlePhase.ACCURACY,
		BattlePhase.EXECUTE_EFFECTS,
		BattlePhase.AFTER_DAMAGE,
		BattlePhase.FAINT_CHECK,
		BattlePhase.AFTER_ACTION,
		BattlePhase.END_TURN_STATUS,
		BattlePhase.END_TURN_TRIGGERS,
		BattlePhase.TURN_END,
	])


func _test_pp_runtime() -> void:
	var server := _server(10, [&"tackle"], [&"idle"])
	var slot := server.state.creature(&"a").move_slot(&"tackle")
	var before := slot.current_pp
	var events := server.submit_turn(_move_actions(server.state, &"tackle", &"idle"))
	_expect("v2_pp_consumed", slot.current_pp == before - 1)
	_expect("v2_pp_event", _first(events, BattleEvent.PP_CHANGED) != null)


func _test_zero_pp_rejected() -> void:
	var server := _server(11, [&"tackle"], [&"idle"])
	server.state.creature(&"a").move_slot(&"tackle").current_pp = 0
	var events := server.submit_turn(_move_actions(server.state, &"tackle", &"idle"))
	_expect("v2_zero_pp_rejected", _rejection_reason(events) == "no_pp" and server.state.turn == 0)


func _test_pp_snapshot() -> void:
	var server := _server(12, [&"tackle"], [&"idle"])
	server.submit_turn(_move_actions(server.state, &"tackle", &"idle"))
	var restored := BattleState.from_dict(JSON.parse_string(JSON.stringify(server.snapshot())))
	_expect(
		"v2_pp_snapshot",
		restored.creature(&"a").move_slot(&"tackle").current_pp
		== server.state.creature(&"a").move_slot(&"tackle").current_pp,
	)


func _test_accuracy_hit_and_miss() -> void:
	var hit_server := _server(13, [&"never_miss"], [&"idle"])
	var hit_events := hit_server.submit_turn(_move_actions(hit_server.state, &"never_miss", &"idle"))
	var miss_server := _server(13, [&"always_miss"], [&"idle"])
	var miss_events := miss_server.submit_turn(_move_actions(miss_server.state, &"always_miss", &"idle"))
	_expect("v2_accuracy_hit", _first(hit_events, BattleEvent.DAMAGE_APPLIED) != null)
	_expect(
		"v2_accuracy_miss",
		_first(miss_events, BattleEvent.MOVE_MISSED) != null
		and _first(miss_events, BattleEvent.DAMAGE_APPLIED) == null,
	)


func _test_accuracy_evasion_stages() -> void:
	var ruleset := BattleRuleset.new()
	var neutral := ruleset.accuracy_threshold_basis_points(80, 0, 0)
	var boosted := ruleset.accuracy_threshold_basis_points(80, 2, 0)
	var evaded := ruleset.accuracy_threshold_basis_points(80, 0, 2)
	_expect("v2_accuracy_evasion_stages", boosted > neutral and neutral > evaded)


func _test_stat_stage_changes_and_caps() -> void:
	var stages := StatStages.new()
	var up := stages.change(StatStages.ATTACK, 1)
	var down := stages.change(StatStages.DEFENSE, -1)
	stages.change(StatStages.ATTACK, 99)
	var capped_up := stages.get_stage(StatStages.ATTACK)
	stages.change(StatStages.ATTACK, -99)
	_expect("v2_stat_stage_plus", up == 1)
	_expect("v2_stat_stage_minus", down == -1)
	_expect("v2_stat_stage_caps", capped_up == 6 and stages.get_stage(StatStages.ATTACK) == -6)


func _test_physical_and_special_damage() -> void:
	var attacker := _creature(&"atk", &"charmander", [&"physical_test", &"special_test"], 20, 100, 20)
	var defender := _creature(&"def", &"squirtle", [&"idle"], 10, 100, 100)
	var calc := DamageCalculator.new()
	var physical := calc.calculate(
		attacker, defender, _catalog.move(&"physical_test"), _catalog,
		SeededRandomSource.new(3), BattleRuleset.new(), 10000, 0
	)
	var special := calc.calculate(
		attacker, defender, _catalog.move(&"special_test"), _catalog,
		SeededRandomSource.new(3), BattleRuleset.new(), 10000, 0
	)
	_expect("v2_physical_damage", physical.amount > 0)
	_expect("v2_special_damage", special.amount > 0 and physical.amount > special.amount)


func _test_type_effectiveness_events() -> void:
	var super_server := _server(14, [&"thunder_punch"], [&"idle"], &"pikachu", &"squirtle")
	var super_events := super_server.submit_turn(_move_actions(super_server.state, &"thunder_punch", &"idle"))
	var resisted_server := _server(14, [&"ember"], [&"idle"], &"charmander", &"squirtle")
	var resisted_events := resisted_server.submit_turn(_move_actions(resisted_server.state, &"ember", &"idle"))
	var immune_server := _server(14, [&"ground_test"], [&"idle"], &"geodude", &"pidgey")
	var immune_events := immune_server.submit_turn(_move_actions(immune_server.state, &"ground_test", &"idle"))
	_expect("v2_super_effective", _effectiveness_category(super_events) == "super_effective")
	_expect("v2_not_very_effective", _effectiveness_category(resisted_events) == "not_very_effective")
	_expect(
		"v2_immune",
		_effectiveness_category(immune_events) == "immune"
		and _first(immune_events, BattleEvent.DAMAGE_APPLIED) == null,
	)


func _test_critical_determinism() -> void:
	var seed := _seed_for_success(BattleRuleset.new().critical_threshold_basis_points())
	var first := DamageCalculator.new().calculate(
		_creature(&"a1", &"charmander", [&"tackle"]),
		_creature(&"b1", &"squirtle", [&"idle"]),
		_catalog.move(&"tackle"), _catalog, SeededRandomSource.new(seed), BattleRuleset.new()
	)
	var second := DamageCalculator.new().calculate(
		_creature(&"a2", &"charmander", [&"tackle"]),
		_creature(&"b2", &"squirtle", [&"idle"]),
		_catalog.move(&"tackle"), _catalog, SeededRandomSource.new(seed), BattleRuleset.new()
	)
	_expect("v2_critical", first.critical and first.critical_basis_points == 15000)
	_expect("v2_critical_deterministic", first == second)


func _test_burn() -> void:
	var burned := _creature(&"burned", &"bulbasaur", [&"tackle"])
	burned.status_state.persistent_id = StatusSystem.BURN
	var healthy := _creature(&"healthy", &"bulbasaur", [&"tackle"])
	var defender := _creature(&"def", &"squirtle", [&"idle"])
	var calc := DamageCalculator.new()
	var burned_damage: int = int(calc.calculate(
		burned, defender, _catalog.move(&"tackle"), _catalog,
		SeededRandomSource.new(20), BattleRuleset.new(), 10000, 0
	).amount)
	var normal_damage: int = int(calc.calculate(
		healthy, defender, _catalog.move(&"tackle"), _catalog,
		SeededRandomSource.new(20), BattleRuleset.new(), 10000, 0
	).amount)
	var server := _server(20, [&"idle"], [&"idle"])
	server.state.creature(&"a").status_state.persistent_id = StatusSystem.BURN
	var events := server.submit_turn(_move_actions(server.state, &"idle", &"idle"))
	_expect("v2_burn_penalty", burned_damage < normal_damage)
	_expect("v2_burn_tick", _status_damage(events, StatusSystem.BURN) > 0)


func _test_poison_and_badly_poisoned() -> void:
	var poison_server := _server(21, [&"idle"], [&"idle"])
	poison_server.state.creature(&"a").status_state.persistent_id = StatusSystem.POISON
	var poison_events := poison_server.submit_turn(_move_actions(poison_server.state, &"idle", &"idle"))
	var toxic_server := _server(21, [&"idle"], [&"idle"])
	toxic_server.state.creature(&"a").status_state.persistent_id = StatusSystem.BADLY_POISONED
	var first_events := toxic_server.submit_turn(_move_actions(toxic_server.state, &"idle", &"idle"))
	var first_tick := _status_damage(first_events, StatusSystem.BADLY_POISONED)
	var second_events := toxic_server.submit_turn(_move_actions(toxic_server.state, &"idle", &"idle"))
	var second_tick := _status_damage(second_events, StatusSystem.BADLY_POISONED)
	_expect("v2_poison", _status_damage(poison_events, StatusSystem.POISON) > 0)
	_expect("v2_badly_poisoned", second_tick > first_tick and toxic_server.state.creature(&"a").status_state.toxic_counter == 2)


func _test_paralysis() -> void:
	var seed := _seed_for_success(BattleRuleset.new().paralysis_skip_chance_basis_points)
	var server := _server(seed, [&"tackle"], [&"idle"])
	server.state.creature(&"a").status_state.persistent_id = StatusSystem.PARALYSIS
	var events := server.submit_turn(_move_actions(server.state, &"tackle", &"idle"))
	_expect(
		"v2_paralysis",
		_first(events, BattleEvent.ACTION_PREVENTED) != null
		and server.state.creature(&"a").move_slot(&"tackle").current_pp == _catalog.move(&"tackle").pp,
	)


func _test_sleep() -> void:
	var state := BattleState.new(&"sleep", [
		_creature(&"a", &"bulbasaur", [&"idle"]),
		_creature(&"b", &"squirtle", [&"idle"]),
	], 30)
	var rng := SeededRandomSource.new(30)
	var events: Array[BattleEvent] = []
	var status := StatusSystem.new()
	var applied := status.try_apply(
		state, state.creature(&"a"), state.creature(&"b"), StatusSystem.SLEEP,
		_catalog, rng, events
	)
	var duration := state.creature(&"b").status_state.turns_remaining
	var can_act := status.can_act(state, state.creature(&"b"), rng, events, BattleRuleset.new())
	_expect("v2_sleep_duration", applied.applied and duration >= 1 and duration <= 3)
	_expect("v2_sleep_prevents_action", not can_act and _first(events, BattleEvent.ACTION_PREVENTED) != null)


func _test_status_immunity() -> void:
	var state := BattleState.new(&"immune", [
		_creature(&"a", &"bulbasaur", [&"idle"]),
		_creature(&"b", &"charmander", [&"idle"]),
	], 31)
	var events: Array[BattleEvent] = []
	var result := StatusSystem.new().try_apply(
		state, state.creature(&"a"), state.creature(&"b"), StatusSystem.BURN,
		_catalog, SeededRandomSource.new(31), events
	)
	_expect(
		"v2_status_immunity",
		not result.applied and result.reason == &"type_immunity"
		and _first(events, BattleEvent.STATUS_FAILED) != null,
	)


func _test_heal_recoil_and_drain() -> void:
	var heal_server := _server(32, [&"recover"], [&"idle"])
	heal_server.state.creature(&"a").current_hp = 20
	var heal_events := heal_server.submit_turn(_move_actions(heal_server.state, &"recover", &"idle"))
	var recoil_server := _server(33, [&"double_edge"], [&"idle"])
	var recoil_events := recoil_server.submit_turn(_move_actions(recoil_server.state, &"double_edge", &"idle"))
	var drain_server := _server(34, [&"mega_drain"], [&"idle"], &"bulbasaur", &"squirtle")
	drain_server.state.creature(&"a").current_hp = 20
	var drain_events := drain_server.submit_turn(_move_actions(drain_server.state, &"mega_drain", &"idle"))
	_expect("v2_heal", _first(heal_events, BattleEvent.HP_RECOVERED) != null)
	_expect("v2_recoil", _first(recoil_events, BattleEvent.RECOIL_DAMAGE) != null)
	var drain_event := _first(drain_events, BattleEvent.HP_RECOVERED)
	_expect("v2_drain", drain_event != null and drain_event.metadata.get("cause", "") == "drain")


func _test_secondary_effect_chance() -> void:
	var found_seed := -1
	var first_events: Array[BattleEvent] = []
	for seed in range(1, 300):
		var server := _server(seed, [&"thunder_punch"], [&"idle"], &"charmander", &"squirtle")
		var events := server.submit_turn(_move_actions(server.state, &"thunder_punch", &"idle"))
		if _first(events, BattleEvent.STATUS_APPLIED) != null:
			found_seed = seed
			first_events = events
			break
	var replay := _server(found_seed, [&"thunder_punch"], [&"idle"], &"charmander", &"squirtle")
	var replay_events := replay.submit_turn(_move_actions(replay.state, &"thunder_punch", &"idle"))
	_expect("v2_secondary_effect", found_seed > 0 and _first(first_events, BattleEvent.STATUS_APPLIED) != null)
	_expect("v2_secondary_deterministic", JSON.stringify(_dicts(first_events)) == JSON.stringify(_dicts(replay_events)))


func _test_representative_move_mappings() -> void:
	var growl := _server(35, [&"growl"], [&"idle"])
	var growl_events := growl.submit_turn(_move_actions(growl.state, &"growl", &"idle"))
	var swords := _server(36, [&"swords_dance"], [&"idle"])
	var swords_events := swords.submit_turn(_move_actions(swords.state, &"swords_dance", &"idle"))
	var water := _server(37, [&"water_gun"], [&"idle"], &"squirtle", &"charmander")
	var water_events := water.submit_turn(_move_actions(water.state, &"water_gun", &"idle"))
	var quick := _server(38, [&"quick_attack"], [&"tackle"])
	quick.state.creature(&"a").stats.speed = 1
	quick.state.creature(&"b").stats.speed = 100
	var quick_events := quick.submit_turn(_move_actions(quick.state, &"quick_attack", &"tackle"))
	_expect(
		"v2_move_growl",
		growl.state.creature(&"b").stat_stages.get_stage(StatStages.ATTACK) == -1
		and _first(growl_events, BattleEvent.STAT_STAGE_CHANGED) != null,
	)
	_expect(
		"v2_move_swords_dance",
		swords.state.creature(&"a").stat_stages.get_stage(StatStages.ATTACK) == 2
		and _first(swords_events, BattleEvent.STAT_STAGE_CHANGED) != null,
	)
	var water_damage := _first(water_events, BattleEvent.DAMAGE_APPLIED)
	_expect("v2_move_water_gun", water_damage != null and water_damage.metadata.damage_class == "special")
	_expect("v2_move_quick_attack", _first(quick_events, BattleEvent.ACTION_USED).actor_id == &"a")
	_expect("v2_move_ember", _move_can_apply_status(&"ember", StatusSystem.BURN, &"charmander", &"bulbasaur"))
	_expect("v2_move_thunder", _move_can_apply_status(&"thunder", StatusSystem.PARALYSIS, &"pikachu", &"squirtle"))
	_expect("v2_move_thunder_wave", _move_can_apply_status(&"thunder_wave", StatusSystem.PARALYSIS, &"pikachu", &"squirtle"))
	_expect("v2_move_will_o_wisp", _move_can_apply_status(&"will_o_wisp", StatusSystem.BURN, &"charmander", &"bulbasaur"))
	_expect("v2_move_toxic", _move_can_apply_status(&"toxic", StatusSystem.BADLY_POISONED, &"charmander", &"squirtle"))
	_expect("v2_move_sleep_powder", _move_can_apply_status(&"sleep_powder", StatusSystem.SLEEP, &"bulbasaur", &"squirtle"))


func _test_additional_effect_primitives() -> void:
	var state := BattleState.new(&"primitives", [
		_creature(&"a", &"charmander", [&"idle"]),
		_creature(&"b", &"squirtle", [&"idle"]),
	], 39)
	state.turn = 1
	var events: Array[BattleEvent] = []
	var context := BattleEffectContext.new(
		state, state.creature(&"a"), state.creature(&"b"), _catalog.move(&"idle"),
		_catalog, BattleRuleset.new(), SeededRandomSource.new(39), events
	)
	var executor := BattleEffectExecutor.new()
	var registry := BattleEffectRegistry.new()
	state.creature(&"b").status_state.persistent_id = StatusSystem.POISON
	state.creature(&"b").status_ids.append(StatusSystem.POISON)
	var cured := executor.execute(BattleEffectSpec.new(
		BattleEffectSpec.CURE_STATUS, BattleEffectSpec.OPPONENT
	), context, registry)
	var before := state.creature(&"b").current_hp
	var fixed := executor.execute(BattleEffectSpec.new(
		BattleEffectSpec.FIXED_DAMAGE, BattleEffectSpec.OPPONENT, 17
	), context, registry)
	var flinch := executor.execute(BattleEffectSpec.new(
		BattleEffectSpec.FLINCH, BattleEffectSpec.OPPONENT
	), context, registry)
	_expect("v2_primitive_cure_status", cured.applied and state.creature(&"b").status_state.persistent_id == &"")
	_expect("v2_primitive_fixed_damage", fixed.amount == 17 and state.creature(&"b").current_hp == before - 17)
	_expect("v2_primitive_flinch", flinch.applied and state.creature(&"b").status_state.has_volatile(StatusSystem.FLINCH))


func _test_intimidate() -> void:
	var server := _server(40, [&"idle"], [&"idle"])
	server.state.creature(&"a").ability_id = &"intimidate"
	var events := server.submit_turn(_move_actions(server.state, &"idle", &"idle"))
	_expect(
		"v2_ability_intimidate",
		server.state.creature(&"b").stat_stages.get_stage(StatStages.ATTACK) == -1
		and _source_triggered(events, BattleEvent.ABILITY_TRIGGERED, "intimidate"),
	)


func _test_levitate() -> void:
	var server := _server(41, [&"ground_test"], [&"idle"], &"geodude", &"gastly")
	server.state.creature(&"b").ability_id = &"levitate"
	var hp_before := server.state.creature(&"b").current_hp
	var events := server.submit_turn(_move_actions(server.state, &"ground_test", &"idle"))
	_expect(
		"v2_ability_levitate",
		server.state.creature(&"b").current_hp == hp_before
		and _source_triggered(events, BattleEvent.ABILITY_TRIGGERED, "levitate"),
	)


func _test_blaze() -> void:
	var boosted := _server(42, [&"ember"], [&"idle"], &"charmander", &"bulbasaur")
	boosted.state.creature(&"a").ability_id = &"blaze"
	boosted.state.creature(&"a").current_hp = boosted.state.creature(&"a").stats.max_hp / 3
	var boosted_events := boosted.submit_turn(_move_actions(boosted.state, &"ember", &"idle"))
	var plain := _server(42, [&"ember"], [&"idle"], &"charmander", &"bulbasaur")
	plain.state.creature(&"a").current_hp = plain.state.creature(&"a").stats.max_hp / 3
	var plain_events := plain.submit_turn(_move_actions(plain.state, &"ember", &"idle"))
	_expect(
		"v2_ability_blaze",
		_damage_amount(boosted_events) > _damage_amount(plain_events)
		and _source_triggered(boosted_events, BattleEvent.ABILITY_TRIGGERED, "blaze"),
	)


func _test_other_pinch_abilities() -> void:
	_expect("v2_ability_torrent", _pinch_ability_works(
		&"torrent", &"water_gun", &"squirtle", &"charmander"
	))
	_expect("v2_ability_overgrow", _pinch_ability_works(
		&"overgrow", &"mega_drain", &"bulbasaur", &"squirtle"
	))


func _test_static() -> void:
	var found := false
	for seed in range(1, 300):
		var server := _server(seed, [&"tackle"], [&"idle"])
		server.state.creature(&"b").ability_id = &"static"
		var events := server.submit_turn(_move_actions(server.state, &"tackle", &"idle"))
		if server.state.creature(&"a").status_state.persistent_id == StatusSystem.PARALYSIS:
			found = _source_triggered(events, BattleEvent.ABILITY_TRIGGERED, "static")
			break
	_expect("v2_ability_static", found)


func _test_leftovers_and_sitrus() -> void:
	var leftovers := _server(50, [&"idle"], [&"idle"])
	leftovers.state.creature(&"a").held_item_id = &"leftovers"
	leftovers.state.creature(&"a").current_hp = 50
	var left_events := leftovers.submit_turn(_move_actions(leftovers.state, &"idle", &"idle"))
	var sitrus := _server(51, [&"heavy_test"], [&"idle"])
	sitrus.state.creature(&"b").held_item_id = &"sitrus_berry"
	sitrus.state.creature(&"b").current_hp = 70
	var sitrus_events := sitrus.submit_turn(_move_actions(sitrus.state, &"heavy_test", &"idle"))
	_expect(
		"v2_item_leftovers",
		_source_triggered(left_events, BattleEvent.ITEM_TRIGGERED, "leftovers")
		and _first(left_events, BattleEvent.HP_RECOVERED) != null,
	)
	_expect(
		"v2_item_sitrus",
		sitrus.state.creature(&"b").held_item_consumed
		and _source_triggered(sitrus_events, BattleEvent.ITEM_TRIGGERED, "sitrus_berry"),
	)


func _test_switching() -> void:
	var a := _creature(&"a", &"charmander", [&"tackle"], 30)
	var a2 := _creature(&"a2", &"bulbasaur", [&"idle"], 10)
	var b := _creature(&"b", &"squirtle", [&"tackle"], 20)
	var state := BattleState.create_with_parties(&"switch", [a, a2], [b], 60)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var events := server.submit_turn([
		_client.request_switch(1, &"side_a", &"a", &"a2"),
		_client.request_move(1, &"b", &"tackle", &"a", &"side_b"),
	])
	var switched := _first(events, BattleEvent.SWITCHED)
	var used := _first(events, BattleEvent.ACTION_USED)
	_expect("v2_switching", state.active_for_side(&"side_a").instance_id == &"a2" and switched != null)
	_expect("v2_switch_priority", _event_index(events, switched) < _event_index(events, used))


func _test_switch_validation() -> void:
	var a := _creature(&"a", &"charmander", [&"idle"])
	var a2 := _creature(&"a2", &"bulbasaur", [&"idle"])
	var b := _creature(&"b", &"squirtle", [&"idle"])
	var state := BattleState.create_with_parties(&"switch_bad", [a, a2], [b], 61)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var events := server.submit_turn([
		_client.request_switch(1, &"side_a", &"a", &"b"),
		_client.request_move(1, &"b", &"idle", &"a", &"side_b"),
	])
	_expect("v2_invalid_switch", _rejection_reason(events) == "invalid_switch")


func _test_server_validation() -> void:
	var server := _server(62, [&"tackle"], [&"idle"])
	var nonexistent := BattleAction.new(1, &"missing", &"tackle", &"b")
	var other := _client.request_move(1, &"b", &"idle", &"a")
	var missing_events := server.submit_turn([nonexistent, other])
	var wrong_side_server := _server(62, [&"tackle"], [&"idle"])
	var wrong_side := _client.request_move(1, &"a", &"tackle", &"b", &"side_b")
	var wrong_side_events := wrong_side_server.submit_turn([
		wrong_side, _client.request_move(1, &"b", &"idle", &"a", &"side_b")
	])
	var missing_side_server := _server(62, [&"tackle"], [&"idle"])
	var missing_side_events := missing_side_server.submit_turn([
		_client.request_move(1, &"a", &"tackle", &"b"),
		_client.request_move(1, &"b", &"idle", &"a", &"side_b"),
	])
	var ko_server := _server(62, [&"tackle"], [&"idle"])
	ko_server.state.creature(&"a").current_hp = 0
	var ko_events := ko_server.submit_turn(_move_actions(ko_server.state, &"tackle", &"idle"))
	_expect("v2_actor_not_found", _rejection_reason(missing_events) == "actor_not_found")
	_expect("v2_wrong_participant", _rejection_reason(wrong_side_events) == "wrong_participant")
	_expect("v2_missing_participant", _rejection_reason(missing_side_events) == "missing_participant")
	_expect("v2_ko_actor_rejected", _rejection_reason(ko_events) == "actor_unavailable")


func _test_snapshot_round_trip_v2() -> void:
	var a := _creature(&"a", &"charmander", [&"tackle", &"recover"])
	var bench := _creature(&"a2", &"bulbasaur", [&"mega_drain"])
	var b := _creature(&"b", &"squirtle", [&"idle"])
	a.ability_id = &"blaze"
	a.held_item_id = &"sitrus_berry"
	a.stat_stages.change(StatStages.ATTACK, 2)
	a.status_state.persistent_id = StatusSystem.BADLY_POISONED
	a.status_state.toxic_counter = 2
	var state := BattleState.create_with_parties(&"snapshot_v2", [a, bench], [b], 70)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var text := JSON.stringify(server.snapshot())
	var restored := BattleState.from_dict(JSON.parse_string(text))
	_expect(
		"v2_snapshot_round_trip",
		text == JSON.stringify(restored.to_dict())
		and restored.sides[0].party_ids.size() == 2
		and restored.creature(&"a").ability_id == &"blaze"
		and restored.creature(&"a").stat_stages.get_stage(StatStages.ATTACK) == 2
		and restored.creature(&"a").status_state.toxic_counter == 2,
	)


func _test_snapshot_rng_continuation() -> void:
	var original := _server(71, [&"tackle", &"idle"], [&"tackle", &"idle"])
	original.submit_turn(_move_actions(original.state, &"tackle", &"tackle"))
	var restored_state := BattleState.from_dict(JSON.parse_string(JSON.stringify(original.snapshot())))
	var restored := AuthoritativeBattleServer.new(restored_state, _catalog)
	var original_events := original.submit_turn(_move_actions(original.state, &"tackle", &"tackle"))
	var restored_events := restored.submit_turn(_move_actions(restored.state, &"tackle", &"tackle"))
	_expect(
		"v2_snapshot_rng_continuation",
		JSON.stringify(_dicts(original_events)) == JSON.stringify(_dicts(restored_events))
		and JSON.stringify(original.snapshot()) == JSON.stringify(restored.snapshot()),
	)


func _test_same_seed_same_result() -> void:
	var first := _server(72, [&"thunder"], [&"tackle"], &"pikachu", &"squirtle")
	var second := _server(72, [&"thunder"], [&"tackle"], &"pikachu", &"squirtle")
	var first_events := first.submit_turn(_move_actions(first.state, &"thunder", &"tackle"))
	var second_events := second.submit_turn(_move_actions(second.state, &"thunder", &"tackle"))
	_expect(
		"v2_same_seed_same_result",
		JSON.stringify(_dicts(first_events)) == JSON.stringify(_dicts(second_events))
		and JSON.stringify(first.snapshot()) == JSON.stringify(second.snapshot()),
	)


func _test_trigger_order() -> void:
	var server := _server(73, [&"idle"], [&"idle"])
	server.state.creature(&"a").ability_id = &"intimidate"
	server.state.creature(&"b").ability_id = &"intimidate"
	var events := server.submit_turn(_move_actions(server.state, &"idle", &"idle"))
	var sources: Array[StringName] = []
	for event in events:
		if event.kind == BattleEvent.ABILITY_TRIGGERED:
			sources.append(event.actor_id)
	_expect("v2_deterministic_trigger_order", sources == [&"a", &"b"])


func _test_semantic_events() -> void:
	var server := _server(74, [&"tackle"], [&"idle"])
	var events := server.submit_turn(_move_actions(server.state, &"tackle", &"idle"))
	var semantic := true
	for event in events:
		semantic = semantic and not event.to_dict().has("text")
	_expect("v2_semantic_events", semantic)


func _test_golden_damage_scenario() -> void:
	var seed := _seed_for_failure(BattleRuleset.new().critical_threshold_basis_points())
	var server := _server(seed, [&"tackle"], [&"idle"])
	var events := server.submit_turn(_move_actions(server.state, &"tackle", &"idle"))
	_expect("v2_golden_damage_events", _kinds(events) == [
		BattleEvent.ACTION_USED,
		BattleEvent.PP_CHANGED,
		BattleEvent.DAMAGE_APPLIED,
		BattleEvent.ACTION_USED,
		BattleEvent.PP_CHANGED,
		BattleEvent.TURN_ENDED,
	])
	_expect(
		"v2_golden_damage_state",
		server.state.turn == 1
		and server.state.creature(&"b").current_hp < server.state.creature(&"b").stats.max_hp
		and server.state.rng_state != seed,
	)


func _test_golden_status_scenario() -> void:
	var server := _server(75, [&"idle"], [&"idle"])
	server.state.creature(&"b").status_state.persistent_id = StatusSystem.POISON
	var events := server.submit_turn(_move_actions(server.state, &"idle", &"idle"))
	_expect("v2_golden_status_events", _kinds(events) == [
		BattleEvent.ACTION_USED,
		BattleEvent.PP_CHANGED,
		BattleEvent.ACTION_USED,
		BattleEvent.PP_CHANGED,
		BattleEvent.STATUS_DAMAGE,
		BattleEvent.TURN_ENDED,
	])


func _test_runtime_coverage_contract() -> void:
	var file := FileAccess.open("res://data/battle/runtime_coverage_v2.json", FileAccess.READ)
	var coverage: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	var registry := BattleEffectRegistry.new()
	var move_ids := _string_names_to_strings(registry.runtime_supported_move_ids())
	var ability_ids := _string_names_to_strings(registry.runtime_supported_ability_ids())
	var item_ids := _string_names_to_strings(registry.runtime_supported_item_ids())
	_expect(
		"v2_move_coverage_contract",
		coverage.moves.RUNTIME_SUPPORTED == 541
		and coverage.moves.RUNTIME_SUPPORTED + coverage.moves.PARTIAL_RUNTIME
		+ coverage.moves.DATA_ONLY + coverage.moves.UNSUPPORTED == coverage.moves.DATA_READY
		and move_ids == coverage.moves.newly_runtime_supported,
	)
	_expect(
		"v2_ability_coverage_contract",
		coverage.abilities.RUNTIME_SUPPORTED == 6
		and coverage.abilities.RUNTIME_SUPPORTED + coverage.abilities.DATA_ONLY == coverage.abilities.DATA_READY
		and ability_ids == coverage.abilities.runtime_supported,
	)
	_expect(
		"v2_item_coverage_contract",
		coverage.items.RUNTIME_SUPPORTED == 2
		and coverage.items.RUNTIME_SUPPORTED + coverage.items.DATA_ONLY == coverage.items.DATA_READY
		and item_ids == coverage.items.runtime_supported,
	)


func _test_fase5_multi_hit() -> void:
	var found := false
	var hit_count := 0
	for seed in range(1, 500):
		var server := _server(seed, [&"double_slap"], [&"idle"], &"charmander", &"squirtle")
		var events := server.submit_turn(_move_actions(server.state, &"double_slap", &"idle"))
		var damage_events := 0
		var multi_event: BattleEvent = null
		for event in events:
			if event.kind == BattleEvent.DAMAGE_APPLIED:
				damage_events += 1
			if event.kind == BattleEvent.MULTI_HIT:
				multi_event = event
		if multi_event != null and damage_events >= 2:
			found = true
			hit_count = multi_event.amount
			break
	_expect("fase5_multi_hit_runs", found)
	_expect("fase5_multi_hit_count_valid", found and hit_count >= 2 and hit_count <= 5)


func _test_fase5_static_contact() -> void:
	# Contact move (thunder_punch) must fire the Static ability trigger (contact-based, not physical).
	var contact_event := false
	for seed in range(1, 300):
		var server := _server(seed, [&"thunder_punch"], [&"idle"], &"pikachu", &"squirtle")
		server.state.creature(&"b").ability_id = &"static"
		var events := server.submit_turn(_move_actions(server.state, &"thunder_punch", &"idle"))
		if _source_triggered(events, BattleEvent.ABILITY_TRIGGERED, "static"):
			contact_event = true
			break
	# Non-contact physical move (earthquake) must NOT fire the Static ability trigger.
	var non_contact_event := false
	for seed in range(1, 300):
		var server := _server(seed, [&"earthquake"], [&"idle"], &"geodude", &"squirtle")
		server.state.creature(&"b").ability_id = &"static"
		var events := server.submit_turn(_move_actions(server.state, &"earthquake", &"idle"))
		if _source_triggered(events, BattleEvent.ABILITY_TRIGGERED, "static"):
			non_contact_event = true
			break
	_expect("fase5_static_contact_triggers", contact_event)
	_expect("fase5_static_non_contact_no_trigger", not non_contact_event)


func _server(
	seed: int,
	moves_a: Array[StringName],
	moves_b: Array[StringName],
	species_a: StringName = &"charmander",
	species_b: StringName = &"squirtle",
) -> AuthoritativeBattleServer:
	var state := BattleState.new(&"v2_test", [
		_creature(&"a", species_a, moves_a, 30),
		_creature(&"b", species_b, moves_b, 20),
	], seed)
	return AuthoritativeBattleServer.new(state, _catalog)


func _creature(
	id: StringName,
	species_id: StringName,
	moves: Array[StringName],
	speed: int = 20,
	attack: int = 60,
	special_attack: int = 60,
) -> CreatureInstance:
	return CreatureInstance.new(
		id, species_id, 30, StatBlock.new(160, attack, 55, speed, special_attack, 55), moves
	)


func _move_actions(
	state: BattleState, move_a: StringName, move_b: StringName
) -> Array[BattleAction]:
	return [
		_client.request_move(state.turn + 1, &"a", move_a, state.opponent_of(&"a").instance_id, &"side_a"),
		_client.request_move(state.turn + 1, &"b", move_b, state.opponent_of(&"b").instance_id, &"side_b"),
	]


func _add_test_definitions() -> void:
	_add_move(&"idle", 0, &"normal", "status", -1, 40)
	_add_move(&"always_miss", 40, &"normal", "physical", 0, 10)
	_add_move(&"never_miss", 40, &"normal", "physical", -1, 10)
	_add_move(&"physical_test", 60, &"normal", "physical", 100, 10)
	_add_move(&"special_test", 60, &"normal", "special", 100, 10)
	_add_move(&"ground_test", 60, &"ground", "physical", 100, 10)
	_add_move(&"heavy_test", 100, &"normal", "physical", 100, 10)


func _add_move(
	id: StringName,
	power: int,
	type_id: StringName,
	damage_class: String,
	accuracy: int,
	pp: int,
) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.power = power
	move.type_id = type_id
	move.damage_class = damage_class
	move.accuracy = accuracy
	move.pp = pp
	_catalog.add_move(move)


func _first(events: Array[BattleEvent], kind: StringName) -> BattleEvent:
	for event in events:
		if event.kind == kind:
			return event
	return null


func _rejection_reason(events: Array[BattleEvent]) -> String:
	var event := _first(events, BattleEvent.ACTION_REJECTED)
	return String(event.metadata.get("reason", "")) if event != null else ""


func _effectiveness_category(events: Array[BattleEvent]) -> String:
	var event := _first(events, BattleEvent.TYPE_EFFECTIVENESS)
	return String(event.metadata.get("category", "")) if event != null else ""


func _status_damage(events: Array[BattleEvent], status_id: StringName) -> int:
	for event in events:
		if event.kind == BattleEvent.STATUS_DAMAGE and event.metadata.get("status_id", "") == String(status_id):
			return event.amount
	return 0


func _damage_amount(events: Array[BattleEvent]) -> int:
	var event := _first(events, BattleEvent.DAMAGE_APPLIED)
	return event.amount if event != null else 0


func _source_triggered(events: Array[BattleEvent], kind: StringName, source_id: String) -> bool:
	for event in events:
		if event.kind == kind and event.metadata.get("source_id", "") == source_id:
			return true
	return false


func _move_can_apply_status(
	move_id: StringName,
	status_id: StringName,
	attacker_species: StringName,
	target_species: StringName,
) -> bool:
	for seed in range(1, 500):
		var server := _server(seed, [move_id], [&"idle"], attacker_species, target_species)
		server.submit_turn(_move_actions(server.state, move_id, &"idle"))
		if server.state.creature(&"b").status_state.persistent_id == status_id:
			return true
	return false


func _pinch_ability_works(
	ability_id: StringName,
	move_id: StringName,
	attacker_species: StringName,
	target_species: StringName,
) -> bool:
	var boosted := _server(43, [move_id], [&"idle"], attacker_species, target_species)
	boosted.state.creature(&"a").ability_id = ability_id
	boosted.state.creature(&"a").current_hp = boosted.state.creature(&"a").stats.max_hp / 3
	var boosted_events := boosted.submit_turn(_move_actions(boosted.state, move_id, &"idle"))
	var plain := _server(43, [move_id], [&"idle"], attacker_species, target_species)
	plain.state.creature(&"a").current_hp = plain.state.creature(&"a").stats.max_hp / 3
	var plain_events := plain.submit_turn(_move_actions(plain.state, move_id, &"idle"))
	return (
		_damage_amount(boosted_events) > _damage_amount(plain_events)
		and _source_triggered(boosted_events, BattleEvent.ABILITY_TRIGGERED, String(ability_id))
	)


func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


func _event_index(events: Array[BattleEvent], target: BattleEvent) -> int:
	for index in range(events.size()):
		if events[index] == target:
			return index
	return -1


func _seed_for_success(chance_bp: int) -> int:
	for seed in range(1, 10000):
		if SeededRandomSource.new(seed).roll_basis_points(chance_bp):
			return seed
	return -1


func _seed_for_failure(chance_bp: int) -> int:
	for seed in range(1, 10000):
		if not SeededRandomSource.new(seed).roll_basis_points(chance_bp):
			return seed
	return -1


func _dicts(events: Array[BattleEvent]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		result.append(event.to_dict())
	return result


func _kinds(events: Array[BattleEvent]) -> Array[StringName]:
	var result: Array[StringName] = []
	for event in events:
		result.append(event.kind)
	return result


func _expect(name: String, condition: bool) -> void:
	_check.call(name, condition)
