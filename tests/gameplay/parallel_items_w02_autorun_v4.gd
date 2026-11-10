extends "res://tests/gameplay/parallel_items_w02_autorun_v3.gd"

# W02 TANDA 04, no new items. Native baseline-equivalence and rerun of actual
# transactions to prove the scoped Growth.plan cleanup preserves behavior.
const V4_FIXTURE := "res://tests/fixtures/parallel_items/w02_autorun_v4.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run_v4")
	create_timer(700.0).timeout.connect(func():
		if not done:
			push_error("W02 AUTORUN V4 watchdog")
			quit(2))

func _run_v4() -> void:
	destination = "res://.godot/parallel_items/w02_autorun_v4"
	DirAccess.make_dir_recursive_absolute(destination)
	var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(V4_FIXTURE))
	check("V4 immutable manifest and baseline", f is Dictionary
		and String(f.get("worker", "")) == "W02"
		and String(f.get("tanda", "")) == "04"
		and int(f.get("new_items", -1)) == 0
		and f.get("modes", []) == ["active", "reserve"]
		and f.get("checks", []).size() == 10
		and int(f.baseline.run_id) == 42890511612)
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("V4 catalog overlay", Variants.apply(catalogs))
	for mode: String in ["active", "reserve"]:
		current_case = "semantic_equivalence_" + mode
		_probe_equivalence(mode)
		current_case = "level_ivysaur_" + mode
		_test_level_evolution(mode)
		current_case = "item_vaporeon_" + mode
		_probe_vaporeon_item(mode)
		current_case = "multilevel_choices_" + mode
		_probe_multilevel(mode)
		current_case = "unminted_" + mode
		_test_unminted_evolution(mode)
		current_case = "replaced_" + mode
		_test_mint_replacement(mode)
		current_case = "same_original_" + mode
		_test_same_original_effective(mode)
		current_case = "save_corruption_" + mode
		_test_save_corruption(mode)
	var passed: bool = errors.is_empty()
	done = true
	print("W02_AUTORUN_V4_GODOT ", "PASS" if passed else "FAIL", " checks=", checks)
	quit(0 if passed else 1)

func _probe_equivalence(mode: String) -> void:
	# The removed old fallback did: (1) copy effective_nature_id again,
	# (2) recalculate_stats again. The general EvolutionSystem now owns both.
	# Compare entire persisted creature payload before/after that old fallback.
	for original_nature: StringName in [&"hardy", &"adamant"]:
		var ctx: Dictionary = _new_minted(mode, ["water_stone"], &"eevee", 30)
		if ctx.is_empty(): continue
		var owner: PlayerCollection = ctx.owner
		var source: CreatureInstance = owner.owned_creature(&"own")
		var state: Dictionary = _owner_data(owner)
		if original_nature == &"adamant":
			# In this row the effective and birth nature coincide after
			# an explicit remint; no mutation of the creature factory.
			var changed: Dictionary = source.to_dict()
			changed["nature_id"] = "adamant"
			var with_birth: CreatureInstance = CreatureInstance.from_dict(changed)
			check("V4 valid alternate birth-nature fixture", with_birth != null)
			if with_birth == null: continue
			with_birth.recalculate_stats(catalogs.species(with_birth.species_id), ProgressionRuleset.new())
			check("V4 stage same-identity source for comparison",
				owner.replace_owned_same_identity(with_birth))
			source = owner.owned_creature(&"own")
			state = _owner_data(owner)
		var new_evolution: CreatureInstance = EvolutionSystem.apply_evolution(
			source, &"vaporeon", catalogs, ProgressionRuleset.new())
		check("V4 direct canonical evolution source exists", new_evolution != null)
		if new_evolution == null: continue
		var legacy_fallback: CreatureInstance = CreatureInstance.from_dict(new_evolution.to_dict())
		check("V4 legacy fallback candidate copy exists", legacy_fallback != null)
		if legacy_fallback == null: continue
		legacy_fallback.effective_nature_id = source.effective_nature_id
		legacy_fallback.recalculate_stats(
			catalogs.species(legacy_fallback.species_id), ProgressionRuleset.new())
		check("V4 old duplicate recalculation is semantically idempotent",
			legacy_fallback.to_dict() == new_evolution.to_dict())
		check("V4 birth/effective nature and exact independent stat oracle",
			new_evolution.nature_id == original_nature
			and new_evolution.effective_nature_id == &"adamant"
			and new_evolution.stats.to_dict() == StatCalculator.compute(
				catalogs.species(&"vaporeon").base_stat_block(), source.ivs, source.evs,
				&"adamant", source.level).to_dict()
			and new_evolution.instance_id == source.instance_id)
		check("V4 no accidental publication from staged equivalence",
			_owner_data(owner) == state and owner.owned_creature(&"own").species_id == &"eevee")

