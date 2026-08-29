class_name LearnsetSystem
extends RefCounted

# Pure queries over a species' learnset (level-up method). Deterministic, no rng.

const LEVEL_UP := "level_up"


static func level_up_entries(species: CreatureSpecies) -> Array:
	var out: Array = []
	for e in species.learnset:
		if e is LearnSetEntry and (e as LearnSetEntry).method == LEVEL_UP:
			out.append(e)
	return out


static func moves_learned_at_level(species: CreatureSpecies, level: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for e in level_up_entries(species):
		if (e as LearnSetEntry).level == level:
			out.append((e as LearnSetEntry).move_id)
	return out


# Moves learned strictly after old_level (inclusive of old_level+1) up to and including new_level.
# Returns LearnSetEntry list sorted by level ascending, de-duplicated by move_id (first occurrence kept).
static func level_up_moves_between(species: CreatureSpecies, old_level: int, new_level: int) -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for e in level_up_entries(species):
		var le := e as LearnSetEntry
		if le.level > old_level and le.level <= new_level:
			if not seen.has(le.move_id):
				seen[le.move_id] = true
				out.append(le)
	out.sort_custom(func(a, b): return (a as LearnSetEntry).level < (b as LearnSetEntry).level)
	return out


# Initial moveset for a freshly created creature: all level-up moves learned at or below
# `level`, keeping the most recently learned up to MOVE_SLOTS_MAX (classic behaviour).
static func initial_moves(species: CreatureSpecies, level: int) -> Array[StringName]:
	var learned: Array = []
	for e in level_up_entries(species):
		if (e as LearnSetEntry).level <= level:
			learned.append(e)
	learned.sort_custom(func(a, b): return (a as LearnSetEntry).level < (b as LearnSetEntry).level)
	var out: Array[StringName] = []
	for e in learned:
		out.append((e as LearnSetEntry).move_id)
	if out.size() > ProgressionRuleset.MOVE_SLOTS_MAX:
		out = out.slice(out.size() - ProgressionRuleset.MOVE_SLOTS_MAX, out.size())
	return out
