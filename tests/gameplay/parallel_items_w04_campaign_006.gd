extends SceneTree
# IA4/W04 CAMP006: three EXISTING apple evolutions through actual visual field demo,
# its bag UI, FieldItemService and native SaveV2 bridge. No new gameplay rules.
const FIXTURE := "res://tests/fixtures/parallel_items/w04_campaign_006.json"
var checks := 0
var errors: Array[String] = []
var closed := false
var scene: Node2D

func _initialize() -> void:
    create_timer(180.0).timeout.connect(func():
        if not closed:
            check(false, "watchdog")
            finish())
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        errors.append(label)
        push_error(label)

func snapshot(collection: PlayerCollection) -> String:
    return JSON.stringify(SaveGameData.build(collection.party, collection.storage, collection.inventory).to_dict())

func make_mon(species_id: StringName, id: StringName, catalogs: DefinitionCatalog) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261104
    return CreatureFactory.create(catalogs.species(species_id), 40, catalogs, ProgressionRuleset.new(), rng,
        {"instance_id": id, "nature_id": &"hardy", "moves": ["tackle", "protect"]})

func choose_item(bag: Variant, item: StringName) -> bool:
    for index in range(bag._items.item_count):
        if StringName(bag._items.get_item_metadata(index)) == item:
            bag._items.select(index)
            bag._refresh_choices()
            return true
    return false

func choose_creature(bag: Variant, id: StringName) -> bool:
    for index in range(bag._targets.item_count):
        if StringName(bag._targets.get_item_metadata(index)) == id:
            bag._targets.select(index)
            bag._refresh_choices()
            return true
    return false

