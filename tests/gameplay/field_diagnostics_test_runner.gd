extends SceneTree

const SCRIPT := preload("res://scenes/visual/field_diagnostics.gd")
const ELEMENTAL := [&"flamethrower", &"thunderbolt", &"ice_beam"]
const EXTERNAL := [&"circle_throw", &"dragon_tail", &"flip_turn", &"u_turn", &"volt_switch"]
const STATUS_SWITCH := [&"roar", &"whirlwind", &"teleport", &"baton_pass", &"parting_shot"]
const WEATHER := [&"rain_dance", &"hail", &"sandstorm", &"snowscape", &"chilly_reception"]
const SUBSTITUTE := [&"substitute", &"shed_tail"]
const TRANSFORM := [&"wailord", &"pikachu", &"charizard"]
const CURSOR_NAMES := [
	"_elemental_index", "_external_index", "_switch_index", "_status_switch_index",
	"_weather_index", "_substitute_index", "_transform_index",
]

var checks := 0
var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)


func indices(diagnostic) -> Array:
	return [
		diagnostic.index_for(&"elemental"),
		diagnostic.index_for(&"external"),
		diagnostic.index_for(&"switch"),
		diagnostic.index_for(&"status_switch"),
		diagnostic.index_for(&"weather"),
		diagnostic.index_for(&"substitute"),
		diagnostic.index_for(&"transform"),
	]


func expect_request(label: String, request: Dictionary, move_id: StringName, switch_rules: bool, weather_rules: bool, substitute_rules: bool, transform_rules: bool, target_species: StringName) -> void:
	check(label + " key count", request.size() == 6)
	for key: String in ["move_id", "switch_rules", "weather_rules", "substitute_rules", "transform_rules", "target_species"]:
		check(label + " has " + key, request.has(key))
	check(label + " move type", typeof(request.get("move_id")) == TYPE_STRING_NAME)
	check(label + " target type", typeof(request.get("target_species")) == TYPE_STRING_NAME)
	check(label + " move", request.get("move_id") == move_id)
	check(label + " switch", request.get("switch_rules") == switch_rules and typeof(request.get("switch_rules")) == TYPE_BOOL)
	check(label + " weather", request.get("weather_rules") == weather_rules and typeof(request.get("weather_rules")) == TYPE_BOOL)
	check(label + " substitute", request.get("substitute_rules") == substitute_rules and typeof(request.get("substitute_rules")) == TYPE_BOOL)
	check(label + " transform", request.get("transform_rules") == transform_rules and typeof(request.get("transform_rules")) == TYPE_BOOL)
	check(label + " target", request.get("target_species") == target_species)


func exercise_sequence(action: StringName, moves: Array, switch_rules: bool, weather_rules: bool, substitute_rules: bool, transform_rules: bool, targets: Array = []) -> void:
	var diagnostic = SCRIPT.new()
	check(String(action) + " new instance starts at zero", indices(diagnostic) == [0, 0, 0, 0, 0, 0, 0])
	for i in moves.size():
		var expected_move := StringName(moves[i])
		var expected_target: StringName = &"" if targets.is_empty() else StringName(targets[i])
		var label := "%s/%d" % [String(action), i]
		var request: Dictionary = diagnostic.request_for(action)
		expect_request(label, request, expected_move, switch_rules, weather_rules, substitute_rules, transform_rules, expected_target)
		var repeated: Dictionary = diagnostic.request_for(action)
		check(label + " repeated request identical", JSON.stringify(repeated) == JSON.stringify(request))
		check(label + " request is fresh", not is_same(request, repeated))
		check(label + " no commit keeps cursor", diagnostic.index_for(action) == i)
		request["move_id"] = &"tackle"
		request["switch_rules"] = not switch_rules
		request["weather_rules"] = not weather_rules
		request["substitute_rules"] = not substitute_rules
		request["transform_rules"] = not transform_rules
		request["target_species"] = &"mew"
		check(label + " mutation does not leak", JSON.stringify(diagnostic.request_for(action)) == JSON.stringify(repeated))
		diagnostic.commit_success(action)
		check(label + " commit advances one", diagnostic.index_for(action) == (i + 1) % moves.size())
	check(String(action) + " full sequence wraps", diagnostic.index_for(action) == 0)
	diagnostic.commit_success(action)
	check(String(action) + " wrap plus one", diagnostic.index_for(action) == 1)
	var expected_indices := [0, 0, 0, 0, 0, 0, 0]
	expected_indices[[&"elemental", &"external", &"switch", &"status_switch", &"weather", &"substitute", &"transform"].find(action)] = 1
	check(String(action) + " other cursors untouched", indices(diagnostic) == expected_indices)


