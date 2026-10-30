extends "res://modules/battle/backends/showdown/showdown_backend.gd"

# Opt-in application session. Reuses collection/capture/escape/progression;
# the inherited native backend owns all combat. Campaign changes publish once,
# synchronously, after a terminal result. No legacy BattleState is executed.
var player: PlayerCollection
var catalogs: DefinitionCatalog
var progression_ruleset := ProgressionRuleset.new()
var completion_reason := ""
var battle_kind := ""
var opponent_trainer_id := &""
var inventory: PlayerInventory
var escape_attempts := 0
var _baseline := ""
var _started := false
var _command_busy := false
var _settled := false
var _capture_rng := RandomNumberGenerator.new()
var _escape_rng := RandomNumberGenerator.new()
const Medicine = preload("res://modules/inventory/battle_medicine_profile.gd")
const Escape = preload("res://modules/inventory/battle_escape_profile.gd")
var _spent_items := {}


func _init(catalog: DefinitionCatalog, collection: PlayerCollection, p_format: String = "gen9customgame") -> void:
	super(catalog, p_format)
	catalogs = catalog
	player = collection
	commit_guard = _campaign_unchanged


func begin_wild(tree: SceneTree, wild: CreatureInstance, seed: Array = [1, 2, 3, 4], adventure_seed: int = 701) -> bool:
	var roster: Array[CreatureInstance] = []
	if wild != null: roster.append(wild)
	return await _begin(tree, roster, "wild", &"", seed, adventure_seed)


func begin_trainer(tree: SceneTree, trainer_id: StringName, roster: Array[CreatureInstance], seed: Array = [1, 2, 3, 4]) -> bool:
	if trainer_id == &"": last_error = "trainer_id_required"; return false
	return await _begin(tree, roster, "trainer", trainer_id, seed, 701)


func _begin(tree: SceneTree, opponents: Array[CreatureInstance], kind: String, trainer_id: StringName, seed: Array, adventure_seed: int) -> bool:
	if _started or player == null or player.inventory.corrupted or player.storage.is_corrupted(): last_error = "invalid_or_active_session"; return false
	var own: Array[CreatureInstance] = []
	var other: Array[CreatureInstance] = []
	for creature: CreatureInstance in player.party.get_creatures():
		if player.storage.contains_instance_id(creature.instance_id): last_error = "duplicate_ownership"; return false
		if not creature.is_knocked_out(): own.append(creature)
	for creature: CreatureInstance in opponents:
		if creature == null or player.owned_creature(creature.instance_id) != null: last_error = "opponent_identity_conflict"; return false
		if not creature.is_knocked_out(): other.append(creature)
	if own.is_empty() or other.is_empty(): last_error = "no_available_creature"; return false
	_baseline = _campaign_stamp()
	inventory = PlayerInventory.from_dict(player.inventory.to_dict())
	_started = true
	battle_kind = kind
	opponent_trainer_id = trainer_id
	_capture_rng.seed = adventure_seed
	_escape_rng.seed = adventure_seed + 1
	var ok: bool = await super.open(tree, own, other, seed)
	if not ok: _started = false; return false
	if not _campaign_unchanged(): await close(); last_error = "campaign_changed"; return false
	return true


func has_active_battle() -> bool:
	return _started and not _settled and completion_reason.is_empty() and _client != null


func phase() -> String:
	if not completion_reason.is_empty(): return "finished"
	return super.phase()


func submit(choice: String, expected_revision: int) -> Dictionary:
	if _command_busy or not has_active_battle() or not _campaign_unchanged(): return _command_rejected("inactive_or_changed_campaign")
	return await super.submit(choice, expected_revision)


func submit_reaction(_kind: String, _expected_revision: int) -> Dictionary:
	return {"accepted": false, "error": "use_capture_or_flee_command", "events": []}


func submit_medicine(_command: Dictionary, _expected_revision: int) -> Dictionary:
	return {"accepted": false, "error": "use_item_command", "events": []}