func _case(caso: Dictionary) -> void:
    var item := StringName(caso.get("item_id", ""))
    var target := StringName(caso.get("target", ""))
    var creature_id := StringName("w04_c006_" + String(item))
    var wrong_id := StringName("w04_c006_wrong_" + String(item))
    var label := String(item)
    var catalog: DefinitionCatalog = scene.field_definitions()
    var collection: PlayerCollection = scene.field_collection()
    check(collection != null and catalog != null, label + "/collection_and_catalog")
    if collection == null or catalog == null:
        return
    var mon := make_mon(&"applin", creature_id, catalog)
    var wrong := make_mon(&"pikachu", wrong_id, catalog)
    check(mon != null and wrong != null, label + "/two_real_creatures")
    if mon == null or wrong == null:
        return
    collection.party = CreatureParty.new()
    check(collection.party.add_creature(mon) and collection.party.add_creature(wrong), label + "/party_created")
    check(collection.inventory.set_quantity(item, 2), label + "/item_stock")
    var before_mon: Dictionary = mon.to_dict()
    var before: String = snapshot(collection)
    check(scene.field_can_open_item_bag(), label + "/field_demo_idle")
    var bag: Variant = scene._item_bag
    check(scene.toggle_item_bag() and bag.visible, label + "/visual_bag_open")
    check(scene.field_item_service_is_current(bag.service), label + "/service_bound_to_live_collection")
    check(choose_item(bag, item), label + "/apple_visible_in_bag")
    check(choose_creature(bag, wrong_id), label + "/wrong_species_selectable")
    var invalid: Dictionary = bag._apply("use")
    check(not invalid.get("accepted", false) and snapshot(collection) == before, label + "/wrong_species_no_spend")
    check(choose_item(bag, item) and choose_creature(bag, creature_id), label + "/applin_selected")
    check(bag.service.evolution_options(item, creature_id) == [target], label + "/unique_evolution_option")
    var success: Dictionary = bag._apply("use")
    check(success.get("accepted", false) and StringName(success.get("species_id", "")) == target, label + "/visual_bag_positive_use")
    check(bag._result.text.begins_with("¡Ha evolucionado a "), label + "/visual_success_message")
    var evolved: CreatureInstance = collection.owned_creature(creature_id)
    check(evolved != null and evolved.instance_id == creature_id and evolved.species_id == target, label + "/identity_and_target")
    check(collection.inventory.quantity(item) == 1 and collection.location_of(creature_id) == &"PARTY", label + "/exactly_one_consumed")
    if evolved == null:
        bag.hide()
        await process_frame
        return
    var after_mon: Dictionary = evolved.to_dict()
    check(before_mon.get("ivs") == after_mon.get("ivs") and before_mon.get("evs") == after_mon.get("evs") and
        before_mon.get("move_ids") == after_mon.get("move_ids") and before_mon.get("experience") == after_mon.get("experience") and
        before_mon.get("friendship") == after_mon.get("friendship") and before_mon.get("nature_id") == after_mon.get("nature_id") and
        before_mon.get("level") == after_mon.get("level"), label + "/persistent_stats_and_moves")
    check(collection.owned_creature(wrong_id) != null and collection.owned_creature(wrong_id).species_id == &"pikachu",
        label + "/other_pokemon_untouched")
    var after: String = snapshot(collection)
    var repeated: Dictionary = bag._apply("use")
    check(not repeated.get("accepted", false) and snapshot(collection) == after, label + "/cannot_evolve_twice")
    bag.hide()
    await process_frame
    var bridge: Variant = scene._native_battles
    bridge.save_path = String(caso.get("save", ""))
    check(scene.field_player_movement_enabled() and not bridge.occupied(), label + "/save_idle_boundary")
    check(bridge.save_game(), label + "/visual_native_save")
    check(collection.inventory.add(item, 1), label + "/change_live_state_before_load")
    check(collection.inventory.quantity(item) == 2, label + "/save_then_mutate_control")
    check(await bridge.load_game(), label + "/visual_native_load")
    var restored: PlayerCollection = scene.field_collection()
    check(restored != null and not is_same(collection, restored), label + "/new_loaded_collection_published")
    if restored != null:
        var persisted: CreatureInstance = restored.owned_creature(creature_id)
        check(persisted != null and persisted.species_id == target and persisted.instance_id == creature_id,
            label + "/evolved_target_loaded")
        check(restored.inventory.quantity(item) == 1 and restored.location_of(creature_id) == &"PARTY",
            label + "/spent_apple_and_party_loaded")
        if persisted != null:
            var saved_data: Dictionary = persisted.to_dict()
            check(after_mon.get("ivs") == saved_data.get("ivs") and after_mon.get("evs") == saved_data.get("evs") and
                after_mon.get("move_ids") == saved_data.get("move_ids") and after_mon.get("experience") == saved_data.get("experience") and
                after_mon.get("friendship") == saved_data.get("friendship") and after_mon.get("nature_id") == saved_data.get("nature_id"),
                label + "/attributes_loaded")
        check(restored.owned_creature(wrong_id) != null and restored.owned_creature(wrong_id).species_id == &"pikachu",
            label + "/wrong_pokemon_saved")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(String(caso.get("save", ""))))
    print("CAMP006_W04_APPLE id=", String(item), " target=", String(target), " status=L3_SCENE_BAG_AND_NATIVE_SAVEV2")

func _run() -> void:
    var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
    check(fixture is Dictionary, "fixture_json")
    if not fixture is Dictionary:
        finish()
        return
    var blocks: Array = fixture.get("blocks", [])
    check(fixture.get("campaign") == "CAMP_006" and blocks.size() == 1 and blocks[0].get("block") == "01",
        "block_01_exact")
    if blocks.size() != 1:
        finish()
        return
    scene = load("res://scenes/visual/field_demo.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    await physics_frame
    check(scene.is_demo_ready() and scene._native_battles != null and scene._item_bag != null, "real_visual_demo_ready")
    for caso: Dictionary in blocks[0].get("cases", []):
        await _case(caso)
    check(blocks[0].get("cases", []).size() == 3, "three_apples_no_new_ids")
    if scene != null and is_instance_valid(scene):
        scene.queue_free()
    await process_frame
    finish()

func finish() -> void:
    if closed:
        return
    closed = true
    if errors.is_empty():
        print("CAMP006_W04_GODOT PASS blocks=1 checks=", checks)
    else:
        print("CAMP006_W04_GODOT FAIL errors=", JSON.stringify(errors))
    quit(0 if errors.is_empty() else 1)
