class_name TrainerBeliefState
extends RefCounted

const SCHEMA_VERSION := 2
const LEGACY_SCHEMA_VERSION := 1

const DOMAIN_MOVE := &"move"
const DOMAIN_ABILITY := &"ability"
const DOMAIN_ITEM := &"item"
const DOMAIN_SPEED := &"speed"

const EVIDENCE_PRIOR := &"prior"
const EVIDENCE_INFERRED := &"inferred"
const EVIDENCE_REVEALED := &"revealed"

var battle_id: StringName = &""
var observer_side_id: StringName = &""
var hypotheses: Dictionary = {}
var ranges: Dictionary = {}


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
	ranges.clear()


# Candidate confidence uses basis points so inference remains deterministic and JSON-stable.
# Provenance records only public/inference model identifiers, never raw hidden battle metadata.
func set_candidate(
	creature_id: StringName,
	domain: StringName,
	candidate_id: StringName,
	confidence_basis_points: int,
	evidence: StringName = EVIDENCE_INFERRED,
	provenance: Array[String] = [],
) -> void:
	if creature_id == &"" or domain == &"" or candidate_id == &"":
		return
	var creature_key := String(creature_id)
	var domain_key := String(domain)
	var candidate_key := String(candidate_id)
	var creature_beliefs: Dictionary = hypotheses.get(creature_key, {})
	var domain_beliefs: Dictionary = creature_beliefs.get(domain_key, {})
	var existing: Dictionary = domain_beliefs.get(candidate_key, {})
	var existing_evidence := StringName(existing.get("evidence", ""))
	if existing_evidence == EVIDENCE_REVEALED and evidence != EVIDENCE_REVEALED:
		return
	var existing_provenance: Array = existing.get("provenance", [])
	domain_beliefs[candidate_key] = {
		"confidence_basis_points": clampi(confidence_basis_points, 0, 10000),
		"evidence": String(evidence),
		"provenance": _merge_provenance(existing_provenance, provenance),
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
	set_candidate(
		creature_id,
		domain,
		candidate_id,
		10000,
		EVIDENCE_REVEALED,
		["public_reveal"],
	)


# Moves are not mutually exclusive: revealing one slot must not erase other move hypotheses.
func reveal_move(creature_id: StringName, move_id: StringName) -> void:
	set_candidate(
		creature_id,
		DOMAIN_MOVE,
		move_id,
		10000,
		EVIDENCE_REVEALED,
		["public_reveal"],
	)


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


func provenance_for(
	creature_id: StringName,
	domain: StringName,
	candidate_id: StringName,
) -> Array[String]:
	var out: Array[String] = []
	var record: Dictionary = candidates(creature_id, domain).get(String(candidate_id), {})
	for value in record.get("provenance", []):
		out.append(String(value))
	return out


func has_revealed_candidate(creature_id: StringName, domain: StringName) -> bool:
	for record in candidates(creature_id, domain).values():
		if StringName((record as Dictionary).get("evidence", "")) == EVIDENCE_REVEALED:
			return true
	return false


# Applies deterministic pseudo-Bayesian evidence to a mutually-exclusive domain.
# posterior(candidate) ∝ prior(candidate) * likelihood(candidate), normalized to 10000 bp.
# This is intentionally not used for the multi-label move domain.
func apply_exclusive_likelihoods(
	creature_id: StringName,
	domain: StringName,
	likelihood_basis_points: Dictionary,
	provenance_id: StringName,
) -> bool:
	var current := candidates(creature_id, domain)
	if current.is_empty() or has_revealed_candidate(creature_id, domain):
		return false
	var keys := current.keys()
	keys.sort()
	var weights: Dictionary = {}
	var total_weight: int = 0
	for candidate_key in keys:
		var record: Dictionary = current[candidate_key]
		var prior := clampi(int(record.get("confidence_basis_points", 0)), 0, 10000)
		var likelihood := clampi(
			int(likelihood_basis_points.get(String(candidate_key), 10000)),
			0,
			10000,
		)
		var weight := prior * likelihood
		weights[candidate_key] = weight
		total_weight += weight
	if total_weight <= 0:
		return false
	var normalized: Dictionary = {}
	var assigned: int = 0
	for candidate_key in keys:
		var value := int(int(weights[candidate_key]) * 10000 / total_weight)
		normalized[candidate_key] = value
		assigned += value
	var remainder := 10000 - assigned
	var index := 0
	while remainder > 0 and not keys.is_empty():
		var key = keys[index % keys.size()]
		normalized[key] = int(normalized[key]) + 1
		index += 1
		remainder -= 1
	var provenance: Array[String] = []
	if provenance_id != &"":
		provenance.append(String(provenance_id))
	for candidate_key in keys:
		set_candidate(
			creature_id,
			domain,
			StringName(candidate_key),
			int(normalized[candidate_key]),
			EVIDENCE_INFERRED,
			provenance,
		)
	return true


# Numeric ranges represent public bounds (currently speed), not exact hidden stats.
func set_range(
	creature_id: StringName,
	domain: StringName,
	min_value: int,
	max_value: int,
	confidence_basis_points: int = 10000,
	evidence: StringName = EVIDENCE_INFERRED,
	provenance: Array[String] = [],
) -> bool:
	if creature_id == &"" or domain == &"" or min_value > max_value:
		return false
	var creature_key := String(creature_id)
	var domain_key := String(domain)
	var creature_ranges: Dictionary = ranges.get(creature_key, {})
	var existing: Dictionary = creature_ranges.get(domain_key, {})
	creature_ranges[domain_key] = {
		"min_value": min_value,
		"max_value": max_value,
		"confidence_basis_points": clampi(confidence_basis_points, 0, 10000),
		"evidence": String(evidence),
		"provenance": _merge_provenance(existing.get("provenance", []), provenance),
	}
	ranges[creature_key] = creature_ranges
	return true


func refine_range(
	creature_id: StringName,
	domain: StringName,
	min_value: int,
	max_value: int,
	confidence_basis_points: int = 10000,
	evidence: StringName = EVIDENCE_INFERRED,
	provenance: Array[String] = [],
) -> bool:
	if min_value > max_value:
		return false
	var existing := range_for(creature_id, domain)
	if existing.is_empty():
		return set_range(
			creature_id, domain, min_value, max_value,
			confidence_basis_points, evidence, provenance
		)
	var refined_min := maxi(int(existing.get("min_value", min_value)), min_value)
	var refined_max := mini(int(existing.get("max_value", max_value)), max_value)
	if refined_min > refined_max:
		# Contradictory evidence must not destroy a previously valid public bound.
		return false
	return set_range(
		creature_id, domain, refined_min, refined_max,
		confidence_basis_points, evidence, provenance
	)


func range_for(creature_id: StringName, domain: StringName) -> Dictionary:
	var creature_ranges: Dictionary = ranges.get(String(creature_id), {})
	return (creature_ranges.get(String(domain), {}) as Dictionary).duplicate(true)


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"battle_id": String(battle_id),
		"observer_side_id": String(observer_side_id),
		"hypotheses": hypotheses.duplicate(true),
		"ranges": ranges.duplicate(true),
	}


