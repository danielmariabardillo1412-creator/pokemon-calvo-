# DATA SOURCES — FASE 4 (Pokémon Data Import)

This document records the authoritative source of all imported Pokémon game data and
the provenance metadata attached to the generated dataset.

## Source dataset

| Field | Value |
|---|---|
| Source name | PokéAPI `api-data` |
| Repository URL | `https://github.com/PokeAPI/api-data.git` |
| Source commit (FULL SHA, pinned) | `784c50b3ad27d0390d3b047fc4c4511f71edd049` |
| Source commit (short, display only) | `784c50b3` |
| License | **BSD 3-Clause** (see `LICENSE.txt` in the `api-data` repo). |
| Local mirror | `F:\pokemon roma el calvo\POKEMON_DATA_LIBRARY\01_POKEAPI_DATA` |
| Import date | 2026-08-29 |
| Adapter tool | `tools/pokeapi_adapter.py` (Python, build-time only) |
| Importer (runtime) | `modules/data/data_importer.gd` (Godot `DataImporter`) |
| Generated raw | `data/raw/pokemon_api.json` |
| Generated manifest | `data/manifests/pokemon_api_manifest.json` (`source_commit: 784c50b3ad27d0390d3b047fc4c4511f71edd049`) |
| Normalized dump | `data/normalized/pokemon_api.json` |
| Reports | `data/reports/{forms_policy_report,unsupported_mechanics,import_summary}.json` |

### License clarification (important)

- The dataset is derived from **PokéAPI `api-data`**, which is distributed under the
  **BSD 3-Clause** license (verified against `LICENSE.txt` at commit
  `784c50b3ad27d0390d3b047fc4c4511f71edd049`). It is NOT CC-BY-SA 3.0.
- BSD 3-Clause permits redistribution with the copyright notice and disclaimer retained.
- **Pokémon character names, designs, and assets are intellectual property of
  Nintendo / Creatures / Game Freak.** The BSD 3-Clause license of the `api-data` repository
  covers the factual/structured game data as packaged by PokéAPI; it does NOT grant any rights
  to Nintendo/Creatures/Game Freak IP. This project is not affiliated with or endorsed by them.
- No Pokémon artwork, audio, or binary assets are included. Only structured factual data
  (stats, types, learnsets, etc.) is imported.

## Why a pinned source

The source is treated as **read-only reference data**. The adapter reads the nested
`data/api/v2/{endpoint}/{numeric_id}/index.json` tree and produces a canonical slug-keyed
raw dataset. Slugs are derived from PokéAPI names via `re.sub(r"[^a-z0-9]+", "_", name.lower())`
so every id matches the project regex `^[a-z0-9_]+$` (e.g. `thunder-bolt` → `thunder_bolt`,
`run-away` → `run_away`).

The source commit is recorded (FULL SHA) in the manifest so the imported dataset is reproducible
and auditable. If the upstream `api-data` is updated, bump the pinned commit and re-run the
adapter + importer, then re-validate.

## What was extracted (FASE 4 scope)

- **Types** (21): name, slug, effectiveness matrix.
- **Moves** (937): power, accuracy, pp, damage_class (physical/special/status), target,
  effect_summary, classification.
- **Abilities** (373): effect_summary, classification (stored as DATA_ONLY; no gameplay logic).
- **Items** (2222): name, slug, classification (DATA_ONLY).
- **Species** (986 base species): 6 base stats, primary/secondary type, ability_ids, learnset, evolutions.
- **Forms** (39): deferred by policy (see MECHANICS_COVERAGE.md / forms_policy_report.json).
- **Learnset** (129390 entries): species → move + method.
- **Evolutions**:
  - SOURCE_EDGES = 484 (raw links in PokéAPI evolution chains)
  - IMPORTED_EDGES = 476 (after dropping edges targeting deferred forms)
  - DEFERRED_FORM_EDGES = 8 (edges to deferred forms, dropped to avoid broken refs)
  - REJECTED_EDGES = 0

## What was NOT extracted (deferred to later phases)

- Status conditions (0 in this source clone) — status endpoint not present in pinned commit.
- Move/ability/item/evolution *runtime effects* — stored as data only; resolution deferred to
  Battle Core V2 (no gameplay logic implemented in FASE 4, by design).

## Reproduce

```powershell
# 1) regenerate canonical raw + manifest + reports from the source mirror
python tools/pokeapi_adapter.py

# 2) import via Godot headless (writes import_summary.json + normalized dump)
godot --headless --script tools/run_import.gd --path .

# 3) validate (61 PASS / 0 FAIL on Godot 4.7 stable, headless)
godot --headless --path .
```
