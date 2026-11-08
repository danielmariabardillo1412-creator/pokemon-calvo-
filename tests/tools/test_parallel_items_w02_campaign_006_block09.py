#!/usr/bin/env python3
"""CAMP006 W02 block09: verify genuine ability/mint routes and cumulative gates."""
import csv,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
d=json.loads((root/"tests/fixtures/parallel_items/w02_campaign_006_block09.json").read_text())
with (root/"docs/coordination/items_parallel_v1/reports/W02/CAMP_006_PROGRESO.csv").open(newline="") as f:
    p=list(csv.DictReader(f))
assert (d["worker"],d["campaign"],d["block"],d["family"])==("W02","CAMP_006","09","TRAINING_E2E")
assert d["ids"]==["ability_capsule","ability_patch","gentle_mint"]
assert d["modes"]==["active","reserve","none"]
assert d["origin"]=={"run_id":42254167309,"sha":"d1f9ea1f2ecbed44e21cf9e6d6398dfff4fdd19f","conclusion":"success"}
assert [(x["id"],x["kind"]) for x in d["cases"]]==[
    ("ability_capsule","ability"),("ability_patch","ability"),("gentle_mint","mint")]
assert len(p)==10 and p[7]["ci_run"]=="42254167309"
assert p[8]["bloque"]=="09" and p[8]["estado"]=="TRES_FUNCIONALES_CI_VERIFICADA"
assert p[8]["ci_run"]=="42418112808"
ability=(root/"modules/inventory/field_ability_effects.gd").read_text()
mint=(root/"modules/inventory/field_mint_effects.gd").read_text()
service=(root/"modules/inventory/field_item_service.gd").read_text()
creature=(root/"modules/creatures/domain/creature_instance.gd").read_text()
runner=(root/"tests/gameplay/parallel_items_w02_campaign_006_block09.gd").read_text()
assert 'item_id in [&"ability_capsule", &"ability_patch"]' in ability
assert 'destination = 2 if current == 1 else 1' in ability
assert 'destination = 1 if current == 3 else 3' in ability
assert '"gentle_mint": "gentle"' in mint
assert 'candidate.effective_nature_id = desired' in mint
assert 'var effective_nature_id: StringName = &""' in creature
assert 'var stat_nature: StringName = nature_id if effective_nature_id == &"" else effective_nature_id' in creature
assert 'if Mint.supports(item_id):' in service
assert 'expected_ability_stamp != "" and expected_ability_stamp != ability.stamp' in service
for fragment in ("service.ability_preview(","service.use_item(", "stale stamp atomic rejection",
                 "gentle_mint repeat no-effect atomic", "SaveGameRepository.new().decode_snapshot(",
                 "StatCalculator.compute(", "effective_nature_id == &\"gentle\"",
                 "CAMP006_W02_TRAIN09", "negative=", "positive="):
    assert fragment in runner,fragment
old=json.loads((root/"tests/fixtures/parallel_items/w02_campaign_005.json").read_text())
assert sum(len(b["cases"]) for b in old["blocks"])==288
print("CAMP006_W02_TRAIN09_PY PASS block=09 checks=28")
