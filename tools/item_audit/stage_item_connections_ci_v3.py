#!/usr/bin/env python3
"""Prepara SOLO fixtures efímeras para el gate portable V27, sin reescribir perfiles.

El runner item_connections depende de tres JSON creados en fases históricas.
La CI empieza desde checkout limpio: reconstruimos los dos artefactos de CSV y
dejamos al exportador Godot la clasificación de evoluciones. No resellar.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/item_audit"))
import prepare_connections_v1 as source  # Reutiliza CSVs primarios y verificación SHA-256.

OUT = ROOT / ".godot/item_connections_v1"
GODOT_OUT = ROOT / ".godot/item_audit_v1"
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
DATA = ROOT / "data/normalized/pokemon_api.json"


def payloads() -> tuple[dict, list]:
    profile = source.read(PROFILE)
    data = source.read(DATA)
    tables = {name: source.table(name) for name in (
        "items.csv", "moves.csv", "version_groups.csv", "machines.csv"
    )}
    item_ids = {row["id"]: source.canonical(row["identifier"]) for row in tables["items.csv"]}
    move_ids = {row["id"]: source.canonical(row["identifier"]) for row in tables["moves.csv"]}
    versions = {row["id"]: row for row in tables["version_groups.csv"] if int(row["id"]) <= 27}
    rebuilt: dict[str, dict[str, str]] = defaultdict(dict)
    for row in tables["machines.csv"]:
        item = item_ids[row["item_id"]]
        version = versions.get(row["version_group_id"])
        if item not in data["items"] or version is None:
            continue
        move = move_ids[row["move_id"]]
        if move not in data["moves"]:
            continue
        version_name = version["identifier"]
        assert version_name not in rebuilt[item], (item, version_name)
        rebuilt[item][version_name] = move
    assert dict(sorted(rebuilt.items())) == profile["machine_rows"]
    assert len(rebuilt) == 338 and profile["active_machine_version"] == "scarlet-violet"

    available: dict[str, list[str]] = defaultdict(list)
    for species_id, species in data["species"].items():
        for entry in species["learnset"]:
            if entry["method"] == "machine" and entry.get("version_group") == "scarlet-violet":
                available[entry["move_id"]].append(species_id)
    fixtures = []
    for item_id, rows in sorted(rebuilt.items()):
        if "scarlet-violet" in rows:
            fixtures.append({
                "item_id": item_id,
                "expected_move": rows["scarlet-violet"],
                "compatible_species": sorted(set(available[rows["scarlet-violet"]])),
            })
    assert len(fixtures) == 229
    original = {
        "rows": tables["machines.csv"],
        "items": tables["items.csv"],
        "moves": tables["moves.csv"],
        "versions": tables["version_groups.csv"],
    }
    return original, fixtures


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="Verifica además el exportador de Godot sin escribir archivos")
    args = parser.parse_args()
    before = {str(p): sha256(p) for p in (PROFILE, DATA)}
    original, fixtures = payloads()
    if not args.check:
        OUT.mkdir(parents=True, exist_ok=True)
        GODOT_OUT.mkdir(parents=True, exist_ok=True)
        for name, value in (("source_machine_rows.json", original),
                            ("machine_fixtures.json", fixtures)):
            (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n",
                                    encoding="utf-8", newline="\n")
    assert source.read(OUT / "source_machine_rows.json") == original
    assert source.read(OUT / "machine_fixtures.json") == fixtures
    if args.check:
        godot = source.read(GODOT_OUT / "godot_inventory.json")
        assert godot["canonical_items"] == 2222 and len(godot["evolution_references"]) > 0
    assert before == {str(p): sha256(p) for p in (PROFILE, DATA)}
    print("ITEM_CI_CONNECTION_FIXTURES_V3 PASS machines=338 fixtures=229 "
          + ("godot_inventory=verified" if args.check else "godot_inventory=pending"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
