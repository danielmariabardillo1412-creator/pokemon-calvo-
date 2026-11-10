extends SceneTree
# W04 TANDA03 row01: six actual regional encounter producers.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const FormSource = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const NativeSave = preload("res://modules/save/field_native_save.gd")
const CASES := {
    "rattata_alola": "rattata-alola",
    "raticate_alola": "raticate-alola",
    "raichu_alola": "raichu-alola",
    "sandshrew_alola": "sandshrew-alola",
    "sandslash_alola": "sandslash-alola",
    "vulpix_alola": "vulpix-alola",
}
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func verify(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        push_error("W04_V3_ROW01_FAIL " + label)

func _run() -> void:
    var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    if not original is Dictionary:
        verify(false, "canonical_source_missing")
        _end()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(original).to_definition_catalog()
    verify(Overlay.apply(catalog), "overlay")
    var policy = preload("res://modules/gameplay/randomlock_content_policy.gd").new()
    verify(policy.load_local(), "policy")
    var repo := SaveGameRepository.new()
    var count := 0
    for key in CASES.keys():
        var sid := StringName(key)
        var species: CreatureSpecies = catalog.species(sid)
        verify(species != null, key + "_catalog")
        if species == null:
            continue
        var expected: StringName = StringName(CASES[key])
        verify(FormSource.from_factory_source(species, catalog) == expected, key + "_source")
        var table := WildEncounterTable.new(StringName("w04_v3_" + key), 10000)
        verify(table.add_slot(WildEncounterSlot.new(StringName(key + "_slot"), sid, 1, 25, 25)),
            key + "_encounter_table")
        var rng := RandomNumberGenerator.new()
        rng.seed = 1900 + count
        var result: WildEncounterResult = WildEncounterSystem.resolve(table, rng, catalog)
        verify(result.status == WildEncounterResult.ENCOUNTER and result.creature != null,
            key + "_encounter")
        if result.creature == null:
            continue
        var mon: CreatureInstance = result.creature
        verify(mon.species_id == sid and mon.form_id == expected and mon.instance_id != &"",
            key + "_factory_canonical")
        verify(FormSource.valid_persistent_form(mon, catalog, policy)
            and NativeSave.new()._valid_creature(mon, catalog, policy), key + "_native_guard")
        var owner := PlayerCollection.new()
        verify(owner.party.add_creature(mon), key + "_party")
        var before := mon.to_dict()
        var snapshot := SaveGameData.build(owner.party, owner.storage, owner.inventory)
        verify(snapshot.validate().ok and snapshot.creatures[0].get("form_id") == String(expected),
            key + "_save_structure")
        var save_path: String = "user://w04_v3_group01_" + String(key) + ".json"
        verify(repo.save_collection(save_path, owner).ok, key + "_save")
        var loaded := repo.load(save_path)
        verify(loaded.ok and loaded.party.get_creature(mon.instance_id) != null
            and loaded.party.get_creature(mon.instance_id).to_dict() == before,
            key + "_party_roundtrip")
        verify(owner.deposit(mon.instance_id), key + "_deposit")
        verify(repo.save_collection(save_path, owner).ok, key + "_storage_save")
        loaded = repo.load(save_path)
        verify(loaded.ok and loaded.storage.get_creature(mon.instance_id) != null
            and loaded.storage.get_creature(mon.instance_id).to_dict() == before,
            key + "_storage_roundtrip")
        mon.form_id = &"slowpoke-galar"
        verify(not FormSource.valid_persistent_form(mon, catalog, policy)
            and not NativeSave.new()._valid_creature(mon, catalog, policy),
            key + "_cross_species_rejection")
        mon.form_id = expected
        verify(mon.to_dict() == before, key + "_no_mutation")
        var corrupt := snapshot.to_dict().duplicate(true)
        corrupt["creatures"][0]["form_id"] = "slowpoke-galar"
        verify(not SaveGameData.from_dict(corrupt).validate().ok, key + "_structural_reject")
        count += 1
    verify(count == 6, "six_source_encounter_routes")
    var plain: CreatureSpecies = catalog.species(&"rattata")
    verify(FormSource.from_factory_source(plain, catalog) == &"",
        "base_species_never_inherits_regional_identity")
    var legacy := CreatureInstance.new(&"legacy", &"rattata", 2)
    verify(legacy.form_id == &"" and not legacy.to_dict().has("form_id"),
        "legacy_form_absence_preserved")
    _end()

func _end() -> void:
    if failures.is_empty():
        print("W04_AUTORUN_V3_ROW01 PASS checks=", checks, " sources=6")
        quit(0)
    else:
        print("W04_AUTORUN_V3_ROW01 FAIL errors=", JSON.stringify(failures))
        quit(1)
