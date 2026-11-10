extends SceneTree
# TANDA02 W04: actual catalog-sourced regional encounter -> form_id ->
# Party/Storage -> SaveV2 repository and native envelope, with strict rejection.
const VariantOverlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const FormSource = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const NativeSave = preload("res://modules/save/field_native_save.gd")
var checks: int = 0
var errors: Array[String] = []
var finished := false

func _initialize() -> void:
    call_deferred("_run")
    create_timer(180.0).timeout.connect(func():
        if not finished:
            check(false, "watchdog_timeout")
            finish())

func check(ok: bool, name: String) -> void:
    checks += 1
    if not ok:
        errors.append(name)
        push_error("W04_V2 FAIL: " + name)

func create_mon(catalog: DefinitionCatalog, species_id: StringName, name: StringName, seed: int) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    return CreatureFactory.create(catalog.species(species_id), 30, catalog, ProgressionRuleset.new(), rng,
        {"instance_id": name, "nature_id": &"hardy", "moves": [&"tackle"]})

func _run() -> void:
    var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(VariantOverlay.CANONICAL))
    check(original is Dictionary, "canonical_dataset_available")
    if not original is Dictionary:
        finish()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(original).to_definition_catalog()
    check(catalog != null and VariantOverlay.apply(catalog), "real_regional_species_overlay_loaded")
    if catalog == null or catalog.species(&"slowpoke_galar") == null:
        finish()
        return
    var regional: CreatureSpecies = catalog.species(&"slowpoke_galar")
    var base: CreatureSpecies = catalog.species(&"slowpoke")
    check(FormSource.from_factory_source(regional, catalog) == &"slowpoke-galar",
        "real_PokeAPI_form_10323_from_catalog_source_10164")
    check(FormSource.from_factory_source(base, catalog) == &"",
        "base_Slowpoke_never_gets_galar_form_inferred")
    var plain: CreatureInstance = create_mon(catalog, &"slowpoke", &"plain_pilot", 33)
    check(plain.form_id == &"" and not plain.to_dict().has("form_id"),
        "base_creation_keeps_legacy_optional_form_empty")
    var created: CreatureInstance = create_mon(catalog, &"slowpoke_galar", &"regional_pilot", 33)
    check(created.form_id == &"slowpoke-galar" and created.species_id == &"slowpoke_galar"
        and created.to_dict().get("form_id") == "slowpoke-galar",
        "Factory_produces_accurate_persistent_form")
    check(created.instance_id == &"regional_pilot" and created.moveset.size() > 0
        and created.nature_id == &"hardy" and created.stats.max_hp > 1,
        "Factory_retains_identity_nature_stats_and_PP")
    var no_override: CreatureInstance = CreatureFactory.create(regional, 30, catalog,
        ProgressionRuleset.new(), RandomNumberGenerator.new(),
        {"instance_id": &"not_forced", "form_id": "alcremie-ruby-cream-berry-sweet"})
    check(no_override.form_id == &"slowpoke-galar",
        "arbitrary_factory_override_cannot_inject_fake_form")
    var clone: CreatureInstance = CreatureInstance.from_dict(
        JSON.parse_string(JSON.stringify(created.to_dict())))
    check(clone.to_dict() == created.to_dict() and clone.instance_id == created.instance_id
        and clone.form_id == created.form_id,
        "form_and_old_creature_fields_roundtrip_JSON")
    var legacy: Dictionary = created.to_dict()
    legacy.erase("form_id")
    var legacy_mon: CreatureInstance = CreatureInstance.from_dict(legacy)
    check(legacy_mon.form_id == &"" and legacy_mon.to_dict() == legacy,
        "old_save_without_form_migrates_as_unspecified_not_fake_form")
    var weird: Dictionary = created.to_dict()
    weird["form_id"] = 10323
    check(CreatureInstance.from_dict(weird).form_id == &"",
        "raw_invalid_form_type_never_inferred_during_from_dict")

    # Real engine encounter producer, not a test-created fake 'form event'.
    var table := WildEncounterTable.new(&"w04_regional_encounter", 10000)
    check(table.add_slot(WildEncounterSlot.new(&"slowpoke_galar_slot", &"slowpoke_galar",
        1, 25, 25)), "authored_existing_species_encounter_slot")
    var random := RandomNumberGenerator.new()
    random.seed = 1482
    var outcome: WildEncounterResult = WildEncounterSystem.resolve(table, random, catalog)
    check(outcome.status == WildEncounterResult.ENCOUNTER and outcome.creature != null,
        "real_WildEncounterSystem_produces_creature")
    if outcome.creature == null:
        finish()
        return
    var actual: CreatureInstance = outcome.creature
    check(actual.species_id == &"slowpoke_galar" and actual.form_id == &"slowpoke-galar"
        and actual.instance_id != &"",
        "real_encounter_sources_verified_form_no_manual_assignment")
    var policy = preload("res://modules/gameplay/randomlock_content_policy.gd").new()
    check(policy.load_local(), "real_Randomlock_policy")
    check(FormSource.valid_persistent_form(actual, catalog, policy),
        "valid_form_exact_PokeAPI_source_and_policy")
    var native = NativeSave.new()
    check(native._valid_creature(actual, catalog, policy),
        "native_creature_validation_accepts_authentic_form")
    var preserved: Dictionary = actual.to_dict()
    actual.form_id = &"slowpoke-incorrect"
    check(not FormSource.valid_persistent_form(actual, catalog, policy)
        and not native._valid_creature(actual, catalog, policy),
        "incorrect_form_rejected_before_native_publication")
    actual.form_id = &"slowpoke-galar"
    check(actual.to_dict() == preserved, "malformed_input_has_no_lingering_mutation")

    var owner := PlayerCollection.new()
    check(owner.party.add_creature(actual), "capture_moves_real_creature_into_party")
    var id := actual.instance_id
    var before: Dictionary = actual.to_dict()
    check(owner.location_of(id) == &"PARTY" and owner.owned_creature(id) == actual,
        "party_ownership_same_object")
    var snapshot := SaveGameData.build(owner.party, owner.storage, owner.inventory)
    check(snapshot.schema_version == 2 and snapshot.validate().ok
        and snapshot.creatures.size() == 1
        and snapshot.creatures[0].get("form_id") == "slowpoke-galar",
        "SaveV2_schema_unchanged_with_valid_form")
    var malicious := SaveGameData.from_dict(snapshot.to_dict().duplicate(true))
    malicious.creatures[0]["form_id"] = "sinistea-antique"
    check(not malicious.validate().ok and
        malicious.validate().reason == "invalid_creature_form_id",
        "SaveV2_wrong_species_form_refused")
    malicious = SaveGameData.from_dict(snapshot.to_dict().duplicate(true))
    malicious.creatures[0]["form_id"] = 10323
    check(not malicious.validate().ok and
        malicious.validate().reason == "invalid_creature_form_type",
        "SaveV2_form_must_have_string_type")
    malicious = SaveGameData.from_dict(snapshot.to_dict().duplicate(true))
    malicious.creatures[0].erase("form_id")
    check(malicious.validate().ok and
        CreatureInstance.from_dict(malicious.creatures[0]).form_id == &"",
        "SaveV2_legacy_without_form_still_valid")

    var repo := SaveGameRepository.new()
    var save_path := "user://w04_autorun_v2_form_test.json"
    check(repo.save_collection(save_path, owner).ok, "SaveV2_real_atomic_write_party")
    var loaded: LoadResult = repo.load(save_path)
    check(loaded.ok and loaded.schema_version == 2 and
        loaded.party.get_creature(id) != null and
        loaded.party.get_creature(id).to_dict() == before,
        "SaveV2_party_roundtrip_all_fields_exact")
    check(owner.deposit(id) and owner.location_of(id) == &"STORAGE"
        and owner.owned_creature(id) == actual, "same_object_deposit_without_duplicate")
    check(repo.save_collection(save_path, owner).ok,
        "SaveV2_real_atomic_write_storage")
    loaded = repo.load(save_path)
    var restored: CreatureInstance = loaded.storage.get_creature(id) if loaded.ok else null
    check(loaded.ok and loaded.party.get_creatures().is_empty() and restored != null
        and restored.form_id == &"slowpoke-galar" and restored.to_dict() == before,
        "SaveV2_storage_roundtrip_original_form_and_attributes")
    check(owner.withdraw(id) and owner.owned_creature(id) == actual
        and owner.location_of(id) == &"PARTY",
        "withdraw_preserves_exact_original_object")

    # Native field envelope additionally checks actual form source+Randomlock.
    var trainer := TrainerCampaignRosterOwner.new()
    var opponent: CreatureInstance = create_mon(catalog, &"mew", &"w04_trainer", 81)
    check(trainer.configure(&"w04_form_trainer", [opponent] as Array[CreatureInstance]),
        "native_trainer_owner_ready")
    var native_path := "user://w04_autorun_v2_form_native.json"
    check(native.write(native_path, owner, {}, trainer, {}, {}, catalog),
        "native_SaveV2_write_with_form")
    var native_loaded: Dictionary = native.read(native_path, catalog)
    check(native_loaded.get("ok", false)
        and native_loaded["collection"].owned_creature(id) != null
        and native_loaded["collection"].owned_creature(id).to_dict() == before,
        "native_field_envelope_roundtrip_form_and_identity")
    var native_bytes := FileAccess.get_file_as_bytes(native_path)
    actual.form_id = &"slowpoke-forged"
    check(not native.write(native_path, owner, {}, trainer, {}, {}, catalog)
        and FileAccess.get_file_as_bytes(native_path) == native_bytes,
        "native_rejects_invalid_form_without_overwriting_good_save")
    actual.form_id = &"slowpoke-galar"
    check(native.read(native_path, catalog).get("ok", false),
        "last_good_native_save_survives_rejected_write")
    check(owner.owned_creature(id) == actual and actual.to_dict() == before,
        "failed_save_does_not_mutate_actual_creature")
    print("W04_AUTORUN_V2_FORM_PILOT scope=canonical_slowpoke_galar producer=real_encounter form=slowpoke-galar savev2=2 gameplay_form_change=false")
    finish()

func finish() -> void:
    if finished:
        return
    finished = true
    if errors.is_empty():
        print("W04_AUTORUN_V2_FORM PASS checks=", checks)
    else:
        print("W04_AUTORUN_V2_FORM FAIL errors=", JSON.stringify(errors))
    quit(0 if errors.is_empty() else 1)
