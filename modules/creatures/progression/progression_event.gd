class_name ProgressionEvent
extends RefCounted

# Semantic progression event. Pure data (no UI, no signals). Emitted by ProgressionSystem
# so callers (UI, networking, save) can react without the Progression Core knowing about them.

const EXPERIENCE_GAINED := "EXPERIENCE_GAINED"
const LEVEL_UP := "LEVEL_UP"
const STAT_CHANGED := "STAT_CHANGED"
const MOVE_LEARNED := "MOVE_LEARNED"
const MOVE_LEARN_CHOICE_REQUIRED := "MOVE_LEARN_CHOICE_REQUIRED"
const EVOLUTION_AVAILABLE := "EVOLUTION_AVAILABLE"
const EVOLUTION_APPLIED := "EVOLUTION_APPLIED"

var kind: String = ""
var creature_id: StringName = &""
var data: Dictionary = {}


func _init(p_kind: String = "", p_creature_id: StringName = &"", p_data: Dictionary = {}) -> void:
	kind = p_kind
	creature_id = p_creature_id
	data = p_data
