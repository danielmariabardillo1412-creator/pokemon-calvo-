class_name TrainerStrategicSwitchingV2TestSuite
extends TrainerItemActionsV2TestSuite

const T_ELECTRIC := &"sw_electric"
const T_GROUND := &"sw_ground"
const T_WATER := &"sw_water"
const T_FIRE := &"sw_fire"
const T_GRASS := &"sw_grass"
const T_NORMAL := &"sw_normal"

const M_ELECTRIC := &"sw_electric_strike"
const M_GROUND := &"sw_ground_strike"
const M_WATER := &"sw_water_strike"
const M_FIRE := &"sw_fire_strike"
const M_GRASS := &"sw_grass_strike"
const M_NORMAL := &"sw_normal_strike"
const M_CHIP := &"sw_chip"
const M_TOXIC := &"sw_toxic"
const M_IDLE := &"sw_idle"

const S_ELECTRIC := &"sw_electric_mon"
const S_GROUND := &"sw_ground_mon"
const S_WATER := &"sw_water_mon"
const S_FIRE := &"sw_fire_mon"
const S_GRASS := &"sw_grass_mon"
const S_NORMAL := &"sw_normal_mon"


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_no_effect_counter_switch()
	_test_reacts_after_opponent_switch()
	_test_revealed_hard_counter_escape()
	_test_immediate_ko_prevents_unnecessary_switch()
	_test_useful_status_route_is_not_false_no_route()
	_test_recent_return_switch_is_penalized()
	_test_productive_sacrifice_preserves_key_bench()
	_test_switch_beats_healing_a_hard_walled_active()


func _build_catalog() -> void:
	super._build_catalog()
	_add_switch_type(T_ELECTRIC, {String(T_GROUND): 0.0, String(T_WATER): 2.0})
	_add_switch_type(T_GROUND, {String(T_ELECTRIC): 2.0, String(T_FIRE): 2.0})
	_add_switch_type(T_WATER, {String(T_GROUND): 2.0, String(T_FIRE): 2.0, String(T_GRASS): 0.5})
	_add_switch_type(T_FIRE, {String(T_GRASS): 2.0, String(T_WATER): 0.5})
	_add_switch_type(T_GRASS, {String(T_WATER): 2.0, String(T_GROUND): 2.0, String(T_FIRE): 0.5})
	_add_switch_type(T_NORMAL, {})

	_add_switch_damage_move(M_ELECTRIC, T_ELECTRIC, 120)
	_add_switch_damage_move(M_GROUND, T_GROUND, 120)
	_add_switch_damage_move(M_WATER, T_WATER, 120)
	_add_switch_damage_move(M_FIRE, T_FIRE, 120)
	_add_switch_damage_move(M_GRASS, T_GRASS, 120)
	_add_switch_damage_move(M_NORMAL, T_NORMAL, 85)
	_add_switch_damage_move(M_CHIP, T_NORMAL, 30)
	_add_switch_status_move(M_TOXIC, [BattleEffectSpec.new(
		BattleEffectSpec.INFLICT_STATUS,
		BattleEffectSpec.OPPONENT,
		0,
		0,
		10000,
		StatusSystem.POISON,
	)])
	_add_switch_status_move(M_IDLE, [])

	_add_switch_species(S_ELECTRIC, T_ELECTRIC, [M_ELECTRIC, M_TOXIC])
	_add_switch_species(S_GROUND, T_GROUND, [M_GROUND])
	_add_switch_species(S_WATER, T_WATER, [M_WATER])
	_add_switch_species(S_FIRE, T_FIRE, [M_FIRE])
	_add_switch_species(S_GRASS, T_GRASS, [M_GRASS])
	_add_switch_species(S_NORMAL, T_NORMAL, [M_NORMAL, M_CHIP, M_IDLE])


func _test_no_effect_counter_switch() -> void:
	var server := _server_from_parties(
		[
			_mon(&"no_route_active", S_ELECTRIC, [M_ELECTRIC], 100, 105, 80, 95),
			_mon(&"no_route_counter", S_WATER, [M_WATER], 100, 115, 95, 80),
		],
		[_mon(&"no_route_foe", S_GROUND, [M_GROUND], 120, 110, 90, 70)],
	)
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_no_route_begin", controller.begin(server))
	var action := controller.choose_action(server)
	_check.call("switch_no_route_selects_switch", action != null and action.action_type == BattleAction.SWITCH)
	_check.call("switch_no_route_selects_water_counter", action != null and action.switch_instance_id == &"no_route_counter")
	_check.call("switch_no_route_reason_recorded", _trace_candidate_has_reason(brain.last_trace, action, "switch:escape_no_effective_route"))


