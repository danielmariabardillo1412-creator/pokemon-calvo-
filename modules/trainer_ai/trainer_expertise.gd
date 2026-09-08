class_name TrainerExpertise
extends RefCounted

# Expertise changes only bounded internal search breadth. It never changes legal
# roots, required depth, world breadth, hidden-information access, or Battle RNG.
# The three production tiers intentionally share the same battle rules and differ
# only in how many inner candidate actions the search is allowed to examine.
const LIMITED := &"limited"
const STANDARD := &"standard"
const FULL := &"full"
const DEFAULT := FULL

const LIMITED_INNER_ACTION_CAP := 1
const STANDARD_INNER_ACTION_CAP := 2
const FULL_INNER_ACTION_CAP := TrainerItemAwareShadowProbe.INNER_ACTION_CAP


static func is_supported(expertise_id: StringName) -> bool:
	return expertise_id == LIMITED or expertise_id == STANDARD or expertise_id == FULL


static func inner_action_cap(expertise_id: StringName) -> int:
	if expertise_id == LIMITED:
		return LIMITED_INNER_ACTION_CAP
	if expertise_id == STANDARD:
		return STANDARD_INNER_ACTION_CAP
	if expertise_id == FULL:
		return FULL_INNER_ACTION_CAP
	return 0


static func difficulty_label(expertise_id: StringName) -> String:
	if expertise_id == LIMITED:
		return "novato"
	if expertise_id == STANDARD:
		return "normal"
	if expertise_id == FULL:
		return "experto"
	return "desconocido"
