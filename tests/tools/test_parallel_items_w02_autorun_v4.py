#!/usr/bin/env python3
"""W02 TANDA04: structural no-double-recompute gate + exact 10-row native test."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
f=json.loads((root/"tests/fixtures/parallel_items/w02_autorun_v4.json").read_text(encoding="utf8"))
assert f["worker"]=="W02" and f["tanda"]=="04" and f["new_items"]==0
assert f["baseline"]["run_id"]==42890511612
assert f["baseline"]["functional_sha"]=="17df457b1320eec379ef78059cd14c4f6e5576e1"
assert f["modes"]==["active","reserve"] and len(f["checks"])==10
script=(root/"tests/gameplay/parallel_items_w02_autorun_v4.gd").read_text(encoding="utf8")
for token in (
"_probe_equivalence(mode)", "_test_level_evolution(mode)", "_probe_vaporeon_item(mode)",
"_probe_multilevel(mode)", "_test_unminted_evolution(mode)", "_test_mint_replacement(mode)",
"_test_same_original_effective(mode)", "_test_save_corruption(mode)",
"legacy_fallback.recalculate_stats(", "legacy_fallback.to_dict() == new_evolution.to_dict()",
"svc.use_growth_item(&\"exp_candy_xl\"", "svc.evolve(&\"water_stone\"",
"SaveV2", "W02_AUTORUN_V4_GODOT"):
    assert token in script,token
growth=(root/"modules/inventory/field_growth_effects.gd").read_text(encoding="utf8")
a=growth.index("static func plan(")
segment=growth[a:]
assert "EvolutionSystem.apply_evolution(c, StringName(choice), catalogs, ProgressionRuleset.new())" in segment
assert "c.current_hp = clampi(old_hp + c.stats.max_hp - old_max, 1, c.stats.max_hp)" in segment
# Deliberate RED before scoped repair. It must never count as green until the
# duplicated recalculation is removed; the old approved result is CI#42890511612.
assert "effective_before_evolution" not in segment, "Growth.plan still repeats effective nature and recalculates"
assert "c.recalculate_stats(catalogs.species(c.species_id), ProgressionRuleset.new())" not in segment
evolution=(root/"modules/creatures/progression/evolution_system.gd").read_text(encoding="utf8")
assert "new_creature.effective_nature_id = creature.effective_nature_id" in evolution
assert "new_creature.stats = StatCalculator.compute(base, new_creature.ivs, new_creature.evs, stat_nature, new_creature.level)" in evolution
instance=(root/"modules/creatures/domain/creature_instance.gd").read_text(encoding="utf8")
assert "var effective_nature_id: StringName" in instance
assert "var form_id:" not in instance, "W04 form_id is not in this baseline; integration cannot be assumed"
print("W02_AUTORUN_V4_PY PASS checks=23")
