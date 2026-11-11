extends SceneTree

# Run in a clean temp project, with the original localization helper copied in.
# Pass "missing" or "invalid" via --. Each invocation is a fresh process so
# the helper's static _loaded cache cannot hide a broken initial load.
const SOURCE := "res://data/localization/machine_moves_es_sv_v1.json"
const HELPER := "res://modules/localization/machine_moves_es_sv_w05.gd"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not args[0] in ["missing", "invalid"]:
		print("W05_V5_FALLBACK FAIL reason=bad_test_mode")
		quit(2)
		return
	var mode := args[0]
	if mode == "missing" and FileAccess.file_exists(SOURCE):
		print("W05_V5_FALLBACK FAIL reason=file_should_not_exist")
		quit(2)
		return
	if mode == "invalid" and not FileAccess.file_exists(SOURCE):
		print("W05_V5_FALLBACK FAIL reason=fixture_missing")
		quit(2)
		return
	var helper: Variant = load(HELPER)
	if helper == null:
		print("W05_V5_FALLBACK FAIL reason=helper_cannot_load")
		quit(2)
		return
	var result: Dictionary = helper.resolve(&"take_down", "Nombre sin verificar")
	if result.get("name", "") != "Nombre sin verificar" or result.get("verified_es", true) or result.get("source_locale", "") != "fallback" or int(result.get("source_api_id", -1)) != 0 or result.get("move_id", "") != "take_down":
		print("W05_V5_FALLBACK FAIL reason=unexpected_fallback status=" + str(result))
		quit(1)
		return
	print("W05_V5_FALLBACK PASS mode=%s verified=false source=fallback" % mode)
	quit(0)
