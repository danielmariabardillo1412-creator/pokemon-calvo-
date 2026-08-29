class_name BattleRuleset
extends RefCounted

const ID := &"calvo_v1"
const STAGE_MIN := -6
const STAGE_MAX := 6

var critical_chance_numerator: int = 1
var critical_chance_denominator: int = 24
var critical_multiplier_basis_points: int = 15000
var burn_physical_multiplier_basis_points: int = 5000
var paralysis_speed_multiplier_basis_points: int = 5000
var paralysis_skip_chance_basis_points: int = 2500
var sleep_min_turns: int = 1
var sleep_max_turns: int = 3
var freeze_thaw_chance_basis_points: int = 2000
var poison_max_hp_divisor: int = 8
var burn_max_hp_divisor: int = 16
var badly_poisoned_max_hp_divisor: int = 16
var switch_priority: int = 6


func stat_multiplier_basis_points(stage: int) -> int:
	var value := clampi(stage, STAGE_MIN, STAGE_MAX)
	if value >= 0:
		return ((2 + value) * 10000) / 2
	return (2 * 10000) / (2 - value)


func accuracy_multiplier_basis_points(stage: int) -> int:
	var value := clampi(stage, STAGE_MIN, STAGE_MAX)
	if value >= 0:
		return ((3 + value) * 10000) / 3
	return (3 * 10000) / (3 - value)


func accuracy_threshold_basis_points(base_accuracy: int, accuracy_stage: int, evasion_stage: int) -> int:
	if base_accuracy < 0:
		return 10000
	var combined_stage := clampi(accuracy_stage - evasion_stage, STAGE_MIN, STAGE_MAX)
	return clampi(base_accuracy * accuracy_multiplier_basis_points(combined_stage) / 100, 0, 10000)


func critical_threshold_basis_points() -> int:
	return critical_chance_numerator * 10000 / critical_chance_denominator


func status_immunity_types(status_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	match status_id:
		&"burn":
			result.append(&"fire")
		&"poison", &"badly_poisoned":
			result.append(&"poison")
			result.append(&"steel")
		&"paralysis":
			result.append(&"electric")
	return result
