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


static func from_dict(data: Dictionary) -> TrainerDecisionTrace:
	assert(
		int(data.get("schema_version", -1)) == SCHEMA_VERSION,
		"Unsupported trainer decision trace schema",
	)
	var trace := TrainerDecisionTrace.new()
	trace.battle_id = StringName(data.get("battle_id", ""))
	trace.turn = maxi(0, int(data.get("turn", 0)))
	trace.brain_id = StringName(data.get("brain_id", ""))
	trace.profile_id = StringName(data.get("profile_id", ""))
	for raw_candidate in data.get("candidates", []):
		var candidate_data := raw_candidate as Dictionary
		trace.candidates.append({
			"action": (candidate_data.get("action", {}) as Dictionary).duplicate(true),
			"source_id": String(candidate_data.get("source_id", "")),
			"score": int(candidate_data.get("score", 0)),
			"confidence_basis_points": clampi(
				int(candidate_data.get("confidence_basis_points", 0)),
				0,
				10000,
			),
			"reasons": (candidate_data.get("reasons", []) as Array).duplicate(),
			"metadata": (candidate_data.get("metadata", {}) as Dictionary).duplicate(true),
		})
	trace.selected_action = (
		(data.get("selected_action", {}) as Dictionary).duplicate(true)
	)
	trace.selected_reason = String(data.get("selected_reason", ""))
	trace.metadata = (data.get("metadata", {}) as Dictionary).duplicate(true)
	return trace
