# ADR-004: Move effects as structured data (`BattleEffectSpec.effect_specs`)

- Status: ACCEPTED
- Date: 2026-08-29
- Branch: `feature/battle-effects-data-v1`
- Supersedes: the 15 hard-coded explicit move mappings in `BattleEffectRegistry` (kept as fallback only)

## Context

Battle Core V2 (FASE 5 prerequisite, `feature/battle-core-v2`) resolved moves with a small,
hard-coded set of explicit `BattleEffectSpec` per move (15 moves) plus an implicit DAMAGE spec
for any move with `power > 0`. Every other damaging move whose secondary effect was not in that
15-move list was only partially supported, and every status / non-damaging move was `DATA_ONLY`
(no runtime behavior).

We needed to raise `RUNTIME_SUPPORTED` coverage without:
- redesigning Battle Core,
- adding autoloads / EventBus / ECS,
- parsing `effect_summary` / flavor text,
- implementing 937 bespoke per-move handlers.

## Decision

Generate `BattleEffectSpec` `effect_specs` **from PokéAPI structured move metadata** at dataset
build time (adapter `tools/pokeapi_adapter.py`), serialize them on `MoveDefinition`
(`effect_specs: Array[BattleEffectSpec]`), and have the runtime prefer the dataset specs.

Mapping (structured field -> spec):
- `meta.ailment` (+ `ailment_chance`) -> `INFLICT_STATUS` (wrapped in `CHANCE` when chance < 100%).
  Ailment names map to `StatusSystem` ids; `toxic` is overridden to `badly_poisoned`.
- `meta.stat_changes` (+ `stat_chance`) -> `MODIFY_STAT_STAGE` (target = self for user-stat moves
  like Swords Dance, opponent for moves like Growl).
- `meta.drain > 0` -> `DRAIN` (ratio = drain*100 bp); `meta.drain < 0` -> `RECOIL` (ratio = -drain*100 bp).
- `meta.healing > 0` -> `HEAL` (ratio = healing*100 bp).
- `meta.flinch_chance > 0` -> `CHANCE` wrapping `FLINCH`.
- `meta.min_hits`/`max_hits > 1` -> `MULTI_HIT` (children = drain/recoil repeated per hit; damage is
  repeated implicitly by the executor).
- `crit_rate` -> `MoveDefinition.crit_rate_bp` (added to the crit threshold in `DamageCalculator`).

`effect_specs` contain **secondary** effects only. The implicit `DAMAGE` spec is still added by
`BattleEffectRegistry.effects_for_move` for `power > 0` moves, except when a `MULTI_HIT` spec is
present (multi-hit repeats damage internally). `contact` is **not** in PokéAPI source metadata, so
it is supplied via a curated override table `tools/move_flags_override.json` (`makes_contact` on
`MoveDefinition`). `Static` now keys off `requires_contact` (not `requires_physical`).

## Consequences

- `RUNTIME_SUPPORTED` moves: **376 -> 541** (out of 937). `PARTIAL_RUNTIME`: 60. `DATA_ONLY`: 327.
  `UNSUPPORTED`: 9 (gimmick/copy moves).
- The 15 explicit `BattleEffectRegistry` mappings remain as a fallback for moves whose dataset
  provides no specs (does not regress the 131 Battle Core V2 tests, now 137 total).
- `BattleEffectSpec` gained `MULTI_HIT` and `min_hits`/`max_hits`/`min_turns`/`max_turns` fields;
  `BattleEvent.MULTI_HIT` added.
- Strong validation in `DataImporter`: broken specs are rejected and reported (`effect_spec_invalid`).
- Deferred (documented, not implemented this phase): Protect/vulnerable, weather/terrain/hazards,
  doubles targeting, unmodeled ailments (infatuation/trap/fling), ruleset fingerprint.
