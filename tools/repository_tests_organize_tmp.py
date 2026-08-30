#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"


def run(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def group(name: str) -> str:
    if name == "test_runner.gd":
        return "root"
    if name.startswith("trainer_"):
        return "trainer_ai"
    if name.startswith("battle_"):
        return "battle"
    if name.startswith(("data_foundation_", "spanish_")):
        return "data"
    if name.startswith((
        "inventory_", "savegame_", "wild_", "overworld_", "vertical_slice_",
        "progression_", "capture_", "party_", "storage_",
    )):
        return "gameplay"
    return "UNCLASSIFIED"


def replace_references(mapping: dict[str, str]) -> None:
    extensions = {".gd", ".md", ".tscn", ".tres", ".json", ".py", ".sh"}
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in extensions:
            continue
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith(".github/workflows/"):
            continue
        if rel == "tools/repository_tests_organize_tmp.py":
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        changed = text
        for old, new in mapping.items():
            changed = changed.replace(f"res://{old}", f"res://{new}")
            changed = changed.replace(old, new)
        if changed != text:
            path.write_text(changed, encoding="utf-8")


def main() -> None:
    top_level = sorted(p for p in TESTS.glob("*.gd") if p.name != "test_runner.gd")
    classifications = {p.name: group(p.name) for p in top_level}
    unclassified = sorted(name for name, g in classifications.items() if g == "UNCLASSIFIED")
    if unclassified:
        raise RuntimeError("unclassified tests: " + ", ".join(unclassified))

    mapping: dict[str, str] = {}
    for path in top_level:
        target_dir = TESTS / classifications[path.name]
        target_dir.mkdir(parents=True, exist_ok=True)
        old_rel = path.relative_to(ROOT).as_posix()
        new_rel = (target_dir / path.name).relative_to(ROOT).as_posix()
        mapping[old_rel] = new_rel
        run("git", "mv", old_rel, new_rel)

        uid = ROOT / f"{old_rel}.uid"
        if not uid.exists():
            raise RuntimeError(f"missing UID sidecar for {old_rel}")
        run("git", "mv", f"{old_rel}.uid", f"{new_rel}.uid")

    replace_references(mapping)

    (TESTS / "README.md").write_text(
        "# Tests\n\n"
        "`test_runner.gd` permanece en la raíz como regresión global. El resto se organiza por dominio:\n\n"
        "- `battle/`: Battle Core/presentación/comandos/captura/switch/run.\n"
        "- `data/`: DATA FOUNDATION V3 y tipos españoles.\n"
        "- `gameplay/`: progresión, captura/party, inventario, savegame, encuentros, overworld y vertical slice.\n"
        "- `trainer_ai/`: FASE19+ de IA de entrenadores, benchmarks y corpus.\n\n"
        "Los archivos `*.gd.uid` son metadata persistente de Godot 4.4+ y se versionan junto a su script.\n"
        "Los workflows de `.github/workflows/` son los gates autoritativos; no se borran suites históricas mientras sigan formando parte de esos gates.\n",
        encoding="utf-8",
    )

    print(f"organized_test_scripts={len(mapping)}")
    for old, new in sorted(mapping.items()):
        print(f"{old} -> {new}")


if __name__ == "__main__":
    main()
