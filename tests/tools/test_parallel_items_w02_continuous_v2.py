#!/usr/bin/env python3
"""W02 V2: structural inventory of 42 approved berries, not an L3 certificate.

Native tests and successful SHA-matched CI are separate mandatory gates.
"""
from collections import defaultdict
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "tests/fixtures/parallel_items"
ORDER = ROOT / "docs/coordination/items_parallel_v1/IA6_AUTORUN.md"


def read_json(filename: str) -> dict:
    return json.loads((BASE / filename).read_text(encoding="utf-8"))


def fail_if(condition: bool, message: str) -> None:
    if condition:
        raise AssertionError(message)


def main() -> None:
    note = ORDER.read_text(encoding="utf-8")
    section = note.split("## Cola completa", 1)[1].split("**Orden de trabajo continuo:**", 1)[0]
    rows = re.findall(r"^\\|\\s*(0[1-5])\\s*\\|([^\\n]+)\\|", section, flags=re.MULTILINE)
    fail_if(len(rows) != 5, "V2 must contain exactly five blocks")
    blocks = []
    for number, text in rows:
        ids = re.findall(r"`([a-z0-9_]+_berry)`", text)
        blocks.append(ids)
        fail_if(not ids, f"empty berry block {number}")
    expected = [i for block in blocks for i in block]
    fail_if(len(expected) != 42 or len(set(expected)) != 42,
            "approved V2 backlog must have 42 distinct berries")
    fail_if(list(map(len, blocks)) != [10, 10, 10, 10, 2],
            "approved V2 block sizes changed")
    historic = read_json("w02_campaign_003.json")
    cases = defaultdict(list)
    for block in historic["blocks"]:
        for case in block["cases"]:
            if case["id"] in expected:
                cases[case["id"]].append(case)
    certified = set()
    for berry_id, checks in cases.items():
        positives = [c for c in checks if c.get("consumes", c.get("applies")) is True]
        negatives = [c for c in checks if c.get("consumes", c.get("applies")) is False]
        fail_if(not positives or not negatives,
                f"historical berry missing positive/negative: {berry_id}")
        certified.add(berry_id)
    fail_if(len(certified) != 36, f"36 existing native histories expected, got {len(certified)}")
    fail_if(any(not set(block).issubset(certified) for block in blocks[1:]),
            "blocks 02-05 must already be historically covered")
    field = read_json("w02_continuous_v2_block01.json")
    field_ids = set(field["item_ids"])
    fail_if(len(field_ids) != 6 or len(field["cases"]) != 12,
            "new field gate must be 6 IDs / 12 scenarios")
    fail_if(field.get("proof_scope") != "field_use_only_no_held_combat_claim",
            "field scope cannot be misreported as held native battle")
    for berry_id in field_ids:
        checks = [c for c in field["cases"] if c["id"] == berry_id]
        fail_if(len(checks) != 2 or {bool(c["applies"]) for c in checks} != {True, False},
                f"field positive and negative missing: {berry_id}")
    persim = read_json("w02_continuous_v2_persim.json")
    fail_if(persim.get("item_id") != "persim_berry" or
            {bool(c["triggers"]) for c in persim["cases"]} != {True, False},
            "Persim must have trigger and no-trigger native cases")
    fail_if(certified | field_ids | {"persim_berry"} != set(expected),
            "new tests + historical coverage do not account for 42 berries")
    fail_if(field_ids - certified != {
        "cheri_berry", "chesto_berry", "pecha_berry", "rawst_berry", "oran_berry"
    }, "field gate cannot claim new IDs or repeat old ones")
    print("W02_CONTINUOUS_V2_AUDIT_PY PASS ids=42 historical=36 field=6 persim=1 checks=42")


if __name__ == "__main__":
    main()
