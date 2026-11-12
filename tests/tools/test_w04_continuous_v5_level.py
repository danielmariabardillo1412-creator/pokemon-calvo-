#!/usr/bin/env python3
"""W04 V5: canonical metadata gate, not a substitute for native Godot L3 tests."""
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
expected = {
    "diglett_alola": ("dugtrio_alola", 26),
    "geodude_alola": ("graveler_alola", 25),
    "grimer_alola": ("muk_alola", 38),
    "meowth_galar": ("perrserker", 28),
    "ponyta_galar": ("rapidash_galar", 40),
    "mr_mime_galar": ("mr_rime", 42),
    "corsola_galar": ("cursola", 38),
    "zigzagoon_galar": ("linoone_galar", 20),
    "zorua_hisui": ("zoroark_hisui", 30),
    "wooper_paldea": ("clodsire", 20),
}
blocked = {
    "rattata_alola": ("raticate_alola", "time_of_day"),
    "meowth_alola": ("persian_alola", "min_happiness"),
    "linoone_galar": ("obstagoon", "time_of_day"),
    "qwilfish_hisui": ("overqwil", "known_move"),
    "sneasel_hisui": ("sneasler", "held_item"),
    "sliggoo_hisui": ("goodra_hisui", "needs_overworld_rain"),
}
data = json.loads((ROOT / "config/pokemon_variants_v1.json").read_text(encoding="utf8"))
regional = data["regional_species"]
assert len(regional) == 57, "regional species cardinality changed"
entries = [(src, e) for src, species in regional.items() for e in species["evolutions"]]
counts = Counter(e["trigger"] for _, e in entries)
assert len(entries) == 28 and counts["level_up"] == 16 and counts["use_item"] == 7
assert counts["trade"] == 1 and sum(counts[t] for t in counts if t not in {"level_up", "use_item", "trade"}) == 4
levels = [(src, e) for src, e in entries if e["trigger"] == "level_up"]
unconditional = {src: (e["species_id"], e["min_level"]) for src, e in levels if not e["conditions"]}
assert unconditional == expected, f"unconditional routes drifted: {unconditional}"
conditioned = {src: e for src, e in levels if e["conditions"]}
assert conditioned.keys() == blocked.keys(), f"conditional routes drifted: {conditioned.keys()}"
for src, (dest, condition_key) in blocked.items():
    assert conditioned[src]["species_id"] == dest and condition_key in conditioned[src]["conditions"]
    assert conditioned[src]["conditions"], "condition must not be simplified"
contract = (ROOT / "modules/creatures/progression/regional_level_evolution_contract_w04_v5.gd").read_text(encoding="utf8")
for source, (target, level) in expected.items():
    marker = f'&"{source}": {{&"target": &"{target}", &"level": {level}}}'
    assert marker in contract, f"missing exact route in pure helper: {marker}"
assert "Canonical.from_factory_source" in contract
assert "invalid_source_form" in contract and "target_form_not_verified" in contract
engine = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text(encoding="utf8")
assert "regional_item_evolution_contract_w04_v2.gd" in engine, "V4 item route removed"
assert "regional_level_evolution_contract_w04_v5.gd" in engine, "V5 resolver removed"
assert "new_creature.effective_nature_id = creature.effective_nature_id" in engine, "W02 nature lost"
policy = json.loads((ROOT / "config/item_selection_v1.json").read_text(encoding="utf8"))
assert "dynamax_candy" in policy["excluded_ids"], "explicit veto removed"
print("W04_V5_PY PASS routes=10 conditional=6 trade=1 special=4 regional=57")
