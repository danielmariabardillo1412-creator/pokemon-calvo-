class_name TrainerRosterRoleInference
extends RefCounted

const MODEL_ID := "trainer_roster_role_inference_evidence_v1"
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

	return {
		"model_id": MODEL_ID,
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
			"setup_signal_bp": setup_signal_bp,
			"sustain_signal_bp": sustain_signal_bp,
		},
		"runtime_move_ids": runtime_move_ids,
		"excluded_move_ids": excluded_move_ids,
		"unknown_move_ids": unknown_move_ids,
	}


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
