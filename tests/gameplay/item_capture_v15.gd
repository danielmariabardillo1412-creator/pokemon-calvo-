extends "res://tests/gameplay/item_capture_v11.gd"

const V15 := "res://.godot/item_capture_v15/"
const V15_BALLS: Array[StringName] = [&"friend_ball", &"safari_ball", &"sport_ball", &"cherish_ball"]
var routes: Array = []

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done: push_error("CAPTURE_V15 timeout"); quit(2))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V15)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay", Variants.apply(catalogs))
	var selection := service_for()
	for ball: StringName in V15_BALLS:
		check("permitted existing ball " + String(ball), catalogs.item(ball) != null and selection.selection.content_allowed(ball))
	# The headless run certifies the exhaustive rules/transaction matrix. GPU
	# runs the four real UI routes without repeating that nonvisual workload.
	if not capture:
		_matrix_v15()
		_rejections_v15()
		_storage_v15()
		_legacy_v15()
		await _native_v15()
		await _failed_routes_v15()
	for ball: StringName in V15_BALLS: await _field_v15(ball)
	var report := {"status":"PASS" if errors.is_empty() else "FAIL", "checks":checks, "errors":errors,
		"cases":cases,"successes":successes,"failures":failures,"routes":routes,"gpu":capture}
	var file := FileAccess.open(V15 + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	done = true
	print("ITEM_CAPTURE_V15 ",report.status," checks=",checks," cases=",cases," GPU=",capture)
	quit(0 if errors.is_empty() else 1)

func _p_v15(c: CreatureInstance, ball: StringName) -> float:
	var raw := float(catalogs.species(c.base_species_id()).capture_rate) / 255.0
	var factor := 1.5 if ball in [&"safari_ball",&"sport_ball"] else 1.0
	var bonus := 2.0 if c.status_state.persistent_id == &"sleep" else 1.0
	return minf(1.0,raw * factor * bonus * float(3*c.stats.max_hp-2*c.current_hp)/(3*c.stats.max_hp))

func _matrix_v15() -> void:
	var index := 0
	for sid: String in catalogs.variant_allowed_species:
		index += 1
		for ball: StringName in V15_BALLS:
			for asleep in [false,true]:
				for full_hp in [false,true]:
					var c := _prepared(StringName(sid),(index%100)+1,asleep)
					if full_hp: c.current_hp = c.stats.max_hp
					c.friendship = [0,149,199,200,255][index%5]
					var before := c.to_dict();var expected_p := _p_v15(c,ball)
					var rng := RandomNumberGenerator.new();rng.seed = index+1501
					var control := RandomNumberGenerator.new();control.state = rng.state
					var caught := control.randf() < expected_p
					var bag := PlayerInventory.new();bag.add(ball,3)
					var party := CreatureParty.new()
					var resolution := CaptureInventoryService.resolve(CaptureAttempt.new(c,ball,CaptureBattleContext.new()),rng,catalogs,party,bag)
					check("matrix probability " + sid + String(ball),is_equal_approx(resolution.result.probability,expected_p) and (resolution.result.status==CaptureResult.SUCCESS)==caught)
					check("matrix physical cost and RNG",resolution.result.consume_item and bag.quantity(ball)==2 and rng.state==control.state and party.size()==(1 if caught else 0))
					if caught and ball==&"friend_ball":before.friendship=200
					check("matrix only allowed catch change",c.to_dict()==before and (not caught or is_same(resolution.captured,c)))
					cases += 1
					if caught:successes += 1
					else:failures += 1
	check("matrix covers all 1076 eligible forms and four balls",index==1076 and cases==17216 and successes>0 and failures>0)

func _rejections_v15() -> void:
	for ball: StringName in V15_BALLS:
		for mode in 11:
			var c := _prepared(&"mew",50,false);var ctx := CaptureBattleContext.new()
			var bag := PlayerInventory.new();bag.add(ball,2)
			var party := CreatureParty.new();var rng := RandomNumberGenerator.new();rng.seed=1502
			match mode:
				0:ctx.is_wild=false
				1:ctx.battle_finished=true
				2:ctx.target_owner_trainer_id=&"trainer"
				3:c.current_hp=0
				4:bag.remove(ball,2)
				5:bag.corrupted=true
				6:c.level=0
				7:c.level=101
				8:c.current_hp=c.stats.max_hp+1
				9:c.status_state=null
				10:ctx=null
			# Null status cannot be serialized by the creature's snapshot helper.
			var before := c.to_dict() if c.status_state!=null else {}
			var state := rng.state;var inventory := bag.to_dict()
			var result := CaptureInventoryService.resolve(CaptureAttempt.new(c,ball,ctx),rng,catalogs,party,bag)
			check("invalid no cost " + String(ball)+str(mode),result.result.status==CaptureResult.INVALID and not result.result.consume_item and rng.state==state and bag.to_dict()==inventory and party.is_empty() and (c.to_dict()==before if c.status_state!=null else c.status_state==null))
	for value in [-1,256]:
		var c := _mon();c.friendship=value
		var bag := PlayerInventory.new();bag.add(&"friend_ball")
		var rng := RandomNumberGenerator.new();rng.seed=5;var state:=rng.state
		var result := CaptureInventoryService.resolve(CaptureAttempt.new(c,&"friend_ball",CaptureBattleContext.new()),rng,catalogs,CreatureParty.new(),bag)
		check("invalid friendship rejected before spending",result.result.reason=="invalid_ball_friendship_state" and bag.quantity(&"friend_ball")==1 and rng.state==state and c.friendship==value)
	for value in [0,149,199,200,255]:
		var c := _prepared(&"caterpie",1,true);c.current_hp=1;c.friendship=value
		var rng := RandomNumberGenerator.new();rng.seed=9
		var result := CaptureSystem.resolve(CaptureAttempt.new(c,&"friend_ball",CaptureBattleContext.new()),rng,catalogs,CreatureParty.new())
		check("Friend sets 200 rather than adding or clamping old friendship",result.result.status==CaptureResult.SUCCESS and c.friendship==200)
	for unsupported: StringName in [&"luxury_ball",&"repeat_ball",&"park_ball",&"banana_ball"]:
		check("context-dependent or unknown ball not enabled",not CaptureRuleset.new().is_known_ball(unsupported))
	# Sustituye la antigua expectativa "Net desconocida" por cobertura de las
	# probabilidades reales, el consumo de una unidad y la identidad capturada.
	check("Net is registered in shared capture rules", CaptureRuleset.new().is_known_ball(&"net_ball"))
	for row: Array in [[&"magikarp", 3.5], [&"caterpie", 3.5], [&"pidgey", 1.0]]:
		var sid: StringName = row[0]; var factor: float = row[1]
		var net_creature := _prepared(sid, 15, false)
		var net_species: CreatureSpecies = catalogs.species(sid)
		var net_before := net_creature.to_dict()
		var net_bag := PlayerInventory.new(); net_bag.add(&"net_ball", 2)
		var net_party := CreatureParty.new()
		var net_rng := RandomNumberGenerator.new(); net_rng.seed = 1503
		var expected_p := CaptureRuleset.new().catch_probability(net_species.capture_rate, factor, 1.0,
			net_creature.stats.max_hp, net_creature.current_hp)
		var net_resolution := CaptureInventoryService.resolve(CaptureAttempt.new(net_creature, &"net_ball", CaptureBattleContext.new()), net_rng, catalogs, net_party, net_bag)
		var was_caught := net_resolution.result.status == CaptureResult.SUCCESS
		check("Net species-based probability " + String(sid), is_equal_approx(net_resolution.result.probability, expected_p)
			and net_resolution.result.status != CaptureResult.INVALID and net_resolution.result.consume_item)
		check("Net uses one ball and preserves ownership " + String(sid), net_bag.quantity(&"net_ball") == 1
			and net_party.size() == (1 if was_caught else 0) and net_creature.to_dict() == net_before
			and (not was_caught or is_same(net_party.get_creature(net_creature.instance_id), net_creature)))

func _storage_v15() -> void:
	for ball: StringName in V15_BALLS:
		var party := CreatureParty.new()
		for i in 6:party.add_creature(_mon(&"mew",50,StringName("storage_own_"+str(i))))
		var c := _prepared(&"caterpie",1,true);c.current_hp=1;c.friendship=255
		var before := c.to_dict();var bag := PlayerInventory.new();bag.add(ball)
		var rng := RandomNumberGenerator.new();rng.seed=9
		var result := CaptureInventoryService.resolve(CaptureAttempt.new(c,ball,CaptureBattleContext.new()),rng,catalogs,party,bag)
		check("full party requests storage",result.result.status==CaptureResult.SUCCESS and result.disposition==CaptureDisposition.STORAGE_REQUIRED and party.size()==6 and bag.quantity(ball)==0)
		var storage := CreatureStorage.new();var routed := CaptureOwnershipRouter.new().route(result,party,storage)
		if ball==&"friend_ball":before.friendship=200
		check("catch effect precedes storage routing",routed.stored and is_same(storage.get_creature(c.instance_id),c) and c.to_dict()==before)
		check("storage snapshot retains friendship",CreatureInstance.from_dict(storage.get_creature(c.instance_id).to_dict()).friendship==before.friendship)

func _legacy_v15() -> void:
	for ball: StringName in V15_BALLS:
		var owner := PlayerCollection.new();owner.party.add_creature(_mon(&"mew",100,&"legacy_v15"));owner.inventory.add(ball,2)
		var table := WildEncounterTable.new(&"v15_route");table.add_slot(WildEncounterSlot.new(&"slot",&"caterpie",1,1,1))
		var rng := RandomNumberGenerator.new();rng.seed=15
		var session := WildAdventureSession.new(owner,catalogs,ProgressionRuleset.new())
		check("legacy starts",session.begin_encounter(table,rng).status==WildEncounterResult.ENCOUNTER)
		var wild := session.current_wild();wild.current_hp=1;status(wild,&"sleep");wild.friendship=255
		var result := session.capture_current(ball,rng)
		var caught := owner.owned_creature(wild.instance_id)
		check("legacy ball connection",result.resolution.result.status==CaptureResult.SUCCESS and caught!=null and caught.friendship==(200 if ball==&"friend_ball" else 255) and owner.inventory.quantity(ball)==1)

func _native_v15() -> void:
	for ball: StringName in V15_BALLS:
		for full_party in [false,true]:
			var owner := PlayerCollection.new();var own := _mon(&"mew",100,&"native_v15")
			own.moveset.clear();own.move_ids.clear();own.add_move(&"spore",catalogs);owner.party.add_creature(own)
			if full_party:
				for i in 5:owner.party.add_creature(_mon(&"mew",100,StringName("reserve_"+str(i))))
			owner.inventory.add(ball,2)
			var wild := _prepared(&"caterpie",1,false);wild.current_hp=1;wild.friendship=255
			var clocks := {};var session := FieldNative.new(catalogs,owner,clocks,"gen9calvounifiedv1")
			var opened: bool=await session.begin_wild(self,wild,[23,19,29,43])
			check("native begins four ball route: "+session.last_error,opened)
			if not opened:await session.close();continue
			var original := session.snapshot()
			check("stale capture has no publication",not (await session.capture(ball,session.revision+1)).accepted and session.snapshot()==original)
			check("native real sleep",(await session.submit("move 1",session.revision)).accepted and session.battle_state().creature(wild.instance_id).status_state.persistent_id==&"sleep")
			var saved := session.snapshot();await session.close()
			session=FieldNative.new(catalogs,owner,clocks,"gen9calvounifiedv1")
			check("restore before capture",await session.restore_saved(self,saved))
			var result: Dictionary=await session.capture(ball,session.revision)
			var caught := owner.owned_creature(wild.instance_id)
			check("native captured and published once",result.accepted and session.completion_reason=="CAPTURED" and caught!=null and owner.inventory.quantity(ball)==1)
			if caught!=null:
				# Save/IPC converts dictionary keys/numbers to JSON types. Compare
				# canonical serialized values, including every IV/EV, as saves do.
				var original_values:=wild.to_dict();var captured_values:=caught.to_dict()
				var preserved := {"friendship":caught.friendship==(200 if ball==&"friend_ball" else 255),"identity":caught.instance_id==wild.instance_id,"ivs":captured_values.ivs==original_values.ivs,"evs":captured_values.evs==original_values.evs,"shiny":caught.is_shiny,"nature":caught.nature_id==wild.nature_id,"hp":caught.current_hp==1,"pp_max":caught.moveset[0].max_pp==64}
				check("native friendship and original identity preserved "+JSON.stringify(preserved),not preserved.values().has(false))
				routes.append({"route":"canonical_capture_values","ball":String(ball),"full_party":full_party,"ivs_before":original_values.ivs,"ivs_after":captured_values.ivs,"evs_before":original_values.evs,"evs_after":captured_values.evs})
				check("sleep still belongs to captured creature",caught.status_state.persistent_id==&"sleep" and clocks.has(String(wild.instance_id)))
				check("native storage destination",owner.storage.contains_instance_id(wild.instance_id)==full_party and owner.party.size()==(6 if full_party else 2))
			var after := owner.inventory.to_dict()
			check("capture replay rejected without double spend",not (await session.capture(ball,session.revision)).accepted and owner.inventory.to_dict()==after)
			routes.append({"route":"native_success","ball":String(ball),"full_party":full_party})
			await session.close()

func _failed_routes_v15() -> void:
	for ball: StringName in V15_BALLS:
		var owner := PlayerCollection.new();owner.party.add_creature(_mon(&"mew",100,&"failed_v15"));owner.inventory.add(ball,2);owner.inventory.add(&"master_ball")
		var wild := _mon(&"mew",100,&"failed_wild_v15");wild.friendship=117
		var session := Native.new(catalogs,owner,"gen9calvounifiedv1")
		check("failed route opens",await session.begin_wild(self,wild,[23,19,29,43],1))
		var original := session.snapshot();var rng := RandomNumberGenerator.new();rng.state=int(original.adventure.capture_rng)
		check("failure draw selected without changing production RNG",rng.randf()>_p_v15(wild,ball))
		var before := JSON.stringify([owner.party.to_dict(),owner.inventory.to_dict()])
		var result: Dictionary=await session.capture(ball,session.revision)
		check("failure spends one staged ball and one turn",result.accepted and result.capture_result.status=="FAILED" and session.inventory.quantity(ball)==1 and session.battle_state().turn==1)
		check("failed capture leaves campaign and friendship intact",JSON.stringify([owner.party.to_dict(),owner.inventory.to_dict()])==before and session.battle_state().creature(wild.instance_id).friendship==117)
		var saved := session.snapshot();check("one draw recorded",saved.adventure.capture_rng==str(rng.state) and saved.adventure.spent_items[String(ball)]==1)
		await session.close();session=Native.new(catalogs,owner,"gen9calvounifiedv1")
		check("failure snapshot restores",await session.restore_saved(self,saved))
		check("master settles failed cost",(await session.capture(&"master_ball",session.revision)).accepted and owner.inventory.quantity(ball)==1 and owner.inventory.quantity(&"master_ball")==0)
		check("failed Friend ball grants no later friendship",owner.owned_creature(wild.instance_id).friendship==117)
		routes.append({"route":"failed_restore_master","ball":String(ball)})
		await session.close()

func _field_v15(ball: StringName) -> void:
	scene=load("res://scenes/visual/field_demo.tscn").instantiate();root.add_child(scene)
	await process_frame;await physics_frame
	var config: Dictionary=scene._active_config.duplicate(true)
	config.encounter_chance_percent=100;config.wild_species_id="caterpie";config.wild_min_level=5;config.wild_max_level=5
	scene._on_configuration_applied(config)
	var owner: PlayerCollection=scene.field_collection();var own_id:=owner.party.get_creatures()[0].instance_id
	var c:=_mon(&"mew",100,own_id);c.moveset.clear();c.move_ids.clear();c.add_move(&"false_swipe",catalogs);c.add_move(&"spore",catalogs)
	check("field owner replaced by stable identity",owner.replace_owned_same_identity(c))
	owner.inventory.add(ball,8)
	var bridge=scene._native_battles;bridge.save_path=V15+("gpu_" if capture else "headless_")+String(ball)+".json"
	check("field inventory saves",bridge.save_game());check("field inventory restores",await bridge.load_game())
	var before: int=scene.field_collection().inventory.quantity(ball)
	scene.player.global_position=Vector2(420,150);await scene._on_player_step_completed(scene.player.global_position)
	var view=bridge.view;view._playback.set_process(false)
	var ready: bool=view.session!=null and view.session.battle_state()!=null
	check("field battle begins: "+bridge.last_error,ready)
	if not ready:scene.queue_free();await process_frame;return
	var wild_id: StringName=view.session.battle_state().active_for_side(&"side_b").instance_id
	var original_friendship: int=view.session.battle_state().creature(wild_id).friendship
	check("native False Swipe leaves living target",(await view.choose("move 1")).accepted and view.session.battle_state().creature(wild_id).current_hp==1)
	await _drain(view)
	check("native Spore establishes capture sleep",(await view.choose("move 2")).accepted and view.session.battle_state().creature(wild_id).status_state.persistent_id==&"sleep")
	await _drain(view)
	check("field prepared capture checkpoint saves",bridge.save_game())
	var restored: bool=await bridge.load_game()
	check("field prepared capture checkpoint restores: "+bridge.last_error,restored)
	if not restored:
		if view.session!=null:await view.session.close()
		scene.queue_free();await process_frame;return
	view._playback.set_process(false)
	check("picker has all supported balls",view._capture_balls.item_count==CaptureRuleset.ordered_ball_ids().size()-1)
	for i in view._capture_balls.item_count:
		if view._capture_balls.get_item_metadata(i)==String(ball):view._capture_balls.select(i)
	view._refresh_view()
	check("picker selects actual owned item",view._capture_balls.selected_ball()==ball and not view._ball.disabled)
	if capture and ball==&"friend_ball":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		check("four ball picker capture",root.get_texture().get_image().save_png(V15+"friend_selector.png")==OK)
		check("ball controls fit viewport",view._ball.get_global_rect().end.x<=root.size.x and view._ball.get_global_rect().end.y<=root.size.y)
	var result: Dictionary=await view.adventure_command("ball")
	check("picker command captures with chosen ball",result.accepted and view.session.completion_reason=="CAPTURED" and result.get("capture_outcome",{}).get("capture",{}).get("result",{}).get("ball_id")==String(ball))
	await _drain(view);await bridge.leave_battle()
	owner=scene.field_collection();var caught:=owner.owned_creature(wild_id)
	check("field catch cost and friendship",owner.inventory.quantity(ball)==before-1 and caught!=null and caught.friendship==(200 if ball==&"friend_ball" else original_friendship))
	check("field final save",bridge.save_game());check("field final load",await bridge.load_game())
	check("field final persistence",scene.field_collection().inventory.quantity(ball)==before-1 and scene.field_collection().owned_creature(wild_id).friendship==(200 if ball==&"friend_ball" else original_friendship))
	routes.append({"route":"field_picker_save_load","ball":String(ball)})
	if view.session!=null:await view.session.close()
	scene.queue_free();await process_frame
