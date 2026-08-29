class_name CaptureEvent
extends RefCounted

# Semantic, serializable capture events. No localized text, no UI strings.
# The future presentation layer turns these into animation/text.

const ATTEMPTED := &"CAPTURE_ATTEMPTED"
const SHAKE := &"CAPTURE_SHAKE"
const FAILED := &"CAPTURE_FAILED"
const SUCCEEDED := &"CAPTURE_SUCCEEDED"
const REJECTED := &"CAPTURE_REJECTED"
const PARTY_ADDED := &"PARTY_ADDED"
const STORAGE_REQUIRED := &"STORAGE_REQUIRED"


var kind: StringName = &""
var data: Dictionary = {}


func _init(p_kind: StringName = &"", p_data: Dictionary = {}) -> void:
	kind = p_kind
	data = p_data
