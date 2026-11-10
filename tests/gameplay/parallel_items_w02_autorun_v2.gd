extends "res://tests/gameplay/parallel_items_w02_mint_pilot02_20261109.gd"

# W02 AUTORUN V2: first native red reproducer for growth and mochi after mint.
const GrowthV2 = preload("res://modules/inventory/field_growth_effects.gd")
const MochiV2 = preload("res://modules/inventory/field_mochi_effects.gd")

func _initialize() -> void:
	capture = false
	call_deferred("_run_v2")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("W02 AUTORUN V2 watchdog")
			quit(2)
	)

func _run_v2() -> void:
	destination = "res://.godot/parallel_items/w02_autorun_v2"
	DirAccess.make_dir_recursive_absolute(destination)
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("TANDA02 catalog overlay", Variants.apply(catalogs))
	for mode: String in ["active", "reserve"]:
		current_case = "red_rare_candy_" + mode
		_red_after_mint(mode, &"rare_candy")
		current_case = "red_muscle_mochi_" + mode
		_red_after_mint(mode, &"muscle_mochi")
		current_case = "red_swift_mochi_" + mode
		_red_after_mint(mode, &"swift_mochi")
	for mode: String in ["active", "reserve"]:
		current_case = "xp_after_mint_" + mode
		_probe_exp_after_mint(mode)
		current_case = "growth_choices_after_mint_" + mode
		_probe_growth_choices(mode)
		current_case = "fresh_start_after_mint_" + mode
		_probe_fresh_start(mode)
		current_case = "vitamins_after_mint_" + mode
		_probe_vitamins(mode)
		current_case = "chain_after_mint_" + mode
		_probe_chain(mode)
	var passed: bool = errors.is_empty()
	done = true
	print("W02_AUTORUN_V2_GODOT ", "PASS" if passed else "FAIL", " checks=", checks)
	quit(0 if passed else 1)

func _red_after_mint(mode: String, item: StringName) -> void:
	var c: CreatureInstance = _pilot_creature()
	check("red genuine real creature", c != null)
	if c == null: return
	var owner: PlayerCollection = _pilot_owner(c, mode)
	check("red mint stock", owner.inventory.add(&"adamant_mint", 1))
	check("red second item stock", owner.inventory.add(item, 1))
	var svc := Service.new()
	check("red real FieldItemService", svc.configure(owner, catalogs, func(): return true))
	var minted: Dictionary = svc.use_item(&"adamant_mint", &"own")
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("red mint applied with preserved original nature", bool(minted.get("accepted", false))
		and now != null and now.nature_id == &"hardy" and now.effective_nature_id == &"adamant")
	if now == null: return
	var before: Dictionary = _owner_data(owner)
	var expected: Dictionary = StatCalculator.compute(
		catalogs.species(now.species_id).base_stat_block(), now.ivs, now.evs,
		&"adamant", now.level).to_dict()
	check("red original+effective stat consistency", now.stats.to_dict() == expected)
	var validation: String = GrowthV2.validation_error(now, catalogs) if item == &"rare_candy" 		else MochiV2.validation_error(now, -1, catalogs)
	check("red after mint validator accepts effective nature", validation == "")
	var response: Dictionary = svc.use_growth_item(item, &"own") if item == &"rare_candy" 		else svc.use_item(item, &"own")
	var resulting: CreatureInstance = owner.owned_creature(&"own")
	check("red positive growth/mochi from real bag", bool(response.get("accepted", false))
		and resulting != null and resulting.nature_id == &"hardy"
		and resulting.effective_nature_id == &"adamant"
		and owner.inventory.quantity(item) == 0
		and resulting.current_hp > 0)
	if not bool(response.get("accepted", false)):
		check("red rejected transaction kept 1 stock and full SaveV2 state",
			owner.inventory.quantity(item) == 1 and _owner_data(owner) == before)
	else:
		var after_applied: Dictionary = _owner_data(owner)
		var exhausted: Dictionary = svc.use_growth_item(item, &"own") if item == &"rare_candy" else svc.use_item(item, &"own")
		check("v2 red successor no-stock rejection without mutation",
			not bool(exhausted.get("accepted", true)) and String(exhausted.get("reason", "")) == "item_not_owned"
			and _owner_data(owner) == after_applied)

