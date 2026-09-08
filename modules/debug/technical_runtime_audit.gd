class_name TechnicalRuntimeAudit
extends RefCounted

# Deterministic black-box audit used by the technical executable. It does not replace
# the normal test suites: it exercises the same runtime seams a human build uses and
# returns a compact OK/WARN/FAIL report that can be attached to a bug report.

const ENCOUNTER_TRIALS := 2000
const CAPTURE_TRIALS := 2000
const STATISTICAL_TOLERANCE := 0.04
const MAX_SAMPLES := 24


func run(catalogs: DefinitionCatalog, world: Node2D, config: Dictionary) -> Dictionary:
	var started_usec := Time.get_ticks_usec()
	var checks: Array[Dictionary] = []
	var metrics: Dictionary = {}

	_audit_catalogs(catalogs, checks, metrics)
	_audit_world_geometry(world, checks, metrics)
	_audit_encounter_runtime(catalogs, config, checks, metrics)
	_audit_capture_runtime(catalogs, config, checks, metrics)
	_audit_trainer_levels(catalogs, config, checks, metrics)

	var counts := {"OK": 0, "WARN": 0, "FAIL": 0}
	for entry in checks:
		var status := String(entry.get("status", "FAIL"))
		counts[status] = int(counts.get(status, 0)) + 1
	var overall := "OK"
	if int(counts.FAIL) > 0:
		overall = "FAIL"
	elif int(counts.WARN) > 0:
		overall = "WARN"
	return {
		"schema_version": 1,
		"overall_status": overall,
		"counts": counts,
		"duration_msec": float(Time.get_ticks_usec() - started_usec) / 1000.0,
		"checks": checks,
		"metrics": metrics,
		"config": config.duplicate(true),
	}


