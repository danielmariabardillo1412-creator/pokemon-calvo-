extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Session = preload("res://modules/gameplay/showdown_adventure_session.gd")
const SubstituteRules = preload("res://modules/battle/application/substitute_rules.gd")
const OUT := "res://.godot/showdown_move_repair_checks/"
var catalog: DefinitionCatalog
var active: RefCounted
var checks := 0
var errors: Array[String] = []
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(name: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(name); push_error(name)
		if active != null: printerr(active.last_error)


func make_creature(id: String, moves: Array, species: String = "mew", level: int = 50) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(catalog.species(StringName(species)), level, catalog, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""
	return c


func _run() -> void:
	create_timer(180).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			check("watchdog", false); _finish())
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	await _transform_and_mimic()
	await _transformed_capture()
	await _substitutes()
	await _pain_split()
	await _max_moves()
	await _max_lifecycle()
	await _revival_choice()
	_finish()


func _transform_and_mimic() -> void:
	for move: String in ["transform", "mimic"]:
		var player := PlayerCollection.new(); var own := make_creature("own", [move, "tackle"], "ditto" if move == "transform" else "snorlax")
		player.party.add_creature(own); player.inventory.add(&"master_ball", 1)
		var initial := own.to_dict()
		active = Session.new(catalog, player)
		check("open temporary move " + move, await active.begin_wild(self, make_creature("wild", ["reflect", "tackle", "recover", "protect"])))
		var result: Dictionary = await active.submit("move 1", active.revision)
		check("temporary move accepted " + move, result.accepted)
		check("original owned data stays untouched " + move, own.to_dict() == initial)
		var saved: Dictionary = active.snapshot()
		var restored := Session.new(catalog, player)
		check("temporary state restores " + move, await restored.restore_saved(self, saved) and restored.snapshot() == saved)
		await restored.close()
		check("copied move usable " + move, (await active.submit("move 1", active.revision)).accepted)
		var caught: Dictionary = await active.capture(&"master_ball", active.revision)
		check("postbattle copy uses original identity " + move, caught.accepted and own.species_id == StringName(initial.species_id) and own.move_ids[0] == StringName(move))
		check("original move PP paid once, copied PP not persisted " + move, own.moveset[0].current_pp == int(initial.moveset[0].current_pp) - 1)
		await active.close()


func _transformed_capture() -> void:
	var player := PlayerCollection.new(); player.party.add_creature(make_creature("own", ["protect", "tackle", "reflect", "recover"], "charizard")); player.inventory.add(&"master_ball", 1)
	var wild := make_creature("wild_ditto", ["transform"], "ditto")
	var original := wild.to_dict()
	active = Session.new(catalog, player)
	check("wild Transform fixture opens", await active.begin_wild(self, wild))
	check("wild Transform can copy four slots from one", (await active.submit("move 1", active.revision)).accepted and active.battle_state().active_for_side(&"side_b").moveset.size() == 4)
	check("capture transformed target accepted", (await active.capture(&"master_ball", active.revision)).accepted)
	var captured := player.owned_creature(&"wild_ditto")
	check("captured Ditto restores original form stats moves and paid PP", captured != null and captured.species_id == &"ditto" and captured.stats.to_dict() == original.stats and captured.moveset.size() == 1 and captured.moveset[0].move_id == &"transform" and captured.moveset[0].current_pp == int(original.moveset[0].current_pp) - 1)
	await active.close()


func _substitutes() -> void:
	active = Backend.new(catalog)
	var own := make_creature("own", ["substitute"])
	check("doll fixture opens", await active.open(self, [own] as Array[CreatureInstance], [make_creature("enemy", ["tackle"], "snorlax")] as Array[CreatureInstance]))
	var result: Dictionary = await active.submit("move 1", active.revision)
	check("doll created and damaged same turn", result.accepted and result.events.any(func(e): return e.kind == BattleEvent.SUBSTITUTE_CREATED and int(e.metadata.hp) > 0) and result.events.any(func(e): return e.kind == BattleEvent.SUBSTITUTE_DAMAGED and e.amount > 0))
	var row: Dictionary = active._checkpoint.roster[0].pokemon[0]
	check("mirror doll HP equals native doll", SubstituteRules.hp(active.battle_state().active_for_side(&"side_a")) == int(row.substitute_hp))
	var saved: Dictionary = active.snapshot(); var restored := Backend.new(catalog)
	check("doll snapshot restores", await restored.restore_saved(self, saved) and SubstituteRules.hp(restored.battle_state().active_for_side(&"side_a")) == int(row.substitute_hp))
	await restored.close(); await active.close()
	active = Backend.new(catalog)
	check("Shed Tail fixture opens", await active.open(self, [make_creature("own", ["shed_tail"]), make_creature("reserve", ["tackle"])] as Array[CreatureInstance], [make_creature("enemy", ["reflect"])] as Array[CreatureInstance]))
	check("Shed Tail requests real replacement", (await active.submit("move 1", active.revision)).accepted and active.phase() == "player_switch")
	result = await active.submit("switch 2", active.revision)
	check("Shed Tail transfers native doll", result.accepted and SubstituteRules.hp(active.battle_state().active_for_side(&"side_a")) > 0 and result.events.any(func(e): return e.kind == BattleEvent.SUBSTITUTE_TRANSFERRED))
	await active.close()


func _pain_split() -> void:
	active = Backend.new(catalog)
	var own := make_creature("own", ["pain_split"]); own.current_hp = 20
	var enemy := make_creature("enemy", ["reflect"])
	check("Pain Split fixture opens", await active.open(self, [own] as Array[CreatureInstance], [enemy] as Array[CreatureInstance]))
	var result: Dictionary = await active.submit("move 1", active.revision)
	var expected := int((20 + enemy.stats.max_hp) / 2)
	check("Pain Split both HP exact", result.accepted and active.battle_state().active_for_side(&"side_a").current_hp == expected and active.battle_state().active_for_side(&"side_b").current_hp == expected)
	check("Pain Split emits both health changes", result.events.any(func(e): return e.kind == BattleEvent.HP_RECOVERED and e.target_id == &"own") and result.events.any(func(e): return e.kind == BattleEvent.DAMAGE_APPLIED and e.target_id == &"enemy"))
	await active.close()


func _max_moves() -> void:
	var moves := {"max_strike": "tackle", "max_flare": "flamethrower", "max_geyser": "surf", "max_lightning": "thunderbolt", "max_overgrowth": "energy_ball", "max_hailstorm": "ice_beam", "max_knuckle": "aura_sphere", "max_ooze": "sludge_bomb", "max_quake": "earth_power", "max_airstream": "air_slash", "max_mindstorm": "psychic", "max_flutterby": "bug_buzz", "max_rockfall": "ancient_power", "max_phantasm": "shadow_ball", "max_wyrmwind": "dragon_pulse", "max_darkness": "dark_pulse", "max_steelspike": "flash_cannon", "max_starfall": "moonblast", "max_guard": "protect"}
	for id: String in moves:
		active = Backend.new(catalog, "gen8customgame")
		var own := make_creature("own", [moves[id]])
		check("Gen8 opens " + id, await active.open(self, [own] as Array[CreatureInstance], [make_creature("enemy", ["tackle"], "mew", 100)] as Array[CreatureInstance]))
		var result: Dictionary = await active.submit("move 1 dynamax", active.revision)
		check("native Max action mapped " + id, result.accepted and result.events.any(func(e): return String(e.move_id) == id and e.kind == BattleEvent.ACTION_USED))
		check("native doubled HP projected " + id, active.battle_state().active_for_side(&"side_a").stats.max_hp == own.stats.max_hp * 2)
		await active.close()


func _max_lifecycle() -> void:
	var player := PlayerCollection.new(); var own := make_creature("own", ["protect", "tackle"])
	player.party.add_creature(own); player.inventory.add(&"master_ball", 1)
	active = Session.new(catalog, player, "gen8customgame")
	check("Max campaign fixture opens", await active.begin_wild(self, make_creature("wild", ["reflect"])))
	check("Max Guard accepted in session", (await active.submit("move 1 dynamax", active.revision)).accepted)
	var saved: Dictionary = active.snapshot()
	var restored := Session.new(catalog, player, "gen8customgame")
	check("mid-Dynamax checkpoint preserves profile native HP and RNG", await restored.restore_saved(self, saved) and restored.snapshot() == saved)
	await restored.close()
	var wrong := Backend.new(catalog)
	check("Gen8 snapshot cannot silently load as Gen9", not await wrong.restore_saved(self, saved) and wrong._client == null)
	var forged: Dictionary = saved.duplicate(true); forged.format = "gen9customgame"
	check("forged outer format cannot hide inner Gen8 state", not await wrong.restore_saved(self, forged) and wrong._client == null)
	check("capture during Dynamax accepted", (await active.capture(&"master_ball", active.revision)).accepted)
	check("Dynamax HP never leaks to campaign", own.current_hp == own.stats.max_hp and own.stats.max_hp < int(saved.native.native.sides[0].pokemon[0].maxhp))
	await active.close()


func _revival_choice() -> void:
	var player := PlayerCollection.new()
	var lead := make_creature("lead", ["tackle"], "caterpie", 5)
	player.party.add_creature(lead); player.party.add_creature(make_creature("healer", ["revival_blessing", "tackle"], "mew", 100)); player.inventory.add(&"master_ball", 1)
	active = Session.new(catalog, player)
	check("Revival Blessing live fixture opens", await active.begin_wild(self, make_creature("wild", ["psychic"], "mew", 80)))
	check("real in-battle KO creates replacement", (await active.submit("move 1", active.revision)).accepted and active.phase() == "player_switch")
	check("reserve enters after KO", (await active.submit("switch 2", active.revision)).accepted)
	check("Revival Blessing requests fainted identity", (await active.submit("move 1", active.revision)).accepted and active.is_reviving())
	check("native revival selection accepted", (await active.submit("switch 2", active.revision)).accepted and not active.is_reviving())
	check("revived identity has native HP", active.battle_state().creature(&"lead").current_hp > 0)
	check("capture settles revived HP and preserves owned reference", (await active.capture(&"master_ball", active.revision)).accepted and lead.current_hp > 0 and player.party.get_creature(&"lead") == lead)
	await active.close()


func _finish() -> void:
	if done: return
	done = true
	var f := FileAccess.open(OUT + "gameplay.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors}, "  ")); f.close()
	print("SHOWDOWN_MOVE_REPAIR ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
