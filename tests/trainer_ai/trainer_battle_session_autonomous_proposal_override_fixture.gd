class_name TrainerBattleSessionAutonomousProposalOverrideFixture
extends TrainerBattleSession

# TEST-ONLY fixture for C3f-am fail-closed coverage. Production receives no injection hook.
var autonomous_proposal_override_enabled: bool = false
var autonomous_proposal_override_report: Dictionary = {}


func set_autonomous_proposal_override(report: Dictionary) -> void:
	autonomous_proposal_override_enabled = true
	autonomous_proposal_override_report = report.duplicate(true)


func clear_autonomous_proposal_override() -> void:
	autonomous_proposal_override_enabled = false
	autonomous_proposal_override_report = {}


func trainer_action_proposal_report_for_side(side_id: StringName) -> Dictionary:
	if autonomous_proposal_override_enabled:
		return autonomous_proposal_override_report.duplicate(true)
	return super.trainer_action_proposal_report_for_side(side_id)
