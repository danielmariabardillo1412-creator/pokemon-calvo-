extends "res://tests/gameplay/item_automation_v28.gd"

# Staging-only deterministic held-item negative tests. Does not copy old W01 runners.
const HeldService = preload("res://modules/inventory/field_item_service.gd")
var neg_checked: int = 0

func _initialize() -> void:
	capture = false
	call_deferred("_run_negative")
	create_timer(180.0).timeout.connect(func():
		if not done:
			push_error("W01 V4 held negative gate timeout")
			quit(2))

func _verify(label: String, valid: bool) -> void:
	neg_checked += 1
	check(label, valid)

func _save_and_load(owner: PlayerCollection, name: String) -> PlayerCollection:
	var expected := _owner_data(owner)
	var repository := SaveGameRepository.new()
	var target := "user://w01_v4_neg_" + name + ".json"
	var saved: SaveResult = repository.save_collection(target, owner)
	_verify(name + " SaveV2 writes", saved.ok)
	if not saved.ok:
		return null
	var loaded: LoadResult = repository.load(target)
	_verify(name + " SaveV2 reads", loaded.ok)
	if not loaded.ok:
		return null
	var copy := PlayerCollection.new()
	copy.party = loaded.party
	copy.storage = loaded.storage
	copy.inventory = loaded.inventory
	_verify(name + " SaveV2 state roundtrip", _owner_data(copy) == expected)
	return copy

func _run_negative() -> void:
	current_case = "W01_V4_HELD_NEG"
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	_verify("regional variants", Variants.apply(catalogs))
	var owner := PlayerCollection.new()
	_verify("party owns both creatures",
		owner.party.add_creature(_mon(&"mew", 100, &"own", ["tackle"]))
		and owner.party.add_creature(_mon(&"mew", 100, &"reserve", ["tackle"])))
	_verify("stock normal gem", owner.inventory.add(&"normal_gem", 1))
	_verify("stock fire gem", owner.inventory.add(&"fire_gem", 1))
	var service := HeldService.new()
	_verify("service configures", service.configure(owner, catalogs, func(): return true))
	_verify("gem support", service.holdable(&"normal_gem") and service.holdable(&"fire_gem"))
	_verify("equip first gem", service.equip(&"normal_gem", &"own").get("accepted", false))
	_verify("first gem moves from bag to exact holder",
		owner.inventory.quantity(&"normal_gem") == 0
		and owner.owned_creature(&"own").held_item_id == &"normal_gem"
		and owner.owned_creature(&"reserve").held_item_id == &"")
	var baseline := _owner_data(owner)
	_verify("duplicate equip denied", not service.equip(&"normal_gem", &"own").get("accepted", false))
	_verify("duplicate denial is transactional", _owner_data(owner) == baseline)
	_verify("missing stock to reserve denied", not service.equip(&"normal_gem", &"reserve").get("accepted", false))
	_verify("reserve denial is transactional", _owner_data(owner) == baseline)
	_verify("foreign creature denied", not service.equip(&"fire_gem", &"foreign").get("accepted", false))
	_verify("foreign denial is transactional", _owner_data(owner) == baseline)
	_verify("replace first with second", service.equip(&"fire_gem", &"own").get("accepted", false))
	_verify("replacement swaps exactly one unit",
		owner.inventory.quantity(&"normal_gem") == 1
		and owner.inventory.quantity(&"fire_gem") == 0
		and owner.owned_creature(&"own").held_item_id == &"fire_gem")
	var restored := _save_and_load(owner, "replacement")
	if restored != null:
		var stable := _owner_data(restored)
		var rebound := HeldService.new()
		_verify("rebind service on loaded SaveV2", rebound.configure(restored, catalogs, func(): return true))
		_verify("save keeps reserve empty and holder exact",
			restored.owned_creature(&"own").held_item_id == &"fire_gem"
			and restored.owned_creature(&"reserve").held_item_id == &""
			and restored.inventory.quantity(&"normal_gem") == 1)
		_verify("loaded duplicate denied", not rebound.equip(&"fire_gem", &"own").get("accepted", false))
		_verify("loaded duplicate keeps SaveV2 owner stable", _owner_data(restored) == stable)
		_verify("unequip returns only real held unit", rebound.unequip(&"own").get("accepted", false))
		_verify("after unequip physical counts remain exact",
			restored.inventory.quantity(&"normal_gem") == 1
			and restored.inventory.quantity(&"fire_gem") == 1
			and restored.owned_creature(&"own").held_item_id == &"")
		_verify("repeat unequip rejected", not rebound.unequip(&"own").get("accepted", false))
		_verify("final bag persists", _save_and_load(restored, "final") != null)
	done = true
	if errors.is_empty() and neg_checked >= 24:
		print("W01_V4_GEM_NEGATIVE PASS checks=", neg_checked, " errors=0")
		quit(0)
	else:
		print("W01_V4_GEM_NEGATIVE FAIL checks=", neg_checked, " errors=", errors.size())
		quit(1)
