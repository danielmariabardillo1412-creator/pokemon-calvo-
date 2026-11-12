extends SceneTree

const Routes = preload("res://modules/creatures/progression/regional_level_evolution_contract_w04_v5.gd")
const Forms = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const OUT := "res://.godot/items_integration_20261111/level_field/"
const PENDING_BALLS := [&"heavy_ball", &"beast_ball", &"love_ball", &"dive_ball", &"lure_ball"]
const PENDING_HELD := [&"amulet_coin", &"exp_share", &"luck_incense"]
var scene: Node2D
var bridge: Node
var view: Control
var checks := 0
var routes := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
	return ok


func creature(species: StringName, id: StringName, level: int, moves: Array) -> CreatureInstance:
	var definitions: DefinitionCatalog = scene.field_definitions()
	var rng := RandomNumberGenerator.new()
	rng.seed = 6173
	return CreatureFactory.create(definitions.species(species), level, definitions,
		ProgressionRuleset.new(), rng, {"instance_id": id, "nature_id": &"hardy", "moves": moves})


func set_party(member: CreatureInstance) -> void:
	var collection: PlayerCollection = scene.field_collection()
	collection.party = CreatureParty.new()
	check("install controlled team", collection.party.add_creature(member))


func open_wild() -> bool:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	view._playback.set_process(false)
	return view.session != null and view.session.has_active_battle()


func win() -> bool:
	for turn in 4:
		var result: Dictionary = await view.choose("move 1")
		if not result.get("accepted", false): return false
		for tick in 240:
			if not view._playback.is_playing(): break
			view._playback.advance(0.25)
		view._refresh_view()
		await process_frame
		await process_frame
		if view.session.completion_reason == "VICTORY": return true
	return false


func exercise_route(source: StringName, accept: bool, everstone := false, trainer := false) -> void:
	var row: Dictionary = Routes.ROUTES[source]
	var target: StringName = row[&"target"]
	var level: int = row[&"level"]
	var member := creature(source, &"regional_owner", level - 1, [&"flamethrower"])
	var definitions: DefinitionCatalog = scene.field_definitions()
	member.experience = ProgressionRuleset.experience_for_level(definitions.species(source).growth_rate, level) - 1
	member.effective_nature_id = &"adamant"
	member.recalculate_stats(definitions.species(source), ProgressionRuleset.new())
	if everstone: member.held_item_id = &"everstone"
	if trainer: member.form_id = &"" # Legacy regional identity in an old SaveV2 record.
	set_party(member)
	var opened: bool
	if trainer:
		var opponent := creature(&"caterpie", &"regional_trainer", 5, [&"tackle"])
		check("prepare owned trainer roster", scene.field_trainer_owner().configure(scene.TECHNICAL_TRAINER_ID, [opponent] as Array[CreatureInstance]))
		opened = scene.start_demo_trainer_battle()
		while bridge.busy: await process_frame
		view._playback.set_process(false)
		opened = opened and view.session.has_active_battle()
	else:
		opened = await open_wild()
	if not check("open visible native battle %s (%s)" % [source, bridge.last_error], opened): return
	if trainer:
		check("trainer checkpoint reloads with the original and minted natures", bridge.save_game()
			and await bridge.load_game() and view.session.has_active_battle())
		member = scene.field_collection().owned_creature(member.instance_id)
		check("active restoration retains both natures and the legacy form", member.nature_id == &"hardy"
			and member.effective_nature_id == &"adamant" and member.form_id == &"")
		view._playback.set_process(false)
	if not check("settle victory with real XP " + String(source), await win() and member.level >= level): return
	var prompt: Control = view._evolution_choices
	var expected_form := StringName(Forms.SOURCES.get(String(target), {}).get("form_id", "")) if accept else member.form_id
	if everstone:
		check("Everstone suppresses the choice after real XP", not prompt.visible and not view.session.has_level_evolution_choice())
	else:
		check("correct choice is shown before replacing " + String(source), prompt.visible
			and prompt._options.get_item_metadata(prompt._options.item_count - 1) == String(target)
			and scene.field_collection().owned_creature(member.instance_id) == member)
		check("choice gates save/load/return and rejects forged target", view._continue_button.disabled
			and not bridge.save_game() and not await bridge.load_game() and not view.session.resolve_level_evolution(&"pikachu"))
		await bridge.leave_battle()
		check("direct return cannot skip an outstanding choice", bridge.occupied() and prompt.visible)
		if DisplayServer.get_name() != "headless" and routes == 0 and accept:
			await RenderingServer.frame_post_draw
			check("capture real evolution UI", root.get_texture().get_image().save_png(OUT + "evolution_choice.png") == OK)
		if accept:
			var index: int = prompt._options.item_count - 1
			prompt._options.select(index); prompt._options.item_selected.emit(index); prompt._confirm.pressed.emit()
			routes += 1
		else:
			prompt._cancel.pressed.emit()
	var owned: CreatureInstance = scene.field_collection().owned_creature(member.instance_id)
	check("choice is applied once with correct form and existing progress", not prompt.visible
		and not view.session.resolve_level_evolution(target) and owned.species_id == (target if accept else source)
		and owned.form_id == expected_form and owned.level == member.level and owned.experience == member.experience
		and owned.effective_nature_id == member.effective_nature_id and owned.moveset[0].current_pp == member.moveset[0].current_pp)
	check("result view displays the updated team member", view._player_label.text.contains(SpanishGameText.species_name(owned.species_id, definitions))
		and view._arena.player_species == owned.appearance_id())
	var settled := owned.to_dict()
	check("settled game saves", bridge.save_game())
	await bridge.leave_battle()
	check("return and reload preserve owned state and XP", await bridge.load_game()
		and not bridge.occupied() and scene.field_collection().owned_creature(member.instance_id).to_dict() == settled)


