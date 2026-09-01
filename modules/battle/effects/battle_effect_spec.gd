class_name BattleEffectSpec
extends RefCounted

const DAMAGE := &"damage"
const HEAL := &"heal"
const REVIVE := &"revive"
const RECOIL := &"recoil"
const DRAIN := &"drain"
const INFLICT_STATUS := &"inflict_status"
const CURE_STATUS := &"cure_status"
const MODIFY_STAT_STAGE := &"modify_stat_stage"
const CHANCE := &"chance"
const FLINCH := &"flinch"
const FIXED_DAMAGE := &"fixed_damage"
const MAX_HP_DAMAGE := &"max_hp_damage"
const MULTI_HIT := &"multi_hit"

const SELF := &"self"
const OPPONENT := &"opponent"

var kind: StringName
var target: StringName
var value: int
var ratio_basis_points: int
var chance_basis_points: int
var status_id: StringName
var stat_id: StringName
var min_hits: int = 0
var max_hits: int = 0
var min_turns: int = 0
var max_turns: int = 0
var children: Array[BattleEffectSpec] = []


func _init(
	p_kind: StringName = &"",
	p_target: StringName = OPPONENT,
	p_value: int = 0,
	p_ratio_basis_points: int = 0,
	p_chance_basis_points: int = 10000,
	p_status_id: StringName = &"",
	p_stat_id: StringName = &"",
	p_min_hits: int = 0,
	p_max_hits: int = 0,
	p_min_turns: int = 0,
	p_max_turns: int = 0,
) -> void:
	kind = p_kind
	target = p_target
	value = p_value
	ratio_basis_points = p_ratio_basis_points
	chance_basis_points = p_chance_basis_points
	status_id = p_status_id
	stat_id = p_stat_id
	min_hits = p_min_hits
	max_hits = p_max_hits
	min_turns = p_min_turns
	max_turns = p_max_turns


func with_child(child: BattleEffectSpec) -> BattleEffectSpec:
	children.append(child)
	return self


func to_dict() -> Dictionary:
	var serialized_children: Array[Dictionary] = []
	for child in children:
		serialized_children.append(child.to_dict())
	return {
		"kind": String(kind),
		"target": String(target),
		"value": value,
		"ratio_basis_points": ratio_basis_points,
		"chance_basis_points": chance_basis_points,
		"status_id": String(status_id),
		"stat_id": String(stat_id),
		"min_hits": min_hits,
		"max_hits": max_hits,
		"min_turns": min_turns,
		"max_turns": max_turns,
		"children": serialized_children,
	}


static func from_dict(data: Dictionary) -> BattleEffectSpec:
	var spec := BattleEffectSpec.new(
		StringName(data.get("kind", "")),
		StringName(data.get("target", OPPONENT)),
		int(data.get("value", 0)),
		int(data.get("ratio_basis_points", 0)),
		int(data.get("chance_basis_points", 10000)),
		StringName(data.get("status_id", "")),
		StringName(data.get("stat_id", "")),
		int(data.get("min_hits", 0)),
		int(data.get("max_hits", 0)),
		int(data.get("min_turns", 0)),
		int(data.get("max_turns", 0)),
	)
	for child_data in data.get("children", []):
		spec.children.append(BattleEffectSpec.from_dict(child_data))
	return spec
