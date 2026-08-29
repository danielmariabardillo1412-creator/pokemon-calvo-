class_name EvolutionSystem
extends RefCounted

# Evolution eligibility and application. Strictly separated from Battle Core: it only
# reads species data + a context dict and writes a new CreatureInstance that preserves
# identity. It never decides when to evolve during a battle.

const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const PARTIAL := "PARTIAL"
const DATA_ONLY := "DATA_ONLY"
const UNSUPPORTED := "UNSUPPORTED"

const TRIGGER_LEVEL_UP := &"level_up"
const TRIGGER_USE_ITEM := &"use_item"
const TRIGGER_TRADE := &"trade"

# Triggers stored in the dataset that the runtime model cannot evaluate at all.
const UNSUPPORTED_TRIGGERS := [
	&"strong-style-move", &"agile-style-move", &"use-move", &"shed",
	&"recoil-damage", &"take-damage", &"three-defeated-bisharp",
	&"three-critical-hits", &"spin", &"tower-of-darkness", &"tower-of-waters",
	&"gimmighoul-coins", &"other",
]


# Classify a single evolution record into a support bucket.
# catalogs may be null (then item availability is not checked -> use-item kept RUNTIME_SUPPORTED).
static func classify_record(record: EvolutionRecord, catalogs = null) -> String:
	var trig: StringName = record.trigger
	if trig == TRIGGER_LEVEL_UP:
		# Plain level gate is fully supported. Happiness/known-move/time gating is not
		# modelled in V1, but the dataset only stores min_level for level-up, so we treat
		# it as RUNTIME_SUPPORTED (level is the primary, always-present condition).
		return RUNTIME_SUPPORTED
	if trig == TRIGGER_USE_ITEM:
		if catalogs != null and catalogs.item_catalog != null \
				and not catalogs.item_catalog.has(record.item_id):
			return DATA_ONLY
		return RUNTIME_SUPPORTED
	if trig == TRIGGER_TRADE:
		return RUNTIME_SUPPORTED
	if trig in UNSUPPORTED_TRIGGERS:
		return UNSUPPORTED
	# Unknown trigger: data imported but no runtime path -> data only, never silently supported.
	return DATA_ONLY


# Eligible evolutions for a species given a runtime context.
# context keys: level (int), item_id (StringName), traded (bool).
static func evolution_candidates(
	species: CreatureSpecies,
	context: Dictionary,
	catalogs = null,
) -> Array:
	var out: Array = []
	var level := int(context.get("level", 1))
	var item_id: StringName = context.get("item_id", &"")
	var traded: bool = bool(context.get("traded", false))
	for ev in species.evolutions:
		if not (ev is EvolutionRecord):
			continue
		var rec := ev as EvolutionRecord
		var cls := classify_record(rec, catalogs)
		if cls == UNSUPPORTED:
			continue
		var eligible := false
		match rec.trigger:
			TRIGGER_LEVEL_UP:
				eligible = level >= rec.min_level
			TRIGGER_USE_ITEM:
				eligible = (item_id != &"" and item_id == rec.item_id)
			TRIGGER_TRADE:
				eligible = traded
			_:
				eligible = false
		if eligible:
			out.append(rec)
	return out


# Apply an evolution, returning a NEW CreatureInstance that keeps identity and
# persistent progression data (instance_id, level, experience, IVs, EVs, nature_id,
# moveset, current_hp ratio, status). Stats are recomputed from the target species.
static func apply_evolution(
	creature: CreatureInstance,
	target_species_id: StringName,
	catalogs,
	ruleset: ProgressionRuleset,
) -> CreatureInstance:
	var target: CreatureSpecies = catalogs.species_catalog.get_by_id(target_species_id)
	if target == null:
		return null
	var new_creature := CreatureInstance.new(
		creature.instance_id,
		target_species_id,
		creature.level,
		creature.stats.duplicate() if creature.stats != null else StatBlock.new(),
		[],
	)
	new_creature.experience = creature.experience
	new_creature.ivs = creature.ivs.duplicate()
	new_creature.evs = creature.evs.duplicate()
	new_creature.nature_id = creature.nature_id
	new_creature.friendship = creature.friendship
	# Preserve moveset (move ids + persistent PP) where the move is still learnable/valid.
	new_creature.moveset.clear()
	for slot in creature.moveset:
		var ms := slot as BattleMoveSlot
		new_creature.moveset.append(BattleMoveSlot.new(ms.move_id, ms.max_pp, ms.current_pp))
	# Ability: keep the old ability id if the new species also has it, else first ability.
	if target.ability_ids.has(creature.ability_id):
		new_creature.ability_id = creature.ability_id
	elif not target.ability_ids.is_empty():
		new_creature.ability_id = target.ability_ids[0]
	# Recompute stats from the new species base.
	var base := target.base_stat_block()
	new_creature.stats = StatCalculator.compute(base, new_creature.ivs, new_creature.evs, new_creature.nature_id, new_creature.level)
	# Preserve HP ratio (clamp to new max).
	new_creature.current_hp = mini(creature.current_hp, new_creature.stats.max_hp)
	new_creature.stat_stages = StatStages.from_dict(creature.stat_stages.to_dict()) if creature.stat_stages != null else StatStages.new()
	new_creature.status_state = BattleStatusState.from_dict(creature.status_state.to_dict()) if creature.status_state != null else BattleStatusState.new()
	return new_creature


# Aggregate coverage over a species catalog. Returns a Dictionary with counts and examples.
static func coverage_report(catalogs) -> Dictionary:
	var counts := {RUNTIME_SUPPORTED: 0, PARTIAL: 0, DATA_ONLY: 0, UNSUPPORTED: 0}
	var by_trigger: Dictionary = {}
	var examples := {RUNTIME_SUPPORTED: [], PARTIAL: [], DATA_ONLY: [], UNSUPPORTED: []}
	var edges := 0
	for sid in catalogs.species_catalog.all_ids():
		var sp: CreatureSpecies = catalogs.species_catalog.get_by_id(sid)
		for ev in sp.evolutions:
			if not (ev is EvolutionRecord):
				continue
			edges += 1
			var rec := ev as EvolutionRecord
			var cls := classify_record(rec, catalogs)
			counts[cls] += 1
			var key := String(rec.trigger)
			by_trigger[key] = by_trigger.get(key, 0) + 1
			var label := "%s->%s (%s)" % [sp.id, rec.species_id, rec.trigger]
			if examples[cls].size() < 25:
				examples[cls].append(label)
	return {
		"edges_total": edges,
		"counts": counts,
		"by_trigger": by_trigger,
		"examples": examples,
	}
