# DATA V3 ABILITY EXISTING-PREDICATE SCAN — V1

## Purpose
Operational checkpoint for the bounded ability tranche following certified PR #80.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family triage;
- `10_DATA_V3_ABILITY_STAT_DAMAGE_MODIFIERS.md` for Tough Claws and Attack-doubling blockers.

## Certified parent
- PR #80: `DATA V3 — audit contact damage and attack-doubling abilities`.
- Certified final HEAD: `232a3e787fe2d7d58b1feb693272b63bd7a699bf`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent:
  - `RUNTIME_SUPPORTED`: 9
  - `PARTIAL_RUNTIME`: 4
  - `DATA_ONLY`: 360
  - total: 373.

## Current tranche
- Branch: `audit/data-v3-ability-existing-predicate-scan-v1`.
- Exact parent: certified #80 final `232a3e787fe2d7d58b1feb693272b63bd7a699bf`.
- This checkpoint is committed before runtime edits so interruption cannot erase the workstream state.

### Goal
Scan the remaining DATA_ONLY frontier for a **small bounded subgroup** whose semantics can already be represented by Battle Core's existing damage predicates. Do not add weather, terrain, party, form, item, critical-hit, effectiveness, status-state, or broad new move-tag machinery merely to raise coverage.

### Existing predicate surface at parent
`BattleTriggerSystem` can currently test, for actor-side MODIFY_DAMAGE:
- exact move type (`move_type_id`);
- physical damage class (`requires_physical`);
- contact (`requires_contact`);
- owner HP threshold (`hp_at_or_below_divisor`);
- generic owner missing-HP gate in trigger conditions.

Target-side MODIFY_DAMAGE currently has a narrower execution path: Ground-style immunity is supported through `immune_type_id`; ordinary target-side damage multipliers are not yet a certified general primitive.

### Rules
1. Immutable/source semantics first; keyword grouping is only triage.
2. Prefer exact single-effect mechanics using predicates already in the engine.
3. A stat multiplier is not automatically equivalent to a final damage multiplier.
4. A move-property family (punching, biting, slicing, recoil, sound, base-power threshold, etc.) is out of scope unless the property is already represented canonically by the current move model and trigger evaluator.
5. If the scan yields no clean promotion, record the negative result and move to another family instead of broadening Battle Core solely for coverage.
6. Preserve exact 373-accounting and the explicit no-mass-promotion invariant.
7. Closure protocol remains: focal tests -> 18/18 engineering SHA -> artifact diff -> notebook sync -> 18/18 final notebook-bearing SHA -> close without merge.

## Immediate work order
1. Enumerate remaining DATA_ONLY candidates whose source prose suggests only type/physical/contact/HP predicates.
2. Audit exact immutable source for a small candidate set.
3. Promote only semantically exact candidates; explicitly block near-misses.
4. Add real-battle focal tests for any promotion.
5. Update this notebook with source decisions, SHA, artifact drift and next work.
