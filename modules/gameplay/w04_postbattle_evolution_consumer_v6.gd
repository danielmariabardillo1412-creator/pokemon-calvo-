extends RefCounted
# W04 V6: post-settlement evolution choice. This receives REAL progression events
# emitted by ShowdownAdventureSession._finish, never awards XP or levels.
# The UI owns the pending event and decides accept/decline; the helper validates
# the current owner and route again before publishing exactly one replacement.
const LevelRoute = preload("res://modules/creatures/progression/regional_level_evolution_contract_w04_v5.gd")

static func eligible(owner: PlayerCollection, catalogs: DefinitionCatalog,
        event: ProgressionEvent) -> Dictionary:
    if owner == null or catalogs == null or event == null             or event.kind != ProgressionEvent.EVOLUTION_AVAILABLE:
        return {"ok": false, "reason": "not_evolution_event"}
    var source: CreatureInstance = owner.owned_creature(event.creature_id)
    var target := StringName(event.data.get("species_id", ""))
    if source == null or target == &"" or source.instance_id != event.creature_id:
        return {"ok": false, "reason": "not_current_owner"}
    if owner.location_of(event.creature_id) not in [&"PARTY", &"STORAGE"]:
        return {"ok": false, "reason": "ambiguous_ownership"}
    if source.species_id == target:
        return {"ok": false, "reason": "already_evolved"}
    if not LevelRoute.ROUTES.has(source.species_id):
        return {"ok": false, "reason": "outside_v6_scope"}
    var evidence := LevelRoute.inspect(source, target, catalogs)
    if not evidence.get("ok", false):
        return {"ok": false, "reason": evidence.get("reason", "invalid_route")}
    var species: CreatureSpecies = catalogs.species(source.species_id)
    var options := EvolutionSystem.evolution_candidates(species,
        EvolutionSystem.level_up_context(source), catalogs)
    var verified := false
    for rec: EvolutionRecord in options:
        if rec.species_id == target and rec.trigger == &"level_up"                 and rec.conditions.is_empty() and rec.min_level == int(event.data.get("min_level", -1)):
            verified = true
            break
    if not verified:
        return {"ok": false, "reason": "stale_or_blocked_event"}
    return {"ok": true, "source_id": source.species_id, "target_id": target,
        "creature_id": event.creature_id, "source_level": source.level,
        "source_form": source.form_id, "level": source.level}

static func decide(owner: PlayerCollection, catalogs: DefinitionCatalog,
        ruleset: ProgressionRuleset, event: ProgressionEvent,
        expected_source: Dictionary, accept: bool) -> Dictionary:
    var current := eligible(owner, catalogs, event)
    if not current.get("ok", false):
        return {"accepted": false, "reason": current.get("reason", "invalid_event")}
    for key in ["source_id", "target_id", "creature_id", "source_level", "source_form"]:
        if current.get(key) != expected_source.get(key):
            return {"accepted": false, "reason": "stale_choice"}
    if not accept:
        return {"accepted": true, "evolved": false, "creature_id": event.creature_id}
    var source: CreatureInstance = owner.owned_creature(event.creature_id)
    var evolved: CreatureInstance = ProgressionSystem.apply_evolution(source, event, catalogs, ruleset)
    if evolved == null or evolved.instance_id != source.instance_id             or evolved.species_id != current.target_id:
        return {"accepted": false, "reason": "application_failed"}
    if not owner.replace_owned_same_identity(evolved):
        return {"accepted": false, "reason": "ownership_replace_failed"}
    if owner.owned_creature(event.creature_id) != evolved:
        # Fail visibly rather than pretending a successful publication.
        return {"accepted": false, "reason": "publication_mismatch"}
    return {"accepted": true, "evolved": true,
        "creature_id": event.creature_id, "species_id": evolved.species_id,
        "form_id": evolved.form_id}
