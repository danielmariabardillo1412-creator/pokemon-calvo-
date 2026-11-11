#!/usr/bin/env python3
"""IA6 V28 native mechanical gate on the *integrated* checkout.

The historical V28 isolation/allowlist guard is NOT modified or replaced:
the original automation_v28.py runs independently on pinned historical HEAD.
This gate uses its unchanged descriptor validators, real native Godot runner,
raw evidence SHA256 checks, and combined report validators, without claiming
that the integrated checkout satisfies V28's historical git-diff allowlist.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/item_audit"))
sys.path.insert(0, str(ROOT / "tools/distribution"))
import automation_v28 as v28  # noqa: E402


def sha(path: str) -> str:
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=shutil.which("godot"))
    parser.add_argument("--node", default=shutil.which("node"))
    args = parser.parse_args()
    if not args.godot or not args.node:
        raise SystemExit("IA6_V28_INTEGRATED FAILED: pinned Godot and Node required")
    actual_sha = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    expected_sha = os.getenv("ITEM_AUTOMATION_FUNCTIONAL_SHA", actual_sha)
    if actual_sha != expected_sha:
        raise SystemExit(
            f"IA6_V28_INTEGRATED FAILED: wrong checkout {actual_sha} != {expected_sha}")
    sources = [
        "tools/item_audit/automation_v28.py",
        "tests/gameplay/item_automation_v28.gd",
        *v28.DESCRIPTORS,
        "modules/battle/backends/showdown/native_engine.cjs",
    ]
    before = {p: sha(p) for p in sources}
    descriptors = [v28.validate_descriptor(v28.read(ROOT / p))
                   for p in v28.DESCRIPTORS]
    ids = [spec["id"] for desc in descriptors for spec in desc["items"]]
    if len(ids) != len(set(ids)) or len(ids) != 8:
        raise SystemExit("IA6_V28_INTEGRATED FAILED: missing 8 distinct item IDs")
    # All official provenance checks remain enabled. Only the old V28
    # *git-diff scope guard* belongs exclusively to the historical gate.
    provenance = [row for desc in descriptors for row in v28.provenance(desc)]
    if len(provenance) != len(ids):
        raise SystemExit("IA6_V28_INTEGRATED FAILED: incomplete provenance")

    out = ROOT / ".godot/item_automation_v28/runs" / ("ia6_" + str(time.time_ns()))
    out.mkdir(parents=True)
    os.environ["POKEMON_CALVO_NODE"] = str(Path(args.node).resolve())
    common = {
        "functional_sha": actual_sha,
        "checkout_sha": actual_sha,
        "run_url": os.getenv("ITEM_AUTOMATION_RUN_URL", ""),
        "provenance": provenance,
        "integrated_native_only": True,
        "historic_scope_guard": "REQUIRED_SEPARATELY_PINNED",
    }
    groups, rows, checks = [], [], 0
    for name, paths in (
        ("prior", v28.DESCRIPTORS[:2]),
        ("entry", [v28.ENTRY_DESCRIPTOR]),
    ):
        group, report = v28.execute_group(args, paths, common, out / name, name)
        if group["status"] != "SCOPED_VERIFIED" or not report.get("checks"):
            raise RuntimeError("Group not certified: " + name)
        groups.append(group)
        rows.extend(report["scenarios"])
        checks += report["checks"]
    if len(groups) != 2 or len(rows) != 40 or checks < 1935:
        raise RuntimeError("Expected 40 real native scenarios, >=1935 checks")
    if {r["id"] for r in rows} != set(ids):
        raise RuntimeError("V28 integrated missing actual item IDs")
    after = {p: sha(p) for p in sources}
    if before != after:
        raise RuntimeError("Protected native engine or V28 source changed")
    receipt = {
        "status": "PASS",
        "scope": "INTEGRATED_NATIVE_MECHANICS_ONLY",
        "source_sha": actual_sha,
        "checks": checks,
        "items": len(ids),
        "scenarios": len(rows),
        "groups": groups,
        "source_hashes": before,
        "historical_v28_scope_verified_here": False,
        "historical_gate_required_separately": True,
    }
    with (out / "ia6-integrated-result.json").open("w", encoding="utf-8") as stream:
        json.dump(receipt, stream, ensure_ascii=False, indent=2)
    print(
        f"IA6_V28_INTEGRATED PASS checks={checks} items=8 "
        f"scenarios=40 sha={actual_sha}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
