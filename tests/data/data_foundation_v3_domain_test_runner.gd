extends SceneTree

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DataFoundationV3DomainTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AccuracyTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3SelectedSpecialTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3SelectedStatefulTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AllOpponentsTestSuite.new().run(Callable(self, "_check"))
	print("\n=== DATA FOUNDATION V3 DOMAIN RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
