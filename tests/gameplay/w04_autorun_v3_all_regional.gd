extends SceneTree
# W04 TANDA03: all 56 authorized regional encounter producers.
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
    "ninetales_alola": "ninetales-alola",
    "diglett_alola": "diglett-alola",
    "dugtrio_alola": "dugtrio-alola",
    "meowth_alola": "meowth-alola",
    "persian_alola": "persian-alola",
    "geodude_alola": "geodude-alola",
    "graveler_alola": "graveler-alola",
    "golem_alola": "golem-alola",
    "grimer_alola": "grimer-alola",
    "muk_alola": "muk-alola",
    "exeggutor_alola": "exeggutor-alola",
    "marowak_alola": "marowak-alola",
    "meowth_galar": "meowth-galar",
    "ponyta_galar": "ponyta-galar",
    "rapidash_galar": "rapidash-galar",
    "slowbro_galar": "slowbro-galar",
    "farfetchd_galar": "farfetchd-galar",
    "weezing_galar": "weezing-galar",
    "mr_mime_galar": "mr-mime-galar",
    "articuno_galar": "articuno-galar",
    "zapdos_galar": "zapdos-galar",
    "moltres_galar": "moltres-galar",
    "slowking_galar": "slowking-galar",
    "corsola_galar": "corsola-galar",
    "zigzagoon_galar": "zigzagoon-galar",
    "linoone_galar": "linoone-galar",
    "darumaka_galar": "darumaka-galar",
    "darmanitan_galar_standard": "darmanitan-galar-standard",
    "yamask_galar": "yamask-galar",
    "stunfisk_galar": "stunfisk-galar",
    "growlithe_hisui": "growlithe-hisui",
    "arcanine_hisui": "arcanine-hisui",
    "voltorb_hisui": "voltorb-hisui",
    "electrode_hisui": "electrode-hisui",
    "typhlosion_hisui": "typhlosion-hisui",
    "qwilfish_hisui": "qwilfish-hisui",
    "sneasel_hisui": "sneasel-hisui",
    "samurott_hisui": "samurott-hisui",
    "lilligant_hisui": "lilligant-hisui",
    "zorua_hisui": "zorua-hisui",
    "zoroark_hisui": "zoroark-hisui",
    "braviary_hisui": "braviary-hisui",
    "sliggoo_hisui": "sliggoo-hisui",
    "goodra_hisui": "goodra-hisui",
    "avalugg_hisui": "avalugg-hisui",
    "decidueye_hisui": "decidueye-hisui",
    "tauros_paldea_combat_breed": "tauros-paldea-combat-breed",
    "tauros_paldea_blaze_breed": "tauros-paldea-blaze-breed",
    "tauros_paldea_aqua_breed": "tauros-paldea-aqua-breed",
    "wooper_paldea": "wooper-paldea",
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
    var per_group := {}
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
        var canonical_ok := FormSource.valid_persistent_form(mon, catalog, policy)
        var native_ok := NativeSave.new()._valid_creature(mon, catalog, policy)
        if not canonical_ok or not native_ok:
            var base_key := String(species.source_metadata.get("base_species_id", String(species.id)))
            var allowed := policy.form_allowed(base_key, String(species.id))
            var bad_moves: Array[String] = []
            for slot: BattleMoveSlot in mon.moveset:
                if not policy.move_learnable(String(slot.move_id)):
                    bad_moves.append(String(slot.move_id))
            print("W04_V3_NATIVE_DIAG species=", key, " canonical=", canonical_ok,
                " native=", native_ok, " policy_species=", allowed,
                " bad_moves=", JSON.stringify(bad_moves), " move_count=", mon.moveset.size(),
                " ability=", mon.ability_id, " ability_allowed=", policy.ability_allowed(String(mon.ability_id)),
                " stats_match=", mon.stats.to_dict() == StatCalculator.compute(species.base_stat_block(), mon.ivs, mon.evs, mon.nature_id, mon.level).to_dict(),
                " status=", mon.status_state.persistent_id, " held=", mon.held_item_id)
        verify(canonical_ok and native_ok, key + "_native_guard")
        var owner := PlayerCollection.new()
        verify(owner.party.add_creature(mon), key + "_party")
        var before := mon.to_dict()
        var snapshot := SaveGameData.build(owner.party, owner.storage, owner.inventory)
        verify(snapshot.validate().ok and snapshot.creatures[0].get("form_id") == String(expected),
            key + "_save_structure")
        var save_path: String = "user://w04_v3_all_" + String(key) + ".json"
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
        var group_idx := 0
        var ordered_groups := [["rattata_alola","raticate_alola","raichu_alola","sandshrew_alola","sandslash_alola","vulpix_alola"],["ninetales_alola","diglett_alola","dugtrio_alola","meowth_alola","persian_alola","geodude_alola"],["graveler_alola","golem_alola","grimer_alola","muk_alola","exeggutor_alola","marowak_alola"],["meowth_galar","ponyta_galar","rapidash_galar","slowbro_galar","farfetchd_galar","weezing_galar"],["mr_mime_galar","articuno_galar","zapdos_galar","moltres_galar","slowking_galar","corsola_galar"],["zigzagoon_galar","linoone_galar","darumaka_galar","darmanitan_galar_standard","yamask_galar","stunfisk_galar"],["growlithe_hisui","arcanine_hisui","voltorb_hisui","electrode_hisui","typhlosion_hisui"],["qwilfish_hisui","sneasel_hisui","samurott_hisui","lilligant_hisui","zorua_hisui"],["zoroark_hisui","braviary_hisui","sliggoo_hisui","goodra_hisui","avalugg_hisui"],["decidueye_hisui","tauros_paldea_combat_breed","tauros_paldea_blaze_breed","tauros_paldea_aqua_breed","wooper_paldea"]]
        for group in ordered_groups:
            if key in group:
                per_group[group_idx] = int(per_group.get(group_idx, 0)) + 1
                break
            group_idx += 1
    verify(count == 56, "fifty_six_source_encounter_routes")
    for row in range(10):
        var expected_count := 6 if row < 6 else 5
        verify(int(per_group.get(row, 0)) == expected_count, "row_%02d_all_sources" % (row + 1))
        print("W04_V3_ROW_%02d examined=%d validated=%d" % [row + 1, expected_count, int(per_group.get(row, 0))])
    var plain: CreatureSpecies = catalog.species(&"rattata")
    verify(FormSource.from_factory_source(plain, catalog) == &"",
        "base_species_never_inherits_regional_identity")
    var legacy := CreatureInstance.new(&"legacy", &"rattata", 2)
    verify(legacy.form_id == &"" and not legacy.to_dict().has("form_id"),
        "legacy_form_absence_preserved")
    _end()

func _end() -> void:
    if failures.is_empty():
        print("W04_AUTORUN_V3_ALL PASS checks=", checks, " sources=56")
        quit(0)
    else:
        print("W04_AUTORUN_V3_ALL FAIL errors=", JSON.stringify(failures))
        quit(1)
