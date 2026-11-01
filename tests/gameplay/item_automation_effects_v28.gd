extends RefCounted

# Assertion predicates only: no combat execution, RNG, UI or persistent mutations.
static func expectations(spec: Dictionary, contract: Dictionary, observed: Dictionary) -> Array:
	var result: Array = []
	var positive_mode := "active" if contract.target == "own" else "reserve"
	for mode: String in ["active", "none", "reserve"]:
		var sample: Dictionary = observed[mode]
		result.append([mode + " executed and restored", sample.get("valid", false) and sample.get("restored", false)])
		if not sample.get("valid", false): continue
		var frames: Array = sample.frames
		result.append([mode + " complete timeline", frames.size() == contract.commands.size()])
		for index in frames.size():
			var frame: Dictionary = frames[index]
			var baseline: Dictionary = observed.none.frames[index]
			var before: Dictionary = frame.before
			var after: Dictionary = frame.after
			var holder_delta := int(after.target_hp) - int(before.target_hp)
			var foe_loss := int(before.foe_hp) - int(after.foe_hp)
			var plain_foe_loss := int(baseline.before.foe_hp) - int(baseline.after.foe_hp)
			result.append([mode + " active identity " + str(index), after.active_id == contract.target])
			match String(spec.effect.op):
				"residual_heal":
					var wanted := mini(int(before.target_max_hp) / int(spec.effect.divisor), int(before.target_max_hp) - int(before.target_hp)) if mode == positive_mode else 0
					result.append([mode + " residual amount/cap " + str(index), holder_delta == wanted])
					result.append([mode + " no invented foe damage " + str(index), foe_loss == 0])
				"damage_recoil":
					var enabled: bool = contract.activates and mode == positive_mode
					var wanted := int(before.target_max_hp) / int(spec.effect.divisor) if enabled else 0
					result.append([mode + " recoil specific to damaging action " + str(index), -holder_delta == wanted])
					if contract.activates:
						result.append([mode + " positive control hit " + str(index), plain_foe_loss > 0])
						result.append([mode + " matching damage effect " + str(index), foe_loss > plain_foe_loss if enabled else foe_loss == plain_foe_loss])
					else:
						result.append([mode + " status/immunity no damage " + str(index), foe_loss == 0 and plain_foe_loss == 0])
				"contact_retaliation":
					var wanted := int(before.foe_max_hp) / int(spec.effect.divisor) if contract.activates and mode == positive_mode else 0
					result.append([mode + " contact-specific retaliation " + str(index), foe_loss == wanted])
					result.append([mode + " real incoming damage " + str(index), holder_delta < 0])
					result.append([mode + " no defensive damage bonus " + str(index), holder_delta == int(baseline.after.target_hp) - int(baseline.before.target_hp)])
				_:
					result.append(["unsupported expectation", false])
	return result
