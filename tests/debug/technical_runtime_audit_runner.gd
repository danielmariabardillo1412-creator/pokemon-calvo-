extends SceneTree

const TECHNICAL_SCENE := "res://scenes/overworld/technical_overworld.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(TECHNICAL_SCENE) as PackedScene
	if packed == null:
		push_error("TECHNICAL_AUDIT_RUNNER: cannot load technical scene")
		quit(1)
		return
	var world := packed.instantiate() as Node2D
	if world == null:
		push_error("TECHNICAL_AUDIT_RUNNER: cannot instantiate technical scene")
		quit(1)
		return
	root.add_child(world)
	current_scene = world
	await process_frame
	await physics_frame
	var panel := world.get_node_or_null("CanvasLayer/TechnicalTestPanel") as TechnicalTestPanel
	if panel == null:
		push_error("TECHNICAL_AUDIT_RUNNER: technical test panel missing")
		quit(1)
		return
	var result := TechnicalRuntimeAuditService.run_and_export(world, panel.current_configuration())
	if not bool(result.get("ok", false)):
		var error := String(result.get("error", "audit_service_failed"))
		push_error("TECHNICAL_AUDIT_RUNNER: %s" % error)
		print("TECHNICAL_AUDIT_COMPLETE status=FAIL ok=0 warn=0 fail=1 error=%s" % error)
		quit(1)
		return
	var audit := result.get("audit", {}) as Dictionary
	var counts := audit.get("counts", {}) as Dictionary
	var status := String(audit.get("overall_status", "FAIL"))
	var ok_count := int(counts.get("OK", 0))
	var warn_count := int(counts.get("WARN", 0))
	var fail_count := int(counts.get("FAIL", 0))
	print("TECHNICAL_AUDIT_COMPLETE status=%s ok=%d warn=%d fail=%d report=%s" % [
		status,
		ok_count,
		warn_count,
		fail_count,
		String(result.get("path", "")),
	])
	for check in audit.get("checks", []):
		var row := check as Dictionary
		var row_status := String(row.get("status", "FAIL"))
		if row_status != "OK":
			print("AUDIT_%s %s %s" % [row_status, String(row.get("code", "UNKNOWN")), JSON.stringify(row.get("details", {}))])
	quit(0 if fail_count == 0 else 1)
