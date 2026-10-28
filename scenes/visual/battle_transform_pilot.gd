extends Node

# Original clip has only bodies. Adapt the appearance handoff honestly, without
# inventing native particles or editing source art/the frozen preview renderer.
const PACK := "res://.godot/battle_transform/manifest.json"
const PACK_SHA := "b95085da594a3e6f2adc67c919c027a6f19608aa5174fa9b55798c9bd8ebad6d"
var available := false
var _indices := {}


func configure(_arena: Control) -> void:
	if not FileAccess.file_exists(PACK) or FileAccess.get_sha256(PACK) != PACK_SHA: return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PACK))
	if data.get("selection") != "transform_v1" or data.get("native_particle_count") != 0: return
	for index in data.clips.size(): _indices[String(data.clips[index].id)] = index
	available = _indices.size() == 2


func _accepts(move: String, metadata: Dictionary) -> bool:
	return move == "transform" and metadata.get("classification") == "UNSUPPORTED" \
		and metadata.get("power") == 0 and metadata.get("category") == "status" \
		and metadata.get("type_id") == "normal" and metadata.get("target") == "selected-pokemon" \
		and metadata.get("effects_empty") == true


func decorate(sequence: Array[Dictionary], before: Dictionary) -> Array[Dictionary]:
	if not available or not before.get("transform_rules_enabled", false) or not _accepts("transform", before.get("moves", {}).get("transform", {})): return sequence
	var result: Array[Dictionary] = []
	for original: Dictionary in sequence:
		var step := original.duplicate(true)
		if step.get("event_kind") == String(BattleEvent.TRANSFORMED) and step.has("appearance_change"):
			step["transform_binding"] = "transform/" + String(step.side)
			step["appearance_handoff_seconds"] = 8.0 / 20.0
			step.duration = 15.0 / 20.0
			step.effect = "transform"
			step.state = "reposo"
			step.erase("move_visual")
			for index in range(result.size() - 1, -1, -1):
				if result[index].get("event_kind") == String(BattleEvent.ACTION_USED):
					if result[index].get("move_visual", {}).get("move_id") == "transform": result[index].erase("move_visual")
					break
		result.append(step)
	return result
