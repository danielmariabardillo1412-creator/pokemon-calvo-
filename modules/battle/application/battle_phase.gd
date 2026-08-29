class_name BattlePhase
extends RefCounted

const VALIDATE_ACTIONS := &"validate_actions"
const SELECT_ORDER := &"select_order"
const BEFORE_ACTION := &"before_action"
const ACCURACY := &"accuracy"
const EXECUTE_EFFECTS := &"execute_effects"
const AFTER_DAMAGE := &"after_damage"
const FAINT_CHECK := &"faint_check"
const AFTER_ACTION := &"after_action"
const END_TURN_STATUS := &"end_turn_status"
const END_TURN_TRIGGERS := &"end_turn_triggers"
const TURN_END := &"turn_end"

const ORDER: Array[StringName] = [
	VALIDATE_ACTIONS,
	SELECT_ORDER,
	BEFORE_ACTION,
	ACCURACY,
	EXECUTE_EFFECTS,
	AFTER_DAMAGE,
	FAINT_CHECK,
	AFTER_ACTION,
	END_TURN_STATUS,
	END_TURN_TRIGGERS,
	TURN_END,
]

