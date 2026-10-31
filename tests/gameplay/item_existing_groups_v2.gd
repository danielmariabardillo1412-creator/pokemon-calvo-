extends SceneTree

var checks := 0
var errors: Array[String] = []


func _initialize() -> void: call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)


func _run() -> void:
	InventoryTestSuite.new().run(check)
	var inventory_checks := checks
	CapturePartyTestSuite.new().run(check)
	var file := FileAccess.open("res://.godot/item_verification_v2/existing_groups.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "inventory_checks": inventory_checks, "capture_checks": checks - inventory_checks, "errors": errors}, "  ")); file.close()
	print("ITEM_EXISTING_GROUPS_V2 ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks)
	quit(0 if errors.is_empty() else 1)
