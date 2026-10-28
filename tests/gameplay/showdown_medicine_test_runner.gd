extends SceneTree

const Session = preload("res://modules/gameplay/showdown_adventure_session.gd")
const Profile = preload("res://modules/inventory/battle_medicine_profile.gd")
const DEST := "res://.godot/showdown_medicine_checks/"
var catalog: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var active: RefCounted
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, valid: bool) -> void:
	checks += 1
	if not valid: errors.append(label); push_error(label); printerr(active.last_error if active != null else "")


func make_creature(id: String, moves: Array = [&"reflect", &"tackle"]) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 17
	var result := CreatureFactory.create(catalog.species(&"mew"), 50, catalog, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves})
	result.ability_id = &""
	return result


func _run() -> void:
	create_timer(150).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			check("watchdog", false); _finish())
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var existing := BattleEffectRegistry.new()
	for id: StringName in existing.runtime_supported_trainer_item_ids():
		var heal: BattleEffectSpec = existing.effects_for_trainer_item(id)[0]
		var amount: Variant = Profile.items()[String(id)].heal
		check("medicine profile preserves existing project healing " + String(id), heal.kind == BattleEffectSpec.HEAL and (heal.ratio_basis_points == 10000 if amount is String else heal.value == int(amount)))
	var cases := {"potion": "", "super_potion": "", "hyper_potion": "", "max_potion": "", "full_restore": "poison",
		"antidote": "badly_poisoned", "burn_heal": "burn", "ice_heal": "freeze", "awakening": "", "paralyze_heal": "paralysis", "full_heal": "poison",
		"ether": "", "max_ether": "", "elixir": "", "max_elixir": ""}
	for id: String in cases: await _item_case(id, cases[id])
	await _rejection_cases()
	await _rollback()
	await _save_and_settle()
	_finish()


func _item_case(id: String, status: String) -> void:
	var player := PlayerCollection.new()
	var own := make_creature("own", [&"rest", &"reflect"] if id == "awakening" else [&"reflect", &"tackle"])
	own.current_hp = 10
	if not status.is_empty(): own.status_state.persistent_id = StringName(status); own.status_ids.append(StringName(status))
	if id in ["ether", "max_ether", "elixir", "max_elixir"]:
		for slot: BattleMoveSlot in own.moveset: slot.current_pp = 1
	player.party.add_creature(own); player.inventory.add(StringName(id), 1)
	var source := own.to_dict()
	active = Session.new(catalog, player)
	check("open " + id, await active.begin_trainer(self, &"medicine_trainer", [make_creature("enemy")] as Array[CreatureInstance]))
	if id == "awakening": check("Rest sets native sleep before Awakening", (await active.submit("move 1", active.revision)).accepted)
	var before: Dictionary = active.snapshot()
	var result: Dictionary = await active.use_item(StringName(id), &"own", active.revision, 0 if id in ["ether", "max_ether"] else -1)
	check("native medicine accepted " + id, result.accepted)
	check("one item staged and no campaign mutation " + id, active.inventory.quantity(StringName(id)) == 0 and player.inventory.quantity(StringName(id)) == 1 and own.to_dict() == source)
	check("exactly one new native turn " + id, active.battle_state().turn == int(before.native.native.turn))
	check("medicine semantic event " + id, result.get("events", []).any(func(e): return e.kind == BattleEvent.TRAINER_ITEM_USED and e.metadata.item_id == id))
	if not status.is_empty() or id == "awakening": check("native status cured " + id, active.battle_state().active_for_side(&"side_a").status_state.persistent_id == &"")
	check("medicine tracked in save journal " + id, active.snapshot().adventure.spent_items.get(id) == 1)
	await active.close()


func _rejection_cases() -> void:
	var player := PlayerCollection.new(); player.party.add_creature(make_creature("own"))
	player.inventory.add(&"potion", 1); player.inventory.add(&"ether", 1)
	active = Session.new(catalog, player)
	check("rejection fixture opens", await active.begin_wild(self, make_creature("enemy")))
	var before: Dictionary = active.snapshot()
	for command: Array in [[&"potion", &"own", active.revision, -1], [&"ether", &"own", active.revision, 99], [&"potion", &"enemy", active.revision, -1], [&"potion", &"own", -1, -1], [&"full_restore", &"own", active.revision, -1], [&"revive", &"own", active.revision, -1]]:
		var result: Dictionary = await active.use_item(command[0], command[1], command[2], command[3])
		check("invalid or no-effect item keeps entire snapshot " + str(command), not result.accepted and active.snapshot() == before)
	check("raw medicine command cannot bypass game inventory", not (await active.submit_medicine({}, active.revision)).accepted and active.snapshot() == before)
	await active.close()


func _rollback() -> void:
	var player := PlayerCollection.new(); var own := make_creature("own"); own.current_hp = 10
	player.party.add_creature(own); player.inventory.add(&"potion", 1)
	active = Session.new(catalog, player)
	var enemy := make_creature("enemy", [&"substitute"])
	check("rollback fixture opens", await active.begin_wild(self, enemy))
	active._policy._denied_moves["substitute"] = "test_policy_mismatch" # Deliberate policy corruption, not an unsupported mechanic.
	var before: Dictionary = active.snapshot()
	var result: Dictionary = await active.use_item(&"potion", &"own", active.revision)
	check("unsupported enemy effect aborts medicine HP bag journal and native RNG", not result.accepted and active.snapshot() == before and own.current_hp == 10 and player.inventory.quantity(&"potion") == 1)
	await active.close()


func _save_and_settle() -> void:
	var player := PlayerCollection.new(); var own := make_creature("own"); own.current_hp = 10
	player.party.add_creature(own); player.inventory.add(&"potion", 2)
	active = Session.new(catalog, player)
	check("persistent medicine fixture opens", await active.begin_wild(self, make_creature("enemy")))
	check("potion for persistence accepted", (await active.use_item(&"potion", &"own", active.revision)).accepted)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(active.snapshot()))
	var restored := Session.new(catalog, player)
	check("medicine bag journal and native state survive JSON restore", await restored.restore_saved(self, saved) and JSON.parse_string(JSON.stringify(restored.snapshot())) == saved)
	var replay: Dictionary = await restored.use_item(&"potion", &"own", restored.revision)
	var original: Dictionary = await active.use_item(&"potion", &"own", active.revision)
	check("restored continuation preserves native RNG journal and inventory", replay.accepted and original.accepted and restored.snapshot() == active.snapshot())
	await active.close(); active = restored
	var result: Dictionary = await active.flee(active.revision)
	check("finish publishes both spent potions and healed HP on original object", result.accepted and own.current_hp == 50 and player.inventory.quantity(&"potion") == 0 and player.party.get_creature(&"own") == own)
	check("second settlement cannot spend more medicine", not active.settle_finished_battle().accepted and player.inventory.quantity(&"potion") == 0)
	var wrong := saved.duplicate(true); wrong.adventure.medicine_profile_sha256 = "different"
	var fresh := Session.new(catalog, PlayerCollection.new())
	check("wrong medicine profile rejected", not await fresh.restore_saved(self, wrong) and fresh._client == null)
	await active.close()


func _finish() -> void:
	if done: return
	done = true
	var file := FileAccess.open(DEST + "gameplay.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "items": Profile.items().keys()}, "  ")); file.close()
	print("SHOWDOWN_MEDICINES ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
