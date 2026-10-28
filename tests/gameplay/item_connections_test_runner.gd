extends SceneTree

const Service = preload("res://modules/inventory/field_item_service.gd")
const OUT := "res://.godot/item_connections_v1/"
const Content = preload("res://modules/gameplay/randomlock_content_policy.gd")
var content := Content.new()
var catalogs: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var locked := false
var equip_cases: Array = []
var evolution_cases: Array = []
var machine_cases: Array = []
var scene: Node2D
var capture := false
var finished := false


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	create_timer(180).timeout.connect(func():
		if finished: return
		if scene != null and is_instance_valid(scene) and scene._native_battles != null and scene._native_battles.view.session != null: scene._native_battles.view.session.stop_now()
		push_error("ITEM_CONNECTIONS watchdog timeout"); quit(2))
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)


func create(species_id: StringName, id: StringName = &"item_test") -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 17
	var creature := CreatureFactory.create(catalogs.species(species_id), 50, catalogs, ProgressionRuleset.new(), rng, {"instance_id": id, "moves": ["tackle", "protect"]})
	for ability: StringName in catalogs.species(species_id).ability_ids:
		if content.ability_allowed(String(ability)): creature.ability_id = ability; break
	return creature


func service_for(species_id: StringName = &"eevee") -> RefCounted:
	var owner := PlayerCollection.new(); owner.party.add_creature(create(species_id))
	var service := Service.new()
	check("service configured", service.configure(owner, catalogs, func(): return not locked))
	return service


func snapshot(owner: PlayerCollection) -> String:
	var rows: Array = []
	for creature: CreatureInstance in owner.party.get_creatures(): rows.append(creature.to_dict())
	for creature: CreatureInstance in owner.storage.get_all_creatures(): rows.append(creature.to_dict())
	return JSON.stringify({"inventory": owner.inventory.to_dict(), "creatures": rows})


func _run() -> void:
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("test fixture content policy loaded", content.load_local())
	_test_mapping()
	_test_equipment()
	_test_evolutions()
	_test_machines()
	await _test_field_and_save()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "equip_cases": equip_cases, "evolution_cases": evolution_cases, "machine_cases": machine_cases}
	var file := FileAccess.open(OUT + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE); file.store_string(JSON.stringify(report, "  ")); file.close()
	print("ITEM_CONNECTIONS ", report.status, " checks=", checks, " equip=", equip_cases.size(), " evolutions=", evolution_cases.size(), " machines=", machine_cases.size())
	finished = true
	quit(0 if errors.is_empty() else 1)


func _test_mapping() -> void:
	var service := service_for()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "source_machine_rows.json"))
	var ids := {}; var moves := {}; var versions := {}
	for row: Dictionary in source.items: ids[String(row.id)] = String(row.identifier).replace("-", "_").replace("__", "_")
	for row: Dictionary in source.moves: moves[String(row.id)] = String(row.identifier).replace("-", "_")
	for row: Dictionary in source.versions:
		if int(row.id) <= 27: versions[String(row.id)] = row.identifier
	for row: Dictionary in source.rows:
		var item_id: String = ids[String(row.item_id)]
		var move_id: String = moves[String(row.move_id)]
		if not versions.has(String(row.version_group_id)) or catalogs.item(StringName(item_id)) == null or catalogs.move(StringName(move_id)) == null: continue
		check("primary machine mapping %s/%s" % [item_id, versions[String(row.version_group_id)]], service.profile.machine_rows[item_id][versions[String(row.version_group_id)]] == move_id)
	check("338 machine IDs mapped", service.profile.machine_rows.size() == 338)
	check("TM01 Scarlet/Violet is Take Down", service.profile.machine_rows.tm01["scarlet-violet"] == "take_down")
	check("TM01 Sword/Shield is Mega Kick", service.profile.machine_rows.tm01["sword-shield"] == "mega_kick")
	check("HM03 ORAS is Surf", service.profile.machine_rows.hm03["omega-ruby-alpha-sapphire"] == "surf")
	check("TR00 Sword/Shield is Swords Dance", service.profile.machine_rows.tr00["sword-shield"] == "swords_dance")


