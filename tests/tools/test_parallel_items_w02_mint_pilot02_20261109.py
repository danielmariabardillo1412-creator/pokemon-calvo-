#!/usr/bin/env python3
"""W02 authorised MINT-L3 pilot02, independent of historical pilot01."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
spec=json.loads((ROOT/"tests/fixtures/parallel_items/w02_mint_pilot02_20261109.json").read_text(encoding="utf-8"))
assert (spec["worker"],spec["pilot"],spec["block"])==("W02","MINT-L3","02")
assert spec["ids"]==["adamant_mint","modest_mint","timid_mint"]
assert spec["modes"]==["active","reserve","none"]
assert spec["origin"]=={"pilot01_run":42696681590,"pilot01_sha":"9e2797a4972f22dbf14d5bc5f2d24bb212d29456","branch_base":"1a550eb774736d89e6161d4a981559726e40e046"}
expected=[("adamant_mint","adamant","attack","special_attack"),
          ("modest_mint","modest","special_attack","attack"),
          ("timid_mint","timid","speed","attack")]
assert [(x["id"],x["target_nature"],x["up"],x["down"]) for x in spec["cases"]]==expected
assert spec["sequential"]=={"first":"lonely_mint","second":"modest_mint",
"original_nature":"hardy","first_effective":"lonely","last_effective":"modest"}
assert spec["level100"]["ids"]==spec["ids"]
helper=(ROOT/"modules/inventory/field_mint_effects.gd").read_text(encoding="utf-8")
rules=(ROOT/"modules/creatures/progression/progression_ruleset.gd").read_text(encoding="utf-8")
service=(ROOT/"modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
creature=(ROOT/"modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
runner=(ROOT/"tests/gameplay/parallel_items_w02_mint_pilot02_20261109.gd").read_text(encoding="utf-8")
prior=(ROOT/"tests/tools/test_parallel_items_w02_mint_pilot_20261109.py").read_text(encoding="utf-8")
legacy=(ROOT/"tests/tools/test_parallel_items_w02_campaign_006.py").read_text(encoding="utf-8")
policy=json.loads((ROOT/"config/item_selection_v1.json").read_text(encoding="utf-8"))
for item,nature,up,down in expected:
    assert f'"{item}": "{nature}"' in helper,item
    assert f'&"{nature}": ["{up}", "{down}"]' in rules,nature
    assert item not in policy["excluded_ids"],item
assert "nature_mints" not in policy["excluded_categories"]
for item,nature in [("lonely_mint","lonely"),("mild_mint","mild"),("naive_mint","naive"),
                    ("naughty_mint","naughty"),("gentle_mint","gentle"),("rash_mint","rash"),
                    ("sassy_mint","sassy"),("serious_mint","serious")]:
    assert f'"{item}": "{nature}"' in helper,item
for item,nature in (("hasty_mint","hasty"),("lax_mint","lax"),("relaxed_mint","relaxed"),("jolly_mint","jolly"),("bold_mint","bold"),("calm_mint","calm"),("careful_mint","careful"),("brave_mint","brave"),("quiet_mint","quiet"),("impish_mint","impish")):
    assert f'"{item}": "{nature}"' in helper,item
assert "Mint.apply(candidate, item_id, catalogs)" in service
assert 'if Mint.supports(item_id):' in service
assert 'if not staged.remove(item_id): return _deny("item_not_owned")' in service
assert 'if not owner.replace_owned_same_identity(candidate): return _deny("ownership_changed")' in service
assert 'if candidate.stats.to_dict() == before:' in helper
assert 'candidate.effective_nature_id = desired' in helper
assert 'if current_nature == desired: return reject("item_has_no_effect")' in helper
assert 'var effective_nature_id: StringName = &""' in creature
for token in ('_probe_pilot02(spec, mode)','_probe_level100_02(spec)','_probe_replacement02(f.sequential)',
              'StatCalculator.compute(','svc.use_item(item, &"own")','svc.use_item(item, &"own", 0)',
              'creature_knocked_out','temporary_battle_state','invalid_mint_state',
              'now.nature_id == &"hardy" and now.effective_nature_id == target',
              'SaveGameRepository.new().decode_snapshot(','pilot02 legacy snapshot still loads',
              'pilot02 repeated mint no effect no second deduction',
              'pilot02 corrupt effective nature rejected','pilot02 sequence pilot01 mint applies first',
              'W02_MINT_PILOT02_20261109_GODOT'):
    assert token in runner,token
assert 'for item,nature in [("adamant_mint","adamant"),' in prior
assert 'for mint_id, nature_id in {"adamant_mint": "adamant",' in legacy
historic=json.loads((ROOT/"tests/fixtures/parallel_items/w02_campaign_005.json").read_text(encoding="utf-8"))
assert len(historic["blocks"])==10 and sum(len(x["cases"]) for x in historic["blocks"])==288
assert (ROOT/"tests/fixtures/parallel_items/w02_mint_pilot_20261109.json").exists()
print("W02_MINT_PILOT02_20261109_PY PASS checks=39")
