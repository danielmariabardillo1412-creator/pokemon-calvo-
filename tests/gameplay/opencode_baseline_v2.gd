extends SceneTree

# O100 immutable baseline: pre-implementation application-level item transfer,
# bag consumption and a real FieldNativeSave envelope. This runner only reads
# existing services; it must not be adapted to future O110/O120 behavior.

const FieldService = preload("res://modules/inventory/field_item_service.gd")
const FieldSave = preload("res://modules/save/field_native_save.gd")
const DIR := "res://.godot/opencode_items_v2/baseline_fixtures/"
const DEST := DIR + "godot_baseline.json"
const SAVE := DIR + "field_save.json"

var catalogs: DefinitionCatalog
var checks := 0
var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, valid: bool) -> void:
	checks += 1
	if not valid:
		errors.append(label)
		push_error(label)


func creature(id: String, species: String = "mew", level: int = 50, moves: Array = [&"tackle", &"reflect"]) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var result := CreatureFactory.create(catalogs.species(StringName(species)), level, catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves})
	result.ability_id = &""
	return result


func snapshot(player: PlayerCollection) -> Dictionary:
	var creatures: Array = []
	for creature_row: CreatureInstance in player.party.get_creatures():
		creatures.append({"instance_id": String(creature_row.instance_id), "held_item_id": String(creature_row.held_item_id),
			"held_item_consumed": creature_row.held_item_consumed, "current_hp": creature_row.current_hp})
	return JSON.parse_string(JSON.stringify({"inventory": player.inventory.to_dict(), "creatures": creatures}))


func same(left: Variant, right: Variant) -> bool:
	return JSON.stringify(left) == JSON.stringify(right)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	if FileAccess.file_exists(DEST):
		errors.append("baseline fixture already exists; never reseal it")
		_finish({})
		return
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("canonical catalog loads", catalogs != null and catalogs.item(&"oran_berry") != null)
	var player := PlayerCollection.new()
	var owner := creature("baseline_owner")
	owner.current_hp = 10
	player.party.add_creature(owner)
	player.inventory.add(&"oran_berry", 2)
	player.inventory.add(&"potion", 2)
	player.inventory.add(&"x_attack", 1)
	var service := FieldService.new()
	check("field item service binds", service.configure(player, catalogs, func() -> bool: return true))

	var transfer_before := snapshot(player)
	var equip: Dictionary = service.equip(&"oran_berry", &"baseline_owner")
	var transfer_equipped := snapshot(player)
	check("equip accepts a reviewed holdable", equip.get("accepted", false) and equip.get("status", "") == "APPLIED")
	check("equip moves one unit from bag to holder", player.inventory.quantity(&"oran_berry") == 1 and player.party.get_creature(&"baseline_owner").held_item_id == &"oran_berry")
	var unequip: Dictionary = service.unequip(&"baseline_owner")
	var transfer_after := snapshot(player)
	check("unequip returns the same unit", unequip.get("accepted", false) and player.inventory.quantity(&"oran_berry") == 2 and player.party.get_creature(&"baseline_owner").held_item_id == &"")
	check("transfer snapshots differ only by ownership", not same(transfer_before, transfer_equipped) and not same(transfer_equipped, transfer_after))
	check("transfer round-trip preserves the bag", same(transfer_before, transfer_after))

	var consume_before := snapshot(player)
	var used: Dictionary = service.use_item(&"oran_berry", &"baseline_owner")
	var consume_after := snapshot(player)
	var after_owner: CreatureInstance = player.party.get_creature(&"baseline_owner")
	check("field recovery consumes one unit", used.get("accepted", false) and player.inventory.quantity(&"oran_berry") == 1)
	check("field recovery heals the staged owner", after_owner != null and after_owner.current_hp == 20)
	check("consumption changes the physical bag", not same(consume_before, consume_after))

	var trainer_creature := creature("baseline_trainer")
	var trainer := TrainerCampaignRosterOwner.new()
	var trainer_roster: Array[CreatureInstance] = [trainer_creature]
	check("trainer roster binds", trainer.configure(&"baseline_trainer_owner", trainer_roster))
	var world := {"zone_id": "baseline_route", "steps": 7, "rng_state": 123456}
	var save := FieldSave.new()
	check("field save writes atomically", save.write(SAVE, player, world, trainer, {}, {}, catalogs))
	check("field save file exists", FileAccess.file_exists(SAVE))
	var loaded: Dictionary = save.read(SAVE, catalogs)
	check("field save decodes", loaded.get("ok", false))
	var restored_inventory := {}
	if loaded.get("ok", false):
		restored_inventory = loaded.collection.inventory.to_dict()
	check("field save preserves physical bag", loaded.get("ok", false) and JSON.stringify(restored_inventory) == JSON.stringify(player.inventory.to_dict()))
	check("field save preserves current HP", loaded.get("ok", false) and loaded.collection.party.get_creature(&"baseline_owner").current_hp == 20)
	check("field save preserves world payload", loaded.get("ok", false) and same(loaded.world, JSON.parse_string(JSON.stringify(world))))

	var report := {
		"schema_version": 1,
		"phase": "OPENCODE_ITEM_CLOSURE_V2_O100_BASELINE",
		"description": "Pre-implementation application-level transfer, consumption and field-save fixture. Never regenerate after O110/O120 changes.",
		"source_sha256": {
			"field_item_service": FileAccess.get_sha256("res://modules/inventory/field_item_service.gd"),
			"field_native_save": FileAccess.get_sha256("res://modules/save/field_native_save.gd"),
			"save_game_repository": FileAccess.get_sha256("res://modules/save/save_game_repository.gd"),
		},
		"status": "PASS" if errors.is_empty() else "FAIL",
		"checks": checks,
		"errors": errors,
		"transfer": {"before": transfer_before, "equipped": transfer_equipped, "after": transfer_after},
		"consumption": {"before": consume_before, "after": consume_after, "result": used},
		"field_save": {"path": SAVE, "sha256": FileAccess.get_sha256(SAVE), "decoded": loaded.get("ok", false),
			"world": loaded.get("world", {}), "inventory": restored_inventory},
	}
	_finish(report)


func _finish(report: Dictionary) -> void:
	if not report.is_empty():
		report["status"] = "PASS" if errors.is_empty() else "FAIL"
		report["checks"] = checks
		report["errors"] = errors
		var file := FileAccess.open(DEST, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(report, "  ", false) + "\n")
			file.close()
	print("OPENCODE_BASELINE_GODOT ", report.get("status", "FAIL"), " checks=", checks)
	for error: String in errors:
		printerr(error)
	quit(0 if errors.is_empty() else 1)
