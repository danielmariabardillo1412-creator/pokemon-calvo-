#!/usr/bin/env python3
"""W05 V3: structural acceptance for real FieldItemBag mounting.

Run with --expect-red only against baseline before bag changes.
The gameplay test supplies the dynamic proof; this gate is not enough alone.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
BAG = ROOT / "scenes/visual/field_item_bag.gd"
PANEL = ROOT / "scenes/visual/field_machine_book_panel.gd"


def main() -> None:
    text = BAG.read_text(encoding="utf-8")
    panel = PANEL.read_text(encoding="utf-8")
    required = [
        'res://scenes/visual/field_machine_book_panel.gd',
        'bind_existing_service(service)',
        'select_book(',
        'select_creature(',
        'select_replacement_slot(',
        'teaching_finished.connect(',
        'func _on_machine_teaching_finished(',
    ]
    mounted = all(token in text for token in required)
    if "--expect-red" in sys.argv:
        assert not mounted, "Unexpected green before integration"
        print("W05_V3_BASELINE_RED EXPECTED real_bag_mount=absent")
        return
    assert mounted, "FieldItemBag real panel binding absent"
    assert text.count("service.teach(") == 0, "Double-teaching engine in bag"
    assert text.count("service.use_item(") == 1, "Existing non-machine item engine altered"
    assert panel.count("service.teach(id, target, _slot())") == 1
    assert text.count("teaching_finished.connect(") == 1
    assert 'machine_panel_required' in text
    assert 'field_item_service_is_current(service)' in text
    print("W05_V3_BAG_STRUCTURAL PASS mount=1 service_shared=1 "
          "callback=1 item_use_nonmachine_preserved=1")


if __name__ == "__main__":
    main()
