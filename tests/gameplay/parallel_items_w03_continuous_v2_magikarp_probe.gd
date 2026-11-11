extends SceneTree

## W03 V2: independently isolate historical native Magikarp L5 move_policy
## from storage/ball dispatch by using the SAME owner & changing ONLY the
## WildEncounterSystem encounter species to legal Goldeen L5.
## This is a DIAGNOSTIC NEGATIVE, never credit it as a functional ball.
var checks := 0
var errors: Array[String] = []
var scene: Node2D
var bridge: Node
var view: Control

func ck(label: String, yes: bool) -> void:
	checks += 1
	if not yes:
		errors.append(label)
		push_error("W03_V2_MAGIKARP_PROBE: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _mon(id: StringName) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 501005
	var c := CreatureFactory.create(scene._catalogs.species(&"mew"), 40, scene._catalogs,
		ProgressionRuleset.new(), rng, {"instance_id": id, "moves": ["tackle"], "nature_id": &"hardy"})
	c.ability_id = &""
	return c

func _step() -> void:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	ck("native map ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _done()
		return
	scene.player.set_physics_process(false)
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "magikarp"
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	owner.party = CreatureParty.new()
	for i in 6:
		ck("baseline party fixture %d" % i, owner.party.add_creature(_mon(StringName("w03v2_mag_party_%d" % i))))
	for i in 30:
		ck("baseline first box fixture %d" % i, owner.storage.add_creature(_mon(StringName("w03v2_mag_box_%d" % i))))
	owner.inventory.set_quantity(&"poke_ball", 3)
	var party_pre: Dictionary = owner.party.to_dict()
	var box_pre: Dictionary = owner.storage.to_dict()
	var stock_pre := owner.inventory.quantity(&"poke_ball")
	ck("Magikarp catalog is valid but native moves unverified",
		scene._catalogs.species(&"magikarp") != null
		and stock_pre == 3 and owner.party.size() == 6
		and owner.storage.get_all_creatures().size() == 30)
	await _step()
	ck("native Magikarp L5 rejects with move_policy before any capture",
		(view.session == null or not view.session.has_active_battle())
		and String(bridge.last_error).contains("move_policy"))
	ck("rejected native preflight has no ball or creature loss",
		owner.inventory.quantity(&"poke_ball") == stock_pre
		and owner.party.to_dict() == party_pre and owner.storage.to_dict() == box_pre
		and owner.caught_base_species_ids.is_empty())
	# Change ONLY live encounter table, keeping owner, full Party and full box.
	var zone: StringName = scene.TECHNICAL_ZONE_ID
	var built: Dictionary = TechnicalEncounterPoolBuilder.build(scene._catalogs,
		zone, 100, 5, 5, &"goldeen")
	ck("native Goldeen positive control uses same table producer",
		bool(built.get("ok", false)))
	if bool(built.get("ok", false)):
		scene._director._tables[zone] = built.table
		ck("same owner's positive control unchanged",
			is_same(owner, scene.field_collection())
			and owner.inventory.quantity(&"poke_ball") == stock_pre)
		await _step()
		ck("Goldeen L5 native battle STARTS with otherwise identical state",
			view.session != null and view.session.has_active_battle()
			and view.session.battle_state().active_for_side(&"side_b").base_species_id() == &"goldeen")
		if view.session != null and view.session.has_active_battle():
			ck("no ball thrown in diagnostic control",
				owner.inventory.quantity(&"poke_ball") == stock_pre
				and owner.caught_base_species_ids.is_empty())
	await _done()

func _done() -> void:
	if view != null and view.session != null:
		await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	if errors.is_empty():
		print("W03_V2_MAGIKARP_PROBE PASS checks=" + str(checks) + " status=KNOWN_MOVE_POLICY_NO_BALL_LOSS")
		quit(0)
	else:
		print("W03_V2_MAGIKARP_PROBE FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
