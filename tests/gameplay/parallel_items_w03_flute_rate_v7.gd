extends SceneTree
# Isolated unit contract only; NOT evidence of bag / native steps / SaveV2.
const Flutes = preload("res://modules/overworld/field_flute_encounter_rate_v7.gd")
var checks := 0
var failures := 0

func check(name: String, condition: bool) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("W03_FLUTE_V7 FAIL: " + name)

func _initialize() -> void:
	var f = Flutes.new()
	var p: StringName = Flutes.PROFILE
	check("initial_none", f.active_id == &"")
	check("initial_rate", f.modified_chance_bp(3000, p) == 3000)
	check("wrong_profile_rejected", not f.activate(&"black_flute", &"gen9"))
	check("wrong_item_rejected", not f.activate(&"red_flute", p))
	check("activate_black", f.activate(&"black_flute", p))
	check("black_half", f.modified_chance_bp(3000, p) == 1500)
	check("black_edge_zero", f.modified_chance_bp(0, p) == 0)
	check("black_edge_max", f.modified_chance_bp(10000, p) == 5000)
	check("profile_guard", f.modified_chance_bp(3000, &"gen9") == 3000)
	check("idempotent_black", f.activate(&"black_flute", p) and f.modified_chance_bp(3000, p) == 1500)
	check("switch_white", f.activate(&"white_flute", p) and f.active_id == &"white_flute")
	check("white_one_half", f.modified_chance_bp(3000, p) == 4500)
	check("white_cap", f.modified_chance_bp(8000, p) == 10000)
	check("black_replaces_white", f.activate(&"black_flute", p) and f.modified_chance_bp(3000, p) == 1500)
	var saved: Dictionary = f.to_dict()
	var g = Flutes.new()
	check("snapshot_ok", g.restore(saved) and g.active_id == &"black_flute")
	check("corrupt_rejected", not g.restore({"schema_version": 1, "active_id": "red_flute"}) and g.active_id == &"black_flute")
	check("corrupt_version_rejected", not g.restore({"schema_version": 2, "active_id": "white_flute"}))
	check("legacy_default_clear", g.restore({"schema_version": 1, "active_id": ""}) and g.active_id == &"")
	check("clear", f.active_id == &"black_flute")
	f.clear()
	check("clear_effect", f.modified_chance_bp(3000, p) == 3000)
	print("W03_FLUTE_V7_UNIT checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
