extends RefCounted

# Shared data contract, not another battle engine. The native candidate validates
# target/effect and applies changes using Pokemon's own HP/status/PP state.
const PATH := "res://modules/inventory/battle_medicine_profile.json"


static func items() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH)).items


static func supports(id: StringName) -> bool:
	return items().has(String(id))
