extends SceneTree

const Policy = preload("res://modules/inventory/item_selection_policy.gd")
const OUT := "res://.godot/item_audit_v1/"
var checks := 0
var errors: Array[String] = []


func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Policy.PATH))
	var original := JSON.stringify(data.items)
	var policy := Policy.new()
	check("complete item policy loads", policy.configure(config, data.items))
	var excluded: Array[String] = []
	for id: String in data.items:
		if not policy.content_allowed(StringName(id)): excluded.append(id)
	check("exact confirmed scope is 54 IDs", excluded.size() == 54)
	for id: String in ["revive", "max_revive", "revival_herb", "sacred_ash", "max_honey", "bright_powder", "wide_lens", "dream_mail", "linking_cord",
		"dragon_scale", "dubious_disc", "electirizer", "magmarizer", "prism_scale", "protector", "reaper_cloth", "sachet", "up_grade", "whipped_dream"]:
		check("confirmed ban cannot enter even a supported pool " + id, not policy.can_generate(StringName(id), {id: true}) and not policy.exclusion_reason(StringName(id)).is_empty())
	check("no additional evasion ban inferred", policy.content_allowed(&"lax_incense"))
	check("functional Poke Doll is not classified as decoration", policy.content_allowed(&"poke_doll"))
	check("undefined IDs fail closed", not policy.content_allowed(&"not_an_item") and not policy.can_generate(&"not_an_item", {"not_an_item": true}))
	check("content permission alone never enables an unsupported item", policy.content_allowed(&"tm01") and not policy.can_generate(&"tm01", {}))
	check("implemented allowed item needs explicit support", policy.can_generate(&"leftovers", {"leftovers": true}) and not policy.can_generate(&"leftovers", {"leftovers": false}))
	check("configuration never edits canonical definitions", JSON.stringify(data.items) == original)
	var bad := config.duplicate(true); bad.excluded_ids["typo_item"] = "revive"
	check("misspelled ban fails policy instead of being ignored", not Policy.new().configure(bad, data.items))
	bad = config.duplicate(true); bad.excluded_categories["typo_category"] = "decorative"
	check("misspelled category fails policy", not Policy.new().configure(bad, data.items))
	bad = config.duplicate(true); bad.schema_version = 999
	var rejected := Policy.new()
	check("invalid policy cannot generate anything", not rejected.configure(bad, data.items) and not rejected.can_generate(&"leftovers", {"leftovers": true}))
	var file := FileAccess.open(OUT + "selection_policy.json", FileAccess.WRITE)
	excluded.sort(); file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "excluded_ids": excluded}, "  ")); file.close()
	print("ITEM_SELECTION_POLICY ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " excluded=", excluded.size()); quit(0 if errors.is_empty() else 1)


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)
