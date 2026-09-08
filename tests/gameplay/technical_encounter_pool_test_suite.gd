class_name TechnicalEncounterPoolTestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	var catalogs := _catalogs()
	_check.call("ow_pool_catalogs_loaded", catalogs != null and catalogs.species_catalog != null)
	if catalogs == null or catalogs.species_catalog == null:
		return

	var surface := TechnicalEncounterPoolBuilder.build(
		catalogs,
		&"technical_grass",
		100,
		4,
		6,
	)
	_check.call("ow_pool_surface_builds", bool(surface.get("ok", false)))
	_check.call("ow_pool_surface_has_many_species", int(surface.get("pool_size", 0)) > 10)
	_check.call("ow_pool_surface_random_mode", bool(surface.get("random_pool", false)))
	var surface_table := surface.get("table", null) as WildEncounterTable
	_check.call("ow_pool_surface_table_valid", surface_table != null and bool(surface_table.validate(catalogs).get("ok", false)))
	if surface_table != null:
		var levels_ok := true
		var species_ok := true
		for slot in surface_table.slots:
			levels_ok = levels_ok and slot.min_level == 4 and slot.max_level == 6
			species_ok = species_ok and catalogs.species_catalog.get_by_id(slot.species_id) != null
		_check.call("ow_pool_surface_zone_levels", levels_ok)
		_check.call("ow_pool_surface_species_exist", species_ok)

	var cave := TechnicalEncounterPoolBuilder.build(
		catalogs,
		&"technical_cave_floor",
		35,
		8,
		12,
	)
	_check.call("ow_pool_cave_builds", bool(cave.get("ok", false)))
	_check.call("ow_pool_cave_zone_levels", int(cave.get("min_level", 0)) == 8 and int(cave.get("max_level", 0)) == 12)
	var cave_table := cave.get("table", null) as WildEncounterTable
	_check.call("ow_pool_cave_chance", cave_table != null and cave_table.encounter_chance_bp == 3500)

	var fixed := TechnicalEncounterPoolBuilder.build(
		catalogs,
		&"target_species",
		100,
		10,
		10,
		&"pikachu",
	)
	var fixed_table := fixed.get("table", null) as WildEncounterTable
	_check.call("ow_pool_fixed_builds", bool(fixed.get("ok", false)))
	_check.call("ow_pool_fixed_single_species", fixed_table != null and fixed_table.slots.size() == 1 and fixed_table.slots[0].species_id == &"pikachu")
	_check.call("ow_pool_fixed_not_random", not bool(fixed.get("random_pool", true)))

	var invalid := TechnicalEncounterPoolBuilder.build(
		catalogs,
		&"invalid_fixed",
		100,
		4,
		4,
		&"species_does_not_exist",
	)
	_check.call("ow_pool_unknown_fixed_rejected", not bool(invalid.get("ok", true)) and String(invalid.get("reason", "")) == "unknown_fixed_species")


func _catalogs() -> DefinitionCatalog:
	var file := FileAccess.open("res://data/normalized/pokemon_api.json", FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return null
	var data := GameData.from_dict(parsed as Dictionary)
	if data == null or data.manifest == null or not data.manifest.is_valid():
		return null
	return data.to_definition_catalog()