func use_item(item_id: StringName, target_id: StringName, expected_revision: int, move_slot: int = -1) -> Dictionary:
	if not has_active_battle() or busy or _command_busy or needs_recovery or phase() != "move" or expected_revision != revision or not _campaign_unchanged(): return _command_rejected("invalid_item_boundary")
	if Escape.supports(item_id): return _use_escape_item(item_id, target_id, expected_revision, move_slot)
	if not Medicine.supports(item_id) or catalogs.item(item_id) == null: return _command_rejected("item_not_battle_usable")
	if not inventory.has(item_id): return _command_rejected("item_not_owned")
	var target := battle_state().creature(target_id)
	if target == null or not battle_state().sides[0].owns(target_id) or target.is_knocked_out(): return _command_rejected("invalid_living_own_target")
	_command_busy = true
	var bag := PlayerInventory.from_dict(inventory.to_dict())
	bag.remove(item_id)
	var result: Dictionary = await super.submit_medicine({"item_id": String(item_id), "target_id": String(target_id), "move_slot": move_slot}, expected_revision)
	if result.accepted:
		inventory = bag
		_record_spent(item_id)
	_command_busy = false
	return result


func battle_item_usable(item_id: StringName) -> bool:
	return Medicine.supports(item_id) or battle_kind == "wild" and Escape.permitted(item_id, catalogs)


func _use_escape_item(item_id: StringName, target_id: StringName, expected_revision: int, move_slot: int) -> Dictionary:
	if not _external_ready(expected_revision) or not Escape.permitted(item_id, catalogs): return _command_rejected("escape_item_not_usable")
	if move_slot != -1: return _command_rejected("escape_item_unexpected_move")
	var actor := battle_state().active_for_side(&"side_a")
	if actor == null or actor.is_knocked_out() or actor.instance_id != target_id: return _command_rejected("escape_item_requires_active_actor")
	var bag := PlayerInventory.from_dict(inventory.to_dict())
	if not bag.remove(item_id): return _command_rejected("item_not_owned")
	_command_busy = true
	# Guaranteed item escape bypasses trapping and speed rolls. Finish validates
	# and publishes synchronously; no enemy turn, RNG draw or partial spending.
	var result := _finish("FLED", bag)
	if result.accepted:
		_record_spent(item_id)
		result["item_id"] = String(item_id)
		result["escape_resolution"] = Escape.resolution(escape_attempts)
	_command_busy = false
	return result


func _record_spent(id: StringName) -> void:
	_spent_items[String(id)] = int(_spent_items.get(String(id), 0)) + 1


func capture(ball_id: StringName, expected_revision: int) -> Dictionary:
	if not _external_ready(expected_revision): return _command_rejected("invalid_capture_boundary")
	_command_busy = true
	# Stage mutable domain services; rejected native reactions cannot spend a ball,
	# advance capture RNG, or add a creature to the live player's collection.
	var bag := PlayerInventory.from_dict(inventory.to_dict())
	var party := CreatureParty.from_dict(player.party.to_dict())
	var rng := RandomNumberGenerator.new(); rng.state = _capture_rng.state
	var context := CaptureBattleContext.new(); context.is_wild = true; context.target_side_id = &"side_b"
	context.completed_turns = battle_state().turn
	var catcher := battle_state().active_for_side(&"side_a")
	if catcher != null: context.catcher_level = catcher.level
	var target := _persistent_copy(battle_state().active_for_side(&"side_b"))
	var resolution := CaptureInventoryService.resolve(CaptureAttempt.new(target, ball_id, context), rng, catalogs, party, bag)
	if resolution.result.status == CaptureResult.INVALID:
		_command_busy = false; return _rejected(resolution.result.reason)
	if resolution.result.status == CaptureResult.SUCCESS:
		var result := _finish("CAPTURED", bag, resolution)
		if result.accepted:
			_capture_rng.state = rng.state
			_record_spent(ball_id)
			result["capture_outcome"] = {"capture": resolution.to_dict()}
		_command_busy = false
		return result
	var response: Dictionary = await super.submit_reaction("capture_failed", expected_revision)
	if response.accepted:
		inventory = bag; _capture_rng.state = rng.state
		_record_spent(ball_id)
		response["capture_result"] = resolution.result.to_dict()
		response["capture_outcome"] = {"capture": resolution.to_dict()}
	_command_busy = false
	return response


