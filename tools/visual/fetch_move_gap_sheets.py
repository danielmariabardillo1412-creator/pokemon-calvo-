"""Explicit download of TWO checksum-pinned data images, never code or whole games."""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.request import urlopen
from move_gap_repairs import GAP_SHEETS, sheet_url, load_gap_sheet

GAME = Path(__file__).resolve().parents[2]


def fetch(output):
    output.mkdir(parents=True, exist_ok=True)
    records = []
    for name, spec in GAP_SHEETS.items():
        url = sheet_url(name, spec)
        target = output / (spec["source_sha256"] + ".png")
        if target.exists():
            if hashlib.sha256(target.read_bytes()).hexdigest() != spec["source_sha256"]:
                raise ValueError("preserving mismatched existing file: " + str(target))
        else:
            with urlopen(url, timeout=25) as response:
                data = response.read(2_000_001)
            if len(data) > 2_000_000 or hashlib.sha256(data).hexdigest() != spec["source_sha256"]:
                raise ValueError("download checksum/size mismatch: " + name)
            with target.open("xb") as file:
                file.write(data)
        path, provenance = load_gap_sheet(name, output)
        records.append({"name": name, "local_source": str(target), "normalized": str(path), **provenance})
    report = {"version": 1, "images": records, "license_review_required_before_distribution": True,
        "readme": "https://github.com/pagefaultgames/pokerogue-assets#license",
        "credits": "docs/project_book/VISUAL_CATALOG.md; retain Gen9/Reborn and geefuoco/Pagefault Games",
        "scope": "Local laboratory only; no code or JSON animations downloaded or executed"}
    temporary = output / "provenance.tmp"
    temporary.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(output / "provenance.json")
    print("MOVE_GAP_FETCH PASS images=2 source_bytes=" + str(sum(Path(r["local_source"]).stat().st_size for r in records)))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=GAME / ".godot/move_gap_sources")
    fetch(parser.parse_args().output.resolve())
