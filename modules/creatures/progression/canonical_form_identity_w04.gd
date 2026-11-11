extends RefCounted
# W04 TANDA03: strictly catalog-sourced canonical regional forms.
# All 57 individually authorized catalog sources (56 new plus prior Slowpoke pilot).
# Exact form IDs were checked against the pinned pokemon and pokemon-form blobs.
# The exported game only needs this registry and its existing regional catalog.
const SOURCES := {
    "rattata_alola": {"base": "rattata", "region": "alola", "pokemon_id": 10091, "form_id": "rattata-alola"},
    "raticate_alola": {"base": "raticate", "region": "alola", "pokemon_id": 10092, "form_id": "raticate-alola"},
    "raichu_alola": {"base": "raichu", "region": "alola", "pokemon_id": 10100, "form_id": "raichu-alola"},
    "sandshrew_alola": {"base": "sandshrew", "region": "alola", "pokemon_id": 10101, "form_id": "sandshrew-alola"},
    "sandslash_alola": {"base": "sandslash", "region": "alola", "pokemon_id": 10102, "form_id": "sandslash-alola"},
    "vulpix_alola": {"base": "vulpix", "region": "alola", "pokemon_id": 10103, "form_id": "vulpix-alola"},
    "ninetales_alola": {"base": "ninetales", "region": "alola", "pokemon_id": 10104, "form_id": "ninetales-alola"},
    "diglett_alola": {"base": "diglett", "region": "alola", "pokemon_id": 10105, "form_id": "diglett-alola"},
    "dugtrio_alola": {"base": "dugtrio", "region": "alola", "pokemon_id": 10106, "form_id": "dugtrio-alola"},
    "meowth_alola": {"base": "meowth", "region": "alola", "pokemon_id": 10107, "form_id": "meowth-alola"},
    "persian_alola": {"base": "persian", "region": "alola", "pokemon_id": 10108, "form_id": "persian-alola"},
    "geodude_alola": {"base": "geodude", "region": "alola", "pokemon_id": 10109, "form_id": "geodude-alola"},
    "graveler_alola": {"base": "graveler", "region": "alola", "pokemon_id": 10110, "form_id": "graveler-alola"},
    "golem_alola": {"base": "golem", "region": "alola", "pokemon_id": 10111, "form_id": "golem-alola"},
    "grimer_alola": {"base": "grimer", "region": "alola", "pokemon_id": 10112, "form_id": "grimer-alola"},
    "muk_alola": {"base": "muk", "region": "alola", "pokemon_id": 10113, "form_id": "muk-alola"},
    "exeggutor_alola": {"base": "exeggutor", "region": "alola", "pokemon_id": 10114, "form_id": "exeggutor-alola"},
    "marowak_alola": {"base": "marowak", "region": "alola", "pokemon_id": 10115, "form_id": "marowak-alola"},
    "meowth_galar": {"base": "meowth", "region": "galar", "pokemon_id": 10161, "form_id": "meowth-galar"},
    "ponyta_galar": {"base": "ponyta", "region": "galar", "pokemon_id": 10162, "form_id": "ponyta-galar"},
    "rapidash_galar": {"base": "rapidash", "region": "galar", "pokemon_id": 10163, "form_id": "rapidash-galar"},
    "slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164, "form_id": "slowpoke-galar"},
    "slowbro_galar": {"base": "slowbro", "region": "galar", "pokemon_id": 10165, "form_id": "slowbro-galar"},
    "farfetchd_galar": {"base": "farfetchd", "region": "galar", "pokemon_id": 10166, "form_id": "farfetchd-galar"},
    "weezing_galar": {"base": "weezing", "region": "galar", "pokemon_id": 10167, "form_id": "weezing-galar"},
    "mr_mime_galar": {"base": "mr_mime", "region": "galar", "pokemon_id": 10168, "form_id": "mr-mime-galar"},
    "articuno_galar": {"base": "articuno", "region": "galar", "pokemon_id": 10169, "form_id": "articuno-galar"},
    "zapdos_galar": {"base": "zapdos", "region": "galar", "pokemon_id": 10170, "form_id": "zapdos-galar"},
    "moltres_galar": {"base": "moltres", "region": "galar", "pokemon_id": 10171, "form_id": "moltres-galar"},
    "slowking_galar": {"base": "slowking", "region": "galar", "pokemon_id": 10172, "form_id": "slowking-galar"},
    "corsola_galar": {"base": "corsola", "region": "galar", "pokemon_id": 10173, "form_id": "corsola-galar"},
    "zigzagoon_galar": {"base": "zigzagoon", "region": "galar", "pokemon_id": 10174, "form_id": "zigzagoon-galar"},
    "linoone_galar": {"base": "linoone", "region": "galar", "pokemon_id": 10175, "form_id": "linoone-galar"},
    "darumaka_galar": {"base": "darumaka", "region": "galar", "pokemon_id": 10176, "form_id": "darumaka-galar"},
    "darmanitan_galar_standard": {"base": "darmanitan", "region": "galar", "pokemon_id": 10177, "form_id": "darmanitan-galar-standard"},
    "yamask_galar": {"base": "yamask", "region": "galar", "pokemon_id": 10179, "form_id": "yamask-galar"},
    "stunfisk_galar": {"base": "stunfisk", "region": "galar", "pokemon_id": 10180, "form_id": "stunfisk-galar"},
    "growlithe_hisui": {"base": "growlithe", "region": "hisui", "pokemon_id": 10229, "form_id": "growlithe-hisui"},
    "arcanine_hisui": {"base": "arcanine", "region": "hisui", "pokemon_id": 10230, "form_id": "arcanine-hisui"},
    "voltorb_hisui": {"base": "voltorb", "region": "hisui", "pokemon_id": 10231, "form_id": "voltorb-hisui"},
    "electrode_hisui": {"base": "electrode", "region": "hisui", "pokemon_id": 10232, "form_id": "electrode-hisui"},
    "typhlosion_hisui": {"base": "typhlosion", "region": "hisui", "pokemon_id": 10233, "form_id": "typhlosion-hisui"},
    "qwilfish_hisui": {"base": "qwilfish", "region": "hisui", "pokemon_id": 10234, "form_id": "qwilfish-hisui"},
    "sneasel_hisui": {"base": "sneasel", "region": "hisui", "pokemon_id": 10235, "form_id": "sneasel-hisui"},
    "samurott_hisui": {"base": "samurott", "region": "hisui", "pokemon_id": 10236, "form_id": "samurott-hisui"},
    "lilligant_hisui": {"base": "lilligant", "region": "hisui", "pokemon_id": 10237, "form_id": "lilligant-hisui"},
    "zorua_hisui": {"base": "zorua", "region": "hisui", "pokemon_id": 10238, "form_id": "zorua-hisui"},
    "zoroark_hisui": {"base": "zoroark", "region": "hisui", "pokemon_id": 10239, "form_id": "zoroark-hisui"},
    "braviary_hisui": {"base": "braviary", "region": "hisui", "pokemon_id": 10240, "form_id": "braviary-hisui"},
    "sliggoo_hisui": {"base": "sliggoo", "region": "hisui", "pokemon_id": 10241, "form_id": "sliggoo-hisui"},
    "goodra_hisui": {"base": "goodra", "region": "hisui", "pokemon_id": 10242, "form_id": "goodra-hisui"},
    "avalugg_hisui": {"base": "avalugg", "region": "hisui", "pokemon_id": 10243, "form_id": "avalugg-hisui"},
    "decidueye_hisui": {"base": "decidueye", "region": "hisui", "pokemon_id": 10244, "form_id": "decidueye-hisui"},
    "tauros_paldea_combat_breed": {"base": "tauros", "region": "paldea", "pokemon_id": 10250, "form_id": "tauros-paldea-combat-breed"},
    "tauros_paldea_blaze_breed": {"base": "tauros", "region": "paldea", "pokemon_id": 10251, "form_id": "tauros-paldea-blaze-breed"},
    "tauros_paldea_aqua_breed": {"base": "tauros", "region": "paldea", "pokemon_id": 10252, "form_id": "tauros-paldea-aqua-breed"},
    "wooper_paldea": {"base": "wooper", "region": "paldea", "pokemon_id": 10253, "form_id": "wooper-paldea"},
}

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
    return StringName(source["form_id"])

# Structural SaveV2 check: no catalog mutation or implicit source selection.
# Native load/write additionally validates the actual species catalog + policy.
static func structural_form_matches(species_id: String, form_id: String) -> bool:
    if form_id.is_empty():
        return true
    if not SOURCES.has(species_id):
        return false
    return SOURCES[species_id]["form_id"] == form_id

static func from_factory_source(species: CreatureSpecies, catalogs: DefinitionCatalog) -> StringName:
    if species == null or catalogs == null or not catalogs.variants_enabled:
        return &""
    # The regional overlay checks policy before registering the allowed forms.
    if not catalogs.variant_allowed_species.has(String(species.id)):
        return &""
    return _canonical_source_form(species, catalogs)

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
