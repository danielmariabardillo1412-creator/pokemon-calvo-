class_name DataValidationIssue
extends RefCounted

var code: String = ""
var message: String = ""
var context: Dictionary = {}

func _init(p_code: String = "", p_message: String = "", p_context: Dictionary = {}) -> void:
	code = p_code
	message = p_message
	context = p_context

func to_dict() -> Dictionary:
	return {"code": code, "message": message, "context": context}
