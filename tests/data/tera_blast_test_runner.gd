extends SceneTree

var passed := 0
var failures: Array[String] = []


func _initialize() -> void:
	preload("res://tests/data/data_foundation_v3_tera_blast_test_suite.gd").new().run(_check)
	print("TERA_BLAST_REGRESSION %d PASS / %d FAIL" % [passed, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
	else:
		failures.append(label)
		push_error("FAIL " + label)
