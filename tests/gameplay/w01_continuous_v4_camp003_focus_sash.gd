extends "res://tests/gameplay/item_automation_v28.gd"

# CAMP003 Focus Sash; distinct from Focus Band (random, non-consumable).
# Historical cases: full HP lethal seeds 1/19, partial HP lethal 19,
# nonlethal control 23, each active/none/reserve and genuine disk SaveV2.
const SASH_CASES := [
	{"id":"full_hp_1","seed":1,"species":"pikachu","level":1,"foe_level":100,"foe_move":"seismic_toss","condition":"full_lethal"},
	{"id":"full_hp_19","seed":19,"species":"pikachu","level":1,"foe_level":100,"foe_move":"seismic_toss","condition":"full_lethal"},
	{"id":"partial_hp_19","seed":19,"species":"pikachu","level":1,"foe_level":100,"foe_move":"seismic_toss","condition":"partial_lethal"},
	{"id":"nonlethal_23","seed":23,"species":"mew","level":100,"foe_level":1,"foe_move":"tackle","condition":"nonlethal"}
]
var sash_ok: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_sash")
	create_timer(900.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 Focus Sash CAMP003 timeout")
			quit(2))

func _sash_lane(spec: Dictionary, mode: String) -> Dictionary:
	current_case = "W01_V4_C003_SASH_" + String(spec.id) + "_" + mode
	var initial_errors: int = errors.size()
	automation = {
		"actor_species": String(spec.species),
		"level": int(spec.level),
		"format": "gen9calvounifiedv1",
		"seed": [int(spec.seed), 2, 3, 4],
		"physical_move": "growl",
		"special_move": "water_gun",
		"speed_target": "mew", "damage_target": "mew"
	}
	var prepared: Dictionary = _fixture({"id": "focus_sash"}, "physical_damage", mode)
	var owner: PlayerCollection = prepared.owner
	var actor: CreatureInstance = owner.owned_creature(&"own")
	_set_effect_moves(actor, "growl")
	if String(spec.condition) == "partial_lethal":
		actor.current_hp = actor.stats.max_hp - 1
	var expected_initial_hp: int = actor.current_hp
	var foe := _mon(&"mew", int(spec.foe_level), &"foe", [String(spec.foe_move)])
	check("two real Sash physical units " + current_case, _units(owner, &"focus_sash") == 2)
	check("scenario HP initialization " + current_case,
		expected_initial_hp > 0 and expected_initial_hp <= actor.stats.max_hp)
	var owner_original: Dictionary = _owner_data(owner)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, automation.seed)
	check("native battle started " + current_case, opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var initial_live: CreatureInstance = session.battle_state().creature(&"own")
	check("native HP equals owner before first move " + current_case,
		initial_live.current_hp == expected_initial_hp)
	check("native exclusive holder " + current_case,
		initial_live.held_item_id == (&"focus_sash" if mode == "active" else &"")
		and session.battle_state().creature(&"reserve").held_item_id == (&"focus_sash" if mode == "reserve" else &""))
	var action: Dictionary = await session.submit("move 1", session.revision)
	check("native legal turn accepted " + current_case, action.get("accepted", false))
	if not action.get("accepted", false):
		await session.close()
		return {"valid": false}
	var live: CreatureInstance = session.battle_state().creature(&"own")
	var hp_after: int = live.current_hp
	var spent: bool = live.held_item_consumed
	var should_spend: bool = String(spec.condition) == "full_lethal" and mode == "active"
	check("real Sash spent iff active at full HP against lethal attack " + current_case,
		spent == should_spend
		and not session.battle_state().creature(&"reserve").held_item_consumed)
	if String(spec.condition) == "full_lethal":
		check("full HP active holder survives at 1, controls KO " + current_case,
			hp_after == (1 if mode == "active" else 0))
	elif String(spec.condition) == "partial_lethal":
		check("partial HP cannot trigger Sash and faints " + current_case,
			hp_after == 0 and not spent)
	else:
		check("nonlethal hit leaves positive HP and Sash unspent " + current_case,
			hp_after > 0 and hp_after < expected_initial_hp and not spent)
	check("owner not mutated before native settlement " + current_case,
		_owner_data(owner) == owner_original)
	var snapshot: Dictionary = session.snapshot()
	var restored: Dictionary = await _restore_probe(session, owner,
		"c003_sash_" + String(spec.id) + "_" + mode, "Focus Sash native SaveV2 " + mode)
	if not restored.get("valid", false):
		return {"valid": false}
	session = restored.session
	check("native snapshot exact after SaveV2 " + current_case,
		session.snapshot() == snapshot)
	check("restored owner exact " + current_case,
		_owner_data(restored.owner) == owner_original)
	check("consumed flag and HP exact after SaveV2 " + current_case,
		session.battle_state().creature(&"own").current_hp == hp_after
		and session.battle_state().creature(&"own").held_item_consumed == spent)
	await session.close()
	return {"valid": errors.size() == initial_errors, "mode": mode, "hp": hp_after, "spent": spent}

func _run_sash() -> void:
	destination = "res://.godot/parallel_items/w01_v4_c003_sash"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical regional overlay applied", Variants.apply(catalogs))
	for spec: Dictionary in SASH_CASES:
		var lanes: Dictionary = {}
		for mode: String in ["active", "none", "reserve"]:
			lanes[mode] = await _sash_lane(spec, mode)
			if lanes[mode].get("valid", false):
				sash_ok += 1
		check("all 3 lanes valid " + String(spec.id),
			lanes.active.get("valid", false) and lanes.none.get("valid", false)
			and lanes.reserve.get("valid", false))
		if lanes.active.get("valid", false) and lanes.none.get("valid", false) and lanes.reserve.get("valid", false):
			check("reserve never spends Sash " + String(spec.id),
				not lanes.reserve.spent and not lanes.none.spent)
			if String(spec.condition) == "full_lethal":
				check("only active full-HP Sash prevents KO " + String(spec.id),
					lanes.active.hp == 1 and lanes.none.hp == 0 and lanes.reserve.hp == 0)
			else:
				check("Sash not consumed on partial HP/nonlethal " + String(spec.id),
					not lanes.active.spent)
	check("all 12 historical Sash native SaveV2 lanes", sash_ok == 12)
	done = true
	if errors.is_empty() and sash_ok == 12:
		print("W01_V4_C003_SASH PASS modes=12 checks=", checks)
		quit(0)
	else:
		print("W01_V4_C003_SASH FAIL modes=", sash_ok, " checks=", checks, " errors=", errors.size())
		quit(1)
