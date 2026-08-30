class_name TrainerStrategicSwitchEvaluatorV2
extends RefCounted

const MODEL_ID := "strategic_switch_expected_matchup_v2"
const EXPECTED_RANDOM_DAMAGE_BP := 9250

const NO_ROUTE_SWITCH_BONUS := 6200
const CLEAR_OFFENSE_GAIN_BONUS := 2200
const ESCAPE_HARD_COUNTER_BONUS := 3600
const IMPROVED_DEFENSE_BONUS := 1500
const IMMEDIATE_KO_SWITCH_PENALTY := 4200
const POINTLESS_SWITCH_PENALTY := 2200
const RECENT_RETURN_SWITCH_PENALTY := 1800
const KEY_BENCH_EXPOSURE_PENALTY := 2600
const NO_ROUTE_STAY_PENALTY := 4200
const HARD_COUNTER_STAY_PENALTY := 2400
const PRODUCTIVE_SACRIFICE_BONUS := 1200

var _catalog: DefinitionCatalog
var _profile: TrainerProfile
var _ruleset := BattleRuleset.new()


func _init(catalog: DefinitionCatalog, profile: TrainerProfile = null) -> void:
	_catalog = catalog
	_profile = profile if profile != null else TrainerProfile.balanced()


func evaluate(context: TrainerDecisionContext, action: BattleAction) -> Dictionary:
	if context == null or context.observation == null or action == null or _catalog == null:
		return _result(0, [], {})
	var observation := context.observation
	var current := _view_by_id(observation.own_party, observation.own_active_id)
	var opponent := _view_by_id(observation.observed_opponents, observation.opponent_active_id)
	if current.is_empty() or opponent.is_empty():
		return _result(0, [], {"model": MODEL_ID})

	var current_offense := _best_own_damage_ratio_bp(current, opponent)
	var opponent_hp_bp := clampi(int(opponent.get("hp_ratio_basis_points", 10000)), 0, 10000)
	var current_threat := _public_threat_damage_bp(context, current, opponent)
	var best_switch := _best_switch_summary(context)
	var immediate_ko := current_offense >= opponent_hp_bp and current_offense > 0
	var current_has_utility := _has_meaningful_utility_route(current, opponent)

	if action.action_type == BattleAction.SWITCH:
		return _evaluate_switch(
			context,
			action,
			current,
			opponent,
			current_offense,
			current_threat,
			opponent_hp_bp,
			immediate_ko,
			current_has_utility,
		)
	return _evaluate_stay_action(
		context,
		action,
		current,
		opponent,
		current_offense,
		current_threat,
		best_switch,
		immediate_ko,
		current_has_utility,
	)


