#!/usr/bin/env python3
"""W05 TANDA05: portable 229-label integrity and Windows export preflight.

Preflight is not proof of PCK inclusion. Only an inspected exported PCK/runtime
can certify that res://data/localization/machine_moves_es_sv_v1.json exists.
"""
from __future__ import annotations

import configparser
import fnmatch
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RELATIVE = "data/localization/machine_moves_es_sv_v1.json"
TABLE = ROOT / RELATIVE
HELPER = ROOT / "modules/localization/machine_moves_es_sv_w05.gd"
PROFILE = ROOT / "modules/inventory/item_connections_v1.json"
PRESET = ROOT / "export_presets.cfg"
IGNORE = ROOT / ".gitignore"


def check(name: str, condition: bool) -> None:
    if not condition:
        raise AssertionError(name)


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def blob_sha(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode("ascii") + data).hexdigest()


def main() -> None:
    cfg = configparser.ConfigParser(interpolation=None)
    check("Windows preset parses", bool(cfg.read(PRESET, encoding="utf-8")))
    section = cfg["preset.0"]
    check("correct existing Windows desktop preset",
          section.get("name", "").strip('"') == "Pokemon Calvo Technical Test Windows"
          and section.get("platform", "").strip('"') == "Windows Desktop")
    check("export resources mode", section.get("export_filter") == '"all_resources"')
    check("no resource exclusion", section.get("exclude_filter") == '""')
    check("existing executable unchanged",
          section.get("export_path") == '"build/PokemonCalvo-Pruebas-Tecnicas.exe"')
    include = section.get("include_filter", "").strip('"')
    patterns = [p.strip() for p in include.split(",") if p.strip()]
    explicit = any(fnmatch.fnmatchcase(RELATIVE, p) for p in patterns)
    print("W05_V5_EXPORT_PRESET_AUDIT preset=windows export=all_resources "
          f"explicit_include={str(explicit).lower()} "
          "pck_inclusion=UNVERIFIED")
    check("table is a portable repo relative path",
          TABLE.exists() and TABLE.resolve().is_relative_to(ROOT.resolve()))
    source = HELPER.read_text(encoding="utf-8")
    match = re.search(r'const SOURCE_PATH := "(res://[^"]+)"', source)
    check("helper uses resource API path", match is not None)
    check("helper points to this exact table",
          match is not None and match.group(1) == "res://" + RELATIVE)
    check("helper uses FileAccess", "FileAccess.get_file_as_string(SOURCE_PATH)" in source
          and "FileAccess.file_exists(SOURCE_PATH)" in source)
    check("table not .gitignored", not any(
          fnmatch.fnmatchcase(RELATIVE, line.strip()) for line in
          IGNORE.read_text(encoding="utf-8").splitlines()
          if line.strip() and not line.lstrip().startswith("#")))
    profile = read_json(PROFILE)
    table = read_json(TABLE)
    check("schema metadata", table.get("schema_version") == 1
          and table.get("locale") == "es"
          and table.get("version") == "scarlet-violet"
          and table.get("active_books") == table.get("verified_es") == 229
          and table.get("missing_es") == 0)
    check("current machine version", profile.get("active_machine_version") == "scarlet-violet")
    expected = {f"tm{i:02d}": profile["machine_rows"][f"tm{i:02d}"]["scarlet-violet"]
                for i in range(1, 230)}
    check("229 unique canonical IDs", len(expected) == len(set(expected.values())) == 229)
    rows = table["entries"]
    check("229 records only", isinstance(rows, dict)
          and len(rows) == 229 and set(rows) == set(expected.values()))
    checked = 0
    for item_id, move_id in expected.items():
        row = rows[move_id]
        check(item_id + " ownership", row.get("item_id") == item_id)
        origin = row.get("source_path", "")
        check(item_id + " pinned path", origin ==
              f'data/api/v2/move/{row.get("source_api_id")}/index.json')
        src = (ROOT / origin).resolve()
        check(item_id + " source remains under root",
              src.is_relative_to(ROOT.resolve()) and src.is_file())
        raw = src.read_bytes()
        check(item_id + " exact source blob", row.get("source_blob_sha") == blob_sha(raw))
        doc = json.loads(raw)
        check(item_id + " source identity",
              doc.get("id") == row.get("source_api_id")
              and doc.get("name") == move_id.replace("_", "-"))
        names = [entry.get("name") for entry in doc.get("names", [])
                 if entry.get("language", {}).get("name") == "es"]
        check(item_id + " exact Spanish label",
              len(names) == 1 and isinstance(names[0], str)
              and bool(names[0].strip()) and row.get("nombre_es") == names[0])
        checked += 1
    check("completed full coverage", checked == 229)
    print(f"W05_BOOKS_AUTORUN_V5_PY PASS rows={checked} portable=1 "
          "original_sources=229 pck_inclusion=UNVERIFIED")


if __name__ == "__main__":
    main()
