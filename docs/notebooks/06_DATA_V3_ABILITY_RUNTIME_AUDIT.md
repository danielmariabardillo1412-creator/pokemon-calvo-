# DATA V3 ABILITY RUNTIME AUDIT NOTEBOOK

## Purpose

Operational continuity for the ability reliability workstream that starts after Move Effects V3 executable-safety closure.

This notebook is authoritative for the **current ability audit only**. `01_PROJECT_STATE.md` remains the broad project state and `04_NEXT_STEPS.md` remains the short live pointer.

## Certified parent

- Parent workstream: PR #75 — final DATA_ONLY executable move effects.
- Certified parent HEAD: `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`.
- Parent status: 18/18 workflows SUCCESS, PR closed without merge.
- Move Effects V3 safety milestone: `0 DATA_ONLY` move records with non-empty executable `effect_specs`.

## Current tranche

- Branch: `audit/data-v3-ability-runtime-contracts-v1`.
- Goal: establish honest runtime-support semantics for the six abilities already registered in Battle Core before auditing the remaining preserved ability corpus.
- Scope is intentionally narrow: do **not** mass-implement abilities in this tranche.

## Existing mismatch discovered

DATA V3 currently emits all 373 preserved abilities as `DATA_ONLY`.

Battle Core currently has explicit trigger implementations for exactly these six IDs:

- `blaze`
- `intimidate`
- `levitate`
- `overgrow`
- `static`
- `torrent`

The old V2 runtime coverage fixture calls all six `RUNTIME_SUPPORTED`. That label is too coarse for DATA V3 semantic reliability.

## Coverage semantics for this workstream

- `RUNTIME_SUPPORTED`: the battle-relevant source mechanic is faithfully represented by the current engine for states/mechanics the project claims to model; no known missing intrinsic transaction changes the result.
- `PARTIAL_RUNTIME`: a real, useful subset executes correctly, but at least one source-required battle behavior/condition is missing or an in-scope edge case is wrong.
- `DATA_ONLY`: source metadata is preserved but no executable ability mechanic is claimed.
- `UNSUPPORTED`: reserved for ability mechanics that cannot be represented/retained safely under the current contract; do not use merely because an ability is unimplemented.

Coverage labels are claims, not execution gates. Runtime behavior is still determined by Battle Core trigger registrations.

## Initial six-ability audit

### Blaze / Overgrow / Torrent

Immutable source semantics match the current trigger design: at 1/3 max HP or less, matching Fire/Grass/Water moves deal 1.5x regular damage.

Current Battle Core uses `hp_at_or_below_divisor = 3` plus `multiplier_bp = 15000` and routes that multiplier through the real damage calculation.

Provisional decision: `RUNTIME_SUPPORTED` for all three.

### Intimidate

Current Battle Core correctly lowers the opposing active Pokémon's Attack one stage on switch-in in the singles model.

The preserved source also carries additional battle semantics that are not represented by the current trigger model, including acquisition/reacquisition behavior and Substitute-related semantics. Do not claim complete support merely because the base switch-in drop works.

Provisional decision: `PARTIAL_RUNTIME`.

### Levitate

Current Battle Core correctly makes the holder immune to Ground-type move damage.

The preserved source additionally covers grounded-field interactions and suppression conditions such as Spikes/Toxic Spikes/Arena Trap and Gravity/Ingrain/Iron Ball. Those mechanics are not represented by the current ability trigger.

Provisional decision: `PARTIAL_RUNTIME`.

### Static

Current Battle Core correctly models the ordinary case: after contact damage, 30% chance to paralyze the attacker.

A real edge-case gap was found in `TurnExecutor`: AFTER_DAMAGE ability triggers are only requested while the damaged target remains alive, and `_execute_triggers` also rejects knocked-out owners. Therefore a contact hit that knocks out the Static holder cannot currently trigger Static even though contact occurred.

Do **not** make a quick generic trigger change inside this data audit: the same post-damage trigger infrastructure is shared with held items, so a careless change could create false effects such as healing/consumption on fainted creatures.

Provisional decision: `PARTIAL_RUNTIME` until Battle Core receives a deliberate faint-safe trigger policy.

## Expected classification after this tranche

For the 373 preserved abilities:

- `RUNTIME_SUPPORTED`: 3 (`blaze`, `overgrow`, `torrent`)
- `PARTIAL_RUNTIME`: 3 (`intimidate`, `levitate`, `static`)
- `DATA_ONLY`: 367
- Total: 373

These counts are provisional until generated artifact + tests certify them.

## Implementation plan

1. Add an explicit source-validated ability runtime contract module; no heuristic mass classification.
2. Make DATA V3 use that contract when emitting ability `classification`.
3. Add DATA V3 tests for exact IDs/counts and for registry/data consistency.
4. Preserve the Static fatal-contact limitation as a tested/documented partial-support reason rather than silently calling it complete.
5. Run focal DATA V3 + full 18-workflow matrix on exact engineering SHA.
6. Compare regenerated artifact against certified #75 parent; expected semantic changes are ability classification/report metadata only.
7. Update this notebook plus `01_PROJECT_STATE.md` / `04_NEXT_STEPS.md` as appropriate, rerun 18/18 on exact notebook-bearing final HEAD, then close PR without merge if green.

## Next work after this tranche

Do not yet implement hundreds of abilities. First inventory/classify the remaining 367 by semantic families and identify which families the current Battle Core primitives can represent safely.
