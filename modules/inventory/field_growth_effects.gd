extends RefCounted

# Pure replay of one item on a detached candidate. Existing progression owns XP,
# stats, learnsets and evolution rules. No inventory, UI, IO, clock or RNG access.
const Training = preload("res://modules/inventory/field_training_effects.gd")
const Friendship = preload("res://modules/inventory/field_friendship_effects.gd")
const EXP := {"exp_candy_xs": 100, "exp_candy_s": 800, "exp_candy_m": 3000,
	"exp_candy_l": 10000, "exp_candy_xl": 30000}

static func supports(item_id: StringName) -> bool:
	return item_id == &"rare_candy" or EXP.has(String(item_id))

static func deny(reason: String) -> Dictionary:
	return {"accepted": false, "status": "REJECTED", "reason": reason}

static func validation_error(c: CreatureInstance, catalogs: DefinitionCatalog) -> String:
	if c == null or c.is_knocked_out(): return "creature_knocked_out"
	if not c.battle_transform_original.is_empty(): return "temporary_battle_state"
	var error := Training.validation_error(c, -1, catalogs)
	if error != "": return error
	var species := catalogs.species(c.species_id)
	if not ProgressionRuleset.GROWTH_CURVES.has(species.growth_rate) and not ProgressionRuleset.GROWTH_CURVE_ALIASES.has(species.growth_rate): return "invalid_growth_state"
	if c.level < 1 or c.level > 100 or c.experience < 0: return "invalid_growth_state"
	if c.experience > ProgressionRuleset.experience_for_level(species.growth_rate, 100): return "invalid_growth_state"
	if ProgressionRuleset.level_for_experience(species.growth_rate, c.experience) != c.level: return "inconsistent_level_experience"
	if not ProgressionRuleset.is_valid_nature(c.nature_id): return "invalid_growth_state"
	for key: Variant in c.ivs:
		var value: Variant = c.ivs[key]
		if not ProgressionRuleset.STAT_KEYS.has(key): return "invalid_growth_state"
		if not (value is int or value is float) or not is_finite(value) or value < 0 or value > 31 or value != int(value): return "invalid_growth_state"
	if c.stats == null or c.current_hp > c.stats.max_hp: return "invalid_growth_state"
	var expected := StatCalculator.compute(species.base_stat_block(), c.ivs, c.evs, c.nature_id, c.level)
	if expected.to_dict() != c.stats.to_dict(): return "invalid_growth_state"
	if c.moveset.size() != c.move_ids.size() or c.moveset.size() > 4: return "invalid_pp_state"
	for index in c.moveset.size():
		var slot := c.moveset[index]
		if slot == null or slot.move_id != c.move_ids[index] or catalogs.move(slot.move_id) == null: return "invalid_pp_state"
		if slot.max_pp < 1 or slot.current_pp < 0 or slot.current_pp > slot.max_pp: return "invalid_pp_state"
	return ""

static func _eligible_species(id: StringName, catalogs: DefinitionCatalog, policy: RefCounted) -> bool:
	return catalogs.variant_allowed_species.has(String(id)) if catalogs.variants_enabled else policy.species_allowed(String(id))

static func _filtered_species(species: CreatureSpecies, policy: RefCounted) -> CreatureSpecies:
	var copy := CreatureSpecies.from_dict(species.to_dict())
	copy.learnset = copy.learnset.filter(func(e): return policy.move_learnable(String(e.move_id)))
	return copy

static func _pending(key: String, kind: String, details: Dictionary) -> Dictionary:
	var prompt := details.duplicate(true); prompt["key"] = key; prompt["kind"] = kind
	return {"accepted": false, "status": "NEEDS_CONTEXT", "reason": "growth_choice_required", "prompt": prompt}

static func _learn(c: CreatureInstance, move_id: StringName, key: String, decisions: Dictionary,
	used: Dictionary, catalogs: DefinitionCatalog, policy: RefCounted, summary: Dictionary) -> Dictionary:
	if not policy.move_learnable(String(move_id)) or c.has_move(move_id): return {}
	var event := ProgressionEvent.new(ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED, c.instance_id, {"new_move_id": move_id})
	if c.moveset.size() < 4:
		if not ProgressionSystem.apply_move_choice(c, event, ProgressionSystem.LEARN_MOVE, catalogs): return deny("move_not_changed")
		summary.learned_moves.append(String(move_id)); return {}
	if not decisions.has(key):
		return _pending(key, "move", {"move_id": String(move_id), "species_id": String(c.species_id), "level": c.level,
			"slots": c.moveset.map(func(s): return s.to_dict())})
	var choice: Variant = decisions[key]
	if not choice is int or choice < -1 or choice >= c.moveset.size(): return deny("invalid_growth_decision")
	used[key] = true
	if choice == -1:
		ProgressionSystem.apply_move_choice(c, event, ProgressionSystem.DECLINE_MOVE, catalogs); return {}
	var old_id := c.moveset[choice].move_id
	if not ProgressionSystem.apply_move_choice(c, event, ProgressionSystem.REPLACE_MOVE, catalogs, old_id): return deny("move_not_changed")
	summary.learned_moves.append(String(move_id)); return {}