func _test_equipment() -> void:
	var service := service_for()
	var creature: CreatureInstance = service.owner.owned_creature(&"item_test")
	for raw_id: String in service.profile.holdable_ids:
		var item_id := StringName(raw_id)
		service.owner.inventory.clear(); creature.held_item_id = &""; creature.held_item_consumed = false
		service.owner.inventory.add(item_id, 2)
		var before := snapshot(service.owner)
		var result: Dictionary = service.equip(item_id, creature.instance_id)
		if not service.selection.content_allowed(item_id):
			check("excluded equip conserves state " + raw_id, not result.accepted and snapshot(service.owner) == before)
			continue
		check("equip transfers one " + raw_id, result.accepted and service.owner.inventory.quantity(item_id) == 1 and creature.held_item_id == item_id and not creature.held_item_consumed)
		check("unequip returns same item " + raw_id, service.unequip(creature.instance_id).accepted and service.owner.inventory.quantity(item_id) == 2 and creature.held_item_id == &"")
		equip_cases.append({"id": raw_id, "status": "TRANSFER_VERIFIED_EFFECT_NOT_CERTIFIED"})
	service.owner.inventory.clear(); service.owner.inventory.add(&"leftovers"); service.owner.inventory.add(&"life_orb")
	check("first equip", service.equip(&"leftovers", creature.instance_id).accepted)
	check("replacement returns previous item", service.equip(&"life_orb", creature.instance_id).accepted and service.owner.inventory.quantity(&"leftovers") == 1 and service.owner.inventory.quantity(&"life_orb") == 0)
	creature.held_item_consumed = true
	check("consumed item is not duplicated", service.unequip(creature.instance_id).accepted and not service.owner.inventory.has(&"life_orb"))
	var before := snapshot(service.owner); locked = true
	check("locked equipment rejected", not service.equip(&"leftovers", creature.instance_id).accepted and snapshot(service.owner) == before)
	locked = false
	check("unknown owner rejected", not service.equip(&"leftovers", &"not_owned").accepted)
	# Party/storage ownership must remain the same aggregate, not a UI-only copy.
	check("deposit for storage equip", service.owner.deposit(creature.instance_id))
	check("storage equip supported", service.equip(&"leftovers", creature.instance_id).accepted and service.owner.location_of(creature.instance_id) == &"STORAGE")


func _test_evolutions() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/item_audit_v1/godot_inventory.json"))
	for row: Dictionary in fixture.evolution_references:
		if row.trigger != "use_item": continue
		var service := service_for(StringName(row.source))
		var creature: CreatureInstance = service.owner.owned_creature(&"item_test")
		service.owner.inventory.add(StringName(row.item_id), 2)
		var before := snapshot(service.owner)
		var old_ivs: Dictionary = creature.ivs.duplicate(); var old_moves: Array = creature.move_ids.duplicate()
		if row.classification != EvolutionSystem.RUNTIME_SUPPORTED:
			if service.evolution_options(StringName(row.item_id), creature.instance_id).has(StringName(row.target)):
				# Canonical data can share a base target ID between a normal and a deferred regional route.
				# The field API requests species, never a regional form; retain the unsupported route as pending.
				check("deferred form conditions retained " + row.source + "/" + row.target, not row.conditions.is_empty() and snapshot(service.owner) == before)
				evolution_cases.append({"source": row.source, "target": row.target, "item_id": row.item_id, "status": "FORM_ROUTE_DEFERRED_BASE_ROUTE_SEPARATE"})
				continue
			# Some species/item pairs also have a valid base-form evolution. Explicitly request the unsupported branch.
			var rejected: Dictionary = service.evolve(StringName(row.item_id), creature.instance_id, StringName(row.target))
			check("conditioned evolution not weakened " + row.source + "/" + row.target, not rejected.accepted and snapshot(service.owner) == before)
			evolution_cases.append({"source": row.source, "target": row.target, "item_id": row.item_id, "status": "DEPENDENCY_MISSING", "reason": rejected.get("reason", "unexpected_acceptance")})
			continue
		var result: Dictionary = service.evolve(StringName(row.item_id), creature.instance_id, StringName(row.target))
		if not service.content.species_allowed(row.target) or not result.accepted and result.reason == "evolution_ability_route_pending":
			check("excluded evolution keeps state " + row.target, not result.accepted and snapshot(service.owner) == before)
			evolution_cases.append({"source": row.source, "target": row.target, "status": "CONTENT_OR_ABILITY_ROUTE_BLOCKED"}); continue
		var evolved: CreatureInstance = service.owner.owned_creature(creature.instance_id)
		check("evolution target and item consumption " + row.source + "/" + row.target, result.accepted and evolved.species_id == StringName(row.target) and service.owner.inventory.quantity(StringName(row.item_id)) == 1)
		check("evolution preserves ownership and data " + row.target, evolved.instance_id == creature.instance_id and evolved.level == creature.level and evolved.ivs == old_ivs and evolved.move_ids == old_moves and service.owner.party.size() == 1)
		evolution_cases.append({"source": row.source, "target": row.target, "item_id": row.item_id, "status": "BAG_EVOLUTION_VERIFIED"})
	# Fixed Pokemon-rule examples are independent of the runtime-generated eligibility census.
	for golden: Array in [["eevee", "water_stone", "vaporeon"], ["eevee", "fire_stone", "flareon"], ["growlithe", "fire_stone", "arcanine"], ["pikachu", "thunder_stone", "raichu"]]:
		var service := service_for(StringName(golden[0])); service.owner.inventory.add(StringName(golden[1]))
		check("golden evolution " + golden[2], service.evolve(StringName(golden[1]), &"item_test").get("species_id") == golden[2])
	var service := service_for(&"eevee"); service.owner.inventory.add(&"fire_stone")
	var before := snapshot(service.owner)
	check("forged evolution target rejected", not service.evolve(&"fire_stone", &"item_test", &"mewtwo").accepted and snapshot(service.owner) == before)
	locked = true
	check("locked evolution rejected", not service.evolve(&"fire_stone", &"item_test").accepted and snapshot(service.owner) == before)
	locked = false
	service = service_for(&"munna"); service.owner.inventory.add(&"moon_stone")
	service.owner.owned_creature(&"item_test").ability_id = &"forewarn"
	before = snapshot(service.owner)
	check("legacy excluded ability route rejected without reroll", not service.evolve(&"moon_stone", &"item_test").accepted and snapshot(service.owner) == before)
	service = service_for(&"eevee"); before = snapshot(service.owner)
	check("missing evolution item does not mutate", not service.evolve(&"water_stone", &"item_test").accepted and snapshot(service.owner) == before)
	service.owner.inventory.add(&"water_stone")
	check("storage evolution setup", service.owner.deposit(&"item_test"))
	check("storage evolution preserves location and identity", service.evolve(&"water_stone", &"item_test").accepted and service.owner.location_of(&"item_test") == &"STORAGE" and service.owner.owned_creature(&"item_test").species_id == &"vaporeon")
	service = service_for(&"eevee"); service.owner.inventory.add(&"fire_stone")
	service.owner.owned_creature(&"item_test").current_hp = 0
	check("evolution does not silently revive", service.evolve(&"fire_stone", &"item_test").accepted and service.owner.owned_creature(&"item_test").current_hp == 0)


