extends RefCounted
## W03 CAMP006 block02: strictly Escape Rope, no autosave or global API edits.
const Pilot = preload("res://modules/overworld/escape_rope_demo_pilot.gd")
var busy := false

func prepare(field: Node2D, owner: PlayerCollection) -> Dictionary:
	if busy: return _deny("world_item_busy")
	if field == null or owner == null or owner.inventory == null:
		return _deny("missing_collection")
	if not is_same(field.field_collection(), owner):
		return _deny("collection_changed")
	if not owner.inventory.validate().get("ok", false):
		return _deny("invalid_inventory")
	if not owner.inventory.has(&"escape_rope"):
		return _deny("item_not_owned")
	# While the bag is open its movement lock is expected. Preview is performed
	# immediately after closing it, not against the locked player.
	var position: Vector2 = field.player.global_position
	return {"accepted": true, "position": position,
		"inventory_stamp": JSON.stringify(owner.inventory.to_dict()).sha256_text(),
		"region": String(field.technical_region_id()),
		"owner": owner,
		"inventory": owner.inventory,
		"item_id": "escape_rope"}


func execute(field: Node2D, prepared: Dictionary) -> Dictionary:
	if busy: return _deny("world_item_busy")
	busy = true
	var result: Dictionary = await _execute_locked(field, prepared)
	busy = false
	return result


func _execute_locked(field: Node2D, prepared: Dictionary) -> Dictionary:
	if not bool(prepared.get("accepted", false)):
		return _deny("missing_preparation")
	if field == null or not field.has_method("field_collection"):
		return _deny("missing_world")
	var owner := prepared.get("owner") as PlayerCollection
	if owner == null or not is_same(field.field_collection(), owner):
		return _deny("collection_changed")
	var inv := prepared.get("inventory") as PlayerInventory
	if inv == null or not is_same(owner.inventory, inv):
		return _deny("inventory_changed")
	if not inv.validate().get("ok", false) or not inv.has(&"escape_rope"):
		return _deny("item_not_owned")
	if JSON.stringify(inv.to_dict()).sha256_text() != String(prepared.get("inventory_stamp", "")):
		return _deny("inventory_changed")
	var origin: Vector2 = prepared.get("position", Vector2.ZERO)
	if not field.player.global_position.is_equal_approx(origin) \
			or String(field.technical_region_id()) != String(prepared.get("region", "")):
		return _deny("world_changed")
	var plan: Dictionary = Pilot.preview(field)
	if not bool(plan.get("ok", false)):
		return _deny(String(plan.get("reason", "invalid_anchor")))
	var snapshot: Dictionary = inv.to_dict()
	var target: Vector2 = plan.destination
	var result: Dictionary = await Pilot.return_to_demo_anchor(field)
	if not bool(result.get("ok", false)):
		return _restore_position(field, origin, String(result.get("reason", "traversal_rejected")))
	# Never publish a spend if other game state changed across the await.
	if not is_same(field.field_collection(), owner) or not is_same(owner.inventory, inv) \
			or JSON.stringify(inv.to_dict()) != JSON.stringify(snapshot):
		return _restore_position(field, origin, "state_changed_during_traversal")
	if not field.player.global_position.is_equal_approx(target) \
			or field.technical_region_id() != &"surface":
		return _restore_position(field, origin, "destination_mismatch")
	if not inv.remove(&"escape_rope", 1):
		return _restore_position(field, origin, "item_spend_failed")
	return {"accepted": true, "status": "APPLIED", "item_id": "escape_rope",
		"spent_quantity": 1, "anchor_id": String(plan.anchor_id),
		"from_position": [origin.x, origin.y],
		"to_position": [target.x, target.y], "save_committed": false}


func _restore_position(field: Node2D, origin: Vector2, reason: String) -> Dictionary:
	# The bag is never mutated before successful traversal, so revert position
	# only. A restore is safe solely for the same live demo and idle traversal.
	if field != null and field.player != null \
			and not field.traversal_controller.is_busy():
		field.player.global_position = origin
		field.player.velocity = Vector2.ZERO
		field.player.reset_step_meter()
		return _deny(reason)
	return _deny("rollback_unavailable:" + reason)


static func _deny(reason: String) -> Dictionary:
	return {"accepted": false, "status": "REJECTED", "reason": reason,
		"spent_quantity": 0, "save_committed": false}