func flee(expected_revision: int) -> Dictionary:
	if not _external_ready(expected_revision): return _command_rejected("invalid_escape_boundary")
	_command_busy = true
	var active := battle_state().active_for_side(&"side_a")
	var wild := battle_state().active_for_side(&"side_b")
	var native: Dictionary = Adapter.roster_row(_checkpoint, String(active.instance_id))
	var blocked := bool(native.get("trapped", false))
	var rng := RandomNumberGenerator.new(); rng.state = _escape_rng.state
	var escape: WildEscapeResolution
	if blocked:
		escape = WildEscapeResolution.new(); escape.attempt = escape_attempts
	else:
		escape = WildEscapeRuleset.new().resolve(active.stats.speed, wild.stats.speed, escape_attempts + 1, rng)
	if not escape.reason.is_empty(): _command_busy = false; return _rejected(escape.reason)
	if escape.escaped:
		var result := _finish("FLED", inventory)
		if result.accepted:
			_escape_rng.state = rng.state; escape_attempts = escape.attempt
			result["escape_resolution"] = _escape_dict(escape)
		_command_busy = false; return result
	var response: Dictionary = await super.submit_reaction("escape_blocked" if blocked else "escape_failed", expected_revision)
	if response.accepted:
		_escape_rng.state = rng.state; escape_attempts = escape.attempt
		response["escape_attempt"] = escape.attempt
		response["escape_blocked"] = blocked
		response["escape_resolution"] = _escape_dict(escape)
	_command_busy = false
	return response


func _external_ready(expected_revision: int) -> bool:
	return has_active_battle() and battle_kind == "wild" and not busy and not _command_busy and not needs_recovery and phase() == "move" and expected_revision == revision and _campaign_unchanged()


static func _escape_dict(result: WildEscapeResolution) -> Dictionary:
	return {"escaped": result.escaped, "attempt": result.attempt, "odds": result.odds, "roll": result.roll, "rng_consumed": result.rng_consumed, "reason": result.reason}


func _command_rejected(reason: String) -> Dictionary:
	# A competing command must not release the IPC lock owned by the first one.
	last_error = reason
	return {"accepted": false, "error": reason, "events": []}


func settle_finished_battle() -> Dictionary:
	if busy or _command_busy or not has_active_battle() or super.phase() != "finished": return _command_rejected("battle_not_ready_for_settlement")
	var winner := String(_checkpoint.views.p1.winner)
	return _finish("VICTORY" if winner == "Player" else ("DEFEAT" if winner == "Opponent" else "DRAW"), inventory)


