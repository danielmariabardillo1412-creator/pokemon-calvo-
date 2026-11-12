extends "res://tests/gameplay/w01_continuous_v4_gem_negative.gd"

# Isolated legacy V1 migration test. No historical W01 test suite copied.
func _initialize() -> void:
	capture = false
	call_deferred("_run_legacy")
	create_timer(180.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 legacy migration timeout")
			quit(2))

func _run_legacy() -> void:
	current_case = "W01_V4_LEGACY_GEM"
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	_verify("regional overlay available", Variants.apply(catalogs))
	var owner := PlayerCollection.new()
	_verify("legacy original creature is owned",
		owner.party.add_creature(_mon(&"mew", 100, &"own", ["moonblast"])))
	_verify("legacy consumed gem starts in actual inventory",
		owner.inventory.add(&"fairy_gem", 1))
	var service := HeldService.new()
	_verify("legacy original service configured",
		service.configure(owner, catalogs, func(): return true))
	_verify("legacy Fairy Gem real equip",
		service.equip(&"fairy_gem", &"own").get("accepted", false))
	_verify("legacy no extra bag stock",
		owner.inventory.quantity(&"fairy_gem") == 0
		and owner.owned_creature(&"own").held_item_id == &"fairy_gem")
	# A consumed persisted record is deliberately modeled as legacy input,
	# not claimed to be a real battle. Native consumption is in separate CI.
	owner.owned_creature(&"own").held_item_consumed = true
	var legacy: Dictionary = SaveGameData.build(owner.party, owner.storage, owner.inventory).to_dict()
	legacy["schema_version"] = 1
	legacy["format_id"] = "calvo_save_v1"
	legacy.erase("inventory")
	var frozen: Dictionary = legacy.duplicate(true)
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(legacy)
	_verify("V1 legacy decode accepted and original immutable",
		decoded.ok and legacy == frozen)
	if decoded.ok:
		var migrated := PlayerCollection.new()
		migrated.party = decoded.party
		migrated.storage = decoded.storage
		migrated.inventory = decoded.inventory
		_verify("no synthesized Fairy Gem after V1 migration",
			migrated.inventory.quantity(&"fairy_gem") == 0)
		_verify("migrated spent identity preserved",
			migrated.owned_creature(&"own").held_item_id == &"fairy_gem"
			and migrated.owned_creature(&"own").held_item_consumed)
		var rebound := HeldService.new()
		_verify("service binds migrated owner",
			rebound.configure(migrated, catalogs, func(): return true))
		_verify("spent gem cannot be refunded from migrated owner",
			rebound.unequip(&"own").get("accepted", false)
			and migrated.inventory.quantity(&"fairy_gem") == 0
			and migrated.owned_creature(&"own").held_item_id == &"")
		var saved := _save_and_load(migrated, "legacy_fairy_rewritten_v2")
		_verify("migrated state survives SaveV2 without phantom gem",
			saved != null
			and saved.inventory.quantity(&"fairy_gem") == 0
			and saved.owned_creature(&"own").held_item_id == &"")
		if saved != null:
			var final_service := HeldService.new()
			_verify("service rebind after V2 migration", final_service.configure(saved, catalogs, func(): return true))
			var state_before: Dictionary = _owner_data(saved)
			_verify("no stock to re-equip consumed Fairy Gem",
				not final_service.equip(&"fairy_gem", &"own").get("accepted", false))
			_verify("failed re-equip leaves migrated V2 unchanged",
				_owner_data(saved) == state_before)
	done = true
	if errors.is_empty() and neg_checked >= 16:
		print("W01_V4_GEM_LEGACY PASS checks=", neg_checked, " errors=0")
		quit(0)
	else:
		print("W01_V4_GEM_LEGACY FAIL checks=", neg_checked, " errors=", errors.size())
		quit(1)
