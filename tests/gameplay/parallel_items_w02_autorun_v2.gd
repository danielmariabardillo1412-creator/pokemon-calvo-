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
