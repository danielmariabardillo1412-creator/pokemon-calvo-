class_name TrainerRosterRoleInference
extends RefCounted

const MODEL_ID := "trainer_roster_role_inference_evidence_v1"
const ROLE_MODEL_ID := "trainer_roster_role_affinity_v1"
const CONTROL_EVIDENCE_MODEL_ID := "trainer_roster_control_evidence_v1"
const RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"


func extract_intrinsic_evidence(
	member_view: Dictionary,
	catalog: DefinitionCatalog,
) -> Dictionary:
	var stats: Dictionary = member_view.get("stats", {}) as Dictionary
	var max_hp: int = maxi(0, int(stats.get("max_hp", 0)))
	var attack: int = maxi(0, int(stats.get("attack", 0)))
	var defense: int = maxi(0, int(stats.get("defense", 0)))
	var speed: int = maxi(0, int(stats.get("speed", 0)))
	var special_attack: int = maxi(0, int(stats.get("special_attack", 0)))
	var special_defense: int = maxi(0, int(stats.get("special_defense", 0)))

	var physical_power_sum: int = 0
	var special_power_sum: int = 0
	var max_priority: int = 0
	var control_signal_bp: int = 0
	var setup_signal_bp: int = 0
	var sustain_signal_bp: int = 0
	var control_best_runtime_effect_bp: int = 0
	var control_reliability_bp: int = 0
	var control_secondary_reliability_bp: int = 0
	var control_move_count: int = 0
	var control_dedicated_move_count: int = 0
	var control_damaging_move_count: int = 0
	var control_strongest_stat_drop_stages: int = 0
	var control_effect_keys_seen: Dictionary = {}
	var control_effect_families_seen: Dictionary = {}
	var control_breakdown: Array[Dictionary] = []
	var runtime_move_ids: Array[String] = []
	var excluded_move_ids: Array[String] = []
	var unknown_move_ids: Array[String] = []

	var move_ids: Array = member_view.get("move_ids", []) as Array
	for raw_move_id in move_ids:
		var move_id := StringName(String(raw_move_id))
		var move: MoveDefinition = catalog.move(move_id) if catalog != null else null
		if move == null:
			unknown_move_ids.append(String(move_id))
			continue
		if move.classification != RUNTIME_SUPPORTED:
			excluded_move_ids.append(String(move_id))
			continue

		runtime_move_ids.append(String(move_id))
		max_priority = maxi(max_priority, move.priority)
		if move.damage_class == "physical":
			physical_power_sum += maxi(0, move.power)
		elif move.damage_class == "special":
			special_power_sum += maxi(0, move.power)

		for spec in move.effect_specs:
			var signals: Dictionary = _effect_signals(spec, 10000)
			control_signal_bp = maxi(control_signal_bp, int(signals.get("control", 0)))
			setup_signal_bp = maxi(setup_signal_bp, int(signals.get("setup", 0)))
			sustain_signal_bp = maxi(sustain_signal_bp, int(signals.get("sustain", 0)))

		var control_report: Dictionary = _control_move_evidence(move)
		var move_runtime_control_bp: int = int(control_report.get("best_runtime_effect_bp", 0))
		if move_runtime_control_bp <= 0:
			continue
		control_move_count += 1
		control_best_runtime_effect_bp = maxi(control_best_runtime_effect_bp, move_runtime_control_bp)
		var move_reliability_bp: int = int(control_report.get("best_attempt_reliability_bp", 0))
		if move_reliability_bp > control_reliability_bp:
			control_secondary_reliability_bp = control_reliability_bp
			control_reliability_bp = move_reliability_bp
		elif move_reliability_bp > control_secondary_reliability_bp:
			control_secondary_reliability_bp = move_reliability_bp
		if bool(control_report.get("dedicated_control", false)):
			control_dedicated_move_count += 1
		if bool(control_report.get("damaging_control", false)):
			control_damaging_move_count += 1
		control_strongest_stat_drop_stages = maxi(
			control_strongest_stat_drop_stages,
			int(control_report.get("strongest_stat_drop_stages", 0)),
		)
		var report_effect_keys: Array = control_report.get("effect_keys", []) as Array
		for raw_effect_key in report_effect_keys:
			control_effect_keys_seen[String(raw_effect_key)] = true
		var report_effect_families: Array = control_report.get("effect_families", []) as Array
		for raw_effect_family in report_effect_families:
			control_effect_families_seen[String(raw_effect_family)] = true
		control_breakdown.append(control_report)

	control_breakdown.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("move_id", "")) < String(b.get("move_id", ""))
	)

	return {
		"model_id": MODEL_ID,
		"control_evidence_model_id": CONTROL_EVIDENCE_MODEL_ID,
		"instance_id": String(member_view.get("instance_id", "")),
		"stats": {
			"max_hp": max_hp,
			"attack": attack,
			"defense": defense,
			"speed": speed,
			"special_attack": special_attack,
			"special_defense": special_defense,
		},
		"move_features": {
			"physical_power_sum": physical_power_sum,
			"special_power_sum": special_power_sum,
			"max_priority": max_priority,
			"runtime_supported_count": runtime_move_ids.size(),
			"excluded_count": excluded_move_ids.size(),
			"unknown_count": unknown_move_ids.size(),
		},
		"capability_evidence": {
			"physical_damage_signal": attack * physical_power_sum,
			"special_damage_signal": special_attack * special_power_sum,
			"speed_stat": speed,
			"physical_bulk_signal": max_hp * defense,
			"special_bulk_signal": max_hp * special_defense,
			"priority": max_priority,
			"control_signal_bp": control_signal_bp,
			"control_best_runtime_effect_bp": control_best_runtime_effect_bp,
			"control_reliability_bp": control_reliability_bp,
			"control_secondary_reliability_bp": control_secondary_reliability_bp,
			"control_move_count": control_move_count,
			"control_effect_key_count": control_effect_keys_seen.size(),
			"control_effect_family_count": control_effect_families_seen.size(),
			"control_dedicated_move_count": control_dedicated_move_count,
			"control_damaging_move_count": control_damaging_move_count,
			"control_strongest_stat_drop_stages": control_strongest_stat_drop_stages,
			"setup_signal_bp": setup_signal_bp,
			"sustain_signal_bp": sustain_signal_bp,
		},
		"control_breakdown": control_breakdown,
		"runtime_move_ids": runtime_move_ids,
		"excluded_move_ids": excluded_move_ids,
		"unknown_move_ids": unknown_move_ids,
	}


