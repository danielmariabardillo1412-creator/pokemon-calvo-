extends SceneTree

## W03 AUTORUN V3: a genuine native Showdown capture, ownership commit, SaveV2
## roundtrip and next encounter's Repeat Ball probability.
var errors: Array[String] = []
var checks := 0
var scene: Node2D
var bridge: Node
var view: Control

func ck(label: String, yes: bool) -> void:
	checks += 1
	if not yes:
		errors.append(label)
		push_error("W03_REPEAT_NATIVE: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _enter_grass() -> bool:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	return bridge != null and view.session != null and view.session.has_active_battle()

func _end_native_capture() -> void:
	# No UI animation may delay the next map encounter.
	if view._playback.is_playing():
		view._playback.set_process(false)
		var n := 0
		while view._playback.is_playing() and n < 200:
			view._playback.advance(0.5)
			n += 1
	if view.session != null and not view.session.has_active_battle():
		await bridge.leave_battle()

func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	ck("canonical game data", raw is Dictionary)
	if not raw is Dictionary:
		_finish()
		return
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = "user://w03_repeat_native_v3.json"
	ck("native demo booted", scene.is_demo_ready() and bridge != null)
	if not scene.is_demo_ready():
		_finish()
		return
	scene.player.set_physics_process(false)
	var player: PlayerCollection = scene.field_collection()
	ck("new campaign has no caught history", player.caught_base_species_ids.is_empty())
	ck("repeat inventory setup", player.inventory.add(&"repeat_ball", 2))
	ck("first encounter native starts", await _enter_grass())
	if view.session == null:
		_finish()
		return
	view._playback.set_process(false)
	ck("native wild battle, not trainer", view.session.battle_kind == "wild")
	var before_master := player.inventory.quantity(&"master_ball")
	var first: Dictionary = view.session.capture(&"master_ball", view.session.revision)
	ck("first native master capture commits", first.get("accepted", false)
		and view.session.completion_reason == "CAPTURED"
		and player.inventory.quantity(&"master_ball") == before_master - 1)
	ck("first successful native capture writes exact base ledger",
		player.caught_base_species_ids == [&"pidgey"])
	ck("native capture owner owns caught pidgey",
		player.party.get_creatures().any(func(c): return c.base_species_id() == &"pidgey"))
	await _end_native_capture()
	ck("manual native save with real ledger", bridge.save_game())
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(bridge.save_path))
	ck("embedded SaveV2 records real capture",
		saved.get("payload", {}).get("collection", {}).get("caught_base_species_ids", {}).get("ids", []) == ["pidgey"])
	ck("reload native owner with ledger", await bridge.load_game()
		and scene.field_collection().caught_base_species_ids == [&"pidgey"])
	player = scene.field_collection()
	ck("no false caught species", not player.has_previously_caught(&"caterpie", scene._catalogs))
	ck("next native encounter starts", await _enter_grass())
	if view.session == null or not view.session.has_active_battle():
		_finish()
		return
	view._playback.set_process(false)
	ck("repeat ball stocked", player.inventory.has(&"repeat_ball"))
	var before_repeat := player.inventory.quantity(&"repeat_ball")
	var second: Dictionary = view.session.capture(&"repeat_ball", view.session.revision)
	var outcome: Dictionary = second.get("capture_outcome", {}).get("capture", {})
	var capture: Dictionary = outcome.get("result", {})
	ck("second native repeat captures with ledger bonus",
		bool(second.get("accepted", false)) and capture.get("status", "") == String(CaptureResult.SUCCESS))
	ck("native repeat probability has x3.5 bonus", float(capture.get("probability", 0.0)) >= 0.95)
	ck("native repeat spends exactly one", player.inventory.quantity(&"repeat_ball") == before_repeat - 1)
	ck("native ledger deduplicates repeated base", player.caught_base_species_ids == [&"pidgey"])
	ck("native duplicate attempt rejected without extra ball spend",
		not bool(view.session.capture(&"repeat_ball", view.session.revision).get("accepted", false))
		and player.inventory.quantity(&"repeat_ball") == before_repeat - 1)
	await _end_native_capture()
	ck("native second manual save", bridge.save_game())
	ck("repeat history after second reload", await bridge.load_game()
		and scene.field_collection().caught_base_species_ids == [&"pidgey"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bridge.save_path))
	_finish()

func _finish() -> void:
	if scene != null: scene.queue_free()
	await process_frame
	if errors.is_empty():
		print("W03_REPEAT_NATIVE_V3 PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_REPEAT_NATIVE_V3 FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
