extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var check_callback := Callable(self, "_check")
	# FASE 19/20 and the full Godot suite already run as independent PR gates.
	# Keep this runner focused on the 34 new FASE 21 checks so CI does not import
	# the full dataset three extra times inside a redundant nested regression run.
	TrainerTacticalIntelligenceTestSuite.new().run(check_callback)
	print(
		"\n=== TRAINER TACTICAL INTELLIGENCE RESULT: %d PASS / %d FAIL ==="
		% [_passed, _failed]
	)
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