func infer_role_scores(
	member_view: Dictionary,
	catalog: DefinitionCatalog,
) -> Dictionary:
	var evidence: Dictionary = extract_intrinsic_evidence(member_view, catalog)
	var stats: Dictionary = evidence.get("stats", {}) as Dictionary
	var capabilities: Dictionary = evidence.get("capability_evidence", {}) as Dictionary

	var stat_ceiling: int = _non_hp_stat_ceiling(stats)
	var attack_focus_bp: int = _ratio_bp(int(stats.get("attack", 0)), stat_ceiling)
	var defense_focus_bp: int = _ratio_bp(int(stats.get("defense", 0)), stat_ceiling)
	var speed_focus_bp: int = _ratio_bp(int(stats.get("speed", 0)), stat_ceiling)
	var special_attack_focus_bp: int = _ratio_bp(int(stats.get("special_attack", 0)), stat_ceiling)
	var special_defense_focus_bp: int = _ratio_bp(int(stats.get("special_defense", 0)), stat_ceiling)

	var physical_damage: int = maxi(0, int(capabilities.get("physical_damage_signal", 0)))
	var special_damage: int = maxi(0, int(capabilities.get("special_damage_signal", 0)))
	var damage_ceiling: int = maxi(physical_damage, special_damage)
	var physical_route_bp: int = _ratio_bp(physical_damage, damage_ceiling) if damage_ceiling > 0 else 0
	var special_route_bp: int = _ratio_bp(special_damage, damage_ceiling) if damage_ceiling > 0 else 0

	var physical_attacker_bp: int = mini(attack_focus_bp, physical_route_bp)
	var special_attacker_bp: int = mini(special_attack_focus_bp, special_route_bp)
	var offensive_affinity_bp: int = maxi(physical_attacker_bp, special_attacker_bp)
	var fast_attacker_bp: int = mini(speed_focus_bp, offensive_affinity_bp) if damage_ceiling > 0 else 0
	var support_bp: int = maxi(
		clampi(int(capabilities.get("control_signal_bp", 0)), 0, 10000),
		clampi(int(capabilities.get("sustain_signal_bp", 0)), 0, 10000),
	)

	return {
		"model_id": ROLE_MODEL_ID,
		"instance_id": String(evidence.get("instance_id", "")),
		"role_scores_bp": {
			"physical_attacker": physical_attacker_bp,
			"special_attacker": special_attacker_bp,
			"fast_attacker": fast_attacker_bp,
			"bulky_physical": defense_focus_bp,
			"bulky_special": special_defense_focus_bp,
			"support": support_bp,
		},
		"normalization": {
			"stat_ceiling": stat_ceiling,
			"damage_route_ceiling": damage_ceiling,
			"attack_focus_bp": attack_focus_bp,
			"special_attack_focus_bp": special_attack_focus_bp,
			"speed_focus_bp": speed_focus_bp,
			"defense_focus_bp": defense_focus_bp,
			"special_defense_focus_bp": special_defense_focus_bp,
			"physical_route_bp": physical_route_bp,
			"special_route_bp": special_route_bp,
			"offensive_affinity_bp": offensive_affinity_bp,
			"setup_signal_bp": clampi(int(capabilities.get("setup_signal_bp", 0)), 0, 10000),
			"priority": int(capabilities.get("priority", 0)),
		},
		"intrinsic_evidence": evidence,
	}


