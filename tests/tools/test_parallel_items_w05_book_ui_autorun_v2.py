#!/usr/bin/env python3
"""W05 AUTORUN V2 integrity gate. Functional outcomes require the Godot job."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
V1 = ROOT / "tests/fixtures/parallel_items/w05_campaign_006.json"
V2 = ROOT / "tests/fixtures/parallel_items/w05_book_ui_autorun_v2.json"
RUNNER = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v2.gd"
PANEL = ROOT / "scenes/visual/field_machine_book_panel.gd"
V1_RUNNER = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v1.gd"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W05/AUTORUN_V2_PROGRESS.csv"

def main():
    count = 0
    def check(label, valid):
        nonlocal count
        count += 1
        if not valid:
            raise AssertionError(label)
    p = json.loads(PROFILE.read_text(encoding="utf8"))
    previous = json.loads(V1.read_text(encoding="utf8"))
    current = json.loads(V2.read_text(encoding="utf8"))
    runner = RUNNER.read_text(encoding="utf8")
    panel = PANEL.read_text(encoding="utf8")
    progress = PROGRESS.read_text(encoding="utf8").splitlines()
    active = {i for i, versions in p["machine_rows"].items() if versions.get("scarlet-violet")}
    earlier = [i["item_id"] for row in previous["blocks"] for i in row["items"]]
    new = [i["item_id"] for row in current["blocks"] for i in row["items"]]
    check("active scarlet-violet", p["active_machine_version"] == "scarlet-violet")
    check("229 in canonical profile", len(active) == 229)
    check("first 49 unique", len(earlier) == len(set(earlier)) == 49)
    check("new 180 unique", len(new) == len(set(new)) == 180)
    check("disjoint no repeated credit", not set(earlier).intersection(new))
    check("229 exact union", active == (set(earlier) | set(new)))
    check("v2 fixture contract", current.get("campaign") == "AUTORUN_V2" and
          current.get("worker") == "W05" and current.get("active_version") == "scarlet-violet")
    check("ten group rows", len(current["blocks"]) == 10 and len(progress) == 11)
    for n, group in enumerate(current["blocks"], start=1):
        number = f"{n:02d}"
        check(f"ordered group {number}", group["block"] == number)
        check(f"18 exact items {number}", len(group["items"]) == 18)
        check(f"progress row {number}", progress[n].startswith(number + ","))
        for item in group["items"]:
            item_id = item["item_id"]
            check(f"real mapping {item_id}", p["machine_rows"][item_id]["scarlet-violet"] == item["move_id"])
    check("real reusable UI", "PanelClass.new()" in runner and "panel.teach_button.pressed.emit()" in runner)
    check("teaching authority", "service.teach(id, target, _slot())" in panel
          and "ServiceClass.new()" in runner)
    check("one service teach", panel.count("service.teach(id, target, _slot())") == 1)
    check("original runner preserved", V1_RUNNER.exists() and "W05_BOOKS_AUTORUN_GODOT PASS" in V1_RUNNER.read_text(encoding="utf8"))
    check("V2 SaveV2 path", "SaveGameRepository.new()" in runner and "check_save(svc.owner" in runner)
    check("V2 status receipts", "W05_BOOKS_AUTORUN_V2_GROUP" in runner and
          "W05_BOOKS_AUTORUN_V2_GODOT PASS" in runner and "quit(1)" in runner)
    check("negative and positive", "test_incompatible(item_id, move_id)" in runner and
          "not panel.last_result.get" in runner and "exactly one book consumed" in runner)
    print(f"W05_BOOKS_AUTORUN_V2_PY PASS blocks=10 ids=180 total_active=229 previous=49 checks={count}")

if __name__ == "__main__":
    main()
