extends SceneTree

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	await BattleRunPresentationTestSuite.new().run(_check, self)
	await BattleRunPresentationAuditTestSuite.new().run(_check, self)
	print("")
	print("=== BATTLE RUN PRESENTATION RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % label)
	else:
		_failed += 1
		print("FAIL  %s" % label)
