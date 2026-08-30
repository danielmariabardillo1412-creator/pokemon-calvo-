class_name TrainerPublicCoverageBeliefInference
extends TrainerBeliefInference

# Extends the FASE22 public-information model with low-confidence move-compatibility
# priors. These are NOT claims that the opponent actually carries a move. They only
# mean the species is publicly known to have been compatible with that move in the
# imported source data. The current dataset does not preserve version_group, so this
# model must never claim exact generation/version legality.

const COVERAGE_PRIOR_MODEL := "public_species_coverage_compatibility_v1"
const METHOD_MACHINE := "machine"
const METHOD_TUTOR := "tutor"
const METHOD_EGG := "egg"

const MACHINE_PRIOR_BP := 1600
const TUTOR_PRIOR_BP := 1300
const EGG_PRIOR_BP := 900


func _seed_move_priors(
	belief: TrainerBeliefState,
	creature_id: StringName,
	species: CreatureSpecies,
	level: int,
) -> void:
	# Preserve the validated FASE22 level-up model exactly, then augment it with
	# deliberately weaker public compatibility priors.
	super._seed_move_priors(belief, creature_id, species, level)
	if belief == null or species == null or creature_id == &"":
		return

	for raw_entry in species.learnset:
		if not (raw_entry is LearnSetEntry):
			continue
		var entry := raw_entry as LearnSetEntry
		if entry.move_id == &"":
			continue
		var prior_bp := prior_for_method(entry.method)
		if prior_bp <= 0:
			continue
		var existing_confidence := belief.confidence_basis_points(
			creature_id,
			TrainerBeliefState.DOMAIN_MOVE,
			entry.move_id,
		)
		belief.set_candidate(
			creature_id,
			TrainerBeliefState.DOMAIN_MOVE,
			entry.move_id,
			maxi(existing_confidence, prior_bp),
			TrainerBeliefState.EVIDENCE_PRIOR,
			[coverage_provenance(entry.method)],
		)


static func prior_for_method(method: String) -> int:
	match method:
		METHOD_MACHINE:
			return MACHINE_PRIOR_BP
		METHOD_TUTOR:
			return TUTOR_PRIOR_BP
		METHOD_EGG:
			return EGG_PRIOR_BP
		_:
			return 0


static func is_supported_coverage_method(method: String) -> bool:
	return prior_for_method(method) > 0


static func coverage_provenance(method: String) -> String:
	return "%s:%s" % [COVERAGE_PRIOR_MODEL, method]


static func record_has_coverage_provenance(record: Dictionary) -> bool:
	for raw_value in record.get("provenance", []):
		var value := String(raw_value)
		if value.begins_with(COVERAGE_PRIOR_MODEL + ":"):
			return true
	return false
