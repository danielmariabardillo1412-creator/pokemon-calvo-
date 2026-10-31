extends "res://tests/gameplay/progression_items_v18.gd"

# V3 hereda las utilidades de fabricación/sesiones V18, no sus aserciones
# históricas. Se ejecutan aparte sin relajar sus resultados.
const OUT_V3 := "res://.godot/item_closure_v3/"
const Rewards = preload("res://modules/creatures/progression/battle_ev_rewards.gd")
const POWER_ITEMS := {
	"power_weight": "hp", "power_bracer": "attack", "power_belt": "defense",
	"power_lens": "special_attack", "power_band": "special_defense",
	"power_anklet": "speed",
}

func _initialize() -> void:
	capture = false
	call_deferred("_run_v3")
	create_timer(300).timeout.connect(func():
		if not done:
			push_error("ITEM_CLOSURE_V3 timeout")
			quit(2))

func _run_v3() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_V3)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional catalog overlay", Variants.apply(catalogs))
	_domain_ev()
	await _native_ev()
	await _native_ev_remaining_training_items()
	await _map_power()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks,
		"errors": errors, "routes": routes, "profile": "Gen VII-IX EV; legacy Macho Brace",
		"limits": ["Bonus held item only when unchanged from start to finish",
			"No per-KO held-item/suppression history is persisted",
			"XP recipients retain calvo_progression_v1, no Exp. Share"]}
	var file := FileAccess.open(OUT_V3 + "godot.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	done = true
	print("ITEM_CLOSURE_V3 ", report.status, " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() and checks >= 55 else 1)

func _defeats(species_ids: Array, level: int = 10) -> BattleOutcome:
	var result := BattleOutcome.new()
	result.winner_side_id = &"side_a"
	for sid in species_ids:
		var species: CreatureSpecies = catalogs.species(StringName(sid))
		if species != null:
			result.defeated.append({"species_id": String(sid), "base_experience": species.base_experience, "level": level})
	return result

func _sum_evs(c: CreatureInstance) -> int:
	var total := 0
	for key: String in ProgressionRuleset.STAT_KEYS:
		total += int(c.evs.get(key, 0))
	return total

func _domain_ev() -> void:
	var rules := ProgressionRuleset.new()
	var foe: CreatureSpecies = catalogs.species(&"caterpie")
	check("canonical Caterpie EV yield", foe != null and int(foe.ev_yield.get("hp", 0)) > 0)
	if foe == null:
		return
	var base_hp := int(foe.ev_yield.get("hp", 0))
	var one := _defeats(["caterpie"])
	var two := _defeats(["caterpie", "caterpie"])
	var plain := _mon(&"mew", 50, &"plain", ["growl"])
	var before_xp := plain.experience
	ProgressionSystem.reconcile_battle_result([plain], one, catalogs, rules)
	check("plain defeats award base EV", int(plain.evs.get("hp", 0)) == base_hp)
	check("plain XP uses unchanged formula", plain.experience - before_xp == rules.experience_for_defeats(one.defeated, 1))
	check("plain no fictional Power bonus", _sum_evs(plain) == base_hp)
	for item: String in POWER_ITEMS:
		var c := _mon(&"mew", 50, StringName(item), ["growl"])
		c.held_item_id = StringName(item)
		c.current_hp -= 5
		var missing_hp := c.stats.max_hp - c.current_hp
		var starts := {String(c.instance_id): item}
		var start_xp := c.experience
		var gained := Rewards.award(c, one.defeated, catalogs, rules, starts)
		var stat: String = POWER_ITEMS[item]
		check("Power bonus stat " + item, int(c.evs.get(stat, 0)) == int(foe.ev_yield.get(stat, 0)) + 8)
		check("Power respects base yield " + item, _sum_evs(c) == base_hp + 8)
		check("Power report matches gained EV " + item, int(gained.get(stat, 0)) == int(c.evs.get(stat, 0)))
		check("Power keeps XP untouched " + item, c.experience == start_xp)
		check("Power stats and HP reconciled " + item, c.stats.to_dict() == StatCalculator.compute(catalogs.species(c.species_id).base_stat_block(), c.ivs, c.evs, c.nature_id, c.level).to_dict() and c.stats.max_hp - c.current_hp == missing_hp)
		check("Power item not spent " + item, c.held_item_id == StringName(item) and not c.held_item_consumed)
		var restored := CreatureInstance.from_dict(c.to_dict())
		check("Power owner EVs saved and restored " + item, restored.evs == c.evs and restored.held_item_id == c.held_item_id)
		var repeat := _mon(&"mew", 50, StringName(item + "_multi"), ["growl"])
		repeat.held_item_id = StringName(item)
		var extra := Rewards.award(repeat, two.defeated, catalogs, rules, {String(repeat.instance_id): item})
		check("Power accumulates for two foes " + item, _sum_evs(repeat) == 2 * (base_hp + 8) and _sum_evs(repeat) == _sum_dict(extra))
	var brace := _mon(&"mew", 50, &"brace", ["growl"])
	brace.held_item_id = &"macho_brace"
	var brace_gain := Rewards.award(brace, two.defeated, catalogs, rules, {"brace": "macho_brace"})
	check("Macho Brace doubles each foe", _sum_evs(brace) == 4 * base_hp and _sum_dict(brace_gain) == 4 * base_hp)
	var no_bonus := _mon(&"mew", 50, &"changed", ["growl"])
	no_bonus.held_item_id = &"power_weight"
	Rewards.award(no_bonus, one.defeated, catalogs, rules, {"changed": "macho_brace"})
	check("changed item never gets inferred bonus", _sum_evs(no_bonus) == base_hp)
	var lost := _mon(&"mew", 50, &"lost", ["growl"])
	lost.held_item_id = &"power_weight"
	lost.held_item_consumed = true
	Rewards.award(lost, one.defeated, catalogs, rules, {"lost": "power_weight"})
	check("lost item never grants bonus", _sum_evs(lost) == base_hp)
	var untracked := _mon(&"mew", 50, &"untracked", ["growl"])
	untracked.held_item_id = &"power_weight"
	Rewards.award(untracked, one.defeated, catalogs, rules)
	check("newly acquired item does not gain bonus", _sum_evs(untracked) == base_hp)
	var cap := _mon(&"mew", 50, &"cap", ["growl"])
	cap.evs = {"hp": 251, "attack": 252, "defense": 6}
	cap.recalculate_stats(catalogs.species(cap.species_id), rules)
	cap.current_hp = cap.stats.max_hp
	cap.held_item_id = &"power_weight"
	Rewards.award(cap, two.defeated, catalogs, rules, {"cap": "power_weight"})
	check("total cap 510 and individual cap 252", _sum_evs(cap) == 510 and int(cap.evs.hp) == 252)
	var no_room := cap.to_dict()
	Rewards.award(cap, two.defeated, catalogs, rules, {"cap": "power_weight"})
	check("full EV cap refuses further mutation", cap.to_dict() == no_room)
	var hundred := _mon(&"mew", 100, &"hundred", ["growl"])
	hundred.held_item_id = &"power_bracer"
	before_xp = hundred.experience
	var max_events := ProgressionSystem.reconcile_battle_result([hundred], one, catalogs, rules, {"hundred": "power_bracer"})
	check("level 100 accepts EV but not XP", hundred.experience == before_xp and _sum_evs(hundred) == base_hp + 8 and max_events.is_empty())
	var knocked := _mon(&"mew", 50, &"ko", ["growl"])
	knocked.current_hp = 0
	var live := _mon(&"mew", 50, &"live", ["growl"])
	var other := _mon(&"mew", 50, &"other", ["growl"])
	live.held_item_id = &"power_weight"
	var old_live_xp := live.experience
	var old_other_xp := other.experience
	ProgressionSystem.reconcile_battle_result([live, other, knocked], one, catalogs, rules, {"live": "power_weight"})
	var existing_share := rules.experience_for_defeats(one.defeated, 2)
	check("XP receiver set unchanged", live.experience - old_live_xp == existing_share and other.experience - old_other_xp == existing_share)
	check("EVs to both eligible living party members", _sum_evs(live) == base_hp + 8 and _sum_evs(other) == base_hp)
	check("fainted party member never earns EV", _sum_evs(knocked) == 0)
	var invalid := _mon(&"mew", 50, &"invalid", ["growl"])
	invalid.evs = {"hp": 253}
	var before_invalid := invalid.to_dict()
	Rewards.award(invalid, one.defeated, catalogs, rules)
	check("invalid original EV state rejected unchanged", invalid.to_dict() == before_invalid)
	var no_foe := _mon(&"mew", 50, &"missing_species", ["growl"])
	Rewards.award(no_foe, [{"base_experience": 100, "level": 7}], catalogs, rules)
	check("unidentified foe cannot mint EV", _sum_evs(no_foe) == 0)
	routes.append({"family": "EV_DOMAIN", "ids": ["macho_brace"] + POWER_ITEMS.keys(), "foes": ["caterpie"], "generational_profile": "Gen VII-IX"})

func _sum_dict(values: Dictionary) -> int:
	var total := 0
	for v in values.values():
		total += int(v)
	return total

func _native_ev() -> void:
	var own := _mon(&"mew", 50, &"native_power_owner", ["quick_attack", "growl"])
	own.held_item_id = &"power_weight"
	var foe := _mon(&"caterpie", 50, &"native_power_foe", ["growl"])
	foe.current_hp = 1
	var owner := PlayerCollection.new()
	check("native EV party owner accepted", owner.party.add_creature(own))
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [23, 19, 29, 43])
	check("Power item native battle starts", opened)
	if not opened:
		await session.close()
		return
	var old_ev := _sum_evs(own)
	var old_xp := own.experience
	var saved := session.snapshot()
	await session.close()
	session = Native.new(catalogs, owner, "gen9calvounifiedv1")
	var loaded: bool = await session.restore_saved(self, saved)
	check("native Power checkpoint restore", loaded)
	if not loaded:
		await session.close()
		return
	var before := session.snapshot()
	check("stale revision rejected without mutation", not (await session.submit("move 1", session.revision + 1)).accepted and session.snapshot() == before and _sum_evs(own) == old_ev)
	var action: Dictionary = await session.submit("move 1", session.revision)
	check("native actual foe defeated", action.accepted and session.phase() == "finished")
	check("no EV published before settlement", _sum_evs(own) == old_ev)
	if not action.accepted or session.phase() != "finished":
		await session.close()
		return
	var settled: Dictionary = session.settle_finished_battle()
	var hp_yield := int(catalogs.species(&"caterpie").ev_yield.get("hp", 0))
	check("native Power EV in owned creature", settled.accepted and int(own.evs.get("hp", 0)) == hp_yield + 8 and own.experience > old_xp)
	check("held item retained after real battle", own.held_item_id == &"power_weight" and not own.held_item_consumed)
	var final_owner := own.to_dict()
	check("native double-settlement cannot duplicate EV", not session.settle_finished_battle().accepted and own.to_dict() == final_owner)
	var persisted := CreatureInstance.from_dict(final_owner)
	var serialized_again := persisted.to_dict()
	check("native EV persists in current save schema", serialized_again.evs == final_owner.evs and serialized_again.stats == final_owner.stats and int(persisted.evs.get("hp", 0)) == hp_yield + 8)
	routes.append({"family": "EV_NATIVE", "item": "power_weight", "foe": "caterpie", "restored": loaded, "settled": settled.accepted})
	await session.close()
	# Segundo encuentro: los EV previos son persistentes y el siguiente KO
	# suma exactamente otro bloque sin duplicar el primero.
	var second_foe := _mon(&"caterpie", 50, &"native_power_foe_2", ["growl"])
	second_foe.current_hp = 1
	session = Native.new(catalogs, owner, "gen9calvounifiedv1")
	var next_open: bool = await session.begin_wild(self, second_foe, [29, 19, 23, 43])
	check("second battle reads trained EVs and same owner", next_open)
	if next_open:
		var second_action: Dictionary = await session.submit("move 1", session.revision)
		check("second battle really defeats the foe", second_action.accepted and session.phase() == "finished")
		if second_action.accepted and session.phase() == "finished":
			var second_close: Dictionary = session.settle_finished_battle()
			check("second battle adds exactly one bonus", second_close.accepted and int(own.evs.get("hp", 0)) == 2 * (hp_yield + 8))
			var second_snapshot := own.to_dict()
			check("second settlement idempotent", not session.settle_finished_battle().accepted and own.to_dict() == second_snapshot)
			routes.append({"family": "EV_NEXT_BATTLE", "item": "power_weight", "foe": "caterpie", "total_hp_ev": int(own.evs.get("hp", 0))})
	await session.close()

func _native_ev_remaining_training_items() -> void:
	# Complementa la ruta completa power_weight (mochila/mapa/guardado) sin
	# declarar que estos otros equipables hayan recorrido también la mochila.
	# Cada caso atraviesa el motor real, checkpoint, cierre e instancia persistida.
	var training_items: Array[String] = [
		"power_bracer", "power_belt", "power_lens",
		"power_band", "power_anklet", "macho_brace",
	]
	for item: String in training_items:
		var own := _mon(&"mew", 50, StringName("native_training_" + item), ["quick_attack", "growl"])
		own.held_item_id = StringName(item)
		var foe := _mon(&"caterpie", 50, StringName("native_foe_" + item), ["growl"])
		foe.current_hp = 1
		var owner := PlayerCollection.new()
		check("training native accepts original owner " + item, owner.party.add_creature(own))
		var battle := Native.new(catalogs, owner, "gen9calvounifiedv1")
		var opened: bool = await battle.begin_wild(self, foe, [23, 19, 29, 43])
		check("training native opens " + item, opened)
		if not opened:
			await battle.close()
			continue
		var before: Dictionary = own.evs.duplicate(true)
		var before_xp := own.experience
		var saved := battle.snapshot()
		await battle.close()
		battle = Native.new(catalogs, owner, "gen9calvounifiedv1")
		var restored: bool = await battle.restore_saved(self, saved)
		check("training battle restores " + item, restored)
		if not restored:
			await battle.close()
			continue
		var action: Dictionary = await battle.submit("move 1", battle.revision)
		check("training native actually defeats foe " + item, action.accepted and battle.phase() == "finished")
		check("training native no premature EV " + item, own.evs == before)
		if not action.accepted or battle.phase() != "finished":
			await battle.close()
			continue
		var settled: Dictionary = battle.settle_finished_battle()
		check("training settlement and original XP " + item, settled.accepted and own.experience > before_xp)
		var expected_total := 0
		for key: String in ProgressionRuleset.STAT_KEYS:
			var expected := int(catalogs.species(&"caterpie").ev_yield.get(key, 0))
			if item == "macho_brace":
				expected *= 2
			elif String(POWER_ITEMS.get(item, "")) == key:
				expected += 8
			expected_total += expected
			check("training exact native EV " + item + "/" + key,
				int(own.evs.get(key, 0)) == int(before.get(key, 0)) + expected)
		check("training EV total " + item, _sum_evs(own) == expected_total)
		check("training original held item survives " + item,
			own.held_item_id == StringName(item) and not own.held_item_consumed)
		var final_state: Dictionary = own.to_dict()
		check("training no duplicate settlement " + item,
			not battle.settle_finished_battle().accepted and own.to_dict() == final_state)
		var persisted := CreatureInstance.from_dict(final_state)
		# El contrato del schema es el diccionario serializado: .to_dict()
		# normaliza nombres de claves/tipos de Variant, no objetos internos.
		var roundtrip: Dictionary = persisted.to_dict()
		check("training save round-trip EV " + item, roundtrip.evs == final_state.evs)
		check("training save round-trip stats " + item, roundtrip.stats == final_state.stats)
		check("training save round-trip held item " + item,
			roundtrip.held_item_id == final_state.held_item_id
			and roundtrip.held_item_consumed == final_state.held_item_consumed)
		routes.append({"family": "EV_NATIVE_ADDITIONAL", "item": item,
			"foe": "caterpie", "restored": restored, "settled": settled.accepted})
		await battle.close()

func _map_power() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100
	config.wild_species_id = "caterpie"
	config.wild_min_level = 1
	config.wild_max_level = 1
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var own_id: StringName = owner.party.get_creatures()[0].instance_id
	var creature := _mon(&"mew", 50, own_id, ["quick_attack", "growl"])
	check("map Power owner replacement", owner.replace_owned_same_identity(creature))
	owner.inventory.add(&"power_weight", 2)
	check("map real item bag opens", scene.toggle_item_bag())
	var bag = scene._item_bag
	_select(bag, "power_weight")
	check("real bag equips Power item", bag._apply("equip").accepted)
	bag.hide()
	await process_frame
	var bridge = scene._native_battles
	bridge.save_path = OUT_V3 + "map_power_save.json"
	check("Power map saved before battle", bridge.save_game())
	check("Power map loaded before battle", await bridge.load_game())
	owner = scene.field_collection()
	var before_ev := int(owner.owned_creature(own_id).evs.get("hp", 0))
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view
	view._playback.set_process(false)
	check("Power map battle activated", view.session != null and view.session.battle_state() != null)
	if view.session == null:
		scene.queue_free()
		await process_frame
		return
	check("Power battle checkpoint saves", bridge.save_game())
	check("Power battle checkpoint restores", await bridge.load_game())
	view._playback.set_process(false)
	var action: Dictionary = await view.choose("move 1")
	check("map Power attack accepted", action.accepted)
	if not action.accepted:
		await view.session.close()
		scene.queue_free()
		await process_frame
		return
	await _drain_view(view)
	check("Power map finishes by victory", view.session.completion_reason == "VICTORY")
	await bridge.leave_battle()
	owner = scene.field_collection()
	var expected := int(catalogs.species(&"caterpie").ev_yield.get("hp", 0)) + 8
	check("map Power grants exact EVs", int(owner.owned_creature(own_id).evs.get("hp", 0)) - before_ev == expected)
	check("real bag unit physically preserved", _physical_medicine(owner, &"power_weight") == 2)
	check("Power map final save", bridge.save_game())
	check("Power map final load", await bridge.load_game())
	check("map EV and item survive reload", int(scene.field_collection().owned_creature(own_id).evs.get("hp", 0)) == before_ev + expected and _physical_medicine(scene.field_collection(), &"power_weight") == 2)
	routes.append({"family": "EV_MAP_BAG_SAVE", "item": "power_weight", "foe": "caterpie"})
	if view.session != null:
		await view.session.close()
	scene.queue_free()
	await process_frame