func _audit_catalogs(catalogs: DefinitionCatalog, checks: Array[Dictionary], metrics: Dictionary) -> void:
	if catalogs == null:
		_add(checks, "DATA_CATALOGS_READY", false, {"reason": "catalogs_null"})
		return
	_add(checks, "DATA_CATALOGS_READY", true)

	metrics["species_count"] = catalogs.species_catalog.size()
	metrics["move_count"] = catalogs.move_catalog.size()
	metrics["ability_count"] = catalogs.ability_catalog.size()
	metrics["item_count"] = catalogs.item_catalog.size()

	var type_validation := PokemonTypeChart.validate_catalog(catalogs.type_catalog)
	_add(checks, "DATA_TYPE_CHART_COMPLETE", bool(type_validation.get("valid", false)), type_validation)

	var broken_type_refs: Array[String] = []
	var broken_move_refs: Array[String] = []
	var broken_ability_refs: Array[String] = []
	var broken_evolution_refs: Array[String] = []
	var invalid_capture_rates: Array[String] = []
	var zero_capture_rates: Array[String] = []
	var invalid_base_stats: Array[String] = []
	var empty_learnsets: Array[String] = []
	var evolution_count := 0
	var learnset_count := 0

	for species_id in catalogs.species_catalog.all_ids():
		var species := catalogs.species_catalog.get_by_id(species_id)
		if species == null:
			_sample(broken_type_refs, "%s:null_species" % String(species_id))
			continue
		for type_id in species.type_ids_resolved():
			if catalogs.type(type_id) == null:
				_sample(broken_type_refs, "%s:%s" % [String(species_id), String(type_id)])
		for ability_id in species.ability_ids:
			if catalogs.ability(ability_id) == null:
				_sample(broken_ability_refs, "%s:%s" % [String(species_id), String(ability_id)])
		if species.capture_rate < 0 or species.capture_rate > 255:
			_sample(invalid_capture_rates, "%s:%d" % [String(species_id), species.capture_rate])
		elif species.capture_rate == 0:
			_sample(zero_capture_rates, String(species_id))
		if (
			species.base_hp <= 0
			or species.base_attack <= 0
			or species.base_defense <= 0
			or species.base_speed <= 0
			or species.base_special_attack <= 0
			or species.base_special_defense <= 0
		):
			_sample(invalid_base_stats, String(species_id))
		if species.learnset.is_empty():
			_sample(empty_learnsets, String(species_id))
		for raw_entry in species.learnset:
			if not (raw_entry is LearnSetEntry):
				_sample(broken_move_refs, "%s:invalid_learnset_entry" % String(species_id))
				continue
			var entry := raw_entry as LearnSetEntry
			learnset_count += 1
			if entry.move_id == &"" or catalogs.move(entry.move_id) == null:
				_sample(broken_move_refs, "%s:%s" % [String(species_id), String(entry.move_id)])
		for raw_evolution in species.evolutions:
			if not (raw_evolution is EvolutionRecord):
				_sample(broken_evolution_refs, "%s:invalid_evolution_entry" % String(species_id))
				continue
			var evolution := raw_evolution as EvolutionRecord
			evolution_count += 1
			if evolution.species_id == &"" or catalogs.species(evolution.species_id) == null:
				_sample(broken_evolution_refs, "%s->%s" % [String(species_id), String(evolution.species_id)])
			if evolution.item_id != &"" and catalogs.item(evolution.item_id) == null:
				_sample(broken_evolution_refs, "%s:item:%s" % [String(species_id), String(evolution.item_id)])

	var invalid_move_types: Array[String] = []
	var invalid_move_fields: Array[String] = []
	var move_classifications: Dictionary = {}
	for move_id in catalogs.move_catalog.all_ids():
		var move := catalogs.move(move_id)
		if move == null:
			_sample(invalid_move_fields, "%s:null" % String(move_id))
			continue
		move_classifications[move.classification] = int(move_classifications.get(move.classification, 0)) + 1
		if move.type_id == &"" or catalogs.type(move.type_id) == null:
			_sample(invalid_move_types, "%s:%s" % [String(move_id), String(move.type_id)])
		if move.power < 0 or move.pp < 0 or move.accuracy < 0 or move.accuracy > 100:
			_sample(invalid_move_fields, "%s:power=%d,pp=%d,acc=%d" % [String(move_id), move.power, move.pp, move.accuracy])

	metrics["learnset_entries_checked"] = learnset_count
	metrics["evolutions_checked"] = evolution_count
	metrics["move_classifications"] = move_classifications
	metrics["zero_capture_rate_sample"] = zero_capture_rates
	metrics["empty_learnset_sample"] = empty_learnsets

	_add(checks, "DATA_SPECIES_TYPE_REFERENCES", broken_type_refs.is_empty(), {"sample": broken_type_refs})
	_add(checks, "DATA_LEARNSET_MOVE_REFERENCES", broken_move_refs.is_empty(), {"sample": broken_move_refs})
	_add(checks, "DATA_SPECIES_ABILITY_REFERENCES", broken_ability_refs.is_empty(), {"sample": broken_ability_refs})
	_add(checks, "DATA_EVOLUTION_REFERENCES", broken_evolution_refs.is_empty(), {"sample": broken_evolution_refs})
	_add(checks, "DATA_CAPTURE_RATE_RANGE", invalid_capture_rates.is_empty(), {"sample": invalid_capture_rates})
	_add(checks, "DATA_BASE_STATS_POSITIVE", invalid_base_stats.is_empty(), {"sample": invalid_base_stats})
	_add(checks, "DATA_MOVE_TYPE_REFERENCES", invalid_move_types.is_empty(), {"sample": invalid_move_types})
	_add(checks, "DATA_MOVE_FIELDS_RANGE", invalid_move_fields.is_empty(), {"sample": invalid_move_fields})
	_warn(checks, "DATA_ZERO_CAPTURE_RATES", not zero_capture_rates.is_empty(), {"sample": zero_capture_rates})
	_warn(checks, "DATA_EMPTY_LEARNSETS", not empty_learnsets.is_empty(), {"sample": empty_learnsets})


