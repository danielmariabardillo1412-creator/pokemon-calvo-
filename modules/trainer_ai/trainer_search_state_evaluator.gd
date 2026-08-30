class_name TrainerSearchStateEvaluator
extends RefCounted

const TERMINAL_SCORE := 100000
const KO_SCORE := 7000
const STATUS_SCORE := 700


static func evaluate(
	before: BattleState,
	after: BattleState,
	observer_side_id: StringName,
) -> Dictionary:
	if before == null or after == null or observer_side_id == &"":
		return {"score": -TERMINAL_SCORE, "reasons": ["invalid_search_state"], "metadata": {}}
	var own_before := _side(before, observer_side_id)
	var own_after := _side(after, observer_side_id)
	var foe_before := _other_side(before, observer_side_id)
	var foe_after := _other_side(after, observer_side_id)
	if own_before == null or own_after == null or foe_before == null or foe_after == null:
		return {"score": -TERMINAL_SCORE, "reasons": ["missing_search_side"], "metadata": {}}

	var own_alive_before := _alive_count(before, own_before)
	var own_alive_after := _alive_count(after, own_after)
	var foe_alive_before := _alive_count(before, foe_before)
	var foe_alive_after := _alive_count(after, foe_after)
	var reasons: Array[String] = []
	if foe_alive_after == 0:
		return {
			"score": TERMINAL_SCORE,
			"reasons": ["simulated_victory"],
			"metadata": _metadata(before, after, own_before, own_after, foe_before, foe_after),
		}
	if own_alive_after == 0:
		return {
			"score": -TERMINAL_SCORE,
			"reasons": ["simulated_defeat"],
			"metadata": _metadata(before, after, own_before, own_after, foe_before, foe_after),
		}

	var own_hp_before := _party_hp_ratio_sum(before, own_before)
	var own_hp_after := _party_hp_ratio_sum(after, own_after)
	var foe_hp_before := _party_hp_ratio_sum(before, foe_before)
	var foe_hp_after := _party_hp_ratio_sum(after, foe_after)
	var own_hp_loss := maxi(0, own_hp_before - own_hp_after)
	var foe_hp_loss := maxi(0, foe_hp_before - foe_hp_after)
	var score := foe_hp_loss - own_hp_loss
	if foe_hp_loss > 0:
		reasons.append("simulated_damage_dealt")
	if own_hp_loss > 0:
		reasons.append("simulated_damage_taken")
	var foe_kos := maxi(0, foe_alive_before - foe_alive_after)
	var own_kos := maxi(0, own_alive_before - own_alive_after)
	score += foe_kos * KO_SCORE
	score -= own_kos * KO_SCORE
	if foe_kos > 0:
		reasons.append("simulated_ko_gain")
	if own_kos > 0:
		reasons.append("simulated_ko_loss")

	var own_status_delta := _persistent_status_count(after, own_after) - _persistent_status_count(before, own_before)
	var foe_status_delta := _persistent_status_count(after, foe_after) - _persistent_status_count(before, foe_before)
	score += foe_status_delta * STATUS_SCORE
	score -= own_status_delta * STATUS_SCORE
	if foe_status_delta > 0:
		reasons.append("simulated_status_gain")
	if own_status_delta > 0:
		reasons.append("simulated_status_cost")
	if reasons.is_empty():
		reasons.append("neutral_simulated_turn")
	return {
		"score": score,
		"reasons": reasons,
		"metadata": _metadata(before, after, own_before, own_after, foe_before, foe_after),
	}


static func _metadata(
	before: BattleState,
	after: BattleState,
	own_before: BattleSide,
	own_after: BattleSide,
	foe_before: BattleSide,
	foe_after: BattleSide,
) -> Dictionary:
	return {
		"own_hp_ratio_sum_before": _party_hp_ratio_sum(before, own_before),
		"own_hp_ratio_sum_after": _party_hp_ratio_sum(after, own_after),
		"opponent_hp_ratio_sum_before": _party_hp_ratio_sum(before, foe_before),
		"opponent_hp_ratio_sum_after": _party_hp_ratio_sum(after, foe_after),
		"own_alive_before": _alive_count(before, own_before),
		"own_alive_after": _alive_count(after, own_after),
		"opponent_alive_before": _alive_count(before, foe_before),
		"opponent_alive_after": _alive_count(after, foe_after),
	}


static func _party_hp_ratio_sum(state: BattleState, side: BattleSide) -> int:
	var total := 0
	for creature_id in side.party_ids:
		var creature := state.creature(creature_id)
		if creature == null or creature.stats == null or creature.stats.max_hp <= 0:
			continue
		total += clampi(creature.current_hp * 10000 / creature.stats.max_hp, 0, 10000)
	return total


static func _alive_count(state: BattleState, side: BattleSide) -> int:
	var total := 0
	for creature_id in side.party_ids:
		var creature := state.creature(creature_id)
		if creature != null and not creature.is_knocked_out():
			total += 1
	return total


static func _persistent_status_count(state: BattleState, side: BattleSide) -> int:
	var total := 0
	for creature_id in side.party_ids:
		var creature := state.creature(creature_id)
		if creature != null and creature.status_state.persistent_id != &"":
			total += 1
	return total


static func _side(state: BattleState, side_id: StringName) -> BattleSide:
	for side in state.sides:
		if side.side_id == side_id:
			return side
	return null


static func _other_side(state: BattleState, side_id: StringName) -> BattleSide:
	for side in state.sides:
		if side.side_id != side_id:
			return side
	return null
