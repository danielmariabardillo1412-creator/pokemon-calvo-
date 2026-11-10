extends "res://tests/gameplay/parallel_items_w02_autorun_v2.gd"

# IA6 W02 TANDA03. Real mint -> direct shared evolution; test red BEFORE fix.
const V3_DATA := "res://tests/fixtures/parallel_items/w02_autorun_v3.json"

func _initialize() -> void:
	capture = false
	call_deferred("_run_v3")
	create_timer(480.0).timeout.connect(func():
		if not done:
			push_error("W02 AUTORUN V3 watchdog")
			quit(2))

func _run_v3() -> void:
	destination = "res://.godot/parallel_items/w02_autorun_v3"
	DirAccess.make_dir_recursive_absolute(destination)
	var f: Variant = JSON.parse_string(FileAccess.get_file_as_string(V3_DATA))
	check("v3 fixture complete and immutable", f is Dictionary and f.worker == "W02"
		and f.tanda == "03" and f.rows.size() == 10 and f.modes == ["active", "reserve"])
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("v3 canonical regional item overlay", Variants.apply(catalogs))
	for mode: String in ["active", "reserve"]:
		current_case = "direct_minted_evolution_" + mode
		_test_direct_minted(mode)
		current_case = "item_evolution_" + mode
		_test_item_evolution(mode)
		current_case = "unminted_evolution_" + mode
		_test_unminted_evolution(mode)
		current_case = "same_original_effective_" + mode
		_test_same_original_effective(mode)
		current_case = "replaced_mint_evolution_" + mode
		_test_mint_replacement(mode)
		current_case = "level_evolution_" + mode
		_test_level_evolution(mode)
		current_case = "save_corruption_" + mode
		_test_save_corruption(mode)
	var passed: bool = errors.is_empty()
	done = true
	print("W02_AUTORUN_V3_GODOT ", "PASS" if passed else "FAIL", " checks=", checks)
	quit(0 if passed else 1)

func _test_direct_minted(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, [], &"eevee", 30)
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var source: CreatureInstance = owner.owned_creature(&"own")
	var before: Dictionary = source.to_dict()
	var stock: Dictionary = _owner_data(owner)
	var evolved: CreatureInstance = EvolutionSystem.apply_evolution(
		source, &"vaporeon", catalogs, ProgressionRuleset.new())
	check("v3 real vaporeon created", evolved != null)
	if evolved == null: return
	var expected: Dictionary = StatCalculator.compute(catalogs.species(&"vaporeon").base_stat_block(),
		source.ivs, source.evs, &"adamant", source.level).to_dict()
	check("v3 shared evolution retains ORIGINAL and EFFECTIVE natures", 
		evolved.nature_id == &"hardy" and evolved.effective_nature_id == &"adamant")
	check("v3 shared evolution actual effective stat calculator", evolved.stats.to_dict() == expected)
	check("v3 direct evolution preserves identity IV EV friendship PP status held item", 
		evolved.instance_id == source.instance_id and evolved.level == source.level
		and evolved.ivs == source.ivs and evolved.evs == source.evs
		and evolved.friendship == source.friendship
		and evolved.move_ids == source.move_ids
		and evolved.moveset[0].to_dict() == source.moveset[0].to_dict()
		and evolved.moveset[1].to_dict() == source.moveset[1].to_dict()
		and evolved.current_hp == mini(source.current_hp, evolved.stats.max_hp))
	check("v3 direct staged creation no inventory or source mutation",
		source.to_dict() == before and _owner_data(owner) == stock)

