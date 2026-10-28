extends RefCounted

## One atomic envelope: existing canonical SaveV2 + map/RNG/trainer/native battle.
## No save is published to the running campaign during decoding.
const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const FORMAT := "calvo_field_native_v1"
var serializer := SaveGameSerializer.new()
var last_error := ""


func write(path: String, collection: PlayerCollection, world: Dictionary, trainer: TrainerCampaignRosterOwner,
	clocks: Dictionary, battle: Dictionary, catalogs: DefinitionCatalog) -> bool:
	var snapshot := SaveGameData.build(collection.party, collection.storage, collection.inventory)
	if not snapshot.validate().ok: last_error = "invalid_collection"; return false
	var roster: Array = []
	for c: CreatureInstance in trainer.roster_for_battle(): roster.append(c.to_dict())
	var payload := {"collection": snapshot.to_dict(), "world": world, "trainer": {"id": String(trainer.trainer_id), "roster": roster},
		"sleep_clocks": clocks, "battle": battle, "data_sha256": FileAccess.get_sha256(Policy.DATA_PATH), "policy_sha256": FileAccess.get_sha256(Policy.CONFIG_PATH)}
	# Hash the JSON representation, including JSON's numeric normalization.
	payload = JSON.parse_string(JSON.stringify(payload))
	var envelope := {"format": FORMAT, "schema": 1, "payload": payload, "sha256": JSON.stringify(payload).sha256_text()}
	if not decode(envelope, catalogs).ok: return false
	var result := serializer.write_atomic_dictionary(path, envelope)
	last_error = result.reason
	return result.ok


func read(path: String, catalogs: DefinitionCatalog) -> Dictionary:
	last_error = ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() > 32 * 1024 * 1024: return _failed("missing_or_oversized_save")
	var envelope: Variant = JSON.parse_string(f.get_as_text()); f.close()
	return decode(envelope, catalogs)


func decode(envelope: Variant, catalogs: DefinitionCatalog) -> Dictionary:
	if not envelope is Dictionary or envelope.get("format") != FORMAT or envelope.get("schema") != 1 or not envelope.get("payload") is Dictionary: return _failed("field_save_format")
	var payload: Dictionary = envelope.payload
	if JSON.stringify(payload).sha256_text() != envelope.get("sha256"): return _failed("field_save_checksum")
	if payload.get("data_sha256") != FileAccess.get_sha256(Policy.DATA_PATH) or payload.get("policy_sha256") != FileAccess.get_sha256(Policy.CONFIG_PATH): return _failed("field_save_content_version")
	if not payload.get("collection") is Dictionary or not payload.get("world") is Dictionary or not payload.get("trainer") is Dictionary or not payload.get("sleep_clocks") is Dictionary or not payload.get("battle") is Dictionary: return _failed("field_save_shape")
	var decoded := SaveGameRepository.new().decode_snapshot(payload.collection)
	if not decoded.ok: return _failed("collection:" + decoded.reason)
	var collection := PlayerCollection.new()
	collection.party = decoded.party; collection.storage = decoded.storage; collection.inventory = decoded.inventory
	var policy := Policy.new()
	if not policy.load_local(): return _failed("content_policy")
	var ids := {}
	var owned: Array = collection.party.get_creatures() + collection.storage.get_all_creatures()
	for c: CreatureInstance in owned:
		if not _valid_creature(c, catalogs, policy): return _failed("invalid_owned_creature")
		ids[String(c.instance_id)] = true
	if ids.size() != payload.collection.creatures.size(): return _failed("unowned_creature_record")
	for item: StringName in collection.inventory.all_item_ids():
		if catalogs.item(item) == null: return _failed("unknown_inventory_item")
	if not payload.trainer.get("id") is String or not payload.trainer.get("roster") is Array: return _failed("trainer_shape")
	var roster: Array[CreatureInstance] = []
	for row: Variant in payload.trainer.roster:
		if not row is Dictionary: return _failed("trainer_shape")
		var c := CreatureInstance.from_dict(row)
		if ids.has(String(c.instance_id)) or not _valid_creature(c, catalogs, policy): return _failed("trainer_identity_or_creature")
		ids[String(c.instance_id)] = true; roster.append(c)
	var trainer := TrainerCampaignRosterOwner.new()
	if not trainer.configure(StringName(payload.trainer.id), roster): return _failed("trainer_roster")
	for c: CreatureInstance in owned + roster:
		if c.status_state.persistent_id == &"sleep" and not payload.sleep_clocks.has(String(c.instance_id)): return _failed("missing_native_sleep_clock")
	for id: String in payload.sleep_clocks:
		var c := collection.owned_creature(StringName(id))
		if c == null: c = trainer.owned_creature(StringName(id))
		var clock: Variant = payload.sleep_clocks[id]
		if c == null or c.status_state.persistent_id != &"sleep" or not clock is Dictionary or clock.get("version") != "0.10.11": return _failed("sleep_clock_ownership")
		for key: String in ["start_time", "time"]:
			if not clock.get(key) is float and not clock.get(key) is int: return _failed("sleep_clock_shape")
		if int(clock.start_time) != clock.start_time or int(clock.time) != clock.time or clock.start_time < 2 or clock.start_time > 4 or clock.time < 0 or clock.time > clock.start_time or int(clock.time) != c.status_state.turns_remaining: return _failed("sleep_clock_range")
	return {"ok": true, "collection": collection, "trainer": trainer, "world": payload.world, "clocks": payload.sleep_clocks, "battle": payload.battle}


func _valid_creature(c: CreatureInstance, catalogs: DefinitionCatalog, policy: RefCounted) -> bool:
	var species := catalogs.species(c.species_id)
	if species == null or c.level < 1 or c.level > 100 or c.moveset.is_empty() or c.moveset.size() > 4: return false
	var base := String(species.source_metadata.get("base_species_id", String(c.species_id)))
	if not policy.form_allowed(base, String(c.species_id) if base != String(c.species_id) else ""): return false
	if c.ability_id != &"" and not policy.ability_allowed(String(c.ability_id)): return false
	if c.held_item_id != &"" and catalogs.item(c.held_item_id) == null: return false
	if c.stats.to_dict() != StatCalculator.compute(species.base_stat_block(), c.ivs, c.evs, c.nature_id, c.level).to_dict(): return false
	if c.current_hp < 0 or c.current_hp > c.stats.max_hp or not c.battle_transform_original.is_empty(): return false
	if c.status_state.persistent_id not in [&"", &"burn", &"poison", &"badly_poisoned", &"paralysis", &"sleep", &"freeze"]: return false
	for slot: BattleMoveSlot in c.moveset:
		if not policy.move_learnable(String(slot.move_id)) or slot.max_pp < 1 or slot.current_pp < 0 or slot.current_pp > slot.max_pp: return false
	return true


func _failed(reason: String) -> Dictionary:
	last_error = reason
	return {"ok": false, "error": reason}
