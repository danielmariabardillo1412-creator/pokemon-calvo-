extends SceneTree

const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const Lab = preload("res://scenes/visual/move_resource_lab.tscn")
var checks := 0
var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)


func _run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Policy.CONFIG_PATH))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Policy.DATA_PATH))
	var before := JSON.stringify(data).sha256_text()
	var policy := Policy.new()
	_check("local policy valid", policy.load_local())
	if not policy.valid:
		_finish()
		return
	_check("19 confirmed bans including absent signature users", policy.partition_move_ids(data.moves.keys()).excluded.size() == 19)
	_check("Z decision resolved", policy.partition_move_ids(data.moves.keys()).pending.is_empty())
	_check("900 eligible IDs", policy.eligible_ids("moves").size() == 900)
	_check("357 eligible abilities", policy.eligible_ids("abilities").size() == 357)
	_check("1019 eligible species", policy.eligible_ids("species").size() == 1019)
	for group: Dictionary in config.move_exclusions:
		for id: String in group.ids:
			_check("excluded move " + id, policy.move_state(id) == "excluded" and not policy.move_allowed(id))
	for id: String in config.z_moves.ids:
		_check("Z damage-only with explicit signature bans " + id, policy.move_allowed(id) == (data.moves[id].damage_class != "status" and id not in ["10_000_000_volt_thunderbolt", "light_that_burns_the_sky"]))
		_check("Z is not an ordinary learned slot " + id, not policy.move_learnable(id))
	_check("ordinary status retained, Z status forbidden", policy.move_learnable("conversion") and not policy.z_status_allowed())
	for id: String in config.protected_max_move_ids:
		_check("Max retained " + id, policy.move_allowed(id))
	_check("all 19 Max retained", config.protected_max_move_ids.size() == 19)
	for id: String in ["shadow_ball", "shadow_bone", "shadow_claw", "shadow_force", "shadow_punch", "shadow_sneak",
		"headlong_rush", "mystical_power", "lunar_blessing", "take_heart", "roar_of_time", "spacial_rend", "tera_blast", "ivy_cudgel", "vacuum_wave", "hyperspace_hole",
		"after_you", "ally_switch", "aromatic_mist", "coaching", "dragon_cheer", "follow_me", "helping_hand", "hold_hands", "quash", "rage_powder", "spotlight"]:
		_check("ordinary/transferred move retained " + id, policy.move_allowed(id))
	for id: String in config.excluded_ability_ids:
		_check("ability banned " + id, not policy.ability_allowed(id))
	_check("no automatic Slaking ban", policy.species_allowed("slaking"))
	for id: String in ["wishiwashi", "minior", "castform", "nincada", "ninjask", "shedinja"]:
		_check("species and all forms banned " + id, not policy.species_allowed(id) and not policy.form_allowed(id, id + "_test"))
	for form: String in config.excluded_form_ids:
		_check("cap form blocked " + form, not policy.form_allowed("pikachu", form.replace("_", "-")))
	_check("normal Pikachu retained", policy.form_allowed("pikachu"))
	_check("cosplay not silently excluded", policy.form_allowed("pikachu", "pikachu_rock_star"))
	_check("regional forms retained", policy.form_allowed("vulpix", "vulpix_alola"))
	_check("unknown IDs rejected", not policy.move_allowed("not_a_move") and not policy.species_allowed("not_a_species") and not policy.ability_allowed("not_an_ability"))
	_check("ID normalization", not policy.ability_allowed(" No-Guard ") and policy.move_state("Zippy-Zap") == "excluded")
	_check("deduped partitions", policy.partition_move_ids(["splash", "Splash", "max-flare"]).excluded == ["splash"])
	for decision: String in ["include", "exclude"]:
		var changed := config.duplicate(true)
		changed.z_moves.decision = decision
		_check("valid explicit Z decision " + decision, policy.configure(changed, data))
		_check("Z decision applied " + decision, policy.move_allowed("catastropika") == (decision == "include"))
		_check("Max independent from Z decision", policy.move_allowed("max_flare"))
	var malformed := config.duplicate(true)
	malformed.excluded_ability_ids.append("wonder_gurad")
	_check("typo fails validation", not policy.configure(malformed, data))
	_check("invalid policy fails closed", not policy.move_allowed("tackle") and policy.eligible_ids("species").is_empty())
	malformed = config.duplicate(true)
	malformed.excluded_ability_ids.append("truant")
	_check("duplicate rejected", not policy.configure(malformed, data))
	malformed = config.duplicate(true)
	malformed.move_exclusions[0].ids.append("max_flare")
	_check("protected Max exclusion rejected", not policy.configure(malformed, data))
	malformed = config.duplicate(true)
	malformed.z_moves.decision = "guess"
	_check("ambiguous policy decision rejected", not policy.configure(malformed, data))
	_check("canonical data not mutated", JSON.stringify(data).sha256_text() == before)
	var lab = Lab.instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab._load_catalog(true)
	_check("research archive preserves 1822 clips", lab._filtered.size() == 1822)
	lab._game_pool_switch.button_pressed = true
	_check("game-pool preview 1812 clips", lab._filtered.size() == 1812)
	var pool_ids: Dictionary = {}
	for index: int in lab._filtered:
		var id := String(lab._entries[index].move_id)
		pool_ids[id] = true
		_check("every game-pool entry eligible " + id, lab._content_policy.move_allowed(id))
	_check("895 visual game-pool IDs", pool_ids.size() == 895)
	lab._filter("splash")
	_check("search cannot restore exclusions", lab._filtered.is_empty())
	lab._filter("extreme_evoboost")
	_check("search cannot restore status Z", lab._filtered.is_empty())
	lab._filter("max_flare")
	_check("Max available in pool preview", lab._filtered.size() == 2)
	lab._game_pool_switch.button_pressed = false
	lab._filter("splash")
	_check("explicit archive still shows Splash", lab._filtered.size() == 2)
	lab._content_policy.valid = false
	lab._game_pool_switch.button_pressed = true
	_check("invalid policy blocks pool preview", lab._filtered.is_empty() and lab._status.text.begins_with("POOL BLOQUEADO"))
	lab.queue_free()
	_finish()


func _finish() -> void:
	var evidence_dir := "res://.godot/randomlock_content_checks/"
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var hashes: Dictionary = {}
	for path: String in [Policy.CONFIG_PATH, Policy.DATA_PATH,
		"res://modules/gameplay/randomlock_content_policy.gd",
		"res://scenes/visual/move_resource_lab.gd",
		"res://tests/gameplay/randomlock_content_test_runner.gd"]:
		hashes[path.trim_prefix("res://")] = FileAccess.get_sha256(path)
	var file := FileAccess.open(evidence_dir + "result.json", FileAccess.WRITE)
	if file == null:
		errors.append("Cannot save test evidence")
	else:
		file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL",
			"checks": checks, "errors": errors, "source_sha256": hashes}, "  ", true) + "\n")
		file.close()
	print("RANDOMLOCK CONTENT: ", checks, " checks; ", errors.size(), " failures")
	for error: String in errors:
		push_error(error)
	quit(0 if errors.is_empty() else 1)
