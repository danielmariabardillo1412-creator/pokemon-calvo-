extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	TrainerRosterFrontierSwitchingShadowOverlapAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerRosterStructuralRealDataAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerRosterStructuralOverlapRealDataAuditTestSuite.new().run(Callable(self, "_check"))
	TrainerRosterStructuralFormulaComparisonTestSuite.new().run(Callable(self, "_check"))
	TrainerRosterStructuralFormulaSensitivityTestSuite.new().run(Callable(self, "_check"))
	print("\n=== TRAINER TEAM COMPOSITION RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
