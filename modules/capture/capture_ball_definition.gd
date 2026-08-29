class_name CaptureBallDefinition
extends RefCounted

# Structured, extensible ball definition. CaptureSystem reads `base_multiplier` / `guaranteed`
# instead of hard-coding ball names, so new balls (dusk/quick/net/timer) only need a new entry.
#
# Canonical table lives in CaptureRuleset.BALLS (versioned + documented).

var ball_id: StringName = &""
var base_multiplier: float = 1.0
var guaranteed: bool = false


func _init(p_id: StringName = &"", p_mult: float = 1.0, p_guaranteed: bool = false) -> void:
	ball_id = p_id
	base_multiplier = p_mult
	guaranteed = p_guaranteed
