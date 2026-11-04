extends SceneTree

const Pilot = preload("res://modules/overworld/escape_rope_demo_pilot.gd")
const FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_006.json"
var checks := 0
var errors: Array[String] = []
var done := false

func _initialize() -> void:
	call_deferred("_run")
	create_timer(180).timeout.connect(func():
		if not done:
			check("watchdog", false)
			_finish(0))

func check(label: String, good: bool) -> void:
	checks += 1
	if not good:
		errors.append(label)
		push_error("CAMP006_W03: " + label)

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not parsed is Dictionary:
		check("fixture loaded", false); _finish(0); return
	var blocks: Array = parsed.get("blocks", [])
	check("campaign identity", parsed.get("campaign") == "CAMP_006"
		and parsed.get("worker") == "W03" and blocks.size() > 0)
	var n := 0
	for block: Dictionary in blocks:
		n += 1
		match String(block.get("bloque", "")):
			"01": await _block_01(block)
			_: check("block not implemented", false)
	_finish(n)

func _block_01(block: Dictionary) -> void:
	check("block01 exact", block.get("ids", []) == ["escape_rope"]
		and block.get("contract") == "DEMO_RETURN_ANCHOR_V1")
	var scene: Variant = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check("real demo boots", scene.is_demo_ready())
	if not scene.is_demo_ready():
		scene.queue_free(); await process_frame; return
	var player: OverworldPlayer = scene.player
	player.set_physics_process(false)
	var owner: PlayerCollection = scene.field_collection()
	var original_quantity: int = owner.inventory.quantity(&"escape_rope")
	check("item seeded in real inventory",
		owner.inventory.add(&"escape_rope", 2))
	var stocked: int = owner.inventory.quantity(&"escape_rope")
	check("test inventory ready", stocked == original_quantity + 2)
	var early: Dictionary = Pilot.preview(scene)
	check("no anchor on demo surface", not early.get("ok", false)
		and early.get("reason") == "no_return_anchor"
		and owner.inventory.quantity(&"escape_rope") == stocked)
	var enter: OverworldPortal = scene.get_node("CaveEntrance")
	enter.fade_out_msec = 0; enter.fade_in_msec = 0; enter.hold_msec = 0
	check("real cave entry traversal",
		await scene.traversal_controller.traverse_portal(enter))
	check("entered cave region", scene.technical_region_id() == &"cave")
	var plan: Dictionary = Pilot.preview(scene)
	check("anchor is source-owned and marker-backed",
		plan.get("ok", false) and plan.get("anchor_id") == "SurfaceCaveReturn"
		and plan.get("portal") == scene.get_node("CaveExit"))
	var destination: Vector2 = scene.get_node("SurfaceCaveReturn").global_position
	var cave_exit: OverworldPortal = scene.get_node("CaveExit")
	cave_exit.fade_out_msec = 0; cave_exit.fade_in_msec = 0; cave_exit.hold_msec = 0
	player.movement_enabled = false
	var locked: Dictionary = Pilot.preview(scene)
	check("locked movement safe rejection", not locked.get("ok", false)
		and locked.get("reason") == "field_locked"
		and owner.inventory.quantity(&"escape_rope") == stocked)
	player.movement_enabled = true
	var result: Dictionary = await Pilot.return_to_demo_anchor(scene)
	check("positive return through actual traversal",
		result.get("ok", false) and result.get("status") == "PILOT_TRAVERSED_NO_SPEND"
		and player.global_position.is_equal_approx(destination)
		and scene.technical_region_id() == &"surface")
	check("pilot preserves item until authorized transaction",
		owner.inventory.quantity(&"escape_rope") == stocked)
	check("movement restored after portal",
		player.movement_enabled and not scene.traversal_controller.is_busy())
	var world: Dictionary = scene.field_native_world_snapshot("gen9calvounifiedv1")
	check("saved world position is returned anchor",
		world.get("region") == "surface"
		and world.get("position") == [destination.x, destination.y])
	var save: Node = scene._native_battles
	check("native save bridge exists", save != null)
	save.save_path = "user://camp006_w03_escape_rope_pilot.json"
	var saved: bool = save.save_game()
	check("real native SaveV2 envelope write", saved)
	if saved:
		var on_disk: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(save.save_path))
		check("real file stores anchor world position",
			on_disk.get("payload", {}).get("world", {}).get("position", []) ==
				[destination.x, destination.y])
		# Disturb player position before read, then restore through existing bridge.
		player.global_position = scene.get_node("CaveEntrySpawn").global_position
		var loaded: bool = await save.load_game()
		check("native save read restored return position", loaded
			and player.global_position.is_equal_approx(destination)
			and scene.technical_region_id() == &"surface")
		check("save retained rope quantity", scene.field_collection().inventory.quantity(
			&"escape_rope") == stocked)
	check("no new global API changed", block.get("inventory_commit") == false
		and block.get("savev2_schema_changed") == false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save.save_path))
	scene.queue_free()
	await process_frame

func _finish(n: int) -> void:
	done = true
	if errors.is_empty() and checks > 0:
		print("CAMP006_W03_GODOT PASS blocks=" + str(n) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP006_W03_GODOT FAIL blocks=" + str(n) + " checks=" + str(checks)
			+ " errors=" + JSON.stringify(errors))
		quit(1)
