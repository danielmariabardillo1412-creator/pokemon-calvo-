class_name TrainerRosterOperationalEvidenceAuditTestSuite
extends TrainerRosterStructuralValueProductionTestSuite

const OPERATIONAL_EVIDENCE_MODEL_ID := "trainer_roster_current_operational_evidence_audit_v1"
const PP_SENSITIVE_ROLE_IDS: Array[String] = [
	"physical_attacker",
	"special_attacker",
	"fast_attacker",
	"support",
]

var _operational_ruleset := BattleRuleset.new()
var _operational_role_inference := TrainerRosterRoleInference.new()


func run(check_callback: Callable) -> void:
	super.run(check_callback)
	_test_current_operational_evidence()


func _test_current_operational_evidence() -> void:
	_enable_runtime_team_moves()
	var fire := _view(
		&"c3f_fire",
		TC_FIRE_A,
		StatBlock.new(100, 160, 80, 90, 60, 80),
		[TC_FIRE_PHYS, TC_SUPPORT],
	)
	_set_move_pp(fire, TC_FIRE_PHYS, 20, 20)
	_set_move_pp(fire, TC_SUPPORT, 20, 20)
	fire["current_hp"] = 50
	fire["held_item_id"] = "c3f_test_item"
	fire["held_item_consumed"] = false
	var status_state := fire.get("status_state", {}) as Dictionary
	status_state["persistent_id"] = String(StatusSystem.BURN)
	status_state["volatile"] = {"confusion": {"turns": 2}}
	fire["status_state"] = status_state
	fire["stat_stages"] = {"attack": 6, "speed": -6}

	var snapshot: Dictionary = fire.duplicate(true)
	var evidence: Dictionary = _operational_evidence(fire)
	_check.call(
		"roster_operational_evidence_model_recorded",
		String(evidence.get("model_id", "")) == OPERATIONAL_EVIDENCE_MODEL_ID,
	)
	_check.call(
		"roster_operational_evidence_identity_recorded",
		String(evidence.get("instance_id", "")) == "c3f_fire"
		and String(evidence.get("species_id", "")) == String(TC_FIRE_A),
	)
	var hp: Dictionary = evidence.get("hp", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_hp_ratio_current_state",
		int(hp.get("current_hp", -1)) == 50
		and int(hp.get("max_hp", -1)) == 100
		and int(hp.get("hp_ratio_bp", -1)) == 5000,
	)
	_check.call(
		"roster_operational_evidence_does_not_mutate_input",
		fire == snapshot,
	)

	var runtime_moves: Array = evidence.get("runtime_move_pp", []) as Array
	_check.call(
		"roster_operational_evidence_tracks_runtime_pp_per_move",
		runtime_moves.size() == 2
		and int(_move_evidence(evidence, String(TC_FIRE_PHYS)).get("pp_ratio_bp", -1)) == 10000
		and int(_move_evidence(evidence, String(TC_SUPPORT)).get("pp_ratio_bp", -1)) == 10000,
	)
	_check.call(
		"roster_operational_evidence_runtime_moves_available",
		(evidence.get("available_runtime_move_ids", []) as Array).has(String(TC_FIRE_PHYS))
		and (evidence.get("available_runtime_move_ids", []) as Array).has(String(TC_SUPPORT))
		and (evidence.get("depleted_runtime_move_ids", []) as Array).is_empty(),
	)
	var physical_route: Dictionary = _move_evidence(evidence, String(TC_FIRE_PHYS))
	var support_route: Dictionary = _move_evidence(evidence, String(TC_SUPPORT))
	var physical_affinity: Dictionary = physical_route.get("pp_sensitive_role_affinity_bp", {}) as Dictionary
	var support_affinity: Dictionary = support_route.get("pp_sensitive_role_affinity_bp", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_pp_routes_keep_role_affinity",
		int(physical_affinity.get("physical_attacker", 0)) > 0
		and int(support_affinity.get("support", 0)) > 0,
	)

	var status: Dictionary = evidence.get("persistent_status", {}) as Dictionary
	var status_effects: Dictionary = status.get("runtime_effects", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_burn_runtime_semantics",
		String(status.get("status_id", "")) == String(StatusSystem.BURN)
		and bool(status.get("recognized", false))
		and int(status_effects.get("physical_damage_multiplier_bp", -1)) == 5000
		and int(status_effects.get("residual_max_hp_divisor", -1)) == 16,
	)
	var held_item: Dictionary = evidence.get("held_item", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_held_item_availability_recorded",
		String(held_item.get("item_id", "")) == "c3f_test_item"
		and bool(held_item.get("present", false))
		and not bool(held_item.get("consumed", true))
		and bool(held_item.get("available", false))
		and not held_item.has("generic_penalty_bp"),
	)
	_check.call(
		"roster_operational_evidence_transients_excluded",
		not evidence.has("stat_stages")
		and not status.has("volatile")
		and (evidence.get("excluded_transient_fields", []) as Array).has("stat_stages")
		and (evidence.get("excluded_transient_fields", []) as Array).has("status_state.volatile"),
	)

	var no_transients: Dictionary = fire.duplicate(true)
	no_transients["stat_stages"] = {}
	var clean_status := no_transients.get("status_state", {}) as Dictionary
	clean_status["volatile"] = {}
	no_transients["status_state"] = clean_status
	_check.call(
		"roster_operational_evidence_transients_do_not_change_persistent_output",
		_operational_evidence(no_transients) == evidence,
	)

	var paralysis := fire.duplicate(true)
	_set_status(paralysis, StatusSystem.PARALYSIS, 0, 0)
	var paralysis_effects: Dictionary = (
		_operational_evidence(paralysis).get("persistent_status", {}) as Dictionary
	).get("runtime_effects", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_paralysis_runtime_semantics",
		int(paralysis_effects.get("speed_multiplier_bp", -1)) == 5000
		and int(paralysis_effects.get("action_skip_chance_bp", -1)) == 2500,
	)

	var poison := fire.duplicate(true)
	_set_status(poison, StatusSystem.POISON, 0, 0)
	var poison_effects: Dictionary = (
		_operational_evidence(poison).get("persistent_status", {}) as Dictionary
	).get("runtime_effects", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_poison_runtime_semantics",
		int(poison_effects.get("residual_max_hp_divisor", -1)) == 8,
	)

	var toxic := fire.duplicate(true)
	_set_status(toxic, StatusSystem.BADLY_POISONED, 0, 3)
	var toxic_status: Dictionary = _operational_evidence(toxic).get("persistent_status", {}) as Dictionary
	var toxic_effects: Dictionary = toxic_status.get("runtime_effects", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_toxic_runtime_semantics",
		int(toxic_status.get("toxic_counter", -1)) == 3
		and int(toxic_effects.get("residual_max_hp_divisor", -1)) == 16,
	)

	var sleep := fire.duplicate(true)
	_set_status(sleep, StatusSystem.SLEEP, 2, 0)
	var sleep_status: Dictionary = _operational_evidence(sleep).get("persistent_status", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_sleep_duration_recorded",
		int(sleep_status.get("turns_remaining", -1)) == 2,
	)

	var freeze := fire.duplicate(true)
	_set_status(freeze, StatusSystem.FREEZE, 0, 0)
	var freeze_effects: Dictionary = (
		_operational_evidence(freeze).get("persistent_status", {}) as Dictionary
	).get("runtime_effects", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_freeze_runtime_semantics",
		int(freeze_effects.get("thaw_chance_bp", -1)) == 2000,
	)

	var consumed := fire.duplicate(true)
	consumed["held_item_consumed"] = true
	var consumed_item: Dictionary = _operational_evidence(consumed).get("held_item", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_consumed_item_not_available",
		bool(consumed_item.get("consumed", false))
		and not bool(consumed_item.get("available", true)),
	)

	var classification_move: MoveDefinition = _catalog.move(TC_SUPPORT)
	var previous_classification: String = classification_move.classification
	classification_move.classification = "DATA_ONLY"
	var excluded := fire.duplicate(true)
	var excluded_move_ids: Array = excluded.get("move_ids", []) as Array
	excluded_move_ids.append("c3f_unknown_move")
	excluded["move_ids"] = excluded_move_ids
	var excluded_evidence: Dictionary = _operational_evidence(excluded)
	_check.call(
		"roster_operational_evidence_data_only_and_unknown_fail_closed",
		(excluded_evidence.get("excluded_move_ids", []) as Array).has(String(TC_SUPPORT))
		and (excluded_evidence.get("unknown_move_ids", []) as Array).has("c3f_unknown_move")
		and _move_evidence(excluded_evidence, String(TC_SUPPORT)).is_empty()
		and _move_evidence(excluded_evidence, "c3f_unknown_move").is_empty(),
	)
	classification_move.classification = previous_classification

	var invalid_pp := fire.duplicate(true)
	_set_move_pp(invalid_pp, TC_FIRE_PHYS, -1, -1)
	var invalid_pp_move: Dictionary = _move_evidence(
		_operational_evidence(invalid_pp),
		String(TC_FIRE_PHYS),
	)
	_check.call(
		"roster_operational_evidence_invalid_pp_fails_closed",
		not bool(invalid_pp_move.get("pp_state_valid", true))
		and not bool(invalid_pp_move.get("available", true))
		and int(invalid_pp_move.get("pp_ratio_bp", -1)) == 0,
	)

	var important_depleted := fire.duplicate(true)
	_set_move_pp(important_depleted, TC_FIRE_PHYS, 0, 20)
	_set_move_pp(important_depleted, TC_SUPPORT, 20, 20)
	var support_depleted := fire.duplicate(true)
	_set_move_pp(support_depleted, TC_FIRE_PHYS, 20, 20)
	_set_move_pp(support_depleted, TC_SUPPORT, 0, 20)
	var important_evidence: Dictionary = _operational_evidence(important_depleted)
	var support_evidence: Dictionary = _operational_evidence(support_depleted)
	_check.call(
		"roster_operational_evidence_naive_pp_average_collision_demonstrated",
		_naive_runtime_pp_mean_bp(important_evidence) == 5000
		and _naive_runtime_pp_mean_bp(support_evidence) == 5000,
	)
	var important_available: Dictionary = important_evidence.get("available_pp_sensitive_role_max_bp", {}) as Dictionary
	var support_available: Dictionary = support_evidence.get("available_pp_sensitive_role_max_bp", {}) as Dictionary
	_check.call(
		"roster_operational_evidence_route_aware_pp_distinguishes_equal_mean",
		int(important_available.get("physical_attacker", -1))
		< int(support_available.get("physical_attacker", -1))
		and int(important_available.get("support", -1))
		> int(support_available.get("support", -1)),
	)
	_check.call(
		"roster_operational_evidence_pp_route_max_is_monotonic",
		_role_max_subset_is_monotonic(important_evidence)
		and _role_max_subset_is_monotonic(support_evidence),
	)

	var ko := fire.duplicate(true)
	ko["current_hp"] = 0
	var ko_evidence: Dictionary = _operational_evidence(ko)
	_check.call(
		"roster_operational_evidence_knockout_state_recorded_without_scalar",
		bool(ko_evidence.get("is_knocked_out", false))
		and int((ko_evidence.get("hp", {}) as Dictionary).get("hp_ratio_bp", -1)) == 0,
	)

	var repeat: Dictionary = _operational_evidence(fire)
	_check.call("roster_operational_evidence_is_deterministic", repeat == evidence)
	var parsed: Variant = JSON.parse_string(JSON.stringify(evidence))
	_check.call("roster_operational_evidence_is_json_serializable", parsed is Dictionary)
	_check.call(
		"roster_operational_evidence_does_not_freeze_scalar_or_campaign_policy",
		not evidence.has("operational_readiness_bp")
		and not evidence.has("permadeath_loss_cost_bp")
		and not evidence.has("campaign_snapshot")
		and not evidence.has("between_battle_recovery_policy")
		and not evidence.has("replacement_policy")
		and not evidence.has("opponent")
		and not evidence.has("belief")
		and not evidence.has("profile")
		and not evidence.has("rng"),
	)


