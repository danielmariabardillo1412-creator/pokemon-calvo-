extends RefCounted

## Selection boundary, separate from canonical definitions and mechanics support.
const CONFIG_PATH := "res://config/randomlock_content_v1.json"
const DATA_PATH := "res://data/normalized/pokemon_api.json"
var errors: Array[String] = []
var _known: Dictionary = {}
var _denied_moves: Dictionary = {}
var _denied: Dictionary = {}
var _z: Dictionary = {}
var _z_status: Dictionary = {}
var _max: Dictionary = {}
var _z_decision := "pending"
var valid := false


static func canonical_id(value: String) -> String:
	return value.strip_edges().to_lower().replace("-", "_")


func load_local() -> bool:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not config is Dictionary or not data is Dictionary:
		errors.assign(["Missing/invalid content policy or normalized data"])
		valid = false
		return false
	return configure(config, data)


func configure(config: Dictionary, data: Dictionary) -> bool:
	valid = false
	errors.clear()
	_known.clear()
	_denied_moves.clear()
	_denied.clear()
	_z.clear()
	_z_status.clear()
	_max.clear()
	if config.get("version") != 1 or config.get("profile_id") != "randomlock_v1":
		errors.append("Unsupported content policy version/profile")
	for kind: String in ["moves", "abilities", "species"]:
		var entries: Variant = data.get(kind)
		_known[kind] = {}
		if not entries is Dictionary or entries.is_empty():
			errors.append("Missing canonical catalog: " + kind)
			continue
		for id: String in entries:
			_known[kind][id] = true
	var groups: Variant = config.get("move_exclusions")
	if not groups is Array or groups.is_empty():
		errors.append("Missing move exclusion groups")
	else:
		for group: Variant in groups:
			if not group is Dictionary or String(group.get("reason", "")).is_empty():
				errors.append("Invalid move exclusion reason")
				continue
			var presence := String(group.get("presence", ""))
			if presence not in ["required", "optional_future_import"]:
				errors.append("Invalid exclusion presence")
			var ids := _id_set(group.get("ids"), "move exclusions")
			for id: String in ids:
				if _denied_moves.has(id):
					errors.append("Duplicate move exclusion: " + id)
				_denied_moves[id] = group.reason
				if presence == "required" and not _known.moves.has(id):
					errors.append("Unknown required excluded move: " + id)
	for pair: Array in [["abilities", "excluded_ability_ids"], ["species", "excluded_species_ids"], ["forms", "excluded_form_ids"]]:
		var kind: String = pair[0]
		_denied[kind] = _id_set(config.get(pair[1]), pair[1])
		if kind != "forms":
			for id: String in _denied[kind]:
				if not _known[kind].has(id):
					errors.append("Unknown excluded " + kind + ": " + id)
	var z_config: Variant = config.get("z_moves")
	if not z_config is Dictionary:
		errors.append("Missing Z decision")
	else:
		_z_decision = String(z_config.get("decision", ""))
		if _z_decision not in ["pending", "include", "exclude", "damage_only"]:
			errors.append("Invalid Z decision")
		_z = _id_set(z_config.get("ids"), "Z IDs")
		for id: String in _z:
			# Explicit per-move bans take precedence over the general Z decision.
			# Keep all canonical Z IDs in the research inventory, including bans.
			if not _known.moves.has(id):
				errors.append("Unknown Z ID: " + id)
			elif String(data.moves[id].get("damage_class", "")) == "status":
				_z_status[id] = true
	var protected := _id_set(config.get("protected_max_move_ids"), "protected Max IDs")
	_max = protected
	for id: String in protected:
		if not _known.moves.has(id) or _denied_moves.has(id) or _z.has(id):
			errors.append("Unknown/blocked protected Max move: " + id)
	valid = errors.is_empty()
	return valid


func _id_set(value: Variant, label: String) -> Dictionary:
	var result: Dictionary = {}
	if not value is Array or value.is_empty():
		errors.append("Missing ID list: " + label)
		return result
	for item: Variant in value:
		if not item is String or item.is_empty() or item != canonical_id(item):
			errors.append("Noncanonical ID in " + label)
			continue
		if result.has(item):
			errors.append("Duplicate ID in " + label + ": " + item)
		result[item] = true
	return result


func move_state(id: String) -> String:
	if not valid:
		return "invalid_policy"
	id = canonical_id(id)
	if _denied_moves.has(id):
		return "excluded"
	if not _known.moves.has(id):
		return "unknown"
	if _z.has(id):
		if _z_decision == "pending":
			return "pending"
		if _z_decision == "exclude":
			return "excluded"
		if _z_decision == "damage_only" and _z_status.has(id):
			return "excluded"
	return "eligible"


func move_allowed(id: String) -> bool:
	return move_state(id) == "eligible"


func z_status_allowed() -> bool:
	return valid and _z_decision == "include"


## Special actions are generated in battle, never ordinary learned slots.
func move_learnable(id: String) -> bool:
	id = canonical_id(id)
	return move_allowed(id) and not _z.has(id) and not _max.has(id)


func ability_allowed(id: String) -> bool:
	return _catalog_allowed("abilities", id)


func species_allowed(id: String) -> bool:
	return _catalog_allowed("species", id)


func _catalog_allowed(kind: String, id: String) -> bool:
	id = canonical_id(id)
	return valid and _known[kind].has(id) and not _denied[kind].has(id)


## Caller supplies the canonical base species; form ownership belongs to the
## future form catalog. Empty form means the base form, not an unknown species.
func form_allowed(species_id: String, form_id: String = "") -> bool:
	return species_allowed(species_id) and not _denied.forms.has(canonical_id(form_id))


## Future randomizers must draw from these IDs before applying runtime/support,
## level, evolution and special-move rules. This does not randomize learnsets.
func eligible_ids(kind: String) -> Array[String]:
	var result: Array[String] = []
	if not valid or not _known.has(kind):
		return result
	for id: String in _known[kind]:
		if (kind == "moves" and move_allowed(id)) or (kind != "moves" and _catalog_allowed(kind, id)):
			result.append(id)
	result.sort()
	return result


func partition_move_ids(ids: Array) -> Dictionary:
	var result := {"eligible": [], "excluded": [], "pending": [], "unknown": [], "invalid_policy": []}
	for value: Variant in ids:
		var id := canonical_id(String(value))
		var bucket: Array = result[move_state(id)]
		if id not in bucket:
			bucket.append(id)
	for bucket: Array in result.values():
		bucket.sort()
	return result
