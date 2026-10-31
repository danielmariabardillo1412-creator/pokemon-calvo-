extends SceneTree
var checks := 0
var errors: Array[String] = []
func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var main_path := String(ProjectSettings.get_setting("application/run/main_scene"))
	check("configured visual main exists", main_path == "res://scenes/visual/field_demo.tscn" and ResourceLoader.exists(main_path))
	var packed: PackedScene = load(main_path)
	var scene: Node = packed.instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	check("configured main actually boots", scene.has_method("is_demo_ready") and scene.is_demo_ready())
	check("player and encounter zone retained", scene.get_node_or_null("Player") != null and scene.get_node_or_null("EncounterZone") != null)
	check("canvas exists", scene.get_node_or_null("CanvasLayer") != null)
	check("native backend active by default", scene.native_battles_enabled and scene._native_battles != null)
	check("boot owns live party", scene._session != null and scene._session.player.party.get_creatures().size() > 0)
	check("idle field accepts configuration", scene._can_configure() and not scene._native_battles.occupied())
	var script: Script = scene.get_script(); var inherited := false
	while script != null:
		if script.resource_path == "res://scenes/overworld/technical_overworld.gd": inherited = true
		script = script.get_base_script()
	check("visual main retains technical world base", inherited)
	check("isolated userdata name", String(ProjectSettings.get_setting("application/config/name")).begins_with("Pokemon Calvo Comparator "))
	scene.queue_free(); scene = null; await process_frame; await process_frame
	print("COMPARATOR_ENTRYPOINT ","PASS" if errors.is_empty() else "FAIL"," checks=",checks)
	quit(0 if errors.is_empty() else 1)