func _test_reacts_after_opponent_switch() -> void:
	var server := _server_from_parties(
		[
			_mon(&"react_active", S_ELECTRIC, [M_ELECTRIC], 100, 110, 80, 95),
			_mon(&"react_counter", S_WATER, [M_WATER], 100, 115, 95, 80),
		],
		[
			_mon(&"react_initial_foe", S_WATER, [M_WATER], 110, 100, 90, 70),
			_mon(&"react_ground_foe", S_GROUND, [M_GROUND], 110, 110, 90, 75),
		],
	)
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_react_begin", controller.begin(server))
	var first_actions: Array[BattleAction] = [
		BattleAction.new(1, &"react_active", M_ELECTRIC, &"react_initial_foe", BattleAction.MOVE, &"side_a"),
		BattleAction.new(1, &"react_initial_foe", &"", &"", BattleAction.SWITCH, &"side_b", &"react_ground_foe"),
	]
	var events := server.submit_turn(first_actions)
	_check.call("switch_react_opponent_switch_turn_accepted", not _contains_event(events, BattleEvent.ACTION_REJECTED))
	_check.call("switch_react_observe", controller.observe(events, server))
	var action := controller.choose_action(server)
	_check.call("switch_react_memory_sees_new_foe", controller.memory.has_seen(&"react_ground_foe"))
	_check.call("switch_react_after_counter_switch", action != null and action.action_type == BattleAction.SWITCH and action.switch_instance_id == &"react_counter")


func _test_revealed_hard_counter_escape() -> void:
	var server := _server_from_parties(
		[
			_mon(&"hard_active", S_GRASS, [M_GRASS], 100, 105, 80, 85),
			_mon(&"hard_counter", S_WATER, [M_WATER], 100, 110, 100, 80),
		],
		[_mon(&"hard_foe", S_FIRE, [M_FIRE], 115, 125, 85, 90)],
	)
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_hard_counter_begin", controller.begin(server))
	controller.memory.reveal_move(&"hard_foe", M_FIRE)
	controller.belief.sync_revealed(controller.memory)
	var action := controller.choose_action(server)
	_check.call("switch_hard_counter_escapes", action != null and action.action_type == BattleAction.SWITCH)
	_check.call("switch_hard_counter_uses_resistant_counter", action != null and action.switch_instance_id == &"hard_counter")
	_check.call("switch_hard_counter_reason_recorded", _trace_candidate_has_reason(brain.last_trace, action, "switch:escape_hard_counter"))


func _test_immediate_ko_prevents_unnecessary_switch() -> void:
	var server := _server_from_parties(
		[
			_mon(&"ko_active", S_WATER, [M_WATER], 100, 130, 90, 90),
			_mon(&"ko_bench", S_GRASS, [M_GRASS], 100, 120, 90, 85),
		],
		[_mon(&"ko_foe", S_GROUND, [M_GROUND], 100, 110, 85, 70)],
	)
	server.state.creature(&"ko_foe").current_hp = 10
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_immediate_ko_begin", controller.begin(server))
	var action := controller.choose_action(server)
	_check.call("switch_immediate_ko_stays", action != null and action.action_type == BattleAction.MOVE)
	_check.call("switch_immediate_ko_uses_finisher", action != null and action.move_id == M_WATER)
	var switch_action := _find_switch(controller.last_context, &"ko_bench")
	var eval := TrainerStrategicSwitchEvaluatorV2.new(_catalog, TrainerProfile.balanced()).evaluate(controller.last_context, switch_action)
	_check.call("switch_immediate_ko_penalty_recorded", _reasons(eval).has("avoid_switch_with_immediate_ko"))


func _test_useful_status_route_is_not_false_no_route() -> void:
	var server := _server_from_parties(
		[
			_mon(&"utility_active", S_ELECTRIC, [M_ELECTRIC, M_TOXIC], 100, 100, 85, 90),
			_mon(&"utility_counter", S_WATER, [M_WATER], 100, 110, 95, 80),
		],
		[_mon(&"utility_foe", S_GROUND, [M_GROUND], 110, 105, 90, 75)],
	)
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_utility_begin", controller.begin(server))
	controller.choose_action(server)
	var switch_action := _find_switch(controller.last_context, &"utility_counter")
	var eval := TrainerStrategicSwitchEvaluatorV2.new(_catalog, TrainerProfile.balanced()).evaluate(controller.last_context, switch_action)
	_check.call("switch_utility_route_not_mislabeled_no_route", not _reasons(eval).has("escape_no_effective_route"))
	_check.call("switch_utility_model_present", String((eval.get("metadata", {}) as Dictionary).get("model", "")) == TrainerStrategicSwitchEvaluatorV2.MODEL_ID)