func _audit_world_geometry(world: Node2D, checks: Array[Dictionary], metrics: Dictionary) -> void:
	if world == null:
		_add(checks, "WORLD_SCENE_READY", false, {"reason": "world_null"})
		return
	_add(checks, "WORLD_SCENE_READY", true)

	var zone := world.get_node_or_null("EncounterZone") as Area2D
	var zone_shape := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D if zone != null else null
	var zone_rect := zone_shape.shape as RectangleShape2D if zone_shape != null and zone_shape.shape is RectangleShape2D else null
	var zone_inside_ok := false
	var zone_outside_ok := false
	if zone != null and zone_rect != null and world.has_method("zone_at_position"):
		var center := zone.global_position
		var outside := center + Vector2(zone_rect.size.x * 0.5 + 4.0, 0.0)
		zone_inside_ok = StringName(world.call("zone_at_position", center)) == StringName(zone.get("zone_id"))
		zone_outside_ok = StringName(world.call("zone_at_position", outside)) != StringName(zone.get("zone_id"))
	metrics["encounter_zone_center"] = _vec(zone.global_position) if zone != null else {}
	_add(checks, "WORLD_GRASS_INSIDE_DETECTED", zone_inside_ok)
	_add(checks, "WORLD_GRASS_OUTSIDE_REJECTED", zone_outside_ok)

	var trigger := world.get_node_or_null("TrainerTrigger") as Area2D
	var trigger_shape := trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D if trigger != null else null
	var trigger_rect := trigger_shape.shape as RectangleShape2D if trigger_shape != null and trigger_shape.shape is RectangleShape2D else null
	var trigger_inside_ok := false
	var trigger_outside_ok := false
	if trigger != null and trigger_rect != null and world.has_method("trainer_trigger_contains"):
		var trigger_center := trigger.global_position
		var trigger_outside := trigger_center + Vector2(trigger_rect.size.x * 0.5 + 4.0, 0.0)
		trigger_inside_ok = bool(world.call("trainer_trigger_contains", trigger_center))
		trigger_outside_ok = not bool(world.call("trainer_trigger_contains", trigger_outside))
	_add(checks, "WORLD_TRAINER_TRIGGER_INSIDE_DETECTED", trigger_inside_ok)
	_add(checks, "WORLD_TRAINER_TRIGGER_OUTSIDE_REJECTED", trigger_outside_ok)

	var player := world.get_node_or_null("Player") as CharacterBody2D
	var obstacle := world.get_node_or_null("CenterObstacle") as StaticBody2D
	var player_shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D if player != null else null
	var obstacle_shape := obstacle.get_node_or_null("CollisionShape2D") as CollisionShape2D if obstacle != null else null
	var player_rect := player_shape.shape as RectangleShape2D if player_shape != null and player_shape.shape is RectangleShape2D else null
	var obstacle_rect := obstacle_shape.shape as RectangleShape2D if obstacle_shape != null and obstacle_shape.shape is RectangleShape2D else null
	var layer_contract_ok := player != null and obstacle != null and (player.collision_mask & obstacle.collision_layer) != 0
	_add(checks, "WORLD_COLLISION_LAYER_CONTRACT", layer_contract_ok, {
		"player_mask": player.collision_mask if player != null else 0,
		"obstacle_layer": obstacle.collision_layer if obstacle != null else 0,
	})
	var obstacle_collision_ok := false
	var free_motion_ok := false
	if player != null and obstacle != null and player_rect != null and obstacle_rect != null:
		var from := player.global_transform
		from.origin = obstacle.global_position - Vector2(obstacle_rect.size.x * 0.5 + player_rect.size.x * 0.5 + 1.0, 0.0)
		obstacle_collision_ok = player.test_move(from, Vector2(4.0, 0.0))
		var free_from := player.global_transform
		free_motion_ok = not player.test_move(free_from, Vector2(6.0, 0.0))
	_add(checks, "WORLD_REAL_BODY_BLOCKS_OBSTACLE", obstacle_collision_ok)
	_add(checks, "WORLD_SHORT_FREE_MOTION_CLEAR", free_motion_ok)


