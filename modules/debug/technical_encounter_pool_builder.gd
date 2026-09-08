class_name TechnicalEncounterPoolBuilder
extends RefCounted

# Test-laboratory helper only. It builds WildEncounterTable values from the canonical
# species/move catalogs without changing production encounter rules. Random-pool mode
# includes every species that has at least one usable move at the zone minimum level;
# a fixed species id can be supplied for targeted/manual capture tests.


static func build(
	catalogs,
	zone_id: StringName,
	chance_percent: int,
	min_level: int,
	max_level: int,
	fixed_species_id: StringName = &"",
) -> Dictionary:
	if catalogs == null or catalogs.species_catalog == null or catalogs.move_catalog == null:
		return _failure("missing_catalog")
	if zone_id == &"":
		return _failure("empty_zone_id")

	var zone_min := clampi(min_level, 1, ProgressionRuleset.MAX_LEVEL)
	var zone_max := clampi(max_level, 1, ProgressionRuleset.MAX_LEVEL)
	if zone_max < zone_min:
		var swap := zone_min
		zone_min = zone_max
		zone_max = swap
	var chance := clampi(chance_percent, 0, 100)

	var candidates: Array[StringName] = []
	if fixed_species_id != &"":
		if catalogs.species_catalog.get_by_id(fixed_species_id) == null:
			return _failure("unknown_fixed_species")
		candidates.append(fixed_species_id)
	else:
		candidates = catalogs.species_catalog.all_ids()
		candidates.sort()

	var table := WildEncounterTable.new(zone_id, chance * 100)
	var skipped_no_moves := 0
	var eligible_ids: Array[StringName] = []
	for species_id in candidates:
		var species = catalogs.species_catalog.get_by_id(species_id)
		if species == null:
			continue
		if not _has_usable_initial_move(species, zone_min, catalogs):
			skipped_no_moves += 1
			continue
		var slot_id := StringName("technical_pool_%04d" % eligible_ids.size())
		if not table.add_slot(WildEncounterSlot.new(slot_id, species_id, 1, zone_min, zone_max)):
			return _failure("slot_rejected")
		eligible_ids.append(species_id)

	if eligible_ids.is_empty():
		return _failure("empty_eligible_pool")
	var validation := table.validate(catalogs)
	if not bool(validation.get("ok", false)):
		return _failure("table_invalid:%s" % String(validation.get("reason", "unknown")))

	return {
		"ok": true,
		"reason": "",
		"table": table,
		"zone_id": String(zone_id),
		"chance_percent": chance,
		"min_level": zone_min,
		"max_level": zone_max,
		"random_pool": fixed_species_id == &"",
		"fixed_species_id": String(fixed_species_id),
		"pool_size": eligible_ids.size(),
		"catalog_species_count": catalogs.species_catalog.size(),
		"skipped_no_moves": skipped_no_moves,
		"eligible_species_ids": eligible_ids,
	}


static func _has_usable_initial_move(species, level: int, catalogs) -> bool:
	var moves := LearnsetSystem.initial_moves(species, level)
	for raw_move_id in moves:
		var move_id := StringName(raw_move_id)
		if catalogs.move_catalog.has(move_id):
			return true
	return false


static func _failure(reason: String) -> Dictionary:
	return {
		"ok": false,
		"reason": reason,
		"table": null,
		"pool_size": 0,
		"skipped_no_moves": 0,
		"eligible_species_ids": [],
	}
