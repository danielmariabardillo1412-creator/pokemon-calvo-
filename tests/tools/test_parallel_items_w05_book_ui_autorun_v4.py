#!/usr/bin/env python3
"""IA5/W05 TANDA04: attest all 229 Spanish labels to the original local PokeAPI files.

Never derives Spanish names from English or the es-419 locale. Each entry is
strictly validated against the exact move ID, source ID and source Git blob SHA.
The gameplay effect/SaveV2 remains validated in the established Godot suites.
"""
from __future__ import annotations
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
INDEX = ROOT / "data/api/v2/move/index.json"
TABLE = ROOT / "data/localization/machine_moves_es_sv_v1.json"
GLOBAL = ROOT / "modules/localization/spanish_game_text.gd"
HELPER = ROOT / "modules/localization/machine_moves_es_sv_w05.gd"
PANEL = ROOT / "scenes/visual/field_machine_book_panel.gd"
PRESENTATION = ROOT / "modules/inventory/field_machine_book_profile.gd"
PROGRESS = ROOT / "docs/coordination/items_parallel_v1/reports/W05/AUTORUN_V4_PROGRESS.csv"

def json_file(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf8"))

def main() -> None:
    checks = 0
    def check(name: str, valid: bool) -> None:
        nonlocal checks
        checks += 1
        if not valid:
            raise AssertionError(name)

    profile, index, table = [json_file(p) for p in (PROFILE, INDEX, TABLE)]
    check("canonical version", profile["active_machine_version"] == "scarlet-violet")
    check("local repo index", index["count"] == len(index["results"]) == 937)
    index_by_name = {entry["name"]: int(entry["url"].rstrip("/").split("/")[-1])
                     for entry in index["results"]}
    check("unique move names in index", len(index_by_name) == len(index["results"]))
    keys = [f"tm{n:02d}" for n in range(1, 230)]
    moves = [profile["machine_rows"][k]["scarlet-violet"] for k in keys]
    check("229 distinct canonical moves", len(set(moves)) == len(moves) == 229)
    check("table semantics", table["schema_version"] == 1 and table["locale"] == "es"
          and table["version"] == "scarlet-violet" and table["profile_id"] == profile["profile_id"]
          and table["source_index_path"] == "data/api/v2/move/index.json")
    check("exact 229 rows and no fabricated entries", table["active_books"] == 229
          and table["verified_es"] == 229 and table["missing_es"] == 0
          and set(table["entries"]) == set(moves))
    tracked_files: set[int] = set()
    group_rows: list[tuple[str, int, int]] = []
    verified = 0
    missing = 0
    for gi in range(10):
        start, end = 1 + gi*23, min((gi+1)*23, 229)
        current = 0
        for n in range(start, end+1):
            item_id = f"tm{n:02d}"
            move_id = profile["machine_rows"][item_id]["scarlet-violet"]
            record = table["entries"][move_id]
            source_id = record["source_api_id"]
            source = ROOT / record["source_path"]
            check(f"{item_id} exact owner", record["item_id"] == item_id)
            check(f"{item_id} exact URI index", index_by_name.get(move_id.replace("_", "-")) == source_id)
            check(f"{item_id} source path", record["source_path"] ==
                  f"data/api/v2/move/{source_id}/index.json")
            raw = source.read_bytes()
            digest = hashlib.sha1(f"blob {len(raw)}\0".encode("ascii") + raw).hexdigest()
            check(f"{item_id} immutable Git blob", digest == record["source_blob_sha"])
            source_doc = json.loads(raw)
            check(f"{item_id} exact canonical identity",
                  source_doc["id"] == source_id and source_doc["name"] == move_id.replace("_", "-"))
            es_rows = [r for r in source_doc["names"] if r.get("language", {}).get("name") == "es"]
            check(f"{item_id} exactly one ES source", len(es_rows) == 1)
            label = record.get("nombre_es")
            check(f"{item_id} exact es, never es-419/en", isinstance(label, str) and bool(label.strip())
                  and len(es_rows) == 1 and label == es_rows[0]["name"])
            tracked_files.add(source_id)
            verified += 1
            current += 1
        group_rows.append((f"{gi+1:02d}", current, end-start+1-current))
        print(f"W05_BOOKS_AUTORUN_V4_PY_GROUP block={gi+1:02d} translated={current} missing={end-start+1-current}")
    check("all exact source IDs distinct", len(tracked_files) == 229)
    check("all sourced", verified == 229 and missing == 0)
    check("ten group sizes", [r[1] for r in group_rows] == [23]*9 + [22])
    prior = GLOBAL.read_text(encoding="utf8")
    block = prior.split("const CORE_MOVE_NAMES := {", 1)[1].split("const ITEM_NAMES",1)[0]
    prior_labels = dict(re.findall(r'"([^"]+)": "([^"]+)"', block))
    conflicts = [(mid, prior_labels[mid], table["entries"][mid]["nombre_es"])
                 for mid in prior_labels if mid in table["entries"]
                 and prior_labels[mid] != table["entries"][mid]["nombre_es"]]
    check("global core discrepancy recorded", conflicts ==
          [("light_screen", "Pantalla Luz", "Pantalla de Luz")])
    helper, panel, presentation = [p.read_text(encoding="utf8")
                                   for p in (HELPER,PANEL,PRESENTATION)]
    check("no global write", 'class_name MachineMovesEsSvW05' in helper and
          'res://data/localization/machine_moves_es_sv_v1.json' in helper)
    check("local helper explicit trust metadata", 'source_api_id' in helper and
          '"verified_es": true' in helper)
    check("profile exact localized presentation", 'MachineMovesEsSvW05.resolve' in presentation
          and '"traduccion_es_verificada"' in presentation)
    check("panel uses trusted presentation for labels", 'presentation.get("nombre_movimiento"' in panel
          and 'presented.get("nombre_movimiento"' in panel)
    check("panel emits honest fallback warning", 'traducción española no verificada' in panel
          and 'presented.get("traduccion_es_verificada"' in panel)
    check("single real teaching engine", panel.count('service.teach(id, target, _slot())') == 1)
    progress = PROGRESS.read_text(encoding="utf8").splitlines()
    check("progress ten rows", len(progress) == 11 and
          all(progress[i].startswith(f"{i:02d},") for i in range(1, 11)))
    print(f"W05_BOOKS_V4_CORE_DIFF count={len(conflicts)} detail={conflicts}")
    print(f"W05_BOOKS_AUTORUN_V4_PY PASS groups=10 ids=229 translated=229 missing=0 mismatches={len(conflicts)} checks={checks}")

if __name__ == "__main__":
    main()
