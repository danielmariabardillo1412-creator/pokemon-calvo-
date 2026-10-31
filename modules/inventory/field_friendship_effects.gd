extends RefCounted

# Positive base friendship shared by EV berries, vitamins/wings and PP boosts.
# Callers validate the staged creature. Capture-origin bonuses need metadata
# that the owned creature does not yet store; never invent those bonuses here.
static func increase(creature: CreatureInstance, gains: Array) -> int:
	var gain: int = gains[mini(2, creature.friendship / 100)]
	if creature.held_item_id == &"soothe_bell" and not creature.held_item_consumed:
		gain = gain * 3 / 2
	var before := creature.friendship
	creature.friendship = mini(255, before + gain)
	return creature.friendship - before
