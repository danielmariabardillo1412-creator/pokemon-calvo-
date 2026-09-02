extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	TrainerLoadoutsV2TestSuite.new().run(Callable(self, "_check"))
	TrainerRosterRoleInferenceFixtureTestSuite.new().run(Callable(self, "_check"))
	TrainerRosterRoleInferenceTestSuite.new().run(Callable(self, "_check"))
	TrainerRosterRoleRealDataTestSuite.new().run(Callable(self, "_check"))
	TrainerRosterRoleLabelCalibrationTestSuite.new().run(Callable(self, "_check"))
	print("\n=== TRAINER LOADOUTS RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