# Full scoped TANDA02 native regression suite. No fake item service or save.
func _new_minted(mode: String, items: Array, species: StringName = &"mew",
		level: int = 50, moves: Array = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var move_ids: Array = ["growl", "protect"] if moves.is_empty() else moves
	var c: CreatureInstance = CreatureFactory.create(
		catalogs.species(species), level, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": move_ids})
	check("v2 genuine creature and species", c != null and catalogs.species(species) != null)
	if c == null: return {}
	c.friendship = 99
	c.current_hp = maxi(1, c.stats.max_hp - 9)
	var owner := _pilot_owner(c, mode)
	check("v2 minted stock", owner.inventory.add(&"adamant_mint", 1))
	for each: Variant in items:
		check("v2 authorized item in catalog " + String(each),
			catalogs.item(StringName(each)) != null)
		check("v2 full stock " + String(each), owner.inventory.add(StringName(each), 1))
	var svc := Service.new()
	check("v2 configure real FieldItemService", svc.configure(owner, catalogs, func(): return true))
	var before: Dictionary = _owner_data(owner)
	var minted: Dictionary = svc.use_item(&"adamant_mint", &"own")
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("v2 original nature preserved and minted positive",
		bool(minted.get("accepted", false)) and now != null
		and now.nature_id == &"hardy" and now.effective_nature_id == &"adamant"
		and owner.inventory.quantity(&"adamant_mint") == 0 and _owner_data(owner) != before)
	return {"owner": owner, "service": svc, "source": c}

func _assert_effective(now: CreatureInstance, nature: StringName, label: String) -> void:
	check(label + " actual creature exists", now != null)
	if now == null: return
	var derived: Dictionary = StatCalculator.compute(
		catalogs.species(now.species_id).base_stat_block(), now.ivs, now.evs, nature,
		now.level).to_dict()
	check(label + " nature original and effective separated, exact stats",
		now.nature_id == &"hardy" and now.effective_nature_id == nature
		and now.stats.to_dict() == derived
		and now.current_hp > 0 and now.current_hp <= now.stats.max_hp)

func _assert_save(owner: PlayerCollection, label: String) -> void:
	var snapshot: Dictionary = _owner_data(owner)
	var restored: LoadResult = SaveGameRepository.new().decode_snapshot(snapshot)
	check(label + " SaveV2 actually decoded", restored.ok)
	if not restored.ok: return
	var loaded := PlayerCollection.new()
	loaded.party = restored.party
	loaded.storage = restored.storage
	loaded.inventory = restored.inventory
	var now: CreatureInstance = owner.owned_creature(&"own")
	var saved: CreatureInstance = loaded.owned_creature(&"own")
	check(label + " SaveV2 creature identity, stats, nature and PP",
		now != null and saved != null and saved.to_dict() == now.to_dict()
		and loaded.location_of(&"own") == owner.location_of(&"own")
		and loaded.inventory.to_dict() == owner.inventory.to_dict())

func _resolve_growth(svc: Variant, item: StringName, evolution_target := "") -> Dictionary:
	var decisions: Dictionary = {}
	var stamp := ""
	var outcome: Dictionary = svc.use_growth_item(item, &"own")
	for attempt in 16:
		if String(outcome.get("status", "")) != "NEEDS_CONTEXT": return outcome
		if stamp == "": stamp = String(outcome.get("stamp", ""))
		var prompt: Dictionary = outcome.get("prompt", {})
		var key: String = String(prompt.get("key", ""))
		if key == "": return {"accepted": false, "reason": "empty_growth_prompt"}
		decisions[key] = evolution_target if String(prompt.get("kind", "")) == "evolution" else -1
		outcome = svc.use_growth_item(item, &"own", decisions, stamp)
	return {"accepted": false, "reason": "too_many_growth_choices"}

func _probe_exp_after_mint(mode: String) -> void:
	for id: String in ["exp_candy_xs", "exp_candy_xl"]:
		var ctx: Dictionary = _new_minted(mode, [id])
		if ctx.is_empty(): continue
		var owner: PlayerCollection = ctx.owner
		var svc = ctx.service
		var source: CreatureInstance = owner.owned_creature(&"own")
		var before_level: int = source.level
		var before_xp: int = source.experience
		var before_friend: int = source.friendship
		var before_hp_deficit: int = source.stats.max_hp - source.current_hp
		var before_pp: Dictionary = source.moveset[0].to_dict()
		var before_ivs: Dictionary = source.ivs.duplicate(true)
		var before_evs: Dictionary = source.evs.duplicate(true)
		var wrong_before: Dictionary = _owner_data(owner)
		var wrong: Dictionary = svc.use_item(StringName(id), &"own", 0)
		check("v2 XP target slot rejection atomic " + id,
			not bool(wrong.get("accepted", true))
			and String(wrong.get("reason", "")) == "unexpected_growth_target"
			and _owner_data(owner) == wrong_before)
		var result: Dictionary = _resolve_growth(svc, StringName(id))
		var now: CreatureInstance = owner.owned_creature(&"own")
		var wanted_exp: int = mini(ProgressionRuleset.experience_for_level(
			catalogs.species(now.species_id).growth_rate, 100),
			before_xp + (100 if id == "exp_candy_xs" else 30000))
		check("v2 exact exp candy effect and one spent " + id,
			bool(result.get("accepted", false)) and now.experience == wanted_exp
			and now.level >= before_level and now.friendship > before_friend
			and now.stats.max_hp - now.current_hp == before_hp_deficit
			and now.ivs == before_ivs and now.evs == before_evs
			and now.moveset[0].to_dict() == before_pp
			and owner.inventory.quantity(StringName(id)) == 0)
		_assert_effective(now, &"adamant", "xp " + id + " " + mode)
		_assert_save(owner, "xp " + id + " " + mode)
	# At level 100 the same candy has no effect, cannot consume, and leaves
	# the already minted nature and SaveV2 untouched.
	var capped: Dictionary = _new_minted(mode, ["exp_candy_xl"], &"mew", 100)
	if capped.is_empty(): return
	var capped_owner: PlayerCollection = capped.owner
	var capped_svc: RefCounted = capped.service
	var before_cap: Dictionary = _owner_data(capped_owner)
	var at_cap: Dictionary = capped_svc.use_item(&"exp_candy_xl", &"own")
	check("v2 level100 capped experience refused without spending",
		not bool(at_cap.get("accepted", true))
		and String(at_cap.get("reason", "")) == "item_has_no_effect"
		and _owner_data(capped_owner) == before_cap
		and capped_owner.inventory.quantity(&"exp_candy_xl") == 1)
	_assert_save(capped_owner, "level100 " + mode)

func _probe_growth_choices(mode: String) -> void:
	var moves: Array = ["tackle", "growl", "reflect", "protect"]
	var ctx: Dictionary = _new_minted(mode, ["rare_candy"], &"bulbasaur", 11, moves)
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var before: Dictionary = _owner_data(owner)
	var prompt: Dictionary = svc.use_growth_item(&"rare_candy", &"own")
	check("v2 level12 real learn/replace prompt and no transaction",
		String(prompt.get("status", "")) == "NEEDS_CONTEXT"
		and String(prompt.get("prompt", {}).get("kind", "")) == "move"
		and String(prompt.get("prompt", {}).get("move_id", "")) == "razor_leaf"
		and _owner_data(owner) == before)
	if String(prompt.get("status", "")) == "NEEDS_CONTEXT":
		var decisions: Dictionary = {String(prompt.prompt.key): 1}
		var applied: Dictionary = svc.use_growth_item(&"rare_candy", &"own",
			decisions, String(prompt.get("stamp", "")))
		var now: CreatureInstance = owner.owned_creature(&"own")
		check("v2 level12 specific move replaced with correct PP",
			bool(applied.get("accepted", false)) and now != null
			and now.level == 12 and now.move_ids[1] == &"razor_leaf"
			and now.moveset[1].current_pp == catalogs.move(&"razor_leaf").pp
			and owner.inventory.quantity(&"rare_candy") == 0)
		_assert_effective(now, &"adamant", "learn " + mode)
		_assert_save(owner, "learn " + mode)
	# Level evolution needs a second explicit decision; no items spent
	# during NEEDS_CONTEXT and evolution must preserve effective nature.
	ctx = _new_minted(mode, ["rare_candy"], &"bulbasaur", 15, moves)
	if ctx.is_empty(): return
	owner = ctx.owner
	svc = ctx.service
	before = _owner_data(owner)
	prompt = svc.use_growth_item(&"rare_candy", &"own")
	check("v2 level16 explicit ivysaur evolution prompt",
		String(prompt.get("status", "")) == "NEEDS_CONTEXT"
		and String(prompt.get("prompt", {}).get("kind", "")) == "evolution"
		and prompt.get("prompt", {}).get("targets", []).has("ivysaur")
		and _owner_data(owner) == before)
	if String(prompt.get("status", "")) == "NEEDS_CONTEXT":
		var decisions: Dictionary = {String(prompt.prompt.key): "ivysaur"}
		var stamp: String = String(prompt.get("stamp", ""))
		var outcome: Dictionary = svc.use_growth_item(&"rare_candy", &"own", decisions, stamp)
		for attempt in 12:
			if String(outcome.get("status", "")) != "NEEDS_CONTEXT": break
			var extra: Dictionary = outcome.get("prompt", {})
			decisions[String(extra.get("key", ""))] = -1 if String(extra.get("kind", "")) == "move" else "ivysaur"
			outcome = svc.use_growth_item(&"rare_candy", &"own", decisions, stamp)
		var now: CreatureInstance = owner.owned_creature(&"own")
		check("v2 evolution real candidate published one transaction",
			bool(outcome.get("accepted", false)) and now != null
			and now.species_id == &"ivysaur" and now.level == 16
			and now.move_ids.size() == 4
			and now.moveset[0].move_id == &"tackle"
			and now.moveset[1].move_id == &"growl"
			and owner.inventory.quantity(&"rare_candy") == 0)
		_assert_effective(now, &"adamant", "evolve " + mode)
		_assert_save(owner, "evolve " + mode)

func _probe_fresh_start(mode: String) -> void:
	# Nonzero EV source is necessary for reset, not a metadata-only check.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var source: CreatureInstance = CreatureFactory.create(catalogs.species(&"mew"), 50,
		catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": ["growl", "protect"]})
	check("v2 fresh source", source != null)
	if source == null: return
	source.evs["attack"] = 60
	source.evs["speed"] = 20
	source.recalculate_stats(catalogs.species(source.species_id), ProgressionRuleset.new())
	source.friendship = 99
	source.current_hp = source.stats.max_hp - 9
	var owner := _pilot_owner(source, mode)
	check("v2 fresh mint stock", owner.inventory.add(&"adamant_mint", 1))
	check("v2 fresh reset stock", owner.inventory.add(&"fresh_start_mochi", 2))
	var svc := Service.new()
	check("v2 fresh service", svc.configure(owner, catalogs, func(): return true))
	var minted: Dictionary = svc.use_item(&"adamant_mint", &"own")
	check("v2 fresh effective nature applied", bool(minted.get("accepted", false)))
	var before: CreatureInstance = owner.owned_creature(&"own")
	var old_hp: int = before.current_hp
	var old_friend: int = before.friendship
	var old_pp: Dictionary = before.moveset[0].to_dict()
	var action: Dictionary = svc.use_item(&"fresh_start_mochi", &"own")
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("v2 fresh reset exactly 80 EV and spends one",
		bool(action.get("accepted", false)) and String(action.get("action", "")) == "ev_reset"
		and int(action.get("ev_removed", -1)) == 80
		and owner.inventory.quantity(&"fresh_start_mochi") == 1
		and now.evs.attack == 0 and now.evs.speed == 0
		and now.friendship == old_friend and now.current_hp == old_hp
		and now.moveset[0].to_dict() == old_pp)
	_assert_effective(now, &"adamant", "fresh start " + mode)
	_assert_save(owner, "fresh start " + mode)
	var repeat_before: Dictionary = _owner_data(owner)
	var repeat: Dictionary = svc.use_item(&"fresh_start_mochi", &"own")
	check("v2 fresh repeated no EV no spending atomic",
		not bool(repeat.get("accepted", true))
		and String(repeat.get("reason", "")) == "item_has_no_effect"
		and _owner_data(owner) == repeat_before)

func _probe_vitamins(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, ["protein", "carbos"])
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var now: CreatureInstance = owner.owned_creature(&"own")
	var initial_friend: int = now.friendship
	var first: Dictionary = svc.use_item(&"protein", &"own")
	now = owner.owned_creature(&"own")
	check("v2 protein boosts attack EV and real friendship", bool(first.get("accepted", false))
		and String(first.get("action", "")) == "ev_training"
		and int(first.get("ev_added", 0)) == 10 and now.evs.attack == 10
		and now.friendship == initial_friend + 5
		and owner.inventory.quantity(&"protein") == 0)
	_assert_effective(now, &"adamant", "protein " + mode)
	var second: Dictionary = svc.use_item(&"carbos", &"own")
	now = owner.owned_creature(&"own")
	check("v2 carbos boosts speed EV and second friendship tier",
		bool(second.get("accepted", false)) and int(second.get("ev_added", 0)) == 10
		and now.evs.speed == 10 and now.friendship == initial_friend + 8
		and owner.inventory.quantity(&"carbos") == 0)
	_assert_effective(now, &"adamant", "carbos " + mode)
	_assert_save(owner, "vitamins " + mode)

func _probe_chain(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode,
		["rare_candy", "muscle_mochi", "carbos", "timid_mint", "timid_mint"])
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var baseline: CreatureInstance = owner.owned_creature(&"own")
	var before_iv: Dictionary = baseline.ivs.duplicate(true)
	var before_pp: Dictionary = baseline.moveset[0].to_dict()
	var original_deficit: int = baseline.stats.max_hp - baseline.current_hp
	var stamp: Dictionary = _owner_data(owner)
	var invalid: Dictionary = svc.use_item(&"rare_candy", &"own", 0)
	check("v2 chain growth invalid slot rollback", not bool(invalid.get("accepted", true))
		and String(invalid.get("reason", "")) == "unexpected_growth_target"
		and _owner_data(owner) == stamp)
	var grow: Dictionary = _resolve_growth(svc, &"rare_candy")
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("v2 chain real growth", bool(grow.get("accepted", false))
		and now.level == baseline.level + 1
		and owner.inventory.quantity(&"rare_candy") == 0)
	_assert_effective(now, &"adamant", "chain growth " + mode)
	var mochi: Dictionary = svc.use_item(&"muscle_mochi", &"own")
	now = owner.owned_creature(&"own")
	check("v2 chain muscle mochi applies EV one stock",
		bool(mochi.get("accepted", false)) and now.evs.attack == 10
		and owner.inventory.quantity(&"muscle_mochi") == 0)
	_assert_effective(now, &"adamant", "chain mochi " + mode)
	var vitamin: Dictionary = svc.use_item(&"carbos", &"own")
	now = owner.owned_creature(&"own")
	check("v2 chain carbos after mochi preserves nature",
		bool(vitamin.get("accepted", false)) and now.evs.speed == 10
		and owner.inventory.quantity(&"carbos") == 0)
	_assert_effective(now, &"adamant", "chain vitamin " + mode)
	var mint: Dictionary = svc.use_item(&"timid_mint", &"own")
	now = owner.owned_creature(&"own")
	check("v2 chain final mint changes effective only",
		bool(mint.get("accepted", false)) and now.effective_nature_id == &"timid"
		and owner.inventory.quantity(&"timid_mint") == 1
		and now.ivs == before_iv and now.moveset[0].to_dict() == before_pp
		and now.stats.max_hp - now.current_hp == original_deficit
		and now.level == baseline.level + 1
		and now.evs.attack == 10 and now.evs.speed == 10
		and now.nature_id == &"hardy"
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	_assert_effective(now, &"timid", "chain final " + mode)
	_assert_save(owner, "chain final " + mode)
	var terminal: Dictionary = _owner_data(owner)
	var repeated: Dictionary = svc.use_item(&"timid_mint", &"own")
	check("v2 chain repeat effective no spending rollback",
		not bool(repeated.get("accepted", true))
		and String(repeated.get("reason", "")) == "item_has_no_effect"
		and _owner_data(owner) == terminal)
