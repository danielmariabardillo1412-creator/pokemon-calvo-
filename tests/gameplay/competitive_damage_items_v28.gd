extends "res://tests/gameplay/item_closure_v3_test_runner.gd"

# Bloque 5: solo objetos oficiales de daño sin activación por habilidades.
# Los doce enfrentamientos usan ability_id vacío para aislar el objeto.
const DAMAGE_OUT := "res://.godot/competitive_damage_v28/"
const DAMAGE_ITEMS := [
	{"id": "muscle_band", "effective_move": "tackle",
		"control_move": "confusion", "foe": "snorlax"},
	{"id": "wise_glasses", "effective_move": "confusion",
		"control_move": "tackle", "foe": "snorlax"},
	{"id": "expert_belt", "effective_move": "thunder_shock",
		"control_move": "tackle", "foe": "gyarados"},
]
var damage_routes: Array = []

func _initialize() -> void:
	capture = false
	call_deferred("_run_damage")
	create_timer(300.0).timeout.connect(func():
		if not done:
			push_error("COMPETITIVE_DAMAGE_V28 timeout")
			quit(2))

func _run_damage() -> void:
	DirAccess.make_dir_recursive_absolute(DAMAGE_OUT)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("damage catalog overlay", Variants.apply(catalogs))
	var selection := service_for()
	for spec: Dictionary in DAMAGE_ITEMS:
		var id := StringName(spec.id)
		check("official item locally allowed " + String(id),
			catalogs.item(id) != null and selection.selection.content_allowed(id))
		for positive in [true, false]:
			var move: String = spec.effective_move
			if not positive: move = spec.control_move
			var base: Dictionary = await _native_damage(spec, move, false)
			var boost: Dictionary = await _native_damage(spec, move, true)
			check("native pair has comparable valid damage " + String(id) + "/" + move,
				base.get("valid", false) and boost.get("valid", false)
				and int(base.get("damage", 0)) > 0 and int(boost.get("damage", 0)) > 0)
			if base.get("valid", false) and boost.get("valid", false):
				if positive:
					check("official matching move boosted " + String(id),
						int(boost.damage) > int(base.damage))
				else:
					check("nonmatching move not boosted " + String(id),
						int(boost.damage) == int(base.damage))
			damage_routes.append({"type": "real_native_damage_pair",
				"item": String(id), "move": move, "positive": positive,
				"normal": base.get("damage", -1), "equipped": boost.get("damage", -1)})
		await _map_damage_item(id)
	var outcome: Dictionary = {"status": "PASS" if errors.is_empty() else "FAIL",
		"checks": checks, "errors": errors, "routes": damage_routes,
		"ids": DAMAGE_ITEMS.size(),
		"limits": ["No ability/item interactions asserted (empty ability only)",
			"Three physical map routes use Caterpie, not matching damage probes",
			"No GPU/manual visuals or beta objects"]}
	var file := FileAccess.open(DAMAGE_OUT + "godot.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(outcome, "  "))
		file.close()
	done = true
	print("COMPETITIVE_DAMAGE_V28 ", outcome.status, " checks=", checks,
		" ids=", DAMAGE_ITEMS.size(), " errors=", errors.size())
	quit(0 if errors.is_empty() and checks >= 100 and damage_routes.size() == 9 else 1)

func _native_damage(spec: Dictionary, move: String, equipped: bool) -> Dictionary:
	var item := StringName(spec.id)
	var own_id := StringName("native_attack_" + String(spec.id))
	var foe_id := StringName("native_target_" + String(spec.id))
	var own := _mon(&"mew", 100, own_id, [move, "reflect"])
	var foe := _mon(StringName(spec.foe), 100, foe_id, ["growl"])
	var held := &""
	if equipped: held = item
	own.held_item_id = held
	check("no ability dependency (holder/foe) " + String(item),
		own.ability_id == &"" and foe.ability_id == &"")
	var owner := PlayerCollection.new()
	check("native damage owner belongs to party " + String(item),
		owner.party.add_creature(own))
	var session := Native.new(catalogs, owner, "gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self, foe, [23, 19, 29, 43])
	check("native damage battle opens " + String(item), opened)
	if not opened:
		await session.close()
		return {"valid": false}
	var unchanged := own.to_dict()
	var snap: Dictionary = session.snapshot()
	await session.close()
	session = Native.new(catalogs, owner, "gen9calvounifiedv1")
	var restored: bool = await session.restore_saved(self, snap)
	check("native damage checkpoint restores " + String(item), restored)
	if not restored:
		await session.close()
		return {"valid": false}
	var boundary := session.snapshot()
	check("native damage stale revision rejected " + String(item),
		not (await session.submit("move 1", session.revision + 1)).accepted
		and session.snapshot() == boundary)
	var initial: CreatureInstance = session.battle_state().creature(foe_id)
	var initial_hp := initial.current_hp
	var result: Dictionary = await session.submit("move 1", session.revision)
	check("native damage actual move accepted " + String(item), result.accepted)
	if not result.accepted:
		await session.close()
		return {"valid": false}
	var after_foe: CreatureInstance = session.battle_state().creature(foe_id)
	var actor: CreatureInstance = session.battle_state().creature(own_id)
	var dealt := initial_hp - after_foe.current_hp
	check("native damage physically projected " + String(item),
		dealt > 0 and actor.held_item_id == held
		and not actor.held_item_consumed)
	check("native damage campaign not yet published " + String(item),
		owner.owned_creature(own_id).to_dict() == unchanged)
	await session.close()
	return {"valid": dealt > 0, "damage": dealt}

func _map_damage_item(item: StringName) -> void:
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
	check("damage real field owner replacement " + String(item),
		owner.replace_owned_same_identity(own))
	owner.inventory.add(item, 2)
	check("damage real bag opens " + String(item), scene.toggle_item_bag())
	var bag = scene._item_bag
	_select(bag, String(item))
	check("damage real bag equips " + String(item), bag._apply("equip").accepted)
	bag.hide()
	await process_frame
	var bridge = scene._native_battles
	bridge.save_path = DAMAGE_OUT + "map_" + String(item) + ".json"
	check("damage map initial save " + String(item), bridge.save_game())
	check("damage map initial reload " + String(item), await bridge.load_game())
	owner = scene.field_collection()
	check("damage physical equipment persists before battle " + String(item),
		owner.owned_creature(own_id).held_item_id == item
		and _physical_medicine(owner, item) == 2)
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view
	view._playback.set_process(false)
	var opened := view.session != null and view.session.battle_state() != null
	check("damage map native encounter " + String(item), opened)
	if not opened:
		scene.queue_free()
		await process_frame
		return
	check("damage item projected into native encounter " + String(item),
		view.session.battle_state().creature(own_id).held_item_id == item)
	check("damage active battle saved " + String(item), bridge.save_game())
	check("damage active battle loaded " + String(item), await bridge.load_game())
	view._playback.set_process(false)
	check("damage held item preserved across checkpoint " + String(item),
		view.session.battle_state().creature(own_id).held_item_id == item)
	var action: Dictionary = await view.choose("move 1")
	check("damage map actual move submitted " + String(item), action.accepted)
	if action.accepted:
		await _drain_view(view)
		check("damage map native victory " + String(item),
			view.session.completion_reason == "VICTORY")
		await bridge.leave_battle()
		owner = scene.field_collection()
		check("damage equipped item retained after victory " + String(item),
			owner.owned_creature(own_id).held_item_id == item
			and _physical_medicine(owner, item) == 2)
		check("damage map final save " + String(item), bridge.save_game())
		check("damage map final load " + String(item), await bridge.load_game())
		owner = scene.field_collection()
		check("damage item and stock persist after reload " + String(item),
			owner.owned_creature(own_id).held_item_id == item
			and _physical_medicine(owner, item) == 2)
		damage_routes.append({"type": "real_map_bag_save", "item": String(item)})
	if view.session != null:
		await view.session.close()
	scene.queue_free()
	await process_frame
