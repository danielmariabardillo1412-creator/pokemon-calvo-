class_name TrainerPlausibleWorldFactory
extends RefCounted

const DEFAULT_MAX_WORLDS := 12
const SYNTHETIC_SEED_BASE := 1709

var _catalog: DefinitionCatalog


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog


func build(
	context: TrainerDecisionContext,
	max_worlds: int = DEFAULT_MAX_WORLDS,
) -> Array[TrainerPlausibleWorld]:
	var out: Array[TrainerPlausibleWorld] = []
	if context == null or context.observation == null or _catalog == null or max_worlds <= 0:
		return out
	var observation := context.observation
	var active_view := _view_by_id(observation.observed_opponents, observation.opponent_active_id)
	if active_view.is_empty():
		return out
	var ability_options := _ability_options(context, active_view)
	var speed_options := _speed_options(context, active_view)
	var seeds := _synthetic_seeds(observation.turn)
	var candidate_groups := _candidate_groups(ability_options, speed_options, seeds)
	var selected := _stratified_candidates(candidate_groups, max_worlds)
	var world_index := 0
	for candidate in selected:
		var ability := candidate.get("ability", {}) as Dictionary
		var world := _build_world(
			context,
			StringName(ability.get("id", "")),
			int(ability.get("confidence_basis_points", 10000)),
			int(candidate.get("speed", 1)),
			int(candidate.get("seed", SYNTHETIC_SEED_BASE)),
			world_index,
		)
		if world != null:
			out.append(world)
			world_index += 1
	_assign_hypothesis_weights(out)
	return out


func _candidate_groups(
	ability_options: Array[Dictionary],
	speed_options: Array[int],
	seeds: Array[int],
) -> Array[Array]:
	var groups: Array[Array] = []
	for ability in ability_options:
		var group: Array = []
		for speed in speed_options:
			for seed in seeds:
				group.append({
					"ability": (ability as Dictionary).duplicate(true),
					"speed": int(speed),
					"seed": int(seed),
				})
		groups.append(group)
	return groups


func _stratified_candidates(groups: Array[Array], max_worlds: int) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	if groups.is_empty() or max_worlds <= 0:
		return selected
	var depth := 0
	while selected.size() < max_worlds:
		var added_at_depth := false
		for group in groups:
			if selected.size() >= max_worlds:
				break
			if depth >= group.size():
				continue
			selected.append((group[depth] as Dictionary).duplicate(true))
			added_at_depth = true
		if not added_at_depth:
			break
		depth += 1
	return selected


func _build_world(
	context: TrainerDecisionContext,
	active_ability_id: StringName,
	ability_confidence_bp: int,
	active_speed: int,
	rng_seed: int,
	world_index: int,
) -> TrainerPlausibleWorld:
	var observation := context.observation
	var own_party := _own_party(observation)
	var opponent_party := _opponent_party(
		context,
		active_ability_id,
		active_speed,
	)
	if own_party.is_empty() or opponent_party.is_empty():
		return null
	var state := BattleState.create_with_parties(
		observation.battle_id,
		own_party,
		opponent_party,
		rng_seed,
	)
	state.sides[0].side_id = observation.observer_side_id
	state.sides[1].side_id = observation.opponent_side_id
	state.switch_active(observation.observer_side_id, observation.own_active_id)
	state.switch_active(observation.opponent_side_id, observation.opponent_active_id)
	state.turn = observation.turn
	state.phase = observation.phase
	state.battle_started = observation.turn > 0

	var world := TrainerPlausibleWorld.new()
	world.world_id = StringName("world_%02d_a_%s_s_%d_r_%d" % [
		world_index,
		String(active_ability_id) if active_ability_id != &"" else "unknown",
		active_speed,
		rng_seed,
	])
	world.state = state
	world.assumptions = [
		"safe_context_only",
		"synthetic_rng_not_live_rng",
		"public_species_proxy_non_speed_stats",
		"opponent_unknown_pp_assumed_full",
	]
	if active_ability_id == &"":
		world.assumptions.append("opponent_ability_unmodeled")
	if String(_view_by_id(observation.observed_opponents, observation.opponent_active_id).get("revealed_item_id", "")).is_empty():
		world.assumptions.append("opponent_unknown_item_unmodeled")
	world.metadata = {
		"active_opponent_ability_id": String(active_ability_id),
		"ability_confidence_basis_points": clampi(ability_confidence_bp, 0, 10000),
		"active_opponent_speed_sample": active_speed,
		"rng_model": "synthetic_seed_grid_v1",
		"rng_seed": rng_seed,
		"sampling_model": "ability_stratified_round_robin_v1",
	}
	return world


