from pathlib import Path
p = Path('modules/gameplay/trainer_battle_session.gd')
s = p.read_text()
old = '\t\tvar submitted_dict := substitution_report.get("submitted_action", null)\n'
new = '\t\tvar submitted_dict: Variant = substitution_report.get("submitted_action", null)\n'
assert s.count(old) == 1, s.count(old)
p.write_text(s.replace(old, new, 1))
