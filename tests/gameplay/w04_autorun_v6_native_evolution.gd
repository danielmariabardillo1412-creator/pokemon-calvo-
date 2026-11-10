extends SceneTree
# TANDA06: test native regional destination identity, not item consumption from bag.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Contract = preload("res://modules/creatures/progression/regional_evolution_contract_w04.gd")
const Canonical = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const NativeSave = preload("res://modules/save/field_native_save.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, name: String) -> void:
    checks += 1
    if not ok:
        failures.append(name)
        push_error("W04_V6_FAIL " + name)

func make_mon(catalog: DefinitionCatalog, species_id: StringName, mon_id: StringName) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261111
    return CreatureFactory.create(catalog.species(species_id), 30, catalog, ProgressionRuleset.new(), rng,
        {"instance_id": mon_id, "nature_id": &"hardy", "moves": [&"tackle"]})

func roundtrip(mon: CreatureInstance, catalog: DefinitionCatalog, tag: String) -> void:
    var policy = preload("res://modules/gameplay/randomlock_content_policy.gd").new()
    check(policy.load_local(), tag + "_policy")
    check(Canonical.valid_persistent_form(mon, catalog, policy), tag + "_real_source_form")
    check(NativeSave.new()._valid_creature(mon, catalog, policy), tag + "_native_guard")
    var bag := PlayerCollection.new()
    check(bag.party.add_creature(mon), tag + "_party")
    var before := mon.to_dict()
    var snapshot := SaveGameData.build(bag.party, bag.storage, bag.inventory)
    check(snapshot.validate().ok, tag + "_valid_savev2")
    var corrupt := snapshot.to_dict().duplicate(true)
    corrupt["creatures"][0]["form_id"] = "slowpoke-galar" if mon.species_id != &"slowpoke_galar" else "slowbro-galar"
    check(not SaveGameData.from_dict(corrupt).validate().ok, tag + "_cross_species_corrupt_reject")
    var legacy := snapshot.to_dict().duplicate(true)
    legacy["creatures"][0].erase("form_id")
    check(SaveGameData.from_dict(legacy).validate().ok, tag + "_legacy_optional_form")
    var save_path: String = "user://w04_v6_" + tag + ".json"
    var repo := SaveGameRepository.new()
    check(repo.save_collection(save_path, bag).ok, tag + "_party_save")
    var loaded := repo.load(save_path)
    check(loaded.ok and loaded.party.get_creature(mon.instance_id) != null
        and loaded.party.get_creature(mon.instance_id).to_dict() == before, tag + "_party_load")
    check(bag.deposit(mon.instance_id), tag + "_deposit")
    check(repo.save_collection(save_path, bag).ok, tag + "_storage_save")
    loaded = repo.load(save_path)
    check(loaded.ok and loaded.storage.get_creature(mon.instance_id) != null
        and loaded.storage.get_creature(mon.instance_id).to_dict() == before, tag + "_storage_load")

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    check(parsed is Dictionary, "canonical_dataset")
    if not parsed is Dictionary:
        finish()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalog), "regional_overlay")
    var source_species: CreatureSpecies = catalog.species(&"slowpoke_galar")
    check(source_species != null and source_species.evolutions.size() == 2, "two_regional_evolution_records")
    var source := make_mon(catalog, &"slowpoke_galar", &"w04_v6_origin")
    check(source.form_id == &"slowpoke-galar", "canonical_producer")
    var original: Dictionary = source.to_dict()
    var paths := {
        &"galarica_cuff": &"slowbro_galar",
        &"galarica_wreath": &"slowking_galar",
    }
    var index := 0
    for item: StringName in paths:
        var target_id: StringName = paths[item]
        var option := Contract.inspect(source, item, catalog, target_id)
        var item_exists := catalog.item_catalog.has(item)
        var record: EvolutionRecord = source_species.evolutions[index]
        check(record.trigger == &"use_item" and record.item_id == item and
            record.species_id == target_id and record.conditions.is_empty()
            and record.version_group == &"the_isle_of_armor", String(item) + "_source_record")
        check(item_exists, String(item) + "_item_catalog_present")
        if item_exists:
            check(option.get("ok", false) and StringName(option.get("target_species_id", "")) == target_id
                and String(option.get("status", "")) == "L2_CONTRACT_ONLY_NO_NATIVE_CONSUMER",
                String(item) + "_pure_contract_positive")
            check(StringName(option.get("target_form_id", "")) != source.form_id
                and Canonical.structural_form_matches(String(target_id), String(option["target_form_id"])),
                String(item) + "_canonical_destination_form")
        else:
            check(not option.get("ok", false) and option.get("reason", "") == "item_absent_from_catalog",
                String(item) + "_explicit_missing_item_block")
        check(not Contract.inspect(source, item, catalog, &"pikachu").get("ok", false),
            String(item) + "_wrong_target")
        var source_wrong := CreatureInstance.from_dict(original)
        source_wrong.form_id = &"slowbro-galar"
        check(not Contract.inspect(source_wrong, item, catalog).get("ok", false),
            String(item) + "_wrong_form")
        check(not Contract.inspect(source, &"potion", catalog).get("ok", false),
            String(item) + "_wrong_item")
        var base := make_mon(catalog, &"slowpoke", &"w04_v6_base")
        check(not Contract.inspect(base, item, catalog).get("ok", false),
            String(item) + "_base_cannot_use_regional")
        var target := make_mon(catalog, target_id, StringName("w04_v6_" + String(target_id)))
        check(target.form_id != &"" and target.form_id != source.form_id and target.species_id == target_id,
            String(item) + "_target_factory_identity_not_inherited")
        roundtrip(target, catalog, String(target_id))
        # Native application must now produce the exact canonical destination form.
        # The item has NOT been consumed by this method: this is not bag-level L3.
        var engine_result := EvolutionSystem.apply_evolution(source, target_id, catalog, ProgressionRuleset.new())
        check(engine_result != null and engine_result.species_id == target_id
            and engine_result.form_id == StringName(option.get("target_form_id", "")),
            String(item) + "_native_engine_exact_destination_form")
        if engine_result != null and engine_result.form_id != &"":
            check(engine_result.instance_id == source.instance_id and engine_result.nature_id == source.nature_id
                and engine_result.experience == source.experience and engine_result.is_shiny == source.is_shiny,
                String(item) + "_persistent_identity")
            roundtrip(engine_result, catalog, "native_" + String(target_id))
        var wrong_source := make_mon(catalog, &"slowpoke", &"w04_v6_kanto_" + String(item))
        check(EvolutionSystem.apply_evolution(wrong_source, target_id, catalog, ProgressionRuleset.new()) == null,
            String(item) + "_native_kanto_rejected")
        var corrupted_source := CreatureInstance.from_dict(original)
        corrupted_source.form_id = &"slowbro-galar"
        check(EvolutionSystem.apply_evolution(corrupted_source, target_id, catalog, ProgressionRuleset.new()) == null,
            String(item) + "_native_wrong_form_rejected")
        check(source.to_dict() == original, String(item) + "_source_immutable")
        index += 1
    check(index == 2, "two_routes_examined")
    check(not Contract.inspect(source, &"", catalog).get("ok", false), "empty_item_rejected")
    roundtrip(source, catalog, "slowpoke_galar")
    print("W04_V6_NATIVE routes=", index, " native_L2=2 L3=0")
    finish()

func finish() -> void:
    if failures.is_empty():
        print("W04_AUTORUN_V6 PASS checks=", checks, " routes=2 native_L2=2 L3=0")
        quit(0)
    else:
        print("W04_AUTORUN_V6 FAIL errors=", JSON.stringify(failures))
        quit(1)
