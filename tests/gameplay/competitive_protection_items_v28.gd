extends "res://tests/gameplay/item_closure_v3_test_runner.gd"

# Bloque 4 V28: objetos protectores para randomlocke competitivo.
# El simulador ya implementa estos tres efectos (V2). Aquí se demuestra
# efecto observado con/sin item y el recorrido físico desde la mochila.
const PROTECTION_OUT := "res://.godot/competitive_protection_v28/"
const PROTECTION_CASES := [
	{"item": "safety_goggles", "foe_move": "spore", "effect": "sleep"},
	{"item": "covert_cloak", "foe_move": "nuzzle", "effect": "paralysis"},
	{"item": "clear_amulet", "foe_move": "charm", "effect": "attack_stage"},
]
var protection_routes: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_protection")
	create_timer(300.0).timeout.connect(func():
		if not done:
			push_error("COMPETITIVE_PROTECTION_V28 timeout")
			quit(2))

func _run_protection() -> void:
	DirAccess.make_dir_recursive_absolute(PROTECTION_OUT)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("protection regional catalog overlay", Variants.apply(catalogs))
	var selection := service_for()
	for spec: Dictionary in PROTECTION_CASES:
		var id := StringName(spec.item)
		check("competitive item available and permitted " + String(id),
			catalogs.item(id) != null and selection.selection.content_allowed(id))
		await _native_protection(spec, true)
		await _native_protection(spec, false)
		await _map_protection(spec)
	var data := {"status": "PASS" if errors.is_empty() else "FAIL",
		"checks": checks, "errors": errors, "routes": protection_routes,
		"cases": PROTECTION_CASES.size(),
		"limits": ["Native tests observe protective effect against a matching foe move",
			"Map tests verify physical equip, native handoff and disk persistence; Caterpie does not trigger protection",
			"No doubles, suppression or Knock Off contexts added",
			"GPU/manual visuals not tested"]}
	var output := FileAccess.open(PROTECTION_OUT + "godot.json", FileAccess.WRITE)
	if output != null:
		output.store_string(JSON.stringify(data, "  "))
		output.close()
	done = true
	print("COMPETITIVE_PROTECTION_V28 ", data.status,
		" checks=", checks, " cases=", PROTECTION_CASES.size(),
		" errors=", errors.size())
	quit(0 if errors.is_empty() and checks >= 80 and protection_routes.size() == 9 else 1)

func _protected_state(c: CreatureInstance, effect: String) -> bool:
	match effect:
		"sleep", "paralysis": return c.status_state.persistent_id == &""
		"attack_stage": return c.stat_stages.get_stage(&"attack") == 0
	return false

func _unprotected_state(c: CreatureInstance, effect: String) -> bool:
	match effect:
		"sleep": return c.status_state.persistent_id == &"sleep"
		"paralysis": return c.status_state.persistent_id == &"paralysis"
		"attack_stage": return c.stat_stages.get_stage(&"attack") == -2
	return false

