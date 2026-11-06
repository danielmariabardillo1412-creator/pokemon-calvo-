#!/usr/bin/env python3
"""W02 CAMP006 block07 contract. Godot is the positive runtime authority."""
from pathlib import Path
import json, csv
R=Path(__file__).resolve().parents[2]
with (R/"tests/fixtures/parallel_items/w02_campaign_006_block07.json").open() as f:
    data=json.load(f)
with (R/"docs/coordination/items_parallel_v1/reports/W02/CAMP_006_PROGRESO.csv").open(newline="") as f:
    rows=list(csv.DictReader(f))
assert (data["worker"],data["campaign"],data["block"],data["family"])==("W02","CAMP_006","07","TRAINING_HELD")
assert data["ids"]==["power_bracer","power_lens","power_weight"]
assert [(x["id"],x["stat"],x["expected_power_bonus"]) for x in data["cases"]]==[
    ("power_bracer","attack",8),("power_lens","special_attack",8),("power_weight","hp",8)]
assert data["rules"]=={"bonus_per_defeat":8,"per_stat_cap":252,"total_cap":510}
assert data["modes"]==["active","reserve","none"]
assert data["baseline_gate"]=={
    "run_id":41972015003,"conclusion":"success","head_sha":"58dc8103c8dd85275d477d4f563ca7ef279d9f86"}
assert len(rows)==7 and rows[-1]["bloque"]=="07"
assert rows[-1]["ids"]=="power_bracer;power_lens;power_weight"
assert rows[-1]["estado"]=="PRUEBAS_NATIVAS_PUBLICADAS_CI_PENDIENTE"
assert rows[-1]["ci_run"]=="CI_BLOQUE07_PENDIENTE"
assert rows[-2]["ci_run"]=="41972015003"
source=(R/"modules/creatures/progression/battle_ev_rewards.gd").read_text()
progression=(R/"modules/creatures/progression/progression_system.gd").read_text()
runner=(R/"tests/gameplay/parallel_items_w02_campaign_006_block07.gd").read_text()
for item in data["cases"]:
    assert ('"'+item["id"]+'": "'+item["stat"]+'"') in source, item["id"]
assert "BattleEvRewards.award(sp, outcome.defeated, catalogs, ruleset, starting_items)" in progression
for token in (
    "svc.equip(", "ProgressionSystem.reconcile_battle_result(",
    "SaveGameRepository.new().decode_snapshot(",
    "BattleEvRewards.award(", "CAMP006_W02_EV07",
    "positive=",", "mismatched_gain",
    "cap510", "cap252", "available_for_power"
):
    assert token in runner, token
old=json.loads((R/"tests/fixtures/parallel_items/w02_campaign_005.json").read_text())
assert sum(len(b["cases"]) for b in old["blocks"])==288
print("CAMP006_W02_EV07_PY PASS block=07 checks=26")