func _operational_evidence(member_view: Dictionary) -> Dictionary:
	var stats: Dictionary = member_view.get("stats", {}) as Dictionary
	var max_hp: int = maxi(0, int(stats.get("max_hp", 0)))
	var current_hp: int = clampi(int(member_view.get("current_hp", 0)), 0, max_hp) if max_hp > 0 else 0
	var hp_ratio_bp: int = current_hp * 10000 / max_hp if max_hp > 0 else 0
	var slots_by_id: Dictionary = {}
	for raw_slot in member_view.get("moveset", []):
		if not (raw_slot is Dictionary):
			continue
		var slot: Dictionary = raw_slot as Dictionary
		slots_by_id[String(slot.get("move_id", ""))] = slot

	var runtime_move_pp: Array[Dictionary] = []
	var available_runtime_move_ids: Array[String] = []
	var depleted_runtime_move_ids: Array[String] = []
	var excluded_move_ids: Array[String] = []
	var unknown_move_ids: Array[String] = []
	var all_role_max := _empty_pp_sensitive_role_scores()
	var available_role_max := _empty_pp_sensitive_role_scores()

	for raw_move_id in member_view.get("move_ids", []):
		var move_id := StringName(String(raw_move_id))
		var move: MoveDefinition = _catalog.move(move_id) if _catalog != null else null
		if move == null:
			unknown_move_ids.append(String(move_id))
			continue
		if move.classification != RUNTIME_SUPPORTED:
			excluded_move_ids.append(String(move_id))
			continue

		var slot: Dictionary = slots_by_id.get(String(move_id), {}) as Dictionary
		var raw_current_pp: int = int(slot.get("current_pp", -1))
		var raw_max_pp: int = int(slot.get("max_pp", -1))
		var pp_state_valid: bool = raw_max_pp > 0 and raw_current_pp >= 0
		var current_pp: int = clampi(raw_current_pp, 0, raw_max_pp) if pp_state_valid else 0
		var max_pp: int = raw_max_pp if pp_state_valid else 0
		var pp_ratio_bp: int = current_pp * 10000 / max_pp if pp_state_valid and max_pp > 0 else 0
		var available: bool = pp_state_valid and current_pp > 0
		var route_affinity: Dictionary = _pp_sensitive_route_affinity(member_view, move_id)
		_merge_role_max(all_role_max, route_affinity)
		if available:
			available_runtime_move_ids.append(String(move_id))
			_merge_role_max(available_role_max, route_affinity)
		else:
			depleted_runtime_move_ids.append(String(move_id))

		runtime_move_pp.append({
			"move_id": String(move_id),
			"current_pp": current_pp,
			"max_pp": max_pp,
			"pp_ratio_bp": pp_ratio_bp,
			"pp_state_valid": pp_state_valid,
			"available": available,
			"damage_class": move.damage_class,
			"power": move.power,
			"type_id": String(move.type_id),
			"pp_sensitive_role_affinity_bp": route_affinity,
		})

	runtime_move_pp.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("move_id", "")) < String(b.get("move_id", ""))
	)
	available_runtime_move_ids.sort()
	depleted_runtime_move_ids.sort()
	excluded_move_ids.sort()
	unknown_move_ids.sort()

	var held_item_id := String(member_view.get("held_item_id", ""))
	var held_item_consumed := bool(member_view.get("held_item_consumed", false))
	return {
		"model_id": OPERATIONAL_EVIDENCE_MODEL_ID,
		"instance_id": String(member_view.get("instance_id", "")),
		"species_id": String(member_view.get("species_id", "")),
		"is_knocked_out": current_hp <= 0,
		"hp": {
			"current_hp": current_hp,
			"max_hp": max_hp,
			"hp_ratio_bp": hp_ratio_bp,
		},
		"runtime_move_pp": runtime_move_pp,
		"available_runtime_move_ids": available_runtime_move_ids,
		"depleted_runtime_move_ids": depleted_runtime_move_ids,
		"excluded_move_ids": excluded_move_ids,
		"unknown_move_ids": unknown_move_ids,
		"all_pp_sensitive_role_max_bp": all_role_max,
		"available_pp_sensitive_role_max_bp": available_role_max,
		"persistent_status": _persistent_status_evidence(member_view),
		"held_item": {
			"item_id": held_item_id,
			"present": not held_item_id.is_empty(),
			"consumed": held_item_consumed if not held_item_id.is_empty() else false,
			"available": not held_item_id.is_empty() and not held_item_consumed,
		},
		"excluded_transient_fields": ["stat_stages", "status_state.volatile"],
	}


