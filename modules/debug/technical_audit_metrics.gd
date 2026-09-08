class_name TechnicalAuditMetrics
extends RefCounted

# Derived metrics for the asset-free human test laboratory.
# This class never changes gameplay. It only receives observations from the technical scene
# and turns them into compact summaries that are easier to audit than a raw event stream.

const MIN_RATE_SAMPLE := 100
const MOTION_EPSILON := 0.25
const POSITION_ERROR_EPSILON := 0.75
const SLOW_TRANSITION_GRACE_MSEC := 150

var _completed_runs: Array[Dictionary] = []
var _run_index: int = -1
var _config: Dictionary = {}
var _run_started_msec: int = 0

var _steps_total: int = 0
var _zone_steps: Dictionary = {}
var _movement_attempts: int = 0
var _blocked_motion_attempts: int = 0
var _partial_motion_attempts: int = 0
var _requested_distance: float = 0.0
var _actual_distance: float = 0.0

var _encounter_rolls: int = 0
var _encounters: int = 0
var _encounter_misses: int = 0
var _encounter_invalid: int = 0
var _current_dry_streak: int = 0
var _max_dry_streak: int = 0
var _rolls_since_last_encounter: int = 0
var _encounter_intervals: Array[int] = []

var _wild_battles_started: int = 0
var _wild_battles_closed: int = 0
var _trainer_battles_started: int = 0
var _trainer_battles_closed: int = 0
var _trainer_turns: int = 0
var _trainer_turn_errors: int = 0

var _capture_attempts: int = 0
var _capture_accepted: int = 0
var _capture_successes: int = 0
var _capture_failures: int = 0
var _capture_invalid: int = 0
var _capture_to_party: int = 0
var _capture_to_storage: int = 0
var _capture_routing_failures: int = 0
var _capture_by_ball: Dictionary = {}

var _run_attempts: int = 0
var _run_successes: int = 0
var _run_failures: int = 0

var _transition_count: int = 0
var _transition_blocked: int = 0
var _transition_by_kind: Dictionary = {}
var _transition_samples_msec: Array[int] = []
var _transition_slow_count: int = 0
var _transition_position_errors: int = 0

var _ledge_jumps: int = 0
var _ledge_rejected: int = 0
var _ledge_samples_msec: Array[int] = []
var _ledge_position_errors: int = 0

var _validation_snapshots: int = 0
var _validation_failures: int = 0
var _validation_issue_histogram: Dictionary = {}


func begin_run(config: Dictionary) -> void:
	if _run_index >= 0:
		_completed_runs.append(_snapshot_current_run())
	_run_index += 1
	_config = config.duplicate(true)
	_run_started_msec = Time.get_ticks_msec()
	_reset_counters()


func note_step(zone_id: StringName) -> void:
	_steps_total += 1
	var zone := String(zone_id)
	if zone.is_empty():
		return
	_zone_steps[zone] = int(_zone_steps.get(zone, 0)) + 1


func note_motion(requested_displacement: Vector2, actual_displacement: Vector2) -> Dictionary:
	var requested := requested_displacement.length()
	if requested <= MOTION_EPSILON:
		return {"anomaly": false}
	var actual := actual_displacement.length()
	_movement_attempts += 1
	_requested_distance += requested
	_actual_distance += actual
	if actual <= MOTION_EPSILON:
		_blocked_motion_attempts += 1
		return {
			"anomaly": true,
			"kind": "blocked",
			"requested_distance": requested,
			"actual_distance": actual,
		}
	if actual + MOTION_EPSILON < requested:
		_partial_motion_attempts += 1
		return {
			"anomaly": true,
			"kind": "partial",
			"requested_distance": requested,
			"actual_distance": actual,
		}
	return {"anomaly": false}


func note_encounter_roll(battle_started: bool, encounter_status: StringName, reason: String = "") -> void:
	_encounter_rolls += 1
	_rolls_since_last_encounter += 1
	if battle_started or encounter_status == WildEncounterResult.ENCOUNTER:
		_encounters += 1
		_encounter_intervals.append(_rolls_since_last_encounter)
		_rolls_since_last_encounter = 0
		_current_dry_streak = 0
		return
	if encounter_status == WildEncounterResult.NONE or reason == "chance_miss":
		_encounter_misses += 1
		_current_dry_streak += 1
		_max_dry_streak = maxi(_max_dry_streak, _current_dry_streak)
		return
	_encounter_invalid += 1


func note_battle_started(scope: StringName) -> void:
	if scope == &"wild":
		_wild_battles_started += 1
	elif scope == &"trainer":
		_trainer_battles_started += 1


func note_battle_closed(scope: StringName) -> void:
	if scope == &"wild":
		_wild_battles_closed += 1
	elif scope == &"trainer":
		_trainer_battles_closed += 1


