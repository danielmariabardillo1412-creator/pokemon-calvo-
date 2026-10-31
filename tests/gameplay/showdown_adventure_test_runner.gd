extends SceneTree

const Session = preload("res://modules/gameplay/showdown_adventure_session.gd")
const DEST := "res://.godot/showdown_adventure_checks/"
var catalogs: DefinitionCatalog
var errors: Array[String] = []
var checks := 0
var active: RefCounted
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, valid: bool) -> void:
	checks += 1
	if not valid:
		errors.append(label); push_error(label)
		if active != null: printerr("SESSION_ERROR ", active.last_error)


func creature(id: String, species: String = "mew", level: int = 50, moves: Array = [&"tackle", &"reflect"]) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 14
	var result := CreatureFactory.create(catalogs.species(StringName(species)), level, catalogs, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves})
	result.ability_id = &"" # Isolate application lifecycle from species-specific abilities.
	return result


func collection(count: int = 1) -> PlayerCollection:
	var player := PlayerCollection.new()
	for i in count: player.party.add_creature(creature("own_%d" % i))
	player.inventory.add(&"poke_ball", 1)
	player.inventory.add(&"master_ball", 1)
	player.inventory.add(&"potion", 3)
	return player


func _run() -> void:
	create_timer(150).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			check("watchdog", false); _finish())
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional catalog loads", preload("res://modules/creatures/progression/pokemon_variant_catalog.gd").apply(catalogs))
	await _capture_success(1)
	await _capture_success(6)
	await _capture_failure()
	await _escape()
	await _blocked_escape()
	await _settlement(true)
	await _settlement(false)
	await _draw()
	await _conflicts()
	await _dead_party()
	await _unsupported_capture_reaction()
	await _recovery()
	await _snapshot_contracts()
	await _forced_switch()
	await _overlapping_commands()
	_finish()


func _capture_success(count: int) -> void:
	var player := collection(count)
	var reference := player.party.get_creatures()[0]
	var wild := creature("wild_capture_%d" % count, "vulpix_alola", 18, [&"tackle"]); wild.is_shiny = true; wild.current_hp = 7
	var original := wild.to_dict()
	active = Session.new(catalogs, player)
	check("wild session opens full party %d" % count, await active.begin_wild(self, wild))
	var native_before: Dictionary = active.snapshot().native
	var stale: Dictionary = await active.capture(&"master_ball", -1)
	check("stale capture spends nothing %d" % count, not stale.accepted and player.inventory.quantity(&"master_ball") == 1)
	var result: Dictionary = await active.capture(&"master_ball", active.revision)
	check("guaranteed capture publishes result %d" % count, result.accepted and active.completion_reason == "CAPTURED")
	check("capture consumes exactly one ball %d" % count, player.inventory.quantity(&"master_ball") == 0 and player.inventory.quantity(&"potion") == 3)
	check("capture has no native enemy turn %d" % count, active.snapshot().native == native_before)
	var captured := player.owned_creature(wild.instance_id)
	check("capture preserves regional shiny identity and current HP %d" % count, captured != null and captured.to_dict() == original)
	check("capture routes party versus PC %d" % count, result.stored == (count == 6) and player.location_of(wild.instance_id) == (&"STORAGE" if count == 6 else &"PARTY"))
	check("existing owned reference survives capture %d" % count, player.party.get_creature(reference.instance_id) == reference)
	check("capture cannot publish twice %d" % count, not (await active.capture(&"master_ball", active.revision)).accepted and player.inventory.quantity(&"master_ball") == 0)
	await active.close()


