class_name TrainerStrategicSwitchEvaluator
extends RefCounted

# Explainable switching urgency layered on top of the ordinary tactical score.
# It uses only own full information plus the sanitized public opponent observation.
# Its purpose is to make obvious counter-switches decisive without encouraging
# constant ping-pong switching when the gain is marginal.

const MODEL_ID := "strategic_switch_urgency_v1"

const NO_EFFECT_SWITCH_BONUS := 8000
const CLEAR_OFFENSE_GAIN_BONUS := 2600
const ESCAPE_SUPER_EFFECTIVE_BONUS := 3600
const IMMEDIATE_KO_STAY_PENALTY := 4200
const POINTLESS_SWITCH_PENALTY := 1800

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
	if action.action_type != BattleAction.SWITCH:
		return _result(0, [])

	var observation := context.observation
	var current := _view_by_id(observation.own_party, observation.own_active_id)
	var incoming := _view_by_id(observation.own_party, action.switch_instance_id)
	var opponent := _view_by_id(observation.observed_opponents, observation.opponent_active_id)
	if current.is_empty() or incoming.is_empty() or opponent.is_empty():
		return _result(0, [])

	var current_offense := _best_offensive_pressure_bp(current, opponent)
	var incoming_offense := _best_offensive_pressure_bp(incoming, opponent)
	var current_threat := _worst_public_threat_bp(current, opponent)
	var incoming_threat := _worst_public_threat_bp(incoming, opponent)
	var opponent_hp_bp := clampi(int(opponent.get("hp_ratio_basis_points", 10000)), 0, 10000)

	var raw_score := 0
	var reasons: Array[String] = []

	# If the active creature literally has no damaging route into the observed opponent,
	# but a healthy bench creature does, the generic switch cost must not keep it trapped.
	if current_offense <= 0 and incoming_offense > 0 and _own_hp_ratio_bp(incoming) > 2500:
		raw_score += NO_EFFECT_SWITCH_BONUS
		reasons.append("active_has_no_effective_damage")

	# Reward a material offensive counter, not a tiny numerical improvement.
	if (
		incoming_offense >= current_offense + 3000
		and incoming_offense * 100 >= maxi(1, current_offense) * 160
	):
		raw_score += CLEAR_OFFENSE_GAIN_BONUS
		reasons.append("clear_offensive_matchup_gain")

	# Known/reasonably public type pressure is enough to justify escaping a bad matchup.
	# Revealed moves take precedence; otherwise only the opponent species' own public STAB
	# types are considered. Hidden coverage moves are never read here.
	if current_threat >= 20000 and incoming_threat <= 10000:
		raw_score += ESCAPE_SUPER_EFFECTIVE_BONUS
		reasons.append("escape_super_effective_threat")
	elif current_threat >= 20000 and incoming_threat + 5000 <= current_threat:
		raw_score += ESCAPE_SUPER_EFFECTIVE_BONUS / 2
		reasons.append("improved_defensive_escape")

	# Do not throw away a public immediate KO merely because a bench option is also good.
	if current_offense > 0 and current_offense >= opponent_hp_bp:
		raw_score -= IMMEDIATE_KO_STAY_PENALTY
		reasons.append("avoid_switch_with_immediate_ko")

	# Anti-ping-pong: when neither offense nor safety materially improves, switching is
	# actively worse than simply staying. The ordinary tactical switch cost still applies too.
	var offense_gain := incoming_offense - current_offense
	var safety_gain := current_threat - incoming_threat
	if offense_gain < 1200 and safety_gain < 5000:
		raw_score -= POINTLESS_SWITCH_PENALTY
		reasons.append("avoid_pointless_switch")

	var weighted_score := raw_score * _profile.switch_weight_bp / 10000
	return _result(
		weighted_score,
		reasons,
		{
			"model": MODEL_ID,
			"current_offensive_pressure_basis_points": current_offense,
			"incoming_offensive_pressure_basis_points": incoming_offense,
			"current_public_threat_basis_points": current_threat,
			"incoming_public_threat_basis_points": incoming_threat,
			"opponent_hp_ratio_basis_points": opponent_hp_bp,
		},
	)


func _best_offensive_pressure_bp(attacker: Dictionary, defender: Dictionary) -> int:
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
		var effectiveness_bp := _type_effectiveness_bp(move.type_id, defender_species)
		if effectiveness_bp <= 0:
			continue
		var stab_bp := 15000 if attacker_species.has_type(move.type_id) else 10000
		var pressure := move.power * effectiveness_bp / 10000
		pressure = pressure * stab_bp / 10000
		best = maxi(best, pressure * 100)
	return best


func _worst_public_threat_bp(defender: Dictionary, opponent: Dictionary) -> int:
	var defender_species := _catalog.species(StringName(defender.get("species_id", "")))
	var opponent_species := _catalog.species(StringName(opponent.get("species_id", "")))
	if defender_species == null or opponent_species == null:
		return 10000
	var revealed_moves := opponent.get("revealed_move_ids", []) as Array
	var worst := 0
	if not revealed_moves.is_empty():
		for raw_move_id in revealed_moves:
			var move := _catalog.move(StringName(raw_move_id))
			if move == null or move.power <= 0:
				continue
			worst = maxi(worst, _type_effectiveness_bp(move.type_id, defender_species))
		return worst if worst > 0 else 10000
	for attack_type in opponent_species.type_ids_resolved():
		worst = maxi(worst, _type_effectiveness_bp(attack_type, defender_species))
	return worst if worst > 0 else 10000


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


func _result(score: int, reasons: Array[String], metadata: Dictionary = {}) -> Dictionary:
	return {
		"score": score,
		"reasons": reasons.duplicate(),
		"metadata": metadata.duplicate(true),
	}
