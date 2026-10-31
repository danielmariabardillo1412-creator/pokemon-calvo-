extends RefCounted

# A deliberately limited trusted presentation adapter. Consumes private server
# snapshots, never the AI/player projection. Unknown mechanics remain explicit.
static func project(before: Dictionary, after: Dictionary, move_ids: Array[StringName]) -> Dictionary:
	var ids: Dictionary = after.identities
	var moves := {}
	for id: StringName in move_ids: moves[String(id).replace("_", "")] = String(id)
	var hp := {}
	for side: Dictionary in before.native.sides:
		for pokemon: Dictionary in side.pokemon: hp[String(ids[pokemon.set.name])] = int(pokemon.hp)
	var events: Array = []
	var unmapped: Array[String] = []
	var log: Array = after.native.log
	var index := (before.native.log as Array).size()
	var actor := ""
	var move := ""
	while index < log.size():
		var text := String(log[index]); index += 1
		if text.begins_with("|split|"):
			text = String(log[index]); index += 2 # trusted renderer uses exact HP
		var fields := text.split("|")
		if fields.size() < 2: continue
		var kind := String(fields[1])
		if kind in ["", "t:", "upkeep", "debug"]: continue
		var target := _identity(String(fields[2]), ids) if fields.size() > 2 else ""
		var metadata := {"origin": "showdown_probe"}
		match kind:
			"move":
				actor = target
				var native_move := String(fields[3]).to_lower().replace(" ", "").replace("-", "").replace("'", "")
				if not moves.has(native_move): unmapped.append(text); continue
				move = moves[native_move]
				var recipient := _identity(String(fields[4]), ids) if fields.size() > 4 else actor
				events.append(_event(BattleEvent.ACTION_USED, int(after.native.turn) - 1, actor, recipient, move, 0, metadata))
			"-damage", "-heal":
				if not hp.has(target): unmapped.append(text); continue
				var health := String(fields[3]).split(" ")[0].split("/")[0]
				var next_hp := int(health)
				var amount := absi(next_hp - int(hp[target]))
				var type := BattleEvent.HP_RECOVERED if kind == "-heal" else BattleEvent.DAMAGE_APPLIED
				if text.contains("[from]") and kind == "-damage": type = BattleEvent.STATUS_DAMAGE
				events.append(_event(type, int(after.native.turn) - 1, actor, target, move, amount, metadata))
				hp[target] = next_hp
			"-status", "-curestatus":
				metadata["status_id"] = {"brn": "burn", "psn": "poison", "tox": "badly_poisoned", "slp": "sleep", "frz": "freeze", "par": "paralysis"}.get(String(fields[3]), "")
				events.append(_event(BattleEvent.STATUS_CURED if kind == "-curestatus" else BattleEvent.STATUS_APPLIED, int(after.native.turn) - 1, actor, target, move, 0, metadata))
			"-crit": events.append(_event(BattleEvent.CRITICAL_HIT, int(after.native.turn) - 1, actor, target, move, 0, metadata))
			"-resisted", "-supereffective", "-immune":
				metadata["category"] = {"-resisted": "not_very_effective", "-supereffective": "super_effective", "-immune": "immune"}[kind]
				events.append(_event(BattleEvent.TYPE_EFFECTIVENESS, int(after.native.turn) - 1, actor, target, move, 0, metadata))
			"faint": events.append(_event(BattleEvent.KNOCKED_OUT, int(after.native.turn) - 1, actor, target, move, 0, metadata))
			"turn": events.append(_event(BattleEvent.TURN_ENDED, int(fields[2]) - 1, "", "", "", 0, metadata))
			_: unmapped.append(text)
	return {"events": events, "unmapped": unmapped}


static func _identity(value: String, identities: Dictionary) -> String:
	var name := value.substr(value.find(": ") + 2) if value.contains(": ") else ""
	return String(identities.get(name, ""))


static func _event(kind: StringName, turn: int, actor: String, target: String, move: String,
	amount: int, metadata: Dictionary) -> Dictionary:
	return BattleEvent.new(kind, turn, StringName(actor), StringName(target), StringName(move), amount, metadata).to_dict()
