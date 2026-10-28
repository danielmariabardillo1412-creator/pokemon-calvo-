extends SceneTree

const Medicine = preload("res://modules/inventory/battle_medicine_profile.gd")
const OUT := "res://.godot/item_audit_v1/"


func _initialize() -> void: call_deferred("_run")


func _run() -> void:
	var catalog := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var medicine: Dictionary = Medicine.items()
	var balls := CaptureRuleset.new().BALLS.keys()
	var evolution: Array = []
	for id: StringName in catalog.species_catalog.all_ids():
		var species := catalog.species(id)
		for record: EvolutionRecord in species.evolutions:
			if record.item_id == &"": continue
			evolution.append({"source": String(id), "target": String(record.species_id), "item_id": String(record.item_id), "trigger": String(record.trigger),
				"conditions": record.conditions, "classification": EvolutionSystem.classify_record(record, catalog, id)})
	var prototypes := {}
	for row: Array in [["mew", 50, "hardy"], ["gengar", 50, "hardy"], ["gyarados", 50, "hardy"], ["mew_100", 100, "hardy"], ["mew_modest", 50, "modest"]]:
		var rng := RandomNumberGenerator.new(); rng.seed = 8
		var c := CreatureFactory.create(catalog.species(&"mew" if String(row[0]).begins_with("mew_") else StringName(row[0])), row[1], catalog, ProgressionRuleset.new(), rng,
			{"instance_id": StringName(row[0]), "moves": ["tackle", "protect"], "nature_id": StringName(row[2])})
		c.ability_id = &""; prototypes[row[0]] = c.to_dict()
	var p := FileAccess.open(OUT + "prototypes.json", FileAccess.WRITE); p.store_string(JSON.stringify(prototypes)); p.close()
	var file := FileAccess.open(OUT + "godot_inventory.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"canonical_items": catalog.item_catalog.size(), "medicine": medicine, "capture_balls": balls, "evolution_references": evolution,
		"scope": "Declared capability/classification, not an end-to-end item-use certification."}, "  ")); file.close()
	print("ITEM_GODOT_INVENTORY items=", catalog.item_catalog.size(), " medicine=", medicine.size(), " balls=", balls.size(), " evolution_references=", evolution.size()); quit()