func _non_hp_stat_ceiling(stats: Dictionary) -> int:
	var ceiling: int = 1
	for key in ["attack", "defense", "speed", "special_attack", "special_defense"]:
		ceiling = maxi(ceiling, maxi(0, int(stats.get(key, 0))))
	return ceiling


func _ratio_bp(value: int, ceiling: int) -> int:
	if value <= 0 or ceiling <= 0:
		return 0
	return clampi(value * 10000 / ceiling, 0, 10000)


func _control_move_evidence(move: MoveDefinition) -> Dictionary:
	var state: Dictionary = {
		"best_runtime_effect_bp": 0,
		"route_count": 0,
		"effect_keys": {},
		"effect_families": {},
		"strongest_stat_drop_stages": 0,
	}
	for spec in move.effect_specs:
		_accumulate_control_shape(spec, 10000, state)

	var effect_keys_dict: Dictionary = state.get("effect_keys", {}) as Dictionary
	var effect_keys: Array[String] = []
	for raw_key in effect_keys_dict.keys():
		effect_keys.append(String(raw_key))
	effect_keys.sort()

	var effect_families_dict: Dictionary = state.get("effect_families", {}) as Dictionary
	var effect_families: Array[String] = []
	for raw_family in effect_families_dict.keys():
		effect_families.append(String(raw_family))
	effect_families.sort()

	var best_runtime_effect_bp: int = int(state.get("best_runtime_effect_bp", 0))
	var accuracy_bp: int = _move_accuracy_bp(move)
	return {
		"move_id": String(move.id),
		"accuracy_bp": accuracy_bp,
		"best_runtime_effect_bp": best_runtime_effect_bp,
		"best_attempt_reliability_bp": best_runtime_effect_bp * accuracy_bp / 10000,
		"route_count": int(state.get("route_count", 0)),
		"effect_keys": effect_keys,
		"effect_families": effect_families,
		"strongest_stat_drop_stages": int(state.get("strongest_stat_drop_stages", 0)),
		"dedicated_control": best_runtime_effect_bp > 0 and move.power <= 0,
		"damaging_control": best_runtime_effect_bp > 0 and move.power > 0,
	}


