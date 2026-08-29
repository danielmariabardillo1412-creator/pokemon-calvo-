class_name WildEncounterSystem
extends RefCounted

# Pure encounter-domain service. It knows nothing about maps, footsteps, grass animations, UI or
# battle scenes. A higher layer decides WHEN a zone asks for an encounter roll; this service decides
# whether one occurs, which slot/level is selected, and creates the persistent CreatureInstance.
# All randomness is caller-owned and injected.


static func resolve(
	table: WildEncounterTable,
	rng: RandomNumberGenerator,
	catalogs,
	progression_ruleset: ProgressionRuleset = null,
) -> WildEncounterResult:
	var out := WildEncounterResult.new()
	if table == null:
		out.reason = "missing_table"
		return out
	out.zone_id = table.zone_id
	if rng == null:
		out.reason = "missing_rng"
		return out
	if catalogs == null or catalogs.species_catalog == null:
		out.reason = "missing_catalog"
		return out

	# Validate BEFORE consuming RNG. Bad authored data must never perturb the deterministic stream.
	var validation := table.validate(catalogs)
	if not validation.ok:
		out.reason = String(validation.reason)
		return out

	# A disabled table is a valid, deterministic no-encounter and consumes no RNG.
	if table.encounter_chance_bp == 0:
		out.status = WildEncounterResult.NONE
		out.reason = "chance_miss"
		return out

	# Guaranteed chance deliberately skips the chance roll. Otherwise consume exactly one roll.
	if table.encounter_chance_bp < WildEncounterRuleset.CHANCE_BP_MAX:
		if rng.randi_range(0, WildEncounterRuleset.CHANCE_BP_MAX - 1) >= table.encounter_chance_bp:
			out.status = WildEncounterResult.NONE
			out.reason = "chance_miss"
			return out

	var slot := _select_slot(table, rng)
	if slot == null:
		# Defensive guard; a validated table should make this unreachable.
		out.reason = "selection_failed"
		return out

	var level := slot.min_level
	if slot.min_level < slot.max_level:
		level = rng.randi_range(slot.min_level, slot.max_level)

	var species: CreatureSpecies = catalogs.species_catalog.get_by_id(slot.species_id)
	if species == null:
		# Also defensive: validation already checked it, but never publish a phantom encounter.
		out.reason = "unknown_species"
		return out

	# Identity is generated from the same injected stream so a replay with the same starting state
	# reproduces the exact encounter, including instance_id. In a normal continuous stream subsequent
	# encounters naturally get different IDs.
	var id_a := rng.randi()
	var id_b := rng.randi()
	var instance_id := StringName("wild_%s_%d_%d" % [String(table.zone_id), id_a, id_b])
	var rules := progression_ruleset if progression_ruleset != null else ProgressionRuleset.new()
	var creature := CreatureFactory.create(species, level, catalogs, rules, rng, {
		"instance_id": instance_id,
	})

	out.status = WildEncounterResult.ENCOUNTER
	out.reason = ""
	out.slot_id = slot.slot_id
	out.species_id = slot.species_id
	out.level = level
	out.creature = creature
	return out


static func _select_slot(table: WildEncounterTable, rng: RandomNumberGenerator) -> WildEncounterSlot:
	if table.slots.size() == 1:
		return table.slots[0]
	var roll := rng.randi_range(1, table.total_weight())
	var cumulative := 0
	for slot in table.slots:
		cumulative += slot.weight
		if roll <= cumulative:
			return slot
	return null
