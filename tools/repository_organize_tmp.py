#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def run(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def git_mv(src: str, dst: str) -> None:
    source = ROOT / src
    target = ROOT / dst
    if not source.exists():
        raise RuntimeError(f"missing source: {src}")
    target.parent.mkdir(parents=True, exist_ok=True)
    run("git", "mv", src, dst)


def replace_in_file(path: Path, replacements: list[tuple[str, str]]) -> None:
    text = path.read_text(encoding="utf-8")
    new = text
    for old, replacement in replacements:
        new = new.replace(old, replacement)
    if new != text:
        path.write_text(new, encoding="utf-8")


def tracked_text_files() -> list[Path]:
    # Intentionally excludes .github/workflows and tools. A migration must never
    # rewrite its own workflow or its own source while it is executing.
    patterns = [
        "README.md",
        "docs/**/*.md",
        "tests/**/*.gd",
        "modules/**/*.gd",
        "scenes/**/*.tscn",
    ]
    files: set[Path] = set()
    for pattern in patterns:
        for path in ROOT.glob(pattern):
            if path.is_file():
                files.add(path)
    return sorted(files)


def main() -> None:
    # 1) Reclassify old runtime resources as regression fixtures.
    fixture_root = ROOT / "data/fixtures/regression_resources"
    fixture_root.mkdir(parents=True, exist_ok=True)
    for name in ("species", "moves", "types", "statuses"):
        git_mv(f"data/{name}", f"data/fixtures/regression_resources/{name}")
    (fixture_root / "battle").mkdir(parents=True, exist_ok=True)
    git_mv(
        "data/battle/runtime_coverage_v2.json",
        "data/fixtures/regression_resources/battle/runtime_coverage_v2.json",
    )

    # 2) Separate architecture decisions and historical phase reports.
    (ROOT / "docs/adr").mkdir(parents=True, exist_ok=True)
    for path in sorted((ROOT / "docs").glob("ARCHITECTURE_DECISION_*.md")):
        git_mv(path.relative_to(ROOT).as_posix(), f"docs/adr/{path.name}")

    (ROOT / "docs/history/phase_reports").mkdir(parents=True, exist_ok=True)
    for path in sorted((ROOT / "docs").glob("INFORME_FINAL_*.md")):
        git_mv(path.relative_to(ROOT).as_posix(), f"docs/history/phase_reports/{path.name}")

    (ROOT / "docs/history").mkdir(parents=True, exist_ok=True)
    git_mv("docs/STATUS.md", "docs/history/STATUS_PHASE_HISTORY.md")

    # 3) Archive the superseded absolute-path PokéAPI adapter.
    (ROOT / "tools/archive").mkdir(parents=True, exist_ok=True)
    git_mv("tools/pokeapi_adapter.py", "tools/archive/pokeapi_adapter_v2_legacy.py")

    # 4) Update active path references. Historical documents are preserved, but
    # repository paths are updated so references do not point to locations that
    # no longer exist.
    replacements = [
        ("res://data/species/", "res://data/fixtures/regression_resources/species/"),
        ("res://data/moves/", "res://data/fixtures/regression_resources/moves/"),
        ("res://data/types/", "res://data/fixtures/regression_resources/types/"),
        ("res://data/statuses/", "res://data/fixtures/regression_resources/statuses/"),
        (
            "res://data/battle/runtime_coverage_v2.json",
            "res://data/fixtures/regression_resources/battle/runtime_coverage_v2.json",
        ),
        (
            "data/battle/runtime_coverage_v2.json",
            "data/fixtures/regression_resources/battle/runtime_coverage_v2.json",
        ),
        ("docs/ARCHITECTURE_DECISION_", "docs/adr/ARCHITECTURE_DECISION_"),
        ("docs/INFORME_FINAL_", "docs/history/phase_reports/INFORME_FINAL_"),
    ]
    for path in tracked_text_files():
        replace_in_file(path, replacements)
        if path.parent == ROOT / "docs":
            replace_in_file(
                path,
                [
                    ("](ARCHITECTURE_DECISION_", "](adr/ARCHITECTURE_DECISION_"),
                    ("](INFORME_FINAL_", "](history/phase_reports/INFORME_FINAL_"),
                ],
            )

    v3 = ROOT / "tools/pokeapi_adapter_v3.py"
    replace_in_file(
        v3,
        [
            (
                "from pokeapi_adapter.py is intentionally reused",
                "from archive/pokeapi_adapter_v2_legacy.py is intentionally reused",
            )
        ],
    )

    # .gitkeep files are noise once the directory contains canonical data.
    for rel in ("data/raw/.gitkeep", "data/normalized/.gitkeep"):
        if (ROOT / rel).exists():
            run("git", "rm", rel)

    # 5) Replace stale current-facing documentation with concise canonical entrypoints.
    (ROOT / "README.md").write_text(
        "# Pokémon Calvo\n\n"
        "Proyecto de fangame de criaturas en **Godot 4.7**, con Battle Core determinista, "
        "progresión/captura/overworld y una IA de entrenadores no neuronal con búsqueda, "
        "belief inference, self-play, objetos, switching estratégico y composición de equipos.\n\n"
        "## Baseline certificado\n\n"
        "La base de datos canónica actual es **DATA FOUNDATION V3**, conservada en "
        "`feature/data-foundation-v3` (HEAD certificado `304035e2e7b39a628c4fece89cf0f3db6caa8664`). "
        "Ese HEAD pasó los 18 workflows normales del proyecto.\n\n"
        "La fuente PokéAPI es un snapshot versionado en `data/api/v2` + `data/schema/v2`; "
        "`tools/pokeapi_adapter_v3.py` genera el raw/manifiesto y Godot normaliza mediante "
        "`tools/run_import.gd`.\n\n"
        "## Ejecutar tests\n\n"
        "```bash\n"
        "godot --headless --path . --import\n"
        "godot --headless --path . --script res://tests/test_runner.gd\n"
        "```\n\n"
        "No se fija aquí un número de PASS: el total crece con el proyecto y la fuente de "
        "verdad son los workflows de `.github/workflows/`.\n\n"
        "## Documentación\n\n"
        "- Estado actual: [docs/STATUS.md](docs/STATUS.md)\n"
        "- Índice documental: [docs/README.md](docs/README.md)\n"
        "- DATA FOUNDATION V3: [docs/DATA_FOUNDATION_V3.md](docs/DATA_FOUNDATION_V3.md)\n"
        "- Arquitectura general: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)\n"
        "- ADR: [`docs/adr/`](docs/adr/)\n"
        "- Historial de fases: [`docs/history/`](docs/history/)\n",
        encoding="utf-8",
    )

    (ROOT / "docs/STATUS.md").write_text(
        "# Estado actual del proyecto\n\n"
        "## Baseline certificado\n\n"
        "- Motor: **Godot 4.7**.\n"
        "- Baseline previo a esta reorganización: `feature/data-foundation-v3`.\n"
        "- HEAD certificado: `304035e2e7b39a628c4fece89cf0f3db6caa8664`.\n"
        "- Validación: **18/18 workflows normales SUCCESS** sobre ese mismo HEAD.\n"
        "- Política de desarrollo: las ramas validadas se conservan y los PR se cierran sin merge.\n\n"
        "## Datos canónicos — DATA FOUNDATION V3\n\n"
        "- 1025 especies base y 326 formas auditadas.\n"
        "- 18 tipos de combate.\n"
        "- 919 movimientos runtime.\n"
        "- 373 habilidades y 2222 objetos.\n"
        "- 61.102 entradas de learnset version-aware.\n"
        "- 554 registros de evolución.\n"
        "- 0 referencias rotas y 0 definiciones rechazadas.\n\n"
        "Fuente inmutable: `data/api/v2` + `data/schema/v2`. Véase "
        "[DATA_FOUNDATION_V3.md](DATA_FOUNDATION_V3.md).\n\n"
        "## IA de entrenadores\n\n"
        "La línea FASE19–FASE33 está presente en el baseline y cubre sesión de entrenador, "
        "inteligencia táctica, beliefs sin cheating, búsqueda simultánea, presupuesto de profundidad, "
        "self-play/evaluación, adaptive branching, cobertura pública, objetos finitos, switching "
        "estratégico, loadouts y composición de equipos. Las decisiones están en [`adr/`](adr/).\n\n"
        "## Organización del repositorio\n\n"
        "Los recursos sintéticos/antiguos que todavía sostienen regresiones no son datos de juego "
        "canónicos: viven bajo `data/fixtures/`. Los documentos de fases cerradas viven bajo "
        "`docs/history/`; los ADR bajo `docs/adr/`.\n\n"
        "El estado histórico acumulado anterior se conserva íntegro en "
        "[history/STATUS_PHASE_HISTORY.md](history/STATUS_PHASE_HISTORY.md).\n",
        encoding="utf-8",
    )

    (ROOT / "docs/README.md").write_text(
        "# Índice de documentación\n\n"
        "## Actual\n\n"
        "- [STATUS.md](STATUS.md) — estado operativo actual.\n"
        "- [DATA_FOUNDATION_V3.md](DATA_FOUNDATION_V3.md) — contrato y snapshot de datos canónico.\n"
        "- [ARCHITECTURE.md](ARCHITECTURE.md) — reglas arquitectónicas generales.\n"
        "- [BATTLE_ARCHITECTURE.md](BATTLE_ARCHITECTURE.md) — Battle Core.\n"
        "- [PROGRESSION_ARCHITECTURE.md](PROGRESSION_ARCHITECTURE.md) — progresión.\n"
        "- [CAPTURE_ARCHITECTURE.md](CAPTURE_ARCHITECTURE.md) — captura/party.\n"
        "- [SAVEGAME_ARCHITECTURE.md](SAVEGAME_ARCHITECTURE.md) — persistencia.\n"
        "- [STORAGE_ARCHITECTURE.md](STORAGE_ARCHITECTURE.md) — almacenamiento.\n"
        "- [THIRD_PARTY_CODE.md](THIRD_PARTY_CODE.md) — procedencia de terceros.\n\n"
        "## Architecture Decision Records\n\n"
        "Los ADR 001–033 están en [`adr/`](adr/). Se conservan porque documentan decisiones "
        "técnicas y límites que siguen siendo relevantes para evitar regresiones conceptuales.\n\n"
        "## Historial\n\n"
        "- [`history/phase_reports/`](history/phase_reports/) — informes finales de fases cerradas.\n"
        "- [history/STATUS_PHASE_HISTORY.md](history/STATUS_PHASE_HISTORY.md) — antiguo STATUS acumulativo.\n\n"
        "Los documentos históricos pueden contener cifras y rutas válidas para su fase original que "
        "ya no describen el baseline actual. Para datos actuales prevalecen `STATUS.md` y "
        "`DATA_FOUNDATION_V3.md`.\n",
        encoding="utf-8",
    )

    (ROOT / "data/fixtures/README.md").write_text(
        "# Fixtures de regresión\n\n"
        "Este directorio contiene **datos de prueba**, no el dataset canónico del juego.\n\n"
        "- `starter_dataset.json` + `../manifests/starter_manifest.json`: fixture del Data Pipeline V1.\n"
        "- `regression_resources/`: Resources `.tres` sintéticos/estables usados por regresiones "
        "históricas (Foundation, tipos españoles y Battle V2).\n\n"
        "Los datos Pokémon canónicos proceden del snapshot `data/api/v2` + `data/schema/v2`, "
        "se generan en `data/raw/pokemon_api.json` y se normalizan en "
        "`data/normalized/pokemon_api.json`.\n",
        encoding="utf-8",
    )

    (ROOT / "tools/archive/README.md").write_text(
        "# Herramientas archivadas\n\n"
        "`pokeapi_adapter_v2_legacy.py` es el adaptador PokéAPI anterior a DATA FOUNDATION V3. "
        "Se conserva únicamente por trazabilidad histórica: contiene rutas locales absolutas y no "
        "debe usarse para regenerar el dataset actual.\n\n"
        "El adaptador canónico es `../pokeapi_adapter_v3.py`. Documentos históricos pueden mencionar "
        "la antigua ruta `tools/pokeapi_adapter.py` porque era correcta en la fase que describen.\n",
        encoding="utf-8",
    )

    print("repository organization migration prepared")


if __name__ == "__main__":
    main()
