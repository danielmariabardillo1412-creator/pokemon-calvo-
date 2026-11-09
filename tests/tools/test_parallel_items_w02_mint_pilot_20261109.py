#!/usr/bin/env python3
"""IA6 W02 MINT-L3 01: narrow authorised mapping, positive native runtime gate."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
spec=json.loads((ROOT/"tests/fixtures/parallel_items/w02_mint_pilot_20261109.json").read_text(encoding="utf-8"))
assert (spec["worker"],spec["pilot"],spec["block"])==("W02","MINT-L3","01")
assert spec["ids"]==["lonely_mint","mild_mint","naive_mint"]
assert spec["modes"]==["active","reserve","none"]
assert spec["base_gate"]=={"run_id":42690004814,"sha":"662905404193b5247a55962fd08bf295871d7b53","conclusion":"success"}
expected=[("lonely_mint","lonely","attack","defense"),
          ("mild_mint","mild","special_attack","defense"),
          ("naive_mint","naive","speed","special_defense")]
assert [(x["id"],x["target_nature"],x["up"],x["down"]) for x in spec["cases"]]==expected
mint=(ROOT/"modules/inventory/field_mint_effects.gd").read_text()
rules=(ROOT/"modules/creatures/progression/progression_ruleset.gd").read_text()
service=(ROOT/"modules/inventory/field_item_service.gd").read_text()
creature=(ROOT/"modules/creatures/domain/creature_instance.gd").read_text()
runner=(ROOT/"tests/gameplay/parallel_items_w02_mint_pilot_20261109.gd").read_text()
legacy=(ROOT/"tests/tools/test_parallel_items_w02_campaign_006.py").read_text()
for item,nature,up,down in expected:
    assert f'"{item}": "{nature}"' in mint,item
    assert f'&"{nature}": ["{up}", "{down}"]' in rules,nature
for item,nature in [("gentle_mint","gentle"),("naughty_mint","naughty"),
                    ("rash_mint","rash"),("sassy_mint","sassy"),("serious_mint","serious")]:
    assert f'"{item}": "{nature}"' in mint,item
for item in ["hasty_mint","lax_mint","adamant_mint","modest_mint"]:
    assert f'"{item}"' not in mint,item
for token in ('func _apply_mint_item(', 'if Mint.supports(item_id):',
              'Mint.apply(candidate, item_id, catalogs)',
              'if not staged.remove(item_id): return _deny("item_not_owned")',
              'if not owner.replace_owned_same_identity(candidate): return _deny("ownership_changed")'):
    assert token in service,token
assert 'candidate.effective_nature_id = desired' in mint
assert 'if current_nature == desired: return reject("item_has_no_effect")' in mint
assert 'var effective_nature_id: StringName = &""' in creature
assert 'if effective_nature_id != &"": result["effective_nature_id"]' in creature
assert 'SaveGameRepository.new().decode_snapshot(' in runner
for token in ("_probe_mint_l3(spec, mode)","StatCalculator.compute(",
              "svc.use_item(item, &\"own\", 0)","MintPilot.apply(transformed, item, catalogs)",
              "gentle to lonely","duplicate no-effect atomic rollback","legacy keeps original statistics",
              "SaveV2 effective nature and bag","corrupt effective nature SaveV2",
              "positive == 6 and negative == 3","W02_MINT_PILOT_20261109_GODOT"):
    assert token in runner,token
assert 'for mint_id, nature_id in {"lonely_mint": "lonely",' in legacy
assert 'gentle_mint' in legacy
historic=json.loads((ROOT/"tests/fixtures/parallel_items/w02_campaign_005.json").read_text())
assert len(historic["blocks"])==10
assert sum(len(block["cases"]) for block in historic["blocks"])==288
print("W02_MINT_PILOT_20261109_PY PASS checks=35")
