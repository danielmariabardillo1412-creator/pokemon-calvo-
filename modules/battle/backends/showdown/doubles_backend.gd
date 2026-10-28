extends "res://modules/battle/backends/showdown/showdown_backend.gd"

## Two native active slots per side; never execute this mirror with singles rules.
const FORMAT := "gen9doublescustomgame"


func _init(catalog: DefinitionCatalog, p_format: String = FORMAT) -> void:
	super(catalog, p_format)


func backend_id() -> String:
	return "showdown_doubles_v1"


func format_supported() -> bool:
	return format_id in [FORMAT, "gen9calvounifieddoublesv1"]


func open(tree: SceneTree, a: Array[CreatureInstance], b: Array[CreatureInstance], seed: Array = [1, 2, 3, 4]) -> bool:
	if a.size() < 2 or b.size() < 2: last_error = "two_initial_actives_required"; return false
	return await super.open(tree, a, b, seed)


func _valid_saved_origin(value: Variant) -> bool:
	return super._valid_saved_origin(value) and value.p1.size() >= 2 and value.p2.size() >= 2


func phase() -> String:
	if needs_recovery: return "interrupted"
	if _checkpoint.is_empty(): return "closed"
	if _checkpoint.views.p1.ended: return "finished"
	for side: String in ["p1", "p2"]:
		if true in request(side).get("forceSwitch", []): return "replacement"
	return "move"


func active_ids(side: String) -> Array:
	for row: Dictionary in _checkpoint.get("roster", []):
		if row.id == side: return row.get("active_ids", []).duplicate()
	return []


func _mirror(data: Dictionary) -> BattleState:
	var state := super._mirror(data)
	if state == null: return null
	state.active_ids.clear()
	for side: Dictionary in data.roster:
		if not side.get("active_ids") is Array or side.active_ids.size() != 2: last_error = "doubles_active_shape"; return null
		var seen := {}
		var own: BattleSide = state.sides[0 if side.id == "p1" else 1]
		own.active_id = StringName(side.active_ids[0])
		for id: String in side.active_ids:
			if id.is_empty(): continue
			if seen.has(id) or not own.owns(StringName(id)): last_error = "doubles_active_identity"; return null
			seen[id] = true; state.active_ids.append(StringName(id))
	if not data.views.p1.ended and (true in data.views.p1.request.get("forceSwitch", []) if data.views.p1.request is Dictionary else false): state.phase = BattleState.WAITING_FOR_SWITCH
	return state


func submit(_choice: String, _revision: int) -> Dictionary:
	return {"accepted": false, "error": "doubles_pair_required", "events": []}


func submit_pair(choices: Dictionary, expected_revision: int) -> Dictionary:
	if busy or needs_recovery or _client == null or expected_revision != revision or phase() == "finished": return {"accepted": false, "error": "busy_stale_or_finished", "events": []}
	var required := {}
	for side: Variant in choices:
		if side not in ["p1", "p2"]: return {"accepted": false, "error": "unknown_side", "events": []}
	for side: String in ["p1", "p2"]:
		var req := request(side)
		if not req.is_empty() and not req.get("wait", false):
			if not choices.get(side) is String: return {"accepted": false, "error": "missing_side_choice", "events": []}
			# Special-mechanic profiles are separate work, not implicit doubles support.
			var unsupported := ["mega", "terastallize", "ultra"] if format_id == "gen9calvounifieddoublesv1" else ["zmove", "dynamax", "mega", "terastallize", "ultra"]
			for word: String in unsupported:
				if word in String(choices[side]).to_lower(): return {"accepted": false, "error": "special_mechanic_profile_pending", "events": []}
			required[side] = choices[side]
	if required.is_empty(): return {"accepted": false, "error": "no_choice_requested", "events": []}
	busy = true
	return await _submit_choices(required)


func submit_reaction(_kind: String, _revision: int) -> Dictionary:
	return {"accepted": false, "error": "singles_adventure_only", "events": []}


func submit_medicine(_command: Dictionary, _revision: int) -> Dictionary:
	return {"accepted": false, "error": "singles_adventure_only", "events": []}


## Signed positions are native targets: positive opponent, negative own side.
## The native engine remains the final validator, including redirection.
func targets(side: String, active_slot: int, target_kind: String) -> Array:
	if target_kind not in ["normal", "any", "adjacentAlly", "adjacentAllyOrSelf", "adjacentFoe"]: return [{"location": 0, "label": "Automático"}]
	var options: Array = []
	for own: bool in [true, false]:
		var target_side := side if own else ("p2" if side == "p1" else "p1")
		var ids := active_ids(target_side)
		for i in ids.size():
			if String(ids[i]).is_empty(): continue
			var creature := presentation_state.creature(StringName(ids[i]))
			if creature == null or creature.is_knocked_out(): continue
			if own and (target_kind == "adjacentFoe" or i == active_slot and target_kind != "adjacentAllyOrSelf"): continue
			if not own and target_kind in ["adjacentAlly", "adjacentAllyOrSelf"]: continue
			options.append({"location": -(i + 1) if own else i + 1, "label": ("Aliado " if own else "Rival ") + str(i + 1) + " · " + SpanishGameText.creature_name(creature, _catalog)})
	return options
