extends RefCounted

## W03 V3 — canonical, side-effect-free Moon Ball producer. The live owner
## supplies DefinitionCatalog and the native target's BASE species identity.
## Never infer eligibility from name, type, legendary status, family or UI form.
## EvolutionRecord.version_group is *source provenance*, NOT today's game
## version; historical trigger remains relevant for later games.
const RULE_PROFILE := "moon_ball_gen7_plus_v1"
const MOON_STONE := &"moon_stone"

static func moon_context(species_id: StringName, catalogs: DefinitionCatalog) -> Dictionary:
	if catalogs == null or species_id == &"":
		return {"ok": false, "reason": "moon_species_or_catalog_missing"}
	var species: CreatureSpecies = catalogs.species(species_id)
	if species == null:
		return {"ok": false, "reason": "moon_species_unknown"}
	# The item is a real, canonical Stone definition, not a guessed name.
	if catalogs.item(MOON_STONE) == null:
		return {"ok": false, "reason": "moon_stone_catalog_missing"}
	for evolution: EvolutionRecord in species.evolutions:
		if evolution.item_id != MOON_STONE:
			continue
		# An item name in an incomplete evolution record is not a producer.
		if evolution.trigger != &"use_item" or evolution.species_id == &"" \
				or evolution.version_group == &"" or not evolution.is_default \
				or not evolution.conditions.is_empty():
			return {"ok": false, "reason": "moon_evolution_provenance_invalid"}
		if catalogs.species(evolution.species_id) == null:
			return {"ok": false, "reason": "moon_evolution_target_unknown"}
		return {"ok": true, "eligible": true,
			"profile": RULE_PROFILE, "version_group": String(evolution.version_group),
			"target_species": String(evolution.species_id)}
	return {"ok": true, "eligible": false, "profile": RULE_PROFILE}
