extends RefCounted
# W04 TANDA03: strictly catalog-sourced canonical regional forms.
# All 57 individually authorized catalog sources (56 new plus prior Slowpoke pilot).
# Exact form ID is resolved from local pokemon/pokemon-form, never synthesized.
const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const SOURCES := {
    "rattata_alola": {"base": "rattata", "region": "alola", "pokemon_id": 10091},
    "raticate_alola": {"base": "raticate", "region": "alola", "pokemon_id": 10092},
    "raichu_alola": {"base": "raichu", "region": "alola", "pokemon_id": 10100},
    "sandshrew_alola": {"base": "sandshrew", "region": "alola", "pokemon_id": 10101},
    "sandslash_alola": {"base": "sandslash", "region": "alola", "pokemon_id": 10102},
    "vulpix_alola": {"base": "vulpix", "region": "alola", "pokemon_id": 10103},
    "ninetales_alola": {"base": "ninetales", "region": "alola", "pokemon_id": 10104},
    "diglett_alola": {"base": "diglett", "region": "alola", "pokemon_id": 10105},
    "dugtrio_alola": {"base": "dugtrio", "region": "alola", "pokemon_id": 10106},
    "meowth_alola": {"base": "meowth", "region": "alola", "pokemon_id": 10107},
    "persian_alola": {"base": "persian", "region": "alola", "pokemon_id": 10108},
    "geodude_alola": {"base": "geodude", "region": "alola", "pokemon_id": 10109},
    "graveler_alola": {"base": "graveler", "region": "alola", "pokemon_id": 10110},
    "golem_alola": {"base": "golem", "region": "alola", "pokemon_id": 10111},
    "grimer_alola": {"base": "grimer", "region": "alola", "pokemon_id": 10112},
    "muk_alola": {"base": "muk", "region": "alola", "pokemon_id": 10113},
    "exeggutor_alola": {"base": "exeggutor", "region": "alola", "pokemon_id": 10114},
    "marowak_alola": {"base": "marowak", "region": "alola", "pokemon_id": 10115},
    "meowth_galar": {"base": "meowth", "region": "galar", "pokemon_id": 10161},
    "ponyta_galar": {"base": "ponyta", "region": "galar", "pokemon_id": 10162},
    "rapidash_galar": {"base": "rapidash", "region": "galar", "pokemon_id": 10163},
    "slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164},
    "slowbro_galar": {"base": "slowbro", "region": "galar", "pokemon_id": 10165},
    "farfetchd_galar": {"base": "farfetchd", "region": "galar", "pokemon_id": 10166},
    "weezing_galar": {"base": "weezing", "region": "galar", "pokemon_id": 10167},
    "mr_mime_galar": {"base": "mr_mime", "region": "galar", "pokemon_id": 10168},
    "articuno_galar": {"base": "articuno", "region": "galar", "pokemon_id": 10169},
    "zapdos_galar": {"base": "zapdos", "region": "galar", "pokemon_id": 10170},
    "moltres_galar": {"base": "moltres", "region": "galar", "pokemon_id": 10171},
    "slowking_galar": {"base": "slowking", "region": "galar", "pokemon_id": 10172},
    "corsola_galar": {"base": "corsola", "region": "galar", "pokemon_id": 10173},
    "zigzagoon_galar": {"base": "zigzagoon", "region": "galar", "pokemon_id": 10174},
    "linoone_galar": {"base": "linoone", "region": "galar", "pokemon_id": 10175},
    "darumaka_galar": {"base": "darumaka", "region": "galar", "pokemon_id": 10176},
    "darmanitan_galar_standard": {"base": "darmanitan", "region": "galar", "pokemon_id": 10177},
    "yamask_galar": {"base": "yamask", "region": "galar", "pokemon_id": 10179},
    "stunfisk_galar": {"base": "stunfisk", "region": "galar", "pokemon_id": 10180},
    "growlithe_hisui": {"base": "growlithe", "region": "hisui", "pokemon_id": 10229},
    "arcanine_hisui": {"base": "arcanine", "region": "hisui", "pokemon_id": 10230},
    "voltorb_hisui": {"base": "voltorb", "region": "hisui", "pokemon_id": 10231},
    "electrode_hisui": {"base": "electrode", "region": "hisui", "pokemon_id": 10232},
    "typhlosion_hisui": {"base": "typhlosion", "region": "hisui", "pokemon_id": 10233},
    "qwilfish_hisui": {"base": "qwilfish", "region": "hisui", "pokemon_id": 10234},
    "sneasel_hisui": {"base": "sneasel", "region": "hisui", "pokemon_id": 10235},
    "samurott_hisui": {"base": "samurott", "region": "hisui", "pokemon_id": 10236},
    "lilligant_hisui": {"base": "lilligant", "region": "hisui", "pokemon_id": 10237},
    "zorua_hisui": {"base": "zorua", "region": "hisui", "pokemon_id": 10238},
    "zoroark_hisui": {"base": "zoroark", "region": "hisui", "pokemon_id": 10239},
    "braviary_hisui": {"base": "braviary", "region": "hisui", "pokemon_id": 10240},
    "sliggoo_hisui": {"base": "sliggoo", "region": "hisui", "pokemon_id": 10241},
    "goodra_hisui": {"base": "goodra", "region": "hisui", "pokemon_id": 10242},
    "avalugg_hisui": {"base": "avalugg", "region": "hisui", "pokemon_id": 10243},
    "decidueye_hisui": {"base": "decidueye", "region": "hisui", "pokemon_id": 10244},
    "tauros_paldea_combat_breed": {"base": "tauros", "region": "paldea", "pokemon_id": 10250},
    "tauros_paldea_blaze_breed": {"base": "tauros", "region": "paldea", "pokemon_id": 10251},
    "tauros_paldea_aqua_breed": {"base": "tauros", "region": "paldea", "pokemon_id": 10252},
    "wooper_paldea": {"base": "wooper", "region": "paldea", "pokemon_id": 10253},
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
        if String(f["pokemon"].get("name", "")) != candidate or (
            String(f["pokemon"].get("url", "")) != "/api/v2/pokemon/%d/" % pokemon_id
        ):
            continue
        var form_name := String(f.get("form_name", ""))
        var region := String(source["region"])
        if form_name != region and not form_name.begins_with(region + "-"):
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
