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

# Canonical V3 trigger IDs use underscores. These mechanics have no runtime path in
# the current progression model and must never fall through as apparently unknown
# data merely because an old constant used the source API's hyphenated spelling.
const UNSUPPORTED_TRIGGERS := [
	&"strong_style_move", &"agile_style_move", &"use_move", &"shed",
	&"recoil_damage", &"take_damage", &"three_defeated_bisharp",
	&"three_critical_hits", &"spin", &"tower_of_darkness", &"tower_of_waters",
	&"gimmighoul_coins", &"other",
]


# Classify a single evolution record into a support bucket.
# Supported conditions are a matching base_form selector and the level-up
# Attack/Defense comparison. Every other condition remains DATA_ONLY.
static func classify_record(
	record: EvolutionRecord,
	catalogs = null,
	source_species_id: StringName = &"",
) -> String:
	var trig: StringName = record.trigger
	if trig in UNSUPPORTED_TRIGGERS:
		return UNSUPPORTED

	if trig == TRIGGER_LEVEL_UP or trig == TRIGGER_USE_ITEM or trig == TRIGGER_TRADE:
		if not _conditions_are_runtime_compatible(record, source_species_id):
			return DATA_ONLY
		if trig == TRIGGER_USE_ITEM:
			if record.item_id == &"":
				return DATA_ONLY
			if catalogs != null and catalogs.item_catalog != null \
					and not catalogs.item_catalog.has(record.item_id):
				return DATA_ONLY
		return RUNTIME_SUPPORTED

	# Unknown trigger: data imported but no runtime path -> data only, never silently supported.
	return DATA_ONLY


# V3 preserves many real evolution requirements in `conditions`: friendship, time,
# gender, known moves, held trade items, region/form routing, weather, party state,
# location and more. None may be ignored and simplified to the primary trigger.
static func _conditions_are_runtime_compatible(
	record: EvolutionRecord,
	source_species_id: StringName,
) -> bool:
	if record.conditions.is_empty():
		return true
	if source_species_id == &"":
		return false
	for key: String in record.conditions:
		match key:
			"base_form":
				if StringName(str(record.conditions[key])) != source_species_id: return false
			"relative_physical_stats":
				var value: Variant = record.conditions[key]
				if record.trigger != TRIGGER_LEVEL_UP or not _integer_number(value): return false
				if int(value) not in [-1, 0, 1]: return false
			_:
				return false
	return true


static func _integer_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) == floor(float(value))


# Persistent stats after level-up, without temporary battle stages/modifiers.
static func level_up_context(creature: CreatureInstance) -> Dictionary:
	var context := {"level": creature.level}
	if creature.stats != null:
		context["attack"] = creature.stats.attack
		context["defense"] = creature.stats.defense
	return context


static func _stat_relation_matches(record: EvolutionRecord, context: Dictionary) -> bool:
	if not record.conditions.has("relative_physical_stats"): return true
	var attack: Variant = context.get("attack")
	var defense: Variant = context.get("defense")
	if not _integer_number(attack) or not _integer_number(defense): return false
	if int(attack) <= 0 or int(defense) <= 0: return false
	var relation := 1 if int(attack) > int(defense) else -1 if int(attack) < int(defense) else 0
	return relation == int(record.conditions["relative_physical_stats"])


# Eligible evolutions for a species given a runtime context.
# context keys: level (int), item_id (StringName), traded (bool), attack/defense.
# DATA_ONLY records are preserved but deliberately not executable: this prevents a
# conditioned evolution from silently degrading into a weaker level/item/trade rule.
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
		var cls := classify_record(rec, catalogs, species.id)
		if cls != RUNTIME_SUPPORTED:
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
		if eligible and _stat_relation_matches(rec, context):
			out.append(rec)
	return out


# Apply an evolution, returning a NEW CreatureInstance that keeps identity and persistent data.
# Callers that own the creature in Party/Storage must replace the old object behind the SAME stable
# instance_id; the aggregate helper PlayerCollection.replace_owned_same_identity does that safely.
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
	new_creature.is_shiny = creature.is_shiny
	new_creature.friendship = creature.friendship
	new_creature.status_ids = creature.status_ids.duplicate()
	new_creature.held_item_id = creature.held_item_id
	new_creature.held_item_consumed = creature.held_item_consumed

	# Preserve moveset AND the parallel move_ids index. Keeping only BattleMoveSlot values would make
	# later serialization/queries disagree about which moves the evolved creature owns.
	new_creature.moveset.clear()
	new_creature.move_ids.clear()
	for slot in creature.moveset:
		var ms := slot as BattleMoveSlot
		new_creature.moveset.append(BattleMoveSlot.new(ms.move_id, ms.max_pp, ms.current_pp))
		new_creature.move_ids.append(ms.move_id)

	# Ability: keep the old ability id if the new species also has it, else first ability.
	if target.ability_ids.has(creature.ability_id):
		new_creature.ability_id = creature.ability_id
	elif not target.ability_ids.is_empty():
		new_creature.ability_id = target.ability_ids[0]
	# Recompute stats from the new species base.
	var base := target.base_stat_block()
	new_creature.stats = StatCalculator.compute(base, new_creature.ivs, new_creature.evs, new_creature.nature_id, new_creature.level)
	# Preserve current HP conservatively, clamped to the new maximum.
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
			var cls := classify_record(rec, catalogs, sp.id)
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