func _capture_failure() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	check("failed capture session opens", await active.begin_wild(self, creature("mewtwo_wild", "mewtwo", 50, [&"tackle"])))
	# Find a deterministic FAILURE using the reused domain probability, not guesses.
	var target: CreatureInstance = active.battle_state().active_for_side(&"side_b")
	var context := CaptureBattleContext.new(); context.is_wild = true
	var seed := 1
	while seed < 100:
		var probe := RandomNumberGenerator.new(); probe.seed = seed
		var resolution := CaptureSystem.resolve(CaptureAttempt.new(target, &"poke_ball", context), probe, catalogs, null)
		if resolution.result.status == CaptureResult.FAILED: break
		seed += 1
	active._capture_rng.seed = seed
	var before: Dictionary = active.snapshot()
	var invalid: Dictionary = await active.capture(&"ultra_ball", active.revision)
	check("unowned ball rejected without RNG or native changes", not invalid.accepted and active.snapshot() == before)
	var result: Dictionary = await active.capture(&"poke_ball", active.revision)
	check("failed ball invokes native opponent reaction", result.accepted and result.get("capture_result", {}).get("status") == "FAILED")
	check("failed capture uses turn and no player move PP", active.battle_state().turn == 1 and active.battle_state().active_for_side(&"side_a").moveset[0].current_pp == player.party.get_creatures()[0].moveset[0].current_pp)
	check("ball consumption is staged until campaign finish", active.inventory.quantity(&"poke_ball") == 0 and player.inventory.quantity(&"poke_ball") == 1)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(active.snapshot()))
	var restored := Session.new(catalogs, player)
	var loaded: bool = await restored.restore_saved(self, saved)
	check("adventure checkpoint loads", loaded)
	check("adventure checkpoint restores bag RNG and native turn", JSON.parse_string(JSON.stringify(restored.snapshot())) == saved)
	await active.close(); active = restored
	var caught: Dictionary = await active.capture(&"master_ball", active.revision)
	check("finishing capture also publishes previously spent last ball", caught.accepted and player.inventory.quantity(&"poke_ball") == 0 and player.inventory.quantity(&"master_ball") == 0)
	check("native reaction HP persists after capture", player.party.get_creatures()[0].current_hp < player.party.get_creatures()[0].stats.max_hp)
	await active.close()


func _escape() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	check("escape session opens", await active.begin_wild(self, creature("slow_wild", "snorlax", 10, [&"tackle"])))
	var before: Dictionary = active.snapshot()
	var fled: Dictionary = await active.flee(active.revision)
	check("faster creature escapes with no enemy turn", fled.accepted and active.completion_reason == "FLED" and active.snapshot().native == before.native)
	check("escape has no XP or item consumption", fled.progression_events.is_empty() and player.inventory.quantity(&"poke_ball") == 1)
	await active.close()
	player = collection()
	active = Session.new(catalogs, player)
	check("slow escape session opens", await active.begin_wild(self, creature("fast_wild", "electrode", 100, [&"tackle"])))
	var roll_seed := 1
	while roll_seed < 100:
		var rng := RandomNumberGenerator.new(); rng.seed = roll_seed
		if not WildEscapeRuleset.new().resolve(player.party.get_creatures()[0].stats.speed, active.battle_state().active_for_side(&"side_b").stats.speed, 1, rng).escaped: break
		roll_seed += 1
	active._escape_rng.seed = roll_seed
	var result: Dictionary = await active.flee(active.revision)
	check("failed escape consumes exactly one native turn", result.accepted and active.escape_attempts == 1 and active.battle_state().turn == 1 and active.completion_reason == "")
	await active.close()


func _settlement(win: bool) -> void:
	var player := PlayerCollection.new()
	var own := creature("player_finish", "mewtwo" if win else "caterpie", 80 if win else 5, [&"psychic"] if win else [&"tackle"])
	player.party.add_creature(own)
	var original_exp := own.experience
	var enemy := creature("trainer_finish", "caterpie" if win else "mewtwo", 5 if win else 80, [&"tackle"] if win else [&"psychic"])
	active = Session.new(catalogs, player)
	check("trainer session opens %s" % win, await active.begin_trainer(self, &"route_trainer", [enemy] as Array[CreatureInstance]))
	var before: Dictionary = active.snapshot()
	check("trainer capture and escape rejected %s" % win, not (await active.capture(&"master_ball", active.revision)).accepted and not (await active.flee(active.revision)).accepted and active.snapshot() == before)
	check("unfinished result cannot be settled %s" % win, not active.settle_finished_battle().accepted)
	var turns := 0
	while active.phase() != "finished" and turns < 20:
		var result: Dictionary = await active.submit("move 1" if active.phase() != "opponent_switch" else "", active.revision)
		check("trainer native command %s/%d" % [win, turns], result.accepted)
		if not result.accepted: printerr(active.last_error); break
		turns += 1
	check("trainer reaches terminal result %s" % win, active.phase() == "finished")
	var result: Dictionary = active.settle_finished_battle()
	check("correct winner exported with no first-side fallback %s" % win, result.accepted and result.outcome.winner_side_id == ("side_a" if win else "side_b"))
	check("XP only on actual victory %s" % win, own.experience > original_exp if win else own.experience == original_exp)
	check("owned creature object identity unchanged %s" % win, player.party.get_creature(own.instance_id) == own)
	check("KO remains KO and is not revived %s" % win, not own.is_knocked_out() if win else own.is_knocked_out())
	var settled := own.to_dict()
	check("settlement cannot award XP twice %s" % win, not active.settle_finished_battle().accepted and own.to_dict() == settled)
	await active.close()


