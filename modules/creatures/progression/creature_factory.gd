class_name CreatureFactory
extends RefCounted

# Builds CreatureInstance values from species data + catalogs + a ruleset + a seeded RNG.
# Deterministic: same (species, level, overrides, seed) -> same creature. No autoload.

static var _counter := 0


static func _next_id() -> StringName:
	_counter += 1
	return StringName("creature_%d" % _counter)


static func _random_ivs(rng: RandomNumberGenerator, ruleset: ProgressionRuleset) -> Dictionary:
	var out: Dictionary = {}
	for k in ProgressionRuleset.STAT_KEYS:
		out[k] = rng.randi_range(ProgressionRuleset.IV_MIN, ProgressionRuleset.IV_MAX)
	return out


static func _random_nature(rng: RandomNumberGenerator) -> StringName:
	var keys := ProgressionRuleset.NATURE_MODIFIERS.keys()
	return keys[rng.randi_range(0, keys.size() - 1)]


# Create a creature. `overrides` may contain: instance_id, ivs, evs, nature_id,
# ability_id, experience, moves (Array[StringName]), current_hp.
static func create(
	species: CreatureSpecies,
	level: int,
	catalogs,
	ruleset: ProgressionRuleset,
	rng: RandomNumberGenerator,
	overrides: Dictionary = {},
) -> CreatureInstance:
	var lvl := ruleset.clamp_level(level)
	var instance_id: StringName = overrides.get("instance_id", _next_id())
	var ivs: Dictionary = overrides.get("ivs", _random_ivs(rng, ruleset))
	var evs: Dictionary = ruleset.clamp_ev_total(overrides.get("evs", {}))
	var nature_id: StringName = overrides.get("nature_id", _random_nature(rng))
	if not ProgressionRuleset.is_valid_nature(nature_id):
		nature_id = ProgressionRuleset.NEUTRAL_NATURE

	var creature := CreatureInstance.new(
		instance_id, species.id, lvl, StatBlock.new(), []
	)
	creature.ivs = ivs
	creature.evs = evs
	creature.nature_id = nature_id
	creature.experience = maxi(0, int(overrides.get("experience", ruleset.experience_for_level(species.growth_rate, lvl))))

	var ability: StringName = overrides.get("ability_id", &"")
	if ability == &"" and not species.ability_ids.is_empty():
		ability = species.ability_ids[0]
	creature.ability_id = ability

	creature.recalculate_stats(species, ruleset)

	var moves := []
	if overrides.has("moves"):
		for m in overrides["moves"]:
			moves.append(StringName(m))
	if moves.is_empty():
		moves = LearnsetSystem.initial_moves(species, lvl)
	for move_id in moves:
		if catalogs != null and catalogs.move_catalog.has(move_id):
			var slot := BattleMoveSlot.new(move_id)
			var definition = catalogs.move(move_id)
			slot.initialize(definition)
			creature.moveset.append(slot)
			creature.move_ids.append(move_id)

	var hp_override = overrides.get("current_hp", -1)
	creature.current_hp = creature.stats.max_hp if hp_override < 0 else clampi(int(hp_override), 0, creature.stats.max_hp)
	return creature
