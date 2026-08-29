# MECHANICS COVERAGE — Battle Core V2

Scope: dataset FASE 4.1 + runtime `calvo_v1`. The import report remains an immutable
historical report; current runtime deltas are versioned in
`data/battle/runtime_coverage_v2.json`.

- **DATA_READY** — the necessary data is imported and modeled in the domain classes.
- **RUNTIME_SUPPORTED / PARTIAL_RUNTIME / DATA_ONLY / UNSUPPORTED** — how much the *engine*
  (Foundation V1 battle) can actually execute.

Source: PokéAPI `api-data` @ `784c50b3ad27d0390d3b047fc4c4511f71edd049` (BSD 3-Clause).

## Terminology (honest)

| Label | Meaning |
|---|---|
| `DATA_READY` | Data imported and modeled; available for Battle Core V2 to consume. |
| `RUNTIME_SUPPORTED` | Runtime + test execute the complete behavior claimed for that stable ID under `calvo_v1`. |
| `PARTIAL_RUNTIME` | Part of the behavior is implemented; the rest is not (e.g. damaging move whose secondary effect is unimplemented). |
| `DATA_ONLY` | Definition exists; no runtime behavior in Foundation V1 (e.g. status moves, abilities, items). |
| `UNSUPPORTED` | The model/runtime cannot yet represent or execute the mechanic (gimmick moves; unmodeled evolution triggers). |

> No move is promoted merely because `effect_summary` describes it. Promotion requires an explicit
> structured mapping/handler and runtime test.

## Totals imported

| Category | Count |
|---|---|
| Species (base) | 986 |
| Forms (deferred) | 39 |
| Types | 21 |
| Moves | 937 |
| Abilities | 373 |
| Items | 2222 |
| Status conditions | 0 (not present in pinned source) |
| Learnset entries | 129390 |
| Broken references | 0 |
| Rejected entries | 0 |
| Import time | ~927 ms |

## Moves (937) — DATA_READY = 937

| Coverage | Count | Sum check |
|---|---|---|
| `RUNTIME_SUPPORTED` | 91 | baseline 76 + 15 stable IDs with complete tested V2 mappings |
| `PARTIAL_RUNTIME` | 496 | damaging moves with missing secondary/unique behavior |
| `DATA_ONLY` | 341 | status/non-damaging moves without mapping |
| `UNSUPPORTED` | 9 | gimmick/copy moves the model cannot represent |
| **TOTAL** | **937** | 91 + 496 + 341 + 9 = 937 ✓ |

Newly supported stable IDs: `double_edge`, `ember`, `growl`, `mega_drain`,
`quick_attack`, `recover`, `sleep_powder`, `swords_dance`, `tackle`, `thunder`,
`thunder_punch`, `thunder_wave`, `toxic`, `water_gun`, `will_o_wisp`.

## Abilities (373) — DATA_READY = 373

| Coverage | Count |
|---|---|
| `RUNTIME_SUPPORTED` | 6 (`blaze`, `intimidate`, `levitate`, `overgrow`, `static`, `torrent`) |
| `DATA_ONLY` | 367 |

## Items (2222) — DATA_READY = 2222

| Coverage | Count |
|---|---|
| `RUNTIME_SUPPORTED` | 2 (`leftovers`, `sitrus_berry`) |
| `DATA_ONLY` | 2220 |

## Canonical internal status

PokéAPI aporta 0 definiciones de status. `calvo_v1` define IDs internos versionados:
burn, poison, badly_poisoned, paralysis, sleep y freeze; flinch/confusion son
volátiles. Burn, poison, badly poisoned, paralysis y sleep tienen comportamiento y
tests. Freeze tiene modelo/thaw pero ninguna move V2 lo aplica; confusion solo tiene
estado volátil, por lo que ambos se declaran parciales.

## Evolutions

Raw edges in PokéAPI chains vs. imported edges after the forms policy:

