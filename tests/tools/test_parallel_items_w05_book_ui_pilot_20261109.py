#!/usr/bin/env python3
"""W05 pilot: static boundaries only; runtime assertions execute in Godot."""
import json
from pathlib import Path

R = Path(__file__).resolve().parents[2]
PANEL = R / "scenes/visual/field_machine_book_panel.gd"
GODOT = R / "tests/gameplay/parallel_items_w05_book_ui_pilot_20261109.gd"
PROFILE = R / "modules/inventory/item_connections_v1.json"
FIXTURE = R / "tests/fixtures/parallel_items/w05_campaign_006.json"

def main():
    n = 0
    def check(label, condition):
        nonlocal n
        n += 1
        if not condition:
            raise AssertionError(label)
    p = PANEL.read_text(encoding="utf-8")
    gd = GODOT.read_text(encoding="utf-8")
    cfg = json.loads(PROFILE.read_text(encoding="utf-8"))
    old = json.loads(FIXTURE.read_text(encoding="utf-8"))
    check("SV active", cfg["active_machine_version"] == "scarlet-violet")
    check("tm202 mapped", cfg["machine_rows"]["tm202"]["scarlet-violet"] == "pain_split")
    check("tm31 mapped", cfg["machine_rows"]["tm31"]["scarlet-violet"] == "metal_claw")
    check("old campaign preserved", len(old["blocks"]) == 10 and sum(len(b["items"]) for b in old["blocks"]) == 49)
    check("presentation domain used", "Books.presentacion" in p)
    check("uses same configured service", "bind_existing_service" in p and "Service.new()" not in p)
    check("exact original teach called", "service.teach(id, target, _slot())" in p)
    check("real bag", "service.owner.inventory.all_item_ids()" in p)
    check("real party", "service.owner.party.get_creatures()" in p)
    check("learnset from species", "species.learnset" in p and 'entry.version_group' in p)
    # V4 promotion: verify the exact PokeAPI es source, rather than literal
    # strings embedded in the panel. Original Godot panel tests remain intact.
    source_es = json.loads((R / "data/localization/machine_moves_es_sv_v1.json").read_text(encoding="utf8"))
    def verified_pilot(move_id, label):
        entry = source_es["entries"][move_id]
        doc = json.loads((R / entry["source_path"]).read_text(encoding="utf8"))
        es = [name["name"] for name in doc["names"]
              if name["language"]["name"] == "es"]
        return (source_es["locale"] == "es" and
                entry["nombre_es"] == label and doc["id"] == entry["source_api_id"]
                and doc["name"] == move_id.replace("_","-") and es == [label])
    check("Spanish localized pilot", verified_pilot("pain_split", "Divide Dolor")
          and verified_pilot("metal_claw", "Garra Metal")
          and 'presentation.get("nombre_movimiento"' in p
          and 'presented.get("nombre_movimiento"' in p)
    check("real button", "teach_button.pressed.emit()" in gd)
    check("replace and no spend", "select_replacement_slot" in gd and "move_replacement_required" in gd)
    check("no stock negative", "item_not_owned" in gd)
    check("incompatible negative", "machine_incompatible" in gd)
    check("real persistence", "SaveGameRepository.new()" in gd and "save_collection" in gd and "repo.load(SAVE)" in gd)
    check("UI blocks incompatibility", '_blocked_reason = "machine_incompatible"' in p and "teach_button.disabled = true" in p)
    check("UI blocks missing stock", 'service.owner.inventory.has(item_id)' in p and 'Sin existencias' in p)
    check("UI blocks locked service", 'service._boundary(item_id)' in p and '"field_locked"' in p)
    check("UI revalidates click", 'func teach_selected()' in p and "_refresh_compatibility()" in p)
    check("no alternate engine", p.count("service.teach(id, target, _slot())") == 1)
    check("new negative Godot coverage", all(s in gd for s in ["test_field_lock()", "test_last_copy()", "test_no_selection()", "test_missing_version_context()"]))
    check("no premature Godot pass", "W05_BOOK_UI_PILOT_20261109_GODOT PASS" in gd and "quit(1)" in gd)
    print(f"W05_BOOK_UI_PILOT_20261109_PY PASS checks={n}")

if __name__ == "__main__":
    main()
