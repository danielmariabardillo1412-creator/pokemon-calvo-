#!/usr/bin/env python3
"""W02 TANDA03 source/oracle and QA structure, runtime assertions in Godot."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
f=json.loads((root/"tests/fixtures/parallel_items/w02_autorun_v3.json").read_text(encoding="utf-8"))
assert (f["worker"],f["tanda"],len(f["rows"])) == ("W02","03",10)
assert f["modes"]==["active","reserve"]
assert [x["id"] for x in f["cases"]]==["direct","item","level","unminted","replace"]
code=(root/"modules/creatures/progression/evolution_system.gd").read_text(encoding="utf-8")
fstart=code.index("static func apply_evolution(")
fend=code.index("static func coverage_report(",fstart)
body=code[fstart:fend]
assert "new_creature.nature_id = creature.nature_id" in body
assert "new_creature.effective_nature_id = creature.effective_nature_id" in body
assert "new_creature.stats = StatCalculator.compute(base, new_creature.ivs, new_creature.evs, stat_nature, new_creature.level)" in body
assert 'new_creature.nature_id if new_creature.effective_nature_id == &"" else new_creature.effective_nature_id' in body
assert "new_creature.form_id" not in body # W04 protected form route never edited by W02
script=(root/"tests/gameplay/parallel_items_w02_autorun_v3.gd").read_text(encoding="utf-8")
for token in [
"_test_direct_minted(mode)", "_test_item_evolution(mode)", "_test_unminted_evolution(mode)",
"_test_same_original_effective(mode)", "_test_mint_replacement(mode)",
"_test_level_evolution(mode)", "_test_save_corruption(mode)",
"svc.evolve(&\"fire_stone\"", "svc.evolve(&\"water_stone\"",
"svc.use_growth_item(&\"rare_candy\"", "SaveGameRepository.new().decode_snapshot",
"v3 corrupted external snapshot never alters live owner", "v3 original adamant and effective adamant",
"_assert_effective(e, &\"timid\"", "W02_AUTORUN_V3_GODOT"
]: assert token in script, token
assert len(f["rows"])==10
print("W02_AUTORUN_V3_PY PASS checks=26")
