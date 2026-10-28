extends RefCounted

## Explicit diagnostic-preset catalog and the seven selection cursors used by the
## field laboratory. It answers only "what should the owner try next"; it owns no
## scene, session, catalog, widget, service or Callable authority.
const ELEMENTAL_TEST_MOVES: Array[StringName] = [&"flamethrower", &"thunderbolt", &"ice_beam"]
const EXTERNAL_DAMAGE_TEST_MOVES: Array[StringName] = [&"circle_throw", &"dragon_tail", &"flip_turn", &"u_turn", &"volt_switch"]
const STATUS_SWITCH_TEST_MOVES: Array[StringName] = [&"roar", &"whirlwind", &"teleport", &"baton_pass", &"parting_shot"]
const WEATHER_TEST_MOVES: Array[StringName] = [&"rain_dance", &"hail", &"sandstorm", &"snowscape", &"chilly_reception"]
const SUBSTITUTE_TEST_MOVES: Array[StringName] = [&"substitute", &"shed_tail"]
const TRANSFORM_TEST_SPECIES: Array[StringName] = [&"wailord", &"pikachu", &"charizard"]

var _elemental_index := 0
var _external_index := 0
var _switch_index := 0
var _status_switch_index := 0
var _weather_index := 0
var _substitute_index := 0
var _transform_index := 0


func action_for_key(keycode: int) -> StringName:
	match keycode:
		KEY_F4: return &"tera"
		KEY_F5: return &"elemental"
		KEY_F6: return &"external"
		KEY_F7: return &"switch"
		KEY_F8: return &"status_switch"
		KEY_F9: return &"weather"
		KEY_F10: return &"substitute"
		KEY_F11: return &"transform"
		_: return &""


func request_for(action: StringName) -> Dictionary:
	match action:
		&"tera":
			return _request(&"tera_blast", false, false, false, false, &"")
		&"elemental":
			return _request(ELEMENTAL_TEST_MOVES[_elemental_index], false, false, false, false, &"")
		&"external":
			return _request(EXTERNAL_DAMAGE_TEST_MOVES[_external_index], false, false, false, false, &"")
		&"switch":
			return _request(EXTERNAL_DAMAGE_TEST_MOVES[_switch_index], true, false, false, false, &"")
		&"status_switch":
			return _request(STATUS_SWITCH_TEST_MOVES[_status_switch_index], true, false, false, false, &"")
		&"weather":
			return _request(WEATHER_TEST_MOVES[_weather_index], true, true, false, false, &"")
		&"substitute":
			return _request(SUBSTITUTE_TEST_MOVES[_substitute_index], true, false, true, false, &"")
		&"transform":
			return _request(&"transform", true, true, true, true, TRANSFORM_TEST_SPECIES[_transform_index])
		_:
			return {}


func commit_success(action: StringName) -> void:
	match action:
		&"elemental":
			_elemental_index = (_elemental_index + 1) % ELEMENTAL_TEST_MOVES.size()
		&"external":
			_external_index = (_external_index + 1) % EXTERNAL_DAMAGE_TEST_MOVES.size()
		&"switch":
			_switch_index = (_switch_index + 1) % EXTERNAL_DAMAGE_TEST_MOVES.size()
		&"status_switch":
			_status_switch_index = (_status_switch_index + 1) % STATUS_SWITCH_TEST_MOVES.size()
		&"weather":
			_weather_index = (_weather_index + 1) % WEATHER_TEST_MOVES.size()
		&"substitute":
			_substitute_index = (_substitute_index + 1) % SUBSTITUTE_TEST_MOVES.size()
		&"transform":
			_transform_index = (_transform_index + 1) % TRANSFORM_TEST_SPECIES.size()
		_:
			pass


func index_for(action: StringName) -> int:
	match action:
		&"elemental": return _elemental_index
		&"external": return _external_index
		&"switch": return _switch_index
		&"status_switch": return _status_switch_index
		&"weather": return _weather_index
		&"substitute": return _substitute_index
		&"transform": return _transform_index
		_:
			return 0


func describe_move(move_id: StringName) -> Dictionary:
	var external_damage := move_id in EXTERNAL_DAMAGE_TEST_MOVES
	var status_switch := move_id in STATUS_SWITCH_TEST_MOVES
	var weather := move_id in WEATHER_TEST_MOVES
	var substitute := move_id in SUBSTITUTE_TEST_MOVES
	var transform := move_id == &"transform"
	var supported := move_id == &"tera_blast" or move_id in ELEMENTAL_TEST_MOVES or external_damage or status_switch or weather or substitute or transform
	return {
		"supported": supported,
		"external_damage": external_damage,
		"status_switch": status_switch,
		"weather": weather,
		"substitute": substitute,
		"transform": transform,
	}


func _request(move_id: StringName, switch_rules: bool, weather_rules: bool, substitute_rules: bool, transform_rules: bool, target_species: StringName) -> Dictionary:
	return {
		"move_id": move_id,
		"switch_rules": switch_rules,
		"weather_rules": weather_rules,
		"substitute_rules": substitute_rules,
		"transform_rules": transform_rules,
		"target_species": target_species,
	}