func _persistent_status_evidence(member_view: Dictionary) -> Dictionary:
	var state: Dictionary = member_view.get("status_state", {}) as Dictionary
	var status_id := StringName(String(state.get("persistent_id", "")))
	var turns_remaining := maxi(0, int(state.get("turns_remaining", 0)))
	var toxic_counter := maxi(0, int(state.get("toxic_counter", 0)))
	var recognized := true
	var runtime_effects: Dictionary = {}
	match status_id:
		&"":
			pass
		StatusSystem.BURN:
			runtime_effects = {
				"physical_damage_multiplier_bp": _operational_ruleset.burn_physical_multiplier_basis_points,
				"residual_max_hp_divisor": _operational_ruleset.burn_max_hp_divisor,
			}
		StatusSystem.PARALYSIS:
			runtime_effects = {
				"speed_multiplier_bp": _operational_ruleset.paralysis_speed_multiplier_basis_points,
				"action_skip_chance_bp": _operational_ruleset.paralysis_skip_chance_basis_points,
			}
		StatusSystem.POISON:
			runtime_effects = {
				"residual_max_hp_divisor": _operational_ruleset.poison_max_hp_divisor,
			}
		StatusSystem.BADLY_POISONED:
			runtime_effects = {
				"residual_max_hp_divisor": _operational_ruleset.badly_poisoned_max_hp_divisor,
			}
		StatusSystem.SLEEP:
			runtime_effects = {
				"turns_remaining": turns_remaining,
			}
		StatusSystem.FREEZE:
			runtime_effects = {
				"thaw_chance_bp": _operational_ruleset.freeze_thaw_chance_basis_points,
			}
		_:
			recognized = false
	return {
		"status_id": String(status_id),
		"recognized": recognized,
		"turns_remaining": turns_remaining,
		"toxic_counter": toxic_counter,
		"runtime_effects": runtime_effects,
	}


