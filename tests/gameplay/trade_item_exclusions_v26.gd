extends "res://tests/gameplay/field_held_v16.gd"

const V26 := "res://.godot/trade_item_exclusions_v26/"
const EXCLUDED := {"dragon_scale":"seadra", "dubious_disc":"porygon2", "electirizer":"electabuzz", "magmarizer":"magmar", "prism_scale":"feebas", "protector":"rhydon", "reaper_cloth":"dusclops", "sachet":"spritzee", "up_grade":"porygon", "whipped_dream":"swirlix"}
const REASON := "trade_evolution_item_not_needed_in_level_evolution_design"


func _initialize() -> void:
	call_deferred("_run")
	create_timer(90).timeout.connect(func():
		if not done: push_error("TRADE_ITEM_EXCLUSIONS_V26 timeout"); quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/item_audit_v1/")
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	for raw_id: String in EXCLUDED:
		var id:=StringName(raw_id); var c:=_make(StringName(EXCLUDED[raw_id]),40)
		var service:=_service(c,id);var before:=snapshot(service)
		check("excluded reason "+raw_id,service.selection.exclusion_reason(id)==REASON)
		check("no generation even if offered supported "+raw_id,not service.selection.can_generate(id,{raw_id:true}))
		check("no held eligibility "+raw_id,not service.holdable(id))
		var used: Dictionary=service.use_item(id,c.instance_id)
		check("use blocked by policy "+raw_id,not used.accepted and used.reason==REASON and snapshot(service)==before)
		var equipped: Dictionary=service.equip(id,c.instance_id)
		check("equip blocked by policy "+raw_id,not equipped.accepted and equipped.reason==REASON and snapshot(service)==before)
		var evolved: Dictionary=service.evolve(id,c.instance_id)
		check("evolution API cannot bypass policy "+raw_id,not evolved.accepted and evolved.reason==REASON and snapshot(service)==before)
		check("legacy inventory preserved "+raw_id,service.owner.inventory.quantity(id)==3 and catalogs.item(id)!=null)
		check("no level replacement introduced "+raw_id,EvolutionSystem.evolution_candidates(catalogs.species(c.species_id),{"level":1},catalogs).is_empty())
	for id: StringName in [&"metal_coat",&"kings_rock",&"deep_sea_tooth",&"deep_sea_scale"]:
		var c:=_make();var service:=_service(c,id)
		check("combat-role item remains equipable "+String(id),service.selection.content_allowed(id) and service.equip(id,c.instance_id).accepted and c.held_item_id==id)
	var c:=_make(&"vulpix",20);var service:=_service(c,&"fire_stone")
	check("ordinary stone evolution retained",service.use_item(&"fire_stone",c.instance_id).accepted and service.owner.owned_creature(c.instance_id).species_id==&"ninetales")
	check("ordinary level evolution retained",EvolutionSystem.evolution_candidates(catalogs.species(&"charmander"),{"level":16},catalogs).size()==1)
	check("Haunter level 100 is still unchanged",EvolutionSystem.evolution_candidates(catalogs.species(&"haunter"),{"level":100},catalogs).is_empty())
	var report: Dictionary={"status":"PASS" if errors.is_empty() else "FAIL","checks":checks,"errors":errors}
	var file:=FileAccess.open(V26+"exclusions.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("TRADE_ITEM_EXCLUSIONS_V26 ",report.status," checks=",checks);quit(0 if errors.is_empty() else 1)
