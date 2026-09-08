class_name TrainerRosterOperationalReadinessEvaluator
extends RefCounted

# C3f-d productionizes only the decomposed current-state evidence certified by
# C3f-a/b/c. It deliberately does not choose an aggregate readiness scalar or
# introduce recovery/replacement/campaign policy.

const MODEL_ID := "trainer_roster_current_operational_components_v1"
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const PP_SENSITIVE_ROLE_IDS: Array[String] = [
	"physical_attacker",
	"special_attacker",
	"fast_attacker",
	"support",
]
const EXCLUDED_TRANSIENT_FIELDS: Array[String] = [
	"stat_stages",
	"status_state.volatile",
]

var _catalog: DefinitionCatalog
var _ruleset: BattleRuleset
var _role_inference := TrainerRosterRoleInference.new()


func _init(catalog: DefinitionCatalog, ruleset: BattleRuleset = null) -> void:
	_catalog = catalog
	_ruleset = ruleset if ruleset != null else BattleRuleset.new()


func evaluate_current_components(own_party: Array) -> Dictionary:
	if _catalog == null:
		return _empty_result()

	var members: Array[Dictionary] = []
	var skipped_invalid_member_indices: Array[int] = []
	for index in range(own_party.size()):
		var raw_member: Variant = own_party[index]
		if not (raw_member is Dictionary):
			skipped_invalid_member_indices.append(index)
			continue
		var member: Dictionary = raw_member as Dictionary
		var instance_id := String(member.get("instance_id", ""))
		var species_id := StringName(String(member.get("species_id", "")))
		if instance_id.is_empty() or species_id == &"" or _catalog.species(species_id) == null:
			skipped_invalid_member_indices.append(index)
			continue
		members.append(_member_components(member))

	return {
		"model_id": MODEL_ID,
		"member_count": members.size(),
		"skipped_invalid_member_indices": skipped_invalid_member_indices,
		"member_components": members,
	}


func _member_components(member_view: Dictionary) -> Dictionary:
	var evidence := _operational_evidence(member_view)
	var hp := evidence.get("hp", {}) as Dictionary
	var hp_state_bp := clampi(int(hp.get("hp_ratio_bp", 0)), 0, 10000)
	var route := _route_retention(evidence)
	var status_action := _immediate_status_action(evidence)
	var attrition := _attrition_evidence(evidence)
	var held_item := evidence.get("held_item", {}) as Dictionary
	return {
		"instance_id": String(evidence.get("instance_id", "")),
		"species_id": String(evidence.get("species_id", "")),
		"is_active": bool(evidence.get("is_active", false)),
		"is_knocked_out": bool(evidence.get("is_knocked_out", false)),
		"hp_state_bp": hp_state_bp,
		"route_retention_bp": int(route.get("route_retention_bp", 0)),
		"immediate_status_action_bp": int(status_action.get("immediate_status_action_bp", 0)),
		"attrition": attrition,
		"held_item_id": String(held_item.get("item_id", "")),
		"held_item_consumed": bool(held_item.get("consumed", false)),
		"held_item": held_item.duplicate(true),
		"breakdown": {
			"hp": hp.duplicate(true),
			"route_retention": route,
			"immediate_status_action": status_action,
		},
		"excluded_transient_fields": EXCLUDED_TRANSIENT_FIELDS.duplicate(),
	}


func _operational_evidence(member_view: Dictionary) -> Dictionary:
	var stats: Dictionary = member_view.get("stats", {}) as Dictionary
	var max_hp: int = maxi(0, int(stats.get("max_hp", 0)))
	var current_hp: int = (
		clampi(int(member_view.get("current_hp", 0)), 0, max_hp)
		if max_hp > 0
		else 0
	)
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
		var move: MoveDefinition = _catalog.move(move_id)
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
		var pp_ratio_bp: int = (
			current_pp * 10000 / max_pp
			if pp_state_valid and max_pp > 0
			else 0
		)
		var available: bool = pp_state_valid and current_pp > 0
		var route_affinity := _pp_sensitive_route_affinity(member_view, move_id)
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
		"instance_id": String(member_view.get("instance_id", "")),
		"species_id": String(member_view.get("species_id", "")),
		"is_active": bool(member_view.get("is_active", false)),
		"is_knocked_out": current_hp <= 0 or bool(member_view.get("is_knocked_out", false)),
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
	}


