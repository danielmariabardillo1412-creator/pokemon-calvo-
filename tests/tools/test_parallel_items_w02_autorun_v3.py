#!/usr/bin/env python3
"""W02 TANDA03 manifest/source and native evolution QA. No false runtime PASS."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
f=json.loads((root/"tests/fixtures/parallel_items/w02_autorun_v3.json").read_text(encoding="utf-8"))
assert (f["worker"],f["tanda"],len(f["rows"])) == ("W02","03",10)
assert f["modes"]==["active","reserve"]
assert [x["id"] for x in f["cases"]]==["direct","item","level","unminted","replace"]
s=(root/"tests/gameplay/parallel_items_w02_autorun_v3.gd").read_text(encoding="utf-8")
for token in ("_new_minted(mode, [], &\"eevee\", 30)", "EvolutionSystem.apply_evolution(",
              "evolved.effective_nature_id == &\"adamant\"", "StatCalculator.compute(",
              "source.to_dict() == before", "W02_AUTORUN_V3_GODOT"):
    assert token in s,token
print("W02_AUTORUN_V3_PY PASS checks=12")
