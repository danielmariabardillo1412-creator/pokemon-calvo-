extends RefCounted

# The technical scene remains a legacy fixture. The configured game now boots
# its visual subclass; check that relationship without opening a live session.
static func configured_main_is_field() -> bool:
	var path := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if path != "res://scenes/visual/field_demo.tscn" or not ResourceLoader.exists(path):
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		return false
	var field := packed.instantiate()
	var script: Script = field.get_script()
	var inherits_world := false
	while script != null:
		if script.resource_path == "res://scenes/overworld/technical_overworld.gd":
			inherits_world = true
		script = script.get_base_script()
	var has_nodes := field.get_node_or_null("Player") is OverworldPlayer \
		and field.get_node_or_null("EncounterZone") is OverworldEncounterZone \
		and field.get_node_or_null("CanvasLayer") != null
	field.free()
	return inherits_world and has_nodes
