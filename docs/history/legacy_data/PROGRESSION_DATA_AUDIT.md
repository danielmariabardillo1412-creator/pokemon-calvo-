# PROGRESSION DATA AUDIT (FASE 6)

Source: PokéAPI `api-data` @ `784c50b3ad27d0390d3b047fc4c4511f71edd049` (BSD 3-Clause).

## Field mapping (adapter → domain)

| Domain field | Source endpoint | Source key | Notes |
|---|---|---|---|
| `CreatureSpecies.growth_rate` | `pokemon-species` | `growth_rate.name` | e.g. bulbasaur = `medium-slow` |
| `CreatureSpecies.base_experience` | **`pokemon`** | `base_experience` | **Corrected**: previously read from `pokemon-species` (absent) → produced `0` |
| `CreatureSpecies.ev_yield` | **`pokemon`** | `effort` (per-stat) | mapped to `hp/attack/defense/speed/special_attack/special_defense` |
| `CreatureSpecies.learnset` | `pokemon` | `moves[].version_group_details[].level_learned_at` | already imported in FASE 4 |
| `EvolutionRecord` | `pokemon-species` | `evolves_to[].evolution_details[]` | already imported in FASE 4 |

> **Bug fixed in FASE 6:** `base_experience` lives on the `pokemon` endpoint (per-form stats), NOT on
> `pokemon-species`. The adapter now reads it from `pokemon_by_name[...].base_experience`. Without this,
> every species had `base_experience = 0` and XP-from-defeat was always 0.

## Imported volume (FASE 6 re-import)

- 986 species (base) · 39 forms deferred
- 476 evolution edges (0 broken references, 0 rejected)
- `growth_rate` set on all 986 species (default `medium` if absent)
- `ev_yield` present on all species that yield EVs (most have ≥1)

## Integrity invariants (tests)
- `pokeapi_base_experience_nonzero` — base_experience > 0 for known species (bulbasaur = 64).
- `pokeapi_growth_rate_present` — every species has a recognized `growth_rate`.
- `pokeapi_ev_yield_sum` — sum of EVs per species within sane bounds (≤ 3 stats, ≤ 2 each typical).
- Round-trip `CreatureInstance.to_dict` → `from_dict` preserves all new fields (regression-guarded by
  `battle_state_serialization`).

## Not modeled in FASE 6
- `base_happiness`, `gender_rate` (present in source; deferred — no gameplay consumer yet).
- `effort` values > 3 per species edge cases (none in this source commit).
- Form-based evolution targets (8 edges dropped by forms policy; see `docs/history/legacy_data/MECHANICS_COVERAGE.md`).
