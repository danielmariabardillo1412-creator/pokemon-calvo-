class_name ProgressionSystem
extends RefCounted

# Orchestrates per-creature progression: experience, level-up, derived stats, learnsets,
# and evolution availability. It consumes BattleOutcome (never battle internals) and
# emits semantic ProgressionEvent values. No autoload, no UI, deterministic.

const LEARN_MOVE := "LEARN_MOVE"
const REPLACE_MOVE := "REPLACE_MOVE"
const DECLINE_MOVE := "DECLINE_MOVE"


# Award experience to a creature. Returns the list of ProgressionEvents produced.
# `species` must be the creature's current (pre-evolution) species from the catalog.
static func gain_experience(
	creature: CreatureInstance,
	amount: int,
	species: CreatureSpecies,
	catalogs,
	ruleset: ProgressionRuleset,
) -> Array:
	var events: Array = []
	var real_amount := maxi(0, int(amount))
	if real_amount <= 0:
		return events

	var old_level := creature.level
	var max_exp := ruleset.experience_for_level(species.growth_rate, ruleset.MAX_LEVEL)
	creature.experience = mini(creature.experience + real_amount, max_exp)
	events.append(ProgressionEvent.new(
		ProgressionEvent.EXPERIENCE_GAINED, creature.instance_id,
		{"amount": real_amount, "total": creature.experience},
	))

	var new_level := ruleset.level_for_experience(species.growth_rate, creature.experience)
	new_level = mini(new_level, ruleset.MAX_LEVEL)

	if new_level <= old_level:
		return events

	for lvl in range(old_level + 1, new_level + 1):
		creature.level = lvl
		events.append(ProgressionEvent.new(ProgressionEvent.LEVEL_UP, creature.instance_id, {"level": lvl}))
		var previous := creature.stats.to_dict()
		creature.recalculate_stats(species, ruleset)
		events.append(ProgressionEvent.new(
			ProgressionEvent.STAT_CHANGED, creature.instance_id,
			{"stats": creature.stats.to_dict(), "previous": previous},
		))
		var learned := LearnsetSystem.level_up_moves_between(species, lvl - 1, lvl)
		for le in learned:
			var mid: StringName = (le as LearnSetEntry).move_id
			if creature.has_move(mid):
				continue
			if creature.moveset.size() < ruleset.MOVE_SLOTS_MAX:
				creature.add_move(mid, catalogs)
				events.append(ProgressionEvent.new(ProgressionEvent.MOVE_LEARNED, creature.instance_id, {"move_id": mid}))
			else:
				events.append(ProgressionEvent.new(
					ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED, creature.instance_id,
					{"new_move_id": mid, "current_moves": creature.move_ids.duplicate()},
				))

	var candidates := EvolutionSystem.evolution_candidates(species, {"level": creature.level}, catalogs)
	for rec in candidates:
		events.append(ProgressionEvent.new(
			ProgressionEvent.EVOLUTION_AVAILABLE, creature.instance_id,
			{"species_id": rec.species_id, "trigger": String(rec.trigger), "min_level": rec.min_level},
		))
	return events


# Resolve a MOVE_LEARN_CHOICE_REQUIRED event. Returns true if a valid intent was applied.
static func apply_move_choice(
	creature: CreatureInstance,
	choice: ProgressionEvent,
	intent: String,
	catalogs,
	old_move_id: StringName = &"",
) -> bool:
	if choice == null or choice.kind != ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED:
		return false
	var new_move: StringName = StringName(choice.data.get("new_move_id", ""))
	match intent:
		LEARN_MOVE:
			if creature.moveset.size() < ProgressionRuleset.MOVE_SLOTS_MAX:
				return creature.add_move(new_move, catalogs)
			return false
		REPLACE_MOVE:
			var target: StringName = old_move_id
			if target == &"" and not creature.move_ids.is_empty():
				target = creature.move_ids[0]
			return creature.replace_move(target, new_move, catalogs)
		DECLINE_MOVE:
			return true
		_:
			return false


# Apply a pending evolution from an EVOLUTION_AVAILABLE event. Returns the evolved
# CreatureInstance (a NEW object preserving identity) or null if not applicable.
static func apply_evolution(
	creature: CreatureInstance,
	available: ProgressionEvent,
	catalogs,
	ruleset: ProgressionRuleset,
) -> CreatureInstance:
	if available == null or available.kind != ProgressionEvent.EVOLUTION_AVAILABLE:
		return null
	var target: StringName = StringName(available.data.get("species_id", ""))
	var evolved := EvolutionSystem.apply_evolution(creature, target, catalogs, ruleset)
	if evolved != null:
		evolved.friendship = creature.friendship
	return evolved


# Consume a BattleOutcome for the winning side: distribute defeated-foe experience across
# surviving participants and run level-up/learn/evolve logic for each.
static func reconcile_battle_result(
	participants: Array,
	outcome: BattleOutcome,
	catalogs,
	ruleset: ProgressionRuleset,
) -> Array:
	var events: Array = []
	var survivors: Array = []
	for p in participants:
		var c := p as CreatureInstance
		if c != null and not c.is_knocked_out():
			survivors.append(c)
	if survivors.is_empty():
		return events
	var defeats: Array = []
	for d in outcome.defeated:
		defeats.append({"base_experience": int(d.get("base_experience", 0)), "level": int(d.get("level", 1))})
	var share := ruleset.experience_for_defeats(defeats, survivors.size())
	if share <= 0:
		return events
	for sp in survivors:
		var species: CreatureSpecies = catalogs.species_catalog.get_by_id(sp.species_id)
		if species == null:
			continue
		events.append_array(gain_experience(sp, share, species, catalogs, ruleset))
	return events
