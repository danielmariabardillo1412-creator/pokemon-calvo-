extends SceneTree

# Execute from a NEW empty Godot project and mount only the exported PCK.
# This avoids the false positive caused by reading the repository working tree.
const TABLE := "res://data/localization/machine_moves_es_sv_v1.json"
const EXPECTED := {
	"take_down": "Derribo",            # tm01
	"light_screen": "Pantalla de Luz", # tm75
	"pain_split": "Divide Dolor",      # tm202
	"upper_hand": "Palma Rauda",       # tm229
}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		print("W05_V5_PCK_PROBE FAIL reason=expected_one_pack_arg")
		quit(2)
		return
	var pack_path := args[0]
	if not ProjectSettings.load_resource_pack(pack_path, false):
		print("W05_V5_PCK_PROBE FAIL reason=pack_mount")
		quit(2)
		return
	if not FileAccess.file_exists(TABLE):
		print("W05_V5_PCK_PROBE FAIL reason=missing_json_from_export")
		quit(1)
		return
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE))
	if not doc is Dictionary:
		print("W05_V5_PCK_PROBE FAIL reason=invalid_json_from_export")
		quit(1)
		return
	var rows: Variant = doc.get("entries", {})
	if not rows is Dictionary:
		print("W05_V5_PCK_PROBE FAIL reason=invalid_rows")
		quit(1)
		return
	if doc.get("schema_version", 0) != 1 or doc.get("locale", "") != "es" or rows.size() != 229:
		print("W05_V5_PCK_PROBE FAIL reason=invalid_schema_or_count")
		quit(1)
		return
	for key: String in EXPECTED.keys():
		var entry: Variant = rows.get(key, null)
		if not entry is Dictionary or entry.get("nombre_es", "") != EXPECTED[key]:
			print("W05_V5_PCK_PROBE FAIL reason=mismatch move=" + key)
			quit(1)
			return
	print("W05_V5_PCK_PROBE PASS records=229 runtime_samples=4 source=pck_only")
	quit(0)