func _route_retention(evidence: Dictionary) -> Dictionary:
	var all_scores := evidence.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
	var available_scores := evidence.get("available_pp_sensitive_role_max_bp", {}) as Dictionary
	var total_all := 0
	var total_available := 0
	for role_id in PP_SENSITIVE_ROLE_IDS:
		var all_score := clampi(int(all_scores.get(role_id, 0)), 0, 10000)
		var available_score := clampi(int(available_scores.get(role_id, 0)), 0, all_score)
		total_all += all_score
		total_available += available_score
	var route_retention_bp := 10000
	if total_all > 0:
		route_retention_bp = clampi(total_available * 10000 / total_all, 0, 10000)
	return {
		"route_retention_bp": route_retention_bp,
		"role_capacity_total_bp_sum": total_all,
		"role_capacity_available_bp_sum": total_available,
		"all_pp_sensitive_role_max_bp": all_scores.duplicate(true),
		"available_pp_sensitive_role_max_bp": available_scores.duplicate(true),
		"runtime_move_pp": (evidence.get("runtime_move_pp", []) as Array).duplicate(true),
		"available_runtime_move_ids": (evidence.get("available_runtime_move_ids", []) as Array).duplicate(),
		"depleted_runtime_move_ids": (evidence.get("depleted_runtime_move_ids", []) as Array).duplicate(),
		"excluded_move_ids": (evidence.get("excluded_move_ids", []) as Array).duplicate(),
		"unknown_move_ids": (evidence.get("unknown_move_ids", []) as Array).duplicate(),
	}


func _immediate_status_action(evidence: Dictionary) -> Dictionary:
	var status := evidence.get("persistent_status", {}) as Dictionary
	var status_id := StringName(String(status.get("status_id", "")))
	var recognized := bool(status.get("recognized", false))
	var effects := status.get("runtime_effects", {}) as Dictionary
	var all_scores := evidence.get("all_pp_sensitive_role_max_bp", {}) as Dictionary
	var factor := 10000
	var rule_id := "none"
	var dependencies: Dictionary = {}

	match status_id:
		&"":
			pass
		StatusSystem.BURN:
			rule_id = "burn_physical_dependency_v1"
			var physical := clampi(int(all_scores.get("physical_attacker", 0)), 0, 10000)
			var special := clampi(int(all_scores.get("special_attacker", 0)), 0, 10000)
			var dependency_den := maxi(1, maxi(physical, special))
			var physical_dependency_bp := physical * 10000 / dependency_den if physical > 0 else 0
			var physical_multiplier_bp := clampi(
				int(effects.get("physical_damage_multiplier_bp", 10000)),
				0,
				10000,
			)
			var penalty_if_pure_physical_bp := 10000 - physical_multiplier_bp
			factor = clampi(
				10000 - penalty_if_pure_physical_bp * physical_dependency_bp / 10000,
				0,
				10000,
			)
			dependencies = {
				"physical_attacker_bp": physical,
				"special_attacker_bp": special,
				"physical_dependency_bp": physical_dependency_bp,
				"physical_damage_multiplier_bp": physical_multiplier_bp,
				"penalty_if_pure_physical_bp": penalty_if_pure_physical_bp,
			}
		StatusSystem.PARALYSIS:
			rule_id = "paralysis_action_and_speed_dependency_v1"
			var skip_chance_bp := clampi(int(effects.get("action_skip_chance_bp", 0)), 0, 10000)
			var action_availability_bp := 10000 - skip_chance_bp
			var max_role := 0
			for role_id in PP_SENSITIVE_ROLE_IDS:
				max_role = maxi(max_role, int(all_scores.get(role_id, 0)))
			var fast_score := clampi(int(all_scores.get("fast_attacker", 0)), 0, 10000)
			var fast_dependency_bp := fast_score * 10000 / maxi(1, max_role) if fast_score > 0 else 0
			var speed_multiplier_bp := clampi(int(effects.get("speed_multiplier_bp", 10000)), 0, 10000)
			var speed_factor_bp := 10000 - (10000 - speed_multiplier_bp) * fast_dependency_bp / 10000
			factor = clampi(action_availability_bp * speed_factor_bp / 10000, 0, 10000)
			dependencies = {
				"action_skip_chance_bp": skip_chance_bp,
				"action_availability_bp": action_availability_bp,
				"fast_attacker_bp": fast_score,
				"max_pp_sensitive_role_bp": max_role,
				"fast_dependency_bp": fast_dependency_bp,
				"speed_multiplier_bp": speed_multiplier_bp,
				"speed_factor_bp": speed_factor_bp,
			}
		StatusSystem.SLEEP:
			rule_id = "sleep_current_action_v1"
			var turns_remaining := maxi(0, int(status.get("turns_remaining", 0)))
			factor = 0 if turns_remaining > 0 else 10000
			dependencies = {"turns_remaining": turns_remaining}
		StatusSystem.FREEZE:
			rule_id = "freeze_thaw_current_action_v1"
			var thaw_chance_bp := clampi(int(effects.get("thaw_chance_bp", 0)), 0, 10000)
			factor = thaw_chance_bp
			dependencies = {"thaw_chance_bp": thaw_chance_bp}
		StatusSystem.POISON, StatusSystem.BADLY_POISONED:
			rule_id = "attrition_only_no_immediate_action_penalty_v1"
			factor = 10000
		_:
			rule_id = "unrecognized_no_certified_immediate_modifier_v1"
			factor = 10000

	return {
		"immediate_status_action_bp": factor,
		"status_id": String(status_id),
		"recognized": recognized,
		"rule_id": rule_id,
		"runtime_effects": effects.duplicate(true),
		"dependencies": dependencies,
	}


