class_name TrainerThreatOrderedWorldFactory
extends TrainerPlausibleWorldFactory

const ORDERING_MODEL := "plausible_move_threat_order_v1"
const STATUS_THREAT := 1800
const STAGE_THREAT := 650
const HEAL_THREAT := 900
const FLINCH_THREAT := 450


func _plausible_moves(
	context: TrainerDecisionContext,
	creature_id: StringName,
	view: Dictionary,
	species: CreatureSpecies,
	level: int,
) -> Array[StringName]:
	var out := super._plausible_moves(context, creature_id, view, species, level)
	if out.size() <= 1 or context == null or context.observation == null:
		return out
	var confidence_by_move := _confidence_map(context, creature_id, view)
	var target_view := _view_by_id(context.observation.own_party, context.observation.own_active_id)
	out.sort_custom(func(a, b):
		var a_id := StringName(a)
		var b_id := StringName(b)
		var a_threat := _move_threat(a_id, species, target_view)
		var b_threat := _move_threat(b_id, species, target_view)
		if a_threat != b_threat:
			return a_threat > b_threat
		var a_conf := int(confidence_by_move.get(String(a_id), 0))
		var b_conf := int(confidence_by_move.get(String(b_id), 0))
		if a_conf != b_conf:
			return a_conf > b_conf
		return String(a_id) < String(b_id)
	)
	return out


func _confidence_map(
	context: TrainerDecisionContext,
	creature_id: StringName,
	view: Dictionary,
) -> Dictionary:
	var out: Dictionary = {}
	for move_id in view.get("revealed_move_ids", []):
		out[String(move_id)] = 10000
	var candidates := _domain_candidates(context, creature_id, TrainerBeliefState.DOMAIN_MOVE)
	for key in candidates.keys():
		out[String(key)] = maxi(
			int(out.get(String(key), 0)),
			clampi(int((candidates[key] as Dictionary).get("confidence_basis_points", 0)), 0, 10000),
		)
	return out


func _move_threat(
	move_id: StringName,
	attacker_species: CreatureSpecies,
	target_view: Dictionary,
) -> int:
	var move := _catalog.move(move_id)
	if move == null:
		return -1
	var score := 0
	if move.power > 0:
		var accuracy_bp := 10000 if move.accuracy <= 0 else clampi(move.accuracy * 100, 0, 10000)
		var effectiveness_bp := _effectiveness_bp(move.type_id, target_view)
		var stab_bp := 15000 if attacker_species != null and attacker_species.has_type(move.type_id) else 10000
		score = move.power * 100
		score = score * effectiveness_bp / 10000
		score = score * stab_bp / 10000
		score = score * accuracy_bp / 10000
	if move.priority > 0:
		score += move.priority * 500
	for spec in move.effect_specs:
		score += _effect_threat(spec)
	return score


func _effect_threat(spec: BattleEffectSpec, inherited_chance_bp: int = 10000) -> int:
	if spec == null:
		return 0
	var chance_bp := inherited_chance_bp * clampi(spec.chance_basis_points, 0, 10000) / 10000
	if spec.kind == BattleEffectSpec.CHANCE:
		var nested := 0
		for child in spec.children:
			nested += _effect_threat(child, chance_bp)
		return nested
	var value := 0
	match spec.kind:
		BattleEffectSpec.INFLICT_STATUS:
			if spec.target == BattleEffectSpec.OPPONENT:
				value = STATUS_THREAT
		BattleEffectSpec.MODIFY_STAT_STAGE:
			if spec.target == BattleEffectSpec.OPPONENT and spec.value < 0:
				value = abs(spec.value) * STAGE_THREAT
			elif spec.target == BattleEffectSpec.SELF and spec.value > 0:
				value = spec.value * STAGE_THREAT
		BattleEffectSpec.HEAL, BattleEffectSpec.DRAIN:
			if spec.target == BattleEffectSpec.SELF or spec.kind == BattleEffectSpec.DRAIN:
				value = HEAL_THREAT
		BattleEffectSpec.FLINCH:
			value = FLINCH_THREAT
	return value * chance_bp / 10000


func _effectiveness_bp(attack_type_id: StringName, target_view: Dictionary) -> int:
	var target_species := _catalog.species(StringName(target_view.get("species_id", "")))
	if target_species == null:
		return 10000
	var multiplier := 1.0
	for defender_type_id in target_species.type_ids_resolved():
		multiplier *= _catalog.type_multiplier(attack_type_id, defender_type_id)
	return int(round(multiplier * 10000.0))
