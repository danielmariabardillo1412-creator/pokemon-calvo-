from pathlib import Path

p = Path('modules/gameplay/trainer_battle_session.gd')
s = p.read_text()

old = '\tvar events := _battle_server.submit_turn([player_action, authoritative_opponent_action])\n'
new = '''\tvar events: Array[BattleEvent] = []\n\tif _trainer_action_substitution_enabled:\n\t\tevents = _battle_server.submit_turn([player_action, authoritative_opponent_action])\n\telse:\n\t\tevents = _submit_explicit_opponent_action(player_action, opponent_action)\n'''
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new, 1)

marker = '\n\n# Trainer battles settle only after Battle Core reaches FINISHED. Capture/Flee are not settlement\n'
assert s.count(marker) == 1, s.count(marker)
helper = '''\n\n# Preserve the historical explicit-caller path exactly when C3f-ak substitution is OFF.\n# This helper is live production code, not a compatibility stub: submit_player_action uses it\n# on the disabled/default path and returns the same authoritative event batch.\nfunc _submit_explicit_opponent_action(\n\tplayer_action: BattleAction,\n\topponent_action: BattleAction,\n) -> Array[BattleEvent]:\n\tvar events := _battle_server.submit_turn([player_action, opponent_action])\n\treturn events\n'''
s = s.replace(marker, helper + marker, 1)
p.write_text(s)