func _attrition_evidence(evidence: Dictionary) -> Dictionary:
	var status := evidence.get("persistent_status", {}) as Dictionary
	var status_id := StringName(String(status.get("status_id", "")))
	var recognized := bool(status.get("recognized", false))
	var effects := status.get("runtime_effects", {}) as Dictionary
	var hp := evidence.get("hp", {}) as Dictionary
	var max_hp := maxi(0, int(hp.get("max_hp", 0)))
	var current_hp := clampi(int(hp.get("current_hp", 0)), 0, max_hp) if max_hp > 0 else 0
	var divisor := maxi(0, int(effects.get("residual_max_hp_divisor", 0)))
	var toxic_counter_before := maxi(0, int(status.get("toxic_counter", 0)))
	var toxic_counter_for_next_tick := toxic_counter_before
	var formula_defined := false
	var loss_max_hp_bp := 0
	var raw_damage_hp := 0

	match status_id:
		StatusSystem.BADLY_POISONED:
			if divisor > 0:
				formula_defined = true
				toxic_counter_for_next_tick = maxi(1, toxic_counter_before + 1)
				loss_max_hp_bp = clampi(toxic_counter_for_next_tick * 10000 / divisor, 0, 10000)
				if max_hp > 0:
					raw_damage_hp = maxi(1, max_hp * toxic_counter_for_next_tick / divisor)
		StatusSystem.BURN, StatusSystem.POISON:
			if divisor > 0:
				formula_defined = true
				loss_max_hp_bp = clampi(10000 / divisor, 0, 10000)
				if max_hp > 0:
					raw_damage_hp = maxi(1, max_hp / divisor)

	var is_active := bool(evidence.get("is_active", false))
	var is_knocked_out := bool(evidence.get("is_knocked_out", false))
	var applies_now := formula_defined and is_active and not is_knocked_out
	var applied_damage_hp := mini(current_hp, raw_damage_hp) if applies_now else 0
	return {
		"status_id": String(status_id),
		"recognized": recognized,
		"active_member_required": true,
		"requires_active_end_turn_assumption": formula_defined,
		"next_active_tick_formula_defined": formula_defined,
		"next_active_tick_applies_now": applies_now,
		"next_active_tick_loss_max_hp_bp": loss_max_hp_bp,
		"next_active_tick_raw_damage_hp": raw_damage_hp,
		"next_active_tick_applied_damage_hp": applied_damage_hp,
		"residual_max_hp_divisor": divisor,
		"toxic_counter_before": toxic_counter_before,
		"toxic_counter_for_next_tick": toxic_counter_for_next_tick,
		"projected_readiness_included": false,
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
				"physical_damage_multiplier_bp": _ruleset.burn_physical_multiplier_basis_points,
				"residual_max_hp_divisor": _ruleset.burn_max_hp_divisor,
			}
		StatusSystem.PARALYSIS:
			runtime_effects = {
				"speed_multiplier_bp": _ruleset.paralysis_speed_multiplier_basis_points,
				"action_skip_chance_bp": _ruleset.paralysis_skip_chance_basis_points,
			}
		StatusSystem.POISON:
			runtime_effects = {
				"residual_max_hp_divisor": _ruleset.poison_max_hp_divisor,
			}
		StatusSystem.BADLY_POISONED:
			runtime_effects = {
				"residual_max_hp_divisor": _ruleset.badly_poisoned_max_hp_divisor,
			}
		StatusSystem.SLEEP:
			runtime_effects = {"turns_remaining": turns_remaining}
		StatusSystem.FREEZE:
			runtime_effects = {"thaw_chance_bp": _ruleset.freeze_thaw_chance_basis_points}
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
	var inferred: Dictionary = _role_inference.infer_role_scores(route_view, _catalog)
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


func _empty_result() -> Dictionary:
	return {
		"model_id": MODEL_ID,
		"member_count": 0,
		"skipped_invalid_member_indices": [],
		"member_components": [],
	}
