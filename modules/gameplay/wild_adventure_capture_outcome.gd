class_name WildAdventureCaptureOutcome
extends RefCounted

var resolution: CaptureResolution = null
var routing: CaptureRoutingResult = null
var session_completed: bool = false
var reason: String = ""


func succeeded() -> bool:
	return (
		resolution != null
		and resolution.result != null
		and resolution.result.status == CaptureResult.SUCCESS
	)


func to_dict() -> Dictionary:
	return {
		"session_completed": session_completed,
		"reason": reason,
		"capture": resolution.to_dict() if resolution != null else {},
		"routed": routing.routed if routing != null else false,
		"stored": routing.stored if routing != null else false,
		"routing_reason": routing.reason if routing != null else "",
	}
