extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	TrainerEvaluationCorpusTestSuite.new().run(Callable(self, "_check"))
	TrainerBattleSessionActionProposalAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerBattleSessionAuthoritativeSubstitutionAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerBattleSessionMultiTurnAuthoritativeSubstitutionAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerBattleSessionAutonomousSideBSubmissionApiAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerBattleSessionTerminalHorizonCompletenessAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerBattleSessionCrossBattleResetLifecycleAuditTestSuite.new().run(Callable(self, "_check"))
	await TrainerBattleRuntimeIntegrationTestSuite.new().run(Callable(self, "_check"), self)
	await TrainerAIRuntimeFinalClosureTestSuite.new().run(Callable(self, "_check"), self)
	TrainerGameReadyHardeningTestSuite.new().run(Callable(self, "_check"))
	TrainerExpertiseContractAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerExpertiseBudgetSafetyAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerExpertiseRuntimeIntegrationTestSuite.new().run(Callable(self, "_check"))
	TrainerExpertiseBattleE2EClosureTestSuite.new().run(Callable(self, "_check"))
	TrainerCampaignPersistenceBoundaryAuditTestSuite.new().run(Callable(self, "_check"))
	print("\n=== TRAINER EVALUATION CORPUS RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
