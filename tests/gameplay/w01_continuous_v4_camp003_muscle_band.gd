extends "res://tests/gameplay/w01_continuous_v4_plate_pilot.gd"

# CAMP003 Muscle Band. Reuse stage-only real native battle + disk SaveV2 lane,
# but assert physical-only damage rather than Plate-type bonus.
# Focused fixture equivalence for physical Tackle and special Water Gun (seed 19).
const DAMAGE_CASES := [
	{"id": "physical_tackle", "move": "tackle", "boosted": true},
	{"id": "special_water_gun", "move": "water_gun", "boosted": false}
]
var valid_lanes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_muscle_band")
	create_timer(750.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 CAMP003 Muscle Band timeout")
			quit(2))

func _run_muscle_band() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_muscle_band"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional variants", Variants.apply(catalogs))
	for scenario: Dictionary in DAMAGE_CASES:
		var lanes: Dictionary = {}
		for mode: String in ["active", "none", "reserve"]:
			current_case = "W01_C003_MUSCLE_" + String(scenario.id) + "_" + mode
			lanes[mode] = await _plate_lane("muscle_band", String(scenario.move), mode)
			if lanes[mode].get("valid", false):
				valid_lanes += 1
		check("all three native battle/settlement/SaveV2 lanes " + String(scenario.id),
			lanes.active.get("valid", false)
			and lanes.none.get("valid", false)
			and lanes.reserve.get("valid", false))
		if lanes.active.get("valid", false) and lanes.none.get("valid", false) and lanes.reserve.get("valid", false):
			check("reserve exactly equals no-item damage " + String(scenario.id),
				int(lanes.none.damage) == int(lanes.reserve.damage))
			if bool(scenario.boosted):
				check("Muscle Band boosts only active physical move",
					int(lanes.active.damage) > int(lanes.none.damage)
					and int(lanes.none.damage) > 0)
			else:
				check("Muscle Band cannot boost special Water Gun",
					int(lanes.active.damage) == int(lanes.none.damage)
					and int(lanes.none.damage) > 0)
	check("six real Muscle Band native+SaveV2 routes", valid_lanes == 6)
	done = true
	if errors.is_empty() and valid_lanes == 6:
		print("W01_V4_C003_MUSCLE_BAND PASS modes=6 checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_MUSCLE_BAND FAIL modes=", valid_lanes,
			" errors=", errors.size(), " checks=", checks)
		quit(1)
