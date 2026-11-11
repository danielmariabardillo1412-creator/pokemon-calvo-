extends SceneTree

const Routes = preload("res://modules/creatures/progression/regional_item_evolution_contract_w04_v2.gd")
const Forms = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const SAVE := "res://.godot/items_integration_20261111/regional_bag_save.json"
var checks := 0
var failures: Array[String] = []
var exercised := 0


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, valid: bool) -> bool:
	checks += 1
	if not valid: failures.append(label)
	return valid


func select_id(list: Variant, id: StringName) -> bool:
	for index in list.item_count:
		if StringName(list.get_item_metadata(index)) == id:
			list.select(index)
			list.item_selected.emit(index)
			return true
	return false


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/items_integration_20261111/")
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	if check("real demo ready", scene.is_demo_ready()):
		scene.player.set_physics_process(false)
		scene._native_battles.save_path = SAVE
		var actor: StringName = scene.field_collection().party.get_creatures()[0].instance_id
		var defs: DefinitionCatalog = scene.field_definitions()
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261111
		for source_id: StringName in Routes.ROUTES:
			for item_id: StringName in Routes.ROUTES[source_id]:
				var target_id: StringName = Routes.ROUTES[source_id][item_id]
				var owner: PlayerCollection = scene.field_collection()
				var creature := CreatureFactory.create(defs.species(source_id), 30, defs,
					ProgressionRuleset.new(), rng, {"instance_id": actor, "moves": [&"tackle"]})
				var legacy := exercised == 0
				if legacy: creature.form_id = &""
				check("replace owned test creature " + String(source_id), owner.replace_owned_same_identity(creature))
				check("stock " + String(item_id), owner.inventory.set_quantity(item_id, 2))
				if legacy:
					check("load old regional record without form field", scene._native_battles.save_game()
						and await scene._native_battles.load_game())
					owner = scene.field_collection()
					check("legacy record retains absent form", owner.owned_creature(actor).form_id == &"")
				var bag = scene._item_bag
				if not check("select real bag item and owner " + String(item_id), bag.open_bag()
					and select_id(bag._items, item_id) and select_id(bag._targets, actor)):
					bag.hide()
					continue
				var result: Dictionary = await bag._apply("use")
				var evolved := owner.owned_creature(actor)
				check("bag evolves and spends one " + String(item_id), result.get("accepted", false)
					and evolved.species_id == target_id and owner.inventory.quantity(item_id) == 1)
				check("canonical identity and move survive " + String(target_id), evolved.instance_id == actor
					and String(evolved.form_id) == Forms.SOURCES[String(target_id)].form_id and evolved.has_move(&"tackle"))
				bag.hide()
				check("save and load " + String(target_id), scene._native_battles.save_game()
					and await scene._native_battles.load_game())
				owner = scene.field_collection()
				check("evolution and stock persist " + String(target_id), owner.owned_creature(actor).species_id == target_id
					and owner.owned_creature(actor).form_id == evolved.form_id and owner.inventory.quantity(item_id) == 1)
				exercised += 1
		check("seven regional routes exercised", exercised == 7)
	scene.queue_free()
	await process_frame
	var result := "PASS" if failures.is_empty() else "FAIL"
	print("IA6_REGIONAL_BAG ", result, " checks=", checks, " routes=", exercised, " errors=", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
