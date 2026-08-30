class_name TrainerBeliefInference
extends RefCounted

# Public-information inference only. This service consumes TrainerObservation and the
# sanitized TrainerBattleMemory event envelope; it never receives BattleState, RNG,
# CreatureInstance opponents or raw BattleEvent metadata.

const MOVE_RECENT_PRIOR_BP := 6500
const MOVE_OLDER_PRIOR_BP := 2500
const SPEED_BOUND_CONFIDENCE_BP := 10000

const PROVENANCE_LEVEL_UP := "public_level_up_learnset_v1"
const PROVENANCE_ABILITY := "uniform_species_ability_prior_v1"
const PROVENANCE_SPEED := "public_species_level_speed_bounds_v1"
const PROVENANCE_ORDER := "same_priority_turn_order_v1"

var _catalog: DefinitionCatalog
var _ruleset: BattleRuleset


func _init(
	catalog: DefinitionCatalog,
	ruleset: BattleRuleset = null,
) -> void:
	_catalog = catalog
	_ruleset = ruleset if ruleset != null else BattleRuleset.new()


func seed_from_observation(
	belief: TrainerBeliefState,
	observation: TrainerObservation,
) -> bool:
	if belief == null or observation == null or _catalog == null:
		return false
	if belief.battle_id != &"" and belief.battle_id != observation.battle_id:
		return false
	for view in observation.observed_opponents:
		var creature_id := StringName(view.get("instance_id", ""))
		var species_id := StringName(view.get("species_id", ""))
		var level := maxi(1, int(view.get("level", 1)))
		var species := _catalog.species(species_id)
		if creature_id == &"" or species == null:
			continue
		_seed_move_priors(belief, creature_id, species, level)
		_seed_ability_prior(belief, creature_id, species)
		_seed_speed_bounds(belief, creature_id, species, level)
	return true


func update_after_observation(
	belief: TrainerBeliefState,
	previous_observation: TrainerObservation,
	memory: TrainerBattleMemory,
	current_observation: TrainerObservation,
) -> bool:
	if belief == null or memory == null or current_observation == null:
		return false
	if not belief.sync_revealed(memory):
		return false
	seed_from_observation(belief, current_observation)
	if previous_observation != null:
		_infer_speed_from_turn_order(
			belief,
			previous_observation,
			memory,
			current_observation.turn,
		)
	return true


func _seed_move_priors(
	belief: TrainerBeliefState,
	creature_id: StringName,
	species: CreatureSpecies,
	level: int,
) -> void:
	# Level-up data is a useful public prior, not a closed action list. Older learned moves
	# remain possible because move-learning choices may preserve them; non-level-up/TM
	# systems may also exist later. A revealed move always overrides the prior.
	var latest_level_by_move: Dictionary = {}
	for raw_entry in species.learnset:
		if not (raw_entry is LearnSetEntry):
			continue
		var entry := raw_entry as LearnSetEntry
		if entry.method != LearnsetSystem.LEVEL_UP or entry.level > level or entry.move_id == &"":
			continue
		var key := String(entry.move_id)
		latest_level_by_move[key] = maxi(int(latest_level_by_move.get(key, -1)), entry.level)
	var learned: Array[Dictionary] = []
	for move_key in latest_level_by_move.keys():
		learned.append({
			"move_id": String(move_key),
			"level": int(latest_level_by_move[move_key]),
		})
	learned.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var level_a := int(a.get("level", 0))
		var level_b := int(b.get("level", 0))
		if level_a == level_b:
			return String(a.get("move_id", "")) < String(b.get("move_id", ""))
		return level_a < level_b
	)
	var recent_start := maxi(0, learned.size() - ProgressionRuleset.MOVE_SLOTS_MAX)
	var existing := belief.candidates(creature_id, TrainerBeliefState.DOMAIN_MOVE)
	for index in range(learned.size()):
		var record: Dictionary = learned[index]
		var move_id := StringName(record.get("move_id", ""))
		if move_id == &"" or existing.has(String(move_id)):
			continue
		var confidence := MOVE_RECENT_PRIOR_BP if index >= recent_start else MOVE_OLDER_PRIOR_BP
		belief.set_candidate(
			creature_id,
			TrainerBeliefState.DOMAIN_MOVE,
			move_id,
			confidence,
			TrainerBeliefState.EVIDENCE_PRIOR,
			["%s:learned_at_%d" % [PROVENANCE_LEVEL_UP, int(record.get("level", 0))]],
		)


func _seed_ability_prior(
	belief: TrainerBeliefState,
	creature_id: StringName,
	species: CreatureSpecies,
) -> void:
	if belief.has_revealed_candidate(creature_id, TrainerBeliefState.DOMAIN_ABILITY):
		return
	var existing := belief.candidates(creature_id, TrainerBeliefState.DOMAIN_ABILITY)
	if not existing.is_empty():
		return
	var ability_ids: Array[StringName] = []
	for ability_id in species.ability_ids:
		if ability_id != &"" and not ability_ids.has(ability_id):
			ability_ids.append(ability_id)
	ability_ids.sort()
	if ability_ids.is_empty():
		return
	var base := 10000 / ability_ids.size()
	var remainder := 10000 - base * ability_ids.size()
	for index in range(ability_ids.size()):
		var confidence := base + (1 if index < remainder else 0)
		belief.set_candidate(
			creature_id,
			TrainerBeliefState.DOMAIN_ABILITY,
			ability_ids[index],
			confidence,
			TrainerBeliefState.EVIDENCE_PRIOR,
			[PROVENANCE_ABILITY],
		)


