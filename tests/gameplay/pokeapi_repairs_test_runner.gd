extends SceneTree

var checks := 0
var errors: Array[String] = []
var catalog: DefinitionCatalog

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		if errors.size() < 12: push_error(label)

func _initialize() -> void:
	call_deferred("_run")

func _targets(species: CreatureSpecies, context: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for row: EvolutionRecord in EvolutionSystem.evolution_candidates(species, context, catalog):
		result.append(String(row.species_id))
	return result

func _run() -> void:
	var data := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json")))
	catalog = data.to_definition_catalog()
	var species := catalog.species(&"tyrogue")
	for level: int in [19, 20, 21, 100]:
		for attack: int in [10, 11, 12]:
			var expected: Array[String] = []
			if level >= 20:
				expected.append("hitmonchan" if attack < 11 else "hitmontop" if attack == 11 else "hitmonlee")
			var context := {"level": level, "attack": attack, "defense": 11}
			var frozen := JSON.stringify(species.to_dict()) + JSON.stringify(context)
			check("relation %d/%d" % [level, attack], _targets(species, context) == expected)
			check("pure eligibility %d/%d" % [level, attack], frozen == JSON.stringify(species.to_dict()) + JSON.stringify(context))
	for context: Dictionary in [{"level": 20}, {"level": 20, "attack": 11},
		{"level": 20, "attack": true, "defense": 11}, {"level": 20, "attack": -1, "defense": 11},
		{"level": 20, "attack": 11.5, "defense": 11}, {"level": 20, "attack": 0, "defense": 0}]:
		check("missing or invalid stats fail closed " + str(context), _targets(species, context).is_empty())
	var restored := CreatureSpecies.from_dict(JSON.parse_string(JSON.stringify(species.to_dict())))
	check("condition zero survives JSON", _targets(restored, {"level": 20, "attack": 11, "defense": 11}) == ["hitmontop"])
	for relation: int in [-1, 0, 1]:
		var record := EvolutionRecord.new(&"hitmontop", 20, &"level_up", &"", &"", true, {"relative_physical_stats": relation})
		check("supported stat relation " + str(relation), EvolutionSystem.classify_record(record, catalog, &"tyrogue") == EvolutionSystem.RUNTIME_SUPPORTED)
	for conditions: Dictionary in [{"relative_physical_stats": 0, "time_of_day": "night"},
		{"relative_physical_stats": 2}, {"relative_physical_stats": false}, {"relative_physical_stats": 0.5},
		{"relative_physical_stats": "0"}, {"base_form": "other", "relative_physical_stats": 0}]:
		var invalid := CreatureSpecies.new(); invalid.id = &"tyrogue"
		invalid.evolutions = [EvolutionRecord.new(&"hitmontop", 20, &"level_up", &"", &"", true, conditions)]
		check("unsupported requirements not bypassed " + str(conditions), _targets(invalid, {"level": 100, "attack": 11, "defense": 11}).is_empty())
	for relation: int in [-1, 0, 1]:
		var rng := RandomNumberGenerator.new(); rng.seed = 17
		var creature := CreatureFactory.create(species, 19, catalog, ProgressionRuleset.new(), rng,
			{"instance_id": &"evolution_fixture", "nature_id": &"hardy", "moves": ["tackle"]})
		for key: String in ProgressionRuleset.STAT_KEYS: creature.ivs[key] = 0; creature.evs[key] = 0
		creature.ivs["attack"] = 31 if relation > 0 else 0
		creature.ivs["defense"] = 31 if relation < 0 else 0
		creature.recalculate_stats(species, ProgressionRuleset.new())
		creature.experience = ProgressionRuleset.experience_for_level(species.growth_rate, 19)
		var amount := ProgressionRuleset.experience_for_level(species.growth_rate, 20) - creature.experience
		var events := ProgressionSystem.gain_experience(creature, amount, species, catalog, ProgressionRuleset.new())
		var targets: Array[String] = []
		var event: ProgressionEvent
		for e: ProgressionEvent in events:
			if e.kind == ProgressionEvent.EVOLUTION_AVAILABLE:
				targets.append(String(e.data.species_id)); event = e
		var expected := "hitmonchan" if relation < 0 else "hitmontop" if relation == 0 else "hitmonlee"
		check("progression offers one correct branch " + expected, targets == [expected])
		check("progression reaches level 20 " + expected, creature.level == 20)
		if event != null:
			var collection := PlayerCollection.new()
			collection.party.add_creature(creature)
			var session := WildAdventureSession.new(collection, catalog)
			var forged := ProgressionEvent.new(ProgressionEvent.EVOLUTION_AVAILABLE, creature.instance_id,
				{"species_id": "hitmonlee" if expected != "hitmonlee" else "hitmontop"})
			check("owned session rejects wrong stat branch " + expected, session.apply_evolution_event(forged) == null)
			var evolved := session.apply_evolution_event(event)
			check("owned session accepts actual branch " + expected, evolved != null and String(evolved.species_id) == expected)
			check("owned replacement preserves identity " + expected, evolved != null and evolved.instance_id == creature.instance_id and collection.owned_creature(creature.instance_id) == evolved)
	check("Haunter remains trade-only", _targets(catalog.species(&"haunter"), {"level": 100}).is_empty())
	check("Haunter permits trade", _targets(catalog.species(&"haunter"), {"level": 10, "traded": true}) == ["gengar"])
	check("ordinary evolution still available", _targets(catalog.species(&"bulbasaur"), {"level": 16}) == ["ivysaur"])
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors}
	DirAccess.make_dir_recursive_absolute("res://.godot/pokeapi_repairs_v1")
	var file := FileAccess.open("res://.godot/pokeapi_repairs_v1/domain_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t")); file.close()
	print("POKEAPI_REPAIR_TEST ", report.status, " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
