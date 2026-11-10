extends RefCounted
# IA6-delegated W04 narrow PILOT: validate the true regional form produced by
# CreatureFactory from a catalog-provided slowpoke_galar species. NO generic
# base-species form synthesis, no wild-choice simulation, no form transformations.
const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const PILOT_SPECIES := &"slowpoke_galar"
const PILOT_BASE := &"slowpoke"
const PILOT_FORM := &"slowpoke-galar"
const PILOT_POKEMON_ID := 10164
const PILOT_FORM_ID := 10323

static func _canonical_source_form(species: CreatureSpecies, catalogs: DefinitionCatalog) -> StringName:
    if species == null or catalogs == null or species.id != PILOT_SPECIES:
        return &""
    if catalogs.species(PILOT_BASE) == null or catalogs.species(PILOT_SPECIES) != species:
        return &""
    var metadata: Dictionary = species.source_metadata
    if String(metadata.get("base_species_id", "")) != String(PILOT_BASE) or (
        String(metadata.get("regional_form", "")) != "galar" or
        int(metadata.get("source_pokemon_id", 0)) != PILOT_POKEMON_ID
    ):
        return &""
    var pokemon_path := "res://data/api/v2/pokemon/%d/index.json" % PILOT_POKEMON_ID
    var form_path := "res://data/api/v2/pokemon-form/%d/index.json" % PILOT_FORM_ID
    if not FileAccess.file_exists(pokemon_path) or not FileAccess.file_exists(form_path):
        return &""
    var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(pokemon_path))
    var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(form_path))
    if not (p is Dictionary and f is Dictionary):
        return &""
    if int(p.get("id", 0)) != PILOT_POKEMON_ID or (
        String(p.get("name", "")) != String(PILOT_FORM) or
        not p.get("species") is Dictionary or
        String(p["species"].get("name", "")) != String(PILOT_BASE)
    ):
        return &""
    var found := false
    for row: Variant in p.get("forms", []):
        if row is Dictionary and row.get("name") == String(PILOT_FORM) and (
            row.get("url") == "/api/v2/pokemon-form/%d/" % PILOT_FORM_ID
        ):
            found = true
    if not found or int(f.get("id", 0)) != PILOT_FORM_ID or (
        String(f.get("name", "")) != String(PILOT_FORM) or
        String(f.get("form_name", "")) != "galar" or
        not f.get("pokemon") is Dictionary or
        String(f["pokemon"].get("name", "")) != String(PILOT_FORM)
    ):
        return &""
    return PILOT_FORM


# Call ONLY when the actual source CreatureSpecies was selected by the game
# catalog/encounter; never infer forms from a bare base species or a test string.
static func from_factory_source(species: CreatureSpecies, catalogs: DefinitionCatalog) -> StringName:
    var form := _canonical_source_form(species, catalogs)
    if form == &"":
        return &""
    var policy := Policy.new()
    if not policy.load_local() or not policy.form_allowed(String(PILOT_BASE), String(form)):
        return &""
    return form


# Native SaveV2 validates against the exact same PokeAPI source as the factory.
# Absence of form_id is legacy-compatible; any nonempty unsupported form fails.
static func valid_persistent_form(creature: CreatureInstance, catalogs: DefinitionCatalog,
        policy: RefCounted) -> bool:
    if creature == null or catalogs == null or policy == null:
        return false
    if creature.form_id == &"":
        return true
    if creature.species_id != PILOT_SPECIES or creature.form_id != PILOT_FORM:
        return false
    var species: CreatureSpecies = catalogs.species(creature.species_id)
    return _canonical_source_form(species, catalogs) == creature.form_id and (
        policy.form_allowed(String(PILOT_BASE), String(creature.form_id))
    )
