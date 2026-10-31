extends "res://tests/gameplay/showdown_adventure_test_runner.gd"

# O110 batch runner: the eleven reviewed battle-support IDs over the real native
# worker. It exercises effects, exact consumption, rejections without spending,
# friendship settlement/persistence, save/load, the mandatory-replacement and
# trainer boundaries, and the real map bag panel (consumable vs reusable).
const OUT_SUPPORT := "res://.godot/opencode_battle_support_v2/"
const SUPPORT_IDS: Array[StringName] = [&"x_attack", &"x_defense", &"x_sp_atk", &"x_sp_def", &"x_speed", &"x_accuracy", &"dire_hit", &"guard_spec", &"blue_flute", &"yellow_flute", &"red_flute"]
const ACTIVE_ONLY: Array[StringName] = [&"x_attack", &"x_defense", &"x_sp_atk", &"x_sp_def", &"x_speed", &"x_accuracy", &"dire_hit", &"guard_spec", &"yellow_flute", &"red_flute"]
# Native checkpoint boost keys for each X item.
const X_NATIVE_STAT := {"x_attack": "atk", "x_defense": "def", "x_sp_atk": "spa", "x_sp_def": "spd", "x_speed": "spe", "x_accuracy": "accuracy"}
var capture := false
var scene: Node2D


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(420).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			push_error("OPENCODE_BATTLE_SUPPORT_V2 timeout"); quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_SUPPORT)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional catalog loads", preload("res://modules/creatures/progression/pokemon_variant_catalog.gd").apply(catalogs))
	check("exact imported family", Session.BattleSupport.items().keys().size() == 11)
	check("consumption contract", Session.BattleSupport.consumable(&"x_attack") and Session.BattleSupport.consumable(&"dire_hit") and Session.BattleSupport.consumable(&"guard_spec") and not Session.BattleSupport.consumable(&"blue_flute") and not Session.BattleSupport.consumable(&"yellow_flute") and not Session.BattleSupport.consumable(&"red_flute"))
	check("target contract", Session.BattleSupport.target_scope(&"x_attack") == &"active_own" and Session.BattleSupport.target_scope(&"blue_flute") == &"any_own_living")
	if not capture:
		for id: StringName in [&"x_attack", &"x_defense", &"x_sp_atk", &"x_sp_def", &"x_speed", &"x_accuracy"]:
			await x_item_positive(id)
		await dire_hit_positive()
		await guard_spec_positive()
		await blue_flute_positive()
		await blue_flute_wrong_status()
		await yellow_flute_positive()
		await red_flute_positive()
		await rejections()
		await friendship_settlement()
		await staged_spending_and_reload()
		await trainer_and_replacement_boundaries()
	for id: StringName in [&"x_attack", &"blue_flute"]: await map_bag(id)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "gpu": capture}
	var file := FileAccess.open(OUT_SUPPORT + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("OPENCODE_BATTLE_SUPPORT_V2 ", report.status, " checks=", checks, " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func enemy(id: String, moves: Array = [&"tackle"], level: int = 50) -> CreatureInstance:
	return creature(id, "mew", level, moves)


func require_open(label: String, opened: bool) -> bool:
	check(label, opened)
	if not opened and active != null:
		active.stop_now()
	return opened


func x_item_positive(id: StringName) -> void:
	var player := collection(); player.inventory.add(id, 2)
	player.party.get_creature(&"own_0").friendship = 100
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("x item wild opens " + String(id), await active.begin_wild(self, enemy("sup_enemy_" + String(id)))): return
	check("x item offered " + String(id), active.battle_item_usable(id))
	var before_log: int = active._checkpoint.snapshot.native.log.size()
	var result: Dictionary = await active.use_item(id, &"own_0", active.revision)
	check("x item accepted " + String(id), result.accepted)
	check("x item exact native stage " + String(id), int(active._checkpoint.roster[0].pokemon[0].boosts.get(X_NATIVE_STAT[String(id)], 0)) == 2)
	check("x item spends one staged unit " + String(id), active.inventory.quantity(id) == 1)
	check("x item lone enemy action " + String(id), active._checkpoint.snapshot.native.log.slice(before_log).filter(func(line: String): return line.begins_with("|move|p2a")).size() == 1)
	check("x item friendship gain " + String(id), active._checkpoint.roster[0].pokemon[0].friendship == 101 and player.party.get_creature(&"own_0").friendship == 100)
	await active.close()


func dire_hit_positive() -> void:
	var player := collection(); player.inventory.add(&"dire_hit", 2)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("dire hit wild opens", await active.begin_wild(self, enemy("sup_dire_enemy"))): return
	check("dire hit accepted", (await active.use_item(&"dire_hit", &"own_0", active.revision)).accepted)
	check("dire hit focus energy volatile", active._checkpoint.roster[0].pokemon[0].volatiles.has("focusenergy"))
	check("dire hit spends one staged unit", active.inventory.quantity(&"dire_hit") == 1)
	var frozen: Dictionary = active.snapshot()
	check("dire hit rejects while active without spending", not (await active.use_item(&"dire_hit", &"own_0", active.revision)).accepted and active.snapshot() == frozen and active.inventory.quantity(&"dire_hit") == 1)
	await active.close()


func guard_spec_positive() -> void:
	var player := collection(); player.inventory.add(&"guard_spec", 2)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("guard spec wild opens", await active.begin_wild(self, enemy("sup_guard_enemy"))): return
	check("guard spec accepted", (await active.use_item(&"guard_spec", &"own_0", active.revision)).accepted)
	check("guard spec native mist", active._checkpoint.snapshot.native.sides[0].sideConditions.has("mist"))
	check("guard spec spends one staged unit", active.inventory.quantity(&"guard_spec") == 1)
	var frozen: Dictionary = active.snapshot()
	check("guard spec rejects reapply without spending", not (await active.use_item(&"guard_spec", &"own_0", active.revision)).accepted and active.snapshot() == frozen and active.inventory.quantity(&"guard_spec") == 1)
	await active.close()


func resting_player() -> PlayerCollection:
	var player := collection()
	var own: CreatureInstance = player.party.get_creature(&"own_0")
	own.current_hp = 10
	_configure_moves(own, [&"rest", &"tackle"])
	player.inventory.add(&"blue_flute", 1)
	return player


func blue_flute_positive() -> void:
	var player := resting_player()
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("blue flute wild opens", await active.begin_wild(self, enemy("sup_blue_enemy", [&"growl"]))): return
	check("blue flute rest sleeps the actor", (await active.submit("move 1", active.revision)).accepted and active._checkpoint.roster[0].pokemon[0].status_id == "sleep")
	check("blue flute accepted", (await active.use_item(&"blue_flute", &"own_0", active.revision)).accepted)
	check("blue flute cures sleep", active._checkpoint.roster[0].pokemon[0].status_id == "")
	check("blue flute reusable (no spend)", active.inventory.quantity(&"blue_flute") == 1 and not active._spent_items.has("blue_flute"))
	await active.close()


func yellow_flute_positive() -> void:
	var player := collection(); player.inventory.add(&"yellow_flute", 1)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("yellow flute wild opens", await active.begin_wild(self, enemy("sup_yellow_enemy", [&"confuse_ray"], 100))): return
	check("yellow flute confuse ray lands", (await active.submit("move 1", active.revision)).accepted and active._checkpoint.roster[0].pokemon[0].volatiles.has("confusion"))
	var before_size: int = active._checkpoint.snapshot.native.log.size()
	var result: Dictionary = await active.use_item(&"yellow_flute", &"own_0", active.revision)
	var turn_log: Array = active._checkpoint.snapshot.native.log.slice(before_size)
	var cure_index := -1
	for i: int in turn_log.size():
		var line := String(turn_log[i]).to_lower()
		if line.begins_with("|-end|") and line.contains("confusion") and line.contains("yellow_flute"): cure_index = i
	check("yellow flute accepted", result.accepted)
	check("yellow flute exact cure line", cure_index >= 0)
	if cure_index >= 0 and active._checkpoint.roster[0].pokemon[0].volatiles.has("confusion"):
		var re_applied := false
		for i: int in range(cure_index + 1, turn_log.size()):
			var line := String(turn_log[i]).to_lower()
			if line.begins_with("|-start|") and line.contains("confusion"): re_applied = true
		check("any remaining confusion is a real later enemy application", re_applied)
	check("yellow flute reusable (no spend)", active.inventory.quantity(&"yellow_flute") == 1 and not active._spent_items.has("yellow_flute"))
	await active.close()


# Attract needs opposite genders. The native engine assigns them from the battle
# seed, so the fixture searches a bounded deterministic seed range for a real
# landing instead of faking the volatile.
func red_flute_positive() -> void:
	var landed := false
	for attempt in 40:
		var player := collection()
		var rng := RandomNumberGenerator.new(); rng.seed = 700 + attempt
		var gendered := CreatureFactory.create(catalogs.species(&"pikachu"), 50, catalogs, ProgressionRuleset.new(), rng, {"instance_id": &"own_0", "moves": [&"tackle"]})
		player.party.remove_creature(&"own_0"); player.party.add_creature(gendered)
		player.inventory.add(&"red_flute", 1)
		var candidate := Session.new(catalogs, player, "gen9calvounifiedv1")
		var seed := [1000 + attempt * 7, 12004, 12006, 1]
		var foe := creature("sup_red_enemy", "eevee", 100, [&"attract"])
		if not await candidate.begin_wild(self, foe, seed):
			await candidate.close(); continue
		var submitted: Dictionary = await candidate.submit("move 1", candidate.revision)
		if submitted.accepted and candidate._checkpoint.roster[0].pokemon[0].volatiles.has("attract"):
			var before_size: int = candidate._checkpoint.snapshot.native.log.size()
			var result: Dictionary = await candidate.use_item(&"red_flute", &"own_0", candidate.revision)
			var turn_log: Array = candidate._checkpoint.snapshot.native.log.slice(before_size)
			var cure_index := -1
			for i: int in turn_log.size():
				var line := String(turn_log[i]).to_lower()
				if line.begins_with("|-end|") and line.contains("attract") and line.contains("red_flute"): cure_index = i
			check("red flute accepted after a real attraction", result.accepted and cure_index >= 0)
			if cure_index >= 0 and candidate._checkpoint.roster[0].pokemon[0].volatiles.has("attract"):
				var re_applied := false
				for i: int in range(cure_index + 1, turn_log.size()):
					var line := String(turn_log[i]).to_lower()
					if line.begins_with("|-start|") and line.contains("attract"): re_applied = true
				check("any remaining attraction is a real later enemy application", re_applied)
			check("red flute reusable (no spend)", candidate.inventory.quantity(&"red_flute") == 1 and not candidate._spent_items.has("red_flute"))
			landed = true
			await candidate.close()
			break
		await candidate.close()
	check("red flute attraction fixture found in the deterministic seed range", landed)


func _configure_moves(own: CreatureInstance, moves: Array) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 14
	var prepared := CreatureFactory.create(catalogs.species(own.species_id), own.level, catalogs, ProgressionRuleset.new(), rng, {"instance_id": own.instance_id, "moves": moves})
	own.moveset = prepared.moveset
	own.move_ids = prepared.move_ids


func rejection(label: String, id: StringName, target: StringName, rev: int, slot: int = -1) -> void:
	var before: Dictionary = active.snapshot()
	var bag_before: Dictionary = active.inventory.to_dict()
	var owner_before: Dictionary = active.player.inventory.to_dict()
	var result: Dictionary = await active.use_item(id, target, rev, slot)
	check(label, not result.accepted and active.snapshot() == before and active.inventory.to_dict() == bag_before and active.player.inventory.to_dict() == owner_before)


func blue_flute_wrong_status() -> void:
	var player := collection()
	player.inventory.add(&"blue_flute", 1)
	var own := player.party.get_creature(&"own_0")
	own.status_state.persistent_id = &"poison"
	own.status_ids.append(&"poison")
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("poisoned blue flute session opens", await active.begin_wild(self, enemy("sup_poison_enemy", [&"growl"]))): return
	check("blue flute poison fixture imported", active._checkpoint.roster[0].pokemon[0].status_id == "poison")
	await rejection("blue flute cannot cure poison or advance the battle", &"blue_flute", &"own_0", active.revision)
	await active.close()


func rejections() -> void:
	var player := collection(2)
	for id: StringName in SUPPORT_IDS: player.inventory.add(id, 2)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("rejection wild opens", await active.begin_wild(self, enemy("sup_reject_enemy"))): return
	await rejection("stale revision", &"x_attack", &"own_0", active.revision + 1)
	for id: StringName in ACTIVE_ONLY:
		await rejection("reserve actor " + String(id), id, &"own_1", active.revision)
	await rejection("foreign target", &"x_attack", &"sup_reject_enemy", active.revision)
	await rejection("unexpected move slot", &"x_attack", &"own_0", active.revision, 0)
	await rejection("healthy blue flute target", &"blue_flute", &"own_0", active.revision)
	await rejection("no condition yellow flute", &"yellow_flute", &"own_0", active.revision)
	await rejection("no condition red flute", &"red_flute", &"own_0", active.revision)
	active._command_busy = true; await rejection("competing command", &"x_attack", &"own_0", active.revision)
	check("rejection keeps IPC ownership", active._command_busy); active._command_busy = false
	active.needs_recovery = true; await rejection("interrupted session", &"x_attack", &"own_0", active.revision); active.needs_recovery = false
	player.inventory.add(&"ether"); await rejection("changed campaign", &"x_attack", &"own_0", active.revision)
	await active.close()
	player = collection(); active = Session.new(catalogs, player)
	check("missing item session", await active.begin_wild(self, enemy("sup_missing_enemy")))
	await rejection("no owned item", &"x_attack", &"own_0", active.revision)
	await active.close()


func friendship_settlement() -> void:
	var player := collection()
	var own: CreatureInstance = player.party.get_creature(&"own_0")
	own.friendship = 100
	player.inventory.add(&"x_attack", 1)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("friendship wild opens " + active.last_error, await active.begin_wild(self, creature("sup_friend_enemy", "vulpix_alola", 18, [&"tackle"]))): return
	check("friendship use accepted " + active.last_error, (await active.use_item(&"x_attack", &"own_0", active.revision)).accepted)
	check("friendship gained in the candidate", active._checkpoint.roster[0].pokemon[0].friendship == 101)
	check("capture settles the friendship once", (await active.capture(&"master_ball", active.revision)).accepted and player.party.get_creature(&"own_0").friendship == 101)
	check("settled friendship is not paid twice", not (await active.capture(&"master_ball", active.revision)).accepted and player.party.get_creature(&"own_0").friendship == 101)
	await active.close()
	# At 200 the reference gain is zero; the projection must not invent a gain.
	player = collection()
	player.party.get_creature(&"own_0").friendship = 200
	player.inventory.add(&"x_attack", 1)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("capped friendship wild opens", await active.begin_wild(self, creature("sup_cap_enemy", "vulpix_alola", 18, [&"tackle"]))): return
	check("capped friendship use accepted", (await active.use_item(&"x_attack", &"own_0", active.revision)).accepted)
	check("friendship stays at 200", active._checkpoint.roster[0].pokemon[0].friendship == 200 and (await active.capture(&"master_ball", active.revision)).accepted and player.party.get_creature(&"own_0").friendship == 200)
	await active.close()


func staged_spending_and_reload() -> void:
	var player := collection()
	player.inventory.add(&"x_attack", 2); player.inventory.add(&"blue_flute", 1)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	if not require_open("reload fixture opens", await active.begin_wild(self, enemy("sup_reload_enemy"))): return
	check("booster accepted", (await active.use_item(&"x_attack", &"own_0", active.revision)).accepted)
	var frozen: Dictionary = active.snapshot()
	check("reusable flute rejects a healthy target without changes", not (await active.use_item(&"blue_flute", &"own_0", active.revision)).accepted and active.snapshot() == frozen)
	check("booster spent is staged once", player.inventory.quantity(&"x_attack") == 2 and active.inventory.quantity(&"x_attack") == 1)
	var saved: Dictionary = active.snapshot()
	await active.close()
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("spent booster snapshot restores", await active.restore_saved(self, saved))
	check("restored staged spending", active.inventory.quantity(&"x_attack") == 1 and int(active._spent_items.get("x_attack", 0)) == 1 and active.inventory.quantity(&"blue_flute") == 1)
	check("restored battle accepts another booster", (await active.use_item(&"x_attack", &"own_0", active.revision)).accepted and active.inventory.quantity(&"x_attack") == 0)
	check("capture publishes both spends once", (await active.capture(&"master_ball", active.revision)).accepted and player.inventory.quantity(&"x_attack") == 0 and player.inventory.quantity(&"blue_flute") == 1)
	await active.close()


func trainer_and_replacement_boundaries() -> void:
	var player := collection(); player.inventory.add(&"x_attack", 2)
	active = Session.new(catalogs, player)
	if require_open("trainer session opens", await active.begin_trainer(self, &"route_support_trainer", [enemy("sup_trainer_enemy")] as Array[CreatureInstance])):
		check("trainer battle still offers the booster", active.battle_item_usable(&"x_attack"))
		check("trainer booster accepted " + active.last_error, (await active.use_item(&"x_attack", &"own_0", active.revision)).accepted)
	await active.close()
	player = collection(2); player.party.get_creature(&"own_0").current_hp = 1; player.inventory.add(&"x_attack", 2)
	active = Session.new(catalogs, player)
	check("replacement fixture opens", await active.begin_wild(self, enemy("sup_ko_enemy", [&"tackle"], 100)))
	check("actual KO", (await active.submit("move 2", active.revision)).accepted and active.phase() != "move")
	await rejection("no item during mandatory replacement", &"x_attack", &"own_1", active.revision)
	await active.close()


func select_item(view: Control, id: StringName) -> void:
	var found := false
	for i: int in view._medicine_items.item_count:
		if view._medicine_items.get_item_metadata(i) == String(id): view._medicine_items.select(i); found = true
	check("battle bag offers " + String(id), found)
	view._refresh_medicine_moves()


func map_bag(id: StringName) -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	owner.inventory.add(id, 3); owner.inventory.add(&"potion", 2); owner.inventory.add(&"master_ball", 1)
	var bridge = scene._native_battles; bridge.save_path = OUT_SUPPORT + ("gpu_" if capture else "headless_") + String(id) + ".json"
	scene.player.global_position = Vector2(420, 150); await scene._on_player_step_completed(scene.player.global_position)
	var view: Control = bridge.view; view._playback.set_process(false)
	check("map real encounter " + String(id), view.session != null and view.session.has_active_battle())
	check("map save before use " + String(id), bridge.save_game()); check("map load before use " + String(id), await bridge.load_game()); view._playback.set_process(false)
	owner = scene.field_collection()
	view.open_medicine_bag(); select_item(view, id)
	var reusable: bool = not Session.BattleSupport.consumable(id)
	check("UI states consumption/reuse " + String(id), view._medicine_hint.text.contains("reutilizable") if reusable else view._medicine_hint.text.contains("consume una unidad"))
	check("UI active-only label " + String(id), view._medicine_target_label.text.contains("activo") if id == &"x_attack" or id == &"yellow_flute" else true)
	if id == &"x_attack":
		if view.session.inventory.has(&"potion"):
			select_item(view, &"potion"); check("medicine target controls restored", view._medicine_targets.visible and view._medicine_target_label.text.contains("Pokémon")); select_item(view, id)
		if capture:
			await process_frame; await process_frame; await RenderingServer.frame_post_draw
			check("popup compact and within window", view._medicine_popup.size.y < scene.get_viewport_rect().size.y and view._medicine_popup.position.y >= 0 and view._medicine_popup.position.y + view._medicine_popup.size.y <= scene.get_viewport_rect().size.y)
			check("GPU support bag", root.get_texture().get_image().save_png(OUT_SUPPORT + "battle_support_bag.png") == OK)
	var active_id: StringName = view.session.battle_state().sides[0].active_id
	var result: Dictionary = await view.use_selected_medicine()
	# Drain the resolved turn before issuing another UI command.
	for i: int in 2000:
		if not view._playback.is_playing(): break
		view._playback.advance(0.25)
	await process_frame
	if id == &"x_attack":
		check("map bag completes the booster " + JSON.stringify(result) + " error=" + view.session.last_error, result.accepted and view.session.battle_state().creature(active_id).stat_stages.get_stage(StatStages.ATTACK) == 2)
		check("map booster stages one unit before settlement", view.session.inventory.quantity(id) == 2 and owner.inventory.quantity(id) == 3)
		check("map capture settles the spend " + view.session.last_error + " phase=" + view.session.phase(), (await view.adventure_command("master")).accepted and owner.inventory.quantity(id) == 2)
	else:
		# A healthy target has no sleep: the reusable flute must reject visibly
		# without spending and without ending the battle.
		check("map reusable flute rejects without spend " + JSON.stringify(result), not result.accepted and owner.inventory.quantity(id) == 3 and view.session.has_active_battle())
		check("map reusable rejection message clear", view._event_log.get_parsed_text().contains("No se ha usado el objeto"))
		check("map reusable capture settles nothing", (await view.adventure_command("master")).accepted and owner.inventory.quantity(id) == 3)
	for i: int in 2000:
		if not view._playback.is_playing(): break
		view._playback.advance(0.25)
	await process_frame
	check("completed UI cannot spend twice " + String(id), not (await view.use_selected_medicine()).accepted and owner.inventory.quantity(id) == (2 if id == &"x_attack" else 3))
	await bridge.leave_battle()
	check("back in field " + String(id), not bridge.busy and not view.visible)
	check("map final save " + String(id), bridge.save_game()); check("map final load " + String(id), await bridge.load_game())
	check("consumed count persists " + String(id), scene.field_collection().inventory.quantity(id) == (2 if id == &"x_attack" else 3))
	scene.queue_free(); await process_frame