func _evaluate_switch(
	context: TrainerDecisionContext,
	action: BattleAction,
	current: Dictionary,
	opponent: Dictionary,
	current_offense: int,
	current_threat: int,
	opponent_hp_bp: int,
	immediate_ko: bool,
	current_has_utility: bool,
) -> Dictionary:
	var observation := context.observation
	var incoming := _view_by_id(observation.own_party, action.switch_instance_id)
	if incoming.is_empty():
		return _result(0, [], {"model": MODEL_ID})

	var incoming_offense := _best_own_damage_ratio_bp(incoming, opponent)
	var incoming_threat := _public_threat_damage_bp(context, incoming, opponent)
	var current_hp_bp := _own_hp_ratio_bp(current)
	var incoming_hp_bp := _own_hp_ratio_bp(incoming)
	var raw_score := 0
	var reasons: Array[String] = []

	if current_offense <= 0 and not current_has_utility and incoming_offense > 0 and incoming_hp_bp > 2000:
		raw_score += NO_ROUTE_SWITCH_BONUS
		reasons.append("escape_no_effective_route")

	if (
		incoming_offense >= current_offense + 2500
		and incoming_offense * 100 >= maxi(1, current_offense) * 150
	):
		raw_score += CLEAR_OFFENSE_GAIN_BONUS
		reasons.append("clear_offensive_matchup_gain")

	if current_threat >= 6500 and incoming_threat * 100 <= current_threat * 65:
		raw_score += ESCAPE_HARD_COUNTER_BONUS
		reasons.append("escape_hard_counter")
	elif current_threat >= 4500 and incoming_threat + 1800 <= current_threat:
		raw_score += IMPROVED_DEFENSE_BONUS
		reasons.append("improved_defensive_matchup")

	if immediate_ko:
		raw_score -= IMMEDIATE_KO_SWITCH_PENALTY
		reasons.append("avoid_switch_with_immediate_ko")

	var offense_gain := incoming_offense - current_offense
	var safety_gain := current_threat - incoming_threat
	if offense_gain < 1200 and safety_gain < 1200:
		raw_score -= POINTLESS_SWITCH_PENALTY
		reasons.append("avoid_pointless_switch")

	if _is_recent_return_switch(context, action.switch_instance_id) and offense_gain < 2500 and safety_gain < 2500:
		raw_score -= RECENT_RETURN_SWITCH_PENALTY
		reasons.append("avoid_recent_switch_ping_pong")

	var current_future := _future_value_bp(context, current)
	var incoming_future := _future_value_bp(context, incoming)
	if (
		current_hp_bp <= 1800
		and incoming_future >= current_future + 2500
		and incoming_threat >= 4500
	):
		raw_score -= KEY_BENCH_EXPOSURE_PENALTY
		reasons.append("preserve_key_bench_from_bad_entry")

	if incoming_hp_bp <= 1800:
		raw_score -= 1000
		reasons.append("avoid_fragile_entry")

	var weighted := raw_score * _profile.switch_weight_bp / 10000
	return _result(
		weighted,
		reasons,
		{
			"model": MODEL_ID,
			"current_offense_damage_basis_points": current_offense,
			"incoming_offense_damage_basis_points": incoming_offense,
			"current_public_threat_damage_basis_points": current_threat,
			"incoming_public_threat_damage_basis_points": incoming_threat,
			"current_hp_ratio_basis_points": current_hp_bp,
			"incoming_hp_ratio_basis_points": incoming_hp_bp,
			"opponent_hp_ratio_basis_points": opponent_hp_bp,
			"current_future_value_basis_points": current_future,
			"incoming_future_value_basis_points": incoming_future,
		},
	)


func _evaluate_stay_action(
	context: TrainerDecisionContext,
	action: BattleAction,
	current: Dictionary,
	opponent: Dictionary,
	current_offense: int,
	current_threat: int,
	best_switch: Dictionary,
	immediate_ko: bool,
	current_has_utility: bool,
) -> Dictionary:
	var raw_score := 0
	var reasons: Array[String] = []
	var best_switch_offense := int(best_switch.get("offense", 0))
	var best_switch_threat := int(best_switch.get("threat", 10000))
	var best_switch_id := String(best_switch.get("instance_id", ""))

	var active_targeted_item := (
		action.action_type == BattleAction.ITEM
		and action.target_id == context.observation.own_active_id
	)
	if (
		current_offense <= 0
		and not current_has_utility
		and best_switch_offense > 0
		and (action.action_type == BattleAction.MOVE or active_targeted_item)
	):
		raw_score -= NO_ROUTE_STAY_PENALTY
		reasons.append("avoid_staying_without_effective_route")

	if (
		current_threat >= 6500
		and best_switch_threat * 100 <= current_threat * 65
		and not immediate_ko
		and (action.action_type == BattleAction.MOVE or active_targeted_item)
	):
		raw_score -= HARD_COUNTER_STAY_PENALTY
		reasons.append("avoid_staying_in_hard_counter")

	if immediate_ko and action.action_type == BattleAction.MOVE:
		raw_score += 1600
		reasons.append("finish_before_switching")

	var current_future := _future_value_bp(context, current)
	var best_bench_future := _best_bench_future_value_bp(context)
	if (
		action.action_type == BattleAction.MOVE
		and _own_hp_ratio_bp(current) <= 1800
		and current_future + 2500 <= best_bench_future
		and current_offense > 0
		and best_switch_threat >= 4500
	):
		raw_score += PRODUCTIVE_SACRIFICE_BONUS
		reasons.append("productive_sacrifice_window")

	return _result(
		raw_score,
		reasons,
		{
			"model": MODEL_ID,
			"current_offense_damage_basis_points": current_offense,
			"current_public_threat_damage_basis_points": current_threat,
			"best_switch_instance_id": best_switch_id,
			"best_switch_offense_damage_basis_points": best_switch_offense,
			"best_switch_public_threat_damage_basis_points": best_switch_threat,
			"current_future_value_basis_points": current_future,
			"best_bench_future_value_basis_points": best_bench_future,
		},
	)


