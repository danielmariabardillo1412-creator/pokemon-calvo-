extends SceneTree

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Layout = preload("res://scenes/visual/battle_sprite_layout.gd")
const ARENAS := [Vector2(338, 120), Vector2(420, 160), Vector2(674, 359), Vector2(698, 376), Vector2(1000, 280)]
var _passed := 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var metrics: Dictionary = Catalog.presentation_metrics()
	_check("complete_pinned_base_metrics", metrics.size() == 1025)
	_check("base_and_regional_catalog", Catalog.species_rows().size() == 1082)
	_check("complete_pinned_scale_references", Catalog.scale_references().size() == 1025)
	metrics = metrics.duplicate(true)
	for key: String in Catalog.species_rows():
		var row: Dictionary = Catalog.species_rows()[key]
		if row.has("metrics"): metrics[key] = row.metrics
	var comparisons: Dictionary = {}
	var limited_front := 0
	var limited_back := 0
	for key: String in metrics:
		var species_report: Dictionary = {}
		for side: String in ["front", "back"]:
			var data: Array = metrics[key][side].bounds
			var original_envelope := Rect2(float(data[0]), float(data[1]), float(data[2]) - float(data[0]), float(data[3]) - float(data[1]))
			var reference_factor := Catalog.presentation_scale(StringName(key), side)
			var envelope := Rect2(original_envelope.position * reference_factor, original_envelope.size * reference_factor)
			_check("positive_envelope/%s/%s" % [key, side], envelope.size.x > 0 and envelope.size.y > 0)
			for arena: Vector2 in ARENAS:
				var result: Dictionary = Layout.placement(arena, side, envelope)
				var projected := Rect2(Vector2(result.anchor) + envelope.position * float(result.gain), envelope.size * float(result.gain))
				var label := "%s/%s/%s" % [key, side, arena]
				_check("positive_gain/" + label, is_finite(float(result.gain)) and float(result.gain) > 0.0)
				_check("inside_arena/" + label, Rect2(Vector2.ZERO, arena).grow(0.0001).encloses(projected))
				var fraction := Layout.FRONT_MAX_FRACTION if side == "front" else Layout.BACK_MAX_FRACTION
				_check("footprint_limit/" + label, projected.size.x <= arena.x * fraction.x + 0.0001 and projected.size.y <= arena.y * fraction.y + 0.0001)
				var repeated: Dictionary = Layout.placement(arena, side, envelope)
				_check("fixed_deterministic_gain/" + label, repeated == result)
				_check("no_stretch_or_enlargement/" + label, float(result.guard) > 0 and float(result.guard) <= 1.0)
			var reference := Vector2(674, 359)
			var placement: Dictionary = Layout.placement(reference, side, envelope)
			var old_gain := minf(reference.y * 0.52 / 240.0, reference.x * 0.43 / 356.0)
			species_report[side] = {"before": [original_envelope.size.x * old_gain, original_envelope.size.y * old_gain],
				"after": [envelope.size.x * float(placement.gain), envelope.size.y * float(placement.gain)],
				"scale_change": float(placement.gain) * reference_factor / old_gain, "guard": placement.guard}
			if float(placement.guard) < 0.999999:
				if side == "front":
					limited_front += 1
				else:
					limited_back += 1
		comparisons[key] = species_report
	if comparisons.has("wailord"):
		_check("wailord_enemy_reduced", comparisons.wailord.front.scale_change < 0.75)
		_check("wailord_player_roughly_preserved", comparisons.wailord.back.scale_change > 0.90)
		_check("wailord_enemy_smaller_than_player", comparisons.wailord.front.after[0] < comparisons.wailord.back.after[0])
	for arena: Vector2 in [Vector2.ZERO, Vector2(-1, 100), Vector2(100, -1)]:
		_check("invalid_arena_safe", Layout.placement(arena, "front", Rect2(-10, -20, 20, 20)).gain == 0)
	_check("empty_envelope_safe", Layout.placement(Vector2(100, 100), "front", Rect2()).gain == 0)
	var report := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed, "failures": _failures,
		"species": metrics.size(), "arena_sizes": ARENAS.size(), "limited_front": limited_front, "limited_back": limited_back,
		"reference_arena": [674, 359], "comparisons": comparisons,
		"scope": "All opaque frame/state envelopes, perspective and safe bounds; not official game scale certification."}
	DirAccess.make_dir_recursive_absolute("res://.godot/layout_checks")
	var output := FileAccess.open("res://.godot/layout_checks/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	print("SPRITE_LAYOUT_RESULT " + JSON.stringify({"status": report.status, "passed": _passed, "failures": _failures, "limited_front": limited_front, "limited_back": limited_back, "wailord": comparisons.get("wailord", {})}))
	quit(0 if _failures.is_empty() else 1)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
