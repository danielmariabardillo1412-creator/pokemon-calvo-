class_name TrainerBeliefState
extends RefCounted

const SCHEMA_VERSION := 1
const DOMAIN_MOVE := &"move"
const DOMAIN_ABILITY := &"ability"
const DOMAIN_ITEM := &"item"
const EVIDENCE_INFERRED := &"inferred"
const EVIDENCE_REVEALED := &"revealed"

var battle_id: StringName = &""
var observer_side_id: StringName = &""
var hypotheses: Dictionary = {}


func begin(memory: TrainerBattleMemory) -> bool:
	clear()
	if memory == null or memory.battle_id == &"" or memory.observer_side_id == &"":
		return false
	battle_id = memory.battle_id
	observer_side_id = memory.observer_side_id
	sync_revealed(memory)
	return true


func clear() -> void:
	battle_id = &""
	observer_side_id = &""
	hypotheses.clear()


# Stores a belief without claiming certainty. Confidence is expressed in basis points
# so the runtime remains deterministic and avoids float serialization drift.
func set_candidate(
	creature_id: StringName,
	domain: StringName,
	candidate_id: StringName,
	confidence_basis_points: int,
	evidence: StringName = EVIDENCE_INFERRED,
) -> void:
	if creature_id == &"" or domain == &"" or candidate_id == &"":
		return
	var creature_key := String(creature_id)
	var domain_key := String(domain)
	var candidate_key := String(candidate_id)
	var creature_beliefs: Dictionary = hypotheses.get(creature_key, {})
	var domain_beliefs: Dictionary = creature_beliefs.get(domain_key, {})
	domain_beliefs[candidate_key] = {
		"confidence_basis_points": clampi(confidence_basis_points, 0, 10000),
		"evidence": String(evidence),
	}
	creature_beliefs[domain_key] = domain_beliefs
	hypotheses[creature_key] = creature_beliefs


func reveal_single(
	creature_id: StringName,
	domain: StringName,
	candidate_id: StringName,
) -> void:
	if creature_id == &"" or domain == &"" or candidate_id == &"":
		return
	var creature_key := String(creature_id)
	var creature_beliefs: Dictionary = hypotheses.get(creature_key, {})
	creature_beliefs[String(domain)] = {}
	hypotheses[creature_key] = creature_beliefs
	set_candidate(creature_id, domain, candidate_id, 10000, EVIDENCE_REVEALED)


func reveal_move(creature_id: StringName, move_id: StringName) -> void:
	set_candidate(creature_id, DOMAIN_MOVE, move_id, 10000, EVIDENCE_REVEALED)


func sync_revealed(memory: TrainerBattleMemory) -> bool:
	if memory == null:
		return false
	if battle_id != &"" and memory.battle_id != battle_id:
		return false
	if battle_id == &"":
		battle_id = memory.battle_id
		observer_side_id = memory.observer_side_id
	for creature_id in memory.seen_opponent_ids:
		for move_id in memory.revealed_move_ids(creature_id):
			reveal_move(creature_id, move_id)
		var ability_id := memory.revealed_ability_id(creature_id)
		if ability_id != &"":
			reveal_single(creature_id, DOMAIN_ABILITY, ability_id)
		var item_id := memory.revealed_item_id(creature_id)
		if item_id != &"":
			reveal_single(creature_id, DOMAIN_ITEM, item_id)
	return true


func candidates(creature_id: StringName, domain: StringName) -> Dictionary:
	var creature_beliefs: Dictionary = hypotheses.get(String(creature_id), {})
	return (creature_beliefs.get(String(domain), {}) as Dictionary).duplicate(true)


func confidence_basis_points(
	creature_id: StringName,
	domain: StringName,
	candidate_id: StringName,
) -> int:
	var record: Dictionary = candidates(creature_id, domain).get(String(candidate_id), {})
	return int(record.get("confidence_basis_points", 0))


func evidence_for(
	creature_id: StringName,
	domain: StringName,
	candidate_id: StringName,
) -> StringName:
	var record: Dictionary = candidates(creature_id, domain).get(String(candidate_id), {})
	return StringName(record.get("evidence", ""))


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"battle_id": String(battle_id),
		"observer_side_id": String(observer_side_id),
		"hypotheses": hypotheses.duplicate(true),
	}


static func from_dict(data: Dictionary) -> TrainerBeliefState:
	assert(int(data.get("schema_version", -1)) == SCHEMA_VERSION, "Unsupported trainer belief schema")
	var belief := TrainerBeliefState.new()
	belief.battle_id = StringName(data.get("battle_id", ""))
	belief.observer_side_id = StringName(data.get("observer_side_id", ""))
	var serialized_hypotheses: Dictionary = data.get("hypotheses", {})
	for creature_key in serialized_hypotheses.keys():
		var creature_domains: Dictionary = serialized_hypotheses[creature_key]
		for domain_key in creature_domains.keys():
			var domain_candidates: Dictionary = creature_domains[domain_key]
			for candidate_key in domain_candidates.keys():
				var record: Dictionary = domain_candidates[candidate_key]
				belief.set_candidate(
					StringName(creature_key),
					StringName(domain_key),
					StringName(candidate_key),
					int(record.get("confidence_basis_points", 0)),
					StringName(record.get("evidence", EVIDENCE_INFERRED)),
				)
	return belief