func _test_machines() -> void:
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT + "machine_fixtures.json"))
	check("229 SV machine fixtures", fixtures.size() == 229)
	for fixture: Dictionary in fixtures:
		var service := service_for()
		var chosen := ""
		for species_id: String in fixture.compatible_species:
			if service.content.species_allowed(species_id): chosen = species_id; break
		if chosen.is_empty():
			machine_cases.append({"id": fixture.item_id, "status": "NEEDS_COMPATIBILITY_CONTEXT"}); continue
		service = service_for(StringName(chosen))
		var creature: CreatureInstance = service.owner.owned_creature(&"item_test")
		creature.moveset.clear(); creature.move_ids.clear()
		service.owner.inventory.add(StringName(fixture.item_id), 2)
		var result: Dictionary = service.teach(StringName(fixture.item_id), creature.instance_id)
		if not service.content.move_learnable(fixture.expected_move):
			check("excluded machine move rejected " + fixture.item_id, not result.accepted and service.owner.inventory.quantity(StringName(fixture.item_id)) == 2); continue
		check("machine teaches primary-source move " + fixture.item_id, result.accepted and service.owner.owned_creature(creature.instance_id).has_move(StringName(fixture.expected_move)) and service.owner.inventory.quantity(StringName(fixture.item_id)) == 1)
		var current: CreatureInstance = service.owner.owned_creature(creature.instance_id)
		check("taught move starts with correct PP " + fixture.item_id, current.move_slot(StringName(fixture.expected_move)).current_pp == catalogs.move(StringName(fixture.expected_move)).pp)
		var before := snapshot(service.owner)
		check("already-known machine is not consumed " + fixture.item_id, not service.teach(StringName(fixture.item_id), creature.instance_id).accepted and snapshot(service.owner) == before)
		locked = true
		check("machine blocked during activity " + fixture.item_id, not service.teach(StringName(fixture.item_id), creature.instance_id).accepted and snapshot(service.owner) == before)
		locked = false
		machine_cases.append({"id": fixture.item_id, "species": chosen, "move": fixture.expected_move, "status": "TEACH_AND_CONSUMPTION_VERIFIED"})
	var service := service_for(&"eevee")
	service.owner.inventory.add(&"hm03"); var before := snapshot(service.owner)
	check("legacy HM needs explicit profile", not service.teach(&"hm03", &"item_test").accepted and snapshot(service.owner) == before)
	service.owner.inventory.add(&"tr00"); before = snapshot(service.owner)
	check("legacy TR needs explicit profile", not service.teach(&"tr00", &"item_test").accepted and snapshot(service.owner) == before)
	# Cancellation/full moveset must never forget slot zero implicitly.
	service = service_for(&"mew"); var creature: CreatureInstance = service.owner.owned_creature(&"item_test")
	creature.add_move(&"growl", catalogs); creature.add_move(&"rest", catalogs)
	service.owner.inventory.add(&"tm01", 2); before = snapshot(service.owner)
	check("full moveset requires explicit choice", service.teach(&"tm01", creature.instance_id).get("reason") == "move_replacement_required" and snapshot(service.owner) == before)
	check("explicit replacement teaches Take Down", service.teach(&"tm01", creature.instance_id, 2).accepted and service.owner.owned_creature(creature.instance_id).moveset[2].move_id == &"take_down")
	service = service_for(&"mew"); service.owner.inventory.add(&"tm01")
	service.owner.owned_creature(&"item_test").current_hp = 0
	check("teaching does not silently revive", service.teach(&"tm01", &"item_test").accepted and service.owner.owned_creature(&"item_test").current_hp == 0)