func _test_recent_return_switch_is_penalized() -> void:
	var server := _server_from_parties(
		[
			_mon(&"ping_a", S_NORMAL, [M_NORMAL], 100, 100, 90, 90),
			_mon(&"ping_b", S_NORMAL, [M_NORMAL], 100, 100, 90, 90),
		],
		[_mon(&"ping_foe", S_NORMAL, [M_IDLE], 100, 90, 90, 70)],
	)
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_ping_begin", controller.begin(server))
	var first_actions: Array[BattleAction] = [
		BattleAction.new(1, &"ping_a", &"", &"", BattleAction.SWITCH, &"side_a", &"ping_b"),
		BattleAction.new(1, &"ping_foe", M_IDLE, &"ping_a", BattleAction.MOVE, &"side_b"),
	]
	var events := server.submit_turn(first_actions)
	_check.call("switch_ping_first_switch_accepted", not _contains_event(events, BattleEvent.ACTION_REJECTED))
	_check.call("switch_ping_observe", controller.observe(events, server))
	var action := controller.choose_action(server)
	_check.call("switch_ping_brain_does_not_return_immediately", action == null or action.action_type != BattleAction.SWITCH or action.switch_instance_id != &"ping_a")
	var return_action := _find_switch(controller.last_context, &"ping_a")
	var eval := TrainerStrategicSwitchEvaluatorV2.new(_catalog, TrainerProfile.balanced()).evaluate(controller.last_context, return_action)
	_check.call("switch_ping_penalty_reason", _reasons(eval).has("avoid_recent_switch_ping_pong"))


func _test_productive_sacrifice_preserves_key_bench() -> void:
	var server := _server_from_parties(
		[
			_mon(&"sac_active", S_NORMAL, [M_CHIP], 100, 70, 55, 60),
			_mon(&"sac_key", S_WATER, [M_WATER], 110, 125, 100, 80),
		],
		[
			_mon(&"sac_current_foe", S_ELECTRIC, [M_ELECTRIC], 115, 135, 85, 110),
			_mon(&"sac_future_foe", S_FIRE, [M_FIRE], 120, 120, 90, 75),
		],
	)
	server.state.creature(&"sac_active").current_hp = 10
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_sacrifice_begin", controller.begin(server))
	controller.memory.mark_seen(&"sac_future_foe")
	controller.memory.reveal_move(&"sac_current_foe", M_ELECTRIC)
	controller.belief.sync_revealed(controller.memory)
	var action := controller.choose_action(server)
	_check.call("switch_sacrifice_stays_to_absorb_ko", action != null and action.action_type == BattleAction.MOVE)
	var move_eval := TrainerStrategicSwitchEvaluatorV2.new(_catalog, TrainerProfile.balanced()).evaluate(controller.last_context, action)
	_check.call("switch_sacrifice_productive_reason", _reasons(move_eval).has("productive_sacrifice_window"))
	var switch_action := _find_switch(controller.last_context, &"sac_key")
	var switch_eval := TrainerStrategicSwitchEvaluatorV2.new(_catalog, TrainerProfile.balanced()).evaluate(controller.last_context, switch_action)
	_check.call("switch_sacrifice_preserves_key_bench_reason", _reasons(switch_eval).has("preserve_key_bench_from_bad_entry"))


func _test_switch_beats_healing_a_hard_walled_active() -> void:
	var server := _server_from_parties(
		[
			_mon(&"heal_wall_active", S_ELECTRIC, [M_ELECTRIC], 100, 100, 80, 90),
			_mon(&"heal_wall_counter", S_WATER, [M_WATER], 110, 120, 100, 80),
		],
		[_mon(&"heal_wall_foe", S_GROUND, [M_GROUND], 120, 110, 90, 70)],
		{HYPER_POTION: 1},
	)
	server.state.creature(&"heal_wall_active").current_hp = 25
	var brain := _brain()
	var controller := TrainerIntelligenceController.new(&"side_a", brain, _catalog)
	_check.call("switch_vs_heal_begin", controller.begin(server))
	var legal := TrainerActionSpace.from_server(server, &"side_a")
	_check.call("switch_vs_heal_hyper_is_legal", _has_item_action(legal, HYPER_POTION, &"heal_wall_active"))
	var action := controller.choose_action(server)
	_check.call("switch_vs_heal_prefers_counter_switch", action != null and action.action_type == BattleAction.SWITCH)
	_check.call("switch_vs_heal_uses_water_counter", action != null and action.switch_instance_id == &"heal_wall_counter")