func _audit_encounter_runtime(catalogs: DefinitionCatalog, config: Dictionary, checks: Array[Dictionary], metrics: Dictionary) -> void:
	if catalogs == null:
		return
	var species_id := StringName(String(config.get("wild_species_id", "pikachu")))
	var species := catalogs.species(species_id)
	if species == null:
		_add(checks, "ENCOUNTER_CONFIG_SPECIES_EXISTS", false, {"species_id": String(species_id)})
		return
	_add(checks, "ENCOUNTER_CONFIG_SPECIES_EXISTS", true, {"species_id": String(species_id)})
	var min_level := clampi(int(config.get("wild_min_level", 4)), 1, 100)
	var max_level := clampi(int(config.get("wild_max_level", 4)), 1, 100)
	if max_level < min_level:
		var swap := min_level
		min_level = max_level
		max_level = swap
	var chance_percent := clampi(int(config.get("encounter_chance_percent", 100)), 0, 100)
	var table := WildEncounterTable.new(&"audit_grass", chance_percent * 100)
	var slot_ok := table.add_slot(WildEncounterSlot.new(&"audit_slot", species_id, 1, min_level, max_level))
	_add(checks, "ENCOUNTER_TABLE_VALID", slot_ok and bool(table.validate(catalogs).get("ok", false)), table.to_dict())
	if not slot_ok:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 941001
	var hits := 0
	var invalid_payloads := 0
	for _index in range(ENCOUNTER_TRIALS):
		var outcome := WildEncounterSystem.resolve(table, rng, catalogs, ProgressionRuleset.new())
		if outcome.status == WildEncounterResult.ENCOUNTER:
			hits += 1
			if outcome.species_id != species_id or outcome.level < min_level or outcome.level > max_level or outcome.creature == null:
				invalid_payloads += 1
	var observed := float(hits) / float(ENCOUNTER_TRIALS)
	var expected := float(chance_percent) / 100.0
	var difference := absf(observed - expected)
	var probability_ok := difference <= STATISTICAL_TOLERANCE
	if chance_percent == 0:
		probability_ok = hits == 0
	elif chance_percent == 100:
		probability_ok = hits == ENCOUNTER_TRIALS
	metrics["encounter_probability"] = {
		"species_id": String(species_id),
		"trials": ENCOUNTER_TRIALS,
		"expected": expected,
		"observed": observed,
		"absolute_difference": difference,
	}
	_add(checks, "ENCOUNTER_EMPIRICAL_RATE_MATCHES_CONFIG", probability_ok, metrics.encounter_probability)
	_add(checks, "ENCOUNTER_PAYLOAD_SPECIES_LEVEL_VALID", invalid_payloads == 0, {"invalid_payloads": invalid_payloads})


