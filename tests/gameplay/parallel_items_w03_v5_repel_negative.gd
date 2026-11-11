extends SceneTree

# W03 V5: real field bag + fault-injected inventory remove. No production changes.
class DeniedRemoveInventory:
	extends PlayerInventory
	func remove(_item_id: StringName, _amount: int = 1) -> bool:
		return false

var checks := 0
var errors: Array[String] = []

func ck(label: String, valid: bool) -> void:
	checks += 1
	if not valid:
		errors.append(label)
		push_error("W03_V5_REPEL_NEG: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	ck("real demo ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish(scene)
		return

	scene.player.set_physics_process(false)
	var owner: PlayerCollection = scene.field_collection()
	var bag: Control = scene._item_bag
	var effect = scene._repel_effect
	ck("initial effect empty", effect.active_id == &"" and effect.remaining_steps == 0)
	var connections_before: int = scene.player.step_completed.get_connections().size()
	ck("attach is idempotent", effect.attach(scene.player) and effect.attach(scene.player)
		and scene.player.step_completed.get_connections().size() == connections_before)

	# Preflight can see stock, but the real inventory commit is forced to fail.
	# This subclass is only injected in this test and never saved or committed.
	owner.inventory = DeniedRemoveInventory.new()
	for item_id: StringName in [&"repel", &"super_repel", &"max_repel"]:
		owner.inventory.clear()
		ck("one stock available " + String(item_id), owner.inventory.add(item_id, 1))
		ck("open genuine bag " + String(item_id), bag.open_bag())
		var index := -1
		for i in bag._items.item_count:
			if String(bag._items.get_item_metadata(i)) == String(item_id):
				index = i
		ck("visible in real bag " + String(item_id), index >= 0)
		if index < 0:
			bag.hide()
			break
		bag._items.select(index)
		bag._refresh_choices()
		ck("no target required " + String(item_id), not bag._use.disabled)
		var initial_effect: Dictionary = effect.to_dict()

		ck("stale inventory injected " + String(item_id), owner.inventory.set_quantity(item_id, 0))
		var stale: Dictionary = bag._apply_repel()
		ck("stale stock rejected " + String(item_id),
			not bool(stale.get("accepted", false)) and stale.get("reason", "") == "item_not_owned"
			and owner.inventory.quantity(item_id) == 0 and effect.to_dict() == initial_effect)

		ck("stock restored for commit failure " + String(item_id),
			owner.inventory.set_quantity(item_id, 1))
		bag._refresh_choices()
		ck("real bag enables valid stock " + String(item_id), not bag._use.disabled)
		var denied: Dictionary = bag._apply_repel()
		ck("failed remove rolls back real field effect " + String(item_id),
			not bool(denied.get("accepted", false))
			and denied.get("reason", "") == "inventory_commit_failed"
			and owner.inventory.quantity(item_id) == 1
			and effect.to_dict() == initial_effect)
		ck("no battle or step on failed transaction " + String(item_id),
			not scene._native_battles.occupied() and effect.remaining_steps == 0)
		bag.hide()
		await process_frame

	await _finish(scene)

func _finish(scene: Node) -> void:
	scene.queue_free()
	await process_frame
	if errors.is_empty() and checks > 0:
		print("W03_V5_REPEL_NEG PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_V5_REPEL_NEG FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