func _test_item_evolution(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, ["fire_stone", "water_stone"], &"eevee", 30)
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var source: CreatureInstance = owner.owned_creature(&"own")
	var original: Dictionary = source.to_dict()
	var snapshot: Dictionary = _owner_data(owner)
	var wrong: Dictionary = svc.evolve(&"fire_stone", &"own", &"mewtwo")
	check("v3 invalid requested species rejected with atomic rollback",
		not bool(wrong.get("accepted", true))
		and String(wrong.get("reason", "")) == "invalid_evolution_target"
		and _owner_data(owner) == snapshot)
	wrong = svc.evolve(&"water_stone", &"own", &"flareon")
	check("v3 wrong stone cannot force incompatible target",
		not bool(wrong.get("accepted", true))
		and String(wrong.get("reason", "")) == "invalid_evolution_target"
		and _owner_data(owner) == snapshot)
	var effect: Dictionary = svc.evolve(&"fire_stone", &"own", &"flareon")
	var evolved: CreatureInstance = owner.owned_creature(&"own")
	check("v3 real Fire Stone evolution consumes precisely one and preserves owner",
		bool(effect.get("accepted", false))
		and String(effect.get("species_id", "")) == "flareon"
		and evolved != null and evolved.species_id == &"flareon"
		and owner.inventory.quantity(&"fire_stone") == 0
		and owner.inventory.quantity(&"water_stone") == 1
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	if evolved == null: return
	check("v3 evolved owned identity stats and slot status conserved",
		evolved.instance_id == source.instance_id and evolved.nature_id == &"hardy"
		and evolved.ivs == source.ivs and evolved.evs == source.evs
		and evolved.moveset[0].to_dict() == source.moveset[0].to_dict()
		and evolved.moveset[1].to_dict() == source.moveset[1].to_dict()
		and evolved.status_state.to_dict() == source.status_state.to_dict()
		and evolved.stat_stages.to_dict() == source.stat_stages.to_dict()
		and evolved.current_hp == mini(source.current_hp, evolved.stats.max_hp))
	_assert_effective(evolved, &"adamant", "fire stone minted " + mode)
	check("v3 source detached object untouched by evolution", source.to_dict() == original)
	var after: Dictionary = _owner_data(owner)
	wrong = svc.evolve(&"fire_stone", &"own", &"flareon")
	check("v3 second stone use without stock denied atomically",
		not bool(wrong.get("accepted", true))
		and String(wrong.get("reason", "")) == "item_not_owned"
		and _owner_data(owner) == after)
	_assert_save(owner, "evolved item " + mode)

func _test_unminted_evolution(mode: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var c: CreatureInstance = CreatureFactory.create(catalogs.species(&"eevee"), 30,
		catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": ["growl", "protect"]})
	check("v3 unminted canonical Eevee", c != null and c.effective_nature_id == &"")
	if c == null: return
	var owner := _pilot_owner(c, mode)
	check("v3 unminted Fire Stone stock", owner.inventory.add(&"fire_stone", 1))
	var svc := Service.new()
	check("v3 unminted real service", svc.configure(owner, catalogs, func(): return true))
	var before: Dictionary = c.to_dict()
	var effect: Dictionary = svc.evolve(&"fire_stone", &"own", &"flareon")
	var e: CreatureInstance = owner.owned_creature(&"own")
	check("v3 unminted evolution remains native, no effective nature synthesized",
		bool(effect.get("accepted", false)) and e != null and e.species_id == &"flareon"
		and e.nature_id == &"hardy" and e.effective_nature_id == &""
		and e.ivs == c.ivs and e.evs == c.evs
		and e.moveset[0].to_dict() == c.moveset[0].to_dict()
		and e.moveset[1].to_dict() == c.moveset[1].to_dict()
		and e.friendship == c.friendship
		and e.ability_id != &""
		and owner.inventory.quantity(&"fire_stone") == 0)
	if e == null: return
	var expected: Dictionary = StatCalculator.compute(
		catalogs.species(e.species_id).base_stat_block(), e.ivs, e.evs, &"hardy", e.level).to_dict()
	check("v3 unminted stats remain original oracle and current HP bounded",
		e.stats.to_dict() == expected
		and e.current_hp == mini(c.current_hp, e.stats.max_hp)
		and c.to_dict() == before)
	_assert_save(owner, "unminted legacy compatible " + mode)
	var snap: Dictionary = _owner_data(owner)
	var restored: LoadResult = SaveGameRepository.new().decode_snapshot(snap)
	check("v3 unminted legacy SaveV2 no effective nature", restored.ok)
	if restored.ok:
		var from_save := PlayerCollection.new()
		from_save.party = restored.party; from_save.storage = restored.storage
		var loaded: CreatureInstance = from_save.owned_creature(&"own")
		check("v3 legacy nature default absent",
			loaded != null and loaded.effective_nature_id == &""
			and loaded.nature_id == &"hardy")

func _test_same_original_effective(mode: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var c: CreatureInstance = CreatureFactory.create(catalogs.species(&"eevee"), 30,
		catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"adamant", "moves": ["growl", "protect"]})
	check("v3 same-original valid base", c != null and c.nature_id == &"adamant")
	if c == null: return
	var owner := _pilot_owner(c, mode)
	check("v3 same-original timid mint stock", owner.inventory.add(&"timid_mint", 1))
	check("v3 same-original adamant mint stock", owner.inventory.add(&"adamant_mint", 1))
	check("v3 same-original stone stock", owner.inventory.add(&"water_stone", 1))
	var svc := Service.new()
	check("v3 same-original configured", svc.configure(owner, catalogs, func(): return true))
	var first: Dictionary = svc.use_item(&"timid_mint", &"own")
	var second: Dictionary = svc.use_item(&"adamant_mint", &"own")
	var after_mint: CreatureInstance = owner.owned_creature(&"own")
	check("v3 original adamant and effective adamant via second mint",
		bool(first.get("accepted", false)) and bool(second.get("accepted", false))
		and after_mint.nature_id == &"adamant" and after_mint.effective_nature_id == &"adamant"
		and owner.inventory.quantity(&"timid_mint") == 0
		and owner.inventory.quantity(&"adamant_mint") == 0)
	var done_evo: Dictionary = svc.evolve(&"water_stone", &"own", &"vaporeon")
	var evolved: CreatureInstance = owner.owned_creature(&"own")
	check("v3 same original/effective nature persists after full evolution",
		bool(done_evo.get("accepted", false)) and evolved != null
		and evolved.species_id == &"vaporeon"
		and evolved.nature_id == &"adamant" and evolved.effective_nature_id == &"adamant"
		and owner.inventory.quantity(&"water_stone") == 0)
	if evolved == null: return
	var oracle: Dictionary = StatCalculator.compute(catalogs.species(&"vaporeon").base_stat_block(),
		evolved.ivs, evolved.evs, &"adamant", evolved.level).to_dict()
	check("v3 same nature exact stat oracle", evolved.stats.to_dict() == oracle)
	_assert_save(owner, "same nature " + mode)

func _test_mint_replacement(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, ["timid_mint", "water_stone"], &"eevee", 30)
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var first: CreatureInstance = owner.owned_creature(&"own")
	var original: Dictionary = first.to_dict()
	var second: Dictionary = svc.use_item(&"timid_mint", &"own")
	var changed: CreatureInstance = owner.owned_creature(&"own")
	check("v3 re-mint changes effective while preserving birth nature",
		bool(second.get("accepted", false)) and changed != null
		and changed.nature_id == &"hardy" and changed.effective_nature_id == &"timid"
		and owner.inventory.quantity(&"timid_mint") == 0)
	var evolution: Dictionary = svc.evolve(&"water_stone", &"own", &"vaporeon")
	var e: CreatureInstance = owner.owned_creature(&"own")
	check("v3 replacement then stone evolution one owned creature",
		bool(evolution.get("accepted", false)) and e != null
		and e.species_id == &"vaporeon"
		and e.nature_id == &"hardy" and e.effective_nature_id == &"timid"
		and owner.inventory.quantity(&"water_stone") == 0
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	_assert_effective(e, &"timid", "replacement " + mode)
	_assert_save(owner, "replacement " + mode)
	check("v3 replaced source object remained immutable", first.to_dict() == original)

func _test_level_evolution(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, ["rare_candy"], &"bulbasaur", 15,
		["tackle", "growl", "reflect", "protect"])
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var start: Dictionary = _owner_data(owner)
	var first: Dictionary = svc.use_growth_item(&"rare_candy", &"own")
	check("v3 authentic level evolution requires explicit context",
		String(first.get("status", "")) == "NEEDS_CONTEXT"
		and String(first.get("prompt", {}).get("kind", "")) == "evolution"
		and _owner_data(owner) == start)
	if String(first.get("status", "")) != "NEEDS_CONTEXT": return
	var choices: Dictionary = {String(first.prompt.key): "ivysaur"}
	var stamp: String = String(first.get("stamp", ""))
	var outcome: Dictionary = svc.use_growth_item(&"rare_candy", &"own", choices, stamp)
	for attempt in 12:
		if String(outcome.get("status", "")) != "NEEDS_CONTEXT": break
		var next_prompt: Dictionary = outcome.get("prompt", {})
		choices[String(next_prompt.get("key", ""))] = -1 if String(next_prompt.get("kind", "")) == "move" else "ivysaur"
		outcome = svc.use_growth_item(&"rare_candy", &"own", choices, stamp)
	var now: CreatureInstance = owner.owned_creature(&"own")
	check("v3 level evolution publishes via existing growth transaction exactly once",
		bool(outcome.get("accepted", false)) and now != null
		and now.level == 16 and now.species_id == &"ivysaur"
		and now.moveset.size() == 4
		and owner.inventory.quantity(&"rare_candy") == 0)
	_assert_effective(now, &"adamant", "level-up " + mode)
	_assert_save(owner, "level-up " + mode)

func _test_save_corruption(mode: String) -> void:
	var ctx: Dictionary = _new_minted(mode, ["fire_stone"], &"eevee", 30)
	if ctx.is_empty(): return
	var owner: PlayerCollection = ctx.owner
	var svc = ctx.service
	var response: Dictionary = svc.evolve(&"fire_stone", &"own", &"flareon")
	check("v3 save candidate actually evolved", bool(response.get("accepted", false)))
	if not bool(response.get("accepted", false)): return
	var state: Dictionary = _owner_data(owner)
	_assert_save(owner, "corrupt reference clean " + mode)
	var forged: Dictionary = state.duplicate(true)
	for row: Dictionary in forged.get("creatures", []):
		if String(row.get("instance_id", "")) == "own":
			row["effective_nature_id"] = "malformed_fake_mint_20261110"
	var invalid: LoadResult = SaveGameRepository.new().decode_snapshot(forged)
	check("v3 SaveV2 rejects invalid effective nature rather than publishing",
		not invalid.ok and String(invalid.reason) == "invalid_creature_id")
	check("v3 corrupted external snapshot never alters live owner and stock",
		_owner_data(owner) == state and owner.inventory.quantity(&"fire_stone") == 0)
	# Direct invalid evolution cannot accidentally fabricate an owned creature.
	var source: CreatureInstance = owner.owned_creature(&"own")
	var bad: CreatureInstance = EvolutionSystem.apply_evolution(
		source, &"invalid_species_20261110", catalogs, ProgressionRuleset.new())
	check("v3 direct unknown target rejects without owner writes",
		bad == null and _owner_data(owner) == state)
