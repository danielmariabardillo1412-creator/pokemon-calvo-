extends "res://tests/gameplay/w01_continuous_v4_plate_pilot.gd"

# Remaining 12 canonical Plates; inherit the V4 local plate QA helper only.
# Arceus form switching is deliberately outside the scope of this native-damage check.
const EXTRA_PLATES := {
	"fist_plate": "brick_break",
	"sky_plate": "air_slash",
	"toxic_plate": "sludge_bomb",
	"earth_plate": "earth_power",
	"stone_plate": "power_gem",
	"insect_plate": "bug_buzz",
	"spooky_plate": "shadow_ball",
	"iron_plate": "flash_cannon",
	"dread_plate": "dark_pulse",
	"mind_plate": "psychic",
	"icicle_plate": "ice_beam",
	"draco_plate": "dragon_pulse"
}

func _initialize() -> void:
	capture = false
	call_deferred("_run_remaining_plates")
	create_timer(1800.0).timeout.connect(func():
		if not done:
			push_error("W01 remaining 12 Plates QA timed out")
			quit(2))

func _run_remaining_plates() -> void:
	destination = "res://.godot/parallel_items/w01_v4_remaining_plates"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional overlay", Variants.apply(catalogs))
	var canonical_items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://modules/inventory/item_connections_v1.json"))
	for item_name: String in EXTRA_PLATES:
		check("canonical supported Plate " + item_name,
			canonical_items.get("holdable_ids", []).has(item_name))
		var start: int = plate_rows.size()
		for mode: String in ["active", "none", "reserve"]:
			var row: Dictionary = await _plate_lane(item_name, String(EXTRA_PLATES[item_name]), mode)
			plate_rows.append(row)
			if row.get("valid", false):
				plate_passed += 1
		if plate_rows.size() == start + 3:
			var active: Dictionary = plate_rows[start]
			var plain: Dictionary = plate_rows[start + 1]
			var bench: Dictionary = plate_rows[start + 2]
			check("type and holder exclusive bonus " + item_name,
				active.get("valid", false) and plain.get("valid", false) and bench.get("valid", false)
				and int(active.damage) > int(plain.damage)
				and int(plain.damage) == int(bench.damage))
	check("all remaining 12 Plates and three ownership modes", plate_passed == 36)
	done = true
	if errors.is_empty() and plate_passed == 36:
		print("W01_V4_PLATES_REMAINING PASS items=12 modes=36 checks=", checks)
		quit(0)
	else:
		print("W01_V4_PLATES_REMAINING FAIL modes=", plate_passed,
			" checks=", checks, " errors=", errors.size())
		quit(1)
