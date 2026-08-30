class_name TrainerDecisionTrace
extends RefCounted

const SCHEMA_VERSION := 1

var battle_id: StringName = &""
var turn: int = 0
var brain_id: StringName = &""
var profile_id: StringName = &""
var candidates: Array[Dictionary] = []
var selected_action: Dictionary = {}
var selected_reason: String = ""
var metadata: Dictionary = {}


func add_candidate(
	action: BattleAction,
	source_id: StringName,
	score: int,
	confidence_basis_points: int = 0,
	reasons: Array[String] = [],
	p_metadata: Dictionary = {},
) -> void:
	if action == null:
		return
	candidates.append({
		"action": action.to_dict(),
		"source_id": String(source_id),
		"score": score,
		"confidence_basis_points": clampi(confidence_basis_points, 0, 10000),
		"reasons": reasons.duplicate(),
		"metadata": p_metadata.duplicate(true),
	})


func select(action: BattleAction, reason: String = "") -> void:
	selected_action = action.to_dict().duplicate(true) if action != null else {}
	selected_reason = reason


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"battle_id": String(battle_id),
		"turn": turn,
		"brain_id": String(brain_id),
		"profile_id": String(profile_id),
		"candidates": candidates.duplicate(true),
		"selected_action": selected_action.duplicate(true),
		"selected_reason": selected_reason,
		"metadata": metadata.duplicate(true),
	}
