class_name TrainerBattleLoadout
extends RefCounted

# Immutable-by-convention authored preparation for a trainer battle. Tactical personality
# remains in TrainerProfile; this object describes rank/resources/legitimate knowledge.

const SCHEMA_VERSION := 1

const ROLE_ROUTE := &"route"
const ROLE_STANDARD := &"standard"
const ROLE_GYM_LEADER := &"gym_leader"
const ROLE_ELITE := &"elite"
const ROLE_CHAMPION := &"champion"
const ROLE_SPECIAL := &"special"

var trainer_id: StringName = &""
var role_id: StringName = ROLE_STANDARD
var knowledge: TrainerKnowledgeProfile = TrainerKnowledgeProfile.trained()
var resource_policy: TrainerResourcePolicy = TrainerResourcePolicy.standard()
var resources: TrainerBattleResources = TrainerBattleResources.new()


static func empty(p_trainer_id: StringName) -> TrainerBattleLoadout:
	var out := TrainerBattleLoadout.new()
	out.trainer_id = p_trainer_id
	out.role_id = ROLE_STANDARD
	out.knowledge = TrainerKnowledgeProfile.trained()
	out.resource_policy = TrainerResourcePolicy.none()
	out.resources = TrainerBattleResources.new()
	return out


static func early_route(p_trainer_id: StringName) -> TrainerBattleLoadout:
	var out := TrainerBattleLoadout.new()
	out.trainer_id = p_trainer_id
	out.role_id = ROLE_ROUTE
	out.knowledge = TrainerKnowledgeProfile.basic()
	out.resource_policy = TrainerResourcePolicy.early_route()
	return out


static func gym_leader(
	p_trainer_id: StringName,
	specialist_type_ids: Array[StringName],
) -> TrainerBattleLoadout:
	var out := TrainerBattleLoadout.new()
	out.trainer_id = p_trainer_id
	out.role_id = ROLE_GYM_LEADER
	out.knowledge = TrainerKnowledgeProfile.specialist(specialist_type_ids)
	out.resource_policy = TrainerResourcePolicy.gym_leader()
	return out


static func elite(
	p_trainer_id: StringName,
	specialist_type_ids: Array[StringName] = [],
) -> TrainerBattleLoadout:
	var out := TrainerBattleLoadout.new()
	out.trainer_id = p_trainer_id
	out.role_id = ROLE_ELITE
	out.knowledge = TrainerKnowledgeProfile.elite(specialist_type_ids)
	out.resource_policy = TrainerResourcePolicy.elite()
	return out


static func champion(p_trainer_id: StringName) -> TrainerBattleLoadout:
	var out := TrainerBattleLoadout.new()
	out.trainer_id = p_trainer_id
	out.role_id = ROLE_CHAMPION
	out.knowledge = TrainerKnowledgeProfile.champion()
	out.resource_policy = TrainerResourcePolicy.champion()
	return out


func validate(catalog: DefinitionCatalog = null) -> Dictionary:
	if trainer_id == &"":
		return {"ok": false, "reason": "trainer_id_required"}
	if knowledge == null:
		return {"ok": false, "reason": "missing_knowledge_profile"}
	if resource_policy == null:
		return {"ok": false, "reason": "missing_resource_policy"}
	if resources == null:
		return {"ok": false, "reason": "missing_resources"}
	var knowledge_validation := knowledge.validate(catalog)
	if not bool(knowledge_validation.get("ok", false)):
		return knowledge_validation
	var resource_validation := resource_policy.allows(resources)
	if not bool(resource_validation.get("ok", false)):
		return resource_validation
	return {"ok": true, "reason": ""}


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"trainer_id": String(trainer_id),
		"role_id": String(role_id),
		"knowledge": knowledge.to_dict() if knowledge != null else {},
		"resource_policy": resource_policy.to_dict() if resource_policy != null else {},
		"resources": resources.to_dict() if resources != null else {},
	}


func duplicate_loadout() -> TrainerBattleLoadout:
	return from_dict(to_dict())


static func from_dict(data: Dictionary) -> TrainerBattleLoadout:
	var out := TrainerBattleLoadout.new()
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return out
	out.trainer_id = StringName(data.get("trainer_id", ""))
	out.role_id = StringName(data.get("role_id", ROLE_STANDARD))
	out.knowledge = TrainerKnowledgeProfile.from_dict(data.get("knowledge", {}))
	out.resource_policy = TrainerResourcePolicy.from_dict(data.get("resource_policy", {}))
	out.resources = TrainerBattleResources.from_dict(data.get("resources", {}))
	return out
