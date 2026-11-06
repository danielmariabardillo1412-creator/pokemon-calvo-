#!/usr/bin/env python3
"""W02 CAMP006 block08 source-bound contract; positive effects run in native Godot."""
import csv,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
d=json.loads((root/"tests/fixtures/parallel_items/w02_campaign_006_block08.json").read_text())
with (root/"docs/coordination/items_parallel_v1/reports/W02/CAMP_006_PROGRESO.csv").open(newline="") as f:
    p=list(csv.DictReader(f))
assert (d["worker"],d["campaign"],d["block"],d["family"])==("W02","CAMP_006","08","TRAINING_HELD")
assert d["ids"]==["macho_brace","soothe_bell"] and d["modes"]==["active","reserve","none"]
assert d["origin"]=={"run_id":42232974438,"sha":"2c727c47c057eeb4cebb02c51b33ebe873a8d55c","conclusion":"success"}
assert d["cases"]==[
    {"id":"macho_brace","effect":"battle_ev_multiplier","foe":"magikarp","stat":"speed","base_yield":1,"expected_yield":2,"cap_per_stat":252,"cap_total":510},
    {"id":"soothe_bell","effect":"friendship_from_vitamin","trigger":"protein","friendship_initial":99,"base_gain":5,"held_gain":7,"max_friendship":255}]
assert len(p)==8 and p[6]["ci_run"]=="42232974438"
assert p[7]["ids"]=="macho_brace;soothe_bell" and p[7]["estado"]=="PRUEBAS_NATIVAS_PUBLICADAS_CI_PENDIENTE"
ev=(root/"modules/creatures/progression/battle_ev_rewards.gd").read_text()
friend=(root/"modules/inventory/field_friendship_effects.gd").read_text()
train=(root/"modules/inventory/field_training_effects.gd").read_text()
prog=(root/"modules/creatures/progression/progression_system.gd").read_text()
runner=(root/"tests/gameplay/parallel_items_w02_campaign_006_block08.gd").read_text()
assert 'base * 2 if item == "macho_brace" else base' in ev
assert 'creature.held_item_id == &"soothe_bell"' in friend and 'gain = gain * 3 / 2' in friend
assert 'Friendship.increase(creature, [5, 3, 2] if vitamin else [3, 2, 1])' in train
assert 'BattleEvRewards.award(sp, outcome.defeated, catalogs, ruleset, starting_items)' in prog
for snippet in ("svc.equip(","active.use_item(&\"protein\"","ProgressionSystem.reconcile_battle_result(","Ev08.award(","Friend08.increase(","_reload08(","CAMP006_W02_HELD08","cap255","cap510","changed start snapshot","direct use rejected"):
    assert snippet in runner, snippet
old=json.loads((root/"tests/fixtures/parallel_items/w02_campaign_005.json").read_text())
assert sum(len(x["cases"]) for x in old["blocks"])==288
print("CAMP006_W02_HELD08_PY PASS block=08 checks=28")
