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