func _test_field_and_save() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	check("existing field boots", scene.is_demo_ready())
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var first: CreatureInstance = scene._session.player.party.get_creatures()[0]
	var replacement := create(&"eevee", first.instance_id)
	check("ephemeral UI setup preserves identity", scene._session.player.replace_owned_same_identity(replacement))
	scene._session.player.inventory.add(&"fire_stone"); scene._session.player.inventory.add(&"leftovers"); scene._session.player.inventory.add(&"tm01")
	check("B bag opens", scene.toggle_item_bag())
	check("bag blocks world and save", not scene.player.movement_enabled and not scene._native_battles.save_game())
	var bag: Control = scene._item_bag
	for index in bag._items.item_count:
		if bag._items.get_item_metadata(index) == "fire_stone": bag._items.select(index); break
	bag._targets.select(0); bag._refresh_choices()
	check("real bag evolves selected owned creature", bag._apply("use").accepted and scene._session.player.owned_creature(first.instance_id).species_id == &"flareon")
	for index in bag._items.item_count:
		if bag._items.get_item_metadata(index) == "tm01": bag._items.select(index); break
	bag._refresh_choices()
	check("machine preview uses current mapping rather than legacy description", bag._description.text.contains(SpanishGameText.move_name(&"take_down", catalogs)))
	bag._moves.select(1)
	check("real bag teaches explicit slot before save", bag._apply("use").accepted and scene._session.player.owned_creature(first.instance_id).moveset[0].move_id == &"take_down")
	for index in bag._items.item_count:
		if bag._items.get_item_metadata(index) == "leftovers": bag._items.select(index); break
	check("real bag equips owned Leftovers", bag._apply("equip").accepted and scene._session.player.owned_creature(first.instance_id).held_item_id == &"leftovers")
	if capture:
		await process_frame; await process_frame; await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("bag fits inside game viewport", bag.position.x >= 0 and bag.position.y >= 0 and bag.position.x + bag.size.x <= scene.get_viewport_rect().size.x and bag.position.y + bag.size.y <= scene.get_viewport_rect().size.y)
		check("field bag GPU screenshot", root.get_texture().get_image().save_png(OUT + "field_bag.png") == OK)
	bag.hide(); await process_frame
	check("bag close restores movement", scene.player.movement_enabled)
	var save_path := "user://item_connections_gpu_test_only.json" if capture else "user://item_connections_headless_test_only.json"
	scene._native_battles.save_path = save_path
	var before := snapshot(scene._session.player)
	check("real campaign save includes bag evolution", scene._native_battles.save_game())
	check("real campaign load keeps inventory and creature", await scene._native_battles.load_game() and snapshot(scene._session.player) == before)
	check("bag rebinds loaded ownership", scene.toggle_item_bag() and bag.service.owner == scene._session.player)
	bag.hide(); await process_frame
	var holder: CreatureInstance = scene._session.player.owned_creature(first.instance_id)
	holder.current_hp = maxi(1, holder.stats.max_hp - 50)
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	check("native encounter opens for item guard", scene._native_battles.view.session != null and scene._native_battles.view.session.has_active_battle())
	check("equipped item reaches native battle", scene._native_battles.view.session.battle_state().creature(first.instance_id).held_item_id == &"leftovers")
	var native: RefCounted = scene._native_battles.view.session
	var active: CreatureInstance = native.battle_state().creature(first.instance_id)
	var hp_before := active.current_hp
	var expected_heal := maxi(1, active.stats.max_hp / 16)
	var turn: Dictionary = await native.submit("move 2", native.revision)
	check("bag-equipped Leftovers heals in native turn", turn.accepted and native.battle_state().creature(first.instance_id).current_hp == mini(active.stats.max_hp, hp_before + expected_heal))
	check("native effects do not publish campaign early", scene._session.player.owned_creature(first.instance_id).current_hp == holder.current_hp)
	check("bag cannot open during battle", not scene.toggle_item_bag())
	before = snapshot(scene._session.player)
	check("direct item service cannot mutate during battle", not bag.service.equip(&"leftovers", first.instance_id).accepted and snapshot(scene._session.player) == before)
	if scene._native_battles.view.session != null: await scene._native_battles.view.session.close()
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
