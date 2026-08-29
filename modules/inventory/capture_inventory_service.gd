class_name CaptureInventoryService
extends RefCounted

# Application-layer bridge between Inventory and Capture. CaptureSystem stays pure and unaware of
# item ownership; this service guarantees a valid attempt cannot consume RNG or mutate Party unless
# the player actually owns the requested ball. Exactly one ball is consumed for every valid capture
# attempt (success or failure), matching CaptureResult.consume_item semantics.

static func resolve(
	attempt: CaptureAttempt,
	rng: RandomNumberGenerator,
	catalogs,
	party: CreatureParty,
	inventory: PlayerInventory,
) -> CaptureResolution:
	# Preserve CaptureSystem's validation precedence. Invalid attempts do not require/consume a ball.
	var invalid_reason := CaptureSystem.validate_attempt(attempt, catalogs)
	if invalid_reason != "":
		return CaptureSystem.resolve(attempt, rng, catalogs, party)

	if inventory == null:
		return _reject(attempt, "inventory_required")
	if inventory.corrupted:
		return _reject(attempt, "inventory_corrupted")
	if not inventory.has(attempt.ball_id, 1):
		return _reject(attempt, "item_not_owned")

	# Reserve the item before resolution. This makes the ownership+consumption boundary transactional:
	# no successful/failed valid attempt can escape without decrementing the bag.
	if not inventory.remove(attempt.ball_id, 1):
		return _reject(attempt, "inventory_consume_failed")

	var resolution := CaptureSystem.resolve(attempt, rng, catalogs, party)
	# Defensive rollback if CaptureSystem ever rejects after validate_attempt passed. With the current
	# deterministic contract this branch should be unreachable, but it prevents item loss on drift.
	if resolution == null or resolution.result == null or not resolution.result.consume_item:
		inventory.add(attempt.ball_id, 1)
	return resolution


static func _reject(attempt: CaptureAttempt, reason: String) -> CaptureResolution:
	var out := CaptureResolution.new()
	var target_id: StringName = &""
	var ball_id: StringName = &""
	if attempt != null:
		ball_id = attempt.ball_id
		if attempt.target != null:
			target_id = attempt.target.instance_id

	var result := CaptureResult.new()
	result.status = CaptureResult.INVALID
	result.ball_id = ball_id
	result.target_id = target_id
	result.consume_item = false
	result.reason = reason
	out.result = result
	out.events = [
		CaptureEvent.new(CaptureEvent.ATTEMPTED, {
			"ball_id": String(ball_id),
			"target_id": String(target_id),
		}),
		CaptureEvent.new(CaptureEvent.REJECTED, {"reason": reason}),
	]
	return out
