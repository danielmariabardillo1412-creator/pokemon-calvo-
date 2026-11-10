#!/usr/bin/env python3
"""Exact 10-row IA6 W02 AUTONOMY_V1 source and historic promotion gate."""
import csv, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
read=lambda p: (ROOT/p).read_text(encoding="utf-8")
f=json.loads(read("tests/fixtures/parallel_items/w02_autorun_v1.json"))
expected=[["hasty_mint","hasty","speed","defense"],["lax_mint","lax","defense","special_defense"],["relaxed_mint","relaxed","defense","speed"],["jolly_mint","jolly","speed","special_attack"],["bold_mint","bold","defense","attack"],["calm_mint","calm","special_defense","attack"],["careful_mint","careful","special_defense","special_attack"],["brave_mint","brave","attack","speed"],["quiet_mint","quiet","special_attack","speed"],["impish_mint","impish","defense","special_attack"]]
assert f["worker"]=="W02" and f["tanda"]=="01" and f["modes"]==["active","reserve","none"]
assert (f["frozen_sha"],f["frozen_ci"])==("9e2797a4972f22dbf14d5bc5f2d24bb212d29456",42696681590)
assert f["expected"]=={"positive":20,"negative":10,"level100":10,"sequential":10}
assert [(x["id"],x["target_nature"],x["up"],x["down"]) for x in f["rows"]]==[tuple(x) for x in expected]
assert [x["block"] for x in f["rows"]]==[f"{i:02d}" for i in range(1,11)]
mnt=read("modules/inventory/field_mint_effects.gd")
rules=read("modules/creatures/progression/progression_ruleset.gd")
migration=read("tests/gameplay/parallel_items_w02_campaign_005.gd")
godot=read("tests/gameplay/parallel_items_w02_autorun_v1.gd")
service=read("modules/inventory/field_item_service.gd")
policy=json.loads(read("config/item_selection_v1.json"))
old=json.loads(read("tests/fixtures/parallel_items/w02_campaign_005.json"))
historic=[c for b in old["blocks"] for c in b["cases"]]
assert len(historic)==288 and len(old["blocks"])==10
promoted={"adamant_mint","modest_mint","timid_mint"}|{x[0] for x in expected}
hist_promoted=[c for c in historic if c["kind"]=="mint_dependency" and c["id"] in promoted]
assert len(hist_promoted)==82 and f["promoted_historical"]==82
assert all(c["applies"] is False and c["expect_reason"]=="field_effect_not_connected" for c in hist_promoted)
for item,nature,up,down in expected:
    assert item not in policy["excluded_ids"],item
    assert f'"{item}": "{nature}"' in mnt,item
    assert f'&"{nature}": ["{up}", "{down}"]' in rules,item
    assert f'"{item}": "{nature}"' in migration,item
for token in ("historical_count == 82", "migration_counts", "now.to_dict() == exact",
              "StatCalculator.compute(", "promoted negative specific reason and no mutation"):
    assert token in migration,token
for token in ("_probe_pilot02(spec, mode)", "_probe_level100_02(spec)",
              "_probe_replacement02(", "positives == 20", "level100 == 10",
              "SaveV2", "W02_AUTORUN_V1_GODOT"):
    assert token in godot,token
assert "if Mint.supports(item_id):" in service
assert "Mint.apply(candidate, item_id, catalogs)" in service
with (ROOT/"docs/coordination/items_parallel_v1/reports/W02/AUTORUN_V1_PROGRESS.csv").open() as h:
    progress=list(csv.DictReader(h))
assert len(progress)==10 and [c["id"] for c in progress]==[x[0] for x in expected]
assert all(c["estado"] in {"IMPLEMENTADO_CI_PENDIENTE","CERTIFICADO","BLOQUEADO"} for c in progress)
print("W02_AUTORUN_V1_PY PASS rows=10 historical=288 promoted=82 checks=95")
