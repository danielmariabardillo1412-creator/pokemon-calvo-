class_name TrainerTeamStrategicEvaluator
extends RefCounted

# Team-level preservation layer inspired by competitive battle agents: a tactically
# attractive action is penalized if it needlessly risks the only known answer to a
# different observed threat. It uses only own full data + already observed opponents.

var _catalog: DefinitionCatalog
var _profile: TrainerProfile


func _init(
	catalog: DefinitionCatalog,
	profile: TrainerProfile = null,
) -> void:
	_catalog = catalog
	_profile = profile if profile != null else TrainerProfile.balanced()


func evaluate(context: TrainerDecisionContext, action: BattleAction) -> Dictionary:
	if context == null or context.observation == null or action == null or _catalog == null:
		return _result(0, [])
	var observation := context.observation
	if observation.observed_opponents.size() < 2:
		return _result(0, [])
	var current := _view_by_id(observation.own_party, observation.own_active_id)
	if current.is_empty():
		return _result(0, [])
	var future_threats := _future_threats(observation)
	if future_threats.is_empty():
		return _result(0, [])

	var unique_for: Array[String] = _unique_answer_targets(observation, current, future_threats)
	if unique_for.is_empty():
		return _result(0, [])
	var hp_bp := _own_hp_ratio_bp(current)
	if hp_bp > 5500:
		return _result(0, [])

	var magnitude := (5500 - hp_bp) / 2 + 900
	magnitude = magnitude * _profile.preservation_weight_bp / 10000
	if action.action_type == BattleAction.SWITCH:
		return _result(
			magnitude,
			["preserve_unique_answer"],
			{"unique_answer_for": unique_for, "active_hp_ratio_basis_points": hp_bp},
		)
	if action.action_type == BattleAction.MOVE:
		return _result(
			-magnitude,
			["risk_unique_answer"],
			{"unique_answer_for": unique_for, "active_hp_ratio_basis_points": hp_bp},
		)
	return _result(0, [])


func _future_threats(observation: TrainerObservation) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for view in observation.observed_opponents:
		if bool(view.get("is_knocked_out", false)):
			continue
		if StringName(view.get("instance_id", "")) == observation.opponent_active_id:
			continue
		out.append(view)
	return out


func _unique_answer_targets(
	observation: TrainerObservation,
	current: Dictionary,
	threats: Array[Dictionary],
) -> Array[String]:
	var unique: Array[String] = []
	var current_id := StringName(current.get("instance_id", ""))
	for threat in threats:
		var best_id: StringName = &""
		var best := -1
		var second := -1
		for ally in observation.own_party:
			if int(ally.get("current_hp", 0)) <= 0 or bool(ally.get("is_knocked_out", false)):
				continue
			var pressure := _coverage_pressure(ally, threat)
			if pressure > best:
				second = best
				best = pressure
				best_id = StringName(ally.get("instance_id", ""))
			elif pressure > second:
				second = pressure
		if best_id == current_id and best >= 15000 and (second < 0 or second * 100 < best * 70):
			unique.append(String(threat.get("instance_id", "")))
	return unique


func _coverage_pressure(attacker: Dictionary, defender: Dictionary) -> int:
	var attacker_species := _catalog.species(StringName(attacker.get("species_id", "")))
	var defender_species := _catalog.species(StringName(defender.get("species_id", "")))
	if attacker_species == null or defender_species == null:
		return 0
	var best := 0
	for value in attacker.get("moveset", []):
		var slot := value as Dictionary
		if int(slot.get("current_pp", 0)) <= 0:
			continue
		var move := _catalog.move(StringName(slot.get("move_id", "")))
		if move == null or move.power <= 0:
			continue
		var eff_bp := _type_effectiveness_bp(move.type_id, defender_species)
		var stab_bp := 15000 if attacker_species.has_type(move.type_id) else 10000
		var pressure := move.power * eff_bp / 10000
		pressure = pressure * stab_bp / 10000
		best = maxi(best, pressure * 100)
	return best


func _type_effectiveness_bp(
	attack_type_id: StringName,
	defender: CreatureSpecies,
) -> int:
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


func _result(
	score: int,
	reasons: Array[String],
	metadata: Dictionary = {},
) -> Dictionary:
	return {
		"score": score,
		"reasons": reasons.duplicate(),
		"metadata": metadata.duplicate(true),
	}
