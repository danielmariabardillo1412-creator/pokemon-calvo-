class_name TrainerBeliefInferenceTestSuite
extends RefCounted

const MOVE_OLD := &"belief_old"
const MOVE_MID := &"belief_mid"
const MOVE_RECENT_A := &"belief_recent_a"
const MOVE_RECENT_B := &"belief_recent_b"
const MOVE_RECENT_C := &"belief_recent_c"
const MOVE_FUTURE := &"belief_future"
const MOVE_SECRET := &"belief_secret"
const MOVE_OWN := &"belief_own"
const MOVE_PRIORITY := &"belief_priority"

const PLAYER_SPECIES := &"belief_player_species"
const TRAINER_SPECIES := &"belief_trainer_species"
const ABILITY_A := &"belief_ability_a"
const ABILITY_B := &"belief_ability_b"
const ITEM_REVEALED := &"belief_item_revealed"

var _check: Callable
var _catalog := DefinitionCatalog.new()
var _rules := ProgressionRuleset.new()
var _client := BattleClient.new()


func run(check_callback: Callable) -> void:
	_check = check_callback
	_build_catalog()
	var tests := [
		"_test_schema_v1_migration_and_round_trip",
		"_test_public_species_level_priors",
		"_test_public_reveals_override_without_false_certainty",
		"_test_exclusive_pseudo_bayesian_update",
		"_test_same_priority_turn_order_refines_speed_range",
		"_test_priority_order_does_not_fake_speed_evidence",
	]
	for name in tests:
		print("TRAINER_BELIEF_TEST %s" % name)
		self.call(name)