func _best_switch_summary(context: TrainerDecisionContext) -> Dictionary:
	var observation := context.observation
	var opponent := _view_by_id(observation.observed_opponents, observation.opponent_active_id)
	var best: Dictionary = {"instance_id": "", "offense": 0, "threat": 10000, "score": -2147483648}
	for ally in observation.own_party:
		var ally_id := StringName(ally.get("instance_id", ""))
		if ally_id == observation.own_active_id:
			continue
		if int(ally.get("current_hp", 0)) <= 0 or bool(ally.get("is_knocked_out", false)):
			continue
		var offense := _best_own_damage_ratio_bp(ally, opponent)
		var threat := _public_threat_damage_bp(context, ally, opponent)
		var score := offense - threat / 2 + _own_hp_ratio_bp(ally) / 10
		if score > int(best.score) or (score == int(best.score) and String(ally_id) < String(best.instance_id)):
			best = {
				"instance_id": String(ally_id),
				"offense": offense,
				"threat": threat,
				"score": score,
			}
	return best


func _best_bench_future_value_bp(context: TrainerDecisionContext) -> int:
	var best := 0
	for ally in context.observation.own_party:
		var ally_id := StringName(ally.get("instance_id", ""))
		if ally_id == context.observation.own_active_id:
			continue
		if int(ally.get("current_hp", 0)) <= 0 or bool(ally.get("is_knocked_out", false)):
			continue
		best = maxi(best, _future_value_bp(context, ally))
	return best


func _future_value_bp(context: TrainerDecisionContext, ally: Dictionary) -> int:
	var total := 0
	var count := 0
	for opponent in context.observation.observed_opponents:
		if bool(opponent.get("is_knocked_out", false)):
			continue
		if StringName(opponent.get("instance_id", "")) == context.observation.opponent_active_id:
			continue
		var offense := _best_own_damage_ratio_bp(ally, opponent)
		var threat := _public_threat_damage_bp(context, ally, opponent)
		var safety := clampi(10000 - threat, -10000, 10000)
		total += offense + safety / 2
		count += 1
	if count <= 0:
		return 0
	return total / count


func _best_own_damage_ratio_bp(attacker: Dictionary, defender: Dictionary) -> int:
	var best := 0
	for raw_slot in attacker.get("moveset", []):
		var slot := raw_slot as Dictionary
		if int(slot.get("current_pp", 0)) <= 0:
			continue
		var move := _catalog.move(StringName(slot.get("move_id", "")))
		if move == null or move.power <= 0:
			continue
		best = maxi(best, _own_damage_ratio_bp(attacker, defender, move))
	return best


func _own_damage_ratio_bp(attacker: Dictionary, defender: Dictionary, move: MoveDefinition) -> int:
	var attacker_species := _catalog.species(StringName(attacker.get("species_id", "")))
	var defender_species := _catalog.species(StringName(defender.get("species_id", "")))
	if attacker_species == null or defender_species == null or move.power <= 0:
		return 0
	var defender_stats := defender_species.stats_for_level(maxi(1, int(defender.get("level", 1))))
	var attacker_stats := attacker.get("stats", {}) as Dictionary
	var physical := move.damage_class == "physical"
	var attack_stat := int(attacker_stats.get("attack" if physical else "special_attack", 1))
	var defense_stat := defender_stats.defense if physical else defender_stats.special_defense
	var attacker_stages := attacker.get("stat_stages", {}) as Dictionary
	var defender_stages := defender.get("stat_stages", {}) as Dictionary
	attack_stat = attack_stat * _ruleset.stat_multiplier_basis_points(int(attacker_stages.get(String(StatStages.ATTACK if physical else StatStages.SPECIAL_ATTACK), 0))) / 10000
	defense_stat = defense_stat * _ruleset.stat_multiplier_basis_points(int(defender_stages.get(String(StatStages.DEFENSE if physical else StatStages.SPECIAL_DEFENSE), 0))) / 10000
	var level := maxi(1, int(attacker.get("level", 1)))
	var base_damage := ((((2 * level) / 5 + 2) * move.power * maxi(1, attack_stat)) / maxi(1, defense_stat)) / 50 + 2
	var stab_bp := 15000 if attacker_species.has_type(move.type_id) else 10000
	var eff_bp := _type_effectiveness_bp(move.type_id, defender_species)
	if eff_bp <= 0:
		return 0
	var damage := base_damage * stab_bp / 10000
	damage = damage * eff_bp / 10000
	damage = damage * EXPECTED_RANDOM_DAMAGE_BP / 10000
	damage = damage * _accuracy_bp(move) / 10000
	return clampi(damage * 10000 / maxi(1, defender_stats.max_hp), 0, 50000)