func _accumulate_control_shape(
	spec: BattleEffectSpec,
	inherited_runtime_bp: int,
	state: Dictionary,
) -> void:
	if spec == null:
		return
	var effective_runtime_bp: int = inherited_runtime_bp
	if spec.kind == BattleEffectSpec.CHANCE:
		effective_runtime_bp = inherited_runtime_bp * clampi(spec.chance_basis_points, 0, 10000) / 10000

	if _is_control_leaf(spec):
		state["route_count"] = int(state.get("route_count", 0)) + 1
		state["best_runtime_effect_bp"] = maxi(
			int(state.get("best_runtime_effect_bp", 0)),
			effective_runtime_bp,
		)
		var effect_keys: Dictionary = state.get("effect_keys", {}) as Dictionary
		var effect_families: Dictionary = state.get("effect_families", {}) as Dictionary
		if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
			effect_keys["stat:%s" % String(spec.stat_key)] = true
			effect_families["stat_debuff"] = true
			state["strongest_stat_drop_stages"] = maxi(
				int(state.get("strongest_stat_drop_stages", 0)),
				absi(spec.value),
			)
		elif spec.kind == BattleEffectSpec.INFLICT_STATUS:
			effect_keys["status:%s" % String(spec.status_id)] = true
			effect_families["status"] = true
		elif spec.kind == BattleEffectSpec.FLINCH:
			effect_keys["flinch"] = true
			effect_families["flinch"] = true

	for child in spec.children:
		_accumulate_control_shape(child, effective_runtime_bp, state)


func _is_control_leaf(spec: BattleEffectSpec) -> bool:
	if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
		return spec.target == BattleEffectSpec.OPPONENT and spec.value < 0
	if spec.kind == BattleEffectSpec.INFLICT_STATUS:
		return spec.target == BattleEffectSpec.OPPONENT
	if spec.kind == BattleEffectSpec.FLINCH:
		return spec.target == BattleEffectSpec.OPPONENT
	return false


func _move_accuracy_bp(move: MoveDefinition) -> int:
	if move.accuracy < 0:
		return 10000
	return clampi(move.accuracy * 100, 0, 10000)


func _effect_signals(spec: BattleEffectSpec, inherited_chance_bp: int) -> Dictionary:
	if spec == null:
		return {"control": 0, "setup": 0, "sustain": 0}
	var own_chance_bp: int = clampi(spec.chance_basis_points, 0, 10000)
	var effective_chance_bp: int = inherited_chance_bp * own_chance_bp / 10000
	var control: int = 0
	var setup: int = 0
	var sustain: int = 0

	if spec.kind == BattleEffectSpec.MODIFY_STAT_STAGE:
		if spec.target == BattleEffectSpec.OPPONENT and spec.value < 0:
			control = effective_chance_bp
		elif spec.target == BattleEffectSpec.SELF and spec.value > 0:
			setup = effective_chance_bp
	elif spec.kind == BattleEffectSpec.INFLICT_STATUS and spec.target == BattleEffectSpec.OPPONENT:
		control = effective_chance_bp
	elif spec.kind == BattleEffectSpec.FLINCH and spec.target == BattleEffectSpec.OPPONENT:
		control = effective_chance_bp
	elif spec.kind == BattleEffectSpec.HEAL and spec.target == BattleEffectSpec.SELF:
		if spec.ratio_basis_points > 0:
			sustain = mini(10000, spec.ratio_basis_points) * effective_chance_bp / 10000
		elif spec.value > 0:
			sustain = effective_chance_bp
	elif spec.kind == BattleEffectSpec.CURE_STATUS and spec.target == BattleEffectSpec.SELF:
		sustain = effective_chance_bp
	elif spec.kind == BattleEffectSpec.DRAIN:
		var drain_bp: int = spec.ratio_basis_points if spec.ratio_basis_points > 0 else effective_chance_bp
		sustain = mini(10000, drain_bp) * effective_chance_bp / 10000

	if spec.kind == BattleEffectSpec.CHANCE or not spec.children.is_empty():
		for child in spec.children:
			var child_signals: Dictionary = _effect_signals(child, effective_chance_bp)
			control = maxi(control, int(child_signals.get("control", 0)))
			setup = maxi(setup, int(child_signals.get("setup", 0)))
			sustain = maxi(sustain, int(child_signals.get("sustain", 0)))

	return {
		"control": control,
		"setup": setup,
		"sustain": sustain,
	}
