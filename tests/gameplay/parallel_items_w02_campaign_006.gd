extends "res://tests/gameplay/parallel_items_w02_campaign_005.gd"

# CAMP006 W02 block01: real native regression of 41742682811.
# Reuses (never mocks) full CAMP005 Service/CreatureFactory/SaveV2 probe.
const SOURCE_006_RECOVERY := "res://tests/fixtures/parallel_items/w02_campaign_006.json"


func _initialize() -> void:
	capture = false
	call_deferred("_run_recovery006")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("CAMP006 W02 recovery watchdog")
			quit(2))


func _run_recovery006() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_006"
	DirAccess.make_dir_recursive_absolute(destination)
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_006_RECOVERY))
	if not loaded is Dictionary:
		push_error("CAMP006 W02 fixture no es Dictionary")
		quit(2)
		return
	automation = loaded
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay real y especies base", Variants.apply(catalogs))
	check("worker y campaña propios", automation.campaign == "CAMP_006"
		and automation.worker == "W02")
	check("recuperación + bloques02/03 + piloto04", automation.blocks.size() == 4
		and automation.blocks[0].block == "01"
		and automation.blocks[0].ids == ["exp_candy_xl", "relaxed_mint"]
		and automation.blocks[1].block == "02"
		and automation.blocks[1].ids == ["gentle_mint", "hasty_mint", "lax_mint"]
		and automation.blocks[1].status == "DEPENDENCY_DOCUMENTED_NOT_FUNCTIONAL"
		and automation.blocks[2].block == "03"
		and automation.blocks[2].ids == ["lonely_mint", "mild_mint", "naive_mint"]
		and automation.blocks[2].status == "DEPENDENCY_DOCUMENTED_NOT_FUNCTIONAL"
		and automation.blocks[3].block == "04"
		and automation.blocks[3].ids == ["naughty_mint", "rash_mint", "sassy_mint", "serious_mint"]
		and automation.blocks[3].status == "POSITIVE_PILOT_AWAITING_CI")
	check("tres modos heredados PARTY/STORAGE", automation.modes == ["active", "none", "reserve"])
	var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_005))
	check("fixture CAMP005 intacta", old is Dictionary)
	if not old is Dictionary:
		quit(2)
		return
	check("conservados los diez bloques CAMP005", old.blocks.size() == 10)
	var count_cases: int = 0
	for block: Dictionary in old.blocks:
		count_cases += block.cases.size()
	check("conservados los 288 escenarios", count_cases == 288)
	var selected: Dictionary = {}
	for block: Dictionary in old.blocks:
		for spec: Dictionary in block.cases:
			for criterion: Dictionary in automation.blocks[0].cases:
				if String(spec.scenario) == String(criterion.scenario):
					check("escenario recuperación único", not selected.has(String(spec.scenario)))
					selected[String(spec.scenario)] = spec
	check("exactamente tres escenarios de recuperación", selected.size() == 3)
	var curve: String = String(catalogs.species(&"mew").growth_rate)
	var xp99: int = ProgressionRuleset.experience_for_level(curve, 99)
	var xp100: int = ProgressionRuleset.experience_for_level(curve, 100)
	check("Mew usa curva medium-slow", curve == "medium-slow")
	check("brecha independiente 99 a 100 es 32757", xp100 - xp99 == 32757)
	check("Caramelo XL 30000 inferior a brecha", xp99 + 30000 < xp100)
	var passed_cases: int = 0
	for criterion: Dictionary in automation.blocks[0].cases:
		var label: String = String(criterion.scenario)
		current_case = label
		if not selected.has(label):
			check("escenario requerido presente", false)
			continue
		var spec: Dictionary = selected[label]
		var before_errors: int = errors.size()
		var observed: Dictionary = {}
		for mode: String in automation.modes:
			observed[mode] = _probe_training(spec, mode)
			check(mode + " ejecución nativa y SaveV2", bool(observed[mode].get("valid", false))
				and bool(observed[mode].get("save_v2", false)))
			if label == "exp_candy_xl_level99_gain":
				check(mode + " XL sube 30000 XP sin subir al 100",
					int(observed[mode].get("level", -1)) == 99
					and bool(observed[mode].get("accepted", false)) == (mode != "none")
					and xp99 + 30000 == int(criterion.expected_exp)
					and xp100 - xp99 - 30000 == int(criterion.exp_remaining))
			elif label == "exp_candy_xl_level99_cap_50xp":
				check(mode + " XL a 50 XP de 100 sí llega a 100",
					int(observed[mode].get("level", -1)) == (99 if mode == "none" else 100)
					and bool(observed[mode].get("accepted", false)) == (mode != "none")
					and int(criterion.expected_exp_gain) == 50)
			elif label == "relaxed_mint_level100":
				check(mode + " mint sin ejecutor no altera ni consume",
					int(observed[mode].get("level", -1)) == 100
					and not bool(observed[mode].get("accepted", true))
					and int(observed[mode].get("count", -1)) == (0 if mode == "none" else 2))
		if errors.size() == before_errors:
			passed_cases += 1
	check("los tres contratos completos sin errores", passed_cases == 3)
	# Only one shared dependency: the native item service cannot apply any of
	# these three mints until IA6 approves an independent effective-nature field.
	var b2: Dictionary = automation.blocks[1]
	check("bloque02 sin falso nivel L2", String(b2.dependency.level) == "L1_DEPENDENCY_NOT_L2"
		and b2.cases.size() == 1)
	for id_text: String in b2.ids:
		check("catálogo incluye menta pendiente: " + id_text,
			catalogs.item(StringName(id_text)) != null)
	var nature_specs: Dictionary = b2.expected_nature_modifiers
	for nature: String in nature_specs:
		var target: Dictionary = nature_specs[nature]
		var expected_pair: Array = [String(target.up), String(target.down)]
		check("tabla nativa naturaleza y modificadores: " + nature,
			ProgressionRuleset.NATURE_MODIFIERS.get(StringName(nature), []) == expected_pair)
	var example: Dictionary = b2.cases[0]
	check("único test negativo representativo", example.scenario == "gentle_mint_missing_effect_route"
		and example.id == "gentle_mint" and not bool(example.applies))
	current_case = String(example.scenario)
	var sentinel_errors: int = errors.size()
	var rejected_all: bool = true
	for mode: String in automation.modes:
		var mint_spec: Dictionary = example
		var result_mint: Dictionary = _probe_training(mint_spec, mode)
		rejected_all = (rejected_all and bool(result_mint.get("valid", false))
			and bool(result_mint.get("save_v2", false))
			and not bool(result_mint.get("accepted", true))
			and int(result_mint.get("count", -1)) == (0 if mode == "none" else 2))
	check("menta representativa rechazada en tres propietarios con SaveV2",
		rejected_all and errors.size() == sentinel_errors)
	print("CAMP006_W02_DEPENDENCY ", "BLOCKED" if rejected_all
		and errors.size() == sentinel_errors else "FAIL",
		" block=02 ids=3 checks=", checks)
	var block03: Dictionary = automation.blocks[2]
	check("03 hereda único productor pendiente IA6",
		String(block03.dependency_ref) == String(b2.dependency.key)
		and block03.cases.is_empty() and String(block03.dependency_owner) == "IA6")
	var expected03: Dictionary = {"lonely": ["attack", "defense"],
		"mild": ["special_attack", "defense"],
		"naive": ["speed", "special_defense"]}
	check("03 tiene tres naturalezas", block03.expected_nature_modifiers.size() == 3)
	for nat03: String in expected03:
		var m03: Dictionary = block03.expected_nature_modifiers.get(nat03, {})
		check("03 modificadores nativos: " + nat03,
			ProgressionRuleset.NATURE_MODIFIERS.get(StringName(nat03), []) == expected03[nat03]
			and String(m03.get("up", "")) == String(expected03[nat03][0])
			and String(m03.get("down", "")) == String(expected03[nat03][1]))
	for id03: String in block03.ids:
		check("03 objeto menta presente en catálogo: " + id03,
			catalogs.item(StringName(id03)) != null)
	print("CAMP006_W02_DEPENDENCY BLOCKED block=03 ids=3 checks=", checks)
	var mint04_ok: bool = true
	for pilot_spec: Dictionary in automation.blocks[3].cases:
		current_case = String(pilot_spec.scenario)
		for mode04: String in automation.modes:
			var errors_before_04: int = errors.size()
			_probe_mint04(pilot_spec, mode04)
			if errors.size() != errors_before_04: mint04_ok = false
	print("CAMP006_W02_MINT04 ", "PASS" if mint04_ok else "FAIL",
		" block=04 ids=4 checks=", checks)
	var success: bool = errors.is_empty() and passed_cases == 3 and mint04_ok
	done = true
	print("CAMP006_W02_GODOT ", "PASS" if success else "FAIL",
		" blocks=", 1 if success else 0, " checks=", checks)
	quit(0 if success else 1)


