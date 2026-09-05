from pathlib import Path

path = Path("modules/gameplay/trainer_battle_session.gd")
text = path.read_text()
old = '\tvar submitted_dict := substitution_report.get("submitted_action", null)\n'
new = '\tvar submitted_dict: Variant = substitution_report.get("submitted_action", null)\n'
count = text.count(old)
assert count == 1, f"expected exactly one autonomous untyped submitted_dict, found {count}"
path.write_text(text.replace(old, new, 1))
