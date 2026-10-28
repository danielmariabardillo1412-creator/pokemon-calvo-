extends SceneTree

var OUT := "res://.godot/native_doubles_checks/"
const IDS := ["after_you", "ally_switch", "aromatic_mist", "coaching", "dragon_cheer", "follow_me", "helping_hand", "hold_hands", "quash", "rage_powder", "spotlight"]
var scene: Node
var view: Control
var checks := 0
var errors: Array[String] = []
var captures: Array = []
var done := false


func _initialize() -> void: call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)


func wait_ready() -> void:
	while view.loading: await process_frame


func _run() -> void:
	if not OS.get_environment("CALVO_DOUBLES_UI_OUT").is_empty(): OUT = OS.get_environment("CALVO_DOUBLES_UI_OUT").replace("\\", "/").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(240).timeout.connect(func():
		if not done:
			if view != null: await view.shutdown()
			check("watchdog", false); _finish())
	root.size = Vector2i(1200, 720)
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await process_frame
	var party: Dictionary = scene._session.player.party.to_dict()
	check("F12 opens native doubles from ordinary map", scene.open_doubles_demo())
	view = scene._doubles_demo; view.save_path = OUT + "trial.json"
	await wait_ready()
	check("world movement locked", not scene.player.movement_enabled)
	for side in 2:
		for i in IDS.size():
			view._preset.select(i); view._origin.select(side); await view.reset_scenario()
			check("UI opens preset " + IDS[i] + str(side), view.server.phase() == "move" and view._choices.size() == 4)
			var result: Dictionary = await view.submit_selected_turn()
			check("four selected actions resolve " + IDS[i] + str(side), result.accepted and int(view.server._checkpoint.snapshot.native.turn) == 2)
			var target_id := "ally" if IDS[i] in ["after_you", "aromatic_mist", "coaching", "dragon_cheer", "helping_hand", "hold_hands"] else "actor"
			var found := false
			while view._index >= 0:
				var step: Dictionary = view._sequence[view._index]
				if step.event.get("kind") == String(BattleEvent.ACTION_USED) and step.event.get("move_id") == IDS[i]:
					found = true
					if IDS[i] != "ally_switch":
						check("reviewed clip bound " + IDS[i] + str(side), is_instance_valid(view.clips.preview) and view.clips.preview.visible and not view.clips.preview.effects_only and not view.clips.preview._arena.visible and not view.clips.preview.external_actor_layout.is_empty())
						if IDS[i] in ["after_you", "aromatic_mist", "coaching", "dragon_cheer", "helping_hand", "hold_hands"]:
							var layout: Dictionary = view.clips.preview.external_actor_layout
							var target_side := "front" if view.clips.preview.clip.actor_side == "back" else "back"
							check("helper uses actual ally position " + IDS[i] + str(side), Vector2(layout[target_side].center).is_equal_approx(view.arena.actor_layout(step.before.units[target_id]).center))
						for sample in 3:
							view._elapsed = float(step.duration) * [0.2, 0.5, 0.8][sample]; view.advance(0)
							await capture(IDS[i] + "_" + str(side) + "_" + str(sample))
				elif step.event.get("kind") == String(BattleEvent.ALLY_POSITIONS_SWAPPED):
					for sample in 3:
						view._elapsed = float(step.duration) * [0.2, 0.5, 0.8][sample]; view.advance(0)
						await capture(IDS[i] + "_" + str(side) + "_" + str(sample))
				view.advance(100)
			check("animation and final roster " + IDS[i] + str(side), found and view.arena.step.after.units.size() == 4)
			if IDS[i] == "ally_switch": check("swap preserves visual identities", view.arena.step.after.slots["side_a" if side == 0 else "side_b"] == ["ally", "actor"])
			if IDS[i] == "dragon_cheer" and side == 0:
				var saved: Dictionary = view.server.snapshot(); view.save_trial()
				check("atomic UI save", FileAccess.file_exists(view.save_path))
				await view.submit_selected_turn()
				while view._index >= 0: view.advance(100)
				await view.load_trial(); check("UI reload restores exact native checkpoint", view.server.snapshot() == saved)
				var file := FileAccess.open(view.save_path, FileAccess.WRITE); file.store_string("{}"); file.close()
				await view.load_trial(); check("invalid load retains battle", view.server.snapshot() == saved)
			check("trial never alters actual campaign party", scene._session.player.party.to_dict() == party)
	var pid: int = view.server._client.pid
	await scene._close_doubles_demo()
	check("close returns map and stops worker", not view.visible and scene.player.movement_enabled and not OS.is_process_running(pid))
	check("F12 reopens without stale transaction", scene.open_doubles_demo()); await wait_ready()
	pid = view.server._client.pid
	await scene._close_doubles_demo(); check("reopened worker closes", not OS.is_process_running(pid))
	scene.queue_free(); await process_frame; _finish()


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame; await RenderingServer.frame_post_draw
	var path := OUT + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})


func _finish() -> void:
	if done: return
	done = true
	var file := FileAccess.open(OUT + ("ui.json" if DisplayServer.get_name() == "headless" else "gpu.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "captures": captures}, "  ")); file.close()
	print("DOUBLES_UI ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size()); quit(0 if errors.is_empty() else 1)
