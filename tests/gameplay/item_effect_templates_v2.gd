extends SceneTree


func _initialize() -> void: call_deferred("_run")


func _run() -> void:
	var catalogs := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var rows := {}
	for species_id: String in ["mew", "gengar", "scizor", "charizard", "gyarados", "blastoise", "dragonite", "snorlax", "clefable", "pikachu", "venusaur", "garchomp"]:
		var rng := RandomNumberGenerator.new(); rng.seed = 37
		var creature := CreatureFactory.create(catalogs.species(StringName(species_id)), 100, catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(species_id), "moves": ["tackle", "reflect"], "nature_id": &"hardy"})
		creature.ability_id = &"" # Deliberate isolated item fixture, not a legal team-generation claim.
		rows[species_id] = creature.to_dict()
	DirAccess.make_dir_recursive_absolute("res://.godot/item_verification_v2/")
	var file := FileAccess.open("res://.godot/item_verification_v2/prototypes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(rows)); file.close()
	print("ITEM_EFFECT_TEMPLATES_V2 ", rows.size()); quit()
