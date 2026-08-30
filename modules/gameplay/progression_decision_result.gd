class_name ProgressionDecisionResult
extends RefCounted

var ok: bool = false
var reason: String = ""
var decision_kind: String = ""
var creature_id: StringName = &""
var intent: String = ""
var new_move_id: StringName = &""
var replaced_move_id: StringName = &""
var remaining: int = 0


func to_dict() -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"decision_kind": decision_kind,
		"creature_id": String(creature_id),
		"intent": intent,
		"new_move_id": String(new_move_id),
		"replaced_move_id": String(replaced_move_id),
		"remaining": remaining,
	}