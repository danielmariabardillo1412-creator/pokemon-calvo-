extends SceneTree
# W04 TANDA04: sanctioned normal ability promotion via real encounter producer.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const AbilityChoice = preload("res://modules/creatures/progression/regional_ability_selection_w04.gd")
const NativeSave = preload("res://modules/save/field_native_save.gd")
const EXPECTED := {
    "ponyta_galar": "pastel_veil",
    "rapidash_galar": "pastel_veil",
    "voltorb_hisui": "static",
    "electrode_hisui": "static",
}
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func verify(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        push_error("W04_V4_FAIL " + label)

func _encounter(catalog: DefinitionCatalog, id: StringName, seed: int) -> CreatureInstance:
    var table := WildEncounterTable.new(StringName("w04_v4_" + String(id)), 10000)
    if not table.add_slot(WildEncounterSlot.new(StringName(String(id) + "_slot"), id, 1, 25, 25)):
        return null
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var result: WildEncounterResult = WildEncounterSystem.resolve(table, rng, catalog)
    if result.status != WildEncounterResult.ENCOUNTER:
        return null
    return result.creature

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    if not parsed is Dictionary:
        verify(false, "canonical_dataset")
        _end()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    verify(Overlay.apply(catalog), "regional_overlay")
    var policy = preload("res://modules/gameplay/randomlock_content_policy.gd").new()
    verify(policy.load_local(), "policy_loaded")
    var repo := SaveGameRepository.new()
    var index := 0
    for id in EXPECTED.keys():
        var sid := StringName(id)
        var species: CreatureSpecies = catalog.species(sid)
        var expected: StringName = StringName(EXPECTED[id])
        verify(species != null and species.ability_slots.size() == 3, id + "_slots")
        if species == null:
            continue
        verify(species.ability_ids.has(expected) and policy.ability_allowed(String(expected))
            and not policy.ability_allowed(String(species.ability_ids[0])), id + "_policy")
        verify(AbilityChoice.select_normal(species, policy) == expected, id + "_pure_helper")
        var before_slots := species.ability_slots.duplicate(true)
        var before_ids := species.ability_ids.duplicate()
        var mon := _encounter(catalog, sid, 14000 + index)
        verify(mon != null, id + "_encounter")
        if mon == null:
            continue
        verify(mon.species_id == sid and mon.ability_id == expected and mon.form_id != &"",
            id + "_factory_real_promotion")
        verify(NativeSave.new()._valid_creature(mon, catalog, policy), id + "_native_guard")
        verify(species.ability_slots == before_slots and species.ability_ids == before_ids,
            id + "_source_immutable")
        var owner := PlayerCollection.new()
        verify(owner.party.add_creature(mon), id + "_party")
        var original := mon.to_dict()
        var path: String = "user://w04_v4_" + id + ".json"
        verify(repo.save_collection(path, owner).ok, id + "_save")
        var loaded := repo.load(path)
        verify(loaded.ok and loaded.party.get_creature(mon.instance_id) != null
            and loaded.party.get_creature(mon.instance_id).to_dict() == original, id + "_party_load")
        verify(owner.deposit(mon.instance_id), id + "_deposit")
        verify(repo.save_collection(path, owner).ok, id + "_storage_save")
        loaded = repo.load(path)
        verify(loaded.ok and loaded.storage.get_creature(mon.instance_id) != null
            and loaded.storage.get_creature(mon.instance_id).to_dict() == original,
            id + "_storage_load")
        # Explicit allowed override must keep caller choice without rerolling.
        var explicit: CreatureInstance = CreatureFactory.create(species, 25, catalog,
            ProgressionRuleset.new(), RandomNumberGenerator.new(),
            {"instance_id": StringName(id + "_forced"), "ability_id": expected, "moves": [&"tackle"]})
        verify(explicit.ability_id == expected, id + "_explicit_override")
        index += 1

    var ex: CreatureSpecies = catalog.species(&"exeggutor_alola")
    verify(ex != null and ex.ability_slots.size() == 2, "exeggutor_slots")
    if ex != null:
        verify(bool(ex.ability_slots[1].get("is_hidden", false))
            and String(ex.ability_slots[1].get("ability_id", "")) == "harvest",
            "exeggutor_harvest_hidden")
        verify(AbilityChoice.select_normal(ex, policy) == &"", "exeggutor_no_automatic_hidden")
        var blocked := _encounter(catalog, &"exeggutor_alola", 14055)
        verify(blocked != null and blocked.ability_id == &"frisk" and
            not NativeSave.new()._valid_creature(blocked, catalog, policy),
            "exeggutor_remains_native_blocked")
    var base: CreatureSpecies = catalog.species(&"ponyta")
    var plain := _encounter(catalog, &"ponyta", 14060)
    verify(plain != null and plain.form_id == &"" and
        plain.ability_id == base.ability_ids[0], "base_unchanged")
    var no_form := CreatureInstance.new(&"old_save", &"ponyta", 10)
    verify(not no_form.to_dict().has("form_id"), "legacy_form_optional")
    _end()

func _end() -> void:
    if failures.is_empty():
        print("W04_AUTORUN_V4 PASS checks=", checks, " promoted=4 blocked=1")
        quit(0)
    else:
        print("W04_AUTORUN_V4 FAIL errors=", JSON.stringify(failures))
        quit(1)