func _own_party(observation: TrainerObservation) -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	for view in observation.own_party:
		var creature := CreatureInstance.from_dict((view as Dictionary).duplicate(true))
		if creature != null:
			out.append(creature)
	return out


func _opponent_party(
	context: TrainerDecisionContext,
	active_ability_id: StringName,
	active_speed: int,
) -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	var observation := context.observation
	for raw_view in observation.observed_opponents:
		var view := raw_view as Dictionary
		var creature_id := StringName(view.get("instance_id", ""))
		var is_active := creature_id == observation.opponent_active_id
		var speed := active_speed if is_active else _middle_speed(context, creature_id, view)
		var ability := active_ability_id if is_active else _top_ability(context, creature_id, view)
		var creature := _opponent_proxy(context, view, speed, ability)
		if creature != null:
			out.append(creature)
	return out


func _opponent_proxy(
	context: TrainerDecisionContext,
	view: Dictionary,
	speed_value: int,
	ability_id: StringName,
) -> CreatureInstance:
	var creature_id := StringName(view.get("instance_id", ""))
	var species_id := StringName(view.get("species_id", ""))
	var species := _catalog.species(species_id)
	if creature_id == &"" or species == null:
		return null
	var level := maxi(1, int(view.get("level", 1)))
	var stats := species.stats_for_level(level)
	stats.speed = maxi(1, speed_value)
	var move_ids := _plausible_moves(context, creature_id, view, species, level)
	var creature := CreatureInstance.new(creature_id, species_id, level, stats, move_ids)
	creature.initialize_move_pp(_catalog)
	var hp_ratio := clampi(int(view.get("hp_ratio_basis_points", 10000)), 0, 10000)
	creature.current_hp = 0 if bool(view.get("is_knocked_out", false)) else maxi(
		1,
		stats.max_hp * hp_ratio / 10000,
	)
	creature.stat_stages = StatStages.from_dict(view.get("stat_stages", {}))
	creature.status_state.persistent_id = StringName(view.get("persistent_status_id", ""))
	for volatile_id in view.get("volatile_statuses", []):
		creature.status_state.add_volatile(StringName(volatile_id))
	creature.ability_id = ability_id
	var revealed_item := StringName(view.get("revealed_item_id", ""))
	creature.held_item_id = revealed_item
	creature.held_item_consumed = bool(view.get("revealed_item_consumed", false)) if revealed_item != &"" else false
	return creature


func _plausible_moves(
	context: TrainerDecisionContext,
	creature_id: StringName,
	view: Dictionary,
	species: CreatureSpecies,
	level: int,
) -> Array[StringName]:
	var out: Array[StringName] = []
	for move_id in view.get("revealed_move_ids", []):
		_append_move(out, StringName(move_id))
	var candidates := _domain_candidates(context, creature_id, TrainerBeliefState.DOMAIN_MOVE)
	var keys := candidates.keys()
	keys.sort_custom(func(a, b):
		var a_record := candidates[a] as Dictionary
		var b_record := candidates[b] as Dictionary
		var a_score := int(a_record.get("confidence_basis_points", 0))
		var b_score := int(b_record.get("confidence_basis_points", 0))
		if a_score == b_score:
			return String(a) < String(b)
		return a_score > b_score
	)
	for key in keys:
		_append_move(out, StringName(key))
		if out.size() >= ProgressionRuleset.MOVE_SLOTS_MAX:
			break
	if out.is_empty():
		for move_id in LearnsetSystem.initial_moves(species, level):
			_append_move(out, move_id)
			if out.size() >= ProgressionRuleset.MOVE_SLOTS_MAX:
				break
	return out


func _append_move(out: Array[StringName], move_id: StringName) -> void:
	if move_id != &"" and _catalog.move(move_id) != null and not out.has(move_id):
		out.append(move_id)


func _ability_options(context: TrainerDecisionContext, view: Dictionary) -> Array[Dictionary]:
	var revealed := StringName(view.get("revealed_ability_id", ""))
	if revealed != &"":
		return [{"id": String(revealed), "confidence_basis_points": 10000}]
	var creature_id := StringName(view.get("instance_id", ""))
	var candidates := _domain_candidates(context, creature_id, TrainerBeliefState.DOMAIN_ABILITY)
	var keys := candidates.keys()
	keys.sort_custom(func(a, b):
		var a_score := int((candidates[a] as Dictionary).get("confidence_basis_points", 0))
		var b_score := int((candidates[b] as Dictionary).get("confidence_basis_points", 0))
		if a_score == b_score:
			return String(a) < String(b)
		return a_score > b_score
	)
	var out: Array[Dictionary] = []
	for key in keys:
		out.append({
			"id": String(key),
			"confidence_basis_points": int((candidates[key] as Dictionary).get("confidence_basis_points", 0)),
		})
		if out.size() >= 2:
			break
	if out.is_empty():
		out.append({"id": "", "confidence_basis_points": 10000})
	return out