func _native_protection(spec: Dictionary, equipped: bool) -> void:
	var item := StringName(spec.item)
	var id := StringName("competitive_owner_" + String(spec.item))
	var own := _mon(&"mew", 50, id, ["reflect"])
	if equipped: own.held_item_id = item
	var foe := _mon(&"gengar", 50, StringName("competitive_foe_" + String(spec.item)), [String(spec.foe_move)])
	var owner := PlayerCollection.new()
	check("protection real owner added " + String(item), owner.party.add_creature(own))
	owner.inventory.add(&"master_ball", 1)
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [23, 19, 29, 43])
	check("protection native battle starts " + String(item) + " equipped=" + str(equipped), opened)
	if not opened:
		await session.close()
		return
	var original_owner: Dictionary = own.to_dict()
	var saved := session.snapshot()
	await session.close()
	session = Native.new(catalogs, owner, "gen9calvounifiedv1")
	var loaded: bool = await session.restore_saved(self, saved)
	check("protection native checkpoint restored " + String(item), loaded)
	if not loaded:
		await session.close()
		return
	var unchanged := session.snapshot()
	check("protection stale revision cannot mutate " + String(item),
		not (await session.submit("move 1", session.revision + 1)).accepted and session.snapshot() == unchanged)
	var result: Dictionary = await session.submit("move 1", session.revision)
	check("protection actual hostile move accepted " + String(item), result.accepted)
	if not result.accepted:
		await session.close()
		return
	var active: CreatureInstance = session.battle_state().creature(id)
	check("protection exact battle owner and held state " + String(item),
		active != null and active.held_item_id == (item if equipped else &"")
	if active != null:
		check("protection observable native effect " + String(item) + " equipped=" + str(equipped),
			_protected_state(active, String(spec.effect)) if equipped else _unprotected_state(active, String(spec.effect)))
	check("protection no early campaign mutation " + String(item),
		owner.owned_creature(id).to_dict() == original_owner and owner.inventory.quantity(&"master_ball") == 1)
	var settled: Dictionary = await session.capture(&"master_ball", session.revision)
	check("protection capture settlement publishes correctly " + String(item), settled.accepted and owner.inventory.quantity(&"master_ball") == 0)
	var published: Dictionary = owner.owned_creature(id).to_dict()
	check("protection same equipment after settlement " + String(item),
		owner.owned_creature(id).held_item_id == (item if equipped else &"")
		and not owner.owned_creature(id).held_item_consumed)
	check("protection no duplicate settlement " + String(item),
		not (await session.capture(&"master_ball", session.revision)).accepted
		and owner.owned_creature(id).to_dict() == published)
	protection_routes.append({"route": "native_effect_and_settlement", "item": String(item),
		"equipped": equipped, "effect": spec.effect})
	await session.close()

func _map_protection(spec: Dictionary) -> void:
	var item := StringName(spec.item)
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
	var own := _mon(&"mew", 50, own_id, ["quick_attack", "growl"])
	check("protection field owned identity " + String(item), owner.replace_owned_same_identity(own))
	owner.inventory.add(item, 2)
	check("protection physical bag opens " + String(item), scene.toggle_item_bag())
	var bag = scene._item_bag
	_select(bag, String(item))
	check("protection actual bag equip " + String(item), bag._apply("equip").accepted)
	bag.hide()
	await process_frame
	var bridge = scene._native_battles
	bridge.save_path = PROTECTION_OUT + "field_" + String(item) + ".json"
	check("protection field initial save " + String(item), bridge.save_game())
	check("protection field initial load " + String(item), await bridge.load_game())
	owner = scene.field_collection()
	check("protection exact owner/stock after reload " + String(item),
		owner.owned_creature(own_id).held_item_id == item
		and _physical_medicine(owner, item) == 2)
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view
	view._playback.set_process(false)
	var opened := view.session != null and view.session.battle_state() != null
	check("protection field native session active " + String(item), opened)
	if not opened:
		scene.queue_free()
		await process_frame
		return
	check("protection exact item enters battle " + String(item),
		view.session.battle_state().creature(own_id).held_item_id == item)
	check("protection field battle checkpoint saves " + String(item), bridge.save_game())
	check("protection field battle checkpoint restores " + String(item), await bridge.load_game())
	view._playback.set_process(false)
	check("protection held item survives battle restore " + String(item),
		view.session.battle_state().creature(own_id).held_item_id == item)
	var turn: Dictionary = await view.choose("move 1")
	check("protection field combat move accepted " + String(item), turn.accepted)
	if turn.accepted:
		await _drain_view(view)
		check("protection field victory " + String(item), view.session.completion_reason == "VICTORY")
		await bridge.leave_battle()
		owner = scene.field_collection()
		check("protection field retained item after victory " + String(item),
			owner.owned_creature(own_id).held_item_id == item
			and _physical_medicine(owner, item) == 2)
		check("protection field final save " + String(item), bridge.save_game())
		check("protection field final load " + String(item), await bridge.load_game())
		owner = scene.field_collection()
		check("protection field retained after disk reload " + String(item),
			owner.owned_creature(own_id).held_item_id == item
			and _physical_medicine(owner, item) == 2)
		protection_routes.append({"route": "real_bag_map_save", "item": String(item), "equipped": true})
	if view.session != null:
		await view.session.close()
	scene.queue_free()
	await process_frame