func _public_threat_damage_bp(
	context: TrainerDecisionContext,
	defender: Dictionary,
	opponent: Dictionary,
) -> int:
	var best := 0
	var seen: Dictionary = {}
	for raw_move_id in opponent.get("revealed_move_ids", []):
		var move_id := StringName(raw_move_id)
		seen[move_id] = true
		best = maxi(best, _public_move_threat_bp(defender, opponent, move_id, 10000))
	var opponent_id := StringName(opponent.get("instance_id", ""))
	var hypotheses: Dictionary = context.belief_snapshot.get("hypotheses", {})
	var creature_hypotheses: Dictionary = hypotheses.get(String(opponent_id), {})
	var move_candidates: Dictionary = creature_hypotheses.get(String(TrainerBeliefState.DOMAIN_MOVE), {})
	for raw_id in move_candidates.keys():
		var move_id := StringName(raw_id)
		if seen.has(move_id):
			continue
		var record := move_candidates[raw_id] as Dictionary
		var confidence := clampi(int(record.get("confidence_basis_points", 0)), 0, 10000)
		best = maxi(best, _public_move_threat_bp(defender, opponent, move_id, confidence))
	if best > 0:
		return best
	# Belief-free fallback: public species STAB typing only, at half confidence.
	var opponent_species := _catalog.species(StringName(opponent.get("species_id", "")))
	if opponent_species == null:
		return 0
	for attack_type in opponent_species.type_ids_resolved():
		var synthetic := MoveDefinition.new()
		synthetic.id = &"public_stab_proxy"
		synthetic.type_id = attack_type
		synthetic.power = 70
		synthetic.damage_class = "physical"
		synthetic.accuracy = 100
		best = maxi(best, _public_move_threat_from_definition_bp(defender, opponent, synthetic, 5000))
	return best


func _public_move_threat_bp(
	defender: Dictionary,
	opponent: Dictionary,
	move_id: StringName,
	confidence_bp: int,
) -> int:
	var move := _catalog.move(move_id)
	if move == null or move.power <= 0 or confidence_bp <= 0:
		return 0
	return _public_move_threat_from_definition_bp(defender, opponent, move, confidence_bp)


func _public_move_threat_from_definition_bp(
	defender: Dictionary,
	opponent: Dictionary,
	move: MoveDefinition,
	confidence_bp: int,
) -> int:
	var attacker_species := _catalog.species(StringName(opponent.get("species_id", "")))
	var defender_species := _catalog.species(StringName(defender.get("species_id", "")))
	if attacker_species == null or defender_species == null:
		return 0
	var attacker_stats := attacker_species.stats_for_level(maxi(1, int(opponent.get("level", 1))))
	var defender_stats := defender.get("stats", {}) as Dictionary
	var physical := move.damage_class == "physical"
	var attack_stat := attacker_stats.attack if physical else attacker_stats.special_attack
	var defense_stat := int(defender_stats.get("defense" if physical else "special_defense", 1))
	var attacker_stages := opponent.get("stat_stages", {}) as Dictionary
	var defender_stages := defender.get("stat_stages", {}) as Dictionary
	attack_stat = attack_stat * _ruleset.stat_multiplier_basis_points(int(attacker_stages.get(String(StatStages.ATTACK if physical else StatStages.SPECIAL_ATTACK), 0))) / 10000
	defense_stat = defense_stat * _ruleset.stat_multiplier_basis_points(int(defender_stages.get(String(StatStages.DEFENSE if physical else StatStages.SPECIAL_DEFENSE), 0))) / 10000
	var level := maxi(1, int(opponent.get("level", 1)))
	var base_damage := ((((2 * level) / 5 + 2) * move.power * maxi(1, attack_stat)) / maxi(1, defense_stat)) / 50 + 2
	var stab_bp := 15000 if attacker_species.has_type(move.type_id) else 10000
	var eff_bp := _type_effectiveness_bp(move.type_id, defender_species)
	if eff_bp <= 0:
		return 0
	var damage := base_damage * stab_bp / 10000
	damage = damage * eff_bp / 10000
	damage = damage * EXPECTED_RANDOM_DAMAGE_BP / 10000
	damage = damage * _accuracy_bp(move) / 10000
	var max_hp := maxi(1, int(defender_stats.get("max_hp", 1)))
	var ratio := clampi(damage * 10000 / max_hp, 0, 50000)
	return ratio * clampi(confidence_bp, 0, 10000) / 10000