func note_wild_diagnostic(entry: Dictionary) -> void:
	var event_name := String(entry.get("event", ""))
	var kind := String(entry.get("kind", ""))
	if event_name == "command":
		if kind == "capture":
			_capture_attempts += 1
			var ball_id := String(entry.get("ball_id", "unknown"))
			_capture_by_ball[ball_id] = int(_capture_by_ball.get(ball_id, 0)) + 1
		elif kind == "run":
			_run_attempts += 1
		return
	if event_name != "command_result":
		return
	if kind == "capture":
		_note_capture_result(entry)
	elif kind == "run":
		_note_run_result(entry)


func note_trainer_diagnostic(entry: Dictionary) -> void:
	if String(entry.get("event", "")) != "turn_resolved":
		return
	_trainer_turns += 1
	if not String(entry.get("last_error", "")).is_empty():
		_trainer_turn_errors += 1


func note_state_validation(issues: Array[String]) -> void:
	_validation_snapshots += 1
	if issues.is_empty():
		return
	_validation_failures += 1
	for issue in issues:
		var family := issue.get_slice(":", 0)
		_validation_issue_histogram[family] = int(_validation_issue_histogram.get(family, 0)) + 1


func note_transition_finished(payload: Dictionary) -> void:
	_transition_count += 1
	var kind := String(payload.get("kind", "unknown"))
	_transition_by_kind[kind] = int(_transition_by_kind.get(kind, 0)) + 1
	var elapsed := int(payload.get("elapsed_msec", 0))
	_transition_samples_msec.append(elapsed)
	var expected := int(payload.get("expected_msec", 0))
	if expected > 0 and elapsed > expected + SLOW_TRANSITION_GRACE_MSEC:
		_transition_slow_count += 1
	if float(payload.get("position_error_px", 0.0)) > POSITION_ERROR_EPSILON:
		_transition_position_errors += 1


func note_traversal_blocked() -> void:
	_transition_blocked += 1


func note_ledge_finished(payload: Dictionary) -> void:
	_ledge_jumps += 1
	_ledge_samples_msec.append(int(payload.get("elapsed_msec", 0)))
	if float(payload.get("position_error_px", 0.0)) > POSITION_ERROR_EPSILON:
		_ledge_position_errors += 1


func note_ledge_rejected() -> void:
	_ledge_rejected += 1


func summary() -> Dictionary:
	var completed := _completed_runs.duplicate(true)
	return {
		"schema_version": 1,
		"run_count": completed.size() + (1 if _run_index >= 0 else 0),
		"completed_runs": completed,
		"current_run": _snapshot_current_run() if _run_index >= 0 else {},
	}


func _note_capture_result(entry: Dictionary) -> void:
	if bool(entry.get("accepted", false)):
		_capture_accepted += 1
	var outcome := entry.get("capture_outcome", {}) as Dictionary
	var capture := outcome.get("capture", {}) as Dictionary
	var result := capture.get("result", {}) as Dictionary
	var status := String(result.get("status", ""))
	if status == "SUCCESS":
		_capture_successes += 1
		if not bool(outcome.get("routed", false)):
			_capture_routing_failures += 1
		elif bool(outcome.get("stored", false)):
			_capture_to_storage += 1
		else:
			_capture_to_party += 1
	elif status == "FAILED":
		_capture_failures += 1
	elif not status.is_empty():
		_capture_invalid += 1


func _note_run_result(entry: Dictionary) -> void:
	var escape := entry.get("escape_resolution", {}) as Dictionary
	if bool(escape.get("escaped", false)):
		_run_successes += 1
	elif bool(entry.get("accepted", false)):
		_run_failures += 1


