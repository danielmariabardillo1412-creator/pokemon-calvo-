"""Refresh exactly one derived move through the canonical V3 converter.

No full snapshot checkout, live API, hand-authored catalog row or other moves.
Run with --apply, then tools/run_import.gd for canonical normalization.
The immutable 69 KB source is read from its pinned Git blob into a temporary
input directory. Default is a dry run; changed input shapes fail closed.
"""
import argparse
import copy
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

import pokeapi_adapter_v3 as v3

SOURCE_BLOB = "121f719bc1b51595e5229f5f9a422786cce69073"
SOURCE_SHA256 = "eeca6b6db91b92f8009472a09b801a1146d4be2b49513e50f9c1e8e8bb4cce26"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    source = subprocess.check_output(["git", "cat-file", "blob", SOURCE_BLOB], cwd=v3.ROOT)
    if hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
        raise RuntimeError("Pinned source SHA-256 mismatch")
    with tempfile.TemporaryDirectory(prefix="pokemon-calvo-tera-") as directory:
        root = Path(directory)
        path = root / "move/851/index.json"
        path.parent.mkdir(parents=True)
        path.write_bytes(source)  # Byte-identical transient source, never data/api.
        rows, _, _ = v3.build_moves(root)
    if len(rows) != 1 or rows[0]["id"] != "tera_blast":
        raise RuntimeError("Expected exactly one converted Tera Blast row")
    row = rows[0]
    raw = v3.load_json(v3.DEFAULT_RAW)
    original = copy.deepcopy(raw)
    matches = [i for i, m in enumerate(raw["moves"]) if m["id"] == "tera_blast"]
    if len(matches) != 1:
        raise RuntimeError("Expected one existing Tera Blast record")
    index = matches[0]
    previous = raw["moves"][index]
    legacy = copy.deepcopy(row)
    legacy["effect_specs"] = v3.legacy._legacy.generate_move_specs(json.loads(source), set())[0]
    legacy["classification"] = "RUNTIME_SUPPORTED"
    if previous not in (legacy, row):
        raise RuntimeError("Existing row has unexpected changes; refusing overwrite")
    raw["moves"][index] = row
    changed = [a["id"] for a, b in zip(original["moves"], raw["moves"]) if a != b]
    if changed not in ([], ["tera_blast"]):
        raise RuntimeError("Out-of-scope move change")
    if args.apply and changed:
        v3.write_json(v3.DEFAULT_RAW, raw)
    print(json.dumps({"mode": "apply" if args.apply else "dry_run", "source_blob": SOURCE_BLOB,
                      "source_sha256": SOURCE_SHA256, "changed_moves": changed,
                      "classification": row["classification"], "effect_specs": row["effect_specs"],
                      "next": "Godot --headless --path . --script tools/run_import.gd"}))


if __name__ == "__main__":
    main()