func _speed_options(context: TrainerDecisionContext, view: Dictionary) -> Array[int]:
	var creature_id := StringName(view.get("instance_id", ""))
	var record := _range_record(context, creature_id, TrainerBeliefState.DOMAIN_SPEED)
	if record.is_empty():
		var species := _catalog.species(StringName(view.get("species_id", "")))
		if species == null:
			return [1]
		return [species.stats_for_level(int(view.get("level", 1))).speed]
	var minimum := maxi(1, int(record.get("min_value", 1)))
	var maximum := maxi(minimum, int(record.get("max_value", minimum)))
	var middle := minimum + (maximum - minimum) / 2
	var out: Array[int] = []
	for value in [minimum, middle, maximum]:
		if not out.has(int(value)):
			out.append(int(value))
	return out


func _middle_speed(
	context: TrainerDecisionContext,
	creature_id: StringName,
	view: Dictionary,
) -> int:
	var options := _speed_options(context, view)
	return options[options.size() / 2] if not options.is_empty() else 1


func _top_ability(
	context: TrainerDecisionContext,
	creature_id: StringName,
	view: Dictionary,
) -> StringName:
	var options := _ability_options(context, view)
	return StringName(options[0].get("id", "")) if not options.is_empty() else &""


func _domain_candidates(
	context: TrainerDecisionContext,
	creature_id: StringName,
	domain: StringName,
) -> Dictionary:
	var hypotheses: Dictionary = context.belief_snapshot.get("hypotheses", {})
	var creature: Dictionary = hypotheses.get(String(creature_id), {})
	return (creature.get(String(domain), {}) as Dictionary).duplicate(true)


func _range_record(
	context: TrainerDecisionContext,
	creature_id: StringName,
	domain: StringName,
) -> Dictionary:
	var ranges: Dictionary = context.belief_snapshot.get("ranges", {})
	var creature: Dictionary = ranges.get(String(creature_id), {})
	return (creature.get(String(domain), {}) as Dictionary).duplicate(true)


func _view_by_id(views: Array[Dictionary], creature_id: StringName) -> Dictionary:
	for view in views:
		if StringName(view.get("instance_id", "")) == creature_id:
			return view
	return {}


func _synthetic_seeds(turn: int) -> Array[int]:
	var base := SYNTHETIC_SEED_BASE + maxi(0, turn) * 97
	return [base + 11, base + 101, base + 307]


func _assign_hypothesis_weights(worlds: Array[TrainerPlausibleWorld]) -> void:
	if worlds.is_empty():
		return
	var counts: Dictionary = {}
	var confidences: Dictionary = {}
	for world in worlds:
		var ability_id := String(world.metadata.get("active_opponent_ability_id", ""))
		counts[ability_id] = int(counts.get(ability_id, 0)) + 1
		confidences[ability_id] = clampi(
			int(world.metadata.get("ability_confidence_basis_points", 0)),
			0,
			10000,
		)
	var confidence_total := 0
	for ability_id in confidences.keys():
		confidence_total += int(confidences[ability_id])
	if confidence_total <= 0:
		_assign_equal_weights(worlds)
		return
	var assigned := 0
	for world in worlds:
		var ability_id := String(world.metadata.get("active_opponent_ability_id", ""))
		var count := maxi(1, int(counts.get(ability_id, 1)))
		var confidence := int(confidences.get(ability_id, 0))
		var weight := confidence * 10000 / (confidence_total * count)
		world.weight_basis_points = weight
		assigned += weight
	var remainder := 10000 - assigned
	var index := 0
	while remainder > 0 and not worlds.is_empty():
		worlds[index % worlds.size()].weight_basis_points += 1
		index += 1
		remainder -= 1


func _assign_equal_weights(worlds: Array[TrainerPlausibleWorld]) -> void:
	if worlds.is_empty():
		return
	var base_weight := 10000 / worlds.size()
	var remainder := 10000 - base_weight * worlds.size()
	for i in worlds.size():
		worlds[i].weight_basis_points = base_weight + (1 if i < remainder else 0)