extends RefCounted

# O120 held escape rule. Pure decision only: the activity flag comes from the
# native checkpoint's real projection of the simulator's held-item state
# (ignoringItem covers Magic Room, Embargo, Klutz, Knock Off/Trick/Fling and
# consumption). Never derive activity from the item name alone.
#
# Reference: Essentials 8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b,
# 011_Battle/001_Battle/007_Battle_ActionRunning.rb#pbRun: an active held item
# with "certain escape" guarantees the escape before trapping/speed checks and
# is not consumed. Trainer battles are rejected before this rule.

const SMOKE_BALL := &"smoke_ball"


static func supports(item_id: StringName) -> bool:
	return item_id == SMOKE_BALL


static func guaranteed(held_item_id: StringName, held_item_active: bool) -> bool:
	return held_item_active and supports(held_item_id)
