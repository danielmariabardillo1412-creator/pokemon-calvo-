#!/usr/bin/env python3
"""W05 TANDA03: structural scope and receipts gate; functional checks require Godot."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
PANEL = ROOT / "scenes/visual/field_machine_book_panel.gd"
RUNNER = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v3.gd"
WORKFLOW = ROOT / ".github/workflows/parallel-w05-books-ui-20261109.yml"
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
PREVIOUS = ROOT / "tests/fixtures/parallel_items/w05_campaign_006.json"
SECOND = ROOT / "tests/fixtures/parallel_items/w05_book_ui_autorun_v2.json"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W05/AUTORUN_V3_PROGRESS.csv"
V1 = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v1.gd"
V2 = ROOT / "tests/gameplay/parallel_items_w05_book_ui_autorun_v2.gd"

def main():
    checks = 0
    def verify(name, cond):
        nonlocal checks
        checks += 1
        if not cond:
            raise AssertionError(name)
    panel = PANEL.read_text(encoding="utf8")
    runner = RUNNER.read_text(encoding="utf8")
    workflow = WORKFLOW.read_text(encoding="utf8")
    profile = json.loads(PROFILE.read_text(encoding="utf8"))
    prev = json.loads(PREVIOUS.read_text(encoding="utf8"))
    second = json.loads(SECOND.read_text(encoding="utf8"))
    progress = PROGRESS.read_text(encoding="utf8").splitlines()
    earlier = [x["item_id"] for g in prev["blocks"] for x in g["items"]]
    more = [x["item_id"] for g in second["blocks"] for x in g["items"]]
    active = {key for key, versions in profile["machine_rows"].items() if versions.get("scarlet-violet")}
    verify("all 229 exact without additions", len(earlier) == 49 and len(more) == 180
           and set(earlier).isdisjoint(more) and active == set(earlier) | set(more)
           and len(active) == 229)
    verify("10 structured progress rows", len(progress) == 11
           and all(progress[n].startswith(f"{n:02d},") for n in range(1, 11)))
    verify("no duplicate teaching engine", panel.count("service.teach(id, target, _slot())") == 1
           and "Service.new()" not in panel)
    verify("visible live inventory selection", "owner.inventory.all_item_ids()" in panel)
    verify("stable selections or deselection", "books.select(-1)" in panel
           and "targets.select(-1)" in panel)
    verify("party-only real ownership", 'service.owner.location_of(creature_id)' in panel)
    verify("no double controls on reattach", 'if books != null:' in panel)
    verify("sort and filter from canonical presentation", 'presentation.get("type_id"' in panel
           and "entries.sort_custom" in panel and "type_filter" in panel)
    verify("Spanish fallback disclosed and sourced", 'traducción española no verificada' in panel
           and 'traduccion_es_verificada' in panel and "MachineMovesEsSvW05.resolve" in panel)
    verify("snapshot validated before execution", "func teach_selected()" in panel
           and "_refresh_compatibility()" in panel)
    verify("all ten named scenarios", all(f"func hit_{n:02d}_" in runner for n in range(1, 10))
           and "block=10 name=ci_resiliencia" in runner)
    verify("multiple reopening and signals", "request_ready()" in runner
           and "get_signal_connection_list" in runner)
    verify("all four slots", "for index in range(4)" in runner
           and "select_replacement_slot(-1)" in runner)
    verify("real stock/owner changes", "inventory.remove" in runner
           and "owner.deposit(POKEMON)" in runner and "storage.remove_creature(POKEMON)" in runner)
    verify("headless benchmark not FPS", "Time.get_ticks_usec()" in runner
           and "W05_BOOKS_V3_PERF headless=true" in runner)
    verify("manual SaveV2 open panel", "SaveGameRepository.new()" in runner
           and "repo.save_collection" in runner and "repo.load(SAVE)" in runner)
    verify("source-driven localized text audit", "SpanishGameText.CORE_MOVE_NAMES" in runner
           and "translation_label" in runner and "invented=0" in runner)
    verify("real Godot explicit failure path", "W05_BOOKS_AUTORUN_V3_GODOT PASS" in runner
           and "quit(1)" in runner)
    verify("historical V1/V2 present", V1.exists() and V2.exists())
    verify("CI requires V1/V2 and V3", "W05_BOOKS_AUTORUN_GODOT PASS" in workflow
           and "W05_BOOKS_AUTORUN_V2_GODOT PASS" in workflow
           and "W05_BOOKS_AUTORUN_V3_GODOT PASS" in workflow)
    verify("CI forbids no-op bypass", "continue-on-error" not in workflow and "|| true" not in workflow)
    print(f"W05_BOOKS_AUTORUN_V3_PY PASS blocks=10 books=229 checks={checks}")

if __name__ == "__main__":
    main()
