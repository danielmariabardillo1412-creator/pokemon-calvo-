extends "res://tests/gameplay/parallel_items_w02_mint_pilot02_20261109.gd"

# AUTONOMY_V1 W02, all ten rows. Inherits the independently certified pilot02
# transactional field-use, SaveV2, KO, invalid state and exact stat probes.
const DATA_V1 := "res://tests/fixtures/parallel_items/w02_autorun_v1.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run_autorun_v1")
	create_timer(600.0).timeout.connect(func():
		if not done:
			push_error("W02 AUTORUN V1 watchdog")
			quit(2))

func _run_autorun_v1() -> void:
	destination = "res://.godot/parallel_items/w02_autorun_v1"
	DirAccess.make_dir_recursive_absolute(destination)
	var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_V1))
	if not f is Dictionary:
		push_error("W02 AUTORUN V1 fixture missing")
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("AUTORUN V1 catalog overlay", Variants.apply(catalogs))
	check("AUTORUN V1 exact ordered ten rows", f.worker == "W02"
		and f.tanda == "01" and f.rows.size() == 10
		and f.modes == ["active", "reserve", "none"])
	var positives: int = 0
	var negatives: int = 0
	var level100: int = 0
	var sequential: int = 0
	var row_index: int = 0
	for spec: Dictionary in f.rows:
		row_index += 1
		check("AUTORUN V1 row numbering and canonical item", String(spec.block) == "%02d" % row_index
			and catalogs.item(StringName(spec.id)) != null)
		for mode: String in f.modes:
			current_case = String(spec.block) + "_" + String(spec.id) + "_" + mode
			var before: int = errors.size()
			_probe_pilot02(spec, mode)
			if errors.size() == before:
				if mode == "none": negatives += 1
				else: positives += 1
		current_case = String(spec.id) + "_level100"
		var old: int = errors.size()
		_probe_level100_02(spec)
		if errors.size() == old: level100 += 1
		current_case = String(spec.id) + "_replacement"
		old = errors.size()
		_probe_replacement02({"first": "lonely_mint", "second": String(spec.id),
			"original_nature": "hardy", "first_effective": "lonely",
			"last_effective": String(spec.target_nature)})
		if errors.size() == old: sequential += 1
	var passed: bool = errors.is_empty() and row_index == 10
	passed = passed and positives == 20 and negatives == 10
	passed = passed and level100 == 10 and sequential == 10
	done = true
	print("W02_AUTORUN_V1_GODOT ", "PASS" if passed else "FAIL",
		" rows=", row_index, " positive=", positives, " negative=", negatives,
		" level100=", level100, " sequential=", sequential, " checks=", checks)
	quit(0 if passed else 1)
