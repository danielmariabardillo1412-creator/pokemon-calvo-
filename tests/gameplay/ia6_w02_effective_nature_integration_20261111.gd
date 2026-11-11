extends SceneTree

# IA6: isolated integration gate for W02 effective nature across growth,
# mochi, evolution, and real owned SaveV2. No mocked inventory operations.
const FieldGrowth = preload("res://modules/inventory/field_growth_effects.gd")
const FieldMochi = preload("res://modules/inventory/field_mochi_effects.gd")
const FieldMint = preload("res://modules/inventory/field_mint_effects.gd")
const FieldService = preload("res://modules/inventory/field_item_service.gd")
var checks: int = 0
var errors: Array[String] = []
var complete: bool = false


func _initialize() -> void:
	call_deferred("_run")
	create_timer(240.0).timeout.connect(func():
		if not complete:
			push_error("IA6_W02_SEAMS timeout")
			quit(2))


func ck(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		errors.append(label)
		push_error("IA6_W02_SEAMS_FAIL " + label)


func new_owner(catalogs: DefinitionCatalog, species_id: StringName, level: int,
		name: StringName = &"ia6_w02") -> PlayerCollection:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1412
	var creature: CreatureInstance = CreatureFactory.create(
		catalogs.species(species_id), level, catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": name, "nature_id": &"hardy", "moves": ["tackle", "growl"]})
	ck("factory_" + String(species_id), creature != null)
	var owner := PlayerCollection.new()
	if creature != null:
		ck("party_" + String(species_id), owner.party.add_creature(creature))
	return owner


func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/normalized/pokemon_api.json"))
	ck("catalog_json", raw is Dictionary)
	if not raw is Dictionary:
		_finish()
		return
	var catalogs: DefinitionCatalog = GameData.from_dict(raw).to_definition_catalog()
	ck("eevee_available", catalogs.species(&"eevee") != null)
	ck("flareon_available", catalogs.species(&"flareon") != null)
	ck("mew_available", catalogs.species(&"mew") != null)
	if catalogs.species(&"eevee") == null or catalogs.species(&"flareon") == null or catalogs.species(&"mew") == null:
		_finish()
		return

	# PARTY: effective nature must survive W02 mint, Mochi, stone evolution,
	# source isolation, and real SaveV2 decode.
	var owner := new_owner(catalogs, &"eevee", 30)
	ck("eevee_stock_mint", owner.inventory.add(&"adamant_mint", 1))
	ck("eevee_stock_mochi", owner.inventory.add(&"muscle_mochi", 1))
	ck("eevee_stock_stone", owner.inventory.add(&"fire_stone", 1))
	var service := FieldService.new()
	ck("eevee_service", service.configure(owner, catalogs, func(): return true))
	var origin: CreatureInstance = owner.owned_creature(&"ia6_w02")
	if origin == null:
		_finish()
		return
	var old_serial: Dictionary = origin.to_dict()
	ck("adamant_mint_registered", FieldMint.supports(&"adamant_mint"))
	var mint: Dictionary = service.use_item(&"adamant_mint", &"ia6_w02")
	var minted: CreatureInstance = owner.owned_creature(&"ia6_w02")
	ck("mint_accepted", bool(mint.get("accepted", false)))
	ck("mint_effective_original_preserved", minted != null
		and minted.nature_id == &"hardy" and minted.effective_nature_id == &"adamant"
		and origin.to_dict() == old_serial)
	if minted == null:
		_finish()
		return
	ck("mint_expected_stats", minted.stats.to_dict() == StatCalculator.compute(
		catalogs.species(&"eevee").base_stat_block(), minted.ivs, minted.evs,
		&"adamant", minted.level).to_dict())
	ck("mint_one_stock_spent", owner.inventory.quantity(&"adamant_mint") == 0)
	ck("minted_growth_valid", FieldGrowth.validation_error(minted, catalogs) == "")
	ck("minted_mochi_valid", FieldMochi.validation_error(minted, -1, catalogs) == "")

	var muscle: Dictionary = service.use_item(&"muscle_mochi", &"ia6_w02")
	var trained: CreatureInstance = owner.owned_creature(&"ia6_w02")
	ck("mochi_accepted", bool(muscle.get("accepted", false)))
	ck("mochi_keeps_natures", trained != null and trained.nature_id == &"hardy"
		and trained.effective_nature_id == &"adamant")
	if trained == null:
		_finish()
		return
	ck("mochi_new_evs_and_stats", int(trained.evs.get("attack", 0)) > int(minted.evs.get("attack", 0))
		and trained.stats.to_dict() == StatCalculator.compute(
		catalogs.species(&"eevee").base_stat_block(), trained.ivs, trained.evs,
		&"adamant", trained.level).to_dict())
	ck("mochi_stock_spent", owner.inventory.quantity(&"muscle_mochi") == 0)
	var before_evolution: Dictionary = trained.to_dict()
	var evolve: Dictionary = service.evolve(&"fire_stone", &"ia6_w02", &"flareon")
	var evolved: CreatureInstance = owner.owned_creature(&"ia6_w02")
	ck("fire_stone_accepted", bool(evolve.get("accepted", false))
		and owner.inventory.quantity(&"fire_stone") == 0)
	ck("evolution_preserves_identity_and_original", evolved != null
		and evolved.instance_id == &"ia6_w02"
		and evolved.species_id == &"flareon"
		and evolved.nature_id == &"hardy" and evolved.effective_nature_id == &"adamant"
		and trained.to_dict() == before_evolution)
	if evolved == null:
		_finish()
		return
	ck("evolution_uses_effective_stats", evolved.stats.to_dict() == StatCalculator.compute(
		catalogs.species(&"flareon").base_stat_block(), evolved.ivs, evolved.evs,
		&"adamant", evolved.level).to_dict())
	ck("evolved_growth_valid", FieldGrowth.validation_error(evolved, catalogs) == "")
	ck("evolved_mochi_valid", FieldMochi.validation_error(evolved, -1, catalogs) == "")
	_verify_save(owner, &"ia6_w02", &"flareon", &"adamant", "mint_mochi_evolve")

	# Independent growth on a minted non-evolving species avoids evolution
	# prompts, and checks the native service's atomic inventory transaction.
	var grow_owner := new_owner(catalogs, &"mew", 40, &"ia6_growth")
	ck("growth_mint_stock", grow_owner.inventory.add(&"modest_mint", 1))
	ck("growth_candy_stock", grow_owner.inventory.add(&"rare_candy", 1))
	var grow_service := FieldService.new()
	ck("growth_service", grow_service.configure(grow_owner, catalogs, func(): return true))
	var grow_mint: Dictionary = grow_service.use_item(&"modest_mint", &"ia6_growth")
	var gm: CreatureInstance = grow_owner.owned_creature(&"ia6_growth")
	ck("growth_mint_accepted", bool(grow_mint.get("accepted", false))
		and gm != null and gm.nature_id == &"hardy" and gm.effective_nature_id == &"modest")
	if gm != null:
		ck("growth_valid_pre", FieldGrowth.validation_error(gm, catalogs) == "")
		var original_level: int = gm.level
		var original_experience: int = gm.experience
		var candy: Dictionary = grow_service.use_growth_item(&"rare_candy", &"ia6_growth")
		var grown: CreatureInstance = grow_owner.owned_creature(&"ia6_growth")
		ck("growth_accepted", bool(candy.get("accepted", false)))
		ck("growth_level_one_stock", grown != null and grown.level == original_level + 1
			and grown.experience > original_experience
			and grow_owner.inventory.quantity(&"rare_candy") == 0)
		if grown != null:
			ck("growth_original_effective_preserved", grown.nature_id == &"hardy"
				and grown.effective_nature_id == &"modest")
			ck("growth_effective_stat_oracle", grown.stats.to_dict() == StatCalculator.compute(
				catalogs.species(&"mew").base_stat_block(), grown.ivs, grown.evs,
				&"modest", grown.level).to_dict())
			_verify_save(grow_owner, &"ia6_growth", &"mew", &"modest", "mint_rare_candy")
	_finish()


func _verify_save(owner: PlayerCollection, id: StringName, species: StringName,
		effective: StringName, description: String) -> void:
	var saved: Dictionary = SaveGameData.build(owner.party, owner.storage, owner.inventory).to_dict()
	var decoded: LoadResult = SaveGameRepository.new().decode_snapshot(saved)
	ck(description + "_savev2_decode", decoded.ok)
	if not decoded.ok: return
	var reconstructed := PlayerCollection.new()
	reconstructed.party = decoded.party
	reconstructed.storage = decoded.storage
	reconstructed.inventory = decoded.inventory
	var original: CreatureInstance = owner.owned_creature(id)
	var restored: CreatureInstance = reconstructed.owned_creature(id)
	ck(description + "_identity_and_stats", original != null and restored != null
		and restored.instance_id == id and restored.species_id == species
		and restored.nature_id == &"hardy" and restored.effective_nature_id == effective
		and restored.stats.to_dict() == original.stats.to_dict()
		and restored.current_hp == original.current_hp)
	ck(description + "_inventory_serialization", reconstructed.inventory.to_dict() == owner.inventory.to_dict())


func _finish() -> void:
	complete = true
	if errors.is_empty():
		print("IA6_W02_SEAMS PASS checks=", checks,
			" features=mint,mochi,evolution,growth,savev2")
		quit(0)
	else:
		print("IA6_W02_SEAMS FAIL checks=", checks, " errors=", JSON.stringify(errors))
		quit(1)
