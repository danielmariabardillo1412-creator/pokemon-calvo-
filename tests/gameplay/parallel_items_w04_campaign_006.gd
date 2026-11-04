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

func _case_trade_03(caso: Dictionary) -> void:
    var item := StringName(caso.get("item_id", ""))
    var source := StringName(caso.get("source", ""))
    var target := StringName(caso.get("target", ""))
    var label := String(item)
    var creature_id := StringName("w04_c006_03_" + label)
    var catalog: DefinitionCatalog = scene.field_definitions()
    var pc: PlayerCollection = scene.field_collection()
    check(catalog != null and pc != null and catalog.species(source) != null and catalog.species(target) != null,
        label + "/03_real_demo_catalog_and_species")
    if catalog == null or pc == null or catalog.species(source) == null:
        return
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://docs/current/ITEM_TRADE_RESTORATION_V27.json"))
    check(raw is Dictionary, label + "/03_v27_policy_file")
    if not raw is Dictionary:
        return
    var policy: Dictionary = raw
    check(policy.get("level_values_selected") == null and policy.get("future_evolution_implementation") == "DEFERRED"
        and policy.get("restored_ids", []).has(label), label + "/03_no_approved_levels_or_trade_conversion")
    check(caso.get("approved_level") == null and caso.get("post_evolution_held_item_rule") == null,
        label + "/03_no_guessed_level_or_evolution_consumption")
    var species: CreatureSpecies = catalog.species(source)
    var records := 0
    var held_record: EvolutionRecord = null
    for record: EvolutionRecord in species.evolutions:
        if record.species_id == target and record.trigger == EvolutionSystem.TRIGGER_TRADE and
            StringName(str(record.conditions.get("held_item", ""))) == item:
            records += 1
            held_record = record
    check(records == 1 and held_record != null, label + "/03_canonical_trade_held_record")
    if held_record == null:
        return
    check(held_record.min_level == 0 and EvolutionSystem.classify_record(held_record, catalog, source) == EvolutionSystem.DATA_ONLY,
        label + "/03_trade_is_not_implemented_as_level")
    var mon: CreatureInstance = make_mon(source, creature_id, catalog)
    check(mon != null, label + "/03_real_source_creature")
    if mon == null:
        return
    pc.party = CreatureParty.new()
    check(pc.party.add_creature(mon), label + "/03_party_owns_same_instance")
    check(pc.inventory.set_quantity(item, 2), label + "/03_stock_two_original_items")
    var baseline: String = snapshot(pc)
    var before: Dictionary = mon.to_dict()
    var bag: Variant = scene._item_bag
    check(scene.toggle_item_bag() and bag.visible, label + "/03_open_visual_bag")
    check(scene.field_item_service_is_current(bag.service), label + "/03_live_field_service_binding")
    check(choose_item(bag, item) and choose_creature(bag, creature_id), label + "/03_select_item_and_source")
    check(bag.service.holdable(item), label + "/03_equippable_item_from_profile")
    var direct: Dictionary = bag._apply("use")
    check(not direct.get("accepted", false) and snapshot(pc) == baseline,
        label + "/03_direct_use_rejected_without_spend")
    check(choose_item(bag, item) and choose_creature(bag, creature_id),
        label + "/03_selection_still_valid")
    var equipped: Dictionary = bag._apply("equip")
    check(equipped.get("accepted", false) and equipped.get("action") == "equip"
        and bag._result.text == "Objeto equipado.", label + "/03_positive_visual_equip")
    check(mon.instance_id == creature_id and mon.species_id == source and
        mon.held_item_id == item and not mon.held_item_consumed and
        pc.inventory.quantity(item) == 1 and pc.location_of(creature_id) == &"PARTY",
        label + "/03_held_context_preserved_without_evolution")
    var expected: Dictionary = before.duplicate(true)
    expected["held_item_id"] = label
    expected["held_item_consumed"] = false
    check(mon.to_dict() == expected, label + "/03_equip_changes_only_held_fields")
    var equipped_snapshot: String = snapshot(pc)
    var duplicate: Dictionary = bag._apply("equip")
    check(not duplicate.get("accepted", false) and snapshot(pc) == equipped_snapshot,
        label + "/03_duplicate_equip_no_extra_consumption")
    check(bag.service.evolution_options(item, creature_id).is_empty(),
        label + "/03_no_direct_use_item_route")
    var premature: Dictionary = bag.service.evolve(item, creature_id, target)
    check(not premature.get("accepted", false) and snapshot(pc) == equipped_snapshot,
        label + "/03_no_premature_trade_or_level_evolution")
    var ctx: Dictionary = EvolutionSystem.level_up_context(mon)
    check(not ctx.has("held_item_id") and not ctx.has("held_item"),
        label + "/03_shared_level_context_producer_missing")
    var candidates: Array = EvolutionSystem.evolution_candidates(species,
        {"level": 100, "item_id": item, "traded": true, "held_item_id": item}, catalog)
    check(candidates.is_empty(), label + "/03_no_invented_level100_even_with_trade_flag")
    var removed: Dictionary = bag._apply("unequip")
    check(removed.get("accepted", false) and removed.get("action") == "unequip" and
        bag._result.text == "Objeto retirado.", label + "/03_positive_visual_unequip")
    check(mon.species_id == source and mon.held_item_id == &"" and
        pc.inventory.quantity(item) == 2 and snapshot(pc) == baseline,
        label + "/03_unequip_fully_reversible")
    check(choose_item(bag, item) and choose_creature(bag, creature_id),
        label + "/03_reselect_for_native_save")
    var again: Dictionary = bag._apply("equip")
    check(again.get("accepted", false) and snapshot(pc) == equipped_snapshot,
        label + "/03_reequip_repeatable_without_conversion")
    bag.hide()
    await process_frame
    var bridge: Variant = scene._native_battles
    var uri := String(caso.get("save", ""))
    bridge.save_path = uri
    check(scene.field_player_movement_enabled() and not bridge.occupied(),
        label + "/03_idle_save_gate")
    check(bridge.save_game(), label + "/03_native_demo_save_held")
    check(pc.inventory.add(item, 1), label + "/03_staged_inventory_mutation")
    mon.held_item_id = &""
    check(pc.inventory.quantity(item) == 2 and mon.held_item_id == &"",
        label + "/03_save_then_mutate_held_context")
    check(await bridge.load_game(), label + "/03_native_demo_load_held")
    var loaded: PlayerCollection = scene.field_collection()
    check(loaded != null and not is_same(loaded, pc), label + "/03_load_new_aggregate")
    if loaded != null:
        var restored: CreatureInstance = loaded.owned_creature(creature_id)
        check(restored != null and restored.instance_id == creature_id and
            restored.species_id == source and restored.held_item_id == item and
            not restored.held_item_consumed and loaded.inventory.quantity(item) == 1 and
            loaded.location_of(creature_id) == &"PARTY", label + "/03_held_item_restored_through_savev2")
        if restored != null:
            check(restored.to_dict() == expected, label + "/03_all_other_persistent_fields_saved")
        check(scene.toggle_item_bag() and scene.field_item_service_is_current(bag.service),
            label + "/03_rebind_visual_bag_after_native_load")
        check(choose_creature(bag, creature_id), label + "/03_reselect_loaded_creature")
        var restored_unequip: Dictionary = bag._apply("unequip")
        check(restored_unequip.get("accepted", false) and
            loaded.owned_creature(creature_id).held_item_id == &"" and
            loaded.inventory.quantity(item) == 2 and loaded.owned_creature(creature_id).species_id == source,
            label + "/03_positive_unequip_after_savev2")
        bag.hide()
        await process_frame
    DirAccess.remove_absolute(ProjectSettings.globalize_path(uri))
    print("CAMP006_W04_TRADE_HELD id=", label, " source=", String(source), " target=", String(target),
        " status=L3_EQUIP_UNEQUIP_SAVEV2__TRADE_LEVEL_DEFERRED requires=IA6_approved_level_and_consumption")


func _run() -> void:
    var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
    check(fixture is Dictionary, "fixture_json")
    if not fixture is Dictionary:
        finish()
        return
    var blocks: Array = fixture.get("blocks", [])
    check(fixture.get("campaign") == "CAMP_006" and blocks.size() == 3 and blocks[0].get("block") == "01" and blocks[1].get("block") == "02" and blocks[2].get("block") == "03",
        "blocks_01_02_03_exact")
    if blocks.size() != 3:
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
    var held_cases: Array = blocks[2].get("cases", [])
    check(held_cases.size() == 2, "03_two_held_trade_routes_only")
    for caso: Dictionary in held_cases:
        await _case_trade_03(caso)
    if scene != null and is_instance_valid(scene):
        scene.queue_free()
    await process_frame
    finish()

func finish() -> void:
    if closed:
        return
    closed = true
    if errors.is_empty():
        print("CAMP006_W04_GODOT PASS blocks=3 checks=", checks)
    else:
        print("CAMP006_W04_GODOT FAIL errors=", JSON.stringify(errors))
    quit(0 if errors.is_empty() else 1)
