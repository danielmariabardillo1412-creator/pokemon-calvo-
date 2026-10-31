extends "res://tests/gameplay/field_held_v16.gd"

const V27 := "res://.godot/trade_item_restoration_v27/"
const RESTORED := {"dragon_scale":"seadra", "dubious_disc":"porygon2", "electirizer":"electabuzz", "magmarizer":"magmar", "prism_scale":"feebas", "protector":"rhydon", "reaper_cloth":"dusclops", "sachet":"spritzee", "up_grade":"porygon", "whipped_dream":"swirlix"}


func _initialize() -> void:
	call_deferred("_run")
	create_timer(90).timeout.connect(func():
		if not done: push_error("TRADE_ITEM_RESTORATION_V27 timeout"); quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/item_audit_v1/")
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	for raw_id: String in RESTORED:
		var id:=StringName(raw_id);var c:=_make(StringName(RESTORED[raw_id]),40)
		var service:=_service(c,id);var original:=c.to_dict()
		check("content restored "+raw_id,service.selection.content_allowed(id) and service.selection.exclusion_reason(id).is_empty())
		check("generation permission restored with explicit support "+raw_id,service.selection.can_generate(id,{raw_id:true}))
		check("holdable restored "+raw_id,service.holdable(id))
		check("real equip restored "+raw_id,service.equip(id,c.instance_id).accepted and c.held_item_id==id and service.owner.inventory.quantity(id)==2)
		var equipped:=original.duplicate(true);equipped.held_item_id=raw_id;equipped.held_item_consumed=false
		check("equipping does not evolve or mutate other data "+raw_id,c.to_dict()==equipped)
		check("original held requirement retained "+raw_id,_has_held_trade_requirement(c.species_id,id))
		check("unequip keeps player control and units "+raw_id,service.unequip(c.instance_id).accepted and c.to_dict()==original and service.owner.inventory.quantity(id)==3)
		check("no provisional level conversion "+raw_id,EvolutionSystem.evolution_candidates(catalogs.species(c.species_id),{"level":100},catalogs).is_empty())
	var c:=_make(&"onix",40);var service:=_service(c,&"metal_coat")
	check("Onix Metal Coat preserved",service.equip(&"metal_coat",c.instance_id).accepted and _has_held_trade_requirement(&"onix",&"metal_coat"))
	check("Onix does not evolve automatically at a guessed level",c.species_id==&"onix" and EvolutionSystem.evolution_candidates(catalogs.species(&"onix"),{"level":100},catalogs).is_empty())
	check("Onix can remove Metal Coat",service.unequip(c.instance_id).accepted and c.species_id==&"onix")
	for id: StringName in [&"kings_rock",&"deep_sea_tooth",&"deep_sea_scale"]:
		check("other held evolution items remain permitted "+String(id),service.selection.content_allowed(id))
	service.owner.inventory.add(&"linking_cord")
	var before:=snapshot(service)
	check("Linking Cord remains excluded",not service.selection.content_allowed(&"linking_cord") and not service.holdable(&"linking_cord") and not service.selection.can_generate(&"linking_cord",{"linking_cord":true}))
	check("Linking Cord cannot evolve",not service.use_item(&"linking_cord",c.instance_id).accepted and snapshot(service)==before)
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors}
	var file:=FileAccess.open(V27+"restoration.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("TRADE_ITEM_RESTORATION_V27 ",report.status," checks=",checks);quit(0 if errors.is_empty() else 1)


func _has_held_trade_requirement(source: StringName, item: StringName) -> bool:
	for record: EvolutionRecord in catalogs.species(source).evolutions:
		if record.trigger==EvolutionSystem.TRIGGER_TRADE and StringName(record.conditions.get("held_item",""))==item:return true
	return false
