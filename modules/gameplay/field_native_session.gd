extends "res://modules/gameplay/showdown_adventure_session.gd"

## Native field owner: additionally publishes trainer consequences and observed
## sleep clocks in the same synchronous settlement as the player's collection.
var trainer_owner: TrainerCampaignRosterOwner
var _trainer_stamp := ""


func _init(catalog: DefinitionCatalog, collection: PlayerCollection, clocks: Dictionary,
	p_format: String = "gen9customgame", owner: TrainerCampaignRosterOwner = null) -> void:
	super(catalog, collection, p_format)
	native_sleep_clocks = clocks
	trainer_owner = owner
	_trainer_stamp = _trainer_fingerprint()


func _trainer_fingerprint() -> String:
	if trainer_owner == null: return ""
	var rows: Array = []
	for c: CreatureInstance in trainer_owner.roster_for_battle(): rows.append(c.to_dict())
	return JSON.stringify(rows).sha256_text()


func _campaign_unchanged() -> bool:
	return super._campaign_unchanged() and _trainer_fingerprint() == _trainer_stamp


func restore_saved(tree: SceneTree, data: Dictionary) -> bool:
	if trainer_owner != null:
		var expected: Array = []
		for c: CreatureInstance in trainer_owner.roster_for_battle():
			if not c.is_knocked_out(): expected.append(_creature_dto(c))
		if JSON.parse_string(JSON.stringify(data.get("origin", {}).get("p2"))) != JSON.parse_string(JSON.stringify(expected)):
			last_error = "trainer_snapshot_ownership"; return false
	return await super.restore_saved(tree, data)


func _finish(reason: String, bag: PlayerInventory, resolution: CaptureResolution = null) -> Dictionary:
	var staged: Array[CreatureInstance] = []
	if trainer_owner != null:
		for cid: StringName in battle_state().sides[1].party_ids:
			var copy := _persistent_copy(battle_state().creature(cid))
			if copy == null or trainer_owner.owned_creature(cid) == null: return _rejected("trainer_identity_missing")
			staged.append(copy)
	var result := super._finish(reason, bag, resolution)
	if not result.accepted: return result
	for copy: CreatureInstance in staged:
		var original := trainer_owner.owned_creature(copy.instance_id)
		for key: String in copy.to_dict():
			if key not in ["instance_id", "battle_transform"]: original.set(key, copy.get(key))
	for side: Dictionary in _checkpoint.roster:
		for row: Dictionary in side.pokemon:
			var id := String(row.instance_id)
			var owned := player.owned_creature(StringName(id))
			if owned == null and trainer_owner != null: owned = trainer_owner.owned_creature(StringName(id))
			if owned == null: continue
			# Capture-side effects (Heal Ball) publish after the native checkpoint.
			# Keep clocks only for a creature that is STILL asleep after settlement.
			if owned.status_state.persistent_id == &"sleep" and row.sleep_clock is Dictionary: native_sleep_clocks[id] = row.sleep_clock.duplicate(true)
			else: native_sleep_clocks.erase(id)
	_trainer_stamp = _trainer_fingerprint()
	return result
