class_name TrainerExpertiseContractAuditTestSuite
extends RefCounted

const PROFILE_SOURCE := "res://modules/trainer_ai/trainer_profile.gd"
const STRATEGIC_BRAIN_SOURCE := "res://modules/trainer_ai/strategic_switching_trainer_brain.gd"
const PROPOSAL_SOURCE := "res://modules/trainer_ai/trainer_item_aware_action_proposal.gd"
const SESSION_SOURCE := "res://modules/gameplay/trainer_battle_session.gd"
const TIE_RESOLVER_SOURCE := "res://modules/trainer_ai/trainer_game_ready_tie_resolver.gd"
const AGGREGATE := "TRAINER_AI_EXPERTISE_CONTRACT_AUDIT_COMPLETE"

var _check: Callable


func run(check_callback: Callable) -> void:
	_check = check_callback

	var profile_source := _read_text(PROFILE_SOURCE)
	var strategic_source := _read_text(STRATEGIC_BRAIN_SOURCE)
	var proposal_source := _read_text(PROPOSAL_SOURCE)
	var session_source := _read_text(SESSION_SOURCE)
	var tie_source := _read_text(TIE_RESOLVER_SOURCE)

	_check.call("expertise_audit_profile_source_present", not profile_source.is_empty())
	_check.call("expertise_audit_strategic_brain_source_present", not strategic_source.is_empty())
	_check.call("expertise_audit_proposal_source_present", not proposal_source.is_empty())
	_check.call("expertise_audit_session_source_present", not session_source.is_empty())
	_check.call("expertise_audit_tie_resolver_source_present", not tie_source.is_empty())

	var balanced := TrainerProfile.balanced()
	var aggressive := TrainerProfile.aggressive()
	var cautious := TrainerProfile.cautious()
	var technical := TrainerProfile.technical()
	var style_ids: Array[String] = [
		String(balanced.profile_id),
		String(aggressive.profile_id),
		String(cautious.profile_id),
		String(technical.profile_id),
	]
	_check.call("expertise_audit_four_style_ids_distinct", _all_unique(style_ids) and style_ids.size() == 4)

	var serialized_styles: Array[String] = [
		JSON.stringify(balanced.to_dict()),
		JSON.stringify(aggressive.to_dict()),
		JSON.stringify(cautious.to_dict()),
		JSON.stringify(technical.to_dict()),
	]
	_check.call("expertise_audit_style_weights_materially_distinct", _all_unique(serialized_styles))

	var schema := balanced.to_dict()
	_check.call(
		"expertise_audit_style_schema_has_no_expertise_or_difficulty",
		not schema.has("expertise_id") and not schema.has("difficulty_id") and not schema.has("competence_id")
	)
	var hidden_keys := [
		"opponent_moves",
		"opponent_party",
		"hidden_information",
		"belief_snapshot",
		"player_current_action",
		"battle_rng",
	]
	var hidden_field_present := false
	for key in hidden_keys:
		hidden_field_present = hidden_field_present or schema.has(key)
	_check.call("expertise_audit_style_schema_has_no_hidden_rival_information", not hidden_field_present)

	var technical_roundtrip := TrainerProfile.from_dict(technical.to_dict())
	_check.call(
		"expertise_audit_style_roundtrip_stable",
		technical_roundtrip != null
		and technical_roundtrip.profile_id == technical.profile_id
		and technical_roundtrip.to_dict() == technical.to_dict()
	)

	_check.call(
		"expertise_audit_strategic_brain_is_profile_aware",
		strategic_source.contains("p_profile: TrainerProfile = null")
		and strategic_source.contains("super(catalog, p_profile, p_budget)")
	)
	_check.call(
		"expertise_audit_runtime_proposal_accepts_explicit_style_and_expertise",
		proposal_source.contains("profile: TrainerProfile = null")
		and proposal_source.contains("expertise_id: StringName = TrainerExpertise.DEFAULT")
		and proposal_source.contains("TrainerItemAwareSearch.new(catalog, active_profile, budget)")
	)
	_check.call(
		"expertise_audit_runtime_proposal_preserves_balanced_full_defaults",
		proposal_source.contains("profile.profile_id if profile != null else TrainerProfile.BALANCED")
		and proposal_source.contains("TrainerExpertise.DEFAULT")
		and proposal_source.contains("const INNER_ACTION_CAP := TrainerItemAwareShadowProbe.INNER_ACTION_CAP")
	)
	_check.call(
		"expertise_audit_proposal_does_not_use_profile_tiebreak",
		proposal_source.contains("\"profile_tiebreak_used\": false")
	)
	_check.call(
		"expertise_audit_fase34_remains_closed_in_proposal",
		proposal_source.contains("\"fase34_open\": false")
	)
	_check.call(
		"expertise_audit_session_keeps_style_and_expertise_separate",
		session_source.contains("_trainer_profile_id")
		and session_source.contains("_trainer_expertise_id")
		and session_source.contains("TrainerExpertise.is_supported")
		and not TrainerProfile.balanced().to_dict().has("expertise_id")
	)
	_check.call(
		"expertise_audit_game_ready_tie_resolver_has_no_style_or_expertise_fallback",
		not tie_source.contains("TrainerProfile")
		and not tie_source.contains("expertise_id")
		and not tie_source.contains("difficulty_id")
		and tie_source.contains("\"player_current_action_used\": false")
	)
	_check.call("expertise_audit_aggregate", true)
	print(AGGREGATE)


func _all_unique(values: Array[String]) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""
