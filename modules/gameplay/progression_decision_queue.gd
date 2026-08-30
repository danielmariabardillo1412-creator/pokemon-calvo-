class_name ProgressionDecisionQueue
extends RefCounted

# Application-layer FIFO for post-battle decisions that MUST be explicitly resolved before the
# wild-adventure session can leave COMPLETED. V1 intentionally queues only move-learning choices.
# Evolution events remain non-blocking until their imported eligibility metadata is audited/fixed.

var _pending: Array[ProgressionEvent] = []


func rebuild_from(events: Array) -> void:
	_pending.clear()
	for raw in events:
		if not (raw is ProgressionEvent):
			continue
		var event := raw as ProgressionEvent
		if event.kind != ProgressionEvent.MOVE_LEARN_CHOICE_REQUIRED:
			continue
		# Never retain the same mutable RefCounted/Dictionary that is returned in WildBattleSettlement.
		# Presentation or another caller may inspect/mutate its copy; the authoritative pending decision
		# must remain detached from that external reference.
		_pending.append(_clone_event(event))


func clear() -> void:
	_pending.clear()


func is_empty() -> bool:
	return _pending.is_empty()


func size() -> int:
	return _pending.size()


# Internal application use. WildAdventureSession does not expose the queue object itself.
func current_event() -> ProgressionEvent:
	return _pending[0] if not _pending.is_empty() else null


# Safe read model for presentation/networking: no mutable event reference leaks out.
func current_snapshot() -> Dictionary:
	var event := current_event()
	if event == null:
		return {}
	return {
		"kind": event.kind,
		"creature_id": String(event.creature_id),
		"data": event.data.duplicate(true),
	}


func consume_current() -> bool:
	if _pending.is_empty():
		return false
	_pending.remove_at(0)
	return true


static func _clone_event(event: ProgressionEvent) -> ProgressionEvent:
	return ProgressionEvent.new(event.kind, event.creature_id, event.data.duplicate(true))