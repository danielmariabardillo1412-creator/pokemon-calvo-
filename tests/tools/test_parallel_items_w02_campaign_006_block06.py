#!/usr/bin/env python3
"""Block06 guarded fixture and real-source contract. Native effects tested by Godot."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
f=json.loads((R/"tests/fixtures/parallel_items/w02_campaign_006_block06.json").read_text())
assert (f["worker"],f["campaign"],f["block"]) == ("W02","CAMP_006","06")
assert f["ids"] == ["power_anklet","power_band","power_belt"]
assert [(c["id"],c["stat"]) for c in f["cases"]] == [
 ("power_anklet","speed"),("power_band","special_defense"),("power_belt","defense")]
assert f["rules"] == {"bonus_per_defeat":8,"per_stat_cap":252,"total_cap":510}
assert f["modes"] == ["active","reserve","none"]
src=(R/"modules/creatures/progression/battle_ev_rewards.gd").read_text()
progression=(R/"modules/creatures/progression/progression_system.gd").read_text()
runner=(R/"tests/gameplay/parallel_items_w02_campaign_006_block06.gd").read_text()
for x in f["cases"]:
 assert '"'+x["id"]+'": "'+x["stat"]+'"' in src
for frag in ("+ 8","EV_PER_STAT_MAX","EV_TOTAL_MAX","stable_training_item","recalculate_stats"):
 assert frag in src,frag
assert "BattleEvRewards.award(sp, outcome.defeated, catalogs, ruleset, starting_items)" in progression
for frag in ("svc.equip(","SaveGameRepository.new().decode_snapshot(","ProgressionSystem.reconcile_battle_result(","BattleEvRewards.award(","positive=", "cap510","cap252"):
 assert frag in runner,frag
old=json.loads((R/"tests/fixtures/parallel_items/w02_campaign_005.json").read_text())
assert sum(len(b["cases"]) for b in old["blocks"])==288
print("CAMP006_W02_EV06_PY PASS block=06 checks=24")