func _snapshot_current_run() -> Dictionary:
	var expected_rate := float(int(_config.get("encounter_chance_percent", 0)))
	var observed_rate := 0.0
	if _encounter_rolls > 0:
		observed_rate = 100.0 * float(_encounters) / float(_encounter_rolls)
	var rate_audit := _rate_audit(expected_rate, observed_rate, _encounter_rolls)
	var encounter_zone_steps := 0
	for value in _zone_steps.values():
		encounter_zone_steps += int(value)
	return {
		"run_index": _run_index,
		"elapsed_msec": maxi(0, Time.get_ticks_msec() - _run_started_msec),
		"config": _config.duplicate(true),
		"overworld": {
			"steps_total": _steps_total,
			"steps_in_encounter_zones": encounter_zone_steps,
			"steps_outside_encounter_zones": maxi(0, _steps_total - encounter_zone_steps),
			"zone_steps": _zone_steps.duplicate(true),
			"movement_attempts": _movement_attempts,
			"blocked_motion_attempts": _blocked_motion_attempts,
			"partial_motion_attempts": _partial_motion_attempts,
			"requested_distance_px": _requested_distance,
			"actual_distance_px": _actual_distance,
		},
		"encounters": {
			"configured_rate_percent": expected_rate,
			"rolls": _encounter_rolls,
			"encounters": _encounters,
			"misses": _encounter_misses,
			"invalid": _encounter_invalid,
			"observed_rate_percent": observed_rate,
			"mean_rolls_per_encounter": float(_encounter_rolls) / float(_encounters) if _encounters > 0 else 0.0,
			"mean_observed_interval_rolls": _mean_ints(_encounter_intervals),
			"max_dry_streak_rolls": _max_dry_streak,
			"current_dry_streak_rolls": _current_dry_streak,
			"intervals_rolls": _encounter_intervals.duplicate(),
			"rate_audit": rate_audit,
		},
		"battles": {
			"wild_started": _wild_battles_started,
			"wild_closed": _wild_battles_closed,
			"trainer_started": _trainer_battles_started,
			"trainer_closed": _trainer_battles_closed,
			"trainer_turns": _trainer_turns,
			"trainer_turn_errors": _trainer_turn_errors,
		},
		"capture": {
			"attempts": _capture_attempts,
			"accepted": _capture_accepted,
			"successes": _capture_successes,
			"failures": _capture_failures,
			"invalid": _capture_invalid,
			"routed_to_party": _capture_to_party,
			"routed_to_storage": _capture_to_storage,
			"routing_failures": _capture_routing_failures,
			"by_ball": _capture_by_ball.duplicate(true),
		},
		"run_away": {
			"attempts": _run_attempts,
			"successes": _run_successes,
			"failures": _run_failures,
		},
		"transitions": {
			"completed": _transition_count,
			"blocked": _transition_blocked,
			"by_kind": _transition_by_kind.duplicate(true),
			"mean_msec": _mean_ints(_transition_samples_msec),
			"max_msec": _max_int(_transition_samples_msec),
			"samples_msec": _transition_samples_msec.duplicate(),
			"slow_count": _transition_slow_count,
			"position_error_count": _transition_position_errors,
		},
		"ledges": {
			"jumps": _ledge_jumps,
			"rejected": _ledge_rejected,
			"mean_msec": _mean_ints(_ledge_samples_msec),
			"max_msec": _max_int(_ledge_samples_msec),
			"samples_msec": _ledge_samples_msec.duplicate(),
			"position_error_count": _ledge_position_errors,
		},
		"state_validation": {
			"snapshots": _validation_snapshots,
			"failures": _validation_failures,
			"issue_histogram": _validation_issue_histogram.duplicate(true),
		},
	}


func _rate_audit(expected_percent: float, observed_percent: float, samples: int) -> Dictionary:
	if samples <= 0:
		return {
			"status": "NO_SAMPLES",
			"delta_percentage_points": 0.0,
			"tolerance_percentage_points": 0.0,
		}
	var delta := observed_percent - expected_percent
	if expected_percent <= 0.0 or expected_percent >= 100.0:
		return {
			"status": "OK" if absf(delta) <= 0.0001 else "CHECK",
			"delta_percentage_points": delta,
			"tolerance_percentage_points": 0.0,
		}
	var p := expected_percent / 100.0
	var sigma_pp := sqrt(p * (1.0 - p) / float(samples)) * 100.0
	var tolerance_pp := maxf(2.0, sigma_pp * 3.0)
	return {
		"status": (
			"INSUFFICIENT_SAMPLE"
			if samples < MIN_RATE_SAMPLE
			else ("OK" if absf(delta) <= tolerance_pp else "CHECK")
		),
		"delta_percentage_points": delta,
		"tolerance_percentage_points": tolerance_pp,
		"minimum_recommended_rolls": MIN_RATE_SAMPLE,
	}


func _reset_counters() -> void:
	_steps_total = 0
	_zone_steps.clear()
	_movement_attempts = 0
	_blocked_motion_attempts = 0
	_partial_motion_attempts = 0
	_requested_distance = 0.0
	_actual_distance = 0.0
	_encounter_rolls = 0
	_encounters = 0
	_encounter_misses = 0
	_encounter_invalid = 0
	_current_dry_streak = 0
	_max_dry_streak = 0
	_rolls_since_last_encounter = 0
	_encounter_intervals.clear()
	_wild_battles_started = 0
	_wild_battles_closed = 0
	_trainer_battles_started = 0
	_trainer_battles_closed = 0
	_trainer_turns = 0
	_trainer_turn_errors = 0
	_capture_attempts = 0
	_capture_accepted = 0
	_capture_successes = 0
	_capture_failures = 0
	_capture_invalid = 0
	_capture_to_party = 0
	_capture_to_storage = 0
	_capture_routing_failures = 0
	_capture_by_ball.clear()
	_run_attempts = 0
	_run_successes = 0
	_run_failures = 0
	_transition_count = 0
	_transition_blocked = 0
	_transition_by_kind.clear()
	_transition_samples_msec.clear()
	_transition_slow_count = 0
	_transition_position_errors = 0
	_ledge_jumps = 0
	_ledge_rejected = 0
	_ledge_samples_msec.clear()
	_ledge_position_errors = 0
	_validation_snapshots = 0
	_validation_failures = 0
	_validation_issue_histogram.clear()


func _mean_ints(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0
	for value in values:
		total += value
	return float(total) / float(values.size())


func _max_int(values: Array[int]) -> int:
	var result := 0
	for value in values:
		result = maxi(result, value)
	return result