# Block04 is a true native engine integration, not a fixture-only mint mapping.
# The authorised W02 service owns detached staging and inventory publication.
func _probe_mint04(spec: Dictionary, mode: String) -> void:
	var item: StringName = StringName(spec.id)
	var target: StringName = StringName(spec.target_nature)
	var source_nature: StringName = StringName(spec.original_nature)
	var build_spec: Dictionary = {"kind": "mint_pilot", "nature": String(source_nature), "level": 50}
	var c: CreatureInstance = _training_creature(build_spec)
	check(mode + " criatura mint04 real", c != null)
	if c == null: return
	var owner := PlayerCollection.new()
	check(mode + " menta04 equipo real", owner.party.add_creature(c))
	if mode == "reserve": check(mode + " menta04 STORAGE real", owner.deposit(&"own"))
	if mode != "none": check(mode + " menta04 dos unidades reales", owner.inventory.add(item, 2))
	var service := Service.new()
	check(mode + " servicio menta04 nativo", service.configure(owner, catalogs, func(): return true))
	var original: Dictionary = c.to_dict()
	var before: Dictionary = _owner_data(owner)
	var old_hp: int = c.current_hp
	var expected_stats: StatBlock = StatCalculator.compute(
		catalogs.species(c.species_id).base_stat_block(), c.ivs, c.evs, target, c.level)
	var original_stats: Dictionary = c.stats.to_dict()
	check(mode + " menta04 modificadores reales calculan diferencia",
		expected_stats.to_dict() != original_stats
		and ProgressionRuleset.is_valid_nature(target)
		and c.nature_id == source_nature and c.effective_nature_id == &"")
	var before_illegal: Dictionary = _owner_data(owner)
	var illegal: Dictionary = service.use_item(item, &"own", 0)
	check(mode + " menta04 slot no solicitado es rollback",
		not bool(illegal.get("accepted", true))
		and String(illegal.get("reason", "")) == "unexpected_mint_target"
		and _owner_data(owner) == before_illegal)
	var applied: Dictionary = service.use_item(item, &"own")
	var should_apply: bool = mode != "none"
	check(mode + " menta04 aceptación real",
		bool(applied.get("accepted", false)) == should_apply)
	var now: CreatureInstance = owner.owned_creature(&"own")
	check(mode + " menta04 conserva identidad y propiedad", now != null
		and owner.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	if now == null: return
	check(mode + " menta04 bag gasta exactamente una",
		owner.inventory.quantity(item) == (1 if should_apply else 0))
	check(mode + " menta04 original en memoria no mutado", original == c.to_dict())
	if should_apply:
		check(mode + " menta04 cambia naturaleza efectiva, no original",
			now.effective_nature_id == target and now.nature_id == source_nature
			and String(applied.get("action", "")) == "effective_nature"
			and String(applied.get("effective_nature_id", "")) == String(target))
		check(mode + " menta04 estadísticas nativas exactas", expected_stats.to_dict() == now.stats.to_dict())
		check(mode + " menta04 conserva PS reales", now.stats.max_hp == c.stats.max_hp
			and now.current_hp == old_hp)
		for stat_key: String in spec.changed_stats:
			check(mode + " menta04 cambia estadística " + stat_key,
				int(now.stats.to_dict().get(stat_key, -1)) != int(original_stats.get(stat_key, -1)))
		check(mode + " menta04 no altera IV EV PP naturaleza o progreso",
			now.ivs == c.ivs and now.evs == c.evs and now.friendship == c.friendship
			and now.moveset[0].to_dict() == c.moveset[0].to_dict()
			and now.moveset[1].to_dict() == c.moveset[1].to_dict()
			and now.experience == c.experience and now.level == c.level
			and now.status_state.persistent_id == c.status_state.persistent_id)
		var before_duplicate: Dictionary = _owner_data(owner)
		var duplicate: Dictionary = service.use_item(item, &"own")
		check(mode + " menta04 duplicado sin efecto no consume ni muta",
			not bool(duplicate.get("accepted", true))
			and String(duplicate.get("reason", "")) == "item_has_no_effect"
			and _owner_data(owner) == before_duplicate)
	else:
		check(mode + " menta04 sin stock rechaza atómico",
			String(applied.get("reason", "")) == "item_not_owned"
			and _owner_data(owner) == before)
	var snapshot: Dictionary = _owner_data(owner)
	var loaded: LoadResult = SaveGameRepository.new().decode_snapshot(snapshot)
	check(mode + " menta04 SaveV2 carga real", loaded.ok)
	if loaded.ok:
		var reloaded := PlayerCollection.new()
		reloaded.party = loaded.party
		reloaded.storage = loaded.storage
		reloaded.inventory = loaded.inventory
		var saved: CreatureInstance = reloaded.owned_creature(&"own")
		check(mode + " menta04 SaveV2 conserva naturaleza efectiva y bolsa",
			saved != null
			and saved.nature_id == source_nature
			and saved.effective_nature_id == (target if should_apply else &"")
			and saved.stats.to_dict() == now.stats.to_dict()
			and reloaded.inventory.quantity(item) == owner.inventory.quantity(item)
			and reloaded.location_of(&"own") == owner.location_of(&"own"))
	var legacy: LoadResult = SaveGameRepository.new().decode_snapshot(before)
	check(mode + " menta04 snapshot SaveV2 anterior sin campo válido", legacy.ok)
	if legacy.ok:
		var legacy_collection := PlayerCollection.new()
		legacy_collection.party = legacy.party
		legacy_collection.storage = legacy.storage
		check(mode + " menta04 retrocompatibilidad naturaleza original",
			legacy_collection.owned_creature(&"own") != null
			and legacy_collection.owned_creature(&"own").effective_nature_id == &""
			and legacy_collection.owned_creature(&"own").nature_id == source_nature)
	if should_apply:
		var invalid: Dictionary = snapshot.duplicate(true)
		var entries: Array = invalid.get("creatures", [])
		for entry: Dictionary in entries:
			if String(entry.get("instance_id", "")) == "own":
				entry["effective_nature_id"] = "invented_invalid_nature"
		var invalid_load: LoadResult = SaveGameRepository.new().decode_snapshot(invalid)
		check(mode + " menta04 SaveV2 rechaza naturaleza efectiva inválida",
			not invalid_load.ok and invalid_load.reason == "invalid_creature_id")
