extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _finished: bool = false


func _initialize() -> void:
	# Run on the next frame so a runtime error inside the adversarial suite cannot leave a headless
	# SceneTree alive forever. The watchdog turns that situation into a bounded CI failure with logs.
	create_timer(5.0).timeout.connect(Callable(self, "_watchdog_timeout"))
	call_deferred("_run_suite")


func _run_suite() -> void:
	SavegameV2AdversarialTestSuite.new().run(Callable(self, "_check"))
	_finished = true
	print("\n=== SAVEGAME V2 ADVERSARIAL RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _watchdog_timeout() -> void:
	if _finished:
		return
	push_error("SAVEGAME V2 ADVERSARIAL WATCHDOG: suite did not finish within 5 seconds")
	quit(2)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
