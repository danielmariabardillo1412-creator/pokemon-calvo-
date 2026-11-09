extends SceneTree

# IA6: primer smoke conjunto de producción W02 + W03 en rama aislada.
# NO prueba Exp Share, repelentes L3 ni fusión a main. Godot headless real.
var checks: int = 0
var errors: Array[String] = []
var completed := false

func _initialize() -> void:
	call_deferred("_run")
	create_timer(240.0).timeout.connect(func():
		if not completed:
			push_error("IA6_INTEGRATION timeout")
			quit(2)
	)

func _ck(label: String, good: bool) -> void:
	checks += 1
	if not good:
		errors.append(label)
		push_error("IA6_INTEGRATION_FAIL " + label)

func _run() -> void:
	_test_mint()
	_test_mint_extensions()
	await _test_rope()
	completed = true
	if errors.is_empty():
		print("IA6_INTEGRATION PASS checks=", checks, " features=mint_effective_nature,escape_rope_bag_savev2")
		quit(0)
	else:
		print("IA6_INTEGRATION FAIL checks=", checks, " errors=", JSON.stringify(errors))
		quit(1)

func _test_mint() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	_ck("catalog_data", raw is Dictionary)
	if not raw is Dictionary: return
	var catalog: DefinitionCatalog = GameData.from_dict(raw).to_definition_catalog()
	var species: CreatureSpecies = catalog.species(&"mew")
	_ck("mint_species", species != null)
	if species == null: return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var creature: CreatureInstance = CreatureFactory.create(
		species, 50, catalog, ProgressionRuleset.new(), rng,
		{"instance_id": &"ia6_mint", "nature_id": &"hardy", "moves": ["tackle", "growl"]})
	_ck("mint_creature", creature != null)
	if creature == null: return
	var owner := PlayerCollection.new()
	_ck("mint_party", owner.party.add_creature(creature))
	_ck("mint_inventory", owner.inventory.add(&"gentle_mint", 2))
	var original: Dictionary = creature.to_dict()
	var svc := preload("res://modules/inventory/field_item_service.gd").new()
	_ck("mint_service_binding", svc.configure(owner, catalog, func(): return true))
	var rejected: Dictionary = svc.use_item(&"gentle_mint", &"ia6_mint", 0)
	_ck("mint_invalid_target_rollback", not bool(rejected.get("accepted", true))
		and owner.inventory.quantity(&"gentle_mint") == 2
		and owner.owned_creature(&"ia6_mint").to_dict() == original)
	var result: Dictionary = svc.use_item(&"gentle_mint", &"ia6_mint")
	_ck("mint_positive", bool(result.get("accepted", false))
		and result.get("effective_nature_id") == "gentle")
	var changed: CreatureInstance = owner.owned_creature(&"ia6_mint")
	_ck("mint_preserves_original", changed != null and changed.nature_id == &"hardy")
	if changed == null: return
	_ck("mint_effective_stat", changed.effective_nature_id == &"gentle"
		and changed.stats.special_defense > creature.stats.special_defense
		and changed.stats.defense < creature.stats.defense)
	_ck("mint_consumes_one", owner.inventory.quantity(&"gentle_mint") == 1)
	var saved := SaveGameData.build(owner.party, owner.storage, owner.inventory)
	_ck("mint_savev2_validate", bool(saved.validate().get("ok", false)))
	var restored: CreatureInstance = CreatureInstance.from_dict(changed.to_dict())
	_ck("mint_snapshot_roundtrip", restored.instance_id == &"ia6_mint"
		and restored.nature_id == &"hardy"
		and restored.effective_nature_id == &"gentle"
		and restored.stats.to_dict() == changed.stats.to_dict())
	var legacy := CreatureInstance.from_dict(original)
	_ck("mint_legacy_roundtrip", legacy.nature_id == &"hardy"
		and legacy.effective_nature_id == &""
		and legacy.stats.to_dict() == creature.stats.to_dict())

