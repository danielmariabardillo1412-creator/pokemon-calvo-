class_name BattleEffectSpec
extends RefCounted

const DAMAGE := &"damage"
const HEAL := &"heal"
const RECOIL := &"recoil"
const DRAIN := &"drain"
const INFLICT_STATUS := &"inflict_status"
const CURE_STATUS := &"cure_status"
const MODIFY_STAT_STAGE := &"modify_stat_stage"
const CHANCE := &"chance"
const FLINCH := &"flinch"
const FIXED_DAMAGE := &"fixed_damage"

const SELF := &"self"
const OPPONENT := &"opponent"

var kind: StringName
var target: StringName
var value: int
var ratio_basis_points: int
var chance_basis_points: int
var status_id: StringName
var stat_id: StringName
var children: Array[BattleEffectSpec] = []


func _init(
	p_kind: StringName = &"",
	p_target: StringName = OPPONENT,
	p_value: int = 0,
	p_ratio_basis_points: int = 0,
	p_chance_basis_points: int = 10000,
	p_status_id: StringName = &"",
	p_stat_id: StringName = &"",
) -> void:
	kind = p_kind
	target = p_target
	value = p_value
	ratio_basis_points = p_ratio_basis_points
	chance_basis_points = p_chance_basis_points
	status_id = p_status_id
	stat_id = p_stat_id


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
	)
	for child_data in data.get("children", []):
		spec.children.append(BattleEffectSpec.from_dict(child_data))
	return spec
