# DATA V3 ABILITY STAT/DAMAGE MODIFIERS — V2

## Purpose

Operational checkpoint for the bounded ability tranche following certified PR #79.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family triage;
- `09_DATA_V3_ABILITY_HIT_STAT_REACTIONS.md` for Stamina and hit-reaction limits.

## Certified parent

- PR #79: `DATA V3 — audit hit-triggered stat ability reactions`.
- Certified final HEAD: `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent:
  - `RUNTIME_SUPPORTED`: 8
  - `PARTIAL_RUNTIME`: 4
  - `DATA_ONLY`: 361
  - total: 373.

## Current tranche

- Branch: `audit/data-v3-ability-stat-damage-modifiers-v2`.
- Exact parent: certified #79 final `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`.
- This checkpoint is committed before runtime edits so interruption cannot erase the workstream state.

### Goal

Audit a small subset of remaining `stat_damage_modifier` abilities whose semantics may already fit Battle Core's existing damage-modifier conditions. Prefer mathematically direct, single-effect abilities. Do not bulk-promote the family.

### Rules

1. Immutable source semantics first; English keyword grouping is only triage.
2. Distinguish an Attack-stat modifier from a damage multiplier. They are not automatically equivalent for status moves, confusion/self-damage, critical-stage interactions, or other mechanics outside the modeled damage path.
3. `RUNTIME_SUPPORTED` requires the current modeled battle transaction to be faithful; otherwise use `PARTIAL_RUNTIME` or keep `DATA_ONLY`.
4. Do not add broad new Battle Core state merely to increase coverage in this tranche.
5. Version-sensitive abilities remain blocked unless the pinned source supports one honest current contract.
6. Preserve exact 373-accounting and the no-mass-promotion allowlist invariant.
7. Closure protocol: focal tests -> 18/18 engineering SHA -> artifact diff -> notebook sync -> 18/18 final notebook-bearing SHA -> close without merge.

## Immediate work order

1. Inspect Battle Core's currently supported MODIFY_DAMAGE predicates.
2. Audit a small candidate set from the remaining stat/damage family.
3. Choose only candidates expressible without new broad primitives.
4. Add exact source guards, runtime registration and focal integration tests for the bounded allowlist.
5. Explicitly document nearby rejected candidates and why they remain DATA_ONLY.
