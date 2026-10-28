extends RefCounted

# Explicit runtime extension; the canonical DATA V3 files remain unchanged.
const CONFIG := "res://config/pokemon_variants_v1.json"
const CANONICAL := "res://data/normalized/pokemon_api.json"
const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")


static func apply(catalog: DefinitionCatalog) -> bool:
	if catalog == null or not FileAccess.file_exists(CONFIG): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary or parsed.get("version") != 1: return false
	if parsed.get("canonical_sha256") != FileAccess.get_sha256(CANONICAL): return false
	var odds := int(parsed.get("shiny_odds_denominator", 0))
	if odds < 1: return false
	var policy := Policy.new()
	if not policy.load_local(): return false
	var pending: Array[CreatureSpecies] = []
	var definitions: Dictionary = parsed.get("regional_species", {})
	if definitions.size() != 57: return false
	for key: String in definitions:
		var species := CreatureSpecies.from_dict(definitions[key])
		var base_id := String(species.source_metadata.get("base_species_id", ""))
		if String(species.id) != key or catalog.species(StringName(base_id)) == null: return false
		if not policy.form_allowed(base_id, key): return false
		for type_id: StringName in species.type_ids_resolved():
			if catalog.type(type_id) == null: return false
		for ability: StringName in species.ability_ids:
			if catalog.ability(ability) == null: return false
		for entry: LearnSetEntry in species.learnset:
			if catalog.move(entry.move_id) == null: return false
		for evolution: EvolutionRecord in species.evolutions:
			if catalog.species(evolution.species_id) == null and not definitions.has(String(evolution.species_id)): return false
		pending.append(species)
	var shiny: Dictionary = {}
	for id: String in parsed.get("shiny_species_ids", []):
		if catalog.species(StringName(id)) == null and not definitions.has(id): return false
		shiny[id] = true
	for species: CreatureSpecies in pending: catalog.add_species(species)
	catalog.shiny_species_ids = shiny
	catalog.shiny_odds_denominator = odds
	catalog.variant_allowed_species.clear()
	for id: String in policy.eligible_ids("species"): catalog.variant_allowed_species[id] = true
	for key: String in definitions: catalog.variant_allowed_species[key] = true
	catalog.variants_enabled = true
	return true


static func choose_shiny(species_id: StringName, catalog: DefinitionCatalog,
	rng: RandomNumberGenerator, instance_id: StringName, forced: Variant = null) -> bool:
	if not catalog.variants_enabled or not catalog.shiny_species_ids.has(String(species_id)): return false
	if forced != null: return bool(forced)
	# Separate cosmetic draw: deterministic, without advancing encounter/battle RNG.
	var cosmetic := RandomNumberGenerator.new()
	var material := "%s/%s/%s" % [rng.state, instance_id, species_id]
	cosmetic.seed = material.sha256_text().substr(0, 15).hex_to_int()
	return cosmetic.randi_range(0, catalog.shiny_odds_denominator - 1) == 0
