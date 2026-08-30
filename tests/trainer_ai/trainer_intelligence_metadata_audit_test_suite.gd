class_name TrainerIntelligenceMetadataAuditTestSuite
extends RefCounted

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback
	print("TRAINER_INTELLIGENCE_TEST _test_event_metadata_is_sanitized")
	_test_event_metadata_is_sanitized()


func _test_event_metadata_is_sanitized() -> void:
	var player := CreatureInstance.new(&"metadata_player", &"bulbasaur")
	var trainer := CreatureInstance.new(&"metadata_trainer", &"charmander")
	var creatures: Array[CreatureInstance] = [player, trainer]
	var state := BattleState.new(&"metadata_audit", creatures, 17)
	var memory := TrainerBattleMemory.new()
	_check.call("intel_metadata_memory_begin", memory.begin(state, &"side_b"))

	var secret := "debug_hidden_secret_must_not_leak"
	var events: Array[BattleEvent] = [
		BattleEvent.new(
			BattleEvent.ABILITY_TRIGGERED,
			1,
			&"metadata_player",
			&"metadata_trainer",
			&"",
			0,
			{"source_id": "overgrow", "debug_hidden_secret": secret},
		),
		BattleEvent.new(
			BattleEvent.ITEM_TRIGGERED,
			1,
			&"metadata_player",
			&"metadata_trainer",
			&"",
			0,
			{"source_id": "leftovers", "internal_roll": 999, "debug_hidden_secret": secret},
		),
	]
	memory.observe_events(events, state)
	var serialized := JSON.stringify(memory.to_dict())
	var raw_metadata_key_absent := true
	for record in memory.event_log:
		if record.has("metadata"):
			raw_metadata_key_absent = false
			break
	_check.call(
		"intel_metadata_raw_fields_not_persisted",
		raw_metadata_key_absent
		and not serialized.contains(secret)
		and not serialized.contains("internal_roll"),
	)
	_check.call(
		"intel_metadata_public_reveals_preserved",
		memory.revealed_ability_id(&"metadata_player") == &"overgrow"
		and memory.revealed_item_id(&"metadata_player") == &"leftovers",
	)
