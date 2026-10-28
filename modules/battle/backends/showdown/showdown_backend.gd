extends RefCounted

# Shared native backend for the ordinary map and labs. Snapshots are authority;
# BattleState is a detached projection for the existing Godot presentation only.
const PipeClient = preload("res://modules/battle/backends/showdown/pipe_client.gd")
const Adapter = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const Policy = preload("res://modules/gameplay/randomlock_content_policy.gd")
const BACKEND := "showdown_singles_v1"
const VERSION := "0.10.11"
var presentation_state: BattleState
var last_error := ""
var revision := 0
var busy := false
var needs_recovery := false
var _client: RefCounted
var _tree: SceneTree
var _catalog: DefinitionCatalog
var _policy: RefCounted
var _origin := {}
var _checkpoint := {}
var _moves := {}
var _items := {}
var _abilities := {}
var _species := {}
var commit_guard: Callable # Optional campaign ownership check, before native commit.
var format_id := "gen9customgame"
var native_sleep_clocks: Dictionary = {} # Only clocks observed by the native campaign owner.


func _init(catalog: DefinitionCatalog, p_format: String = "gen9customgame") -> void:
	_catalog = catalog
	format_id = p_format
	_policy = Policy.new()
	_policy.load_local()
	for id: StringName in catalog.move_catalog.all_ids(): _moves[Adapter.normalized(String(id))] = String(id)
	for id: StringName in catalog.move_catalog.all_ids():
		if String(id).ends_with("_physical") or String(id).ends_with("_special"):
			_moves[Adapter.normalized(String(id).trim_suffix("_physical").trim_suffix("_special"))] = String(id)
	_moves["visegrip"] = "vice_grip" # Official spelling alias; retain canonical game ID.
	for id: StringName in catalog.species_catalog.all_ids(): _species[Adapter.normalized(String(id))] = String(id)
	for pair: Array in [["darmanitangalar", "darmanitan_galar_standard"], ["taurospaldeacombat", "tauros_paldea_combat_breed"], ["taurospaldeablaze", "tauros_paldea_blaze_breed"], ["taurospaldeaaqua", "tauros_paldea_aqua_breed"]]:
		if catalog.species(StringName(pair[1])) != null: _species[pair[0]] = pair[1]
	for id: StringName in catalog.item_catalog.all_ids(): _items[Adapter.normalized(String(id))] = String(id)
	for id: StringName in catalog.item_catalog.all_ids():
		if String(id).ends_with("_z_held"): _items[Adapter.normalized(String(id).trim_suffix("_held"))] = String(id)
	for id: StringName in catalog.ability_catalog.all_ids(): _abilities[Adapter.normalized(String(id))] = String(id)


func open(tree: SceneTree, party_a: Array[CreatureInstance], party_b: Array[CreatureInstance], seed: Array = [1, 2, 3, 4]) -> bool:
	if busy or _client != null: return false
	if not format_supported(): last_error = "unknown_battle_profile"; return false
	var teams := {"p1": [], "p2": []}
	for pair: Array in [["p1", party_a], ["p2", party_b]]:
		for creature: CreatureInstance in pair[1]:
			if creature.is_knocked_out(): last_error = "initial_fainted_not_supported"; return false
			var species := _catalog.species(creature.species_id)
			var base := String(species.source_metadata.get("base_species_id", String(creature.species_id))) if species != null else ""
			if not _policy.form_allowed(base, String(creature.species_id) if base != String(creature.species_id) else "") or (creature.ability_id != &"" and not _policy.ability_allowed(String(creature.ability_id))):
				last_error = "content_policy"; return false
			for slot: BattleMoveSlot in creature.moveset:
				if not _policy.move_learnable(String(slot.move_id)):
					last_error = "move_policy"; return false
			teams[pair[0]].append(_creature_dto(creature))
	# Canonical JSON values keep snapshots stable across file round trips.
	_origin = JSON.parse_string(JSON.stringify(teams))
	_tree = tree
	_client = PipeClient.new()
	if not _client.start(node_path()): last_error = "worker_start"; _client = null; return false
	busy = true
	var hello: Dictionary = await _client.exchange(tree, {"op": "hello"})
	if not hello.get("ok", false) or hello.result.get("version") != VERSION: return await _open_failed("worker_handshake")
	var started: Dictionary = await _client.exchange(tree, {"op": "start", "id": "battle", "format": format_id, "teams": teams, "seed": seed})
	if not started.get("ok", false): return await _open_failed(String(started.get("error", "start_failed")))
	var data: Dictionary = await _client.exchange(tree, {"op": "checkpoint", "id": "battle"})
	if not data.get("ok", false): return await _open_failed("initial_checkpoint")
	var projected := _mirror(data.result)
	if projected == null: return await _open_failed(last_error)
	_checkpoint = data.result
	presentation_state = projected
	busy = false
	return true


