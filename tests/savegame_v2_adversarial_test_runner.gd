extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	SavegameV2AdversarialTestSuite.new().run(Callable(self, "_check"))
	print("\n=== SAVEGAME V2 ADVERSARIAL RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
