extends RefCounted

# Application coordinator: remembers only replayable intentions and the service's
# state token. Publication/consumption always remain in FieldItemService.
var service: RefCounted
var item_id: StringName
var creature_id: StringName
var decisions: Dictionary = {}
var stamp := ""
var prompt: Dictionary = {}
var clocks: Dictionary

func cancel() -> void:
	service = null; decisions.clear(); stamp = ""; prompt.clear(); clocks = {}

func begin(items: RefCounted, item: StringName, creature: StringName) -> Dictionary:
	cancel(); service = items; item_id = item; creature_id = creature; clocks = items.sleep_clocks
	return _advance()

func choose(value: Variant) -> Dictionary:
	if service == null or prompt.is_empty(): return {"accepted": false, "status": "REJECTED", "reason": "no_growth_pending"}
	decisions[prompt.key] = value
	return _advance()

func _advance() -> Dictionary:
	if not is_same(clocks, service.sleep_clocks):
		cancel(); return {"accepted": false, "status": "REJECTED", "reason": "growth_state_changed"}
	var result: Dictionary = service.use_growth_item(item_id, creature_id, decisions, stamp)
	if result.status == "NEEDS_CONTEXT":
		stamp = result.stamp; prompt = result.prompt.duplicate(true)
	else: cancel()
	return result