func _brain() -> StrategicSwitchingTrainerBrain:
	return StrategicSwitchingTrainerBrain.new(
		_catalog,
		TrainerProfile.balanced(),
		TrainerSearchBudget.constrained(2, 2, 128, 3),
	)


func _server_from_parties(
	party_a_raw: Array,
	party_b_raw: Array,
	items: Dictionary = {},
) -> AuthoritativeBattleServer:
	var party_a: Array[CreatureInstance] = []
	var party_b: Array[CreatureInstance] = []
	for raw in party_a_raw:
		party_a.append(raw as CreatureInstance)
	for raw in party_b_raw:
		party_b.append(raw as CreatureInstance)
	var state := BattleState.create_with_parties(&"strategic_switch_test", party_a, party_b, 31337)
	if not items.is_empty():
		var inventory := BattleSideItemInventory.new()
		for raw_id in items.keys():
			inventory.set_quantity(StringName(raw_id), int(items[raw_id]))
		state.set_item_inventory_for_side(&"side_a", inventory)
	return AuthoritativeBattleServer.new(state, _catalog)


func _mon(
	instance_id: StringName,
	species_id: StringName,
	moves: Array[StringName],
	hp: int,
	attack: int,
	defense: int,
	speed: int,
) -> CreatureInstance:
	var creature := CreatureInstance.new(
		instance_id,
		species_id,
		30,
		StatBlock.new(hp, attack, defense, speed, attack, defense),
		moves,
	)
	creature.initialize_move_pp(_catalog)
	return creature


func _add_switch_type(id: StringName, effectiveness: Dictionary) -> void:
	var definition := TypeDefinition.new(String(id), effectiveness)
	definition.id = id
	_catalog.add_type(definition)


func _add_switch_damage_move(id: StringName, type_id: StringName, power: int) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.type_id = type_id
	move.power = power
	move.damage_class = "physical"
	move.accuracy = 100
	move.pp = 20
	move.crit_rate_bp = -10000
	_catalog.add_move(move)


func _add_switch_status_move(id: StringName, effects: Array[BattleEffectSpec]) -> void:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.type_id = T_NORMAL
	move.power = 0
	move.damage_class = "status"
	move.accuracy = 100
	move.pp = 20
	move.crit_rate_bp = -10000
	for effect in effects:
		move.effect_specs.append(effect)
	_catalog.add_move(move)


func _add_switch_species(id: StringName, type_id: StringName, moves: Array[StringName]) -> void:
	var species := CreatureSpecies.new()
	species.id = id
	species.display_name = String(id)
	species.primary_type_id = type_id
	species.type_ids = [type_id]
	species.base_hp = 70
	species.base_attack = 100
	species.base_defense = 80
	species.base_speed = 70
	species.base_special_attack = 100
	species.base_special_defense = 80
	for move_id in moves:
		species.learnset.append(LearnSetEntry.new(1, move_id, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(species)


func _find_switch(context: TrainerDecisionContext, target_id: StringName) -> BattleAction:
	if context == null:
		return null
	for action in context.legal_actions:
		if action != null and action.action_type == BattleAction.SWITCH and action.switch_instance_id == target_id:
			return action
	return null


func _has_item_action(actions: Array[BattleAction], item_id: StringName, target_id: StringName) -> bool:
	for action in actions:
		if action != null and action.action_type == BattleAction.ITEM and action.item_id == item_id and action.target_id == target_id:
			return true
	return false


func _trace_candidate_has_reason(trace: TrainerDecisionTrace, action: BattleAction, reason: String) -> bool:
	if trace == null or action == null:
		return false
	for raw in trace.candidates:
		var candidate := raw as Dictionary
		var action_data := candidate.get("action", {}) as Dictionary
		if StringName(action_data.get("action_type", BattleAction.MOVE)) != action.action_type:
			continue
		if action.action_type == BattleAction.SWITCH and StringName(action_data.get("switch_instance_id", "")) != action.switch_instance_id:
			continue
		if action.action_type == BattleAction.MOVE and StringName(action_data.get("move_id", "")) != action.move_id:
			continue
		for raw_reason in candidate.get("reasons", []):
			if String(raw_reason).contains(reason):
				return true
	return false


func _reasons(result: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for raw in result.get("reasons", []):
		out.append(String(raw))
	return out


func _contains_event(events: Array[BattleEvent], kind: StringName) -> bool:
	for event in events:
		if event.kind == kind:
			return true
	return false