func _finish(reason: String, bag: PlayerInventory, capture_resolution: CaptureResolution = null) -> Dictionary:
	if _settled or not _campaign_unchanged(): return _rejected("campaign_changed_or_already_settled")
	var party := CreatureParty.from_dict(player.party.to_dict())
	var state := battle_state()
	for cid: StringName in state.sides[0].party_ids:
		var creature := _persistent_copy(state.creature(cid))
		if not party.replace_same_identity(creature): return _rejected("party_identity_missing")
	var outcome := BattleOutcome.new()
	var progression: Array = []
	if reason in ["VICTORY", "DEFEAT"]:
		# Existing outcome builder expects a CREATURE identity, unlike the UI mirror's
		# side label. Never let its historical first-side fallback turn a loss into XP.
		var winner_side := &"side_a" if reason == "VICTORY" else &"side_b"
		var previous := state.winner_id
		state.winner_id = state.active_for_side(winner_side).instance_id
		outcome = BattleOutcome.from_battle_state(state, catalogs)
		state.winner_id = previous
		if reason == "VICTORY": progression = ProgressionSystem.reconcile_battle_result(party.get_creatures(), outcome, catalogs, progression_ruleset, ProgressionSystem.HeldItems.starting_items_from_records(_origin.p1))
	var routing: CaptureRoutingResult
	if capture_resolution != null:
		var captured := capture_resolution.captured
		if captured == null or player.owned_creature(captured.instance_id) != null: return _rejected("capture_identity_conflict")
		captured.reconcile_post_battle()
		# Route before applying any other campaign writes. Storage expands using its
		# existing ownership service; full parties never discard a captured identity.
		if capture_resolution.disposition == CaptureDisposition.PARTY and not player.party.add_creature(captured): return _rejected("capture_party_rejected")
		routing = CaptureOwnershipRouter.new().route(capture_resolution, player.party, player.storage)
		if not routing.routed:
			if capture_resolution.disposition == CaptureDisposition.PARTY: player.party.remove_creature(captured.instance_id)
			return _rejected("capture_routing_failed")
	# All preflight checks finished. No await/callback occurs during this publication.
	# Preserve the original owned objects and party order for map/UI references.
	for staged: CreatureInstance in party.get_creatures():
		var owned := player.party.get_creature(staged.instance_id)
		for key: String in staged.to_dict():
			if key not in ["instance_id", "battle_transform"]: owned.set(key, staged.get(key))
	for id: StringName in player.inventory.all_item_ids(): player.inventory.set_quantity(id, bag.quantity(id))
	inventory = bag
	_settled = true; completion_reason = reason; revision += 1
	return {"accepted": true, "events": [], "completion_reason": reason, "outcome": outcome.to_dict(), "progression_events": progression, "stored": routing.stored if routing != null else false, "revision": revision}


func _persistent_copy(source: CreatureInstance) -> CreatureInstance:
	# Use the prebattle identity/ability/stat baseline: temporary Skill Swap and
	# stat changes must never become persistent collection data.
	var origin: Dictionary = {}
	for side: String in ["p1", "p2"]:
		for row: Dictionary in _origin[side]:
			if row.instance_id == String(source.instance_id): origin = row
	var copy := CreatureInstance.from_dict(origin)
	var native: Dictionary = Adapter.roster_row(_checkpoint, String(source.instance_id))
	copy.current_hp = int(native.get("persistent_hp", source.current_hp))
	copy.held_item_id = source.held_item_id; copy.held_item_consumed = source.held_item_consumed
	copy.status_state = BattleStatusState.from_dict(source.status_state.to_dict())
	copy.status_ids = source.status_ids.duplicate()
	copy.status_state.turns_remaining = int(native.get("status_time", 0))
	copy.status_state.toxic_counter = int(native.get("toxic_stage", 0))
	# Native base slots preserve paid Transform/Mimic PP and discard virtual copies.
	# Sketch may legitimately replace a base slot; never persist the display overlay.
	if native.get("base_moves") is Array:
		copy.moveset.clear(); copy.move_ids.clear()
		for slot: Dictionary in native.base_moves:
			if not _moves.has(String(slot.id)): last_error = "unmapped_persistent_move"; return null
			var id := StringName(_moves[String(slot.id)])
			copy.moveset.append(BattleMoveSlot.new(id, int(slot.max_pp), int(slot.pp))); copy.move_ids.append(id)
	else:
		for i in copy.moveset.size(): copy.moveset[i] = BattleMoveSlot.from_dict(source.moveset[i].to_dict())
	copy.reconcile_post_battle()
	return copy


func _campaign_stamp() -> String:
	var stored: Array = []
	for c: CreatureInstance in player.storage.get_all_creatures(): stored.append(c.to_dict())
	return JSON.stringify([player.party.to_dict(), player.inventory.to_dict(), player.storage.to_dict(), stored]).sha256_text()


func _campaign_unchanged() -> bool:
	return player != null and not _baseline.is_empty() and _campaign_stamp() == _baseline


