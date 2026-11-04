extends "res://tests/gameplay/parallel_items_w02_campaign_005.gd"

# CAMP006 W02 block01: real native regression of 41742682811.
# Reuses (never mocks) full CAMP005 Service/CreatureFactory/SaveV2 probe.
const SOURCE_006_RECOVERY := "res://tests/fixtures/parallel_items/w02_campaign_006.json"


func _initialize() -> void:
	capture = false
	call_deferred("_run_recovery006")
	create_timer(420.0).timeout.connect(func():
		if not done:
			push_error("CAMP006 W02 recovery watchdog")
			quit(2))


func _run_recovery006() -> void:
	destination = "res://.godot/parallel_items/w02_campaign_006"
	DirAccess.make_dir_recursive_absolute(destination)
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_006_RECOVERY))
	if not loaded is Dictionary:
		push_error("CAMP006 W02 fixture no es Dictionary")
		quit(2)
		return
	automation = loaded
	catalogs = GameData.from_dict(JSON.parse_string(
		FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("overlay real y especies base", Variants.apply(catalogs))
	check("worker y campaña propios", automation.campaign == "CAMP_006"
		and automation.worker == "W02")
	check("sólo bloque recuperación", automation.blocks.size() == 1
		and automation.blocks[0].block == "01"
		and automation.blocks[0].ids == ["exp_candy_xl", "relaxed_mint"])
	check("tres modos heredados PARTY/STORAGE", automation.modes == ["active", "none", "reserve"])
	var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_005))
	check("fixture CAMP005 intacta", old is Dictionary)
	if not old is Dictionary:
		quit(2)
		return
	check("conservados los diez bloques CAMP005", old.blocks.size() == 10)
	var count_cases: int = 0
	for block: Dictionary in old.blocks:
		count_cases += block.cases.size()
	check("conservados los 288 escenarios", count_cases == 288)
	var selected: Dictionary = {}
	for block: Dictionary in old.blocks:
		for spec: Dictionary in block.cases:
			for criterion: Dictionary in automation.blocks[0].cases:
				if String(spec.scenario) == String(criterion.scenario):
					check("escenario recuperación único", not selected.has(String(spec.scenario)))
					selected[String(spec.scenario)] = spec
	check("exactamente tres escenarios de recuperación", selected.size() == 3)
	var curve: String = String(catalogs.species(&"mew").growth_rate)
	var xp99: int = ProgressionRuleset.experience_for_level(curve, 99)
	var xp100: int = ProgressionRuleset.experience_for_level(curve, 100)
	check("Mew usa curva medium-slow", curve == "medium-slow")
	check("brecha independiente 99 a 100 es 32757", xp100 - xp99 == 32757)
	check("Caramelo XL 30000 inferior a brecha", xp99 + 30000 < xp100)
	var passed_cases: int = 0
	for criterion: Dictionary in automation.blocks[0].cases:
		var label: String = String(criterion.scenario)
		current_case = label
		if not selected.has(label):
			check("escenario requerido presente", false)
			continue
		var spec: Dictionary = selected[label]
		var before_errors: int = errors.size()
		var observed: Dictionary = {}
		for mode: String in automation.modes:
			observed[mode] = _probe_training(spec, mode)
			check(mode + " ejecución nativa y SaveV2", bool(observed[mode].get("valid", false))
				and bool(observed[mode].get("save_v2", false)))
			if label == "exp_candy_xl_level99_gain":
				check(mode + " XL sube 30000 XP sin subir al 100",
					int(observed[mode].get("level", -1)) == 99
					and bool(observed[mode].get("accepted", false)) == (mode != "none")
					and xp99 + 30000 == int(criterion.expected_exp)
					and xp100 - xp99 - 30000 == int(criterion.exp_remaining))
			elif label == "exp_candy_xl_level99_cap_50xp":
				check(mode + " XL a 50 XP de 100 sí llega a 100",
					int(observed[mode].get("level", -1)) == (99 if mode == "none" else 100)
					and bool(observed[mode].get("accepted", false)) == (mode != "none")
					and int(criterion.expected_exp_gain) == 50)
			elif label == "relaxed_mint_level100":
				check(mode + " mint sin ejecutor no altera ni consume",
					int(observed[mode].get("level", -1)) == 100
					and not bool(observed[mode].get("accepted", true))
					and int(observed[mode].get("count", -1)) == (0 if mode == "none" else 2))
		if errors.size() == before_errors:
			passed_cases += 1
	check("los tres contratos completos sin errores", passed_cases == 3)
	var success: bool = errors.is_empty() and passed_cases == 3
	done = true
	print("CAMP006_W02_GODOT ", "PASS" if success else "FAIL",
		" blocks=", 1 if success else 0, " checks=", checks)
	quit(0 if success else 1)
