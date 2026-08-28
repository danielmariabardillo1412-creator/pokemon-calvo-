class_name SeededRandomSource
extends RefCounted

const _MASK_32 := 0xFFFFFFFF
const _DEFAULT_NON_ZERO_STATE := 0x6D2B79F5

var _state: int


func _init(seed: int = 1) -> void:
	_state = seed & _MASK_32
	if _state == 0:
		_state = _DEFAULT_NON_ZERO_STATE


func next_u32() -> int:
	# Numerical Recipes LCG. It is stable across platforms and intentionally not cryptographic.
	_state = (1664525 * _state + 1013904223) & _MASK_32
	return _state


func next_index(count: int) -> int:
	assert(count > 0, "next_index requires a positive count")
	return next_u32() % count


func damage_factor_basis_points() -> int:
	return 8500 + (next_u32() % 1501)


func state() -> int:
	return _state


func restore_state(value: int) -> void:
	_state = value & _MASK_32
	if _state == 0:
		_state = _DEFAULT_NON_ZERO_STATE

