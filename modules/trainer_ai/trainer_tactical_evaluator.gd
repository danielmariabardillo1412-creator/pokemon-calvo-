class_name TrainerTacticalEvaluator
extends RefCounted

# Interpretable one-turn evaluator. Opponent numeric stats are never read from live
# battle state. Damage uses a neutral public-species proxy built from known species
# and level; metadata marks that approximation explicitly.

const DAMAGE_PROXY_ID := "public_species_proxy_v1"
const EXPECTED_RANDOM_DAMAGE_BP := 9250

var _catalog: DefinitionCatalog
var _profile: TrainerProfile
var _ruleset := BattleRuleset.new()


func _init(
	catalog: DefinitionCatalog,
	profile: TrainerProfile = null,
) -> void:
	_catalog = catalog
	_profile = profile if profile != null else TrainerProfile.balanced()


func evaluate(context: TrainerDecisionContext, action: BattleAction) -> Dictionary:
	if context == null or context.observation == null or action == null or _catalog == null:
		return _result(-1000000, 0, ["invalid_evaluation_input"])
	if action.action_type == BattleAction.MOVE:
		return _evaluate_move(context.observation, action)
	if action.action_type == BattleAction.SWITCH:
		return _evaluate_switch(context.observation, action)
	return _result(-1000000, 0, ["unsupported_action_type"])


func _evaluate_move(observation: TrainerObservation, action: BattleAction) -> Dictionary:
	var own := _view_by_id(observation.own_party, action.actor_id)
	var opponent := _view_by_id(observation.observed_opponents, observation.opponent_active_id)
	var move := _catalog.move(action.move_id)
	if own.is_empty() or move == null:
		return _result(-1000000, 0, ["missing_move_context"])
	if opponent.is_empty():
		return _result(0, 2500, ["opponent_not_observed"])

	var damage_ratio_bp := _estimated_damage_ratio_bp(own, opponent, move)
	var accuracy_bp := _accuracy_bp(own, opponent, move)
	var expected_damage_bp := damage_ratio_bp * accuracy_bp / 10000
	var score := expected_damage_bp * _profile.damage_weight_bp / 10000
	var accuracy_preference_delta := _profile.accuracy_weight_bp - 10000
	if accuracy_preference_delta != 0:
		score -= (10000 - accuracy_bp) * accuracy_preference_delta / 40000
	var reasons: Array[String] = []
	if expected_damage_bp > 0:
		reasons.append("expected_damage")
	var opponent_hp_bp := clampi(int(opponent.get("hp_ratio_basis_points", 10000)), 0, 10000)
	if damage_ratio_bp >= opponent_hp_bp and damage_ratio_bp > 0:
		score += _profile.ko_bonus
		reasons.append("estimated_ko")
	if move.priority > 0 and opponent_hp_bp <= 3500:
		score += move.priority * 450
		reasons.append("priority_finish_pressure")

	var utility := _effect_utility(own, opponent, move.effect_specs)
	utility = utility * accuracy_bp / 10000
	score += utility
	if utility > 0:
		reasons.append("structured_utility")
	elif utility < 0:
		reasons.append("structured_cost")
	if move.power <= 0 and move.effect_specs.is_empty():
		score -= 600
		reasons.append("no_structured_tactical_value")

	var slot := _move_slot(own, action.move_id)
	if not slot.is_empty() and int(slot.get("current_pp", 0)) == 1:
		score -= 100
		reasons.append("last_pp_cost")

	var confidence := 7200
	if not (opponent.get("revealed_move_ids", []) as Array).is_empty():
		confidence += 500
	return _result(
		score,
		clampi(confidence, 0, 10000),
		reasons,
		{
			"damage_model": DAMAGE_PROXY_ID,
			"estimated_damage_ratio_basis_points": damage_ratio_bp,
			"expected_damage_ratio_basis_points": expected_damage_bp,
			"accuracy_basis_points": accuracy_bp,
			"opponent_hp_ratio_basis_points": opponent_hp_bp,
			"type_effectiveness_basis_points": _move_effectiveness_bp(move, opponent),
		},
	)


