extends "res://tests/gameplay/item_field_effects_v4.gd"

const Mochi = preload("res://modules/inventory/field_mochi_effects.gd")
const Variants = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Native = preload("res://modules/gameplay/showdown_adventure_session.gd")
const V13 := "res://.godot/item_mochi_v13/"
const ITEMS := {"health_mochi": "hp", "muscle_mochi": "attack", "resist_mochi": "defense", "genius_mochi": "special_attack", "clever_mochi": "special_defense", "swift_mochi": "speed", "fresh_start_mochi": ""}
const KEYS := ["hp", "attack", "defense", "speed", "special_attack", "special_defense"]
const NATURES := {"hardy": ["", ""], "adamant": ["attack", "special_attack"], "timid": ["speed", "attack"]}
var matrix_cases := 0
var owned_cases := 0
var outcomes := {"APPLIED": 0, "NO_EFFECT": 0}
var native_rows: Array = []

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done: push_error("MOCHI_V13 timeout"); quit(2))

func _make(sid: StringName = &"mew", level := 50, evs := {}, nature := "hardy", id: StringName = &"mochi_target") -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 1301
	return CreatureFactory.create(catalogs.species(sid), level, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": id, "nature_id": nature, "evs": evs, "ivs": {"hp":31,"attack":31,"defense":31,"speed":31,"special_attack":31,"special_defense":31}, "moves": ["growl"]})

func _service(c: CreatureInstance, item: StringName) -> RefCounted:
	var owner := PlayerCollection.new(); owner.party.add_creature(c); owner.inventory.add(item, 3)
	var service := Service.new(); service.configure(owner, catalogs, func(): return not locked)
	return service

# Independent integer formula; never call the calculator used by production.
func _stats(c: CreatureInstance, evs: Dictionary) -> Dictionary:
	var base := catalogs.species(c.species_id).base_stat_block().to_dict(); var result := {}
	for key: String in KEYS:
		var stat := "max_hp" if key == "hp" else key
		var value := int(floor((2 * int(base[stat]) + int(c.ivs.get(key, 0)) + int(evs.get(key, 0)) / 4) * c.level / 100.0))
		if key == "hp": value += c.level + 10
		else:
			value += 5
			var modifiers: Array = NATURES[String(c.nature_id)]
			if key == modifiers[0]: value = int(floor(value * 1.1))
			if key == modifiers[1]: value = int(floor(value * 0.9))
		result[stat] = value
	return result

func _expected(c: CreatureInstance, item: String) -> Dictionary:
	var result := c.to_dict(); var evs: Dictionary = result.evs
	var total := 0
	for value: Variant in evs.values(): total += int(value)
	if item == "fresh_start_mochi":
		for key: Variant in evs: evs[key] = 0
	else:
		var stat: String = ITEMS[item]
		evs[stat] = int(evs.get(stat, 0)) + mini(10, mini(252 - int(evs.get(stat, 0)), 510 - total))
	result.stats = _stats(c, evs)
	result.current_hp = clampi(c.current_hp + int(result.stats.max_hp) - c.stats.max_hp, 1, result.stats.max_hp)
	return result

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V13)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	_matrix(); _owned(); _negative()
	await _native_control(); await _native_dependency(); await _field()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"matrix_cases": matrix_cases, "owned_cases": owned_cases, "outcomes": outcomes, "native_rows": native_rows, "gpu": capture}
	var file := FileAccess.open(V13 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	done = true; print("ITEM_MOCHI_V13 ", report.status, " checks=", checks, " cases=", matrix_cases, " GPU=", capture)
	quit(0 if errors.is_empty() else 1)

func _matrix() -> void:
	var index := 0
	for sid: String in catalogs.variant_allowed_species:
		index += 1
		for item: String in ITEMS:
			for pattern in 4:
				var evs := {}
				match pattern:
					1: evs = {"hp": 252, "attack": 252, "defense": 6}
					2: evs = {"hp":92,"attack":80,"defense":76,"speed":68,"special_attack":64,"special_defense":60}
					3: evs["hp" if item == "fresh_start_mochi" else ITEMS[item]] = 251
				var c := _make(StringName(sid), index % 100 + 1, evs)
				c.current_hp = 1 if pattern == 3 else maxi(1, int(c.stats.max_hp / 2.0))
				var service := _service(c, StringName(item)); var before := c.to_dict()
				var expected := _expected(c, item); var changes: bool = expected.evs != before.evs
				var result: Dictionary = service.use_item(StringName(item), c.instance_id)
				var after: CreatureInstance = service.owner.owned_creature(c.instance_id)
				check("catalog outcome " + sid + item, result.accepted == changes)
				check("whole expected state " + sid, after.to_dict() == (expected if changes else before))
				check("single item and detached source", service.owner.inventory.quantity(StringName(item)) == (2 if changes else 3) and c.to_dict() == before and (not is_same(c, after) if changes else is_same(c, after)))
				outcomes["APPLIED" if changes else "NO_EFFECT"] += 1; matrix_cases += 1
	check("all seven routes and eligible forms", index == 1076 and matrix_cases == 30128)

func _owned() -> void:
	for item: String in ITEMS:
		for stored in [false, true]:
			for friendship in [0,99,100,199,200,255]:
				for bell in [0,1,2]:
					for nature: String in NATURES:
						var c := _make(&"mew", 50, {"hp":92,"attack":80,"defense":76}, nature)
						c.current_hp = 1; c.friendship = friendship; c.is_shiny = true
						c.moveset[0].max_pp = 64; c.moveset[0].current_pp = 3; status(c, &"sleep")
						if bell > 0: c.held_item_id = &"soothe_bell"; c.held_item_consumed = bell == 2
						var service := _service(c, StringName(item))
						service.sleep_clocks[String(c.instance_id)] = {"version":"0.10.11","start_time":3,"time":2}
						if stored: service.owner.deposit(c.instance_id)
						var before := c.to_dict(); var expected := _expected(c, item); var clocks: Dictionary = service.sleep_clocks.duplicate(true)
						var result: Dictionary = service.use_item(StringName(item), c.instance_id)
						check("owned full state with nature/PP/status/bell", result.accepted and service.owner.owned_creature(c.instance_id).to_dict() == expected and c.to_dict() == before)
						check("owned location and clocks", service.owner.location_of(c.instance_id) == (&"STORAGE" if stored else &"PARTY") and service.sleep_clocks == clocks)
						owned_cases += 1

func _negative() -> void:
	for item: String in ITEMS:
		var c := _make(); var service := _service(c, StringName(item))
		for mode in 5:
			match mode:
				0: locked = true
				1: c.current_hp = 0
				2: c.current_hp = 1; c.battle_transform_original = {"species_id":"ditto"}
				3: c.battle_transform_original.clear(); service.owner.inventory.corrupted = true
				4: service.owner.inventory.corrupted = false; service.owner.inventory.remove(StringName(item),3)
			var before := snapshot(service)
			check("rejected boundaries " + item + str(mode), not service.use_item(StringName(item), c.instance_id).accepted and snapshot(service) == before)
			locked = false
		c = _make(); service = _service(c, StringName(item))
		check("no foreign recipient", service.use_item(StringName(item), &"foreign").reason == "creature_not_owned")
		check("no move slot", service.use_item(StringName(item), c.instance_id, 0).reason == "unexpected_move_slot")
	for raw: Variant in [-1,253,1.5,"10",true,INF,NAN]:
		var c := _make(); var service := _service(c, &"fresh_start_mochi"); c.evs.hp = raw
		var before := var_to_bytes(c.evs); var inventory: Dictionary = service.owner.inventory.to_dict()
		check("reset does not launder invalid EVs", service.use_item(&"fresh_start_mochi", c.instance_id).reason == "invalid_training_state" and var_to_bytes(c.evs) == before and service.owner.inventory.to_dict() == inventory and is_same(service.owner.owned_creature(c.instance_id),c))
	var c := _make(); var service := _service(c, &"health_mochi")
	c.stats.max_hp += 1; check("inconsistent stats not repaired", service.use_item(&"health_mochi", c.instance_id).reason == "invalid_mochi_state")
	c = _make(); service = _service(c, &"health_mochi"); c.moveset[0] = null
	check("null PP rejected before serializer", service.use_item(&"health_mochi",c.instance_id).reason == "invalid_pp_state" and service.owner.inventory.quantity(&"health_mochi")==3)
	c = _make(); service = _service(c, &"health_mochi"); c.ivs.hp = 1.5
	check("fractional IV not coerced", service.use_item(&"health_mochi",c.instance_id).reason == "invalid_mochi_state" and c.ivs.hp == 1.5)
	c = _make(); service = _service(c, &"fresh_start_mochi"); c.evs = {"hp":252,"attack":252,"defense":7}
	var before := snapshot(service)
	check("reset cannot launder overflowing EV total",service.use_item(&"fresh_start_mochi",c.instance_id).reason=="invalid_training_state" and snapshot(service)==before)

func _native_control() -> void:
	var damage_rows := []
	for mode in 3:
		var c := _make(&"mew",50,{"attack":252})
		c.moveset.clear(); c.move_ids.clear(); c.add_move(&"tackle",catalogs)
		var service := _service(c,&"fresh_start_mochi")
		if mode > 0: check("native reset prepared",service.use_item(&"fresh_start_mochi",c.instance_id).accepted)
		if mode == 2:
			service.owner.inventory.add(&"muscle_mochi"); check("native attack mochi prepared",service.use_item(&"muscle_mochi",c.instance_id).accepted)
		var foe := _make(&"mew",50,{},"hardy",&"mochi_foe")
		var session := Native.new(catalogs,service.owner,"gen9calvounifiedv1")
		var opened: bool = await session.begin_wild(self,foe,[23,19,29,43])
		check("native training control begins",opened)
		if not opened:
			await session.close(); continue
		var initial: int = session.battle_state().creature(foe.instance_id).current_hp
		var result: Dictionary = await session.submit("move 1",session.revision)
		var damage: int = initial - session.battle_state().creature(foe.instance_id).current_hp
		check("native uses final trained stats", result.accepted and session.battle_state().creature(c.instance_id).stats.attack == service.owner.owned_creature(c.instance_id).stats.attack)
		damage_rows.append(damage); native_rows.append({"mode":mode,"damage":damage,"attack_ev":service.owner.owned_creature(c.instance_id).evs.attack})
		await session.close()
	check("native damage confirms EV reset",damage_rows.size()==3 and damage_rows[0] > damage_rows[1] and damage_rows[2] >= damage_rows[1])

func _native_dependency() -> void:
	var c := _make(); c.held_item_id = &"soothe_bell"
	var service := _service(c,&"health_mochi")
	check("Bell does not block EV item in field",service.use_item(&"health_mochi",c.instance_id).accepted)
	var before := snapshot(service)
	var session := Native.new(catalogs,service.owner,"gen9calvounifiedv1")
	var opened: bool = await session.begin_wild(self,_make(&"mew",50,{},"hardy",&"dependency_foe"),[23,19,29,43])
	check("field-only held-item now bridges without campaign mutation",opened and session.last_error=="" and snapshot(service)==before and session.battle_state().creature(c.instance_id).held_item_id==&"soothe_bell")
	native_rows.append({"route":"soothe_bell_bridge_v14","opened":opened,"error":session.last_error,"campaign_unchanged":snapshot(service)==before})
	await session.close()

func _field() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent=100; config.wild_species_id="caterpie"; config.wild_min_level=5; config.wild_max_level=5
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection(); var id := owner.party.get_creatures()[0].instance_id
	var c := _make(&"mew",50,{"hp":252,"attack":252,"speed":6},"hardy",id)
	c.current_hp=1; c.friendship=199; c.held_item_id=&"leftovers"; c.moveset[0].max_pp=64; c.moveset[0].current_pp=13; status(c,&"poison")
	check("real owned training target",owner.replace_owned_same_identity(c))
	for item: String in ITEMS: owner.inventory.add(StringName(item),3)
	owner.inventory.add(&"master_ball",2)
	check("mochi bag opens",scene.toggle_item_bag()); var bag=scene._item_bag
	_select(bag,"fresh_start_mochi")
	check("reset description is distinct",bag._description.text.contains("Reinicia") and not bag._moves.visible)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("mochi bag fits",bag.position.y>=0 and bag.position.y+bag.size.y<=root.size.y)
		check("mochi capture",root.get_texture().get_image().save_png(V13+"mochi_bag.png")==OK)
	check("real reset via bag",bag._apply("use").accepted and bag._result.text.contains("reiniciado"))
	for item: String in ITEMS:
		if item=="fresh_start_mochi": continue
		_select(bag,item); check("real mochi through bag "+item,bag._apply("use").accepted)
	var expected := owner.owned_creature(id).to_dict()
	check("real seven effects preserve friendship PP and HP floor",expected.friendship==199 and expected.current_hp==2 and expected.moveset[0].current_pp==13 and expected.moveset[0].max_pp==64)
	bag.hide(); await process_frame
	var bridge=scene._native_battles; bridge.save_path=V13+("field_gpu.json" if capture else "field_headless.json")
	check("mochi save",bridge.save_game()); check("mochi load",await bridge.load_game())
	check("mochi state survives load",scene.field_collection().owned_creature(id).to_dict()==expected)
	scene.player.global_position=Vector2(420,150); await scene._on_player_step_completed(scene.player.global_position)
	var view=bridge.view; view._playback.set_process(false)
	var ready: bool = view.session != null and view.session.battle_state() != null
	check("native field encounter opens: " + bridge.last_error, ready)
	if not ready:
		scene.queue_free(); await process_frame; return
	check("native field receives mochi stats",view.session.battle_state().creature(id).to_dict().evs==expected.evs and view.session.battle_state().creature(id).stats.to_dict()==expected.stats)
	check("battle blocks mochi",bag.service.use_item(&"health_mochi",id).reason=="field_locked")
	check("mochi battle checkpoint save",bridge.save_game()); check("mochi battle checkpoint load",await bridge.load_game()); view._playback.set_process(false)
	check("mochi capture settles",(await view.adventure_command("master")).accepted)
	for i in 2000:
		if not view._playback.is_playing(): break
		view._playback.advance(0.25)
	await process_frame; await bridge.leave_battle()
	check("settled trained creature unchanged",scene.field_collection().owned_creature(id).to_dict()==expected)
	if view.session!=null: await view.session.close()
	scene.queue_free(); await process_frame