static func from_dict(data: Dictionary) -> TrainerBeliefState:
	var schema_version := int(data.get("schema_version", -1))
	assert(
		schema_version == LEGACY_SCHEMA_VERSION or schema_version == SCHEMA_VERSION,
		"Unsupported trainer belief schema",
	)
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
				var provenance: Array[String] = []
				for value in record.get("provenance", []):
					provenance.append(String(value))
				belief.set_candidate(
					StringName(creature_key),
					StringName(domain_key),
					StringName(candidate_key),
					int(record.get("confidence_basis_points", 0)),
					StringName(record.get("evidence", EVIDENCE_INFERRED)),
					provenance,
				)
	if schema_version >= SCHEMA_VERSION:
		var serialized_ranges: Dictionary = data.get("ranges", {})
		for creature_key in serialized_ranges.keys():
			var creature_ranges: Dictionary = serialized_ranges[creature_key]
			for domain_key in creature_ranges.keys():
				var record: Dictionary = creature_ranges[domain_key]
				var provenance: Array[String] = []
				for value in record.get("provenance", []):
					provenance.append(String(value))
				belief.set_range(
					StringName(creature_key),
					StringName(domain_key),
					int(record.get("min_value", 0)),
					int(record.get("max_value", 0)),
					int(record.get("confidence_basis_points", 0)),
					StringName(record.get("evidence", EVIDENCE_INFERRED)),
					provenance,
				)
	return belief


static func _merge_provenance(existing: Array, incoming: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for value in existing:
		var text := String(value)
		if not out.has(text):
			out.append(text)
	for value in incoming:
		var text := String(value)
		if not out.has(text):
			out.append(text)
	return out
