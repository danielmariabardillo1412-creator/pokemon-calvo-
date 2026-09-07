class_name TrainerExpertise
extends RefCounted

# Expertise changes only bounded internal search breadth. It never changes legal
# roots, required depth, world breadth, hidden-information access, or Battle RNG.
# E1-B explicitly certified only caps 1 and 3; V1 therefore exposes only these.
const LIMITED := &"limited"
const FULL := &"full"
const DEFAULT := FULL

const LIMITED_INNER_ACTION_CAP := 1
const FULL_INNER_ACTION_CAP := TrainerItemAwareShadowProbe.INNER_ACTION_CAP


static func is_supported(expertise_id: StringName) -> bool:
	return expertise_id == LIMITED or expertise_id == FULL


static func inner_action_cap(expertise_id: StringName) -> int:
	if expertise_id == LIMITED:
		return LIMITED_INNER_ACTION_CAP
	if expertise_id == FULL:
		return FULL_INNER_ACTION_CAP
	return 0
