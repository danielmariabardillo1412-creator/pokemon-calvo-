extends RefCounted
# W04 TANDA03: strictly catalog-sourced canonical regional forms.
# Only first six authorized Alola identities and the prior Galar pilot are
# enabled here; no object-triggered transformation or synthetic form override.
const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const SOURCES := {
    "slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164},
    "rattata_alola": {"base": "rattata", "region": "alola", "pokemon_id": 10091},
    "raticate_alola": {"base": "raticate", "region": "alola", "pokemon_id": 10092},
    "raichu_alola": {"base": "raichu", "region": "alola", "pokemon_id": 10100},
    "sandshrew_alola": {"base": "sandshrew", "region": "alola", "pokemon_id": 10101},
    "sandslash_alola": {"base": "sandslash", "region": "alola", "pokemon_id": 10102},
    "vulpix_alola": {"base": "vulpix", "region": "alola", "pokemon_id": 10103},
}

# Obtain the exact form from the pokemon-form object referenced by pokemon,
# not from concatenating species/region strings. Reject missing/ambiguous data.
static func _api_form(source: Dictionary) -> StringName:
    var pokemon_id: int = int(source["pokemon_id"])
    var pokemon_path := "res://data/api/v2/pokemon/%d/index.json" % pokemon_id
    if not FileAccess.file_exists(pokemon_path):
        return &""
    var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(pokemon_path))
    if not (p is Dictionary):
        return &""
    if int(p.get("id", 0)) != pokemon_id or not (p.get("species") is Dictionary):
        return &""
    if String(p["species"].get("name", "")) != String(source["base"]):
        return &""
    if not (p.get("forms") is Array):
        return &""
    var found: StringName = &""
    for entry in p["forms"]:
        if not (entry is Dictionary):
            continue
        var url: String = String(entry.get("url", ""))
        if not url.begins_with("/api/v2/pokemon-form/") or not url.ends_with("/"):
            continue
        var form_text: String = url.trim_prefix("/api/v2/pokemon-form/").trim_suffix("/")
        if not form_text.is_valid_int():
            continue
        var form_id: int = int(form_text)
        if form_id <= 0:
            continue
        var path := "res://data/api/v2/pokemon-form/%d/index.json" % form_id
        if not FileAccess.file_exists(path):
            continue
        var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (f is Dictionary) or not (f.get("pokemon") is Dictionary):
            continue
        var candidate := String(entry.get("name", ""))
        if candidate == "" or int(f.get("id", 0)) != form_id:
            continue
        if String(f.get("name", "")) != candidate or String(p.get("name", "")) != candidate:
            continue
        if String(f["pokemon"].get("name", "")) != candidate:
            continue
        if String(f.get("form_name", "")) != String(source["region"]):
            continue
        if found != &"":
            return &""
        found = StringName(candidate)
    return found

static func _canonical_source_form(species: CreatureSpecies, catalogs: DefinitionCatalog) -> StringName:
    if species == null or catalogs == null:
        return &""
    var key := String(species.id)
    if not SOURCES.has(key):
        return &""
    var source: Dictionary = SOURCES[key]
    if catalogs.species(species.id) != species or catalogs.species(StringName(source["base"])) == null:
        return &""
    var metadata: Dictionary = species.source_metadata
    if String(metadata.get("base_species_id", "")) != String(source["base"]):
        return &""
    if String(metadata.get("regional_form", "")) != String(source["region"]):
        return &""
    if int(metadata.get("source_pokemon_id", 0)) != int(source["pokemon_id"]):
        return &""
    return _api_form(source)

# Structural SaveV2 check: no catalog mutation or implicit source selection.
# Native load/write additionally validates the actual species catalog + policy.
static func structural_form_matches(species_id: String, form_id: String) -> bool:
    if form_id.is_empty():
        return true
    if not SOURCES.has(species_id):
        return false
    return _api_form(SOURCES[species_id]) == StringName(form_id)

static func from_factory_source(species: CreatureSpecies, catalogs: DefinitionCatalog) -> StringName:
    var form := _canonical_source_form(species, catalogs)
    if form == &"":
        return &""
    var source: Dictionary = SOURCES[String(species.id)]
    var policy := Policy.new()
    if not policy.load_local() or not policy.form_allowed(String(source["base"]), String(form)):
        return &""
    return form

static func valid_persistent_form(creature: CreatureInstance, catalogs: DefinitionCatalog,
        policy: RefCounted) -> bool:
    if creature == null or catalogs == null or policy == null:
        return false
    if creature.form_id == &"":
        return true
    var key := String(creature.species_id)
    if not SOURCES.has(key):
        return false
    var species: CreatureSpecies = catalogs.species(creature.species_id)
    var source: Dictionary = SOURCES[key]
    return _canonical_source_form(species, catalogs) == creature.form_id and (
        policy.form_allowed(String(source["base"]), String(creature.form_id))
    )
