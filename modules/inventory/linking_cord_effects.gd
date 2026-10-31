extends RefCounted

# Read-only adapter over existing EvolutionSystem trade records. No inventory,
# creature/catalog mutation, UI, RNG or fake network trade state.
const PATH := "res://modules/inventory/linking_cord_profile_v24.json"
const HeldItems = preload("res://modules/creatures/progression/progression_held_items.gd")
static var _profile: Dictionary = {}


static func _data() -> Dictionary:
	if _profile.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary and parsed.get("schema_version") == 1:
			_profile = parsed
	return _profile


static func supports(item_id: StringName) -> bool:
	return item_id == &"linking_cord"


static func deferred_source(species_id: StringName) -> bool:
	return String(species_id) in _data().get("deferred_runtime_species", [])


static func _allowed_species(id: StringName, catalogs: DefinitionCatalog, content: RefCounted) -> bool:
	var species := catalogs.species(id)
	if species == null: return false
	var base := String(species.source_metadata.get("base_species_id", String(id)))
	if base == String(id): return content.species_allowed(base)
	return catalogs.variants_enabled and catalogs.variant_allowed_species.has(String(id)) and content.form_allowed(base, String(id))


static func targets(creature: CreatureInstance, catalogs: DefinitionCatalog, content: RefCounted) -> Array[StringName]:
	var result: Array[StringName] = []
	if creature == null or creature.is_knocked_out() or not creature.battle_transform_original.is_empty(): return result
	var data := _data()
	if HeldItems.active_item(creature, &"everstone") and String(creature.species_id) not in data.get("everstone_exception_species", []): return result
	var target := StringName(data.get("evolution_routes", {}).get(String(creature.species_id), ""))
	if target == &"" or catalogs.species(target) == null: return result
	if not _allowed_species(creature.species_id, catalogs, content) or not _allowed_species(target, catalogs, content): return result
	var species := catalogs.species(creature.species_id)
	if species == null: return result
	for record: EvolutionRecord in EvolutionSystem.evolution_candidates(species, {"traded":true}, catalogs):
		if record.trigger == EvolutionSystem.TRIGGER_TRADE and record.species_id == target:
			result.append(target); break
	return result
