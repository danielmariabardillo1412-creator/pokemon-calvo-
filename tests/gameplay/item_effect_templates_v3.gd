extends SceneTree


func _initialize() -> void: call_deferred("_run")


func _run() -> void:
	var catalogs := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var rows := {}
	for species_id: String in ["mew", "gengar", "scizor", "charizard", "gyarados", "blastoise", "dragonite", "snorlax", "clefable", "pikachu", "venusaur", "garchomp", "chansey", "blissey", "clamperl", "cubone", "marowak", "ditto", "farfetchd", "latias", "latios", "dialga", "palkia", "giratina", "great_tusk", "iron_hands", "silvally", "genesect", "ogerpon", "zacian", "zamazenta"]:
		var rng := RandomNumberGenerator.new(); rng.seed = 37
		var creature := CreatureFactory.create(catalogs.species(StringName(species_id)), 100, catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(species_id), "moves": ["tackle", "reflect"], "nature_id": &"hardy"})
		creature.ability_id = &"" # Deliberate isolated item fixture, not a legal team-generation claim.
		rows[species_id] = creature.to_dict()
	for key: String in ["mew_50", "pikachu_1", "mew_adamant", "mew_brave", "mew_lonely", "mew_naughty"]:
		var parts := key.split("_")
		var rng := RandomNumberGenerator.new(); rng.seed = 37
		var level := int(parts[1]) if parts[1].is_valid_int() else 100
		var nature := "hardy" if parts[1].is_valid_int() else parts[1]
		var creature := CreatureFactory.create(catalogs.species(StringName(parts[0])), level, catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(key), "moves": ["tackle", "reflect"], "nature_id": StringName(nature)})
		creature.ability_id = &""
		rows[key] = creature.to_dict()
	DirAccess.make_dir_recursive_absolute("res://.godot/item_verification_v3/")
	var file := FileAccess.open("res://.godot/item_verification_v3/prototypes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows)); file.close()
	print("ITEM_EFFECT_TEMPLATES_V3 ", rows.size()); quit()
