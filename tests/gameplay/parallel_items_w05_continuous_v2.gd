extends "res://tests/gameplay/parallel_items_w05_book_ui_autorun_v3.gd"

# CONTINUOUS V2 W05: consumer-side rehearsal, not an integrated FieldItemBag.
# Reuses TANDA02/03 real owners, live service, Godot panel and SaveV2.
# All 229 per-ID positives are already covered by TANDA01+TANDA02.
# IA6 must run a separate actual FieldItemBag + W03 coexistence acceptance.

func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	check("V2 normalized data readable", data is Dictionary)
	if not data is Dictionary:
		_finish_v2()
		return
	catalogs = GameData.from_dict(data).to_definition_catalog()
	check("V2 canonical definitions", catalogs != null)
	check("V2 content policy", policy.load_local())
	if catalogs == null or not policy.valid:
		_finish_v2()
		return

	# Simulate the minimum consumer: same bound FieldItemService instance,
	# persistent TM identity, PARTY identity and a replacement decision.
	var first := setup(&"metal_claw", true)
	check("V2 first eligible real fixture", not first.is_empty())
	if not first.is_empty():
		var service: Variant = first.service
		var panel: Variant = first.panel
		var signals := {"all": 0, "accepted": 0}
		panel.teaching_finished.connect(func(answer: Dictionary):
			signals["all"] = int(signals["all"]) + 1
			if answer.get("accepted", false):
				signals["accepted"] = int(signals["accepted"]) + 1)
		check("V2 bound same transaction service", is_same(panel.service, service))
		check("V2 explicit owner and MT selected", panel._selected(panel.books) == &"tm31"
			and panel._selected(panel.targets) == POKEMON)
		var before_creature: CreatureInstance = service.owner.owned_creature(POKEMON)
		var old_move: StringName = before_creature.moveset[1].move_id
		check("V2 replacement selects slot one", panel.select_replacement_slot(1)
			and not panel.teach_button.disabled)
		var answer: Dictionary = panel.teach_selected()
		var now: CreatureInstance = service.owner.owned_creature(POKEMON)
		var move: BattleMoveSlot = now.move_slot(&"metal_claw") if now != null else null
		var definition: MoveDefinition = catalogs.move(&"metal_claw")
		check("V2 exactly one accepted real service transaction",
			answer.get("accepted", false) and answer.get("move_id", "") == "metal_claw"
			and signals["all"] == 1 and signals["accepted"] == 1)
		check("V2 exactly one consumed and identity retained",
			service.owner.inventory.quantity(&"tm31") == 1
			and now != null and now.instance_id == POKEMON
			and service.owner.location_of(POKEMON) == &"PARTY")
		check("V2 exact replacement and native PP",
			now != null and now.moveset[1].move_id == &"metal_claw"
			and not now.has_move(old_move) and move != null and definition != null
			and move.current_pp == definition.pp and move.max_pp == definition.pp)
		check_save(service.owner, &"tm31", &"metal_claw", old_move)
		var after_one: String = state(service.owner)
		var repeat: Dictionary = panel.teach_selected()
		check("V2 no second spend on duplicate event",
			not repeat.get("accepted", false)
			and repeat.get("reason", "") == "move_already_known"
			and state(service.owner) == after_one
			and signals["all"] == 2 and signals["accepted"] == 1)
		panel.queue_free()

	# A selected identity that has been moved to Storage must never be
	# replaced by a different PARTY member or consume the book.
	var moved := setup()
	check("V2 second owner fixture", not moved.is_empty())
	if not moved.is_empty():
		var service2: Variant = moved.service
		var panel2: Variant = moved.panel
		check("V2 deposit selected owner", service2.owner.deposit(POKEMON))
		check("V2 selected identity now Storage", service2.owner.location_of(POKEMON) == &"STORAGE")
		var before_moved: String = state(service2.owner)
		var rejection: Dictionary = panel2.teach_selected()
		check("V2 deposited owner refused without stock mutation",
			not rejection.get("accepted", false)
			and rejection.get("reason", "") == "creature_not_in_party"
			and state(service2.owner) == before_moved
			and service2.owner.inventory.quantity(&"tm202") == 2)
		panel2.refresh()
		check("V2 stale party selection must be blank",
			panel2._selected(panel2.targets) == &"")
		panel2.queue_free()

	# State revalidation on the authoritative service remains the only
	# permission to teach; deny without partial mutation under lock.
	var locked := setup()
	check("V2 third owner fixture", not locked.is_empty())
	if not locked.is_empty():
		var service3: Variant = locked.service
		var panel3: Variant = locked.panel
		var locked_state: String = state(service3.owner)
		service3.guard = func(): return false
		var denied: Dictionary = panel3.teach_selected()
		check("V2 locked session keeps stock and SaveV2 state",
			not denied.get("accepted", false)
			and denied.get("reason", "") == "field_locked"
			and state(service3.owner) == locked_state)
		panel3.queue_free()
	_finish_v2()


func _finish_v2() -> void:
	if failures.is_empty():
		print("W05_V2_CONSUMER_GODOT PASS live_service=1 real_panel=1 "
			+ "accepted=1 duplicate_spend=0 storage_rejection=1 "
			+ "locked_rollback=1 savev2=1 actual_bag=NOT_MOUNTED "
			+ "w03_coexistence=IA6_PENDING checks=%d" % checks)
		quit(0)
	else:
		print("W05_V2_CONSUMER_GODOT FAIL checks=%d errors=%s" % [checks, str(failures)])
		quit(1)
