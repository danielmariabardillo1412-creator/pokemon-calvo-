# NEXT STEPS — LIVE CHECKPOINT

This file is intentionally short and should be updated frequently. A fresh context should read this immediately after `00_READ_FIRST.md`.

## Latest certified engineering baseline before notebooks

- Branch: `fix/data-v3-simple-self-stat-boosts-b`
- HEAD: `24889d355e8d89f8873d2d958efb951080fd8027`
- PR #51: closed without merge.
- CI: 18/18 SUCCESS on that exact HEAD.

Current notebook insertion branch:

- `docs/project-notebooks-v1`
- Parent: `24889d355e8d89f8873d2d958efb951080fd8027`

Before continuing data work, certify this notebook branch and then use its final HEAD as the parent for the next DATA V3 tranche so the notebooks remain in the branch chain.

## Current workstream

**Move Effects V3 semantic audit.**

Do not switch to trainer AI/archetypes yet.

## Current coverage snapshot after PR #51

- `RUNTIME_SUPPORTED`: 552
- `PARTIAL_RUNTIME`: 66
- `DATA_ONLY`: 289
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: 69.

- 66 stat-change cases.
- 2 heal cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

## Exact next technical task

Continue auditing the remaining 66 stat-change `DATA_ONLY` moves by **small semantic family**.

Recommended next move selection:

1. Use the exact DATA V3 artifact generated from the latest certified HEAD.
2. Find another small set of apparently pure self stat boosts.
3. Verify immutable PokéAPI source semantics for every candidate.
4. Exclude any move with extra state or mechanics, including examples such as `Stockpile`, `Charge`, `Minimize`, `No Retreat`, or similar unique behavior.
5. Confirm Battle Core supports every represented stat effect.
6. Extend the existing explicit `_SIMPLE_SELF_STAT_BOOSTS` contract only for proven-clean moves.
7. Extend the DATA V3 raw invariant gate in lockstep.
8. Open a small PR against the latest certified branch.
9. Require focal DATA V3 success and then 18/18 workflows on the exact HEAD.
10. Close without merge after certification.
11. Update this file and `02_DATA_V3_MOVE_EFFECTS_AUDIT.md`.

## Important known exclusions for now

Do not casually implement/promote:

- `Rest`: intentional `DATA_ONLY` until status replacement/specific sleep semantics exist.
- `Wish`: intentional `DATA_ONLY` until persisted delayed effects exist.
- `Strength Sap`: `PARTIAL_RUNTIME`; Attack drop works, stat-derived healing does not.
- `Roost`: `PARTIAL_RUNTIME`; heal works, temporary Flying-type suppression does not.
- Weather heals: `PARTIAL_RUNTIME` until weather-dependent ratios exist.
- Team-side heals: `PARTIAL_RUNTIME` while effect targets remain SELF/OPPONENT only.
- `Purify`, `Swallow`, `Beat Up`: not yet audited; handle separately.

## Stop condition

If any focal or regression test fails, **do not move to another family**. Diagnose and fix the failure first, rerun the focal workflow, then the full regression matrix.
