#!/usr/bin/env python3
"""W05 V4 staging: source-backed 229 MT, one panel, no Rope regression.

This checks the actual staging tree (NOT a copied W05 historical tree).
The separate Godot runner verifies state transitions. --baseline-red
reconstructs the pre-change gate without modifying staging.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = "e63b2e6c7e175fba318cc2f562bebd1769589092"
BAG = Path("scenes/visual/field_item_bag.gd")
PANEL = Path("scenes/visual/field_machine_book_panel.gd")
PROFILE = Path("modules/inventory/field_machine_book_profile.gd")
LOCAL = Path("data/localization/machine_moves_es_sv_v1.json")
SELECTION = Path("config/item_selection_v1.json")
MAPPING = Path("modules/inventory/item_connections_v1.json")
HELPER = Path("modules/localization/machine_moves_es_sv_w05.gd")


def require(ok: bool, label: str) -> None:
    if not ok:
        raise AssertionError(label)


def text(path: Path) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def godot_method(data: str, name: str) -> str:
    marker = "func " + name + "("
    start = data.find(marker)
    require(start >= 0, "missing " + name)
    end = data.find("\nfunc ", start + len(marker))
    return data[start:end if end >= 0 else len(data)].rstrip()


def baseline() -> str:
    return subprocess.check_output(
        ["git", "show", BASE + ":" + BAG.as_posix()], cwd=ROOT, text=True
    )


def main() -> None:
    bag = text(BAG)
    original = baseline()
    require(godot_method(bag, "_apply_escape_rope") ==
            godot_method(original, "_apply_escape_rope"),
            "PROTECTED: W03 escape rope function changed from fixed staging base")
    require("WorldItemTx" in bag and "return await _apply_escape_rope()" in bag,
            "Rope dispatch must remain")
    require("dynamax_candy" in json.loads(text(SELECTION))["excluded_ids"],
            "Dynamax Candy explicit exclusion dropped")

    if "--baseline-red" in sys.argv:
        require("machine_panel_required" not in original,
                "Baseline expected to lack W05 transaction gate")
        print("W05_V4_BASELINE_RED EXPECTED missing_machine_use_guard=1")
        return

    require(bag.count("BookPanel.new()") == 1 and
            bag.count(".teaching_finished.connect(") == 1 and
            "_machine_panel" not in bag,
            "Duplicate panels or callbacks")
    for token in ("_requested_book_id", "select_book(item_id)",
                  "select_creature(creature_id)", "select_replacement_slot(",
                  "machine_panel_required", "field_item_service_is_current(service)"):
        require(token in bag, "Bag seam missing " + token)
    require(bag.count("service.use_item(") == 1 and
            "service.teach(" not in bag,
            "Native bag added second teaching/mutation path")
    callback = godot_method(bag, "_on_book_teaching_finished")
    require("refresh()" in callback and "field_refresh_hud()" in callback and
            "service.teach(" not in callback and
            "service.use_item(" not in callback,
            "Callback must only update UI/HUD")
    panel = text(PANEL)
    for token in ("_book_selection_stale", "_target_selection_stale",
                  "sort_mode", "type_filter", "traduccion_es_verificada",
                  "service.teach(id, target, _slot())",
                  "teach_button.disabled", "teaching_finished.emit"):
        require(token in panel, "W05 panel guard missing " + token)
    require(panel.count("service.teach(id, target, _slot())") == 1 and
            "PILOT_NAMES" not in panel, "Old pilot-only language or double mutation")
    require("MachineMovesEsSvW05.resolve" in text(PROFILE) and
            "class_name MachineMovesEsSvW05" in text(HELPER) and
            "func resolve(" in text(HELPER),
            "229 ES helper not connected to presentation")
    records = json.loads(text(LOCAL))
    profile = json.loads(text(MAPPING))
    keys = [f"tm{i:02d}" for i in range(1, 230)]
    require(records["locale"] == "es" and
            records["version"] == profile["active_machine_version"] == "scarlet-violet" and
            records["active_books"] == records["verified_es"] == 229 and
            records["missing_es"] == 0 and len(records["entries"]) == 229,
            "229 authentic ES records required")
    checked = 0
    for machine in keys:
        require(machine in profile["machine_rows"], machine + " missing")
        move = profile["machine_rows"][machine]["scarlet-violet"]
        require(move in records["entries"], machine + " not localized")
        row = records["entries"][move]
        require(row["item_id"] == machine, machine + " identity drift")
        require(row["source_path"] == "data/api/v2/move/" +
                str(row["source_api_id"]) + "/index.json", "PokeAPI path changed")
        path = (ROOT / row["source_path"]).resolve()
        require(path.is_relative_to(ROOT.resolve()) and path.is_file(),
                machine + " missing original PokeAPI")
        raw = path.read_bytes()
        sha = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
        require(sha == row["source_blob_sha"], machine + " source blob drift")
        doc = json.loads(raw)
        es = [x["name"] for x in doc.get("names", [])
              if x.get("language", {}).get("name") == "es"]
        require(len(es) == 1 and row["nombre_es"] == es[0] and es[0].strip(),
                machine + " missing exact Spanish PokeAPI")
        checked += 1
    require(len({profile["machine_rows"][m]["scarlet-violet"] for m in keys}) == 229,
            "Repeated move ID")
    print("W05_V4_SOURCE_ES PASS ids=229 exact_pokeapi=229 "
          "excluded_dynamax_candy=1 rope_unmodified=1")
    print("W05_V4_BAG_CONTRACT PASS panel=1 signals=1 "
          "double_spend_guard=1 stable_ids=1 callback_ui_only=1")


if __name__ == "__main__":
    main()
