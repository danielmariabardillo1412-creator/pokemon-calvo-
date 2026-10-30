extends "res://tests/gameplay/field_held_v16.gd"

const V18 := "res://.godot/progression_items_v18/"
const Held = preload("res://modules/creatures/progression/progression_held_items.gd")
const Growth = preload("res://modules/inventory/field_growth_effects.gd")

func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done:push_error("PROGRESSION_V18 timeout");quit(2))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V18)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	if not capture:
		_domain();_everstone();_legacy()
		for mode: String in ["keep","fling","trick","lost","acquired","spent"]:await _native_reward(mode)
	await _map_item(&"lucky_egg");await _map_item(&"everstone")
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors,"routes":routes,"matrix_cases":matrix_cases,"gpu":capture}
	var file:=FileAccess.open(V18+("gpu.json" if capture else "godot.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("PROGRESSION_ITEMS_V18 ",report.status," checks=",checks," cases=",matrix_cases," GPU=",capture)
	quit(0 if errors.is_empty() else 1)

func _mon(sid: StringName,level: int,id: StringName,moves: Array) -> CreatureInstance:
	var c:=_make(sid,level,{},"hardy",id);c.moveset.clear();c.move_ids.clear();c.ability_id=&""
	for move: String in moves:c.add_move(StringName(move),catalogs)
	return c

func _outcome(base:=71,level:=7) -> BattleOutcome:
	var result:=BattleOutcome.new();result.winner_side_id=&"side_a"
	result.defeated=[{"base_experience":base,"level":level}]
	return result

func _xp_events(events: Array,id: StringName) -> int:
	var total:=0
	for event: ProgressionEvent in events:
		if event.kind==ProgressionEvent.EXPERIENCE_GAINED and event.creature_id==id:total+=int(event.data.amount)
	return total

func _evolution_count(events: Array) -> int:
	var count:=0
	for event: ProgressionEvent in events:
		if event.kind==ProgressionEvent.EVOLUTION_AVAILABLE:count+=1
	return count

func _domain() -> void:
	var curves: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/progression_growth_curves/reference_contract.json")).tables
	var mew_levels: Array=curves[catalogs.species(&"mew").growth_rate].levels_1_to_100
	for sid: String in catalogs.variant_allowed_species:
		for mode in 4:
			var c:=_mon(StringName(sid),50,&"matrix",["growl"])
			c.held_item_id=&"lucky_egg" if mode!=0 else &""
			c.held_item_consumed=mode in [2,3]
			var start: Dictionary={"matrix":"lucky_egg"} if mode==2 else {}
			var before:=c.to_dict();var expected:=106 if mode in [1,2] else 71
			var events:=ProgressionSystem.reconcile_battle_result([c],_outcome(),catalogs,ProgressionRuleset.new(),start)
			check("species reward and exact event "+sid+str(mode),c.experience==int(before.experience)+expected and _xp_events(events,c.instance_id)==expected)
			before.experience+=expected
			check("XP modifier changes no other creature data",c.to_dict()==before)
			matrix_cases+=1
	check("all eligible forms reward matrix",matrix_cases==4304)
	for base in [0,1,2,3,7,101,1001]:
		for room in [0,1,50,100000]:
			var c:=_mon(&"mew",50,&"rounding",["growl"]);c.held_item_id=&"lucky_egg"
			check("integer rounding and XP room",Held.battle_reward_amount(base,c,{},c.experience+room)==mini(base*3/2,room))
	var a:=_mon(&"mew",50,&"holder",["growl"]);a.held_item_id=&"lucky_egg"
	var b:=_mon(&"mew",50,&"other",["growl"]);var ko:=_mon(&"mew",50,&"ko",["growl"]);ko.current_hp=0
	var axp:=a.experience;var bxp:=b.experience;var kxp:=ko.experience
	var events:=ProgressionSystem.reconcile_battle_result([a,b,ko],_outcome(71,7),catalogs,ProgressionRuleset.new())
	check("holder bonus does not reduce or boost another survivor",a.experience==axp+52 and b.experience==bxp+35 and ko.experience==kxp and _xp_events(events,a.instance_id)==52)
	var maximum:=int(mew_levels[99])
	var cap:=_mon(&"mew",99,&"cap",["growl"]);cap.held_item_id=&"lucky_egg";cap.experience=maximum-1
	events=ProgressionSystem.reconcile_battle_result([cap],_outcome(),catalogs,ProgressionRuleset.new())
	check("XP cap event reports actual award",cap.experience==maximum and cap.level==100 and _xp_events(events,cap.instance_id)==1)
	events=ProgressionSystem.reconcile_battle_result([cap],_outcome(),catalogs,ProgressionRuleset.new())
	check("maximum XP emits no phantom award",_xp_events(events,cap.instance_id)==0 and events.is_empty())
	var candy:=_mon(&"mew",15,&"candy",["growl"]);candy.held_item_id=&"lucky_egg"
	var policy: RefCounted=_service(candy,&"exp_candy_xs").content
	var planned: Dictionary=Growth.plan(candy,&"exp_candy_xs",catalogs,policy,{})
	check("Lucky Egg does not boost EXP candy",planned.accepted and planned.candidate.experience==candy.experience+100)
	planned=Growth.plan(candy,&"rare_candy",catalogs,policy,{})
	check("Lucky Egg does not boost Rare Candy",planned.accepted and planned.candidate.level==16 and planned.candidate.experience==int(mew_levels[15]))

func _everstone() -> void:
	for mode in 4:
		var c:=_mon(&"bulbasaur",15,&"stone",["growl"])
		c.held_item_id=&"everstone" if mode in [0,1] else &"lucky_egg" if mode==2 else &""
		c.held_item_consumed=mode==1
		var needed:=ProgressionRuleset.experience_for_level("medium-slow",16)-c.experience
		var events:=ProgressionSystem.gain_experience(c,needed,catalogs.species(c.species_id),catalogs,ProgressionRuleset.new())
		check("Everstone blocks only an active level evolution",c.level==16 and (_evolution_count(events)==0)==(mode==0))
		var owner:=PlayerCollection.new();owner.party.add_creature(c)
		var session:=WildAdventureSession.new(owner,catalogs,ProgressionRuleset.new())
		var forged:=ProgressionEvent.new(ProgressionEvent.EVOLUTION_AVAILABLE,c.instance_id,{"species_id":&"ivysaur"})
		if mode==0:check("owned API rejects stale evolution intent",session.apply_evolution_event(forged)==null and owner.owned_creature(c.instance_id).species_id==&"bulbasaur")
		var source:=_mon(&"bulbasaur",15,&"stone_candy",["growl"]);source.held_item_id=c.held_item_id;source.held_item_consumed=c.held_item_consumed
		var policy: RefCounted=_service(source,&"rare_candy").content
		var planned: Dictionary=Growth.plan(source,&"rare_candy",catalogs,policy,{})
		check("candy and combat share the same Everstone gate",planned.accepted if mode==0 else planned.status=="NEEDS_CONTEXT" and planned.prompt.kind=="evolution")

func _legacy() -> void:
	for trainer in [false,true]:
		for lost in [false,true]:
			var own:=_mon(&"mew",50,&"legacy_egg",["quick_attack"]);own.held_item_id=&"lucky_egg"
			var owner:=PlayerCollection.new();owner.party.add_creature(own)
			var session
			var wild: CreatureInstance
			if trainer:
				session=TrainerBattleSession.new(owner,catalogs,ProgressionRuleset.new());wild=_mon(&"caterpie",1,&"trainer_foe",["growl"])
				var roster: Array[CreatureInstance]=[wild]
				check("legacy trainer starts",session.begin_battle(&"v18_trainer",roster,18))
			else:
				session=WildAdventureSession.new(owner,catalogs,ProgressionRuleset.new())
				var table:=WildEncounterTable.new(&"v18");table.add_slot(WildEncounterSlot.new(&"slot",&"caterpie",1,1,1))
				var rng:=RandomNumberGenerator.new();rng.seed=18
				check("legacy wild starts",session.begin_encounter(table,rng,18).status==WildEncounterResult.ENCOUNTER)
				wild=session.current_wild();wild.moveset.clear();wild.move_ids.clear();wild.add_move(&"growl",catalogs)
			# Controlled application-boundary fixture for an item lost after start.
			if lost:own.held_item_consumed=true
			var old:=own.experience
			var player_action:=BattleAction.new(1,own.instance_id,&"quick_attack",wild.instance_id,BattleAction.MOVE,&"side_a")
			var opponent_action:=BattleAction.new(1,wild.instance_id,&"growl",own.instance_id,BattleAction.MOVE,&"side_b")
			if trainer:session.submit_player_action(player_action,opponent_action)
			else:
				var actions: Array[BattleAction]=[player_action,opponent_action];session.submit_turn(actions)
			check("legacy actual KO ends battle",session.battle_state().phase==BattleState.FINISHED)
			var result= session.settle_finished_battle()
			var base:=catalogs.species(&"caterpie").base_experience/7
			check("legacy reward retains initial Egg",result.ok and own.experience==old+base*3/2)
			var after:=own.experience;check("legacy cannot settle XP twice",not session.settle_finished_battle().ok and own.experience==after)
			routes.append({"route":"legacy_reward","trainer":trainer,"lost_item_fixture":lost,"xp_gained":after-old})

func _native_reward(mode: String) -> void:
	var own:=_mon(&"mew",50,&"native_egg",["quick_attack","fling","trick","growl"])
	if mode!="acquired":own.held_item_id=&"lucky_egg"
	own.held_item_consumed=mode=="spent"
	var foe:=_mon(&"caterpie",50,&"native_foe",["knock_off" if mode=="lost" else "growl"]);foe.current_hp=1
	if mode=="acquired":foe.held_item_id=&"lucky_egg"
	var owner:=PlayerCollection.new();owner.party.add_creature(own)
	var session:=Native.new(catalogs,owner,"gen9calvounifiedv1")
	var opened: bool=await session.begin_wild(self,foe,[23,19,29,43]);check("native Egg starts "+mode,opened)
	if not opened:await session.close();return
	var old:=own.experience
	if mode in ["trick","acquired","lost"]:
		check("native item movement occurs",(await session.submit("move 4" if mode=="lost" else "move 3",session.revision)).accepted)
	var saved:=session.snapshot();await session.close();session=Native.new(catalogs,owner,"gen9calvounifiedv1")
	check("native restores initial-item authority",await session.restore_saved(self,saved))
	var original:=session.snapshot()
	check("stale command grants no XP",not (await session.submit("move 1",session.revision+1)).accepted and session.snapshot()==original and own.experience==old)
	check("native actual final attack",(await session.submit("move 2" if mode=="fling" else "move 1",session.revision)).accepted and session.phase()=="finished")
	check("XP stays staged before settlement",own.experience==old)
	var result: Dictionary=session.settle_finished_battle()
	var base:=catalogs.species(&"caterpie").base_experience*50/7
	var expected:=base if mode=="spent" else base*3/2
	check("native Egg reward exact "+mode,result.accepted and own.experience==old+expected)
	check("native ownership reflects real move",own.held_item_consumed==(mode in ["spent","fling","trick","lost"]))
	var after:=own.to_dict();check("native no double reward",not session.settle_finished_battle().accepted and own.to_dict()==after)
	routes.append({"route":"native_reward","mode":mode,"xp_gained":own.experience-old,"initial_context_restored":true})
	await session.close()

func _map_item(id: StringName) -> void:
	scene=load("res://scenes/visual/field_demo.tscn").instantiate();root.add_child(scene)
	await process_frame;await physics_frame
	var config: Dictionary=scene._active_config.duplicate(true)
	config.encounter_chance_percent=100;config.wild_species_id="caterpie";config.wild_min_level=1;config.wild_max_level=1
	scene._on_configuration_applied(config)
	var owner: PlayerCollection=scene.field_collection();var own_id:=owner.party.get_creatures()[0].instance_id
	var c:=_mon(&"bulbasaur" if id==&"everstone" else &"mew",15 if id==&"everstone" else 50,own_id,["quick_attack","growl"])
	if id==&"everstone":c.experience=ProgressionRuleset.experience_for_level("medium-slow",16)-1
	check("map progression owner",owner.replace_owned_same_identity(c));owner.inventory.add(id,3);owner.inventory.add(&"exp_candy_xs")
	check("map progression bag opens",scene.toggle_item_bag());var bag=scene._item_bag
	_select(bag,String(id));check("map equips progression item",bag._apply("equip").accepted)
	bag.hide();await process_frame
	var bridge=scene._native_battles;bridge.save_path=V18+("gpu_" if capture else "headless_")+String(id)+".json"
	check("progression field save",bridge.save_game());check("progression field load",await bridge.load_game())
	owner=scene.field_collection();var xp_before: Dictionary={}
	for creature: CreatureInstance in owner.party.get_creatures():xp_before[String(creature.instance_id)]=creature.experience
	var alive:=owner.party.get_creatures().size();var base:=catalogs.species(&"caterpie").base_experience/7/alive
	scene.player.global_position=Vector2(420,150);await scene._on_player_step_completed(scene.player.global_position)
	var view=bridge.view;view._playback.set_process(false)
	check("progression battle checkpoint saves",bridge.save_game())
	check("progression battle checkpoint restores",await bridge.load_game());view._playback.set_process(false)
	check("map actual winning attack",(await view.choose("move 1")).accepted)
	await _drain_view(view);await process_frame;await process_frame
	check("map victory settles",view.session.completion_reason=="VICTORY")
	await bridge.leave_battle();owner=scene.field_collection()
	var expected:=base*3/2 if id==&"lucky_egg" else base
	check("map owner exact XP",owner.owned_creature(own_id).experience==int(xp_before[String(own_id)])+expected)
	for creature: CreatureInstance in owner.party.get_creatures():
		if creature.instance_id!=own_id:check("map teammate keeps ordinary share",creature.experience==int(xp_before[String(creature.instance_id)])+base)
	check("reward never consumes held progression item",_physical_medicine(owner,id)==3 and owner.owned_creature(own_id).held_item_id==id and not owner.owned_creature(own_id).held_item_consumed)
	check("progression bag reopens",scene.toggle_item_bag());bag=scene._item_bag
	if id==&"lucky_egg":
		_select(bag,"exp_candy_xs");var old:=owner.owned_creature(own_id).experience
		check("real candy ignores Lucky Egg bonus",bag._apply("use").accepted and owner.owned_creature(own_id).experience==old+100)
	else:
		var current:=owner.owned_creature(own_id)
		check("map Everstone level gain has no eligible evolution",current.level==16 and EvolutionSystem.evolution_candidates(catalogs.species(current.species_id),EvolutionSystem.level_up_context(current),catalogs).is_empty())
		check("Everstone can be unequipped",bag.service.unequip(own_id).accepted and _physical_medicine(owner,id)==3)
		check("removing Everstone restores eligibility",not EvolutionSystem.evolution_candidates(catalogs.species(current.species_id),EvolutionSystem.level_up_context(current),catalogs).is_empty())
	if capture and id==&"lucky_egg":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		check("progression bag screenshot",root.get_texture().get_image().save_png(V18+"progression_bag.png")==OK)
		check("progression bag fits viewport",bag.position.y>=0 and bag.position.y+bag.size.y<=root.size.y)
	bag.hide();await process_frame
	var final_xp:=owner.owned_creature(own_id).experience
	check("progression final save",bridge.save_game());check("progression final load",await bridge.load_game())
	check("final XP and physical units persist",scene.field_collection().owned_creature(own_id).experience==final_xp and _physical_medicine(scene.field_collection(),id)==3)
	routes.append({"route":"map_progression","item":String(id),"battle_xp":expected,"saved_after_settlement":true})
	if view.session!=null:await view.session.close()
	scene.queue_free();await process_frame
