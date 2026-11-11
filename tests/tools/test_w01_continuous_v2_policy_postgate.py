#!/usr/bin/env python3
"""W01 verification of IA6 Dynamax exclusion, preserving old functional scope."""
import csv,json
from pathlib import Path
R=Path(__file__).resolve().parents[2]
policy=json.loads((R/"config/item_selection_v1.json").read_text(encoding="utf-8"))
assert policy["excluded_ids"].get("dynamax_candy")
assert all(x not in policy["excluded_ids"] for x in ["rare_candy","exp_candy_s","exp_candy_m","exp_candy_l","exp_candy_xl"])
assert "dynamax_candy" in (R/"docs/coordination/items_parallel_v1/IA6_AUTORUN.md").read_text(encoding="utf-8")
assert "excluded.size() == 45" in (R/"tests/gameplay/item_selection_policy_test_runner.gd").read_text(encoding="utf-8")
def read(p):
 with (R/p).open(encoding="utf-8-sig",newline="") as f: return list(csv.DictReader(f))
a=read("docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V4_PROGRESS.csv")
b=read("docs/coordination/items_parallel_v1/reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv")
assert len(a)==10 and len(b)==26 and "dynamax_candy" not in {x["id"] for x in a+b}
assert all(x["objetos_nuevos"]=="0" for x in a+b)
print("W01_POLICY_POSTGATE_PY PASS excluded=dynamax_candy no_scope_expansion=1 rows=36")
