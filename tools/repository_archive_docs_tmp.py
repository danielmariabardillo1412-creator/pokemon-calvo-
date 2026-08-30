#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]

LEGACY = [
    "CAPTURE_DATA_AUDIT.md",
    "CODEX_BATTLE_V2_HANDOFF.md",
    "DATA_ARCHITECTURE.md",
    "DATA_SOURCES.md",
    "EVOLUTION_COVERAGE.md",
    "MECHANICS_COVERAGE.md",
    "MOVE_EFFECT_COVERAGE.md",
    "PROGRESSION_DATA_AUDIT.md",
    "evolution_coverage_report.json",
]
RESEARCH = ["TRAINER_AI_RESEARCH_FASE21.md"]


def run(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def git_mv(src: str, dst: str) -> None:
    (ROOT / dst).parent.mkdir(parents=True, exist_ok=True)
    run("git", "mv", src, dst)


def replace(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    changed = text.replace(old, new)
    if changed != text:
        path.write_text(changed, encoding="utf-8")


def update_references() -> None:
    docs = [p for p in (ROOT / "docs").rglob("*.md") if p.is_file()]
    docs.append(ROOT / "README.md")
    for path in docs:
        for name in LEGACY:
            replace(path, f"docs/{name}", f"docs/history/legacy_data/{name}")
            # Links written from docs root.
            if path.parent == ROOT / "docs":
                replace(path, f"]({name})", f"](history/legacy_data/{name})")
        for name in RESEARCH:
            replace(path, f"docs/{name}", f"docs/history/research/{name}")
            if path.parent == ROOT / "docs":
                replace(path, f"]({name})", f"](history/research/{name})")


def check_local_markdown_links() -> None:
    link_re = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
    errors: list[str] = []
    files = [ROOT / "README.md"] + [p for p in (ROOT / "docs").rglob("*.md") if p.is_file()]
    for path in files:
        text = path.read_text(encoding="utf-8")
        for raw in link_re.findall(text):
            target = raw.strip().split()[0].strip("<>")
            if not target or target.startswith(("http://", "https://", "mailto:", "#", "res://")):
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            candidate = (path.parent / target).resolve()
            try:
                candidate.relative_to(ROOT.resolve())
            except ValueError:
                continue
            if not candidate.exists():
                errors.append(f"{path.relative_to(ROOT)} -> {target}")
    if errors:
        raise RuntimeError("broken local markdown links:\n" + "\n".join(sorted(set(errors))))


def main() -> None:
    for name in LEGACY:
        git_mv(f"docs/{name}", f"docs/history/legacy_data/{name}")
    for name in RESEARCH:
        git_mv(f"docs/{name}", f"docs/history/research/{name}")

    update_references()

    (ROOT / "docs/history/README.md").write_text(
        "# Historial técnico\n\n"
        "Este árbol conserva documentación válida para fases anteriores sin presentarla como "
        "estado operativo actual.\n\n"
        "- `phase_reports/`: informes de cierre de fases.\n"
        "- `legacy_data/`: documentación y auditorías de los pipelines DATA V1/V2 y coberturas "
        "anteriores a DATA FOUNDATION V3.\n"
        "- `research/`: investigación y referencias externas que justificaron decisiones técnicas.\n"
        "- `STATUS_PHASE_HISTORY.md`: antiguo estado acumulativo del proyecto.\n\n"
        "Para el estado actual prevalecen `../STATUS.md` y `../DATA_FOUNDATION_V3.md`.\n",
        encoding="utf-8",
    )

    docs_readme = ROOT / "docs/README.md"
    text = docs_readme.read_text(encoding="utf-8")
    text = text.replace(
        "- [`history/phase_reports/`](history/phase_reports/) — informes finales de fases cerradas.\n",
        "- [history/README.md](history/README.md) — guía del archivo histórico.\n"
        "- [`history/phase_reports/`](history/phase_reports/) — informes finales de fases cerradas.\n"
        "- [`history/legacy_data/`](history/legacy_data/) — DATA V1/V2, auditorías y coberturas superadas.\n"
        "- [`history/research/`](history/research/) — investigación técnica preservada.\n",
    )
    docs_readme.write_text(text, encoding="utf-8")

    check_local_markdown_links()
    print("legacy documentation archive migration prepared")


if __name__ == "__main__":
    main()
