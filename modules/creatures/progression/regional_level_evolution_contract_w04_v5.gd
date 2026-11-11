extends RefCounted
# W04 V5: pure L2 contract for ten unconditional regional level-up records.
# This is not an XP producer or game event consumer; no arbitrary source/target.
const Canonical = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const ROUTES := {
    &"diglett_alola": {&"target": &"dugtrio_alola", &"level": 26},
    &"geodude_alola": {&"target": &"graveler_alola", &"level": 25},
    &"grimer_alola": {&"target": &"muk_alola", &"level": 38},
    &"meowth_galar": {&"target": &"perrserker", &"level": 28},
    &"ponyta_galar": {&"target": &"rapidash_galar", &"level": 40},
    &"mr_mime_galar": {&"target": &"mr_rime", &"level": 42},
    &"corsola_galar": {&"target": &"cursola", &"level": 38},
    &"zigzagoon_galar": {&"target": &"linoone_galar", &"level": 20},
    &"zorua_hisui": {&"target": &"zoroark_hisui", &"level": 30},
    &"wooper_paldea": {&"target": &"clodsire", &"level": 20},
}

static func inspect(source: CreatureInstance, target_id: StringName,
        catalogs: DefinitionCatalog) -> Dictionary:
    if source == null or catalogs == null or not ROUTES.has(source.species_id):
        return {"ok": false, "reason": "not_approved_source"}
    var route: Dictionary = ROUTES[source.species_id]
    if target_id != route[&"target"]:
        return {"ok": false, "reason": "wrong_target"}
    if source.level < int(route[&"level"]):
        return {"ok": false, "reason": "below_level"}
    var source_species: CreatureSpecies = catalogs.species(source.species_id)
    var target_species: CreatureSpecies = catalogs.species(target_id)
    if source_species == null or target_species == null:
        return {"ok": false, "reason": "missing_species"}
    var source_form := Canonical.from_factory_source(source_species, catalogs)
    if source_form == &"" or source.form_id != source_form:
        return {"ok": false, "reason": "invalid_source_form"}
    var evidence := false
    for record: EvolutionRecord in source_species.evolutions:
        if record.trigger == &"level_up" and record.species_id == target_id                 and record.min_level == int(route[&"level"]) and record.conditions.is_empty():
            evidence = true
    if not evidence:
        return {"ok": false, "reason": "not_unconditional_canonical_record"}
    var target_form: StringName = &""
    if Canonical.SOURCES.has(String(target_id)):
        target_form = Canonical.from_factory_source(target_species, catalogs)
        if target_form == &"" or target_form == source.form_id:
            return {"ok": false, "reason": "target_form_not_verified"}
    # A non-regional species such as Perrserker or Clodsire must NOT inherit
    # the origin's regional form or synthesize a new one.
    return {"ok": true, "target_form_id": target_form, "min_level": int(route[&"level"])}
