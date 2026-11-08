extends "res://tests/gameplay/parallel_items_w02_campaign_006_block09.gd"

# W02 block10; concrete owner/inventory -> SaveV2 -> gameplay domain -> SaveV2.
# EXP SHARE remains a factual dependency, never counted as a positive effect.
const DATA10 := "res://tests/fixtures/parallel_items/w02_campaign_006_block10.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run10")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("W02 block10 native timeout")
			quit(2)
	)

func _run10() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_006"
	DirAccess.make_dir_recursive_absolute(destination)
	var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA10))
	if not f is Dictionary:
		push_error("CAMP006 block10 fixture missing")
		quit(2)
		return
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("10 real catalog overlay", Variants.apply(catalogs))
	check("10 exact scope", f.worker == "W02" and f.block == "10"
		and f.ids == ["exp_share", "lucky_egg", "soothe_bell"]
		and f.dependency.level == "L1_DEPENDENCY_NOT_L2")
	var positive: int = 0
	var dependency: int = 0
	var negative: int = 0
	for spec: Dictionary in f.cases:
		for mode: String in f.modes:
			current_case = String(spec.id) + "_" + mode
			var previous: int = errors.size()
			_probe10(spec, mode)
			if errors.size() == previous:
				if mode == "none": negative += 1
				elif spec.id == "exp_share": dependency += 1
				else: positive += 1
	var passed: bool = errors.is_empty() and positive == 4 and dependency == 2 and negative == 3
	done = true
	print("CAMP006_W02_FINAL10 ", "PASS" if passed else "FAIL",
		" block=10 positive=", positive, " dependency=", dependency,
		" negative=", negative, " checks=", checks)
	quit(0 if passed else 1)

func _probe10(spec: Dictionary, mode: String) -> void:
	var id: StringName = StringName(spec.id)
	var c: CreatureInstance = _make08()
	check(mode + " 10 native creature", c != null)
	if c == null: return
	var owner := _own08(c, mode)
	if mode != "none": check(mode + " 10 source item quantity", owner.inventory.add(id, 2))
	if id == &"soothe_bell": check(mode + " 10 protein source quantity", owner.inventory.add(&"protein", 2))
	var svc := Service.new()
	check(mode + " 10 service configure", svc.configure(owner, catalogs, func(): return true))
	var previous_owner: Dictionary = _owner_data(owner)
	var equip: Dictionary = svc.equip(id, &"own")
	check(mode + " 10 equip expected outcome", bool(equip.get("accepted", false)) == (mode != "none"))
	if mode == "none":
		check(mode + " 10 zero stock atomic rejection",
			equip.get("reason", "") == "item_not_owned"
			and previous_owner == _owner_data(owner))
		return
	check(mode + " 10 equip removes exactly one", owner.inventory.quantity(id) == 1)
	var restored := _reload08(owner, mode + " 10 equipped")
	if restored == null: return
	var mon: CreatureInstance = restored.owned_creature(&"own")
	check(mode + " 10 SaveV2 original location", mon != null
		and restored.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY")
		and mon.held_item_id == id and not mon.held_item_consumed)
	if mon == null: return
	var service2 := Service.new()
	check(mode + " 10 service rebind after load", service2.configure(restored, catalogs, func(): return true))
	var before_repeat: Dictionary = _owner_data(restored)
	var duplicate: Dictionary = service2.equip(id, &"own")
	check(mode + " 10 duplicate equipment rollback",
		not bool(duplicate.get("accepted", true))
		and duplicate.get("reason", "") == "already_equipped"
		and _owner_data(restored) == before_repeat)
	match String(spec.id):
		"exp_share":
			_exp_share10(restored, mon, spec, mode)
		"lucky_egg":
			_lucky_egg10(restored, mon, spec, mode)
		"soothe_bell":
			_soothe_bell10(restored, mon, spec, mode)
	var after := _reload08(restored, mode + " 10 post-effect")
	if after == null: return
	var post: CreatureInstance = after.owned_creature(&"own")
	check(mode + " 10 final persistence inventory identity",
		post != null and post.to_dict() == restored.owned_creature(&"own").to_dict()
		and after.inventory.quantity(id) == restored.inventory.quantity(id)
		and after.location_of(&"own") == restored.location_of(&"own"))

