class_name GameData
extends RefCounted

# Canonical, injectable aggregate of all data catalogs + manifest.
# This is what the game consumes; it is built by DataImporter and is not an autoload.
var manifest: DatasetManifest = DatasetManifest.new()
var species_catalog := SpeciesCatalog.new()
var move_catalog := MoveCatalog.new()
var type_catalog := TypeCatalog.new()
var ability_catalog := AbilityCatalog.new()
var item_catalog := ItemCatalog.new()
var status_catalog := StatusCatalog.new()

# Build the battle-runtime DefinitionCatalog facade from the focused catalogs.
func to_definition_catalog() -> DefinitionCatalog:
	var dc := DefinitionCatalog.new()
	for id in species_catalog.all_ids():
		dc.add_species(species_catalog.get_by_id(id))
	for id in move_catalog.all_ids():
		dc.add_move(move_catalog.get_by_id(id))
	for id in type_catalog.all_ids():
		dc.add_type(type_catalog.get_by_id(id))
	for id in status_catalog.all_ids():
		dc.add_status(status_catalog.get_by_id(id))
	return dc

func to_dict() -> Dictionary:
	return {
		"manifest": manifest.to_dict(),
		"types": type_catalog.to_dict(),
		"moves": move_catalog.to_dict(),
		"abilities": ability_catalog.to_dict(),
		"items": item_catalog.to_dict(),
		"statuses": status_catalog.to_dict(),
		"species": species_catalog.to_dict(),
	}

static func from_dict(d: Dictionary) -> GameData:
	var gd := GameData.new()
	gd.manifest = DatasetManifest.from_dict(d.get("manifest", {}))
	gd.type_catalog = TypeCatalog.from_dict(d.get("types", {}))
	gd.move_catalog = MoveCatalog.from_dict(d.get("moves", {}))
	gd.ability_catalog = AbilityCatalog.from_dict(d.get("abilities", {}))
	gd.item_catalog = ItemCatalog.from_dict(d.get("items", {}))
	gd.status_catalog = StatusCatalog.from_dict(d.get("statuses", {}))
	gd.species_catalog = SpeciesCatalog.from_dict(d.get("species", {}))
	return gd
