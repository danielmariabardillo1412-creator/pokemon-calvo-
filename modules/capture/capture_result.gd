class_name CaptureResult
extends RefCounted

# Semantic, serializable outcome of a single capture attempt.

const SUCCESS := &"SUCCESS"
const FAILED := &"FAILED"
const INVALID := &"INVALID"


var status: StringName = INVALID
var ball_id: StringName = &""
var target_id: StringName = &""
var probability: float = 0.0
var shake_count: int = 0
var consume_item: bool = false
var reason: String = ""


func to_dict() -> Dictionary:
	return {
		"status": String(status),
		"ball_id": String(ball_id),
		"target_id": String(target_id),
		"probability": probability,
		"shake_count": shake_count,
		"consume_item": consume_item,
		"reason": reason,
	}


static func from_dict(d: Dictionary) -> CaptureResult:
	var r := CaptureResult.new()
	r.status = StringName(d.get("status", "INVALID"))
	r.ball_id = StringName(d.get("ball_id", ""))
	r.target_id = StringName(d.get("target_id", ""))
	r.probability = float(d.get("probability", 0.0))
	r.shake_count = int(d.get("shake_count", 0))
	r.consume_item = bool(d.get("consume_item", false))
	r.reason = d.get("reason", "")
	return r
