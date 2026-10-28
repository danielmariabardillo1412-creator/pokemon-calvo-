extends SceneTree

var checks := 0
var errors: Array[String] = []
var fired: Dictionary = {}
const BUTTON_ACTIONS := {
	"F4 · Ensayo Tera (reinicia)": "tera", "F5 · Elementales (reinicia)": "elemental",
	"F6 · Ensayo parcial": "external", "Frecuencia: 15 %": "frequency",
	"Reiniciar": "restart", "F1 · Ajustes": "settings", "F2 · Colisiones": "geometry",
	"F3 · Pokémon": "gallery", "Informe": "report",
}

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)

func _run() -> void:
	var theme := Theme.new()
	var hud_script := load("res://scenes/visual/field_hud.gd")
	var hud = hud_script.new()
	var actions := {}
	for action: String in BUTTON_ACTIONS.values():
		fired[action] = 0
		actions[action] = _record.bind(action)
	var built = hud.build(theme, actions)
	check("built is hud", built == hud)
	check("name FieldHUD", hud.name == "FieldHUD")
	check("place_label", hud.place_label != null)
	check("frequency_label", hud.frequency_label != null)
	check("observed_label", hud.observed_label != null)
	check("collection_label", hud.collection_label != null)
	check("chance_button", hud.chance_button != null)
	check("notice_label", hud.notice_label != null)
	var buttons: Array[Button] = []
	_collect_buttons(hud, buttons)
	check("exactly nine buttons", buttons.size() == 9)
	for action: String in fired: check("no callback on build " + action, fired[action] == 0)
	var seen := {}
	for button: Button in buttons:
		check("known unique button " + button.text, BUTTON_ACTIONS.has(button.text) and not seen.has(button.text))
		if not BUTTON_ACTIONS.has(button.text): continue
		seen[button.text] = true
		var action: String = BUTTON_ACTIONS[button.text]
		var before: Dictionary = fired.duplicate()
		button.pressed.emit()
		for key: String in fired:
			check("correct action exactly once " + action + "/" + key, fired[key] == int(before[key]) + (1 if key == action else 0))
	check("all nine actions exercised", seen.size() == 9)
	for property: String in ["place_label", "frequency_label", "observed_label", "collection_label", "chance_button", "notice_label"]:
		var node: Node = hud.get(property)
		check("public control belongs to HUD " + property, node != null and hud.is_ancestor_of(node))
	check("chance reference is the connected frequency button", hud.chance_button.text == "Frecuencia: 15 %" and buttons.has(hud.chance_button))
	hud.free()
	if errors.is_empty():
		print("FIELD_HUD_CONTRACT PASS checks=%d" % checks)
		quit(0)
	else:
		for e in errors: printerr(e)
		quit(1)

func _record(action: String) -> void:
	fired[action] = int(fired[action]) + 1


func _collect_buttons(node: Node, output: Array[Button]) -> void:
	if node is Button: output.append(node)
	for child: Node in node.get_children(): _collect_buttons(child, output)
