extends "res://tests/gameplay/item_automation_v28.gd"

# Isolated CAMP003 Rocky Helmet native contact recoil vs non-contact control.
# Source historical fixture: contact seeds 19/23, no-contact seed 19.
const HELMET_SCENARIOS := [
	{"id": "contact_19", "move": "tackle", "seed": 19, "contact": true},
	{"id": "contact_23", "move": "tackle", "seed": 23, "contact": true},
	{"id": "noncontact_19", "move": "water_gun", "seed": 19, "contact": false}
]
var passed_lanes: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_helmet")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 CAMP003 Rocky Helmet timeout")
			quit(2))

func _helmet_lane(scenario: Dictionary, mode: String) -> Dictionary:
	current_case = "W01_V4_HELMET_" + String(scenario.id) + "_" + mode
	var old_errors: int = errors.size()
	automation = {"actor_species": "mew", "level": 100,
		"format": "gen9calvounifiedv1",
		"seed": [int(scenario.seed), 2, 3, 4],
		"physical_move": "reflect", "special_move": "water_gun",
		"speed_target": "mew", "damage_target": "mew"}
	var prepared: Dictionary = _fixture({"id": "rocky_helmet"}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	_set_effect_moves(owner.owned_creature(&"own"), "reflect")
	var foe: CreatureInstance = _mon(&"mew", 100, &"foe", [String(scenario.move)])
	var original: Dictionary = _owner_data(owner)
	check("real Helmet physical units " + current_case, _units(owner, &"rocky_helmet") == 2)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var started: bool = await session.begin_wild(self, foe, automation.seed)
	check("Helmet native battle starts " + current_case, started)
	if not started:
		await session.close()
		return {"valid": false}
	check("native exact holder " + current_case,
		session.battle_state().creature(&"own").held_item_id == (&"rocky_helmet" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id == (&"rocky_helmet" if mode == "reserve" else &""))
	var initial_foe_hp: int = session.battle_state().creature(&"foe").current_hp
	var initial_actor_hp: int = session.battle_state().creature(&"own").current_hp
	var command: Dictionary = await session.submit("move 1", session.revision)
	check("native Reflect turn accepted " + current_case, command.get("accepted", false))
	if not command.get("accepted", false):
		await session.close()
		return {"valid": false}
	var recoil: int = initial_foe_hp - session.battle_state().creature(&"foe").current_hp
	var damage_taken: int = initial_actor_hp - session.battle_state().creature(&"own").current_hp
	check("no attacker self-damage except Helmet recoil " + current_case,
		recoil >= 0)
	check("Rocky Helmet does not consume " + current_case,
		not session.battle_state().creature(&"own").held_item_consumed
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	check("no premature owner settlement " + current_case, _owner_data(owner) == original)
	var snapshot: Dictionary = session.snapshot()
	var restored: Dictionary = await _restore_probe(session, owner,
		"c003_helmet_" + String(scenario.id) + "_" + mode,
		"Rocky Helmet SaveV2 " + mode)
	if not restored.get("valid", false):
		return {"valid": false}
	session = restored.session
	check("battle exact after SaveV2 " + current_case, session.snapshot() == snapshot)
	check("owner exact after SaveV2 " + current_case, _owner_data(restored.owner) == original)
	check("real native HP damage survives SaveV2 " + current_case,
		session.battle_state().creature(&"foe").current_hp == initial_foe_hp - recoil
		and session.battle_state().creature(&"own").current_hp == initial_actor_hp - damage_taken)
	await session.close()
	return {"valid": errors.size() == old_errors,
		"recoil": recoil, "damage_taken": damage_taken, "mode": mode}

func _run_helmet() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_helmet"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional overlay", Variants.apply(catalogs))
	for scenario: Dictionary in HELMET_SCENARIOS:
		var results: Dictionary = {}
		for mode: String in ["active", "none", "reserve"]:
			results[mode] = await _helmet_lane(scenario, mode)
			if results[mode].get("valid", false):
				passed_lanes += 1
		check("all modes valid " + String(scenario.id),
			results.active.get("valid", false) and results.none.get("valid", false)
			and results.reserve.get("valid", false))
		if results.active.get("valid", false) and results.none.get("valid", false) and results.reserve.get("valid", false):
			check("reserve has same HP damage as no item " + String(scenario.id),
				results.none.damage_taken == results.reserve.damage_taken)
			if bool(scenario.contact):
				check("contact triggers recoil only on active Helmet holder " + String(scenario.id),
					results.active.recoil > 0 and results.none.recoil == 0
					and results.reserve.recoil == 0
					and results.active.damage_taken > 0)
			else:
				check("noncontact never triggers Helmet " + String(scenario.id),
					results.active.recoil == 0 and results.none.recoil == 0
					and results.reserve.recoil == 0
					and results.active.damage_taken > 0)
	check("nine native Helmet SaveV2 lanes", passed_lanes == 9)
	done = true
	if errors.is_empty() and passed_lanes == 9:
		print("W01_V4_C003_HELMET PASS modes=9 checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_HELMET FAIL modes=", passed_lanes,
			" checks=", checks, " errors=", errors.size())
		quit(1)