func _audit_capture_runtime(catalogs: DefinitionCatalog, config: Dictionary, checks: Array[Dictionary], metrics: Dictionary) -> void:
	if catalogs == null:
		return
	var species_id := StringName(String(config.get("wild_species_id", "pikachu")))
	var species := catalogs.species(species_id)
	if species == null:
		return
	_add(checks, "CAPTURE_CONFIG_RATE_VALID", CaptureRuleset.is_valid_capture_rate(species.capture_rate), {
		"species_id": String(species_id), "capture_rate": species.capture_rate,
	})
	if not CaptureRuleset.is_valid_capture_rate(species.capture_rate):
		return

	var level := clampi(int(config.get("wild_min_level", 4)), 1, 100)
	var rules := ProgressionRuleset.new()
	var creature_rng := RandomNumberGenerator.new()
	creature_rng.seed = 942001
	var target := CreatureFactory.create(species, level, catalogs, rules, creature_rng, {"instance_id": &"audit_capture_target"})
	if target == null:
		_add(checks, "CAPTURE_TARGET_BUILD", false)
		return
	_add(checks, "CAPTURE_TARGET_BUILD", true)
	# Half HP keeps the audit representative without creating a KO edge case.
	target.current_hp = maxi(1, target.stats.max_hp / 2)
	var context := CaptureBattleContext.new()
	context.is_wild = true
	context.battle_finished = false
	context.target_owner_trainer_id = &""

	var balls: Array[StringName] = [&"poke_ball", &"great_ball", &"ultra_ball", &"master_ball"]
	var ball_metrics: Dictionary = {}
	for ball_id in balls:
		var attempt := CaptureAttempt.new(target, ball_id, context)
		var rng := RandomNumberGenerator.new()
		rng.seed = 943000 + balls.find(ball_id)
		var successes := 0
		var expected := -1.0
		var invalid_results := 0
		for trial in range(CAPTURE_TRIALS):
			var resolution := CaptureSystem.resolve(attempt, rng, catalogs, null)
			if resolution == null or resolution.result == null:
				invalid_results += 1
				continue
			if trial == 0:
				expected = 1.0 if ball_id == &"master_ball" else float(resolution.result.probability)
			if resolution.result.status == CaptureResult.SUCCESS:
				successes += 1
		var observed := float(successes) / float(CAPTURE_TRIALS)
		var diff := absf(observed - expected) if expected >= 0.0 else 1.0
		var rate_ok := invalid_results == 0 and diff <= STATISTICAL_TOLERANCE
		if expected == 0.0:
			rate_ok = successes == 0 and invalid_results == 0
		elif expected == 1.0:
			rate_ok = successes == CAPTURE_TRIALS and invalid_results == 0
		ball_metrics[String(ball_id)] = {
			"trials": CAPTURE_TRIALS,
			"expected": expected,
			"observed": observed,
			"absolute_difference": diff,
			"invalid_results": invalid_results,
		}
		_add(checks, "CAPTURE_EMPIRICAL_%s" % String(ball_id).to_upper(), rate_ok, ball_metrics[String(ball_id)])
	metrics["capture_probability"] = {
		"species_id": String(species_id),
		"capture_rate": species.capture_rate,
		"level": level,
		"current_hp": target.current_hp,
		"max_hp": target.stats.max_hp,
		"balls": ball_metrics,
	}


