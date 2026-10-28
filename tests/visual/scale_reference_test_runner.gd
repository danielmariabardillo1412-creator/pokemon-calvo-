extends SceneTree

const Catalog = preload("res://scenes/visual/battle_sprite_catalog.gd")
var _passed := 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var references: Dictionary = Catalog.scale_references()
	var rows: Dictionary = Catalog.species_rows()
	_check("complete_reference_registry", references.size() == 1025)
	var matched := 0
	var adapted := 0
	var custom := 0
	for key: String in rows:
		for side: String in ["front", "back"]:
			var ref: Dictionary = references.get(key, {}).get(side, {})
			var view: Dictionary = rows[key].states.reposo[side]
			var label := key + "/" + side
			_check("entry/" + label, not ref.is_empty())
			if ref.is_empty():
				continue
			var factor := float(ref.factor)
			_check("finite_positive_factor/" + label, is_finite(factor) and factor > 0.0)
			match String(ref.status):
				"reference_dimensions_match":
					matched += 1
					_check("native_dimensions/" + label, ref.local_dimensions == ref.reference_dimensions)
					_check("cancel_height_normalization/" + label, is_equal_approx(float(view.unit_scale) * factor, 1.0))
				"reference_silhouette_adapted":
					adapted += 1
					_check("measured_size/" + label, ref.reference_median_opaque_size.size() == 2 and ref.local_median_opaque_size.size() == 2)
					var corrected := Vector2(float(ref.local_median_opaque_size[0]), float(ref.local_median_opaque_size[1])) * float(ref.silhouette_gain)
					_check("reference_footprint_fit/" + label, corrected.x <= float(ref.reference_median_opaque_size[0]) + 0.00001 and corrected.y <= float(ref.reference_median_opaque_size[1]) + 0.00001)
					_check("pinned_gif/" + label, String(ref.reference_gif_sha256).length() == 64)
				"custom_candidate_calibration_not_external_reference":
					custom += 1
					_check("custom_disclosed/" + label, bool(rows[key].provisional))
					_check("shared_custom_gain/" + label, is_equal_approx(float(references[key].front.factor), float(references[key].back.factor)))
				_:
					_check("recognized_status/" + label, false)
	_check("matched_view_count", matched == 2003)
	_check("adapted_view_count", adapted == 19)
	_check("custom_view_count", custom == 28)
	_check("wailord_front_uses_native_size", is_equal_approx(float(rows.wailord.states.reposo.front.unit_scale) * Catalog.presentation_scale(&"wailord", "front"), 1.0))
	# The same global frame scale must preserve authored relative proportions.
	var wailord_height := float(rows.wailord.states.reposo.front.regions[0][3])
	var joltik_height := float(rows.joltik.states.reposo.front.regions[0][3])
	_check("preserves_authored_wailord_joltik_ratio", is_equal_approx(wailord_height / joltik_height, 81.0 / 31.0))
	var result := {"status": "PASS" if _failures.is_empty() else "FAIL", "passed": _passed,
		"failures": _failures, "matched_views": matched, "adapted_views": adapted, "custom_views": custom}
	DirAccess.make_dir_recursive_absolute("res://.godot/scale_reference_checks")
	var output := FileAccess.open("res://.godot/scale_reference_checks/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t") + "\n")
	output.close()
	print("SCALE_REFERENCE_RESULT " + JSON.stringify(result))
	quit(0 if _failures.is_empty() else 1)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
	else:
		_failures.append(label)
		push_error("FAIL " + label)