func check_pending_items() -> void:
	var member := creature(&"mew", &"pending_owner", 50, [&"flamethrower"])
	set_party(member)
	var bag: Control = scene._item_bag
	for item_id: StringName in PENDING_HELD:
		# Pre-existing equipment from a save predating the prevention.
		member.held_item_id = item_id
		check("old held item survives SaveV2 " + String(item_id), bridge.save_game() and await bridge.load_game())
		var owner: PlayerCollection = scene.field_collection()
		member = owner.owned_creature(member.instance_id)
		check("open real bag for old item", bag.open_bag())
		check("old held item can be removed", (await bag._apply("unequip")).get("accepted", false)
			and member.held_item_id == &"" and owner.inventory.has(item_id))
		for index in bag._items.item_count:
			if StringName(bag._items.get_item_metadata(index)) == item_id:
				bag._items.select(index); bag._items.item_selected.emit(index)
				break
		var before := owner.inventory.to_dict()
		check("real bag prevents new bad equipment " + String(item_id), bag._equip.disabled
			and (await bag._apply("equip")).get("reason") == "held_effect_pending"
			and owner.inventory.to_dict() == before and member.held_item_id == &"")
		bag.hide()
	for item_id: StringName in PENDING_BALLS:
		check("stock pending ball for rejection " + String(item_id), scene.field_collection().inventory.add(item_id))
	if not check("normal battle opens with pending items in bag", await open_wild()): return
	var snapshot: Dictionary = view.session.snapshot()
	for item_id: StringName in PENDING_BALLS:
		var listed := false
		for index in view._capture_balls.item_count:
			if StringName(view._capture_balls.get_item_metadata(index)) == item_id: listed = true
		var result: Dictionary = await view.session.capture(item_id, view.session.revision)
		check("pending ball unavailable without spending or advancing battle " + String(item_id), not listed
			and not result.get("accepted", false) and view.session.snapshot() == snapshot)
	check("ordinary move still works after all pending ball rejections", await win())
	await bridge.leave_battle()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	if check("normal field ready", scene.is_demo_ready()):
		scene.player.set_physics_process(false)
		bridge = scene._native_battles; view = bridge.view; bridge.save_path = OUT + "save.json"
		var config: Dictionary = scene._active_config.duplicate(true)
		config.wild_species_id = "pidgey"; config.wild_min_level = 5; config.wild_max_level = 5; config.encounter_chance_percent = 100
		scene._on_configuration_applied(config)
		for source: StringName in Routes.ROUTES:
			await exercise_route(source, true, false, source == &"wooper_paldea")
		await exercise_route(&"diglett_alola", false)
		await exercise_route(&"grimer_alola", false, true)
		check("all ten routes exercised through the game", routes == 10)
		await check_pending_items()
	scene.queue_free()
	await process_frame
	print("IA6_REGIONAL_LEVEL_FIELD ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks,
		" routes=", routes, " GPU=", DisplayServer.get_name() != "headless", " errors=", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
