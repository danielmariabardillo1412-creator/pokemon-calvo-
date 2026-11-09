extends SceneTree

# W03 CAMP006 B03: functional L3 demo, genuine bag, encounter and native world save.
var checks := 0
var errors: Array[String] = []
func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("W03_REPEL_L3: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	ck("demo boots", scene.is_demo_ready())
	if not scene.is_demo_ready():
		_finish(scene)
		return
	scene.player.set_physics_process(false)
	var bag: Control = scene._item_bag
	var owner: PlayerCollection = scene.field_collection()
	var effect = scene._repel_effect
	ck("single real player attachment", effect._player == scene.player
		and scene.player.step_completed.is_connected(effect._on_real_step))
	var leader: CreatureInstance = null
	for c: CreatureInstance in owner.party.get_creatures():
		if c != null and not c.is_knocked_out():
			leader = c
			break
	ck("real party leader", leader != null and leader.level > 1)
	if leader == null or leader.level <= 1:
		_finish(scene)
		return
	var zone: StringName = scene._director.registered_zone_ids()[0]
	var built: Dictionary = TechnicalEncounterPoolBuilder.build(scene._catalogs, zone, 100, 1, 1, &"pidgey")
	ck("real authored encounter table created", bool(built.get("ok", false)))
	if not bool(built.get("ok", false)):
		_finish(scene)
		return
	scene._director._tables[zone] = built.table
	var original_seed: int = scene._director._next_battle_seed
	for id: StringName in [&"repel", &"super_repel", &"max_repel"]:
		owner = scene.field_collection()
		# Manual load reconstitutes canonical encounter tables. Reapply this test fixture.
		scene._director._tables[zone] = built.table
		ck("inventory add " + String(id), owner.inventory.add(id, 2))
		var quantity: int = owner.inventory.quantity(id)
		ck("open bag " + String(id), bag.open_bag())
		var index := -1
		for i in bag._items.item_count:
			if String(bag._items.get_item_metadata(i)) == String(id):
				index = i
		ck("select real item " + String(id), index >= 0)
		if index < 0: break
		bag._items.select(index)
		bag._refresh_choices()
		ck("enabled without target " + String(id), not bag._use.disabled)
		bag._use.pressed.emit()
		await process_frame
		print("W03_REPEL_DEBUG id=", id, " bag_result=", bag._result.text,
			" amount=", owner.inventory.quantity(id), " effect=", JSON.stringify(effect.to_dict()),
			" field_use=", scene.field_can_use_items())
		ck("one unit consumed " + String(id), owner.inventory.quantity(id) == quantity - 1)
		var total: int = int(effect.DURATIONS[id])
		ck("activated exact duration " + String(id), effect.active_id == id and effect.remaining_steps == total)
		ck("active duplicate no spend " + String(id),
			not bag._apply_repel().get("accepted", false)
			and owner.inventory.quantity(id) == quantity - 1)
		# Closing the UI lets the world move and the real player emit its step signal.
		bag.hide()
		await process_frame
		var state_before: int = scene._director._encounter_rng.state
		var prepared: Dictionary = scene.field_prepare_native_encounter(zone)
		ck("lower-level actual wild suppressed " + String(id),
			bool(prepared.get("blocked_by_repel", false)) and prepared.has("next_rng")
			and scene._director._encounter_rng.state == state_before)
		var seed_before: int = scene._director._next_battle_seed
		var grass_position: Vector2 = scene.get_node("EncounterZone").global_position
		ck("real demo grass position belongs to registered encounter zone",
			scene.zone_at_position(grass_position) == zone)
		await scene._native_battles.on_step(grass_position)
		ck("native bridge suppression commits RNG only " + String(id),
			scene._director._encounter_rng.state == int(prepared.get("next_rng", -1))
			and scene._director._next_battle_seed == seed_before
			and not scene._native_battles.occupied())
		var equal_table: Dictionary = TechnicalEncounterPoolBuilder.build(
			scene._catalogs, zone, 100, leader.level, leader.level, &"pidgey")
		ck("equal-level table valid " + String(id), bool(equal_table.get("ok", false)))
		if bool(equal_table.get("ok", false)):
			scene._director._tables[zone] = equal_table.table
			var allowed: Dictionary = scene.field_prepare_native_encounter(zone)
			var allowed_encounter := allowed.get("result") as WildEncounterResult
			ck("equal-level wild is not repelled " + String(id),
				not bool(allowed.get("blocked_by_repel", false))
				and allowed_encounter != null
				and allowed_encounter.status == WildEncounterResult.ENCOUNTER
				and allowed_encounter.creature.level == leader.level)
			scene._director._tables[zone] = built.table
		var saved: Dictionary = scene.field_native_world_snapshot("gen9calvounifiedv1")
		ck("repel state included in native world " + String(id),
			saved.get("repel", {}) == effect.to_dict())
		var path: String = "user://w03_repel_l3_" + String(id) + ".json"
		scene._native_battles.save_path = path
		ck("manual native save " + String(id), scene._native_battles.save_game())
		var moved: Vector2 = scene.player.apply_motion(Vector2.RIGHT, 1.0 / 3.0)
		ck("real step decrements once " + String(id), moved.length() > 31.0
			and effect.remaining_steps == total - 1)
		ck("manual load restores effect " + String(id), await scene._native_battles.load_game()
			and effect.remaining_steps == total and effect.active_id == id)
		var without_repel: Dictionary = saved.duplicate(true)
		without_repel.erase("repel")
		ck("old save accepted inactive " + String(id),
			bool(scene.field_validate_native_loaded_world(without_repel).get("ok", false)))
		var corrupted: Dictionary = saved.duplicate(true)
		corrupted["repel"] = {"schema_version": 1, "active_id": String(id), "remaining_steps": "10"}
		ck("malformed steps rejected without mutation " + String(id),
			not scene.field_validate_native_loaded_world(corrupted).get("ok", false)
			and effect.remaining_steps == total)
		# Exhaust using physical movement, not hand-edited counters.
		for i in total:
			scene.player.apply_motion(Vector2.LEFT if i % 2 == 0 else Vector2.RIGHT, 1.0 / 3.0)
		ck("expires at exact real step " + String(id),
			effect.remaining_steps == 0 and effect.active_id == &"")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	ck("no suppressions created battles", scene._director._next_battle_seed == original_seed)
	_finish(scene)

func _finish(scene: Node) -> void:
	scene.queue_free()
	await process_frame
	if errors.is_empty() and checks > 0:
		print("CAMP006_W03_REPEL_L3 PASS checks=" + str(checks))
		quit(0)
	else:
		print("CAMP006_W03_REPEL_L3 FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
