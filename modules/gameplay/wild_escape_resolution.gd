class_name WildEscapeResolution
extends RefCounted

var escaped: bool = false
var attempt: int = 0
var odds: int = 0
var roll: int = -1
var rng_consumed: bool = false
var reason: String = ""


func succeeded() -> bool:
	return escaped and reason.is_empty()