| Metric | Count |
|---|---|
| `SOURCE_EDGES` | 484 |
| `IMPORTED_EDGES` | 476 |
| `DEFERRED_FORM_EDGES` | 8 (dropped: target is a deferred form) |
| `REJECTED_EDGES` | 0 |
| Check | 476 + 8 + 0 = 484 ✓ |

Imported-edge coverage (must sum to `IMPORTED_EDGES` = 476):

| Coverage | Count | Sum check |
|---|---|---|
| `SUPPORTED_RUNTIME_OR_MODEL` | 388 | level-up (min_level stored; model represents it) |
| `PARTIAL_RUNTIME` | 52 | e.g. use-item (item_id stored; partially modeled) |
| `UNSUPPORTED` | 36 | trigger the model cannot represent yet |
| **TOTAL** | **476** | 388 + 52 + 36 = 476 ✓ |

> No evolution is executed at runtime in Foundation V1; `SUPPORTED_RUNTIME_OR_MODEL` means the
> *data model* represents the trigger, not that the engine evolves Pokémon.

## Forms policy (39 deferred)

Hyphenated PokéAPI names are treated as **forms** (regional/alternate/mega/gigantamax/totem/
cosmetic) and are NOT imported as base `SpeciesDefinition`. Only the default variety of each base
species is imported. Evolutions targeting deferred forms are dropped (8 edges) to keep
`broken_references = 0`. Full list: `data/reports/forms_policy_report.json` (`deferred`, 39 entries).

## Referential integrity

- `broken_references = 0` across types, moves, abilities, items, species, learnset, evolutions
  (recomputed independently in `pokeapi_broken_ref_invariant` test).
- `rejected = 0` (after adapter-level item slug de-duplication; one duplicate slug `roseli_berry`
  skipped at adapter time).
- All ids unique per catalog (`pokeapi_ids_unique` test).

## Test evidence (Godot 4.7 stable, headless)

`tests/test_runner.gd` + `tests/battle_v2_test_suite.gd` — **131 PASS / 0 FAIL**:
- FASE 1-3 (foundation + data pipeline): 26 PASS
- FASE 4 (mass import): 14 PASS
- FASE 4.1 (QA invariants): 21 PASS
- Battle Core V2: 70 PASS (unitarios, negativos, cobertura y escenarios golden)

New invariant tests (FASE 4.1): `pokeapi_manifest_sha_full`, `pokeapi_manifest_license_bsd`,
`pokeapi_evolution_source_invariant`, `pokeapi_evolution_coverage_invariant`,
`pokeapi_evolution_imported_matches_catalog`, `pokeapi_evolution_no_deferred_targets`,
`pokeapi_move_coverage_sums`, `pokeapi_move_dataready_matches_catalog`,
`pokeapi_ability_dataready_matches_catalog`, `pokeapi_item_dataready_matches_catalog`,
`pokeapi_unique_ids_*`, `pokeapi_broken_ref_recomputed`, `pokeapi_broken_ref_zero`,
`pokeapi_summary_*`.

## Battle Core V2 result

Battle Core V2 ejecuta specs compuestos, PP, stages, accuracy/evasion, críticos,
status, switching, seis abilities y dos held items. Las evoluciones siguen fuera de
Battle y no han cambiado de cobertura.

### Honest snapshot for Codex

- **DATA available:** 21 types, 937 moves (76 fully damage-resolvable, 504 damage + unimplemented effect, 348 status-only), 373 abilities (data only), 2222 items (data only), 986 species, 129390 learnset entries, 476 evolutions (388 level-up modelable, 52 partial, 36 unsupported).
- **Implemented at runtime:** 91 moves bajo el criterio anterior; 6 abilities; 2 held items;
  canonical status; snapshot v2 y servidor autoritativo determinista.
- **NOT implemented yet:** cientos de secundarios/efectos únicos, la mayoría de abilities/items,
  evolution triggering, forms, capture, XP, networking y presentation.