func _build_catalog() -> void:
	for move_id in [
		MOVE_OLD, MOVE_MID, MOVE_RECENT_A, MOVE_RECENT_B, MOVE_RECENT_C,
		MOVE_FUTURE, MOVE_SECRET, MOVE_OWN,
	]:
		_add_move(move_id, 0)
	_add_move(MOVE_PRIORITY, 1)

	var player := _species(PLAYER_SPECIES, 50)
	var abilities: Array[StringName] = [ABILITY_A, ABILITY_B]
	player.ability_ids = abilities
	player.learnset.append(LearnSetEntry.new(1, MOVE_OLD, LearnsetSystem.LEVEL_UP))
	player.learnset.append(LearnSetEntry.new(3, MOVE_MID, LearnsetSystem.LEVEL_UP))
	player.learnset.append(LearnSetEntry.new(5, MOVE_RECENT_A, LearnsetSystem.LEVEL_UP))
	player.learnset.append(LearnSetEntry.new(10, MOVE_RECENT_B, LearnsetSystem.LEVEL_UP))
	player.learnset.append(LearnSetEntry.new(15, MOVE_RECENT_C, LearnsetSystem.LEVEL_UP))
	player.learnset.append(LearnSetEntry.new(20, MOVE_FUTURE, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(player)

	var trainer := _species(TRAINER_SPECIES, 75)
	var trainer_abilities: Array[StringName] = [&"belief_trainer_ability"]
	trainer.ability_ids = trainer_abilities
	trainer.learnset.append(LearnSetEntry.new(1, MOVE_OWN, LearnsetSystem.LEVEL_UP))
	_catalog.add_species(trainer)


func _species(species_id: StringName, base_speed: int) -> CreatureSpecies:
	var species := CreatureSpecies.new()
	species.id = species_id
	species.display_name = String(species_id)
	species.primary_type_id = &"normal"
	var types: Array[StringName] = [&"normal"]
	species.type_ids = types
	species.base_hp = 50
	species.base_attack = 50
	species.base_defense = 50
	species.base_speed = base_speed
	species.base_special_attack = 50
	species.base_special_defense = 50
	return species


func _add_move(move_id: StringName, priority: int) -> void:
	var move := MoveDefinition.new()
	move.id = move_id
	move.display_name = String(move_id)
	move.power = 0
	move.type_id = &"normal"
	move.priority = priority
	move.damage_class = "status"
	move.accuracy = -1
	move.pp = 30
	_catalog.add_move(move)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _creature(
	species_id: StringName,
	instance_id: StringName,
	level: int,
	moves: Array[StringName],
	seed_value: int,
	extra_overrides: Dictionary = {},
) -> CreatureInstance:
	var overrides := extra_overrides.duplicate(true)
	overrides["instance_id"] = instance_id
	overrides["moves"] = moves
	return CreatureFactory.create(
		_catalog.species(species_id),
		level,
		_catalog,
		_rules,
		_rng(seed_value),
		overrides,
	)


func _state(
	player: CreatureInstance,
	trainer: CreatureInstance,
	seed_value: int = 123,
) -> BattleState:
	var party_a: Array[CreatureInstance] = [player]
	var party_b: Array[CreatureInstance] = [trainer]
	return BattleState.create_with_parties(
		&"belief_test_battle",
		party_a,
		party_b,
		seed_value,
	)


func _observation(state: BattleState, memory: TrainerBattleMemory) -> TrainerObservation:
	return TrainerObservationBuilder.build(state, &"side_b", memory)


func _sum_confidence(candidates: Dictionary) -> int:
	var total := 0
	for record in candidates.values():
		total += int((record as Dictionary).get("confidence_basis_points", 0))
	return total


func _test_schema_v1_migration_and_round_trip() -> void:
	var legacy := {
		"schema_version": 1,
		"battle_id": "legacy_battle",
		"observer_side_id": "side_b",
		"hypotheses": {
			"legacy_enemy": {
				"move": {
					"legacy_move": {
						"confidence_basis_points": 3200,
						"evidence": "inferred",
					},
				},
			},
		},
	}
	var migrated := TrainerBeliefState.from_dict(legacy)
	_check.call("belief_v1_migrates_to_v2", int(migrated.to_dict().get("schema_version", 0)) == 2)
	_check.call(
		"belief_v1_candidate_retained",
		migrated.confidence_basis_points(&"legacy_enemy", TrainerBeliefState.DOMAIN_MOVE, &"legacy_move") == 3200,
	)
	_check.call(
		"belief_v1_provenance_defaults_empty",
		migrated.provenance_for(&"legacy_enemy", TrainerBeliefState.DOMAIN_MOVE, &"legacy_move").is_empty(),
	)
	_check.call("belief_v1_ranges_default_empty", migrated.ranges.is_empty())
	var encoded := migrated.to_dict()
	var restored := TrainerBeliefState.from_dict(JSON.parse_string(JSON.stringify(encoded)))
	_check.call("belief_v2_round_trip", JSON.stringify(restored.to_dict()) == JSON.stringify(encoded))


func _test_public_species_level_priors() -> void:
	var player_moves: Array[StringName] = [MOVE_SECRET]
	var trainer_moves: Array[StringName] = [MOVE_OWN]
	var player := _creature(PLAYER_SPECIES, &"prior_player", 15, player_moves, 1)
	var trainer := _creature(TRAINER_SPECIES, &"prior_trainer", 15, trainer_moves, 2)
	var state := _state(player, trainer)
	AuthoritativeBattleServer.new(state, _catalog)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	var belief := TrainerBeliefState.new()
	belief.begin(memory)
	var inference := TrainerBeliefInference.new(_catalog)
	var observation := _observation(state, memory)
	_check.call("belief_seed_public_observation", inference.seed_from_observation(belief, observation))

	var moves := belief.candidates(player.instance_id, TrainerBeliefState.DOMAIN_MOVE)
	_check.call("belief_prior_old_move_present", moves.has(String(MOVE_OLD)))
	_check.call("belief_prior_recent_move_present", moves.has(String(MOVE_RECENT_C)))
	_check.call("belief_prior_future_move_absent", not moves.has(String(MOVE_FUTURE)))
	_check.call("belief_prior_actual_hidden_move_absent", not moves.has(String(MOVE_SECRET)))
	_check.call(
		"belief_prior_recent_more_likely_than_old",
		belief.confidence_basis_points(player.instance_id, TrainerBeliefState.DOMAIN_MOVE, MOVE_RECENT_C)
		> belief.confidence_basis_points(player.instance_id, TrainerBeliefState.DOMAIN_MOVE, MOVE_OLD),
	)

	var abilities := belief.candidates(player.instance_id, TrainerBeliefState.DOMAIN_ABILITY)
	_check.call("belief_ability_species_candidates", abilities.size() == 2)
	_check.call("belief_ability_uniform_prior_sums_10000", _sum_confidence(abilities) == 10000)
	_check.call(
		"belief_item_no_fake_prior",
		belief.candidates(player.instance_id, TrainerBeliefState.DOMAIN_ITEM).is_empty(),
	)
	var speed_range := belief.range_for(player.instance_id, TrainerBeliefState.DOMAIN_SPEED)
	_check.call(
		"belief_public_speed_range_valid",
		int(speed_range.get("min_value", 0)) > 0
		and int(speed_range.get("max_value", 0)) > int(speed_range.get("min_value", 0)),
	)
	_check.call(
		"belief_public_speed_provenance",
		(speed_range.get("provenance", []) as Array).has(TrainerBeliefInference.PROVENANCE_SPEED),
	)
	var serialized := JSON.stringify(belief.to_dict())
	_check.call(
		"belief_snapshot_has_no_hidden_stat_payload",
		not serialized.contains("\"ivs\"")
		and not serialized.contains("\"evs\"")
		and not serialized.contains("nature_id")
		and not serialized.contains("rng_state"),
	)


func _test_public_reveals_override_without_false_certainty() -> void:
	var player_moves: Array[StringName] = [MOVE_SECRET]
	var trainer_moves: Array[StringName] = [MOVE_OWN]
	var player := _creature(PLAYER_SPECIES, &"reveal_player", 15, player_moves, 3)
	var trainer := _creature(TRAINER_SPECIES, &"reveal_trainer", 15, trainer_moves, 4)
	var state := _state(player, trainer)
	AuthoritativeBattleServer.new(state, _catalog)
	var memory := TrainerBattleMemory.new()
	memory.begin(state, &"side_b")
	var belief := TrainerBeliefState.new()
	belief.begin(memory)
	TrainerBeliefInference.new(_catalog).seed_from_observation(belief, _observation(state, memory))

	memory.reveal_move(player.instance_id, MOVE_SECRET)
	memory.reveal_ability(player.instance_id, ABILITY_B)
	memory.reveal_item(player.instance_id, ITEM_REVEALED)
	belief.sync_revealed(memory)
	_check.call(
		"belief_reveal_accepts_out_of_prior_move",
		belief.candidates(player.instance_id, TrainerBeliefState.DOMAIN_MOVE).has(String(MOVE_SECRET)),
	)
	_check.call(
		"belief_revealed_move_certain",
		belief.confidence_basis_points(player.instance_id, TrainerBeliefState.DOMAIN_MOVE, MOVE_SECRET) == 10000,
	)
	_check.call(
		"belief_revealed_move_marked",
		belief.evidence_for(player.instance_id, TrainerBeliefState.DOMAIN_MOVE, MOVE_SECRET) == TrainerBeliefState.EVIDENCE_REVEALED,
	)
	_check.call(
		"belief_reveal_keeps_other_move_hypotheses",
		belief.candidates(player.instance_id, TrainerBeliefState.DOMAIN_MOVE).has(String(MOVE_OLD)),
	)
	var abilities := belief.candidates(player.instance_id, TrainerBeliefState.DOMAIN_ABILITY)
	_check.call("belief_revealed_ability_prunes_candidates", abilities.size() == 1)
	_check.call(
		"belief_revealed_ability_certain",
		belief.confidence_basis_points(player.instance_id, TrainerBeliefState.DOMAIN_ABILITY, ABILITY_B) == 10000,
	)
	var items := belief.candidates(player.instance_id, TrainerBeliefState.DOMAIN_ITEM)
	_check.call("belief_item_only_exists_after_evidence", items.size() == 1)
	_check.call(
		"belief_revealed_item_certain",
		belief.confidence_basis_points(player.instance_id, TrainerBeliefState.DOMAIN_ITEM, ITEM_REVEALED) == 10000,
	)


func _test_exclusive_pseudo_bayesian_update() -> void:
	var belief := TrainerBeliefState.new()
	belief.set_candidate(
		&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_A,
		5000, TrainerBeliefState.EVIDENCE_PRIOR, ["uniform_prior"]
	)
	belief.set_candidate(
		&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_B,
		5000, TrainerBeliefState.EVIDENCE_PRIOR, ["uniform_prior"]
	)
	var likelihoods := {String(ABILITY_A): 8000, String(ABILITY_B): 2000}
	_check.call(
		"belief_bayes_update_applies",
		belief.apply_exclusive_likelihoods(
			&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY,
			likelihoods, &"test_public_evidence"
		),
	)
	_check.call(
		"belief_bayes_a_8000",
		belief.confidence_basis_points(&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_A) == 8000,
	)
	_check.call(
		"belief_bayes_b_2000",
		belief.confidence_basis_points(&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_B) == 2000,
	)
	_check.call(
		"belief_bayes_normalized",
		_sum_confidence(belief.candidates(&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY)) == 10000,
	)
	_check.call(
		"belief_bayes_becomes_inferred",
		belief.evidence_for(&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_A) == TrainerBeliefState.EVIDENCE_INFERRED,
	)
	_check.call(
		"belief_bayes_provenance_retained",
		belief.provenance_for(&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_A).has("test_public_evidence"),
	)
	belief.reveal_single(&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_B)
	_check.call(
		"belief_bayes_never_overwrites_reveal",
		not belief.apply_exclusive_likelihoods(
			&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY,
			likelihoods, &"late_inference"
		),
	)
	_check.call(
		"belief_reveal_survives_late_inference",
		belief.confidence_basis_points(&"bayes_enemy", TrainerBeliefState.DOMAIN_ABILITY, ABILITY_B) == 10000,
	)


func _test_same_priority_turn_order_refines_speed_range() -> void:
	var player_moves: Array[StringName] = [MOVE_SECRET]
	var trainer_moves: Array[StringName] = [MOVE_OWN]
	var player := _creature(
		PLAYER_SPECIES, &"speed_player", 30, player_moves, 5,
		{
			"ivs": {"speed": 31},
			"evs": {"speed": 100},
			"nature_id": &"timid",
		}
	)
	var trainer := _creature(
		TRAINER_SPECIES, &"speed_trainer", 30, trainer_moves, 6,
		{
			"ivs": {"speed": 0},
			"evs": {"speed": 0},
			"nature_id": &"hardy",
		}
	)
	var state := _state(player, trainer, 99)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var controller := TrainerIntelligenceController.new(&"side_b", TrainerBrain.new(), _catalog)
	_check.call("belief_speed_controller_begin", controller.begin(server))
	var before := controller.belief.range_for(player.instance_id, TrainerBeliefState.DOMAIN_SPEED)
	_check.call("belief_speed_prior_seeded", not before.is_empty())
	controller.choose_action(server)
	_check.call("belief_speed_previous_context_captured", controller.last_context != null)

	var player_action := _client.request_move(
		state.turn + 1, player.instance_id, MOVE_SECRET, trainer.instance_id, &"side_a"
	)
	var trainer_action := _client.request_move(
		state.turn + 1, trainer.instance_id, MOVE_OWN, player.instance_id, &"side_b"
	)
	var actions: Array[BattleAction] = [player_action, trainer_action]
	var events := server.submit_turn(actions)
	var first_actor: StringName = &""
	for event in events:
		if event.kind == BattleEvent.ACTION_USED:
			first_actor = event.actor_id
			break
	_check.call("belief_speed_fixture_opponent_really_faster", first_actor == player.instance_id)
	_check.call("belief_speed_controller_observe", controller.observe(events, server))
	var after := controller.belief.range_for(player.instance_id, TrainerBeliefState.DOMAIN_SPEED)
	_check.call(
		"belief_speed_range_refined",
		int(after.get("min_value", 0)) > int(before.get("min_value", 0))
		and int(after.get("max_value", 0)) <= int(before.get("max_value", 0)),
	)
	_check.call(
		"belief_speed_hidden_actual_stays_inside_public_bound",
		player.stats.speed >= int(after.get("min_value", 0))
		and player.stats.speed <= int(after.get("max_value", 0)),
	)
	_check.call(
		"belief_speed_order_provenance",
		_has_provenance(after, TrainerBeliefInference.PROVENANCE_ORDER),
	)
	var context_json := JSON.stringify(controller.last_context.to_dict())
	_check.call(
		"belief_speed_context_still_no_hidden_opponent_stats",
		not context_json.contains("rng_state")
		and not context_json.contains("\"ivs\"")
		and not context_json.contains("\"evs\""),
	)


func _test_priority_order_does_not_fake_speed_evidence() -> void:
	var player_moves: Array[StringName] = [MOVE_PRIORITY]
	var trainer_moves: Array[StringName] = [MOVE_OWN]
	var player := _creature(
		PLAYER_SPECIES, &"priority_player", 30, player_moves, 7,
		{"ivs": {"speed": 0}, "evs": {"speed": 0}, "nature_id": &"brave"}
	)
	var trainer := _creature(
		TRAINER_SPECIES, &"priority_trainer", 30, trainer_moves, 8,
		{"ivs": {"speed": 31}, "evs": {"speed": 252}, "nature_id": &"timid"}
	)
	var state := _state(player, trainer, 101)
	var server := AuthoritativeBattleServer.new(state, _catalog)
	var controller := TrainerIntelligenceController.new(&"side_b", TrainerBrain.new(), _catalog)
	_check.call("belief_priority_controller_begin", controller.begin(server))
	var before := controller.belief.range_for(player.instance_id, TrainerBeliefState.DOMAIN_SPEED)
	_check.call("belief_priority_speed_prior_seeded", not before.is_empty())
	controller.choose_action(server)
	_check.call("belief_priority_previous_context_captured", controller.last_context != null)

	var player_action := _client.request_move(
		state.turn + 1, player.instance_id, MOVE_PRIORITY, trainer.instance_id, &"side_a"
	)
	var trainer_action := _client.request_move(
		state.turn + 1, trainer.instance_id, MOVE_OWN, player.instance_id, &"side_b"
	)
	var actions: Array[BattleAction] = [player_action, trainer_action]
	var events := server.submit_turn(actions)
	_check.call("belief_priority_controller_observe", controller.observe(events, server))
	var after := controller.belief.range_for(player.instance_id, TrainerBeliefState.DOMAIN_SPEED)
	_check.call(
		"belief_priority_does_not_refine_speed",
		int(after.get("min_value", -1)) == int(before.get("min_value", -2))
		and int(after.get("max_value", -1)) == int(before.get("max_value", -2)),
	)
	_check.call(
		"belief_priority_no_fake_order_provenance",
		not _has_provenance(after, TrainerBeliefInference.PROVENANCE_ORDER),
	)


func _has_provenance(record: Dictionary, prefix: String) -> bool:
	for value in record.get("provenance", []):
		if String(value).begins_with(prefix):
			return true
	return false
