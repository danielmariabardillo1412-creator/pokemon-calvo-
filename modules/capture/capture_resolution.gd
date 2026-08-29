class_name CaptureResolution
extends RefCounted

# Full server resolution: the result, the (unchanged) captured creature reference, where it
# should go, and the ordered semantic events. The captured creature is the SAME CreatureInstance
# that was the wild target - capture never rerolls IV/EV/nature/ability.

var result: CaptureResult
var captured: CreatureInstance = null
var disposition: StringName = CaptureDisposition.PARTY
var events: Array[CaptureEvent] = []


func to_dict() -> Dictionary:
	var ev: Array[Dictionary] = []
	for e in events:
		if e is CaptureEvent:
			ev.append({"kind": String(e.kind), "data": e.data})
	var captured_dict: Dictionary = {}
	if captured != null:
		captured_dict = captured.to_dict()
	return {
		"result": result.to_dict() if result != null else {},
		"disposition": String(disposition),
		"captured": captured_dict,
		"events": ev,
	}