func _evaluate_switch(observation: TrainerObservation, action: BattleAction) -> Dictionary:
	var current := _view_by_id(observation.own_party, observation.own_active_id)
	var incoming := _view_by_id(observation.own_party, action.switch_instance_id)
	var opponent := _view_by_id(observation.observed_opponents, observation.opponent_active_id)
	if current.is_empty() or incoming.is_empty():
		return _result(-1000000, 0, ["missing_switch_context"])
	if opponent.is_empty():
		return _result(-_profile.switch_cost, 2500, ["opponent_not_observed"])

	var current_offense := _best_offensive_pressure_bp(current, opponent)
	var incoming_offense := _best_offensive_pressure_bp(incoming, opponent)
	var current_safety := _defensive_safety_bp(current, opponent)
	var incoming_safety := _defensive_safety_bp(incoming, opponent)
	var incoming_hp_bp := _own_hp_ratio_bp(incoming)
	var current_hp_bp := _own_hp_ratio_bp(current)

	var improvement := (incoming_offense - current_offense) / 5
	improvement += (incoming_safety - current_safety) / 4
	var score := improvement * _profile.switch_weight_bp / 10000
	score -= _profile.switch_cost
	var reasons: Array[String] = ["switch_cost"]
	if incoming_offense > current_offense + 1000:
		reasons.append("improved_offensive_matchup")
	if incoming_safety > current_safety + 1000:
		reasons.append("improved_defensive_matchup")
	if current_hp_bp <= 3000 and incoming_hp_bp > current_hp_bp:
		score += 1200 * _profile.preservation_weight_bp / 10000
		reasons.append("preserve_low_hp_active")
	if incoming_hp_bp <= 2500:
		score -= 900
		reasons.append("fragile_switch_in")

	var revealed := opponent.get("revealed_move_ids", []) as Array
	var confidence := 6200 if revealed.is_empty() else 8200
	return _result(
		score,
		confidence,
		reasons,
		{
			"current_offensive_pressure_basis_points": current_offense,
			"incoming_offensive_pressure_basis_points": incoming_offense,
			"current_defensive_safety_basis_points": current_safety,
			"incoming_defensive_safety_basis_points": incoming_safety,
			"current_hp_ratio_basis_points": current_hp_bp,
			"incoming_hp_ratio_basis_points": incoming_hp_bp,
		},
	)


func _estimated_damage_ratio_bp(
	attacker_view: Dictionary,
	defender_view: Dictionary,
	move: MoveDefinition,
) -> int:
	if move.power <= 0:
		return 0
	var attacker_species := _catalog.species(StringName(attacker_view.get("species_id", "")))
	var defender_species := _catalog.species(StringName(defender_view.get("species_id", "")))
	if attacker_species == null or defender_species == null:
		return 0
	var effectiveness_bp := _type_effectiveness_bp(move.type_id, defender_species)
	if effectiveness_bp == 0:
		return 0
	var attacker_stats := attacker_view.get("stats", {}) as Dictionary
	var defender_level := maxi(1, int(defender_view.get("level", 1)))
	var defender_stats := defender_species.stats_for_level(defender_level)
	var physical := move.damage_class == "physical"
	var attack_stat := int(attacker_stats.get("attack" if physical else "special_attack", 1))
	var defense_stat := defender_stats.defense if physical else defender_stats.special_defense
	var attacker_stages := attacker_view.get("stat_stages", {}) as Dictionary
	var defender_stages := defender_view.get("stat_stages", {}) as Dictionary
	var attack_stage_id := StatStages.ATTACK if physical else StatStages.SPECIAL_ATTACK
	var defense_stage_id := StatStages.DEFENSE if physical else StatStages.SPECIAL_DEFENSE
	attack_stat = attack_stat * _ruleset.stat_multiplier_basis_points(
		int(attacker_stages.get(String(attack_stage_id), 0))
	) / 10000
	defense_stat = defense_stat * _ruleset.stat_multiplier_basis_points(
		int(defender_stages.get(String(defense_stage_id), 0))
	) / 10000
	var level := maxi(1, int(attacker_view.get("level", 1)))
	var level_term := (2 * level) / 5 + 2
	var hit_multiplier_bp := _multi_hit_multiplier_bp(move.effect_specs)
	var effective_power := maxi(1, move.power * hit_multiplier_bp / 10000)
	var base_damage := (
		((level_term * effective_power * maxi(1, attack_stat)) / maxi(1, defense_stat)) / 50 + 2
	)
	var stab_bp := 15000 if attacker_species.has_type(move.type_id) else 10000
	var damage := base_damage * stab_bp
	damage = damage * effectiveness_bp / 10000
	if physical and StringName(
		(attacker_view.get("status_state", {}) as Dictionary).get("persistent_id", "")
	) == &"burn":
		damage = damage * _ruleset.burn_physical_multiplier_basis_points / 10000
	damage = damage * EXPECTED_RANDOM_DAMAGE_BP / 10000
	damage = maxi(1, damage / 10000)
	return clampi(damage * 10000 / maxi(1, defender_stats.max_hp), 0, 50000)


