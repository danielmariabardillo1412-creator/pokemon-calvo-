extends "res://tests/gameplay/field_held_v16.gd"

const V17 := "res://.godot/field_held_v17/"
const TRAINING_IDS: Array[StringName]=[&"calcium",&"carbos",&"hp_up",&"iron",&"pp_max",&"pp_up",&"protein",&"rare_candy",&"zinc"]
const BOOST_IDS: Array[StringName]=[&"dire_hit",&"guard_spec",&"x_accuracy",&"x_attack",&"x_defense",&"x_sp_atk",&"x_sp_def",&"x_speed"]

func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	call_deferred("_run")
	create_timer(300).timeout.connect(func():
		if not done:push_error("FIELD_HELD_V17 timeout");quit(2))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(V17)
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	if not capture:
		var ids: Array[StringName]=[];ids.append_array(TRAINING_IDS);ids.append_array(BOOST_IDS)
		for i in ids.size():await _medicine_case(ids[i],["keep","fling","trick","knock_off"][i%4],TRAINING_IDS.has(ids[i]))
	for pair: Array in [["protein","keep"],["pp_up","fling"],["calcium","trick"],["x_attack","keep"]]:await _map_training(StringName(pair[0]),pair[1])
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors,"routes":routes,"gpu":capture}
	var file:=FileAccess.open(V17+("gpu.json" if capture else "godot.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("FIELD_HELD_V17 ",report.status," checks=",checks," GPU=",capture)
	quit(0 if errors.is_empty() else 1)

func _map_training(id: StringName,route: String) -> void:
	scene=load("res://scenes/visual/field_demo.tscn").instantiate();root.add_child(scene)
	await process_frame;await physics_frame
	var config: Dictionary=scene._active_config.duplicate(true)
	config.encounter_chance_percent=100;config.wild_species_id="wailord";config.wild_min_level=50;config.wild_max_level=50
	scene._on_configuration_applied(config)
	var owner: PlayerCollection=scene.field_collection();var own_id:=owner.party.get_creatures()[0].instance_id
	var c:=_with_moves(own_id,["growl","fling","trick"],false);c.friendship=100
	check("map training owner",owner.replace_owned_same_identity(c))
	owner.inventory.add(id,3);owner.inventory.add(&"master_ball",2)
	var initial:=_physical_medicine(owner,id);var before:=c.to_dict()
	check("map training bag opens",scene.toggle_item_bag());var bag=scene._item_bag
	_select(bag,String(id));check("map equips real training item",bag._apply("equip").accepted and _physical_medicine(owner,id)==initial)
	check("equip changes no training data",owner.owned_creature(own_id).friendship==100 and owner.owned_creature(own_id).to_dict().evs==before.evs and owner.owned_creature(own_id).moveset[0].max_pp==int(before.moveset[0].max_pp))
	bag.hide();await process_frame
	var bridge=scene._native_battles;bridge.save_path=V17+("gpu_" if capture else "headless_")+String(id)+".json"
	check("training field save",bridge.save_game());check("training field load",await bridge.load_game())
	scene.player.global_position=Vector2(420,150);await scene._on_player_step_completed(scene.player.global_position)
	var view=bridge.view;view._playback.set_process(false)
	var ready: bool=view.session!=null and view.session.battle_state()!=null
	check("map training enters native: "+bridge.last_error,ready)
	if not ready:scene.queue_free();await process_frame;return
	var choice: String={"keep":"move 1","fling":"move 2","trick":"move 3"}[route]
	var result: Dictionary=await view.choose(choice);check("map training native action",result.accepted)
	if not result.accepted:await view.session.close();scene.queue_free();await process_frame;return
	await _drain_view(view)
	check("training changed-state save",bridge.save_game())
	var loaded: bool=await bridge.load_game();check("training changed-state load: "+bridge.last_error,loaded)
	if not loaded:await view.session.close();scene.queue_free();await process_frame;return
	view._playback.set_process(false)
	check("training encounter capture",(await view.adventure_command("master")).accepted)
	await _drain_view(view);await bridge.leave_battle()
	owner=scene.field_collection();var expected:=initial-(1 if route=="fling" else 0)
	check("map training physical count",_physical_medicine(owner,id)==expected)
	check("holding grants no friendship or EV gains",owner.owned_creature(own_id).friendship==100 and owner.owned_creature(own_id).to_dict().evs==before.evs)
	check("post-battle training bag opens",scene.toggle_item_bag());bag=scene._item_bag
	_select(bag,String(id))
	if id==&"pp_up":bag._moves.select(1)
	var before_use:=snapshot(bag.service)
	var used: Dictionary=bag._apply("use")
	var target:=owner.owned_creature(own_id)
	if id==&"x_attack":
		check("X Attack field use remains rejected without spending",not used.accepted and snapshot(bag.service)==before_use and _physical_medicine(owner,id)==expected)
	else:
		check("explicit training use succeeds",used.accepted and _physical_medicine(owner,id)==expected-1 and target.friendship==103)
		if id==&"protein":check("Protein grants exactly ten attack EVs",int(target.evs.attack)==10)
		if id==&"calcium":check("Calcium grants exactly ten special attack EVs",int(target.evs.special_attack)==10)
		if id==&"pp_up":check("PP Up uses existing max-PP rule",target.moveset[0].max_pp==48 and target.moveset[0].current_pp==48)
	if capture and id==&"pp_up":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		check("training bag screenshot",root.get_texture().get_image().save_png(V17+"training_bag.png")==OK)
		check("training bag fits viewport",bag.position.y>=0 and bag.position.y+bag.size.y<=root.size.y)
	bag.hide();await process_frame
	check("final training save",bridge.save_game());check("final training load",await bridge.load_game())
	var saved: CreatureInstance=scene.field_collection().owned_creature(own_id)
	check("final training item count persists",_physical_medicine(scene.field_collection(),id)==expected-(0 if id==&"x_attack" else 1))
	check("final training data persists",saved.friendship==(100 if id==&"x_attack" else 103) and saved.to_dict().evs==target.to_dict().evs and saved.moveset[0].max_pp==target.moveset[0].max_pp)
	routes.append({"item_id":String(id),"route":"map_"+route,"field_use_supported":id!=&"x_attack","physical_remaining":expected-(0 if id==&"x_attack" else 1)})
	if view.session!=null:await view.session.close()
	scene.queue_free();await process_frame
