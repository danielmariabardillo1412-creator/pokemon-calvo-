class_name BattleTriggerSpec
extends RefCounted

const ON_BATTLE_START := &"on_battle_start"
const ON_SWITCH_IN := &"on_switch_in"
const BEFORE_MOVE := &"before_move"
const MODIFY_DAMAGE := &"modify_damage"
const AFTER_DAMAGE := &"after_damage"
const ON_STATUS_ATTEMPT := &"on_status_attempt"
const AFTER_STATUS := &"after_status"
const ON_FAINT := &"on_faint"
const END_TURN := &"end_turn"

var trigger: StringName
var source_kind: StringName
var source_id: StringName
var priority: int
var effect: BattleEffectSpec
var conditions: Dictionary
var consume_source: bool


func _init(
	p_trigger: StringName,
	p_source_kind: StringName,
	p_source_id: StringName,
	p_effect: BattleEffectSpec,
	p_priority: int = 0,
	p_conditions: Dictionary = {},
	p_consume_source: bool = false,
) -> void:
	trigger = p_trigger
	source_kind = p_source_kind
	source_id = p_source_id
	effect = p_effect
	priority = p_priority
	conditions = p_conditions.duplicate(true)
	consume_source = p_consume_source