func _accuracy_bp(
	attacker_view: Dictionary,
	defender_view: Dictionary,
	move: MoveDefinition,
) -> int:
	var attacker_stages := attacker_view.get("stat_stages", {}) as Dictionary
	var defender_stages := defender_view.get("stat_stages", {}) as Dictionary
	return _ruleset.accuracy_threshold_basis_points(
		move.accuracy,
		int(attacker_stages.get(String(StatStages.ACCURACY), 0)),
		int(defender_stages.get(String(StatStages.EVASION), 0)),
	)


func _effect_utility(
	own: Dictionary,
	opponent: Dictionary,
	specs: Array[BattleEffectSpec],
	chance_bp: int = 10000,
) -> int:
	var total := 0
	for spec in specs:
		if spec == null:
			continue
		var local_chance := chance_bp * clampi(spec.chance_basis_points, 0, 10000) / 10000
		if spec.kind == BattleEffectSpec.CHANCE:
			total += _effect_utility(own, opponent, spec.children, local_chance)
			continue
		var value := 0
		match spec.kind:
			BattleEffectSpec.INFLICT_STATUS:
				if (
					spec.target == BattleEffectSpec.OPPONENT
					and String(opponent.get("persistent_status_id", "")).is_empty()
					and not _known_status_immune(opponent, spec.status_id)
				):
					value = 1800 * _profile.status_weight_bp / 10000
			BattleEffectSpec.CURE_STATUS:
				if spec.target == BattleEffectSpec.SELF and not String(
					(own.get("status_state", {}) as Dictionary).get("persistent_id", "")
				).is_empty():
					value = 1400 * _profile.status_weight_bp / 10000
			BattleEffectSpec.MODIFY_STAT_STAGE:
				var signed_value := spec.value
				if spec.target == BattleEffectSpec.OPPONENT:
					signed_value = -signed_value
				value = signed_value * 650 * _profile.setup_weight_bp / 10000
			BattleEffectSpec.HEAL:
				if spec.target == BattleEffectSpec.SELF:
					var missing_hp_bp := 10000 - _own_hp_ratio_bp(own)
					value = missing_hp_bp * maxi(0, spec.ratio_basis_points) / 10000
					value = value * _profile.preservation_weight_bp / 10000
			BattleEffectSpec.DRAIN:
				value = maxi(0, spec.ratio_basis_points) / 12
			BattleEffectSpec.RECOIL:
				value = -maxi(0, spec.ratio_basis_points) / 10
			BattleEffectSpec.FLINCH:
				value = 450
			BattleEffectSpec.FIXED_DAMAGE:
				var defender_species := _catalog.species(StringName(opponent.get("species_id", "")))
				if defender_species != null:
					var proxy := defender_species.stats_for_level(int(opponent.get("level", 1)))
					value = maxi(0, spec.value) * 10000 / maxi(1, proxy.max_hp)
		total += value * local_chance / 10000
	return total


