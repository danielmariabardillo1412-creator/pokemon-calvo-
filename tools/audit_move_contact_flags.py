#!/usr/bin/env python3
"""Temporary DATA V3 audit of PokéAPI move contact flags.

This audit is intentionally networked and must NOT become part of the canonical
runtime/import path. It compares the generated DATA V3 runtime moves with the
official PokéAPI CSV source pinned to one exact upstream commit, then emits a
complete derived contact override candidate for review.
"""
from __future__ import annotations

import csv
import io
import json
import sys
import urllib.request
from collections import Counter
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))

from pokeapi_adapter import slug  # noqa: E402

UPSTREAM_REPO = "PokeAPI/pokeapi"
UPSTREAM_COMMIT = "3a588cf66475bd05a34aba29bd538480889829fb"
RAW_BASE = f"https://raw.githubusercontent.com/{UPSTREAM_REPO}/{UPSTREAM_COMMIT}/data/v2/csv"
MOVE_FLAGS_URL = f"{RAW_BASE}/move_flags.csv"
MOVE_FLAG_MAP_URL = f"{RAW_BASE}/move_flag_map.csv"
MOVES_URL = f"{RAW_BASE}/moves.csv"

RAW_DATASET = REPO_ROOT / "data" / "raw" / "pokemon_api.json"
LOCAL_OVERRIDE = TOOLS_DIR / "move_flags_override.json"
REPORT_DIR = REPO_ROOT / "data" / "reports"
REPORT_PATH = REPORT_DIR / "contact_flag_audit.json"
CANDIDATE_PATH = REPORT_DIR / "move_flags_override_complete.json"


def _download_text(url: str) -> str:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "pokemon-calvo-data-v3-contact-audit/1"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def _csv_rows(text: str) -> list[dict[str, str]]:
    return list(csv.DictReader(io.StringIO(text)))


def main() -> int:
    if not RAW_DATASET.is_file():
        raise FileNotFoundError(
            f"Generate DATA V3 before running this audit: {RAW_DATASET}"
        )

    flags_rows = _csv_rows(_download_text(MOVE_FLAGS_URL))
    flag_by_name = {row["identifier"]: int(row["id"]) for row in flags_rows}
    contact_flag_id = flag_by_name.get("contact")
    if contact_flag_id != 1:
        raise RuntimeError(
            f"Unexpected PokéAPI contact flag id: {contact_flag_id!r}"
        )

    moves_rows = _csv_rows(_download_text(MOVES_URL))
    move_name_by_numeric_id = {
        int(row["id"]): slug(row["identifier"])
        for row in moves_rows
    }

    contact_numeric_ids = {
        int(row["move_id"])
        for row in _csv_rows(_download_text(MOVE_FLAG_MAP_URL))
        if int(row["move_flag_id"]) == contact_flag_id
    }
    unknown_contact_ids = sorted(contact_numeric_ids - set(move_name_by_numeric_id))
    if unknown_contact_ids:
        raise RuntimeError(
            "Contact flag map references unknown move ids: %s"
            % unknown_contact_ids[:20]
        )

    official_contact = {
        move_name_by_numeric_id[move_id]
        for move_id in contact_numeric_ids
    }

    raw = json.loads(RAW_DATASET.read_text(encoding="utf-8"))
    runtime_moves = {row["id"]: row for row in raw["moves"]}
    runtime_ids = set(runtime_moves)
    official_runtime_contact = official_contact & runtime_ids
    generated_runtime_contact = {
        move_id
        for move_id, move in runtime_moves.items()
        if bool(move.get("makes_contact", False))
    }

    override_data = json.loads(LOCAL_OVERRIDE.read_text(encoding="utf-8"))
    override_raw = [str(value) for value in override_data.get("contact", [])]
    override_normalized = [slug(value) for value in override_raw]
    override_counts = Counter(override_normalized)
    duplicate_override_entries = sorted(
        name for name, count in override_counts.items() if count > 1
    )
    override_set = set(override_normalized)

    missing = sorted(official_runtime_contact - generated_runtime_contact)
    extra = sorted(generated_runtime_contact - official_runtime_contact)
    override_not_runtime = sorted(override_set - runtime_ids)
    official_contact_not_runtime = sorted(official_contact - runtime_ids)

    report = {
        "audit_id": "data_v3_contact_flags_pokeapi_csv_v1",
        "upstream": {
            "repository": UPSTREAM_REPO,
            "commit": UPSTREAM_COMMIT,
            "move_flags_url": MOVE_FLAGS_URL,
            "move_flag_map_url": MOVE_FLAG_MAP_URL,
            "moves_url": MOVES_URL,
            "contact_flag_id": contact_flag_id,
        },
        "counts": {
            "runtime_moves": len(runtime_ids),
            "official_contact_all_upstream_moves": len(official_contact),
            "official_contact_runtime_moves": len(official_runtime_contact),
            "generated_contact_runtime_moves": len(generated_runtime_contact),
            "missing_contact_runtime_moves": len(missing),
            "extra_contact_runtime_moves": len(extra),
            "override_raw_entries": len(override_raw),
            "override_unique_entries": len(override_set),
            "override_duplicate_names": len(duplicate_override_entries),
            "override_entries_not_in_runtime": len(override_not_runtime),
        },
        "missing_contact_runtime_moves": missing,
        "extra_contact_runtime_moves": extra,
        "duplicate_override_entries": duplicate_override_entries,
        "override_entries_not_in_runtime": override_not_runtime,
        "official_contact_moves_not_in_runtime": official_contact_not_runtime,
    }

    candidate = {
        "_comment": (
            "Derived DATA V3 contact flags from official PokeAPI CSV data. "
            "Only runtime moves are included; absence means makes_contact=false."
        ),
        "_provenance": {
            "repository": UPSTREAM_REPO,
            "commit": UPSTREAM_COMMIT,
            "move_flags_path": "data/v2/csv/move_flags.csv",
            "move_flag_map_path": "data/v2/csv/move_flag_map.csv",
            "moves_path": "data/v2/csv/moves.csv",
            "contact_flag_id": contact_flag_id,
            "derivation": "official_contact_set_intersect_data_v3_runtime_moves_v1",
        },
        "contact": sorted(official_runtime_contact),
    }

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    CANDIDATE_PATH.write_text(
        json.dumps(candidate, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(json.dumps(report["counts"], indent=2, sort_keys=True))
    print("MISSING_CONTACT_RUNTIME_MOVES=" + ",".join(missing))
    print("EXTRA_CONTACT_RUNTIME_MOVES=" + ",".join(extra))
    print("DUPLICATE_OVERRIDE_ENTRIES=" + ",".join(duplicate_override_entries))
    print("OVERRIDE_NOT_RUNTIME=" + ",".join(override_not_runtime))

    if missing or extra:
        print(
            "CONTACT FLAG AUDIT FAILED: generated DATA V3 contact flags do not "
            "match pinned official PokéAPI CSV data.",
            file=sys.stderr,
        )
        return 2

    print("CONTACT FLAG AUDIT OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