func _probe_vaporeon_item(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, ["water_stone"], &"eevee", 30)
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var before: Dictionary = _owner_data(owner)
	var rejected: Dictionary = svc.evolve(&"water_stone", &"own", &"flareon")
	check("V4 wrong evolution target leaves full SaveV2 state untouched",
		not bool(rejected.get("accepted", true))
		and _owner_data(owner) == before)
	var accepted: Dictionary = svc.evolve(&"water_stone", &"own", &"vaporeon")
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("V4 water stone exact one-use and owner no duplication",
		bool(accepted.get("accepted", false)) and now != null
		and now.species_id == &"vaporeon"
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY")
		and owner.inventory.quantity(&"water_stone") == 0)
	_assert_effective(now, &"adamant", "V4 water stone " + mode)
	_assert_save(owner, "V4 water stone " + mode)

func _probe_multilevel(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, ["exp_candy_xl"], &"bulbasaur", 11,
		["tackle", "growl", "reflect", "protect"])
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var initial: CreatureInstance = owner.owned_creature(&"own")
	var start_level: int = initial.level
	var start_hp_deficit: int = initial.stats.max_hp - initial.current_hp
	var pp: Dictionary = initial.moveset[0].to_dict()
	var iv: Dictionary = initial.ivs.duplicate(true)
	var ev: Dictionary = initial.evs.duplicate(true)
	var snapshot: Dictionary = _owner_data(owner)
	var first: Dictionary = svc.use_growth_item(&"exp_candy_xl", &"own")
	check("V4 multiple level gain prompts without consuming inventory",
		String(first.get("status", "")) == "NEEDS_CONTEXT"
		and _owner_data(owner) == snapshot
		and owner.inventory.quantity(&"exp_candy_xl") == 1)
	if String(first.get("status", "")) != "NEEDS_CONTEXT": return
	var key: String = String(first.get("prompt", {}).get("key", ""))
	var stamp: String = String(first.get("stamp", ""))
	var bad: Dictionary = svc.use_growth_item(&"exp_candy_xl", &"own",
		{key: 99999}, stamp)
	check("V4 invalid decision rejects with atomic rollback",
		not bool(bad.get("accepted", true))
		and _owner_data(owner) == snapshot)
	var choices: Dictionary = {}
	var response: Dictionary = first
	var prompts: int = 0
	var evolved: bool = false
	for attempt in 120:
		if String(response.get("status", "")) != "NEEDS_CONTEXT": break
		var prompt: Dictionary = response.get("prompt", {})
		var kind: String = String(prompt.get("kind", ""))
		var decision: Variant = -1
		if kind == "evolution":
			var targets: Array = prompt.get("targets", [])
			decision = "ivysaur" if not evolved and targets.has("ivysaur") else ""
			if decision == "ivysaur": evolved = true
		choices[String(prompt.get("key", ""))] = decision
		response = svc.use_growth_item(&"exp_candy_xl", &"own", choices, stamp)
		prompts += 1
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("V4 multi-level learned moves and evolution resolved transactionally",
		bool(response.get("accepted", false)) and now != null
		and now.level > start_level + 1 and now.species_id == &"ivysaur"
		and prompts >= 2 and owner.inventory.quantity(&"exp_candy_xl") == 0
		and now.moveset[0].to_dict() == pp
		and now.ivs == iv and now.evs == ev
		and now.stats.max_hp - now.current_hp == start_hp_deficit
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	_assert_effective(now, &"adamant", "V4 multilevel " + mode)
	_assert_save(owner, "V4 multilevel " + mode)
	var final_state: Dictionary = _owner_data(owner)
	var repeated: Dictionary = svc.use_growth_item(&"exp_candy_xl", &"own")
	check("V4 multilevel no-stock replay rejected without mutating owner",
		not bool(repeated.get("accepted", true))
		and String(repeated.get("reason", "")) == "item_not_owned"
		and _owner_data(owner) == final_state)
