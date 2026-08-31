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
	DataFoundationV3UserStatefulSafeTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3UserHpCostTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3UserMandatoryStateTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3UserPersistentStateTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3UserTerminalStateTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AllPokemonTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3FinalDataOnlyEffectsTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AbilityRuntimeContractTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AbilityFamilyInventoryTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AbilityHitStatTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AbilityContactDamageTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AbilityDefensiveDamageTestSuite.new().run(Callable(self, "_check"))
	DataFoundationV3AbilityMovePropertyTestSuite.new().run(Callable(self, "_check"))
	print("\n=== DATA FOUNDATION V3 DOMAIN RESULT: %d PASS / %d FAIL ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(name: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("PASS  %s" % name)
	else:
		_failed += 1
		push_error("FAIL  %s" % name)
