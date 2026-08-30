class_name SpanishTypeResourcesTestSuite
extends RefCounted


func run(check_callback: Callable) -> void:
	var all_loaded := true
	var all_match := true
	for type_id in PokemonTypeChart.STANDARD_TYPE_IDS:
		var resource := load("res://data/types/%s.tres" % String(type_id)) as TypeDefinition
		if resource == null:
			all_loaded = false
			all_match = false
			continue
		var canonical := PokemonTypeChart.definition(type_id)
		if canonical == null or resource.to_dict() != canonical.to_dict():
			all_match = false
	check_callback.call("types_all_18_resource_files_load", all_loaded)
	check_callback.call("types_resource_files_match_canonical_chart", all_match)
