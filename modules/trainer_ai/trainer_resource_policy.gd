class_name TrainerResourcePolicy
extends RefCounted

# Balance ceiling for trainer-owned consumables. Exact item IDs/counts are authored
# in the loadout; this policy only prevents a low-tier NPC from carrying boss-scale stock.
# `max_quality_tier` is reserved for FASE 30 runtime item classification.

const NONE := &"none"
const EARLY_ROUTE := &"early_route"
const STANDARD := &"standard"
const GYM_LEADER := &"gym_leader"
const ELITE := &"elite"
const CHAMPION := &"champion"
const SPECIAL := &"special"

var policy_id: StringName = NONE
var max_distinct_items: int = 0
var max_total_uses: int = 0
var max_per_item: int = 0
var max_quality_tier: int = 0


static func none() -> TrainerResourcePolicy:
	return TrainerResourcePolicy.new()


static func early_route() -> TrainerResourcePolicy:
	return _policy(EARLY_ROUTE, 1, 1, 1, 1)


static func standard() -> TrainerResourcePolicy:
	return _policy(STANDARD, 2, 3, 2, 2)


static func gym_leader() -> TrainerResourcePolicy:
	return _policy(GYM_LEADER, 3, 4, 2, 3)


static func elite() -> TrainerResourcePolicy:
	return _policy(ELITE, 4, 6, 3, 4)


static func champion() -> TrainerResourcePolicy:
	return _policy(CHAMPION, 5, 8, 4, 5)


static func special(
	p_max_distinct_items: int,
	p_max_total_uses: int,
	p_max_per_item: int,
	p_max_quality_tier: int = 5,
) -> TrainerResourcePolicy:
	return _policy(
		SPECIAL,
		p_max_distinct_items,
		p_max_total_uses,
		p_max_per_item,
		p_max_quality_tier,
	)


func allows(resources: TrainerBattleResources) -> Dictionary:
	if resources == null:
		return {"ok": false, "reason": "missing_resources"}
	var validation := resources.validate()
	if not bool(validation.get("ok", false)):
		return validation
	if resources.distinct_item_count() > max_distinct_items:
		return {"ok": false, "reason": "too_many_distinct_items"}
	if resources.total_uses() > max_total_uses:
		return {"ok": false, "reason": "too_many_total_uses"}
	for item_id in resources.all_item_ids():
		if resources.quantity(item_id) > max_per_item:
			return {"ok": false, "reason": "too_many_uses_for_item"}
	return {"ok": true, "reason": ""}


func to_dict() -> Dictionary:
	return {
		"policy_id": String(policy_id),
		"max_distinct_items": max_distinct_items,
		"max_total_uses": max_total_uses,
		"max_per_item": max_per_item,
		"max_quality_tier": max_quality_tier,
	}


func duplicate_policy() -> TrainerResourcePolicy:
	return from_dict(to_dict())


static func from_dict(data: Dictionary) -> TrainerResourcePolicy:
	return _policy(
		StringName(data.get("policy_id", NONE)),
		maxi(0, int(data.get("max_distinct_items", 0))),
		maxi(0, int(data.get("max_total_uses", 0))),
		maxi(0, int(data.get("max_per_item", 0))),
		maxi(0, int(data.get("max_quality_tier", 0))),
	)


static func _policy(
	p_id: StringName,
	p_distinct: int,
	p_total: int,
	p_per_item: int,
	p_quality: int,
) -> TrainerResourcePolicy:
	var out := TrainerResourcePolicy.new()
	out.policy_id = p_id
	out.max_distinct_items = maxi(0, p_distinct)
	out.max_total_uses = maxi(0, p_total)
	out.max_per_item = maxi(0, p_per_item)
	out.max_quality_tier = maxi(0, p_quality)
	return out