func _blocked_escape() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	check("trapping session opens", await active.begin_wild(self, creature("trapping_wild", "mew", 50, [&"mean_look"])))
	check("native trapping move resolves", (await active.submit("move 2", active.revision)).accepted)
	var before: Dictionary = active.snapshot()
	var result: Dictionary = await active.flee(active.revision)
	check("native trapping blocks fleeing and consumes a reaction turn", result.accepted and result.get("escape_blocked", false) and active.battle_state().turn == 2)
	check("blocked escape does not roll escape RNG or increment attempts", active.snapshot().adventure.escape_rng == before.adventure.escape_rng and active.escape_attempts == 0)
	await active.close()


func _draw() -> void:
	var player := PlayerCollection.new(); player.party.add_creature(creature("draw_own", "electrode", 80, [&"explosion"]))
	var enemy := creature("draw_enemy", "caterpie", 1, [&"tackle"])
	active = Session.new(catalogs, player)
	check("draw session opens", await active.begin_wild(self, enemy))
	var response: Dictionary = await active.submit("move 1", active.revision)
	check("self-KO terminal action accepted", response.accepted and active.phase() == "finished")
	# Gen9 Self-KO clause can award the opponent rather than tie. Both must avoid XP.
	var before_exp: int = player.party.get_creatures()[0].experience
	var result: Dictionary = active.settle_finished_battle()
	check("simultaneous KO never awards XP to fainted party", result.accepted and player.party.get_creatures()[0].is_knocked_out() and player.party.get_creatures()[0].experience == before_exp)
	await active.close()


func _conflicts() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	check("conflict session opens", await active.begin_wild(self, creature("conflict_enemy")))
	var before: Dictionary = active.snapshot()
	player.inventory.add(&"potion", 1)
	check("changed campaign rejects command without overwriting inventory", not (await active.capture(&"master_ball", active.revision)).accepted and active.snapshot() == before and player.inventory.quantity(&"potion") == 4)
	var restored := Session.new(catalogs, player)
	check("checkpoint refuses a different campaign baseline", not await restored.restore_saved(self, before) and restored._client == null)
	await active.close()
	player = collection()
	active = Session.new(catalogs, player)
	check("precommit guard session opens", await active.begin_wild(self, creature("guard_enemy")))
	before = active.snapshot()
	active.commit_guard = func(): return false
	check("failed guard aborts native candidate and staged capture RNG", not (await active.capture(&"poke_ball", active.revision)).accepted and active.snapshot() == before)
	await active.close()


func _dead_party() -> void:
	var player := collection(2)
	var dead: CreatureInstance = player.party.get_creatures()[0]; dead.current_hp = 0
	active = Session.new(catalogs, player)
	check("existing KO excluded from native combat without removing party slot", await active.begin_wild(self, creature("dead_party_wild")) and active._origin.p1.size() == 1 and player.party.size() == 2)
	var result: Dictionary = await active.capture(&"master_ball", active.revision)
	check("capture never revives excluded KO", result.accepted and dead.current_hp == 0 and player.party.get_creature(dead.instance_id) == dead)
	await active.close()


func _unsupported_capture_reaction() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	var enemy := creature("substitute_wild", "mewtwo", 50, [&"substitute"])
	check("unsupported reaction fixture opens", await active.begin_wild(self, enemy))
	active._policy._denied_moves["substitute"] = "test_policy_mismatch" # Deliberate incompatibility still fails closed.
	# Mewtwo's full-health catch rate gives deterministic failure for this seed.
	active._capture_rng.seed = 1
	var before: Dictionary = active.snapshot()
	var result: Dictionary = await active.capture(&"poke_ball", active.revision)
	check("unsupported enemy effect rolls back ball RNG native turn and campaign", not result.accepted and active.snapshot() == before and player.inventory.quantity(&"poke_ball") == 1)
	await active.close()


