extends SceneTree

# Independent RGB oracle uses Godot Color, NOT Python's converter/colorsys.
const PROOF := "res://.godot/move_hue_checks/sources.json"
var _checks := 0
var _failures: Array[String] = []
var _samples := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok and _failures.size() < 30:
		_failures.append(label)


func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROOF))
	if not data is Dictionary or not data.get("rows") is Array:
		printerr("MOVE_HUE_ORACLE FAIL missing/invalid source proof")
		quit(1)
		return
	var proof: Dictionary = data
	_check("current index", proof.index_sha256 == FileAccess.get_sha256("res://.godot/move_batch_catalog/index.json"))
	_check("source audit current", proof.builder_sha256 == FileAccess.get_sha256("res://tools/visual/audit_move_hue_sources.py"))
	for row: Dictionary in proof.rows:
		_check("original hash", FileAccess.get_sha256(row.original) == row.source_sha256)
		_check("derived hash", FileAccess.get_sha256(row.derived) == row.derived_sha256)
		var source := Image.load_from_file(row.original)
		var derived := Image.load_from_file(row.derived)
		_check("dimensions", source.get_size() == derived.get_size())
		var count := source.get_width() * source.get_height()
		var step := maxi(1, count / 4096)
		for offset in range(0, count, step):
			var pos := Vector2i(offset % source.get_width(), offset / source.get_width())
			var original := source.get_pixelv(pos)
			var actual := derived.get_pixelv(pos)
			var expected := Color.from_hsv(fposmod(original.h + float(row.degrees) / 360.0, 1.0), original.s, original.v, original.a)
			_check("HSV red/" + str(pos), absi(expected.r8 - actual.r8) <= 1)
			_check("HSV green/" + str(pos), absi(expected.g8 - actual.g8) <= 1)
			_check("HSV blue/" + str(pos), absi(expected.b8 - actual.b8) <= 1)
			_check("alpha/" + str(pos), original.a8 == actual.a8)
			_samples += 1
		await process_frame
	var report := {"checks": _checks, "samples": _samples, "failures": _failures,
		"index_sha256": proof.index_sha256, "sources_sha256": FileAccess.get_sha256(PROOF),
		"runner_sha256": FileAccess.get_sha256("res://tests/visual/move_hue_test_runner.gd"),
		"scope": "Independent Godot HSV RGB sampling, <=1 byte GPU quantization tolerance, exact alpha; not art approval"}
	var file := FileAccess.open("res://.godot/move_hue_checks/result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("MOVE_HUE_ORACLE ", "PASS" if _failures.is_empty() else "FAIL", " checks=", _checks, " samples=", _samples, " failures=", _failures)
	quit(0 if _failures.is_empty() else 1)