func _best_offensive_pressure_bp(attacker: Dictionary, defender: Dictionary) -> int:
	var best := 0
	for value in attacker.get("moveset", []):
		var slot := value as Dictionary
		if int(slot.get("current_pp", 0)) <= 0:
			continue
		var move := _catalog.move(StringName(slot.get("move_id", "")))
		if move == null or move.power <= 0:
			continue
		best = maxi(best, _estimated_damage_ratio_bp(attacker, defender, move))
	return best


func _defensive_safety_bp(defender: Dictionary, opponent: Dictionary) -> int:
	var defender_species := _catalog.species(StringName(defender.get("species_id", "")))
	var opponent_species := _catalog.species(StringName(opponent.get("species_id", "")))
	if defender_species == null or opponent_species == null:
		return 5000
	var worst_threat_bp := 10000
	var revealed_moves := opponent.get("revealed_move_ids", []) as Array
	if not revealed_moves.is_empty():
		worst_threat_bp = 0
		for move_id in revealed_moves:
			var move := _catalog.move(StringName(move_id))
			if move == null:
				continue
			var eff := _type_effectiveness_bp(move.type_id, defender_species)
			worst_threat_bp = maxi(worst_threat_bp, eff)
	else:
		for attack_type in opponent_species.type_ids_resolved():
			worst_threat_bp = maxi(
				worst_threat_bp,
				_type_effectiveness_bp(attack_type, defender_species),
			)
	return clampi(20000 - worst_threat_bp, 0, 20000)


func _move_effectiveness_bp(move: MoveDefinition, defender_view: Dictionary) -> int:
	var defender := _catalog.species(StringName(defender_view.get("species_id", "")))
	return _type_effectiveness_bp(move.type_id, defender) if defender != null else 10000


func _type_effectiveness_bp(
	attack_type_id: StringName,
	defender: CreatureSpecies,
) -> int:
	var multiplier := 1.0
	for defender_type_id in defender.type_ids_resolved():
		multiplier *= _catalog.type_multiplier(attack_type_id, defender_type_id)
	return int(round(multiplier * 10000.0))


func _known_status_immune(defender_view: Dictionary, status_id: StringName) -> bool:
	if status_id == &"":
		return false
	var defender := _catalog.species(StringName(defender_view.get("species_id", "")))
	if defender == null:
		return false
	var immunity_types := _ruleset.status_immunity_types(status_id)
	for defender_type_id in defender.type_ids_resolved():
		if immunity_types.has(defender_type_id):
			return true
	return false


func _multi_hit_multiplier_bp(specs: Array[BattleEffectSpec]) -> int:
	for spec in specs:
		if spec != null and spec.kind == BattleEffectSpec.MULTI_HIT:
			var low := maxi(1, spec.min_hits)
			var high := maxi(low, spec.max_hits)
			return (low + high) * 5000
	return 10000


func _own_hp_ratio_bp(view: Dictionary) -> int:
	var stats := view.get("stats", {}) as Dictionary
	var max_hp := maxi(1, int(stats.get("max_hp", 1)))
	return clampi(int(view.get("current_hp", 0)) * 10000 / max_hp, 0, 10000)


func _view_by_id(views: Array[Dictionary], creature_id: StringName) -> Dictionary:
	for view in views:
		if StringName(view.get("instance_id", "")) == creature_id:
			return view
	return {}


func _move_slot(view: Dictionary, move_id: StringName) -> Dictionary:
	for value in view.get("moveset", []):
		var slot := value as Dictionary
		if StringName(slot.get("move_id", "")) == move_id:
			return slot
	return {}


func _result(
	score: int,
	confidence_bp: int,
	reasons: Array[String],
	metadata: Dictionary = {},
) -> Dictionary:
	return {
		"score": score,
		"confidence_basis_points": clampi(confidence_bp, 0, 10000),
		"reasons": reasons.duplicate(),
		"metadata": metadata.duplicate(true),
	}
