class_name BattleSide
extends RefCounted

var side_id: StringName
var party_ids: Array[StringName] = []
var active_id: StringName


func _init(
	p_side_id: StringName = &"",
	p_party_ids: Array[StringName] = [],
	p_active_id: StringName = &"",
) -> void:
	side_id = p_side_id
	party_ids = p_party_ids.duplicate()
	active_id = p_active_id if p_active_id != &"" else (party_ids[0] if not party_ids.is_empty() else &"")


func owns(creature_id: StringName) -> bool:
	return party_ids.has(creature_id)


func to_dict() -> Dictionary:
	var serialized_party: Array[String] = []
	for creature_id in party_ids:
		serialized_party.append(String(creature_id))
	return {"side_id": String(side_id), "party_ids": serialized_party, "active_id": String(active_id)}


static func from_dict(data: Dictionary) -> BattleSide:
	var party: Array[StringName] = []
	for creature_id in data.get("party_ids", []):
		party.append(StringName(creature_id))
	return BattleSide.new(
		StringName(data.get("side_id", "")), party, StringName(data.get("active_id", ""))
	)

