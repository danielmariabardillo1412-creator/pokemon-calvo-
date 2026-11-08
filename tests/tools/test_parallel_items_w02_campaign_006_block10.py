#!/usr/bin/env python3
"""W02 CAMP006 block10: native training E2E contract, precise EXP Share dependency."""
import csv,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
f=json.loads((root/"tests/fixtures/parallel_items/w02_campaign_006_block10.json").read_text(encoding="utf-8"))
with (root/"docs/coordination/items_parallel_v1/reports/W02/CAMP_006_PROGRESO.csv").open(newline="") as fp:
    rows=list(csv.DictReader(fp))
assert (f["worker"],f["campaign"],f["block"],f["family"])==("W02","CAMP_006","10","TRAINING_E2E")
assert f["ids"]==["exp_share","lucky_egg","soothe_bell"]
assert f["modes"]==["active","reserve","none"]
assert f["origin"]=={"run_id":42418112808,"conclusion":"success","head_sha":"7ac50f4fce12ee19fe9862538ca0ccd6a30939e0"}
assert [(x["id"],x["kind"]) for x in f["cases"]]==[
 ("exp_share","dependency"),("lucky_egg","positive_battle_xp"),
 ("soothe_bell","positive_field_friendship")]
assert len(rows)==10 and rows[9]["ids"]=="exp_share;lucky_egg;soothe_bell"
assert rows[8]["ci_run"]=="42418112808" and rows[8]["estado"]=="TRES_FUNCIONALES_CI_VERIFICADA"
assert rows[9]["ci_run"]=="CI_BLOQUE10_PENDIENTE"
assert rows[9]["estado"]=="DOS_FUNCIONALES_UNA_DEPENDENCIA_CI_PENDIENTE"
dep=f["dependency"]
assert dep["key"]=="EXP_SHARE_NONPARTICIPANT_XP_POLICY_006_W02"
assert dep["owner"]=="IA6" and dep["level"]=="L1_DEPENDENCY_NOT_L2"
assert dep["do_not_fake_distribution"] is True
assert all(dep.get(key) for key in ["producer","consumer","missing","positive_test_pending"])
progression=(root/"modules/creatures/progression/progression_system.gd").read_text()
held=(root/"modules/creatures/progression/progression_held_items.gd").read_text()
friendship=(root/"modules/inventory/field_friendship_effects.gd").read_text()
runner=(root/"tests/gameplay/parallel_items_w02_campaign_006_block10.gd").read_text()
assert "for sp in survivors:" in progression
assert "survivors.append(c)" in progression
assert "exp_share" not in progression and "exp_share" not in held
assert 'active_item(creature,&"lucky_egg")' in held and 'amount=amount*3/2' in held
assert 'creature.held_item_id == &"soothe_bell"' in friendship
assert 'gain = gain * 3 / 2' in friendship
for frag in ("service2.equip(", "owner.withdraw(", "owner.deposit(", "_held05_outcome()",
             "ProgressionSystem.reconcile_battle_result(", "active_service.use_item(&\"protein\"",
             "SaveGameRepository.new().decode_snapshot(", "EXP Share dependency", "no phantom consumption",
             "CAMP006_W02_FINAL10", "dependency=", "positive=", "negative="):
    assert frag in runner, frag
historic=json.loads((root/"tests/fixtures/parallel_items/w02_campaign_005.json").read_text())
assert sum(len(block["cases"]) for block in historic["blocks"])==288
print("CAMP006_W02_FINAL10_PY PASS block=10 positives=2 dependency=1 checks=27")