func _open_failed(reason: String) -> bool:
	last_error = reason
	await close()
	return false


func format_supported() -> bool:
	return format_id in ["gen9customgame", "gen8customgame", "gen9calvounifiedv1"]


func dynamax_profile() -> bool:
	return format_id in ["gen8customgame", "gen9calvounifiedv1", "gen9calvounifieddoublesv1"]


func backend_id() -> String:
	return BACKEND


func _creature_dto(creature: CreatureInstance) -> Dictionary:
	var value := creature.to_dict()
	if creature.status_state.persistent_id == &"sleep" and native_sleep_clocks.has(String(creature.instance_id)):
		value["native_sleep"] = native_sleep_clocks[String(creature.instance_id)].duplicate(true)
	return value


static func node_path() -> String:
	var configured := OS.get_environment("POKEMON_CALVO_NODE")
	if not configured.is_empty(): return configured
	return "D:/Herramientas/NodeJS/node.exe"


func request(side: String = "p1") -> Dictionary:
	return _checkpoint.get("views", {}).get(side, {}).get("request", {}).duplicate(true) if _checkpoint.get("views", {}).get(side, {}).get("request") is Dictionary else {}


func is_reviving(side: String = "p1") -> bool:
	for row: Dictionary in request(side).get("side", {}).get("pokemon", []):
		if row.get("reviving", false): return true
	return false


## Resolve the native offer; a Z crystal never grants arbitrary Z attacks.
func z_move_id(slot: int, side: String = "p1", active_slot: int = 0) -> String:
	var active: Array = request(side).get("active", [])
	if active_slot < 0 or active_slot >= active.size() or not active[active_slot] is Dictionary: return ""
	var offers: Array = active[active_slot].get("canZMove", [])
	if slot < 0 or slot >= offers.size() or not offers[slot] is Dictionary: return ""
	var name := String(offers[slot].get("move", ""))
	if name.begins_with("Z-"):
		return String(active[active_slot].moves[slot].id) if _policy.z_status_allowed() else ""
	var key := Adapter.normalized(name)
	var id := String(_moves.get(key, ""))
	if id.ends_with("_physical") or id.ends_with("_special"):
		var base := _catalog.move(StringName(_moves.get(String(active[active_slot].moves[slot].id), "")))
		if base == null: return ""
		id = id.trim_suffix("_physical").trim_suffix("_special") + "_" + base.damage_class
	return id if _policy.move_allowed(id) else ""


func phase() -> String:
	if needs_recovery: return "interrupted"
	if _checkpoint.is_empty(): return "closed"
	if _checkpoint.views.p1.ended: return "finished"
	if request().get("forceSwitch", [false])[0]: return "player_switch"
	if request("p2").get("forceSwitch", [false])[0]: return "opponent_switch"
	return "move"


func opponent_choice() -> String:
	# Lab opponent only: own legal request, no access to hidden player state.
	var req := request("p2")
	if req.is_empty() or req.get("wait", false): return ""
	if req.get("forceSwitch", [false])[0]:
		for i in req.side.pokemon.size():
			var p: Dictionary = req.side.pokemon[i]
			if is_reviving("p2"):
				if String(p.condition).contains("fnt"): return "switch %d" % (i + 1)
				continue
			if not p.active and not String(p.condition).contains("fnt"): return "switch %d" % (i + 1)
		return ""
	for i in req.get("active", [{}])[0].get("moves", []).size():
		var move: Dictionary = req.active[0].moves[i]
		if not move.get("disabled", false) and int(move.get("pp", 0)) > 0: return "move %d" % (i + 1)
	return "move 1" # Native request supplies Struggle when no regular PP remain.


func submit(choice: String, expected_revision: int) -> Dictionary:
	if busy or needs_recovery or _client == null or expected_revision != revision or phase() == "finished": return {"accepted": false, "error": "busy_stale_or_finished", "events": []}
	busy = true
	var choices := {}
	var req := request()
	if not req.is_empty() and not req.get("wait", false): choices["p1"] = choice
	var other := opponent_choice()
	if not other.is_empty(): choices["p2"] = other
	return await _submit_choices(choices)


