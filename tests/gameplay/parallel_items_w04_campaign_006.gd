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

func _form_snapshot_02(api_id: int) -> Dictionary:
    var path := "res://data/api/v2/pokemon-form/" + str(api_id) + "/index.json"
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    check(raw is Dictionary, "02_form_snapshot_json_" + str(api_id))
    return raw as Dictionary if raw is Dictionary else {}

func _case_form_02(caso: Dictionary) -> void:
    var item := StringName(caso.get("item_id", ""))
    var source := StringName(caso.get("source", ""))
    var target := StringName(caso.get("target", ""))
    var name := String(item)
    var creature_id := StringName("w04_c006_02_" + name)
    var catalog: DefinitionCatalog = scene.field_definitions()
    var collection: PlayerCollection = scene.field_collection()
    check(collection != null and catalog != null and catalog.species(source) != null and catalog.species(target) != null,
        name + "/02_real_demo_catalog")
    if collection == null or catalog == null or catalog.species(source) == null:
        return
    var source_form := _form_snapshot_02(int(caso.get("source_form_api_id", 0)))
    var target_form := _form_snapshot_02(int(caso.get("target_form_api_id", 0)))
    check(String(source_form.get("form_name", "")) == String(caso.get("source_form", "")) and
        String(source_form.get("pokemon", {}).get("name", "")) == String(source),
        name + "/02_canonical_source_form")
    check(String(target_form.get("pokemon", {}).get("name", "")) == String(target) and
        not bool(source_form.get("is_battle_only", true)) and not bool(target_form.get("is_battle_only", true)),
        name + "/02_source_target_are_permanent_forms")
    var mon: CreatureInstance = make_mon(source, creature_id, catalog)
    check(mon != null, name + "/02_real_creature")
    if mon == null:
        return
    collection.party = CreatureParty.new()
    check(collection.party.add_creature(mon), name + "/02_party_owns_creature")
    check(collection.inventory.set_quantity(item, 2), name + "/02_two_items")
    var before_data: Dictionary = mon.to_dict()
    var before: String = snapshot(collection)
    # This demonstrates the missing consumer/source without inventing a per-creature label.
    check(not before_data.has("form_id") and not before_data.has("source_form_id"),
        name + "/02_form_identity_not_serialized_yet")
    var bag: Variant = scene._item_bag
    check(scene.toggle_item_bag() and bag.visible, name + "/02_visual_bag_open")
    check(scene.field_item_service_is_current(bag.service), name + "/02_real_service_binding")
    check(choose_item(bag, item) and choose_creature(bag, creature_id), name + "/02_item_and_creature_selected")
    check(bag.service.evolution_options(item, creature_id) == [target], name + "/02_species_evolution_available")
    var counterpart := &"cracked_pot" if item == &"chipped_pot" else &"chipped_pot" if item == &"cracked_pot" else &"unremarkable_teacup" if item == &"masterpiece_teacup" else &"masterpiece_teacup"
    # Both pot choices are offered for the SAME individual: this must be fixed by IA6's
    # persistent form producer, not guessed at the moment the item is used.
    check(bag.service.evolution_options(counterpart, creature_id) == [target],
        name + "/02_form_gate_not_connected")
    var applied: Dictionary = bag._apply("use")
    check(applied.get("accepted", false) and StringName(applied.get("species_id", "")) == target,
        name + "/02_species_evolution_positive_from_visual_bag")
    check(bag._result.text.begins_with("¡Ha evolucionado a "), name + "/02_visual_confirmation")
    var evolved: CreatureInstance = collection.owned_creature(creature_id)
    check(evolved != null and evolved.instance_id == creature_id and evolved.species_id == target and
        collection.location_of(creature_id) == &"PARTY" and collection.inventory.quantity(item) == 1,
        name + "/02_identity_and_single_item_consumption")
    if evolved == null:
        bag.hide()
        await process_frame
        return
    var after_data: Dictionary = evolved.to_dict()
    check(before_data.get("ivs") == after_data.get("ivs") and before_data.get("evs") == after_data.get("evs") and
        before_data.get("move_ids") == after_data.get("move_ids") and before_data.get("experience") == after_data.get("experience") and
        before_data.get("friendship") == after_data.get("friendship") and before_data.get("nature_id") == after_data.get("nature_id") and
        before_data.get("level") == after_data.get("level"), name + "/02_persistent_attributes_preserved")
    check(not after_data.has("form_id") and not after_data.has("source_form_id"),
        name + "/02_evolved_form_not_serialized_yet")
    var committed: String = snapshot(collection)
    var again: Dictionary = bag._apply("use")
    check(not again.get("accepted", false) and snapshot(collection) == committed,
        name + "/02_second_use_rejected_no_spend")
    bag.hide()
    await process_frame
    var bridge: Variant = scene._native_battles
    var uri := String(caso.get("save", ""))
    bridge.save_path = uri
    check(scene.field_player_movement_enabled() and not bridge.occupied(), name + "/02_demo_save_idle")
    check(bridge.save_game(), name + "/02_native_scene_save")
    check(collection.inventory.add(item, 1), name + "/02_modify_inventory_after_save")
    check(collection.inventory.quantity(item) == 2, name + "/02_staged_mutation")
    check(await bridge.load_game(), name + "/02_native_scene_reload")
    var loaded: PlayerCollection = scene.field_collection()
    check(loaded != null and not is_same(loaded, collection), name + "/02_new_aggregate_published")
    if loaded != null:
        var saved: CreatureInstance = loaded.owned_creature(creature_id)
        check(saved != null and saved.instance_id == creature_id and saved.species_id == target and
            loaded.location_of(creature_id) == &"PARTY" and loaded.inventory.quantity(item) == 1,
            name + "/02_savev2_target_and_bag")
        if saved != null:
            var loaded_data: Dictionary = saved.to_dict()
            check(after_data.get("ivs") == loaded_data.get("ivs") and after_data.get("evs") == loaded_data.get("evs") and
                after_data.get("move_ids") == loaded_data.get("move_ids") and after_data.get("experience") == loaded_data.get("experience") and
                after_data.get("friendship") == loaded_data.get("friendship") and after_data.get("nature_id") == loaded_data.get("nature_id"),
                name + "/02_savev2_attributes")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(uri))
    print("CAMP006_W04_POT id=", name, " source=", String(source), " target=", String(target),
        " status=L3_SPECIES_EVOLUTION__FORM_AUTHENTICITY_MISSING producer=CreatureInstance_form+Capture+SaveV2")

func _run() -> void:
    var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
    check(fixture is Dictionary, "fixture_json")
    if not fixture is Dictionary:
        finish()
        return
    var blocks: Array = fixture.get("blocks", [])
    check(fixture.get("campaign") == "CAMP_006" and blocks.size() == 2 and blocks[0].get("block") == "01" and blocks[1].get("block") == "02",
        "blocks_01_02_exact")
    if blocks.size() != 2:
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
    var pot_cases: Array = blocks[1].get("cases", [])
    check(pot_cases.size() == 4, "02_four_authorized_pots_cups")
    for caso: Dictionary in pot_cases:
        await _case_form_02(caso)
    if scene != null and is_instance_valid(scene):
        scene.queue_free()
    await process_frame
    finish()

func finish() -> void:
    if closed:
        return
    closed = true
    if errors.is_empty():
        print("CAMP006_W04_GODOT PASS blocks=2 checks=", checks)
    else:
        print("CAMP006_W04_GODOT FAIL errors=", JSON.stringify(errors))
    quit(0 if errors.is_empty() else 1)