func expect_description(label: String, diagnostic, move_id: StringName, supported: bool, external_damage: bool, status_switch: bool, weather: bool, substitute: bool, transform: bool) -> void:
	var description: Dictionary = diagnostic.describe_move(move_id)
	check(label + " key count", description.size() == 6)
	var expected := {
		"supported": supported,
		"external_damage": external_damage,
		"status_switch": status_switch,
		"weather": weather,
		"substitute": substitute,
		"transform": transform,
	}
	check(label + " exact classification", description == expected)
	for key: String in expected:
		check(label + " boolean " + key, typeof(description.get(key)) == TYPE_BOOL)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/field_diagnostics_checks/")
	var diagnostic = SCRIPT.new()
	check("component instantiates", diagnostic != null)

	var key_map := {
		KEY_F4: &"tera", KEY_F5: &"elemental", KEY_F6: &"external", KEY_F7: &"switch",
		KEY_F8: &"status_switch", KEY_F9: &"weather", KEY_F10: &"substitute", KEY_F11: &"transform",
	}
	for keycode: int in key_map:
		check("key %d maps to %s" % [keycode, key_map[keycode]], diagnostic.action_for_key(keycode) == key_map[keycode])
	for keycode: int in [KEY_F1, KEY_F2, KEY_F3, KEY_F12, KEY_A, KEY_B, KEY_ESCAPE, KEY_ENTER, KEY_S, KEY_L, KEY_SPACE, KEY_0]:
		check("foreign key %d is empty" % keycode, diagnostic.action_for_key(keycode) == &"")

	check("initial cursors", indices(diagnostic) == [0, 0, 0, 0, 0, 0, 0])
	check("unknown request empty", diagnostic.request_for(&"unknown").is_empty())
	check("empty request empty", diagnostic.request_for(&"").is_empty())
	check("move id is not an action", diagnostic.request_for(&"tera_blast").is_empty())
	check("unknown index zero", diagnostic.index_for(&"unknown") == 0)
	diagnostic.commit_success(&"unknown")
	check("unknown commit changes nothing", indices(diagnostic) == [0, 0, 0, 0, 0, 0, 0])

	var tera: Dictionary = diagnostic.request_for(&"tera")
	expect_request("tera", tera, &"tera_blast", false, false, false, false, &"")
	check("tera is fresh", not is_same(tera, diagnostic.request_for(&"tera")))
	check("tera request repeats", JSON.stringify(diagnostic.request_for(&"tera")) == JSON.stringify(tera))
	for i in 3:
		diagnostic.commit_success(&"tera")
		check("tera has no cursor after commit %d" % i, indices(diagnostic) == [0, 0, 0, 0, 0, 0, 0])
	check("tera index zero", diagnostic.index_for(&"tera") == 0)

	exercise_sequence(&"elemental", ELEMENTAL, false, false, false, false)
	exercise_sequence(&"external", EXTERNAL, false, false, false, false)
	exercise_sequence(&"switch", EXTERNAL, true, false, false, false)
	exercise_sequence(&"status_switch", STATUS_SWITCH, true, false, false, false)
	exercise_sequence(&"weather", WEATHER, true, true, false, false)
	exercise_sequence(&"substitute", SUBSTITUTE, true, false, true, false)
	exercise_sequence(&"transform", [&"transform", &"transform", &"transform"], true, true, true, true, TRANSFORM)

	var independent = SCRIPT.new()
	var steps := {&"elemental": 1, &"external": 2, &"switch": 1, &"status_switch": 3, &"weather": 2, &"substitute": 1, &"transform": 2}
	for action: StringName in [&"elemental", &"external", &"switch", &"status_switch", &"weather", &"substitute", &"transform"]:
		for i in int(steps[action]):
			independent.commit_success(action)
	check("seven cursors independent", indices(independent) == [1, 2, 1, 3, 2, 1, 2])
	expect_request("independent elemental", independent.request_for(&"elemental"), ELEMENTAL[1], false, false, false, false, &"")
	expect_request("independent external", independent.request_for(&"external"), EXTERNAL[2], false, false, false, false, &"")
	expect_request("independent switch", independent.request_for(&"switch"), EXTERNAL[1], true, false, false, false, &"")
	expect_request("independent status", independent.request_for(&"status_switch"), STATUS_SWITCH[3], true, false, false, false, &"")
	expect_request("independent weather", independent.request_for(&"weather"), WEATHER[2], true, true, false, false, &"")
	expect_request("independent substitute", independent.request_for(&"substitute"), SUBSTITUTE[1], true, false, true, false, &"")
	expect_request("independent transform", independent.request_for(&"transform"), &"transform", true, true, true, true, TRANSFORM[2])
	independent.commit_success(&"external")
	check("external advances without switch", indices(independent) == [1, 3, 1, 3, 2, 1, 2])
	independent.commit_success(&"switch")
	check("switch advances without external", indices(independent) == [1, 3, 2, 3, 2, 1, 2])
	check("tera still has no cursor", independent.index_for(&"tera") == 0)

	var second = SCRIPT.new()
	check("new instance isolated", indices(second) == [0, 0, 0, 0, 0, 0, 0])
	check("first instance preserved", indices(independent) == [1, 3, 2, 3, 2, 1, 2])

	var cursor_names: Array[String] = []
	for property: Dictionary in diagnostic.get_property_list():
		if int(property.get("usage", 0)) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			cursor_names.append(String(property.get("name", "")))
			check("cursor property is int " + String(property.get("name", "")), int(property.get("type", 0)) == TYPE_INT)
	var expected_names: Array = CURSOR_NAMES.duplicate()
	cursor_names.sort(); expected_names.sort()
	check("component retains exactly seven cursors", cursor_names == expected_names)

	expect_description("tera_blast", diagnostic, &"tera_blast", true, false, false, false, false, false)
	for move: StringName in ELEMENTAL:
		expect_description(String(move), diagnostic, move, true, false, false, false, false, false)
	for move: StringName in EXTERNAL:
		expect_description(String(move), diagnostic, move, true, true, false, false, false, false)
	for move: StringName in STATUS_SWITCH:
		expect_description(String(move), diagnostic, move, true, false, true, false, false, false)
	for move: StringName in WEATHER:
		expect_description(String(move), diagnostic, move, true, false, false, true, false, false)
	for move: StringName in SUBSTITUTE:
		expect_description(String(move), diagnostic, move, true, false, false, false, true, false)
	expect_description("transform", diagnostic, &"transform", true, false, false, false, false, true)
	for move: StringName in [&"max_flare", &"unknown", &"", &"tackle", &"tera_blast_extra"]:
		expect_description("unsupported " + String(move), diagnostic, move, false, false, false, false, false, false)
	var first_description: Dictionary = diagnostic.describe_move(&"flamethrower")
	var second_description: Dictionary = diagnostic.describe_move(&"flamethrower")
	check("description is fresh", not is_same(first_description, second_description))
	first_description["weather"] = true
	check("description mutation does not leak", not bool(diagnostic.describe_move(&"flamethrower")["weather"]))

	var report := {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"checks": checks,
		"errors": errors,
		"catalog": {
			"elemental": ELEMENTAL, "external": EXTERNAL, "status_switch": STATUS_SWITCH,
			"weather": WEATHER, "substitute": SUBSTITUTE, "transform": TRANSFORM,
		},
	}
	var file := FileAccess.open("res://.godot/field_diagnostics_checks/contract.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  ", true) + "\n"); file.close()
	print("FIELD_DIAGNOSTICS_CONTRACT ", report.status, " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
