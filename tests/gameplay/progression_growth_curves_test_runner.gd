extends SceneTree

const REFERENCE := "res://tests/fixtures/progression_growth_curves/reference_contract.json"
const OUT := "res://.godot/progression_growth_curves/"
var checks := 0
var errors: Array[String] = []
var rows: Array = []

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		if errors.size() < 12: push_error(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))
	for curve: String in reference.tables:
		var values: Array = reference.tables[curve].levels_1_to_100
		var names: Array = [curve]
		if reference.aliases.has(curve): names.append(reference.aliases[curve])
		for name: String in names:
			for level in range(1, 101):
				var expected := int(values[level-1])
				check("XP table %s/%d" % [name, level], ProgressionRuleset.experience_for_level(name, level) == expected)
				check("XP inverse threshold %s/%d" % [name, level], ProgressionRuleset.level_for_experience(name, expected) == level)
				if level > 1:
					check("XP before threshold %s/%d" % [name, level], ProgressionRuleset.level_for_experience(name, expected-1) == level-1)
				if level < 100:
					check("XP upper boundary %s/%d" % [name, level], ProgressionRuleset.level_for_experience(name, int(values[level])-1) == level)
					check("XP needed next %s/%d" % [name, level], ProgressionRuleset.experience_to_next_level(name, level) == int(values[level])-expected)
			check("XP clamp low " + name, ProgressionRuleset.experience_for_level(name, 0) == 0)
			check("XP clamp high " + name, ProgressionRuleset.experience_for_level(name, 101) == int(values[99]) and ProgressionRuleset.level_for_experience(name, int(values[99])+99999) == 100)
			rows.append({"name": name, "max_exp": values[99]})
	check("unknown curve fallback preserved", ProgressionRuleset.experience_for_level("unknown", 100) == 1000000)
	var data := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json")))
	var catalogs := data.to_definition_catalog()
	var affected := 0
	for id: StringName in catalogs.species_catalog.all_ids():
		var species := catalogs.species(id)
		if not reference.aliases.has(species.growth_rate): continue
		affected += 1
		var values: Array = reference.tables[species.growth_rate].levels_1_to_100
		var rng := RandomNumberGenerator.new(); rng.seed = 411
		var c := CreatureFactory.create(species, 49, catalogs, ProgressionRuleset.new(), rng, {"instance_id": &"growth_fixture", "moves": ["tackle"], "nature_id": &"hardy"})
		check("factory uses source growth " + String(id), c.experience == int(values[48]))
		var amount := int(values[49])-int(values[48])
		var events := ProgressionSystem.gain_experience(c, amount, species, catalogs, ProgressionRuleset.new())
		check("gain uses source curve " + String(id), c.level == 50 and c.experience == int(values[49]))
		check("level event emitted " + String(id), events.any(func(e): return e.kind == ProgressionEvent.LEVEL_UP and e.data.level == 50))
		var restored := CreatureInstance.from_dict(c.to_dict())
		check("XP serialized unchanged " + String(id), restored.experience == c.experience and restored.level == c.level)
		var before := c.experience
		var outcome := BattleOutcome.new(); outcome.defeated = [{"base_experience": 100, "level": 7}]
		var expected_gain := ProgressionRuleset.experience_for_defeat(100, 7, 1)
		ProgressionSystem.reconcile_battle_result([c], outcome, catalogs, ProgressionRuleset.new())
		check("battle award uses same XP base " + String(id), c.experience == before+expected_gain and c.level == ProgressionRuleset.level_for_experience(species.growth_rate, c.experience))
	check("affected canonical species counted", affected == 43)
	DirAccess.make_dir_recursive_absolute(OUT)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"curves": rows, "affected_species": affected, "reference_sha256": FileAccess.get_sha256(REFERENCE)}
	var file := FileAccess.open(OUT+"results.json", FileAccess.WRITE); file.store_string(JSON.stringify(report, "  ")); file.close()
	print("PROGRESSION_GROWTH_CURVES ", report.status, " checks=", checks, " failures=", errors.size())
	quit(0 if errors.is_empty() else 1)
