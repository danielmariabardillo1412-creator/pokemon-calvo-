#!/usr/bin/env python3
"""W05 CONTINUOUS_V2: integration handoff and real Windows export size guard.

Contract tests attest the OWNED panel/service seam, not FieldItemBag integration.
The optional --require-integrated mode is deliberately RED on W05 and belongs
on an IA6 integrated branch after the shared bag has been wired.
"""
from __future__ import annotations

import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PANEL = ROOT / "scenes/visual/field_machine_book_panel.gd"
BAG = ROOT / "scenes/visual/field_item_bag.gd"
SERVICE = ROOT / "modules/inventory/field_item_service.gd"
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
V2 = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v2.gd"
V3 = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v3.gd"
V4 = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v4.gd"
SOURCE_ES = ROOT / "data/localization/machine_moves_es_sv_v1.json"
BASELINE_EXE_BYTES = 635_385_472
SIZE_GUARD_BYTES = BASELINE_EXE_BYTES * 110 // 100


def check(condition: bool, description: str) -> None:
    if not condition:
        raise AssertionError(description)


def contract(require_integrated: bool = False) -> None:
    panel = PANEL.read_text(encoding="utf-8")
    bag = BAG.read_text(encoding="utf-8")
    service = SERVICE.read_text(encoding="utf-8")
    profile = json.loads(PROFILE.read_text(encoding="utf-8"))
    names = json.loads(SOURCE_ES.read_text(encoding="utf-8"))
    keys = [f"tm{i:02d}" for i in range(1, 230)]
    mapping = profile["machine_rows"]
    check(profile["active_machine_version"] == "scarlet-violet",
          "Active SV version required")
    check(all(k in mapping and "scarlet-violet" in mapping[k] for k in keys),
          "229 canonical machine IDs required")
    check(len({mapping[k]["scarlet-violet"] for k in keys}) == 229,
          "229 unique moves")
    check(names.get("verified_es") == 229 and len(names["entries"]) == 229,
          "229 Spanish entries")

    for signature in (
        "func bind_existing_service(bound_service: Variant) -> bool:",
        "func select_book(id: StringName) -> bool:",
        "func select_creature(id: StringName) -> bool:",
        "func select_replacement_slot(slot: int) -> bool:",
        "signal teaching_finished(result: Dictionary)",
    ):
        check(signature in panel, f"Panel interface changed: {signature}")
    check(panel.count("service.teach(id, target, _slot())") == 1,
          "Exactly one authoritative teach entrypoint")
    check("func teach(item_id: StringName, creature_id: StringName" in service
          and "_publish_bag(staged)" in service,
          "Authoritative service transaction exists")
    for name in ("hit_02_lifecycle", "hit_03_stock_stale", "hit_04_owner_moved",
                 "hit_05_all_slots_cancel", "hit_07_negative_states",
                 "hit_09_save_open_panel"):
        check("func " + name in V3.read_text(encoding="utf-8"),
              f"Historical positive/negative regression missing: {name}")
    check("func check_save(" in V2.read_text(encoding="utf-8"),
          "Historical real SaveV2 roundtrip missing")
    check("229 exact entries" in V4.read_text(encoding="utf-8"),
          "Historical 229 source-backed UI audit missing")

    # Future IA6 acceptance: this simple structural gate is deliberately
    # insufficient on its own; actual click/stock/SaveV2/W03 coexistence
    # must be proved by an integrated Godot test on the IA6 branch.
    seam_tokens = (
        "field_machine_book_panel.gd",
        "bind_existing_service(",
        "select_book(",
        "teaching_finished",
    )
    mounted = all(token in bag for token in seam_tokens)
    if require_integrated:
        check(mounted,
              "RED: IA6 FieldItemBag missing panel mount/service/book/signal seam")
        print("W05_V2_IA6_STRUCTURAL_GATE PASS mount_present=true "
              "runtime_UI_W03_SaveV2=REQUIRES_INTEGRATED_GODOT_TEST")
    else:
        print("W05_V2_CONTRACT PASS books=229 source_es=229 "
              "teach_entrypoints=1 historical_regressions=preserved "
              f"real_mount={'present_unverified' if mounted else 'pending_ia6'}")


def package(exe_name: str, pck_name: str) -> None:
    exe, pck = Path(exe_name), Path(pck_name)
    check(exe.is_file() and pck.is_file(), "Real export artifacts missing")
    check(exe.open("rb").read(2) == b"MZ", "Windows PE MZ header missing")
    e_size, p_size = exe.stat().st_size, pck.stat().st_size
    check(0 < p_size <= e_size * 2, "PCK size invalid")
    check(1_000_000 < e_size <= SIZE_GUARD_BYTES,
          "EXE grew >10 percent versus previous certified baseline")
    # This is a tracked-workspace resource inventory, NOT a listing of
    # members inside PCK. The PCK itself is verified by the Godot isolated
    # mount probe from TANDA05; do not conflate those two measurements.
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    paths = [p for p in tracked.decode("utf-8").split("\0") if p]
    groups: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    for rel in paths:
        path = ROOT / rel
        if not path.is_file():
            continue
        group = rel.split("/", 1)[0]
        groups[group][0] += 1
        groups[group][1] += path.stat().st_size
    top = sorted(groups.items(), key=lambda x: x[1][1], reverse=True)[:5]
    print("W05_V2_WORKSPACE_INVENTORY "
          + ",".join(f"{name}:{v[0]}files:{v[1]}bytes" for name, v in top)
          + " NOT_PCK_MEMBERS=1")
    print(f"W05_V2_PACKAGE PASS exe_bytes={e_size} pck_bytes={p_size} "
          f"growth_guard_bytes={SIZE_GUARD_BYTES} "
          f"tracked_workspace_files={sum(v[0] for v in groups.values())} "
          "windows_runtime_manual=UNVERIFIED android=UNVERIFIED")


def main() -> None:
    if len(sys.argv) == 1:
        contract(False)
    elif sys.argv[1] == "--require-integrated" and len(sys.argv) == 2:
        contract(True)
    elif sys.argv[1] == "--package" and len(sys.argv) == 4:
        contract(False)
        package(sys.argv[2], sys.argv[3])
    else:
        raise SystemExit("Usage: script.py [--require-integrated | --package EXE PCK]")


if __name__ == "__main__":
    main()
