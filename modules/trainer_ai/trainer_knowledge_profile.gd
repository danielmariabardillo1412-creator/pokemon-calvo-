class_name TrainerKnowledgeProfile
extends RefCounted

# Describes preparation/knowledge without granting hidden battle state.
# Every tier may know the public type chart; stronger tiers differ in how much public
# species/belief/team/resource reasoning later systems are allowed to exploit.

const BASIC := &"basic"
const TRAINED := &"trained"
const SPECIALIST := &"specialist"
const ELITE := &"elite"
const CHAMPION := &"champion"

var tier_id: StringName = BASIC
var specialist_type_ids: Array[StringName] = []
var knows_public_type_chart: bool = true
var uses_public_species_knowledge: bool = false
var uses_belief_inference: bool = false
var uses_team_preservation: bool = false
var uses_resource_planning: bool = false


static func basic() -> TrainerKnowledgeProfile:
	return TrainerKnowledgeProfile.new()


static func trained() -> TrainerKnowledgeProfile:
	return _profile(TRAINED, [], true, true, false, false, false)


static func specialist(type_ids: Array[StringName]) -> TrainerKnowledgeProfile:
	return _profile(SPECIALIST, type_ids, true, true, true, true, true)


static func elite(type_ids: Array[StringName] = []) -> TrainerKnowledgeProfile:
	return _profile(ELITE, type_ids, true, true, true, true, true)


static func champion(type_ids: Array[StringName] = []) -> TrainerKnowledgeProfile:
	return _profile(CHAMPION, type_ids, true, true, true, true, true)


func validate(catalog: DefinitionCatalog = null) -> Dictionary:
	var seen: Dictionary = {}
	for type_id in specialist_type_ids:
		if type_id == &"":
			return {"ok": false, "reason": "empty_specialist_type"}
		if seen.has(type_id):
			return {"ok": false, "reason": "duplicate_specialist_type"}
		seen[type_id] = true
		if catalog != null and not catalog.type_catalog.has(type_id):
			return {"ok": false, "reason": "unknown_specialist_type"}
	return {"ok": true, "reason": ""}


func to_dict() -> Dictionary:
	var types: Array[String] = []
	for type_id in specialist_type_ids:
		types.append(String(type_id))
	return {
		"tier_id": String(tier_id),
		"specialist_type_ids": types,
		"knows_public_type_chart": knows_public_type_chart,
		"uses_public_species_knowledge": uses_public_species_knowledge,
		"uses_belief_inference": uses_belief_inference,
		"uses_team_preservation": uses_team_preservation,
		"uses_resource_planning": uses_resource_planning,
	}


func duplicate_profile() -> TrainerKnowledgeProfile:
	return from_dict(to_dict())


static func from_dict(data: Dictionary) -> TrainerKnowledgeProfile:
	var types: Array[StringName] = []
	for value in data.get("specialist_type_ids", []):
		var type_id := StringName(value)
		if type_id != &"" and not types.has(type_id):
			types.append(type_id)
	return _profile(
		StringName(data.get("tier_id", BASIC)),
		types,
		bool(data.get("knows_public_type_chart", true)),
		bool(data.get("uses_public_species_knowledge", false)),
		bool(data.get("uses_belief_inference", false)),
		bool(data.get("uses_team_preservation", false)),
		bool(data.get("uses_resource_planning", false)),
	)


static func _profile(
	p_tier: StringName,
	p_types: Array[StringName],
	p_type_chart: bool,
	p_species: bool,
	p_belief: bool,
	p_team: bool,
	p_resources: bool,
) -> TrainerKnowledgeProfile:
	var out := TrainerKnowledgeProfile.new()
	out.tier_id = p_tier
	for type_id in p_types:
		if type_id != &"" and not out.specialist_type_ids.has(type_id):
			out.specialist_type_ids.append(type_id)
	out.knows_public_type_chart = p_type_chart
	out.uses_public_species_knowledge = p_species
	out.uses_belief_inference = p_belief
	out.uses_team_preservation = p_team
	out.uses_resource_planning = p_resources
	return out