static func plan(source: CreatureInstance, item_id: StringName, catalogs: DefinitionCatalog,
	policy: RefCounted, decisions: Dictionary = {}) -> Dictionary:
	if not supports(item_id): return deny("field_effect_not_connected")
	if policy == null or not policy.valid: return deny("invalid_content_policy")
	var error := validation_error(source, catalogs)
	if error != "": return deny(error)
	if not _eligible_species(source.species_id, catalogs, policy): return deny("species_not_permitted")
	var c := CreatureInstance.from_dict(source.to_dict())
	var species := _filtered_species(catalogs.species(c.species_id), policy)
	var maximum := ProgressionRuleset.experience_for_level(species.growth_rate, 100)
	var target := mini(maximum, c.experience + int(EXP.get(String(item_id), 0)))
	if item_id == &"rare_candy" and c.level < 100:
		target = ProgressionRuleset.experience_for_level(species.growth_rate, c.level + 1)
	var summary := {"accepted": true, "status": "APPLIED", "action": "growth", "levels_gained": 0,
		"exp_gained": target - c.experience, "learned_moves": [], "deferred_evolutions": 0}
	var used: Dictionary = {}
	# Resolve each level's decisions before the next level is simulated. This
	# preserves move order/relearning after replacement while evolution is checked
	# once at the final level, matching the pinned item utilities.
	while c.experience < target:
		var next := ProgressionRuleset.experience_for_level(species.growth_rate, mini(100, c.level + 1))
		var amount := mini(target - c.experience, next - c.experience)
		if amount <= 0: return deny("invalid_growth_state")
		var old_hp := c.current_hp; var old_max := c.stats.max_hp
		var events := ProgressionSystem.gain_experience(c, amount, species, catalogs, ProgressionRuleset.new())
		c.current_hp = clampi(old_hp + c.stats.max_hp - old_max, 1, c.stats.max_hp)
		for event: ProgressionEvent in events:
			if event.kind == ProgressionEvent.MOVE_LEARNED: summary.learned_moves.append(String(event.data.move_id))
			if event.kind == ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED:
				var move_id := StringName(event.data.new_move_id)
				var result := _learn(c, move_id, "move:%d:%s" % [c.level, move_id], decisions, used, catalogs, policy, summary)
				if not result.is_empty(): return result
	if c.level > source.level or item_id == &"rare_candy" and source.level == 100:
		var options: Array[String] = []
		if c.held_item_id != &"everstone" or c.held_item_consumed:
			for record: EvolutionRecord in species.evolutions:
				if record.trigger == EvolutionSystem.TRIGGER_LEVEL_UP and record.min_level <= c.level and _eligible_species(record.species_id, catalogs, policy) and EvolutionSystem.classify_record(record, catalogs, species.id) != EvolutionSystem.RUNTIME_SUPPORTED:
					summary.deferred_evolutions += 1
			for record: EvolutionRecord in EvolutionSystem.evolution_candidates(species, EvolutionSystem.level_up_context(c), catalogs):
				if record.trigger != EvolutionSystem.TRIGGER_LEVEL_UP: continue
				if not _eligible_species(record.species_id, catalogs, policy): continue
				var evolved := EvolutionSystem.apply_evolution(c, record.species_id, catalogs, ProgressionRuleset.new())
				if evolved == null or evolved.ability_id != &"" and not policy.ability_allowed(String(evolved.ability_id)):
					summary.deferred_evolutions += 1; continue
				if String(record.species_id) not in options: options.append(String(record.species_id))
		if not options.is_empty():
			var key := "evolve:%s:%d" % [c.species_id, c.level]
			if not decisions.has(key): return _pending(key, "evolution", {"targets": options, "species_id": String(c.species_id), "level": c.level})
			var choice: Variant = decisions[key]
			if not choice is String or choice != "" and choice not in options: return deny("invalid_growth_decision")
			used[key] = true
			if choice != "":
				var old_hp := c.current_hp; var old_max := c.stats.max_hp
				c = EvolutionSystem.apply_evolution(c, StringName(choice), catalogs, ProgressionRuleset.new())
				c.current_hp = clampi(old_hp + c.stats.max_hp - old_max, 1, c.stats.max_hp)
				summary["species_id"] = String(c.species_id)
				var evolved_species := catalogs.species(c.species_id)
				var learned: Array[StringName] = LearnsetSystem.moves_learned_at_level(evolved_species, 0)
				learned.append_array(LearnsetSystem.moves_learned_at_level(evolved_species, c.level))
				for move_id: StringName in learned:
					var result := _learn(c, move_id, "evolution_move:%s:%s" % [c.species_id, move_id], decisions, used, catalogs, policy, summary)
					if not result.is_empty(): return result
	if used.size() != decisions.size(): return deny("invalid_growth_decision")
	# At level 100 a declined/blocked evolution has no effect and gives no bonus.
	if summary.exp_gained == 0 and c.species_id == source.species_id:
		if summary.deferred_evolutions > 0:
			return {"accepted": false, "status": "DEPENDENCY_MISSING", "reason": "evolution_requires_additional_mechanic"}
		return deny("item_has_no_effect")
	if summary.exp_gained > 0: Friendship.increase(c, [5, 3, 2])
	summary.levels_gained = c.level - source.level
	summary["candidate"] = c
	return summary
