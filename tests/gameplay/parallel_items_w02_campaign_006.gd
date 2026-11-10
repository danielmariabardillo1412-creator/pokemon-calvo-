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
	check("recuperación + bloques02/03 + piloto04 + held05", automation.blocks.size() == 5
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
		and automation.blocks[3].status == "POSITIVE_PILOT_CI_VERIFIED"
		and automation.blocks[4].block == "05"
		and automation.blocks[4].ids == ["everstone", "exp_share", "lucky_egg"]
		and automation.blocks[4].status == "TWO_POSITIVE_ONE_DEPENDENCY_AWAITING_CI")
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
				# The archived negative is preserved on frozen SHA. In current HEAD
				# relaxed_mint is explicitly promoted in IA6 AUTONOMY_V1.
				check(mode + " mint relaxed promote exact positive level100",
					int(observed[mode].get("level", -1)) == 100
					and bool(observed[mode].get("accepted", false)) == (mode != "none")
					and int(observed[mode].get("count", -1)) == (0 if mode == "none" else 1))
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
		# The historical gentle-mint rejection remains in the immutable fixture.
		# On current HEAD all ten autonomy mints are promoted; require a
		# real invalid-target rollback, never a fabricated missing handler.
		var mint_spec: Dictionary = example.duplicate(true)
		mint_spec["id"] = "hasty_mint"
		mint_spec["scenario"] = "hasty_mint_promoted_invalid_slot"
		mint_spec["slot"] = 0
		mint_spec["wanted_nature"] = "hasty"
		# Original source fixture says DEPENDENCY_MISSING, but current tree
		# requires a strong negative (invalid slot) for a now-working item.
		var result_mint: Dictionary = _probe_training(mint_spec, mode)
		rejected_all = (rejected_all and bool(result_mint.get("valid", false))
			and bool(result_mint.get("save_v2", false))
			and not bool(result_mint.get("accepted", true))
			and int(result_mint.get("count", -1)) == (0 if mode == "none" else 2))
	check("menta promovida rechaza destino inválido en tres propietarios con SaveV2",
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

	var held05_ok: bool = true
	for held_case: Dictionary in automation.blocks[4].cases:
		current_case = String(held_case.scenario)
		for held_mode: String in automation.modes:
			var before05: int = errors.size()
			_probe_held05(held_case, held_mode)
			if errors.size() != before05: held05_ok = false
	print("CAMP006_W02_HELD05 ", "PASS" if held05_ok else "FAIL",
		" block=05 positive=2 dependency=1 checks=", checks)
	var success: bool = errors.is_empty() and passed_cases == 3 and mint04_ok and held05_ok
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



# CAMP006 W02 block05. Existing progression code is executed directly.
# Equippability is not considered proof of the missing Exp Share distribution.
func _held05_outcome() -> BattleOutcome:
	var o := BattleOutcome.new()
	o.winner_side_id = &"side_a"
	o.defeated = [{"base_experience": 71, "level": 7}]
	return o


func _held05_xp_events(events: Array, creature_id: StringName) -> int:
	var amount: int = 0
	for e: ProgressionEvent in events:
		if e.kind == ProgressionEvent.EXPERIENCE_GAINED and e.creature_id == creature_id:
			amount += int(e.data.get("amount", 0))
	return amount


func _held05_evolution_events(events: Array) -> int:
	var count: int = 0
	for e: ProgressionEvent in events:
		if e.kind == ProgressionEvent.EVOLUTION_AVAILABLE: count += 1
	return count


func _probe_held05(spec: Dictionary, mode: String) -> void:
	var id: StringName = StringName(spec.id)
	var sid: StringName = StringName(spec.original_species)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var c: CreatureInstance = CreatureFactory.create(
		catalogs.species(sid), int(spec.level), catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": &"own", "nature_id": &"hardy", "moves": ["growl"]})
	check(mode + " held05 creature domain", c != null and c.species_id == sid)
	if c == null: return
	var collection := PlayerCollection.new()
	check(mode + " held05 real party ownership", collection.party.add_creature(c))
	if mode == "reserve": check(mode + " held05 real storage", collection.deposit(&"own"))
	if mode != "none": check(mode + " held05 inventory two", collection.inventory.add(id, 2))
	var svc := Service.new()
	check(mode + " held05 actual FieldItemService", svc.configure(collection, catalogs, func(): return true))
	var before: Dictionary = _owner_data(collection)
	var equip_result: Dictionary = svc.equip(id, &"own")
	var equipped: bool = mode != "none"
	check(mode + " held05 equip result reflects stock", bool(equip_result.get("accepted", false)) == equipped)
	check(mode + " held05 equip spends exactly one unit",
		collection.inventory.quantity(id) == (1 if equipped else 0))
	if not equipped:
		check(mode + " held05 rejected no stock is atomic",
			String(equip_result.get("reason", "")) == "item_not_owned"
			and _owner_data(collection) == before)
		return
	var equipped_creature: CreatureInstance = collection.owned_creature(&"own")
	check(mode + " held05 active item and identity",
		equipped_creature != null and equipped_creature.held_item_id == id
		and not equipped_creature.held_item_consumed
		and collection.location_of(&"own") == (&"STORAGE" if mode == "reserve" else &"PARTY"))
	var repeated_before: Dictionary = _owner_data(collection)
	var repeated: Dictionary = svc.equip(id, &"own")
	check(mode + " held05 same equip rejects atomically",
		not bool(repeated.get("accepted", true))
		and String(repeated.get("reason", "")) == "already_equipped"
		and _owner_data(collection) == repeated_before)
	var loaded: LoadResult = SaveGameRepository.new().decode_snapshot(_owner_data(collection))
	check(mode + " held05 actual SaveV2 equipped load", loaded.ok)
	if not loaded.ok: return
	var owner2 := PlayerCollection.new()
	owner2.party = loaded.party
	owner2.storage = loaded.storage
	owner2.inventory = loaded.inventory
	var saved: CreatureInstance = owner2.owned_creature(&"own")
	check(mode + " held05 SaveV2 item/owner/stock",
		saved != null and saved.held_item_id == id and not saved.held_item_consumed
		and owner2.inventory.quantity(id) == 1
		and owner2.location_of(&"own") == collection.location_of(&"own"))
	if saved == null: return
	var service2 := Service.new()
	check(mode + " held05 rebind after SaveV2", service2.configure(owner2, catalogs, func(): return true))
	if id == &"everstone":
		var growth: String = String(catalogs.species(saved.species_id).growth_rate)
		var needed: int = ProgressionRuleset.experience_for_level(growth, int(spec.target_level)) - saved.experience
		check(mode + " Everstone real level threshold", needed > 0)
		var initial_friend: int = saved.friendship
		var before_events: Array = ProgressionSystem.gain_experience(
			saved, needed, catalogs.species(saved.species_id), catalogs, ProgressionRuleset.new())
		check(mode + " Everstone allows real level up but blocks evolution event",
			saved.level == int(spec.target_level)
			and _held05_xp_events(before_events, saved.instance_id) == needed
			and _held05_evolution_events(before_events) == 0
			and saved.friendship == initial_friend
			and saved.held_item_id == id and not saved.held_item_consumed)
		var unequip: Dictionary = service2.unequip(&"own")
		check(mode + " Everstone removed from same owner to inventory",
			bool(unequip.get("accepted", false))
			and saved.held_item_id == &"" and owner2.inventory.quantity(id) == 2)
		var restored_options: Array = EvolutionSystem.evolution_candidates(
			catalogs.species(saved.species_id), EvolutionSystem.level_up_context(saved), catalogs)
		check(mode + " Everstone removing unlocks real Ivysaur candidate",
			restored_options.any(func(ev): return ev.species_id == StringName(spec.expected_blocked_species)))
	elif id == &"lucky_egg":
		var start_exp: int = saved.experience
		var events: Array = ProgressionSystem.reconcile_battle_result(
			[saved], _held05_outcome(), catalogs, ProgressionRuleset.new())
		check(mode + " Lucky Egg actual battle progression 71 to 106",
			saved.experience == start_exp + int(spec.expected_held_reward)
			and _held05_xp_events(events, saved.instance_id) == int(spec.expected_held_reward)
			and saved.held_item_id == &"lucky_egg")
		check(mode + " Lucky Egg reward does not consume held item",
			owner2.inventory.quantity(id) == 1 and not saved.held_item_consumed)
		var unequip: Dictionary = service2.unequip(&"own")
		check(mode + " Lucky Egg unequip returns item", bool(unequip.get("accepted", false))
			and owner2.inventory.quantity(id) == 2)
		var plain_start: int = saved.experience
		var events_plain: Array = ProgressionSystem.reconcile_battle_result(
			[saved], _held05_outcome(), catalogs, ProgressionRuleset.new())
		check(mode + " Lucky Egg removed gives unboosted 71 XP",
			saved.experience == plain_start + int(spec.expected_normal_reward)
			and _held05_xp_events(events_plain, saved.instance_id) == int(spec.expected_normal_reward))
	elif id == &"exp_share":
		var idle_xp: int = saved.experience
		var other: CreatureInstance = CreatureFactory.create(
			catalogs.species(&"mew"), int(spec.level), catalogs, ProgressionRuleset.new(), rng,
			{"instance_id": &"fighter", "nature_id": &"hardy", "moves": ["growl"]})
		check(mode + " Exp Share participant real", other != null)
		if other == null: return
		var fighting_xp: int = other.experience
		var fight_events: Array = ProgressionSystem.reconcile_battle_result(
			[other], _held05_outcome(), catalogs, ProgressionRuleset.new())
		check(mode + " Exp Share explicitly missing XP to nonparticipant",
			saved.experience == idle_xp and _held05_xp_events(fight_events, saved.instance_id) == 0
			and other.experience == fighting_xp + 71
			and bool(spec.expected_no_distribution))
		check(mode + " Exp Share is only equipable, not yet distributive",
			saved.held_item_id == &"exp_share" and owner2.inventory.quantity(id) == 1)
	var state_after: Dictionary = _owner_data(owner2)
	var result_after: LoadResult = SaveGameRepository.new().decode_snapshot(state_after)
	check(mode + " held05 SaveV2 survives progression and changes", result_after.ok)
	if result_after.ok:
		var owner3 := PlayerCollection.new()
		owner3.party = result_after.party
		owner3.storage = result_after.storage
		owner3.inventory = result_after.inventory
		var after_creature: CreatureInstance = owner3.owned_creature(&"own")
		check(mode + " held05 post-action persistent owner/held/EXP",
			after_creature != null
			and after_creature.experience == saved.experience
			and after_creature.held_item_id == saved.held_item_id
			and owner3.inventory.quantity(id) == owner2.inventory.quantity(id)
			and owner3.location_of(&"own") == owner2.location_of(&"own"))
