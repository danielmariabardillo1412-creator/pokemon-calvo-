# MECHANICS COVERAGE — FASE 4 (Pokémon Data Import)

Scope: this phase imports data and **validates referential integrity**. It does NOT implement
gameplay logic. The coverage labels below describe how much of each mechanic's *data* was
captured and, for moves/abilities/evolutions, how much is already resolvable by Foundation V1's
stat-only battle (Battle Core V2 will consume the rest).

Legend:
- **SUPPORTED** — fully usable by current/built data model (stat-affecting move or known trigger).
- **PARTIAL** — imported, but effect/mechanic needs Battle Core V2 to resolve at runtime.
- **UNSUPPORTED** — imported as data only, mechanic explicitly out of Foundation V1 scope.
- **DATA_ONLY** — stored as a definition (name/summary/classification); no runtime behavior yet.

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
| Evolutions (imported) | 476 |
| Broken references | 0 |
| Rejected entries | 0 |
| Import time | 832 ms |

## Moves (937)

| Coverage | Count | Notes |
|---|---|---|
| SUPPORTED | 580 | Damage/stat moves resolvable by stat-only battle (power, accuracy, pp, damage_class). |
| PARTIAL | 348 | Imported; secondary effects (status, stat stages, terrain) need Battle Core V2. |
| UNSUPPORTED | 9 | Mechanic out of Foundation V1 scope (stored as data only). |

## Abilities (373)

| Coverage | Count | Notes |
|---|---|---|
| DATA_ONLY | 373 | `effect_summary` + `classification` stored; no passive runtime behavior yet. |

## Items (2222)

| Coverage | Count | Notes |
|---|---|---|
| DATA_ONLY | 2222 | `classification` stored; consumable/held effects deferred to Battle Core V2. |

## Evolutions (476 imported)

| Coverage | Count | Notes |
|---|---|---|
| SUPPORTED | 394 | Trigger known to data model (level-up, item, trade, friendship). |
| UNSUPPORTED | 90 | Trigger not yet modeled (e.g. specific location/genre/known-move conditions). |

(Note: raw api-data lists 484 evolution edges; 8 targeting deferred forms were dropped to
avoid broken references — see forms policy below.)

## Forms policy (39 deferred)

Hyphenated PokéAPI names are treated as **forms** (regional/alternate/mega/gigantamax/totem/
cosmetic) and are NOT imported as base `SpeciesDefinition`. Only the default variety of each base
species is imported. Evolutions targeting deferred forms are dropped to keep `broken_references = 0`.
Full list: `data/reports/forms_policy_report.json` (`deferred`, 39 entries).

## Referential integrity

- `broken_references = 0` across types, moves, abilities, items, species, learnset, evolutions.
- `rejected = 0` (after adapter-level item slug de-duplication; one duplicate slug `roseli_berry`
  skipped at adapter time).
- Artificial broken-reference test (`pokeapi_artificial_broken_ref`) confirms the validator rejects
  unknown type references instead of silently importing them.

## Test evidence

`tests/test_runner.gd` — 40 PASS / 0 FAIL (Godot 4.7 stable, headless):
- `pokeapi_manifest_valid`, `pokeapi_known_species`, `pokeapi_known_type`,
  `pokeapi_known_move`, `pokeapi_known_ability`, `pokeapi_known_evolution`,
  `pokeapi_known_learnset`, `pokeapi_full_catalog_load`, `pokeapi_no_broken_references`,
  `pokeapi_artificial_broken_ref`, `pokeapi_forms_policy`, `pokeapi_forms_not_in_catalog`,
  `pokeapi_deterministic_ordering`, `pokeapi_big_round_trip`.

## Readiness for Battle Core V2

Data layer is ready: types, moves (with damage_class/power/accuracy/pp/target), abilities,
items, species (full 6 base stats), learnset, and evolutions are all present and referentially
sound. Battle Core V2 may now be authorized to consume `MoveDefinition`/`AbilityDefinition`/
`ItemDefinition` effect data without further data import.
