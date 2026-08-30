extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var check_callback := Callable(self, "_check")
	TrainerIntelligenceFoundationTestSuite.new().run(check_callback)
	TrainerIntelligenceMetadataAuditTestSuite.new().run(check_callback)
	print("\n=== TRAINER INTELLIGENCE FOUNDATION RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
