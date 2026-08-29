# DATA SOURCES — FASE 4 (Pokémon Data Import)

This document records the authoritative source of all imported Pokémon game data and
the provenance metadata attached to the generated dataset.

## Source dataset

| Field | Value |
|---|---|
| Source name | PokéAPI `api-data` |
| Repository URL | `https://github.com/PokeAPI/api-data.git` |
| Source commit (pinned) | `784c50b3` |
| License | CC-BY-SA 3.0 (PokéAPI data) + Pokémon © Nintendo/Creatures/Game Freak |
| Local mirror | `F:\pokemon roma el calvo\POKEMON_DATA_LIBRARY\01_POKEAPI_DATA` |
| Import date | 2026-08-29 |
| Adapter tool | `tools/pokeapi_adapter.py` (Python, build-time only) |
| Importer (runtime) | `modules/data/data_importer.gd` (Godot `DataImporter`) |
| Generated raw | `data/raw/pokemon_api.json` |
| Generated manifest | `data/manifests/pokemon_api_manifest.json` (`source_commit: 784c50b3`) |
| Normalized dump | `data/normalized/pokemon_api.json` |
| Reports | `data/reports/{forms_policy_report,unsupported_mechanics,import_summary}.json` |

## Why a pinned source

The source is treated as **read-only reference data**. The adapter reads the nested
`data/api/v2/{endpoint}/{numeric_id}/index.json` tree and produces a canonical slug-keyed
raw dataset. Slugs are derived from PokéAPI names via `re.sub(r"[^a-z0-9]+", "_", name.lower())`
so every id matches the project regex `^[a-z0-9_]+$` (e.g. `thunder-bolt` → `thunder_bolt`,
`run-away` → `run_away`).

The source commit is recorded in the manifest so the imported dataset is reproducible and
auditable. If the upstream `api-data` is updated, bump the pinned commit and re-run the
adapter + importer, then re-validate.

## What was extracted (FASE 4 scope)

- **Types** (21): name, slug, effectiveness matrix.
- **Moves** (937): power, accuracy, pp, damage_class (physical/special/status), target,
  effect_summary, classification.
- **Abilities** (373): effect_summary, classification (stored as DATA_ONLY; no gameplay logic).
- **Items** (2222): name, slug, classification (DATA_ONLY).
- **Species** (986 base species): 6 base stats (incl. `base_special_attack`/`base_special_defense`),
  primary/secondary type, ability_ids, learnset, evolutions.
- **Forms** (39): deferred by policy (see MECHANICS_COVERAGE.md / forms_policy_report.json).
- **Learnset** (129390 entries): species → move + method.
- **Evolutions** (476 imported): from/to species + trigger (level/item/...).

## What was NOT extracted (deferred to later phases)

- Status conditions (0 in this source clone) — status endpoint not present in pinned commit.
- Move/ability *runtime effects* — stored as human-readable summaries only; resolution deferred
  to Battle Core V2 (no gameplay logic implemented in FASE 4, by design).

## Reproduce

```powershell
# 1) regenerate canonical raw + manifest + reports from the source mirror
python tools/pokeapi_adapter.py

# 2) import via Godot headless (writes import_summary.json + normalized dump)
godot --headless --path .   # runs tools/run_import.gd via the ProjectSettings test hook

# 3) validate
godot --headless --path .   # runs tests/test_runner.gd (40 PASS / 0 FAIL)
```
