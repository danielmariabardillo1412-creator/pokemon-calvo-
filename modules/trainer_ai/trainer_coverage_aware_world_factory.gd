class_name TrainerCoverageAwareWorldFactory
extends TrainerThreatOrderedWorldFactory

# Keeps the four-move plausible-world cap. A publicly compatible coverage move may
# replace only the weakest non-revealed selected move, and only when its modeled
# threat is strictly greater. This gives rare dangerous coverage a path into search
# without treating compatibility as certainty or increasing branching width.

const COVERAGE_SELECTION_MODEL := "threat_relevant_public_coverage_slot_v1"


func _plausible_moves(
	context: TrainerDecisionContext,
	creature_id: StringName,
	view: Dictionary,
	species: CreatureSpecies,
	level: int,
) -> Array[StringName]:
	var selected := super._plausible_moves(context, creature_id, view, species, level)
	if context == null or species == null:
		return selected

	var candidates := _domain_candidates(context, creature_id, TrainerBeliefState.DOMAIN_MOVE)
	if candidates.is_empty():
		return selected
	var target_view := _view_by_id(context.observation.own_party, context.observation.own_active_id)
	var coverage_id := _best_omitted_coverage_candidate(selected, candidates, species, target_view)
	if coverage_id == &"":
		return selected

	if selected.size() < ProgressionRuleset.MOVE_SLOTS_MAX:
		selected.append(coverage_id)
		return _sort_by_threat(selected, candidates, view, species, target_view)

	var revealed: Dictionary = {}
	for raw_move_id in view.get("revealed_move_ids", []):
		revealed[String(raw_move_id)] = true
	var removable_index := -1
	var removable_threat := 2147483647
	for index in range(selected.size()):
		var move_id := selected[index]
		if revealed.has(String(move_id)):
			continue
		var threat := _move_threat(move_id, species, target_view)
		if removable_index < 0 or threat < removable_threat or (
			threat == removable_threat and String(move_id) > String(selected[removable_index])
		):
			removable_index = index
			removable_threat = threat
	if removable_index < 0:
		return selected

	var coverage_threat := _move_threat(coverage_id, species, target_view)
	if coverage_threat <= removable_threat:
		return selected
	selected[removable_index] = coverage_id
	return _sort_by_threat(selected, candidates, view, species, target_view)


func _best_omitted_coverage_candidate(
	selected: Array[StringName],
	candidates: Dictionary,
	species: CreatureSpecies,
	target_view: Dictionary,
) -> StringName:
	var best_id: StringName = &""
	var best_threat := -1
	var best_confidence := -1
	var keys := candidates.keys()
	keys.sort()
	for raw_key in keys:
		var move_id := StringName(raw_key)
		if move_id == &"" or selected.has(move_id):
			continue
		var record := candidates[raw_key] as Dictionary
		if not TrainerPublicCoverageBeliefInference.record_has_coverage_provenance(record):
			continue
		if _catalog.move(move_id) == null:
			continue
		var threat := _move_threat(move_id, species, target_view)
		var confidence := clampi(int(record.get("confidence_basis_points", 0)), 0, 10000)
		if threat > best_threat or (
			threat == best_threat and confidence > best_confidence
		) or (
			threat == best_threat and confidence == best_confidence
			and (best_id == &"" or String(move_id) < String(best_id))
		):
			best_id = move_id
			best_threat = threat
			best_confidence = confidence
	return best_id


func _sort_by_threat(
	moves: Array[StringName],
	candidates: Dictionary,
	view: Dictionary,
	species: CreatureSpecies,
	target_view: Dictionary,
) -> Array[StringName]:
	var confidence_by_move := _confidence_map_from_candidates(candidates, view)
	moves.sort_custom(func(a, b):
		var a_id := StringName(a)
		var b_id := StringName(b)
		var a_threat := _move_threat(a_id, species, target_view)
		var b_threat := _move_threat(b_id, species, target_view)
		if a_threat != b_threat:
			return a_threat > b_threat
		var a_conf := int(confidence_by_move.get(String(a_id), 0))
		var b_conf := int(confidence_by_move.get(String(b_id), 0))
		if a_conf != b_conf:
			return a_conf > b_conf
		return String(a_id) < String(b_id)
	)
	return moves


func _confidence_map_from_candidates(candidates: Dictionary, view: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for move_id in view.get("revealed_move_ids", []):
		out[String(move_id)] = 10000
	for key in candidates.keys():
		out[String(key)] = maxi(
			int(out.get(String(key), 0)),
			clampi(int((candidates[key] as Dictionary).get("confidence_basis_points", 0)), 0, 10000),
		)
	return out