func _pp_sensitive_route_affinity(member_view: Dictionary, move_id: StringName) -> Dictionary:
	var route_view: Dictionary = member_view.duplicate(true)
	route_view["move_ids"] = [String(move_id)]
	var inferred: Dictionary = _operational_role_inference.infer_role_scores(route_view, _catalog)
	var role_scores: Dictionary = inferred.get("role_scores_bp", {}) as Dictionary
	var out := _empty_pp_sensitive_role_scores()
	for role_id in PP_SENSITIVE_ROLE_IDS:
		out[role_id] = clampi(int(role_scores.get(role_id, 0)), 0, 10000)
	return out


func _empty_pp_sensitive_role_scores() -> Dictionary:
	var out: Dictionary = {}
	for role_id in PP_SENSITIVE_ROLE_IDS:
		out[role_id] = 0
	return out


func _merge_role_max(target: Dictionary, source: Dictionary) -> void:
	for role_id in PP_SENSITIVE_ROLE_IDS:
		target[role_id] = maxi(int(target.get(role_id, 0)), int(source.get(role_id, 0)))


func _role_max_subset_is_monotonic(evidence: Dictionary) -> bool:
	var all_scores: Dictionary = evidence.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
	var available_scores: Dictionary = evidence.get("available_pp_sensitive_role_max_bp", {}) as Dictionary
	for role_id in PP_SENSITIVE_ROLE_IDS:
		if int(available_scores.get(role_id, 0)) > int(all_scores.get(role_id, 0)):
			return false
	return true


