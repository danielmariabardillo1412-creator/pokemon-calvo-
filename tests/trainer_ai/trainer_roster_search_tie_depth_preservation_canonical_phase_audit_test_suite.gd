class_name TrainerRosterSearchTieDepthPreservationCanonicalPhaseAuditTestSuite
extends TrainerRosterSearchTieDepthPreservationAuditTestSuite

# C3f-p canonical search-context adapter.
#
# C3f-m/C3f-o deliberately used a switching-only shadow observation phase named
# "action_selection". TrainerStrategicSwitchEvaluatorV2 does not execute Battle Core,
# so that synthetic label was sufficient for those audits. TrainerMultiTurnSearch,
# however, reconstructs BattleState from TrainerObservation and Battle Core accepts
# turns only in BattleState.WAITING_FOR_ACTIONS.
#
# This subclass keeps the certified C3f-o population, evidence, legal switch set,
# beliefs, memory and campaign snapshot unchanged. It changes only the synthetic
# observation phase to the canonical live-trainer phase before search worlds are
# built. Production code is untouched.


func _build_shadow_context(
	own_roster: Array[Dictionary],
	opponent_member: Dictionary,
	mode: String,
	catalog: DefinitionCatalog,
) -> TrainerDecisionContext:
	var context := super._build_shadow_context(own_roster, opponent_member, mode, catalog)
	if context != null and context.observation != null:
		context.observation.phase = BattleState.WAITING_FOR_ACTIONS
	return context


func _build_c3fp_report() -> Dictionary:
	var report := super._build_c3fp_report()
	report["source_shadow_phase"] = "action_selection"
	report["search_context_phase"] = String(BattleState.WAITING_FOR_ACTIONS)
	report["test_only_phase_adapter_used"] = true
	report["production_phase_logic_modified"] = false
	return report
