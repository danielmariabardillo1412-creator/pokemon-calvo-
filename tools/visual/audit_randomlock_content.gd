extends SceneTree

const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const INDEX := "res://.godot/move_batch_catalog/index.json"
const REVIEW := "res://.godot/move_general_checks/418254331eca04dc/gpu/review.json"
const OUTPUT := "res://docs/current/CONTENT_POOL_AUDIT.json"


func _initialize() -> void:
	var policy := Policy.new()
	if not policy.load_local():
		_fail(str(policy.errors))
		return
	var review_path := REVIEW
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--review="):
			review_path = arg.trim_prefix("--review=")
	var index := _read(INDEX)
	var review := _read(review_path)
	var baseline := _read("res://.godot/move_self_body_checks/reference/baseline.json")
	if index.is_empty() or review.is_empty() or baseline.is_empty():
		_fail("Missing source evidence")
		return
	for path: String in baseline:
		if path != "head" and FileAccess.get_sha256("res://" + path) != baseline[path]:
			_fail("Immutable baseline changed: " + path)
			return
	if not review.get("pending_ids") is Dictionary or not review.get("pending_baseline_clip_ids") is Dictionary:
		_fail("Invalid review queue")
		return
	if review.get("renderer_sha256", "") != FileAccess.get_sha256("res://scenes/visual/community_move_preview.gd"):
		_fail("Review does not cover the current renderer")
		return
	if review.get("baseline_review_sha256", "") != baseline[".godot/move_temporal_batches/c5b2756454290487/review.json"]:
		_fail("Review does not refer to the frozen baseline")
		return
	var config := _read(Policy.CONFIG_PATH)
	var data := _read(Policy.DATA_PATH)
	var clips := {"eligible": 0, "excluded": 0, "pending": 0}
	var visual_ids: Array = []
	for shard: Dictionary in index.shards:
		for entry: Dictionary in shard.entries:
			var id := String(entry.move_id)
			var state := policy.move_state(id)
			if not clips.has(state):
				_fail("Unknown visual catalog move: " + id)
				return
			clips[state] += 1
			if id not in visual_ids:
				visual_ids.append(id)
	var source_gaps: Array = []
	for id: String in data.moves:
		if id not in visual_ids:
			source_gaps.append(id)
	var pending_work: Dictionary = {}
	var pending_ids: Array = []
	for kind: String in review.pending_ids:
		pending_work[kind] = policy.partition_move_ids(review.pending_ids[kind])
		for id: String in review.pending_ids[kind]:
			if id in pending_ids:
				_fail("Review move appears in two queues: " + id)
				return
			pending_ids.append(id)
	var clip_queues := {"eligible": [], "excluded": [], "pending": []}
	var clip_move_ids: Array = []
	for clip_id: String in review.pending_baseline_clip_ids:
		var id := clip_id.get_slice("/", 0)
		var state := policy.move_state(id)
		if id not in pending_ids or not clip_queues.has(state):
			_fail("Invalid pending clip: " + clip_id)
			return
		clip_queues[state].append(clip_id)
		if id not in clip_move_ids:
			clip_move_ids.append(id)
	if clip_move_ids.size() != pending_ids.size():
		_fail("Review IDs and clips disagree")
		return
	for bucket: Array in clip_queues.values():
		bucket.sort()
	var hashes: Dictionary = {}
	for path: String in [Policy.CONFIG_PATH, Policy.DATA_PATH, INDEX, review_path,
		"res://scenes/visual/community_move_preview.gd", "res://data/raw/pokemon_api.json",
		"res://modules/gameplay/randomlock_content_policy.gd", "res://tools/visual/audit_randomlock_content.gd"]:
		hashes[path.trim_prefix("res://")] = FileAccess.get_sha256(path)
	var move_partition := policy.partition_move_ids(data.moves.keys())
	var closed_ids: Array = []
	for clip_id: String in review.cumulative_closed_baseline_clip_ids:
		var id := clip_id.get_slice("/", 0)
		if id not in closed_ids:
			closed_ids.append(id)
	var report := {
		"version": 1, "profile_id": config.profile_id, "z_decision": config.z_moves.decision,
		"scope": "Selection and work triage only; eligibility is not mechanics support. Excluded/pending is not a visual PASS.",
		"source_sha256": hashes,
		"counts": {
			"canonical_moves": data.moves.size(),
			"excluded_moves_present": move_partition.excluded.size(),
			"moves_before_pending_decision": data.moves.size() - move_partition.excluded.size(),
			"pending_decision_moves": move_partition.pending.size(),
			"eligible_moves": policy.eligible_ids("moves").size(),
			"canonical_abilities": data.abilities.size(), "eligible_abilities": policy.eligible_ids("abilities").size(),
			"canonical_species": data.species.size(), "eligible_species": policy.eligible_ids("species").size(),
			"cap_forms_excluded": config.excluded_form_ids.size(),
			"visual_ids": visual_ids.size(), "visual_clips_by_state": clips,
			"historical_closed_ids": closed_ids.size(),
			"historical_closed_clips": review.cumulative_closed_baseline_clip_ids.size()
		},
		"excluded_move_ids_present": move_partition.excluded,
		"pending_z_move_ids": move_partition.pending,
		"visual_ids_by_state_count": {},
		"source_gaps": policy.partition_move_ids(source_gaps),
		"pending_visual_work": pending_work,
		"pending_visual_move_ids": policy.partition_move_ids(pending_ids),
		"pending_visual_clip_ids": clip_queues,
		"native_context_reviewed_clip_ids": review.get("native_context_reviewed_clip_ids", []),
		"external_presentation_handoffs": review.get("external_handoffs", []),
		"excluded_ability_ids": config.excluded_ability_ids,
		"excluded_species_ids": config.excluded_species_ids,
		"excluded_form_ids": config.excluded_form_ids,
		"note": "All forms of excluded base species are excluded. Original art reviews, source resources and data are preserved. No final randomizer is implemented here."
	}
	var visual_partition := policy.partition_move_ids(visual_ids)
	for state: String in visual_partition:
		report.visual_ids_by_state_count[state] = visual_partition[state].size()
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file == null:
		_fail("Cannot write audit")
		return
	file.store_string(JSON.stringify(report, "  ", true) + "\n")
	file.close()
	print("CONTENT AUDIT PASS: ", JSON.stringify(report.counts))
	print("Work queue: ", JSON.stringify(report.pending_visual_move_ids))
	quit(0)


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