func snapshot() -> Dictionary:
	var data := super.snapshot()
	data["adventure"] = {"schema_version": 2, "medicine_profile_sha256": FileAccess.get_sha256(Medicine.PATH), "spent_items": _spent_items.duplicate(true), "campaign_stamp": _baseline, "kind": battle_kind, "trainer_id": String(opponent_trainer_id),
		"inventory": inventory.to_dict() if inventory != null else {}, "capture_rng": str(_capture_rng.state), "escape_rng": str(_escape_rng.state), "escape_attempts": escape_attempts,
		"completion_reason": completion_reason}
	return data


func restore_saved(tree: SceneTree, data: Dictionary) -> bool:
	var meta: Variant = data.get("adventure")
	if _started or player == null or not meta is Dictionary or meta.get("schema_version") != 2 or meta.get("medicine_profile_sha256") != FileAccess.get_sha256(Medicine.PATH) or not meta.get("spent_items") is Dictionary or meta.get("kind") not in ["wild", "trainer"] or meta.get("completion_reason") != "" or meta.get("campaign_stamp") != _campaign_stamp(): last_error = "adventure_snapshot_contract"; return false
	if not meta.get("inventory") is Dictionary or not meta.get("capture_rng") is String or not meta.get("escape_rng") is String or not meta.capture_rng.is_valid_int() or not meta.escape_rng.is_valid_int() or not meta.get("escape_attempts") is float and not meta.get("escape_attempts") is int: last_error = "adventure_snapshot_shape"; return false
	var bag := PlayerInventory.from_dict(meta.inventory)
	if bag.corrupted or int(meta.escape_attempts) < 0: last_error = "adventure_snapshot_inventory"; return false
	if not meta.get("trainer_id") is String or (meta.kind == "trainer" and meta.trainer_id.is_empty()) or (meta.kind == "wild" and not meta.trainer_id.is_empty()): last_error = "adventure_snapshot_trainer"; return false
	for id: StringName in bag.all_item_ids():
		if bag.quantity(id) > player.inventory.quantity(id): last_error = "adventure_snapshot_inventory_gain"; return false
	for id: String in meta.spent_items:
		var count: Variant = meta.spent_items[id]
		if not (count is int or count is float) or int(count) != count or int(count) <= 0 or not player.inventory.has(StringName(id), int(count)) or not (Medicine.supports(StringName(id)) or meta.kind == "wild" and CaptureRuleset.new().is_known_ball(StringName(id))): last_error = "adventure_snapshot_spending"; return false
	for id: StringName in player.inventory.all_item_ids():
		if player.inventory.quantity(id) - bag.quantity(id) != int(meta.spent_items.get(String(id), 0)): last_error = "adventure_snapshot_unrelated_item"; return false
	var expected: Array = []
	for creature: CreatureInstance in player.party.get_creatures():
		if not creature.is_knocked_out(): expected.append(_creature_dto(creature))
	if not data.get("origin") is Dictionary or JSON.parse_string(JSON.stringify(data.origin.get("p1"))) != JSON.parse_string(JSON.stringify(expected)): last_error = "adventure_snapshot_party"; return false
	if not data.origin.get("p2") is Array: last_error = "adventure_snapshot_opponent"; return false
	if meta.kind == "wild" and data.origin.p2.size() != 1: last_error = "adventure_snapshot_wild_roster"; return false
	for row: Variant in data.origin.p2:
		if not row is Dictionary or not row.get("instance_id") is String or player.owned_creature(StringName(row.instance_id)) != null: last_error = "adventure_snapshot_opponent"; return false
	_baseline = meta.campaign_stamp
	if not await super.restore_saved(tree, data): return false
	if not _campaign_unchanged(): await close(); last_error = "campaign_changed"; return false
	inventory = bag; battle_kind = meta.kind; opponent_trainer_id = StringName(meta.get("trainer_id", ""))
	_spent_items.clear()
	for id: String in meta.spent_items: _spent_items[id] = int(meta.spent_items[id])
	_capture_rng.state = int(meta.capture_rng); _escape_rng.state = int(meta.escape_rng); escape_attempts = int(meta.escape_attempts)
	_started = true
	return true