func _move_evidence(evidence: Dictionary, move_id: String) -> Dictionary:
	for raw_move in evidence.get("runtime_move_pp", []):
		if not (raw_move is Dictionary):
			continue
		var move: Dictionary = raw_move as Dictionary
		if String(move.get("move_id", "")) == move_id:
			return move
	return {}


func _naive_runtime_pp_mean_bp(evidence: Dictionary) -> int:
	var total := 0
	var count := 0
	for raw_move in evidence.get("runtime_move_pp", []):
		if not (raw_move is Dictionary):
			continue
		var move: Dictionary = raw_move as Dictionary
		if not bool(move.get("pp_state_valid", false)):
			continue
		total += int(move.get("pp_ratio_bp", 0))
		count += 1
	return total / count if count > 0 else 0


func _set_move_pp(member_view: Dictionary, move_id: StringName, current_pp: int, max_pp: int) -> void:
	var moveset: Array = member_view.get("moveset", []) as Array
	for i in moveset.size():
		if not (moveset[i] is Dictionary):
			continue
		var slot: Dictionary = moveset[i] as Dictionary
		if StringName(String(slot.get("move_id", ""))) != move_id:
			continue
		slot["current_pp"] = current_pp
		slot["max_pp"] = max_pp
		moveset[i] = slot
	member_view["moveset"] = moveset


func _set_status(member_view: Dictionary, status_id: StringName, turns_remaining: int, toxic_counter: int) -> void:
	var state: Dictionary = member_view.get("status_state", {}) as Dictionary
	state["persistent_id"] = String(status_id)
	state["turns_remaining"] = turns_remaining
	state["toxic_counter"] = toxic_counter
	state["volatile"] = {}
	member_view["status_state"] = state
