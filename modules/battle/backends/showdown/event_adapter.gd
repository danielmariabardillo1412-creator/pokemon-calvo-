extends RefCounted

# Presentation events only. All battle effects and amounts are resolved by the
# native engine. Unsupported protocol transitions reject the prepared turn.
const STATUS := {"brn": "burn", "psn": "poison", "tox": "badly_poisoned", "slp": "sleep", "frz": "freeze", "par": "paralysis"}
const STATS := {"atk": "attack", "def": "defense", "spa": "special_attack", "spd": "special_defense", "spe": "speed", "accuracy": "accuracy", "evasion": "evasion"}


static func project(before: Dictionary, after: Dictionary, move_map: Dictionary, policy: RefCounted, species_map: Dictionary = {}) -> Dictionary:
	var result: Array[BattleEvent] = []
	var unknown: Array[String] = []
	var hp := {}
	var ids: Dictionary = after.snapshot.identities
	for side: Dictionary in before.roster:
		for p: Dictionary in side.pokemon: hp[String(p.instance_id)] = int(p.hp)
	var turn := int(before.snapshot.native.turn)
	var actor := ""
	var move := ""
	var dolls := {}
	var positions := {}
	for side: Dictionary in before.roster:
		positions[side.id] = side.get("active_ids", [side.get("active_id", "")]).duplicate()
	for side: Dictionary in before.roster:
		for p: Dictionary in side.pokemon: dolls[String(p.instance_id)] = int(p.get("substitute_hp", 0))
	var log: Array = after.snapshot.native.log
	var index := (before.snapshot.native.log as Array).size()
	while index < log.size():
		var text := String(log[index]); index += 1
		if text.begins_with("|split|"):
			if index + 1 >= log.size(): return {"ok": false, "unknown": ["incomplete split"]}
			text = String(log[index]); index += 2 # trusted local presentation, never AI
		var f := text.split("|")
		if f.size() < 2: continue
		var tag := String(f[1])
		if tag in ["", "t:", "upkeep", "debug", "-hint"]: continue
		var target := identity(String(f[2]), ids) if f.size() > 2 else ""
		var meta := {"backend": "showdown_v1", "native_tag": tag}
		match tag:
			"swap":
				var side := "p1" if String(f[2]).begins_with("p1") else "p2"
				var slots: Array = positions.get(side, [])
				var old_slot := slots.find(target)
				var new_slot := int(f[3])
				if slots.size() != 2 or old_slot < 0 or new_slot < 0 or new_slot > 1:
					unknown.append("swap:position"); continue
				var previous := slots.duplicate()
				var partner := String(slots[new_slot])
				slots[new_slot] = target; slots[old_slot] = partner
				meta["side_id"] = "side_a" if side == "p1" else "side_b"
				meta["before"] = previous; meta["after"] = slots.duplicate()
				result.append(event(BattleEvent.ALLY_POSITIONS_SWAPPED, turn, target, partner, move, 0, meta))
			"calvosub":
				var remaining := int(f[4]); var previous := int(dolls.get(target, 0))
				meta["hp"] = remaining; meta["max_hp"] = maxi(previous, remaining)
				var kind := BattleEvent.SUBSTITUTE_CREATED if f[3] == "start" else (BattleEvent.SUBSTITUTE_BROKEN if f[3] == "end" else BattleEvent.SUBSTITUTE_DAMAGED)
				if kind == BattleEvent.SUBSTITUTE_BROKEN and previous > 0:
					result.append(event(BattleEvent.SUBSTITUTE_DAMAGED, turn, actor, target, move, previous, meta))
				result.append(event(kind, turn, actor, target, move, maxi(0, previous - remaining), meta))
				dolls[target] = remaining
			"-ohko", "-swapsideconditions", "-zbroken":
				result.append(event(BattleEvent.MOVE_EFFECT_RESOLVED, turn, actor, target, move, 0, meta))
			"-anim":
				# Secondary native animation hint; ACTION_USED already owns the clip.
				continue
			"-zpower":
				meta["native_zpower"] = true
				result.append(event(BattleEvent.MOVE_EFFECT_RESOLVED, turn, target, target, "", 0, meta))
			"-transform":
				var changed := roster_row(after, target)
				var copied := identity(String(f[3]), ids)
				meta["species_id"] = species_map.get(String(changed.get("species_id", "")), changed.get("species_id", ""))
				meta["appearance_id"] = String(meta.species_id) + ("__shiny" if changed.get("shiny", false) else "")
				result.append(event(BattleEvent.TRANSFORMED, turn, target, copied, move, 0, meta))
			"calvomedicine":
				meta["item_id"] = String(f[3])
				result.append(event(BattleEvent.TRAINER_ITEM_USED, turn, target, target, "", 1, meta))
			"move":
				actor = target
				var key := normalized(String(f[3]))
				var resolved := String(move_map.get(key, ""))
				if resolved.ends_with("_physical") or resolved.ends_with("_special"):
					var category := String(roster_row(after, actor).get("last_move_category", ""))
					resolved = resolved.trim_suffix("_physical").trim_suffix("_special") + "_" + category
				if not move_map.has(normalized(resolved)) or not policy.move_allowed(resolved) or (text.contains("[zeffect]") and roster_row(after, actor).get("last_move_category", "") == "status" and not policy.z_status_allowed()):
					unknown.append("move:" + key); continue
				move = resolved
				var recipient := identity(String(f[4]), ids) if f.size() > 4 else actor
				result.append(event(BattleEvent.ACTION_USED, turn, actor, recipient, move, 0, meta))
			"switch", "drag":
				if target.is_empty(): unknown.append(tag + ":identity"); continue
				meta["side_id"] = "side_a" if String(f[2]).begins_with("p1") else "side_b"
				meta["forced"] = tag == "drag"
				var native_side := "p1" if String(f[2]).begins_with("p1") else "p2"
				var native_slot := 1 if String(f[2]).begins_with(native_side + "b:") else 0
				meta["active_slot"] = native_slot
				var old_owner := ""
				if native_slot < positions.get(native_side, []).size():
					old_owner = String(positions[native_side][native_slot]); positions[native_side][native_slot] = target
				result.append(event(BattleEvent.SWITCHED, turn, "", target, "", 0, meta))
				var doll := int(roster_row(after, target).get("substitute_hp", 0))
				if doll > 0:
					result.append(event(BattleEvent.SUBSTITUTE_TRANSFERRED, turn, "", target, move, 0, {"hp": doll, "max_hp": doll}))
				var current := roster_row(after, old_owner)
				if roster_row(before, old_owner).get("transformed", false) and not current.get("transformed", false):
					meta["species_id"] = species_map.get(String(current.get("species_id", "")), current.get("species_id", ""))
					meta["appearance_id"] = String(meta.species_id) + ("__shiny" if current.get("shiny", false) else "")
					result.append(event(BattleEvent.TRANSFORM_REVERTED, turn, old_owner, old_owner, "", 0, meta))
			"-damage", "-heal", "-sethp":
				if not hp.has(target): unknown.append(tag + ":identity"); continue
				var health := String(f[3]).split(" ")[0]
				if not health.contains("/") and health != "0": unknown.append("non-exact HP"); continue
				var next_hp := int(health.split("/")[0])
				meta["native_hp"] = next_hp
				meta["native_max_hp"] = int(health.split("/")[1]) if health.contains("/") else int(roster_row(after, target).get("max_hp", 1))
				meta["silent"] = "[silent]" in text
				var amount := absi(next_hp - int(hp[target]))
				var kind := BattleEvent.HP_RECOVERED if next_hp >= int(hp[target]) else BattleEvent.DAMAGE_APPLIED
				if tag != "-sethp" and text.contains("[from]") and kind == BattleEvent.DAMAGE_APPLIED: kind = BattleEvent.STATUS_DAMAGE
				if amount > 0: result.append(event(kind, turn, actor, target, move, amount, meta))
				hp[target] = next_hp
				if tag == "-sethp" and f.size() > 5:
					var other := identity(String(f[4]), ids)
					if hp.has(other):
						var other_hp := int(String(f[5]).split("/")[0])
						var other_amount := absi(other_hp - int(hp[other]))
						var other_meta := meta.duplicate(true); other_meta["native_hp"] = other_hp
						other_meta["native_max_hp"] = int(String(f[5]).split("/")[1])
						if other_amount > 0: result.append(event(BattleEvent.HP_RECOVERED if other_hp > int(hp[other]) else BattleEvent.DAMAGE_APPLIED, turn, actor, other, move, other_amount, other_meta))
						hp[other] = other_hp
					elif not String(f[4]).begins_with("["): unknown.append("sethp:identity")
			"-status", "-curestatus":
				if not STATUS.has(String(f[3])): unknown.append("status:" + String(f[3])); continue
				meta["status_id"] = STATUS[String(f[3])]
				result.append(event(BattleEvent.STATUS_APPLIED if tag == "-status" else BattleEvent.STATUS_CURED, turn, actor, target, move, 0, meta))
			"-boost", "-unboost":
				if not STATS.has(String(f[3])): unknown.append("stat:" + String(f[3])); continue
				meta["stat_id"] = STATS[String(f[3])]
				result.append(event(BattleEvent.STAT_STAGE_CHANGED, turn, actor, target, move, int(f[4]) * (-1 if tag == "-unboost" else 1), meta))
			"-clearallboost", "-clearboost", "-clearnegativeboost", "-copyboost", "-swapboost", "-setboost", "-invertboost":
				result.append(event(BattleEvent.MOVE_EFFECT_RESOLVED, turn, actor, target, move, 0, meta))
			"-sidestart", "-sideend", "-fieldstart", "-fieldend", "-fieldactivate", "-singleturn", "-singlemove", "-prepare", "-mustrecharge", "-nothing", "-hitcount":
				result.append(event(BattleEvent.MOVE_EFFECT_RESOLVED, turn, actor, target, move, 0, meta))
			"-activate", "-start", "-end":
				var condition := String(f[3]) if f.size() > 3 else ""
				meta["native_condition"] = condition
				if condition.to_lower().contains("substitute"):
					if tag == "-activate" and not text.contains("[damage]"): result.append(event(BattleEvent.SUBSTITUTE_BLOCKED, turn, actor, target, move, 0, meta))
					continue # Exact native observations follow as calvosub.
				if condition.to_lower().contains("dynamax"):
					meta["native_dynamax"] = tag == "-start"
					result.append(event(BattleEvent.MOVE_EFFECT_RESOLVED, turn, actor, target, move, 0, meta)); continue
				if tag == "-activate" and normalized(condition) in ["moveprotect", "movedetect", "movekingsshield", "movespikyshield", "movebanefulbunker", "moveobstruct", "movesilktrap", "moveburningbulwark", "movewideguard", "movequickguard"]:
					meta["reason"] = "protected"
					result.append(event(BattleEvent.MOVE_EFFECT_FAILED, turn, actor, target, move, 0, meta)); continue
				if condition.begins_with("ability:"):
					result.append(event(BattleEvent.ABILITY_TRIGGERED, turn, target, target, "", 0, meta)); continue
				result.append(event(BattleEvent.MOVE_EFFECT_RESOLVED, turn, actor, target, move, 0, meta))
			"-crit": result.append(event(BattleEvent.CRITICAL_HIT, turn, actor, target, move, 0, meta))
			"-resisted", "-supereffective", "-immune":
				meta["category"] = {"-resisted": "not_very_effective", "-supereffective": "super_effective", "-immune": "immune"}[tag]
				result.append(event(BattleEvent.TYPE_EFFECTIVENESS, turn, actor, target, move, 0, meta))
			"-fail", "-miss", "cant":
				var kind := BattleEvent.MOVE_EFFECT_FAILED
				if tag == "-miss": kind = BattleEvent.MOVE_MISSED
				elif tag == "cant": kind = BattleEvent.ACTION_PREVENTED
				result.append(event(kind, turn, actor, target, move, 0, meta))
			"-ability", "-endability": result.append(event(BattleEvent.ABILITY_TRIGGERED, turn, target, target, "", 0, meta))
			"-block":
				# Recognize this item notification only; unknown block protocols still reject.
				if target.is_empty() or f.size() < 4 or String(f[3]) != "item: Ability Shield":
					unknown.append("-block"); continue
				meta["item_id"] = "ability_shield"
				meta["reason"] = "ability_protected"
				result.append(event(BattleEvent.ITEM_TRIGGERED, turn, target, target, "", 0, meta))
			"-item", "-enditem": result.append(event(BattleEvent.ITEM_TRIGGERED, turn, target, target, "", 0, meta))
			"-weather":
				var weather := weather_view(after)
				meta["weather"] = weather
				result.append(event(BattleEvent.WEATHER_ENDED if weather.is_empty() else BattleEvent.WEATHER_CHANGED, turn, actor, "", move, 0, meta))
			"faint": result.append(event(BattleEvent.KNOCKED_OUT, turn, actor, target, move, 0, meta))
			"turn": result.append(event(BattleEvent.TURN_ENDED, int(f[2]) - 1, "", "", "", 0, meta))
			"win", "tie": result.append(event(BattleEvent.BATTLE_ENDED, turn, "", "", "", 0, meta))
			_: unknown.append(tag)
	# PP are authoritative state, including Pressure/consumption. No guessed -1.
	for side: Dictionary in after.roster:
		for p: Dictionary in side.pokemon:
			var old := roster_row(before, String(p.instance_id))
			for i in p.moves.size():
				if i >= old.get("moves", []).size(): continue # Native Transform can copy a larger set.
				if p.moves[i].id != old.moves[i].id: continue # Native virtual slot replacement, not a PP delta.
				var delta := int(p.moves[i].pp) - int(old.moves[i].pp)
				if delta != 0:
					var id := String(move_map.get(String(p.moves[i].id), ""))
					result.append(event(BattleEvent.PP_CHANGED, turn, String(p.instance_id), String(p.instance_id), id, delta,
						{"current_pp": int(p.moves[i].pp), "max_pp": int(p.moves[i].max_pp)}))
	return {"ok": unknown.is_empty(), "events": result, "unknown": unknown}


static func roster_row(data: Dictionary, id: String) -> Dictionary:
	for side: Dictionary in data.roster:
		for p: Dictionary in side.pokemon:
			if p.instance_id == id: return p
	return {}


static func weather_view(data: Dictionary) -> Dictionary:
	var field: Dictionary = data.snapshot.native.field
	var id := String(field.get("weather", ""))
	if id.is_empty(): return {}
	id = {"raindance": "rain", "sunnyday": "sun", "sandstorm": "sandstorm", "hail": "hail", "snowscape": "snow"}.get(id, id)
	return {"id": id, "turns_remaining": int(field.get("weatherState", {}).get("duration", 0))}


static func identity(value: String, ids: Dictionary) -> String:
	return String(ids.get(value.substr(value.find(": ") + 2), "")) if value.contains(": ") else ""


static func normalized(value: String) -> String:
	var out := ""
	for c: String in value.to_lower():
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"): out += c
	return out


static func event(kind: StringName, turn: int, actor: String, target: String, move: String, amount: int, meta: Dictionary) -> BattleEvent:
	return BattleEvent.new(kind, turn, StringName(actor), StringName(target), StringName(move), amount, meta)
