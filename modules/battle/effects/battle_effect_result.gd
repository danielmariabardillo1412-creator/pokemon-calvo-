class_name BattleEffectResult
extends RefCounted

var applied: bool
var amount: int
var reason: StringName
var metadata: Dictionary


func _init(
	p_applied: bool = false,
	p_amount: int = 0,
	p_reason: StringName = &"",
	p_metadata: Dictionary = {},
) -> void:
	applied = p_applied
	amount = p_amount
	reason = p_reason
	metadata = p_metadata.duplicate(true)