func _exp_share10(owner: PlayerCollection, passive: CreatureInstance, spec: Dictionary, mode: String) -> void:
	# Demonstrate exact missing producer without manufacturing XP for a bench mon.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1413
	var fighter: CreatureInstance = CreatureFactory.create(
		catalogs.species(&"mew"), 50, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"fighter", "nature_id": &"hardy", "moves": ["growl"]})
	check(mode + " EXP Share real fighter", fighter != null)
	if fighter == null: return
	check(mode + " EXP Share fighter owned by party", owner.party.add_creature(fighter))
	var passive_xp: int = passive.experience
	var fighter_xp: int = fighter.experience
	var evs_before: Dictionary = passive.evs.duplicate(true)
	var battle_events: Array = ProgressionSystem.reconcile_battle_result(
		[fighter], _held05_outcome(), catalogs, ProgressionRuleset.new())
	check(mode + " EXP Share dependency no passive XP from participants-only producer",
		passive.experience == passive_xp
		and _held05_xp_events(battle_events, passive.instance_id) == int(spec.expected_nonparticipant_xp)
		and fighter.experience == fighter_xp + 71
		and passive.evs == evs_before)
	check(mode + " EXP Share remains equipped, no phantom consumption",
		passive.held_item_id == &"exp_share" and not passive.held_item_consumed
		and owner.inventory.quantity(&"exp_share") == 1)
	var service := Service.new()
	check(mode + " EXP Share service", service.configure(owner, catalogs, func(): return true))
	var before_direct: Dictionary = _owner_data(owner)
	var unsupported: Dictionary = service.use_item(&"exp_share", &"own")
	check(mode + " EXP Share direct use cannot fake effect or consume",
		not bool(unsupported.get("accepted", true))
		and _owner_data(owner) == before_direct)

func _lucky_egg10(owner: PlayerCollection, mon: CreatureInstance, spec: Dictionary, mode: String) -> void:
	# A stored creature must be withdrawn before legitimately participating.
	if mode == "reserve":
		check(mode + " Lucky Egg withdraw to participate", owner.withdraw(&"own"))
		check(mode + " Lucky Egg now PARTY", owner.location_of(&"own") == &"PARTY")
	var baseline: CreatureInstance = CreatureInstance.from_dict(mon.to_dict())
	check(mode + " Lucky Egg baseline clone", baseline != null)
	if baseline == null: return
	baseline.held_item_id = &""
	var before: int = mon.experience
	var rewarded: Array = ProgressionSystem.reconcile_battle_result(
		[mon], _held05_outcome(), catalogs, ProgressionRuleset.new())
	var unboosted: Array = ProgressionSystem.reconcile_battle_result(
		[baseline], _held05_outcome(), catalogs, ProgressionRuleset.new())
	check(mode + " Lucky Egg battle XP x1.5 vs unheld",
		mon.experience == before + int(spec.expected_boosted_xp)
		and baseline.experience == before + int(spec.expected_plain_xp)
		and _held05_xp_events(rewarded, mon.instance_id) == int(spec.expected_boosted_xp)
		and _held05_xp_events(unboosted, baseline.instance_id) == int(spec.expected_plain_xp))
	check(mode + " Lucky Egg unconsumed after battle",
		mon.held_item_id == &"lucky_egg" and not mon.held_item_consumed
		and owner.inventory.quantity(&"lucky_egg") == 1)
	if mode == "reserve":
		check(mode + " Lucky Egg restore original storage", owner.deposit(&"own"))

func _soothe_bell10(owner: PlayerCollection, mon: CreatureInstance, spec: Dictionary, mode: String) -> void:
	if mode == "reserve":
		check(mode + " Soothe Bell withdraw for field training", owner.withdraw(&"own"))
		check(mode + " Soothe Bell party after withdrawal", owner.location_of(&"own") == &"PARTY")
	var baseline: CreatureInstance = CreatureInstance.from_dict(mon.to_dict())
	check(mode + " Soothe Bell baseline clone", baseline != null)
	if baseline == null: return
	baseline.held_item_id = &""
	var plain_owner := PlayerCollection.new()
	check(mode + " Soothe Bell baseline party", plain_owner.party.add_creature(baseline))
	check(mode + " Soothe Bell baseline vitamin", plain_owner.inventory.add(&"protein", 2))
	var plain_service := Service.new()
	check(mode + " Soothe Bell baseline service",
		plain_service.configure(plain_owner, catalogs, func(): return true))
	var plain_result: Dictionary = plain_service.use_item(&"protein", &"own")
	var active_service := Service.new()
	check(mode + " Soothe Bell service after load",
		active_service.configure(owner, catalogs, func(): return true))
	var before_fri: int = mon.friendship
	var applied: Dictionary = active_service.use_item(&"protein", &"own")
	var updated: CreatureInstance = owner.owned_creature(&"own")
	check(mode + " Soothe Bell real vitamin friendship x1.5",
		bool(applied.get("accepted", false)) and bool(plain_result.get("accepted", false))
		and updated != null
		and updated.friendship == before_fri + int(spec.expected_held_gain)
		and plain_owner.owned_creature(&"own").friendship == before_fri + int(spec.expected_plain_gain))
	if updated == null: return
	check(mode + " Soothe Bell training affects EV, not held stock",
		int(updated.evs.get("attack", 0)) == 10
		and owner.inventory.quantity(&"protein") == 1
		and owner.inventory.quantity(&"soothe_bell") == 1
		and updated.held_item_id == &"soothe_bell" and not updated.held_item_consumed)
	var duplicate_before: Dictionary = _owner_data(owner)
	var unsupported: Dictionary = active_service.use_item(&"soothe_bell", &"own")
	check(mode + " Soothe Bell cannot be spent as direct field item",
		not bool(unsupported.get("accepted", true))
		and _owner_data(owner) == duplicate_before)
	if mode == "reserve":
		check(mode + " Soothe Bell return to storage", owner.deposit(&"own"))
