from pathlib import Path
p = Path('tests/trainer_ai/trainer_battle_session_authoritative_substitution_audit_test_suite.gd')
s = p.read_text()
old1 = '\tvar submitted := substitution.get("submitted_action", null)\n'
new1 = '\tvar submitted: Variant = substitution.get("submitted_action", null)\n'
old2 = '\tvar proposal_action := proposal.get("proposal_action", null)\n'
new2 = '\tvar proposal_action: Variant = proposal.get("proposal_action", null)\n'
assert s.count(old1) == 1, s.count(old1)
assert s.count(old2) == 1, s.count(old2)
s = s.replace(old1, new1, 1).replace(old2, new2, 1)
p.write_text(s)
