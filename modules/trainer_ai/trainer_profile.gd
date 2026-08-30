class_name TrainerProfile
extends RefCounted

# Deterministic tactical personality. These values change priorities, not legality
# or information access. Difficulty must never grant hidden battle information.
const BALANCED := &"balanced"
const AGGRESSIVE := &"aggressive"
const CAUTIOUS := &"cautious"
const TECHNICAL := &"technical"

var profile_id: StringName = BALANCED
var damage_weight_bp: int = 10000
var ko_bonus: int = 3500
var status_weight_bp: int = 10000
var setup_weight_bp: int = 10000
var switch_weight_bp: int = 10000
var preservation_weight_bp: int = 10000
var accuracy_weight_bp: int = 10000
var switch_cost: int = 450


static func balanced() -> TrainerProfile:
	return TrainerProfile.new()


static func aggressive() -> TrainerProfile:
	var profile := TrainerProfile.new()
	profile.profile_id = AGGRESSIVE
	profile.damage_weight_bp = 12500
	profile.ko_bonus = 4500
	profile.status_weight_bp = 7500
	profile.setup_weight_bp = 8000
	profile.switch_weight_bp = 7500
	profile.preservation_weight_bp = 7000
	profile.accuracy_weight_bp = 8500
	profile.switch_cost = 650
	return profile


static func cautious() -> TrainerProfile:
	var profile := TrainerProfile.new()
	profile.profile_id = CAUTIOUS
	profile.damage_weight_bp = 9000
	profile.ko_bonus = 3000
	profile.status_weight_bp = 11000
	profile.setup_weight_bp = 10500
	profile.switch_weight_bp = 12000
	profile.preservation_weight_bp = 14000
	profile.accuracy_weight_bp = 12000
	profile.switch_cost = 250
	return profile


static func technical() -> TrainerProfile:
	var profile := TrainerProfile.new()
	profile.profile_id = TECHNICAL
	profile.damage_weight_bp = 9500
	profile.ko_bonus = 3200
	profile.status_weight_bp = 13000
	profile.setup_weight_bp = 13500
	profile.switch_weight_bp = 10500
	profile.preservation_weight_bp = 11000
	profile.accuracy_weight_bp = 11000
	profile.switch_cost = 350
	return profile


func to_dict() -> Dictionary:
	return {
		"profile_id": String(profile_id),
		"damage_weight_bp": damage_weight_bp,
		"ko_bonus": ko_bonus,
		"status_weight_bp": status_weight_bp,
		"setup_weight_bp": setup_weight_bp,
		"switch_weight_bp": switch_weight_bp,
		"preservation_weight_bp": preservation_weight_bp,
		"accuracy_weight_bp": accuracy_weight_bp,
		"switch_cost": switch_cost,
	}


static func from_dict(data: Dictionary) -> TrainerProfile:
	var profile := TrainerProfile.new()
	profile.profile_id = StringName(data.get("profile_id", BALANCED))
	profile.damage_weight_bp = maxi(0, int(data.get("damage_weight_bp", 10000)))
	profile.ko_bonus = int(data.get("ko_bonus", 3500))
	profile.status_weight_bp = maxi(0, int(data.get("status_weight_bp", 10000)))
	profile.setup_weight_bp = maxi(0, int(data.get("setup_weight_bp", 10000)))
	profile.switch_weight_bp = maxi(0, int(data.get("switch_weight_bp", 10000)))
	profile.preservation_weight_bp = maxi(0, int(data.get("preservation_weight_bp", 10000)))
	profile.accuracy_weight_bp = maxi(0, int(data.get("accuracy_weight_bp", 10000)))
	profile.switch_cost = maxi(0, int(data.get("switch_cost", 450)))
	return profile