func _seed_speed_bounds(
	belief: TrainerBeliefState,
	creature_id: StringName,
	species: CreatureSpecies,
	level: int,
) -> void:
	if not belief.range_for(creature_id, TrainerBeliefState.DOMAIN_SPEED).is_empty():
		return
	var min_speed := _raw_speed_stat(
		species.base_speed,
		level,
		ProgressionRuleset.IV_MIN,
		0,
		9000,
	)
	var max_speed := _raw_speed_stat(
		species.base_speed,
		level,
		ProgressionRuleset.IV_MAX,
		ProgressionRuleset.EV_PER_STAT_MAX,
		11000,
	)
	belief.set_range(
		creature_id,
		TrainerBeliefState.DOMAIN_SPEED,
		min_speed,
		max_speed,
		SPEED_BOUND_CONFIDENCE_BP,
		TrainerBeliefState.EVIDENCE_PRIOR,
		[PROVENANCE_SPEED],
	)


func _infer_speed_from_turn_order(
	belief: TrainerBeliefState,
	previous: TrainerObservation,
	memory: TrainerBattleMemory,
	observed_turn: int,
) -> bool:
	if previous == null or memory == null:
		return false
	if observed_turn != previous.turn + 1:
		return false
	var own_id := previous.own_active_id
	var opponent_id := previous.opponent_active_id
	if own_id == &"" or opponent_id == &"":
		return false

	# Memory contains only the sanitized semantic envelope. Two ACTION_USED records are
	# required; switches, prevented actions and KO-before-action intentionally produce no bound.
	var own_record: Dictionary = {}
	var opponent_record: Dictionary = {}
	var own_index := -1
	var opponent_index := -1
	var action_index := 0
	for raw_record in memory.event_log:
		var record := raw_record as Dictionary
		if int(record.get("turn", -1)) != observed_turn:
			continue
		if StringName(record.get("kind", "")) != BattleEvent.ACTION_USED:
			continue
		var actor_id := StringName(record.get("actor_id", ""))
		if actor_id == own_id and own_record.is_empty():
			own_record = record
			own_index = action_index
		elif actor_id == opponent_id and opponent_record.is_empty():
			opponent_record = record
			opponent_index = action_index
		action_index += 1
	if own_record.is_empty() or opponent_record.is_empty():
		return false

	var own_move := _catalog.move(StringName(own_record.get("move_id", "")))
	var opponent_move := _catalog.move(StringName(opponent_record.get("move_id", "")))
	if own_move == null or opponent_move == null or own_move.priority != opponent_move.priority:
		return false

	var own_view := _view_by_id(previous.own_party, own_id)
	var opponent_view := _view_by_id(previous.observed_opponents, opponent_id)
	if own_view.is_empty() or opponent_view.is_empty():
		return false
	var own_stats: Dictionary = own_view.get("stats", {})
	var own_raw_speed := int(own_stats.get("speed", 0))
	if own_raw_speed <= 0:
		return false
	var own_effective_speed := _effective_speed(own_raw_speed, own_view)
	var current_range := belief.range_for(opponent_id, TrainerBeliefState.DOMAIN_SPEED)
	if current_range.is_empty():
		var species := _catalog.species(StringName(opponent_view.get("species_id", "")))
		if species == null:
			return false
		_seed_speed_bounds(
			belief,
			opponent_id,
			species,
			maxi(1, int(opponent_view.get("level", 1))),
		)
		current_range = belief.range_for(opponent_id, TrainerBeliefState.DOMAIN_SPEED)
	if current_range.is_empty():
		return false

	var opponent_first := opponent_index < own_index
	var compatible_min := -1
	var compatible_max := -1
	for raw_speed in range(
		int(current_range.get("min_value", 1)),
		int(current_range.get("max_value", 1)) + 1
	):
		var effective := _effective_speed(raw_speed, opponent_view)
		var compatible := (
			effective >= own_effective_speed
			if opponent_first
			else effective <= own_effective_speed
		)
		if not compatible:
			continue
		if compatible_min < 0:
			compatible_min = raw_speed
		compatible_max = raw_speed
	if compatible_min < 0:
		return false
	return belief.refine_range(
		opponent_id,
		TrainerBeliefState.DOMAIN_SPEED,
		compatible_min,
		compatible_max,
		10000,
		TrainerBeliefState.EVIDENCE_INFERRED,
		["%s:turn_%d" % [PROVENANCE_ORDER, observed_turn]],
	)


func _effective_speed(raw_speed: int, view: Dictionary) -> int:
	var stages: Dictionary = view.get("stat_stages", {})
	var speed_stage := int(stages.get("speed", 0))
	var value := raw_speed * _ruleset.stat_multiplier_basis_points(speed_stage) / 10000
	var persistent_status := StringName(view.get("persistent_status_id", ""))
	if persistent_status == &"" and view.has("status_state"):
		var status_state: Dictionary = view.get("status_state", {})
		persistent_status = StringName(status_state.get("persistent_id", ""))
	if persistent_status == &"paralysis":
		value = value * _ruleset.paralysis_speed_multiplier_basis_points / 10000
	return maxi(1, value)


static func _raw_speed_stat(
	base_speed: int,
	level: int,
	iv: int,
	ev: int,
	nature_multiplier_basis_points: int,
) -> int:
	var lvl := maxi(1, level)
	var trained := (
		2 * maxi(1, base_speed)
		+ clampi(iv, ProgressionRuleset.IV_MIN, ProgressionRuleset.IV_MAX)
		+ clampi(ev, 0, ProgressionRuleset.EV_PER_STAT_MAX) / 4
	) * lvl
	var value := trained / 100 + 5
	value = value * nature_multiplier_basis_points / 10000
	return maxi(1, value)


static func _view_by_id(views: Array[Dictionary], creature_id: StringName) -> Dictionary:
	for view in views:
		if StringName(view.get("instance_id", "")) == creature_id:
			return view
	return {}
