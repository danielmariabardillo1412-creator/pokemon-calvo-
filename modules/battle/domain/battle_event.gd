class_name BattleEvent
extends RefCounted

const ACTION_REJECTED := &"action_rejected"
const ACTION_USED := &"action_used"
const MOVE_MISSED := &"move_missed"
const PP_CHANGED := &"pp_changed"
const DAMAGE_APPLIED := &"damage_applied"
const CRITICAL_HIT := &"critical_hit"
const TYPE_EFFECTIVENESS := &"type_effectiveness"
const KNOCKED_OUT := &"knocked_out"
const STATUS_DAMAGE := &"status_damage"
const STATUS_APPLIED := &"status_applied"
const STATUS_FAILED := &"status_failed"
const STATUS_CURED := &"status_cured"
const ACTION_PREVENTED := &"action_prevented"
const STAT_STAGE_CHANGED := &"stat_stage_changed"
const HP_RECOVERED := &"hp_recovered"
const RECOIL_DAMAGE := &"recoil_damage"
const SWITCHED := &"switched"
const ABILITY_TRIGGERED := &"ability_triggered"
const ITEM_TRIGGERED := &"item_triggered"
const TURN_ENDED := &"turn_ended"
const BATTLE_ENDED := &"battle_ended"

var kind: StringName
var turn: int
var actor_id: StringName
var target_id: StringName
var move_id: StringName
var amount: int
var metadata: Dictionary


func _init(
	p_kind: StringName = &"",
	p_turn: int = 0,
	p_actor_id: StringName = &"",
	p_target_id: StringName = &"",
	p_move_id: StringName = &"",
	p_amount: int = 0,
	p_metadata: Dictionary = {},
) -> void:
	kind = p_kind
	turn = p_turn
	actor_id = p_actor_id
	target_id = p_target_id
	move_id = p_move_id
	amount = p_amount
	metadata = p_metadata.duplicate(true)


func to_dict() -> Dictionary:
	return {
		"kind": String(kind),
		"turn": turn,
		"actor_id": String(actor_id),
		"target_id": String(target_id),
		"move_id": String(move_id),
		"amount": amount,
		"metadata": metadata.duplicate(true),
	}