func _has_meaningful_utility_route(attacker: Dictionary, defender: Dictionary) -> bool:
	for raw_slot in attacker.get("moveset", []):
		var slot := raw_slot as Dictionary
		if int(slot.get("current_pp", 0)) <= 0:
			continue
		var move := _catalog.move(StringName(slot.get("move_id", "")))
		if move == null or move.power > 0:
			continue
		for spec in move.effect_specs:
			if spec == null:
				continue
			if spec.kind in [BattleEffectSpec.INFLICT_STATUS, BattleEffectSpec.MODIFY_STAT_STAGE, BattleEffectSpec.HEAL]:
				if spec.kind != BattleEffectSpec.INFLICT_STATUS or not _known_status_immune(defender, spec.status_id):
					return true
	return false


func _is_recent_return_switch(context: TrainerDecisionContext, proposed_target: StringName) -> bool:
	var events := context.memory_snapshot.get("event_log", []) as Array
	var current_turn := context.observation.turn
	for index in range(events.size() - 1, -1, -1):
		var event := events[index] as Dictionary
		if StringName(event.get("kind", "")) != BattleEvent.SWITCHED:
			continue
		if int(event.get("turn", -99)) < current_turn - 1:
			break
		var target_id := StringName(event.get("target_id", ""))
		if not _is_own_id(context.observation, target_id):
			continue
		# SWITCHED actor_id is the outgoing creature and target_id the incoming one.
		return StringName(event.get("actor_id", "")) == proposed_target
	return false


func _is_own_id(observation: TrainerObservation, creature_id: StringName) -> bool:
	return not _view_by_id(observation.own_party, creature_id).is_empty()


func _known_status_immune(defender_view: Dictionary, status_id: StringName) -> bool:
	var species := _catalog.species(StringName(defender_view.get("species_id", "")))
	if species == null:
		return false
	for type_id in species.type_ids_resolved():
		if _ruleset.status_immunity_types(status_id).has(type_id):
			return true
	return false


func _accuracy_bp(move: MoveDefinition) -> int:
	return 10000 if move.accuracy < 0 else clampi(move.accuracy * 100, 0, 10000)


func _type_effectiveness_bp(attack_type_id: StringName, defender: CreatureSpecies) -> int:
	var multiplier := 1.0
	for defender_type_id in defender.type_ids_resolved():
		multiplier *= _catalog.type_multiplier(attack_type_id, defender_type_id)
	return int(round(multiplier * 10000.0))


func _own_hp_ratio_bp(view: Dictionary) -> int:
	var stats := view.get("stats", {}) as Dictionary
	var max_hp := maxi(1, int(stats.get("max_hp", 1)))
	return clampi(int(view.get("current_hp", 0)) * 10000 / max_hp, 0, 10000)


func _view_by_id(views: Array[Dictionary], creature_id: StringName) -> Dictionary:
	for view in views:
		if StringName(view.get("instance_id", "")) == creature_id:
			return view
	return {}


func _result(score: int, reasons: Array[String], metadata: Dictionary) -> Dictionary:
	return {
		"score": score,
		"confidence_basis_points": 8500,
		"reasons": reasons.duplicate(),
		"metadata": metadata.duplicate(true),
	}