func submit_reaction(kind: String, expected_revision: int) -> Dictionary:
	if busy or needs_recovery or _client == null or expected_revision != revision or phase() != "move" or kind not in ["capture_failed", "escape_failed", "escape_blocked"]:
		return {"accepted": false, "error": "invalid_reaction_boundary", "events": []}
	busy = true
	return await _submit_choices({"p2": opponent_choice()}, kind)


func submit_medicine(command: Dictionary, expected_revision: int) -> Dictionary:
	if busy or needs_recovery or _client == null or expected_revision != revision or phase() != "move": return {"accepted": false, "error": "invalid_medicine_boundary", "events": []}
	busy = true
	return await _submit_choices({"p2": opponent_choice()}, "medicine", command)


func _submit_choices(choices: Dictionary, reaction: String = "", medicine: Dictionary = {}) -> Dictionary:
	for side: String in choices:
		var commands := String(choices[side]).split(",")
		for active_slot in commands.size():
			var parts := String(commands[active_slot]).strip_edges().split(" ", false)
			if "zmove" in parts:
				if parts.size() not in [3, 4] or parts[0] != "move" or not parts[1].is_valid_int() or parts[-1] != "zmove" or (parts.size() == 4 and not parts[2].is_valid_int()) or z_move_id(int(parts[1]) - 1, side, active_slot).is_empty():
					return _rejected("z_move_policy_or_unavailable")
	var command := {"op": "prepare", "id": "battle", "expected_hash": _checkpoint.state_hash, "choices": choices}
	if not reaction.is_empty(): command["reaction"] = reaction
	if not medicine.is_empty(): command["medicine"] = medicine
	var prepared: Dictionary = await _client.exchange(_tree, command)
	if not prepared.get("ok", false):
		var reason := String(prepared.get("error", "prepare_failed"))
		needs_recovery = reason.contains("pipe") or reason.contains("worker") or reason.contains("Stale native revision") or reason.contains("RPC")
		return _rejected(reason)
	var draft: Dictionary = prepared.result
	var projected := _mirror(draft.checkpoint)
	var translation := Adapter.project(_checkpoint, draft.checkpoint, _moves, _policy, _species)
	if projected == null or not translation.ok:
		await _client.exchange(_tree, {"op": "abort", "id": "battle", "draft_token": draft.draft_token})
		return _rejected(last_error if projected == null else "unsupported_protocol:" + str(translation.unknown))
	if commit_guard.is_valid() and not commit_guard.call():
		await _client.exchange(_tree, {"op": "abort", "id": "battle", "draft_token": draft.draft_token})
		return _rejected("campaign_changed")
	var committed: Dictionary = await _client.exchange(_tree, {"op": "commit", "id": "battle", "draft_token": draft.draft_token})
	if not committed.get("ok", false) or committed.result.state_hash != draft.checkpoint.state_hash:
		needs_recovery = true
		return _rejected("commit_unconfirmed")
	_checkpoint = committed.result
	presentation_state = projected
	revision += 1
	busy = false
	last_error = ""
	return {"accepted": true, "events": translation.events, "revision": revision, "phase": phase()}


func _rejected(reason: String) -> Dictionary:
	busy = false
	last_error = reason
	return {"accepted": false, "error": reason, "events": []}


func snapshot() -> Dictionary:
	return {"schema_version": 1, "backend": backend_id(), "sim_version": VERSION, "format": format_id, "revision": revision,
		"data_sha256": FileAccess.get_sha256(Policy.DATA_PATH), "policy_sha256": FileAccess.get_sha256(Policy.CONFIG_PATH),
		"origin": _origin.duplicate(true), "native": _checkpoint.get("snapshot", {}).duplicate(true)}


