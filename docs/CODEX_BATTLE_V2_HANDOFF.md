# CODEX BATTLE CORE V2 — HANDOFF (facts only)

> This document is a verified snapshot for a Codex agent with NO prior context. It states only
> confirmed facts about the current repo. It does NOT ask Codex to implement anything.

## 1. Project

- New Pokémon-style fangame in **Godot 4.7 stable** (`4.7.stable.official.5b4e0cb0f`).
- Repo: `danielmariabardillo1412-creator/pokemon-calvo-`
- Current branch: `feature/pokemon-data-import-v1` (NOT merged to `main`).
- Single Godot binary: `C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe` (no 4.8).

## 2. Architecture (FROZEN)

- Feature-first + selective Clean/Hexagonal. **0 autoloads.** Resources = immutable defs,
  RefCounted = runtime/state, Nodes = presentation only. UI never authority.
- `extends Node` is allowed ONLY under `tests/`. No new autoloads may be added.
- Data flows through `DatasetManifest` → `DataImporter.import_dataset(raw, manifest)`
  → `GameData` (catalogs) → `DefinitionCatalog` facade (battle consumes the facade).
- Battle (Foundation V1) lives under `modules/battle/`; `StatBlock` and `DamageCalculator`
  are the only battle math modules and were NOT modified during data import.

## 3. Dataset (PokéAPI api-data)

- Source: `https://github.com/PokeAPI/api-data.git`
- Pinned FULL SHA: `784c50b3ad27d0390d3b047fc4c4511f71edd049`
- License: **BSD 3-Clause** (verified in `LICENSE.txt`). NOT CC-BY-SA.
- Pokémon names/designs are IP of Nintendo/Creatures/Game Freak; dataset carries no assets.
- Adapter: `tools/pokeapi_adapter.py` (build tool). Importer: `tools/run_import.gd` (Godot
  `--script`) → writes `data/reports/import_summary.json` + `data/normalized/pokemon_api.json`.
- Canonical raw: `data/raw/pokemon_api.json` (12 MB). Manifest: `data/manifests/pokemon_api_manifest.json`.

### Quantities (verified, 2026-08-29)

| Category | Count |
|---|---|
| Species (base) | 986 |
| Forms (deferred) | 39 |
| Types | 21 |
| Moves | 937 |
| Abilities | 373 |
| Items | 2222 |
| Status conditions | 0 (absent in pinned source) |
| Learnset entries | 129390 |
| Broken references | 0 |
| Rejected entries | 0 |

### Evolution edges

- SOURCE_EDGES = 484 · IMPORTED_EDGES = 476 · DEFERRED_FORM_EDGES = 8 · REJECTED_EDGES = 0
- Imported coverage: `SUPPORTED_RUNTIME_OR_MODEL` = 388, `PARTIAL_RUNTIME` = 52, `UNSUPPORTED` = 36 (sums to 476).

## 4. What is DATA_READY vs RUNTIME_SUPPORTED

Move coverage (937 total): `RUNTIME_SUPPORTED` = 76 (damaging, no stored secondary effect),
`PARTIAL_RUNTIME` = 504 (damaging + secondary effect unimplemented), `DATA_ONLY` = 348
(status/non-damaging), `UNSUPPORTED` = 9 (gimmick/copy moves). Sum = 937.

Abilities (373) and Items (2222): `DATA_ONLY` (definition present, no runtime behavior).

### Actually implemented at runtime (Foundation V1)

- Damage calculation for damaging moves: power, accuracy, damage_class, STAB, type effectiveness
  (dual-type), deterministic RNG. Demonstrated by battle tests + `imported_battle` test.
- Deterministic battle snapshots (serialization round-trip).
- Server-authority model: client sends intent only; forged actions rejected.

### NOT implemented at runtime yet (needs Battle Core V2)

- Move secondary effects (status infliction, stat stage changes, terrain, etc.).
- Ability passive effects.
- Item consumable/held effects.
- Status conditions (none imported; endpoint absent in source).
- Evolution triggering.
- Forms as entities (39 deferred forms excluded from base species).

## 5. Tests

- `godot --headless --path .` runs `tests/test_runner.gd` (main scene `tests/test_runner.tscn`).
- Current result: **61 PASS / 0 FAIL** (Godot 4.7 stable, headless).
  - FASE 1-3 (foundation + data pipeline): 26
  - FASE 4 (mass import): 14
  - FASE 4.1 (QA invariants): 21
- Key invariants enforced: evolution source/imported/deferred identity; evolution coverage sums
  to imported; move coverage sums to 937; ability/item DATA_ONLY == catalog size; ids unique;
  broken references recomputed == 0; manifest SHA == full SHA; license == BSD 3-Clause;
  import_summary matches live catalog.

## 6. Risks / notes

- 9 moves and 36 evolutions use mechanics out of Foundation V1 scope (labeled, data retained).
- 39 forms deferred (policy); revisable if megas/regionals wanted as entities.
- 0 status conditions in pinned source — add if source provides them later.
- Dataset is large (raw 12 MB / normalized 14.5 MB), versioned in git; reproducible via adapter.

## 7. Next step (pending authorization)

Authorize **Battle Core V2** to implement runtime behavior (move effects, abilities, items,
statuses, evolution triggers, forms) consuming the already-imported, validated dataset.
Do NOT merge `feature/pokemon-data-import-v1` to `main` and do NOT modify the existing Battle
without explicit go-ahead.