func _recovery() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	check("recovery session opens", await active.begin_wild(self, creature("recovery_wild", "mewtwo", 50, [&"tackle"])))
	active._capture_rng.seed = 1
	var before: Dictionary = active.snapshot()
	OS.kill(active._client.pid); await create_timer(0.03).timeout
	var result: Dictionary = await active.capture(&"poke_ball", active.revision)
	check("worker loss preserves native checkpoint ball and capture RNG", not result.accepted and active.needs_recovery and active.snapshot() == before and player.inventory.quantity(&"poke_ball") == 1)
	var recovered := Session.new(catalogs, player)
	check("whole adventure transaction can resume", await recovered.restore_saved(self, before) and recovered.snapshot() == before)
	await active.close(); active = recovered
	check("recovered capture can complete normally", (await active.capture(&"master_ball", active.revision)).accepted)
	await active.close()


func _snapshot_contracts() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	check("snapshot contract session opens", await active.begin_wild(self, creature("contract_wild")))
	var before: Dictionary = active.snapshot()
	var forged: Dictionary = before.duplicate(true); forged.adventure.inventory.quantities.potion = 4
	var restore := Session.new(catalogs, player)
	check("snapshot cannot add bag items", not await restore.restore_saved(self, forged) and restore._client == null)
	forged = before.duplicate(true); forged.adventure.inventory.quantities.erase("potion")
	check("snapshot cannot discard unrelated medicines", not await restore.restore_saved(self, forged) and restore._client == null)
	forged = before.duplicate(true); forged.origin.p1[0].instance_id = "different_owned_pokemon"
	check("snapshot cannot replace the owning campaign party", not await restore.restore_saved(self, forged) and restore._client == null)
	var response: Dictionary = await active.submit_reaction("capture_failed", active.revision)
	check("game command API cannot bypass bag using a free reaction", not response.accepted and active.snapshot() == before)
	# Mutation during IPC, rather than only a pre-existing conflict.
	process_frame.connect(func(): player.inventory.add(&"potion", 1), CONNECT_ONE_SHOT)
	response = await active.submit("move 1", active.revision)
	check("campaign mutation during async prepare aborts native candidate", not response.accepted and active.snapshot() == before and player.inventory.quantity(&"potion") == 4)
	await active.close()


func _forced_switch() -> void:
	var player := PlayerCollection.new()
	player.party.add_creature(creature("weak_lead", "caterpie", 5, [&"tackle"]))
	player.party.add_creature(creature("reserve", "mew", 100, [&"tackle"]))
	player.inventory.add(&"master_ball", 1)
	active = Session.new(catalogs, player)
	check("forced replacement session opens", await active.begin_wild(self, creature("strong_wild", "mewtwo", 80, [&"psychic"])))
	check("native KO requests player replacement", (await active.submit("move 1", active.revision)).accepted and active.phase() == "player_switch")
	var before: Dictionary = active.snapshot()
	check("capture cannot bypass forced replacement", not (await active.capture(&"master_ball", active.revision)).accepted and active.snapshot() == before)
	check("flee cannot bypass forced replacement", not (await active.flee(active.revision)).accepted and active.snapshot() == before)
	check("replacement resumes native move request", (await active.submit("switch 2", active.revision)).accepted and active.phase() == "move")
	check("capture after replacement persists KO without revival", (await active.capture(&"master_ball", active.revision)).accepted and player.party.get_creature(&"weak_lead").current_hp == 0)
	await active.close()


func _overlapping_commands() -> void:
	var player := collection()
	active = Session.new(catalogs, player)
	var opened: bool = await active.begin_wild(self, creature("overlap_wild"))
	var observed := {"rejected": false, "lock_retained": false}
	process_frame.connect(func():
		var rejected: Dictionary = await active.capture(&"master_ball", active.revision)
		var settled: Dictionary = active.settle_finished_battle()
		observed.rejected = not rejected.accepted and not settled.accepted
		observed.lock_retained = active.busy, CONNECT_ONE_SHOT)
	var result: Dictionary = await active.submit("move 1", active.revision)
	check("competing capture and settlement cannot release an in-flight native lock", opened and result.accepted and observed.rejected and observed.lock_retained and active.revision == 1 and player.inventory.quantity(&"master_ball") == 1)
	await active.close()


func _finish() -> void:
	if done: return
	done = true
	var file := FileAccess.open(DEST + "gameplay.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors}, "  ")); file.close()
	print("SHOWDOWN_ADVENTURE ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
