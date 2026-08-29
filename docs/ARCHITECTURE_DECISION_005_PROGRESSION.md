# ADR-005 — Progression Core V1

- Status: **Accepted** (FASE 6, 2026-08-29)
- Branch: `feature/progression-core-v1`

## Context

After Battle Core V2 + FASE 5 (move effects as data), the project has a deterministic battle that
produces a `BattleState` but NO per-creature progression: no XP, levels, stats from IV/EV/nature,
individual movesets, learnsets, or evolution. These mechanics must live in their own layer that:

1. Does **not** redesign or re-couple the Battle Core.
2. Does **not** introduce `Autoload` singletons (architecture invariant: 0 autoloads).
3. Does **not** add `extends Node` outside `tests/` (Resources/RefCounted only).
4. Does **not** build UI (presentation consumes events later).
5. Shares the mutation of `CreatureInstance` with Battle without a second source of truth.

## Decision

### Separation of concerns
- `CreatureSpecies` (immutable `Resource`) = definition.
- `CreatureInstance` (mutable `RefCounted`, identity `instance_id`) = single persistent source of truth.
- Progression logic in `modules/creatures/progression/*` (pure functions / stateless services).
- Battle emits `BattleOutcome`; Progression consumes it **after** the battle resolves.
- No `BattleState` → Progression coupling: `BattleOutcome.from_battle_state` reads Battle read-only.

### Why a pure data contract (`BattleOutcome`) instead of a callback into Progression
The Battle Core must remain ignorable of progression. A `BattleOutcome` value object is the only
surface between the two layers. Progression `reconcile_battle_result([survivors], outcome, ...)`
grants XP/EVs/friendship and queues `EVOLUTION_AVAILABLE` events; the caller decides when to apply
evolution and which move choice the player makes.

### Why `CreatureInstance.moveset: Array[BattleMoveSlot]` is the persistent moveset
`BattleMoveSlot` already carries `current_pp`/`max_pp`; battle mutates that slot in place. Storing the
moveset on `CreatureInstance` (not a separate battle-only structure) means PP and move membership
survive across battles and saves without re-binding.

### Why `schema_version` stays 2
`growth_rate`/`ev_yield` are additive fields on `CreatureSpecies`; `CreatureInstance` gained no
schema-impacting key that breaks existing snapshots. Tests assert `==2`.

### XP / stat formulas
Canonical Gen-3/4/5 formulas. `E(1)=0` by policy (level-1 creatures have 0 XP). Stat formulas use
integer EV/4 and nature multipliers of 1.1 / 0.9 / 1.0 (other stats unchanged).

### Evolution coverage is honest
Triggers are classified into `RUNTIME_SUPPORTED` (level-up / trade / use-item, fully executable),
`DATA_ONLY` (special triggers preserved as deferred data) and `UNSUPPORTED` (no model yet). No edge is
promoted to runtime merely because PokéAPI lists a trigger.

## Consequences
- Progression is testable headless without UI or networking (`ProgressionTestSuite`, 71 checks).
- Battle Core surface is unchanged (137 base tests still green).
- Future UI/party/savegame layers compose on top of `ProgressionSystem` + `ProgressionEvent`.
- 12 special evolution triggers remain deferred (data preserved, runtime later).

## Rejected alternatives
- Expanding `BattleState` with progression fields → violates single-responsibility and re-couples layers.
- An `Autoload` `ProgressionManager` → breaks the 0-autoload invariant and hides dependencies.
- Promoting all 476 evolution edges to "supported" → dishonest; 15 special triggers can't be modeled yet.