func restore_saved(tree: SceneTree, data: Dictionary) -> bool:
	if _client != null or not format_supported() or data.get("backend") != backend_id() or data.get("sim_version") != VERSION or data.get("schema_version") != 1 or data.get("format") != format_id: last_error = "snapshot_version"; return false
	if data.get("data_sha256") != FileAccess.get_sha256(Policy.DATA_PATH) or data.get("policy_sha256") != FileAccess.get_sha256(Policy.CONFIG_PATH) or not _valid_saved_origin(data.get("origin")) or not data.get("native") is Dictionary:
		last_error = "snapshot_contract"; return false
	if not data.native.get("native") is Dictionary or data.native.native.get("formatid") != format_id: last_error = "snapshot_profile"; return false
	_tree = tree; _origin = data.get("origin", {}).duplicate(true)
	_client = PipeClient.new()
	if not _client.start(node_path()): _client = null; return false
	busy = true
	var hello: Dictionary = await _client.exchange(tree, {"op": "hello"})
	if not hello.get("ok", false) or hello.result.get("version") != VERSION: return await _open_failed("worker_handshake")
	var restored: Dictionary = await _client.exchange(tree, {"op": "restore", "id": "battle", "snapshot": data.native})
	if not restored.get("ok", false): return await _open_failed("native_restore:" + String(restored.get("error", "unknown")))
	var response: Dictionary = await _client.exchange(tree, {"op": "checkpoint", "id": "battle"})
	if not response.get("ok", false): return await _open_failed("restore_checkpoint")
	var projected := _mirror(response.result)
	if projected == null: return await _open_failed(last_error)
	_checkpoint = response.result; presentation_state = projected; revision = int(data.revision); busy = false
	return true


func _valid_saved_origin(value: Variant) -> bool:
	if not value is Dictionary or not value.get("p1") is Array or not value.get("p2") is Array: return false
	var seen := {}
	for side: String in ["p1", "p2"]:
		if value[side].is_empty() or value[side].size() > 6: return false
		for row: Variant in value[side]:
			if not row is Dictionary or not row.get("instance_id") is String or not row.get("species_id") is String or not row.get("stats") is Dictionary or not row.get("moveset") is Array: return false
			if row.instance_id.is_empty() or seen.has(row.instance_id) or _catalog.species(StringName(row.species_id)) == null: return false
			var species := _catalog.species(StringName(row.species_id))
			var base := String(species.source_metadata.get("base_species_id", row.species_id))
			if not _policy.form_allowed(base, row.species_id if base != row.species_id else ""): return false
			if not String(row.get("ability_id", "")).is_empty() and not _policy.ability_allowed(String(row.ability_id)): return false
			seen[row.instance_id] = true
			for key: String in ["max_hp", "attack", "defense", "special_attack", "special_defense", "speed"]:
				if not row.stats.get(key) is float and not row.stats.get(key) is int: return false
				if int(row.stats[key]) < 1: return false
			if row.moveset.is_empty() or row.moveset.size() > 4: return false
			for slot: Variant in row.moveset:
				if not slot is Dictionary or not slot.get("move_id") is String or not _policy.move_learnable(slot.move_id): return false
	return true


