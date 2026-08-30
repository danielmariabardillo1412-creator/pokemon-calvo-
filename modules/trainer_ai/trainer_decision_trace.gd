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
		var action_data := candidate_data.get("action", {}) as Dictionary
		var canonical_action := {}
		if not action_data.is_empty():
			canonical_action = BattleAction.from_dict(action_data).to_dict()
		trace.candidates.append({
			"action": canonical_action,
			"source_id": String(candidate_data.get("source_id", "")),
			"score": int(candidate_data.get("score", 0)),
			"confidence_basis_points": clampi(
				int(candidate_data.get("confidence_basis_points", 0)),
				0,
				10000,
			),
			"reasons": _canonical_json_value(candidate_data.get("reasons", [])),
			"metadata": _canonical_json_value(candidate_data.get("metadata", {})),
		})
	var selected_data := data.get("selected_action", {}) as Dictionary
	trace.selected_action = (
		BattleAction.from_dict(selected_data).to_dict()
		if not selected_data.is_empty()
		else {}
	)
	trace.selected_reason = String(data.get("selected_reason", ""))
	trace.metadata = _canonical_json_value(data.get("metadata", {})) as Dictionary
	return trace


static func _canonical_json_value(value):
	if value is Dictionary:
		var out_dict: Dictionary = {}
		for key in value.keys():
			out_dict[key] = _canonical_json_value(value[key])
		return out_dict
	if value is Array:
		var out_array: Array = []
		for item in value:
			out_array.append(_canonical_json_value(item))
		return out_array
	if value is float and value == floor(value):
		return int(value)
	return value