func _audit_trainer_levels(catalogs: DefinitionCatalog, config: Dictionary, checks: Array[Dictionary], metrics: Dictionary) -> void:
	if catalogs == null:
		return
	var player_rows: Array = config.get("player_team", [])
	var trainer_rows: Array = config.get("trainer_team", [])
	if player_rows.is_empty() or trainer_rows.is_empty():
		_add(checks, "TRAINER_LEVEL_FIXTURE_READY", false, {"reason": "empty_team"})
		return
	_add(checks, "TRAINER_LEVEL_FIXTURE_READY", true)

	var levels: Array[StringName] = [TrainerExpertise.LIMITED, TrainerExpertise.STANDARD, TrainerExpertise.FULL]
	var expected_caps := {
		String(TrainerExpertise.LIMITED): 1,
		String(TrainerExpertise.STANDARD): 2,
		String(TrainerExpertise.FULL): TrainerItemAwareActionProposal.INNER_ACTION_CAP,
	}
	var profile_id := StringName(String(config.get("trainer_profile_id", "balanced")))
	var reports: Dictionary = {}
	var legal_root_counts: Array[int] = []

	for level_index in range(levels.size()):
		var expertise_id := levels[level_index]
		var rules := ProgressionRuleset.new()
		var collection := PlayerCollection.new()
		var fixture_ok := true
		for index in range(player_rows.size()):
			var creature := _build_creature_from_row(player_rows[index] as Dictionary, catalogs, rules, "audit_player_%d_%d" % [level_index, index], 950000 + level_index * 100 + index)
			if creature == null or not collection.party.add_creature(creature):
				fixture_ok = false
				break
		var roster: Array[CreatureInstance] = []
		if fixture_ok:
			for index in range(trainer_rows.size()):
				var trainer_creature := _build_creature_from_row(trainer_rows[index] as Dictionary, catalogs, rules, "audit_trainer_%d_%d" % [level_index, index], 951000 + level_index * 100 + index)
				if trainer_creature == null:
					fixture_ok = false
					break
				roster.append(trainer_creature)
		if not fixture_ok:
			_add(checks, "TRAINER_LEVEL_%s_FIXTURE" % String(expertise_id).to_upper(), false)
			continue
		var session := TrainerBattleSession.new(collection, catalogs, rules)
		var begin_ok := session.begin_battle(StringName("audit_%s" % String(expertise_id)), roster, 952000 + level_index, profile_id, expertise_id)
		_add(checks, "TRAINER_LEVEL_%s_BEGIN" % String(expertise_id).to_upper(), begin_ok, {
			"profile_id": String(profile_id), "expertise_id": String(expertise_id),
		})
		if not begin_ok:
			continue
		var started_usec := Time.get_ticks_usec()
		var report := session.trainer_action_proposal_report_for_side(&"side_b")
		var elapsed_usec := Time.get_ticks_usec() - started_usec
		var cap := int(report.get("inner_max_actions_per_side", 0))
		var legal_count := int(report.get("legal_action_count", -1))
		legal_root_counts.append(legal_count)
		var complete := (
			bool(report.get("root_all_legal", false))
			and int(report.get("evaluated_root_count", -1)) == legal_count
			and int(report.get("required_depth", 0)) == TrainerItemAwareActionProposal.REQUIRED_DEPTH
		)
		_add(checks, "TRAINER_LEVEL_%s_CAP" % String(expertise_id).to_upper(), cap == int(expected_caps[String(expertise_id)]), {
			"expected_cap": int(expected_caps[String(expertise_id)]), "actual_cap": cap,
		})
		_add(checks, "TRAINER_LEVEL_%s_CONTRACT" % String(expertise_id).to_upper(), complete, {
			"legal_action_count": legal_count,
			"evaluated_root_count": int(report.get("evaluated_root_count", -1)),
			"required_depth": int(report.get("required_depth", 0)),
		})
		reports[String(expertise_id)] = {
			"label": TrainerExpertise.difficulty_label(expertise_id),
			"inner_action_cap": cap,
			"legal_action_count": legal_count,
			"proposal_status": String(report.get("proposal_status", "")),
			"decision_usec": elapsed_usec,
			"root_simulations": report.get("root_simulations", {}).duplicate(true),
		}

	var same_roots := legal_root_counts.size() == levels.size()
	if same_roots and not legal_root_counts.is_empty():
		for count in legal_root_counts:
			same_roots = same_roots and count == legal_root_counts[0]
	_add(checks, "TRAINER_LEVELS_KEEP_SAME_LEGAL_ROOTS", same_roots, {"legal_root_counts": legal_root_counts})
	metrics["trainer_ai_levels"] = reports


func _build_creature_from_row(
	row: Dictionary,
	catalogs: DefinitionCatalog,
	rules: ProgressionRuleset,
	instance_id: String,
	seed: int,
) -> CreatureInstance:
	var species_id := StringName(String(row.get("species_id", "")))
	var level := clampi(int(row.get("level", 1)), 1, 100)
	var species := catalogs.species(species_id)
	if species == null:
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return CreatureFactory.create(species, level, catalogs, rules, rng, {"instance_id": StringName(instance_id)})


func _add(checks: Array[Dictionary], code: String, ok: bool, details: Dictionary = {}) -> void:
	checks.append({
		"code": code,
		"status": "OK" if ok else "FAIL",
		"details": details.duplicate(true),
	})


func _warn(checks: Array[Dictionary], code: String, warning: bool, details: Dictionary = {}) -> void:
	checks.append({
		"code": code,
		"status": "WARN" if warning else "OK",
		"details": details.duplicate(true),
	})


func _sample(values: Array[String], value: String) -> void:
	if values.size() < MAX_SAMPLES:
		values.append(value)


func _vec(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}