func _mirror(data: Dictionary) -> BattleState:
	if not data.get("roster") is Array or data.roster.size() != 2 or not data.get("snapshot") is Dictionary or not data.get("views") is Dictionary:
		last_error = "native_checkpoint_shape"; return null
	var parties := {"p1": [], "p2": []}
	var origin_by_id := {}
	for side: String in ["p1", "p2"]:
		for value: Dictionary in _origin.get(side, []): origin_by_id[String(value.instance_id)] = value
	for side: Dictionary in data.roster:
		if side.get("id") not in ["p1", "p2"] or not side.get("pokemon") is Array: last_error = "native_side_shape"; return null
		for row: Dictionary in side.pokemon:
			if not row.has_all(["instance_id", "species_id", "max_hp", "hp", "moves", "boosts", "transformed", "ability", "item", "status_id"]): last_error = "native_creature_shape"; return null
			if not row.moves is Array or not row.boosts is Dictionary: last_error = "native_creature_fields"; return null
			var origin: Dictionary = origin_by_id.get(String(row.instance_id), {})
			if origin.is_empty(): last_error = "unknown_native_identity"; return null
			var original_id := Adapter.normalized(String({"darmanitan_galar_standard": "darmanitan_galar", "tauros_paldea_combat_breed": "tauros_paldea_combat", "tauros_paldea_blaze_breed": "tauros_paldea_blaze", "tauros_paldea_aqua_breed": "tauros_paldea_aqua"}.get(String(origin.species_id), origin.species_id)))
			var dynamax: bool = "dynamax" in row.get("volatiles", [])
			if (not bool(row.transformed) and String(row.species_id) != original_id) or (int(row.max_hp) != int(origin.stats.max_hp) and not (dynamax_profile() and dynamax and int(row.get("base_max_hp", 0)) == int(origin.stats.max_hp))):
				last_error = "temporary_form_not_supported"; return null
			if int(row.hp) < 0 or int(row.hp) > int(row.max_hp): last_error = "invalid_native_hp"; return null
			var creature := CreatureInstance.from_dict(origin)
			if dynamax: creature.stats.max_hp = int(row.max_hp)
			if bool(row.transformed):
				if not _species.has(String(row.species_id)) or not row.get("stats") is Dictionary: last_error = "unmapped_transform"; return null
				creature.battle_transform_original = {"species_id": origin.species_id, "stats": origin.stats.duplicate(true), "ability_id": origin.ability_id, "moveset": origin.moveset.duplicate(true), "is_shiny": origin.get("is_shiny", false)}
				creature.species_id = StringName(_species[String(row.species_id)])
				creature.stats = StatBlock.from_dict(row.stats)
				creature.is_shiny = bool(row.get("shiny", false))
			creature.current_hp = int(row.hp)
			creature.status_state = BattleStatusState.new()
			creature.status_state.persistent_id = StringName(row.status_id)
			creature.status_ids.clear()
			if not String(row.status_id).is_empty(): creature.status_ids.append(StringName(row.status_id))
			creature.status_state.turns_remaining = int(row.get("status_time", 0))
			creature.status_state.toxic_counter = int(row.get("toxic_stage", 0))
			if int(row.get("substitute_hp", 0)) > 0: creature.status_state.add_volatile(&"substitute", {"hp": int(row.substitute_hp), "max_hp": maxi(int(row.substitute_hp), int(row.max_hp) / 4)})
			creature.stat_stages = StatStages.from_dict(_stages(row.boosts))
			if not String(row.ability).is_empty() and String(row.ability) != "noability":
				if not _abilities.has(String(row.ability)): last_error = "unmapped_ability"; return null
				creature.ability_id = StringName(_abilities[String(row.ability)])
			if String(row.item).is_empty():
				creature.held_item_consumed = creature.held_item_id != &""
			else:
				if not _items.has(String(row.item)): last_error = "unmapped_item"; return null
				creature.held_item_id = StringName(_items[String(row.item)]); creature.held_item_consumed = false
			if row.moves.is_empty() or row.moves.size() > 4: last_error = "move_slot_count"; return null
			creature.moveset.clear(); creature.move_ids.clear()
			for i in row.moves.size():
				if not row.moves[i] is Dictionary or not row.moves[i].has_all(["id", "pp", "max_pp"]): last_error = "native_move_shape"; return null
				if int(row.moves[i].pp) < 0 or int(row.moves[i].pp) > int(row.moves[i].max_pp) or int(row.moves[i].max_pp) < 1: last_error = "native_pp_range"; return null
				if not _moves.has(String(row.moves[i].id)) or not _policy.move_allowed(_moves[String(row.moves[i].id)]): last_error = "unmapped_temporary_move"; return null
				var id := StringName(_moves[String(row.moves[i].id)])
				creature.moveset.append(BattleMoveSlot.new(id, int(row.moves[i].max_pp), int(row.moves[i].pp)))
				creature.move_ids.append(id)
			parties[String(side.id)].append(creature)
	var a: Array[CreatureInstance] = []; a.assign(parties.p1)
	var b: Array[CreatureInstance] = []; b.assign(parties.p2)
	var state := BattleState.create_with_parties(&"showdown_lab", a, b, 1)
	for side: Dictionary in data.roster: state.switch_active(&"side_a" if side.id == "p1" else &"side_b", StringName(side.active_id))
	state.live_moves_enabled = true
	state.substitute_rules_enabled = true; state.transform_rules_enabled = true
	state.weather_rules_enabled = true; state.weather = Adapter.weather_view(data)
	state.turn = maxi(0, int(data.snapshot.native.turn) - 1)
	if data.views.p1.ended:
		state.phase = BattleState.FINISHED
		state.winner_id = &"side_a" if data.views.p1.winner == "Player" else (&"side_b" if data.views.p1.winner == "Opponent" else &"")
	elif data.views.p1.request is Dictionary and data.views.p1.request.get("forceSwitch", [false])[0]: state.phase = BattleState.WAITING_FOR_SWITCH
	return state


static func _stages(boosts: Dictionary) -> Dictionary:
	var out := {}
	for key: String in Adapter.STATS: out[Adapter.STATS[key]] = int(boosts.get(key, 0))
	return out


func battle_state() -> BattleState:
	return presentation_state


func close() -> void:
	if busy: stop_now(); return
	if _client != null: await _client.close(_tree)
	_client = null; busy = false


func stop_now() -> void:
	if _client != null: _client.stop_now()
	_client = null; busy = false