# IA6: newly certified W02 MINT-L3 pilot, exercised against the combined W01/W03 tree.
# W02 has the exhaustive 180-check suite; this checks the actual service + SaveV2 seam.
func _test_mint_extensions() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	_ck("mint3_catalog", data is Dictionary)
	if not data is Dictionary: return
	var catalog: DefinitionCatalog = GameData.from_dict(data).to_definition_catalog()
	var species: CreatureSpecies = catalog.species(&"mew")
	_ck("mint3_species", species != null)
	if species == null: return
	var cases: Array = [
		{"item": &"lonely_mint", "nature": &"lonely", "up": "attack", "down": "defense"},
		{"item": &"mild_mint", "nature": &"mild", "up": "special_attack", "down": "defense"},
		{"item": &"naive_mint", "nature": &"naive", "up": "speed", "down": "special_defense"},
	]
	for spec: Dictionary in cases:
		var item_id: StringName = spec.item
		var nature: StringName = spec.nature
		var rng := RandomNumberGenerator.new()
		rng.seed = 1412
		var pokemon: CreatureInstance = CreatureFactory.create(species, 50, catalog, ProgressionRuleset.new(), rng,
			{"instance_id": &"mint3_own", "nature_id": &"hardy", "moves": ["tackle", "growl"]})
		_ck("mint3_" + String(item_id) + "_creature", pokemon != null)
		if pokemon == null: continue
		var original: Dictionary = pokemon.to_dict()
		var owner := PlayerCollection.new()
		_ck("mint3_" + String(item_id) + "_party", owner.party.add_creature(pokemon))
		_ck("mint3_" + String(item_id) + "_stock", owner.inventory.add(item_id, 2))
		var service := preload("res://modules/inventory/field_item_service.gd").new()
		_ck("mint3_" + String(item_id) + "_bind", service.configure(owner, catalog, func(): return true))
		var rejected: Dictionary = service.use_item(item_id, &"mint3_own", 0)
		_ck("mint3_" + String(item_id) + "_invalid_target_no_spend",
			not bool(rejected.get("accepted", true)) and owner.inventory.quantity(item_id) == 2
			and owner.owned_creature(&"mint3_own").to_dict() == original)
		var expected: Dictionary = StatCalculator.compute(
			species.base_stat_block(), pokemon.ivs, pokemon.evs, nature, pokemon.level).to_dict()
		var actual_result: Dictionary = service.use_item(item_id, &"mint3_own")
		var changed: CreatureInstance = owner.owned_creature(&"mint3_own")
		_ck("mint3_" + String(item_id) + "_positive",
			bool(actual_result.get("accepted", false)) and String(actual_result.get("effective_nature_id", "")) == String(nature))
		_ck("mint3_" + String(item_id) + "_identity_and_stat",
			changed != null and changed.instance_id == &"mint3_own" and changed.nature_id == &"hardy"
			and changed.effective_nature_id == nature and changed.stats.to_dict() == expected
			and int(expected[spec.up]) > int(original.stats[spec.up])
			and int(expected[spec.down]) < int(original.stats[spec.down])
			and changed.current_hp == pokemon.current_hp and changed.stats.max_hp == pokemon.stats.max_hp)
		_ck("mint3_" + String(item_id) + "_single_spend", owner.inventory.quantity(item_id) == 1)
		var second: Dictionary = service.use_item(item_id, &"mint3_own")
		_ck("mint3_" + String(item_id) + "_repeat_atomic", not bool(second.get("accepted", true))
			and String(second.get("reason", "")) == "item_has_no_effect"
			and owner.inventory.quantity(item_id) == 1 and changed.to_dict() == owner.owned_creature(&"mint3_own").to_dict())
		var snapshot := SaveGameData.build(owner.party, owner.storage, owner.inventory)
		_ck("mint3_" + String(item_id) + "_savev2", bool(snapshot.validate().get("ok", false)))
		var restored: CreatureInstance = CreatureInstance.from_dict(changed.to_dict())
		_ck("mint3_" + String(item_id) + "_reload",
			restored != null and restored.effective_nature_id == nature and restored.nature_id == &"hardy"
			and restored.stats.to_dict() == expected and restored.instance_id == &"mint3_own")
		_ck("mint3_" + String(item_id) + "_original_unchanged", pokemon.to_dict() == original)


func _test_rope() -> void:
	var scene: Node2D = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	_ck("rope_scene_boots", scene.is_demo_ready())
	if not scene.is_demo_ready():
		scene.queue_free()
		await process_frame
		return
	scene.player.set_physics_process(false)
	var owner: PlayerCollection = scene.field_collection()
	var bag: Control = scene._item_bag
	var save: Node = scene._native_battles
	save.save_path = "user://ia6_integration_mint_rope_20261109.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save.save_path))
	_ck("rope_stock_add", owner.inventory.add(&"escape_rope", 2))
	var initial: int = owner.inventory.quantity(&"escape_rope")
	var cave: OverworldPortal = scene.get_node("CaveEntrance")
	cave.fade_out_msec = 0
	cave.fade_in_msec = 0
	cave.hold_msec = 0
	var out: OverworldPortal = scene.get_node("CaveExit")
	out.fade_out_msec = 0
	out.fade_in_msec = 0
	out.hold_msec = 0
	_ck("rope_enter_cave", await scene.traversal_controller.traverse_portal(cave))
	_ck("rope_inside", scene.technical_region_id() == &"cave")
	var dest: Vector2 = scene.get_node("SurfaceCaveReturn").global_position
	_ck("rope_bag_visible", bag.open_bag() and bag.visible)
	var index := -1
	for i in bag._items.item_count:
		if String(bag._items.get_item_metadata(i)) == "escape_rope":
			index = i
	_ck("rope_inventory_selected", index >= 0)
	if index >= 0:
		bag._items.select(index)
		bag._refresh_choices()
		_ck("rope_use_enabled", not bag._use.disabled)
		bag._use.pressed.emit()
		for i in 8: await process_frame
		_ck("rope_real_transition", scene.technical_region_id() == &"surface"
			and scene.player.global_position.is_equal_approx(dest) and not bag.visible)
		_ck("rope_one_spent", owner.inventory.quantity(&"escape_rope") == initial - 1)
		_ck("rope_no_autosave", not FileAccess.file_exists(save.save_path))
		var saved: bool = save.save_game()
		_ck("rope_manual_save", saved)
		if saved:
			var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(save.save_path))
			_ck("rope_save_inventory", receipt is Dictionary
				and receipt.get("payload", {}).get("collection", {}).get("inventory", {}).get("quantities", {}).get("escape_rope", -1) == initial - 1)
			var moved_away: Vector2 = scene.get_node("CaveInteriorReturn").global_position if scene.has_node("CaveInteriorReturn") else Vector2(96, 180)
			scene.player.global_position = moved_away
			var loaded: bool = await save.load_game()
			_ck("rope_savev2_load", loaded and scene.player.global_position.is_equal_approx(dest)
				and scene.field_collection().inventory.quantity(&"escape_rope") == initial - 1)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save.save_path))
	scene.queue_free()
	await process_frame
