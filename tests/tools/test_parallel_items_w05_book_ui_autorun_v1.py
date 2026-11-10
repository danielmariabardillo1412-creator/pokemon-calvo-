#!/usr/bin/env python3
"""AUTORUN W05 contract: structural checks, not a substitute for Godot."""
from __future__ import annotations
import csv
import json
import pathlib
import re
ROOT = pathlib.Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/parallel_items/w05_campaign_006.json"
QUEUE = ROOT / "docs/coordination/items_parallel_v1/CAMPAIGN_006_W05_QUEUE_APPROVED.csv"
ORDER = ROOT / "docs/coordination/items_parallel_v1/IA6_AUTORUN.md"
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
PANEL = ROOT / "scenes/visual/field_machine_book_panel.gd"
RUNNER = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v1.gd"
PILOT = ROOT / "tests/gameplay/parallel_items_w05_book_ui_pilot_20261109.gd"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W05/AUTORUN_V1_PROGRESS.csv"

def main():
    checks = 0
    def require(label, condition):
        nonlocal checks
        checks += 1
        if not condition:
            raise AssertionError(label)
    fixture = json.loads(FIXTURE.read_text(encoding="utf8"))
    profile = json.loads(PROFILE.read_text(encoding="utf8"))
    with QUEUE.open(encoding="utf8", newline="") as source:
        rows = [r for r in csv.reader(source) if len(r) >= 5 and r[1] == "W05"]
    order = ORDER.read_text(encoding="utf8")
    panel = PANEL.read_text(encoding="utf8")
    runner = RUNNER.read_text(encoding="utf8")
    progress = PROGRESS.read_text(encoding="utf8").splitlines()
    require("SV version", profile.get("active_machine_version") == "scarlet-violet")
    require("fixture identity", fixture.get("campaign") == "CAMP_006"
            and fixture.get("worker") == "W05" and fixture.get("active_version") == "scarlet-violet")
    require("ten groups", len(rows) == len(fixture["blocks"]) == 10)
    expected_ids = []
    for index, (row, group) in enumerate(zip(rows, fixture["blocks"]), 1):
        block = f"{index:02d}"
        ids = row[4].split(";")
        actual = [item["item_id"] for item in group["items"]]
        require("queue exact block " + block, row[0] == block and group["block"] == block)
        require("queue same order " + block, ids == actual)
        require("queue size " + block, len(ids) == (4 if index == 10 else 5))
        require("autorun contains group " + block, bool(re.search(
            r"^\|\s*" + block + r"\s*\|.*" + re.escape(ids[0]), order, re.M)))
        require("progress checkpoint row " + block,
                len(progress) > index and progress[index].startswith(block + ","))
        for item in group["items"]:
            id_, move = item["item_id"], item["move_id"]
            require("SV mapping " + id_, profile["machine_rows"][id_]["scarlet-violet"] == move)
            expected_ids.append(id_)
    require("49 unique and no unauthorized", len(expected_ids) == len(set(expected_ids)) == 49
            and not set(expected_ids) & {f"tm{i}" for i in range(230, 251)})
    require("pure books presentation", "Books.presentacion" in panel)
    require("one teach in panel", panel.count("service.teach(id, target, _slot())") == 1
            and "Service.new()" not in panel)
    require("real field binding", "bind_existing_service" in panel)
    require("owner inventory and party", "service.owner.inventory.all_item_ids()" in panel
            and "service.owner.party.get_creatures()" in panel)
    require("SV learnset", "species.learnset" in panel and "entry.version_group" in panel)
    require("real UI headless", "PanelClass.new()" in runner and "panel.teach_button.pressed.emit()" in runner)
    require("positive and negative per ID", "func test_book" in runner and "test_incompatible" in runner)
    require("save real", "SaveGameRepository.new()" in runner and "save_collection" in runner and ".load(SAVE)" in runner)
    require("historical pilot preserved", PILOT.exists())
    require("runner emits group receipts", "W05_BOOKS_AUTORUN_GROUP" in runner)
    require("runner exits on failures", 'quit(1)' in runner)
    print(f"W05_BOOKS_AUTORUN_PY PASS blocks=10 ids=49 checks={checks}")

if __name__ == "__main__":
    main()
