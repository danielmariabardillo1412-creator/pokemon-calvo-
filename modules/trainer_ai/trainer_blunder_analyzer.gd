class_name TrainerBlunderAnalyzer
extends RefCounted

# Offline evaluation helper. These are objective diagnostic signatures, not claims
# of perfect-play mistakes. A signature must be derivable from the safe decision
# trace or authoritative public battle events.

const DECISION_NULL := "decision_null"
const ACTION_REJECTED := "action_rejected"
const SELECTED_KNOWN_IMMUNITY := "selected_known_immunity"
const NO_PROGRESS_WINDOW := "no_progress_window"
const TURN_LIMIT := "turn_limit"
const NO_PROGRESS_WINDOW_TURNS := 4

var _counts: Dictionary = {}
var _records: Array[Dictionary] = []
var _no_progress_turns: int = 0


func inspect_decision(
	side_id: StringName,
	action: BattleAction,
	trace: TrainerDecisionTrace,
	turn: int,
) -> void:
	if action == null:
		_record(DECISION_NULL, side_id, turn, {})
		return
	if action.action_type != BattleAction.MOVE or trace == null:
		return
	var selected := action.to_dict()
	for candidate_value in trace.candidates:
		var candidate := candidate_value as Dictionary
		var candidate_action := candidate.get("action", {}) as Dictionary
		if not _same_action(selected, candidate_action):
			continue
		var metadata := candidate.get("metadata", {}) as Dictionary
		var tactical := metadata.get("tactical", {}) as Dictionary
		if int(tactical.get("type_effectiveness_basis_points", 10000)) == 0:
			_record(
				SELECTED_KNOWN_IMMUNITY,
				side_id,
				turn,
				{"move_id": String(action.move_id)},
			)
		return


func inspect_events(events: Array[BattleEvent], turn: int) -> void:
	var progressed := false
	for event in events:
		if event == null:
			continue
		if event.kind == BattleEvent.ACTION_REJECTED:
			_record(
				ACTION_REJECTED,
				&"",
				turn,
				{"reason": String(event.metadata.get("reason", "action_rejected"))},
			)
		if _is_material_progress(event.kind):
			progressed = true
	if progressed:
		_no_progress_turns = 0
	else:
		_no_progress_turns += 1
		if _no_progress_turns >= NO_PROGRESS_WINDOW_TURNS:
			_record(
				NO_PROGRESS_WINDOW,
				&"",
				turn,
				{"window_turns": NO_PROGRESS_WINDOW_TURNS},
			)
			_no_progress_turns = 0


func mark_turn_limit(turn: int) -> void:
	_record(TURN_LIMIT, &"", turn, {})


func count(signature_id: String) -> int:
	return int(_counts.get(signature_id, 0))


func report() -> Dictionary:
	return {
		"schema_version": 1,
		"counts": _counts.duplicate(true),
		"records": _records.duplicate(true),
		"record_count": _records.size(),
	}


func _record(
	signature_id: String,
	side_id: StringName,
	turn: int,
	metadata: Dictionary,
) -> void:
	_counts[signature_id] = int(_counts.get(signature_id, 0)) + 1
	_records.append({
		"signature_id": signature_id,
		"side_id": String(side_id),
		"turn": turn,
		"metadata": metadata.duplicate(true),
	})


func _is_material_progress(kind: StringName) -> bool:
	return kind in [
		BattleEvent.DAMAGE_APPLIED,
		BattleEvent.KNOCKED_OUT,
		BattleEvent.STATUS_DAMAGE,
		BattleEvent.STATUS_APPLIED,
		BattleEvent.STATUS_CURED,
		BattleEvent.STAT_STAGE_CHANGED,
		BattleEvent.HP_RECOVERED,
		BattleEvent.RECOIL_DAMAGE,
		BattleEvent.SWITCHED,
		BattleEvent.BATTLE_ENDED,
	]


func _same_action(a: Dictionary, b: Dictionary) -> bool:
	return (
		String(a.get("actor_id", "")) == String(b.get("actor_id", ""))
		and String(a.get("action_type", "")) == String(b.get("action_type", ""))
		and String(a.get("move_id", "")) == String(b.get("move_id", ""))
		and String(a.get("switch_instance_id", "")) == String(b.get("switch_instance_id", ""))
	)
