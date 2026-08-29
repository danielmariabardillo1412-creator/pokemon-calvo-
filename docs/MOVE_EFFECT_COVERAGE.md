# Move Effect Coverage (FASE 5 — structured metadata → effect_specs)

Source commit `784c50b3ad27d0390d3b047fc4c4511f71edd049` (PokéAPI/api-data, BSD 3-Clause).
Dataset schema_version: **2**. Effect spec schema: BattleEffectSpec V1.

## Generation

`tools/pokeapi_adapter.py` builds `MoveDefinition.effect_specs` from PokéAPI structured move
metadata (no flavor-text parsing). See `docs/ARCHITECTURE_DECISION_004_EFFECT_DATA.md`.

## Totals (937 moves)

| Metric | Count |
| --- | --- |
| `effect_specs_generated` (moves with ≥1 secondary spec) | 352 |
| `generated_by_metadata` (specs derived from structured data) | 433 |
| `generated_by_override` (toxic → badly_poisoned) | 1 |
| `specific_handler` (registry fallback, no dataset specs) | 3 |
| `validation_errors` (importer rejects) | 0 |

## Coverage (honest)

| Category | Before (Battle Core V2) | After (FASE 5) |
| --- | --- | --- |
| `RUNTIME_SUPPORTED` | 376 | **541** |
| `PARTIAL_RUNTIME` | — | 60 |
| `DATA_ONLY` | — | 327 |
| `UNSUPPORTED` (gimmick) | 9 | 9 |

Coverage semantics: a move is `RUNTIME_SUPPORTED` only when **all** of its singles `calvo_v1`
behavior is executed by the runtime **and** at least one test exercises that family.
`PARTIAL_RUNTIME` = damaging move whose secondary effect is not modeled (e.g. `effect_chance`
with an unmodeled bespoke effect, or an unmodeled ailment/stat). `DATA_ONLY` = status / non-
damaging move with no modeled behavior. `UNSUPPORTED` = gimmick/copy moves the model cannot
represent.

## Spec kinds emitted

- `INFLICT_STATUS` (ailment, `CHANCE`-wrapped when chance < 100%)
- `MODIFY_STAT_STAGE` (stat changes; target self/opponent from move target)
- `DRAIN` / `RECOIL` (from `meta.drain`)
- `HEAL` (from `meta.healing`)
- `FLINCH` (`CHANCE`-wrapped)
- `MULTI_HIT` (from `meta.min_hits`/`max_hits`)

## Implemented mechanics

- Multi-hit (`MULTI_HIT`): per-hit damage, recoil/drain repeated per hit.
- Contact: curated override `tools/move_flags_override.json`; `Static` uses `requires_contact`
  (corrected from `requires_physical`).
- Crit: `MoveDefinition.crit_rate_bp` added to the crit threshold in `DamageCalculator`.

## Deferred (documented, not implemented)

- Protect / vulnerable states.
- Weather / terrain / hazards.
- Doubles targeting (moves with `target` ≠ self/opponent resolved best-effort).
- Unmodeled ailments: infatuation, trap, fling.
- Ruleset fingerprint (derive from ruleset + battle algo + effect schema versions).
