extends "res://tests/gameplay/field_held_v16.gd"

const V25 := "res://.godot/item_scope_v25/"


func _initialize() -> void:
	call_deferred("_run")
	create_timer(90).timeout.connect(func():
		if not done:push_error("ITEM_SCOPE_V25 timeout");quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/item_audit_v1/")
	catalogs=GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("regional overlay",Variants.apply(catalogs))
	var c:=_make(&"haunter",40)
	var service:=_service(c,&"linking_cord")
	var before:=snapshot(service)
	check("Cord is explicitly excluded",not service.selection.content_allowed(&"linking_cord"))
	check("cannot generate even when offered as supported",not service.selection.can_generate(&"linking_cord",{"linking_cord":true}))
	check("not equipable",not service.holdable(&"linking_cord"))
	check("direct use rejects without mutation",not service.use_item(&"linking_cord",c.instance_id).accepted and snapshot(service)==before)
	check("direct evolve cannot bypass policy",not service.evolve(&"linking_cord",c.instance_id,&"gengar").accepted and snapshot(service)==before)
	check("equip cannot bypass policy",not service.equip(&"linking_cord",c.instance_id).accepted and snapshot(service)==before)
	check("no Cord preview route remains",service.evolution_options(&"linking_cord",c.instance_id).is_empty())
	check("no provisional level evolution was introduced",EvolutionSystem.evolution_candidates(catalogs.species(&"haunter"),{"level":100},catalogs).is_empty())
	check("canonical trade record remains data",EvolutionSystem.evolution_candidates(catalogs.species(&"haunter"),{"traded":true},catalogs).size()==1)
	var ordinary:=EvolutionSystem.evolution_candidates(catalogs.species(&"charmander"),{"level":16},catalogs)
	check("ordinary level evolution remains",ordinary.size()==1 and ordinary[0].species_id==&"charmeleon")
	var normal:=_make(&"vulpix",20);service=_service(normal,&"fire_stone")
	check("ordinary stone remains usable",service.use_item(&"fire_stone",normal.instance_id).accepted and service.owner.owned_creature(normal.instance_id).species_id==&"ninetales")
	for id: StringName in [&"metal_coat",&"kings_rock",&"deep_sea_tooth",&"deep_sea_scale",&"poke_doll"]:
		check("other meaningful role retained "+String(id),service.selection.content_allowed(id))
	for id: StringName in [&"cleanse_tag",&"pure_incense"]:
		service.owner.inventory.add(id);var frozen:=snapshot(service)
		var result: Dictionary=service.use_item(id,normal.instance_id)
		check("passive hint correction preserved "+String(id),not result.accepted and result.reason=="equip_for_passive_effect" and snapshot(service)==frozen)
	for path: String in ["res://modules/inventory/linking_cord_effects.gd","res://modules/inventory/linking_cord_profile_v24.json"]:
		check("unused adapter retired "+path,not FileAccess.file_exists(path))
	var report: Dictionary={"status":"PASS"if errors.is_empty()else"FAIL","checks":checks,"errors":errors}
	var file:=FileAccess.open(V25+"withdrawal.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	done=true;print("ITEM_SCOPE_V25 ",report.status," checks=",checks);quit(0 if errors.is_empty()else 1)
