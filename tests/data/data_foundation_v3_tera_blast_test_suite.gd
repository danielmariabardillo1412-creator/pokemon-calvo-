extends RefCounted

# Exact normal/non-Tera subset. No mock definition, Tera state or visual override.
func run(check: Callable) -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/raw/pokemon_api.json"))
	var manifest := DatasetManifest.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/manifests/pokemon_api_manifest.json")))
	var imported := DataImporter.new().import_dataset(raw, manifest)
	var gd: GameData = imported.game_data
	var normalized := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json")))
	for pair: Array in [["imported", gd], ["normalized", normalized]]:
		var catalog: DefinitionCatalog = pair[1].to_definition_catalog()
		var move := catalog.move(&"tera_blast")
		var label := "tera_blast/" + String(pair[0])
		check.call(label + "/base_values", move != null and move.type_id == &"normal" and move.power == 80 and move.damage_class == "special" and move.accuracy == 100 and move.pp == 10)
		check.call(label + "/partial_not_full_tera", move != null and move.classification == "PARTIAL_RUNTIME")
		check.call(label + "/no_false_secondary_effect", move != null and move.effect_specs.is_empty())
		for seed in [1, 42, 2026]:
			for reversed: bool in [false, true]:
				var actor_id: StringName = &"b" if reversed else &"a"
				var target_id: StringName = &"a" if reversed else &"b"
				var actor := CreatureInstance.new(actor_id, &"charizard", 50, StatBlock.new(2000, 70, 70, 90, 90, 70), [&"tera_blast"])
				var target := CreatureInstance.new(target_id, &"wailord", 50, StatBlock.new(2000, 70, 70, 60, 70, 70), [&"recover"])
				var participants: Array[CreatureInstance] = []
				participants.assign([target, actor] if reversed else [actor, target])
				var server := AuthoritativeBattleServer.new(BattleState.new(&"tera_regression", participants, seed), catalog)
				var events := server.submit_turn([
					BattleAction.new(1, actor_id, &"tera_blast", target_id, BattleAction.MOVE, &"side_b" if reversed else &"side_a"),
					BattleAction.new(1, target_id, &"recover", actor_id, BattleAction.MOVE, &"side_a" if reversed else &"side_b"),
				])
				var damage := 0
				var stat_events := 0
				for event: BattleEvent in events:
					if event.move_id == &"tera_blast":
						if event.kind == BattleEvent.DAMAGE_APPLIED:
							damage += event.amount
						stat_events += int(event.kind == BattleEvent.STAT_STAGE_CHANGED)
				var sample := label + "/%d/%s" % [seed, actor_id]
				check.call(sample + "/damage_resolved", damage > 0)
				check.call(sample + "/no_debuff_events", stat_events == 0)
				check.call(sample + "/target_stages_unchanged", target.stat_stages.get_stage(StatStages.ATTACK) == 0 and target.stat_stages.get_stage(StatStages.SPECIAL_ATTACK) == 0)
				check.call(sample + "/user_stages_unchanged", actor.stat_stages.get_stage(StatStages.ATTACK) == 0 and actor.stat_stages.get_stage(StatStages.SPECIAL_ATTACK) == 0)
				check.call(sample + "/pp_once", actor.move_slot(&"tera_blast").current_pp == 9)
