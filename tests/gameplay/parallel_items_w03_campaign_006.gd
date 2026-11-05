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
			"02": await _block_02(block)
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

func _block_02(block: Dictionary) -> void:
	check("02 exact family and no autosave",
		block.get("ids", []) == ["escape_rope", "fluffy_tail"]
		and not bool(block.get("autosave", true)))
	var scene: Variant = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check("02 real demo boots", scene.is_demo_ready())
	if not scene.is_demo_ready():
		scene.queue_free(); await process_frame; return
	scene.player.set_physics_process(false)
	var owner: PlayerCollection = scene.field_collection()
	var bag: Control = scene._item_bag
	var save: Node = scene._native_battles
	save.save_path = "user://camp006_w03_block02_manual.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save.save_path))
	check("02 owns rope", owner.inventory.add(&"escape_rope", 2))
	var amount: int = owner.inventory.quantity(&"escape_rope")
	var enter: OverworldPortal = scene.get_node("CaveEntrance")
	enter.fade_out_msec = 0; enter.fade_in_msec = 0; enter.hold_msec = 0
	var exit: OverworldPortal = scene.get_node("CaveExit")
	exit.fade_out_msec = 0; exit.fade_in_msec = 0; exit.hold_msec = 0
	check("02 enter cave", await scene.traversal_controller.traverse_portal(enter))
	var cave_position: Vector2 = scene.player.global_position
	var dest: Vector2 = scene.get_node("SurfaceCaveReturn").global_position
	check("02 bag visible before use", bag.open_bag() and bag.visible)
	var rope_index := -1
	for i in bag._items.item_count:
		if String(bag._items.get_item_metadata(i)) == "escape_rope":
			rope_index = i
	check("02 rope selectable", rope_index >= 0)
	if rope_index >= 0:
		bag._items.select(rope_index)
		bag._refresh_choices()
		check("02 rope usable without Pokémon target", not bag._use.disabled
			and bag._equip.disabled)
		bag._use.pressed.emit()
		for i in 5: await process_frame
		check("02 button causes real return", not bag.visible
			and scene.technical_region_id() == &"surface"
			and scene.player.global_position.is_equal_approx(dest))
		check("02 spends exactly one", owner.inventory.quantity(&"escape_rope") == amount - 1)
		check("02 no automatic save", not FileAccess.file_exists(save.save_path))
	check("02 collection/identity remains", is_same(scene.field_collection(), owner))
	var native_saved: bool = save.save_game()
	check("02 manual SaveV2 written", native_saved)
	if native_saved:
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(save.save_path))
		check("02 manual save contains destination and spent item",
			payload is Dictionary and payload.get("payload", {}).get("world", {}).get("position", []) == [dest.x, dest.y]
			and payload.get("payload", {}).get("collection", {}).get("inventory", {}).get("quantities", {}).get("escape_rope", -1) == amount - 1)
		scene.player.global_position = cave_position
		var loaded: bool = await save.load_game()
		check("02 load restores world and item", loaded
			and scene.player.global_position.is_equal_approx(dest)
			and scene.field_collection().inventory.quantity(&"escape_rope") == amount - 1)
	# Verify preflight no-stock/region and reentry without consuming anything.
	var tx := preload("res://modules/overworld/field_world_item_transaction.gd").new()
	var snapshot: String = JSON.stringify(scene.field_collection().inventory.to_dict())
	var rejected: Dictionary = tx.prepare(scene, scene.field_collection())
	check("02 surface no anchor at execution",
		rejected.get("accepted", false)
		and not (await tx.execute(scene, rejected)).get("accepted", false)
		and JSON.stringify(scene.field_collection().inventory.to_dict()) == snapshot)
	tx.busy = true
	check("02 double-use busy preflight", tx.prepare(scene, scene.field_collection()).get("reason") == "world_item_busy")
	tx.busy = false
	var owner2: PlayerCollection = scene.field_collection()
	# A prepared snapshot is invalidated before any traversal by an inventory change.
	scene.player.global_position = cave_position
	var prepared_stale: Dictionary = tx.prepare(scene, owner2)
	check("02 stale setup in cave", prepared_stale.get("accepted", false))
	var pre_stale_pos: Vector2 = scene.player.global_position
	check("02 stale change", owner2.inventory.add(&"escape_rope", 1))
	var current_qty: int = owner2.inventory.quantity(&"escape_rope")
	var stale: Dictionary = await tx.execute(scene, prepared_stale)
	check("02 stale revision rejects without move/spend",
		not stale.get("accepted", false)
		and stale.get("reason") == "inventory_changed"
		and scene.player.global_position.is_equal_approx(pre_stale_pos)
		and owner2.inventory.quantity(&"escape_rope") == current_qty)
	# A real collision on the return marker must stop the command in preflight.
	var obstruction := StaticBody2D.new()
	obstruction.position = dest
	var obstruction_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 28)
	obstruction_shape.shape = rect
	obstruction.add_child(obstruction_shape)
	scene.add_child(obstruction)
	await physics_frame
	var prepared_blocked: Dictionary = tx.prepare(scene, owner2)
	var blocked_position: Vector2 = scene.player.global_position
	var blocked_qty: int = owner2.inventory.quantity(&"escape_rope")
	var blocked: Dictionary = await tx.execute(scene, prepared_blocked)
	check("02 occupied anchor rejects without move/spend",
		not blocked.get("accepted", false)
		and blocked.get("reason") == "return_anchor_occupied"
		and scene.player.global_position.is_equal_approx(blocked_position)
		and owner2.inventory.quantity(&"escape_rope") == blocked_qty)
	obstruction.queue_free()
	await process_frame
	check("02 no-stock setup", owner2.inventory.set_quantity(&"escape_rope", 0))
	check("02 no rope refusal", tx.prepare(scene, owner2).get("reason") == "item_not_owned")
	check("02 no-stock retains location", scene.player.global_position.is_equal_approx(blocked_position))
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
