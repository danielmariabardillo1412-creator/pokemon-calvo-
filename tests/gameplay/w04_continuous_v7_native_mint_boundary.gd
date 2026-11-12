extends SceneTree
# W04 V7 isolated diagnosis ONLY: W02 nature mints vs native Showdown stat
# import. A refusal is the expected known deficiency, NOT a fix or native pass.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Native = preload("res://modules/gameplay/field_native_session.gd")
var failures: Array[String] = []
var checks := 0
var observed := 0

func _initialize() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
    checks += 1
    if not value: failures.append(label); push_error("W04_V7_MINT_FAIL " + label)

func make(catalog: DefinitionCatalog, sid: StringName, lvl: int,
        id: StringName) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261112
    return CreatureFactory.create(catalog.species(sid), lvl, catalog,
        ProgressionRuleset.new(), rng,
        {"instance_id": id, "nature_id": &"hardy", "moves": [&"quick_attack"]})

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    check(parsed is Dictionary, "canonical")
    if not parsed is Dictionary: quit(1); return
    var catalogs := GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalogs), "overlay")
    for sid in [&"diglett_alola", &"meowth_galar"]:
        var label := String(sid)
        var owner := PlayerCollection.new()
        var mon := make(catalogs, sid, 25, StringName("w04_v7_mint_" + label))
        mon.effective_nature_id = &"adamant"
        mon.recalculate_stats(catalogs.species(sid), ProgressionRuleset.new())
        check(mon.nature_id == &"hardy" and mon.effective_nature_id == &"adamant",
            label + "_actual_mint")
        check(owner.party.add_creature(mon), label + "_party")
        var foe := make(catalogs, &"caterpie", 50, StringName("w04_v7_mint_foe_" + label))
        foe.current_hp = 1
        var session := Native.new(catalogs, owner, {}, "gen9calvounifiedv1")
        var opened: bool = await session.begin_wild(self, foe, [23, 19, 29, 43])
        check(not opened and session.last_error.contains("Stat import mismatch"),
            label + "_known_native_stat_import_gap_" + session.last_error)
        if not opened and session.last_error.contains("Stat import mismatch"):
            observed += 1
            print("W04_V7_MINT_DEP observed=", label, " detail=", session.last_error)
        session.stop_now()
    if failures.is_empty() and observed == 2:
        print("W04_V7_MINT_DEP PASS checks=", checks, " reproduced=2 unresolved=2")
        quit(0)
    else:
        print("W04_V7_MINT_DEP FAIL errors=", JSON.stringify(failures))
        quit(1)
