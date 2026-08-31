# NEXT STEPS — LIVE CHECKPOINT

This file is intentionally short and should be updated frequently. A fresh context should read this immediately after `00_READ_FIRST.md`.

## Current certification chain

Previous certified tranche:

- Branch: `fix/data-v3-howl-target-semantics`
- Final HEAD: `53e20600d372d44bc21eb145f598448a41828e5d`
- PR #57: closed without merge.
- CI: 18/18 SUCCESS on that exact notebook-bearing HEAD.

Current tranche:

- Branch: `fix/data-v3-coaching-semantics`
- PR #58.
- Parent: `53e20600d372d44bc21eb145f598448a41828e5d`.
- Engineering SHA before notebook synchronization: `b7da56687d1e1e45072ca4572f5f0751f9d309d7`.
- Engineering SHA CI: 18/18 SUCCESS, including the independent regenerated-dataset assertion for Coaching.
- Notebook synchronization intentionally moves the branch tip. **Before continuing to another tranche, require 18/18 workflows on the final exact notebook-bearing HEAD and then close PR #58 without merge.** GitHub is authoritative for that final SHA.

## Current workstream

**Move Effects V3 semantic audit.**

Do not switch to trainer AI/archetypes yet.

## Latest exact artifact metrics

From PR #58 engineering SHA `b7da56687d1e1e45072ca4572f5f0751f9d309d7`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 67
- `DATA_ONLY`: 285
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: 61.

- 58 stat-change cases.
- 2 heal cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

## Tranche just completed in PR #58

`Coaching` had two actively wrong generated targets:

- `OPPONENT Attack +1`
- `OPPONENT Defense +1`

The immutable snapshot says Coaching raises an ally Pokémon's Attack and Defense by one stage and fails if there is no ally adjacent to the user. Scarlet/Violet keeps the ally-only semantics. Current Battle Core cannot target allies or represent the adjacent-ally failure condition.

Therefore:

- Source target `user-and-allies` is preserved.
- `Coaching` remains `DATA_ONLY`.
- `effect_specs` is deliberately empty.
- Both false opponent buffs are removed.
- A DATA V3 domain test independently verifies the regenerated JSON remains `target=user-and-allies`, `classification=DATA_ONLY`, and effect-free.

## Exact next technical task

After final exact-head certification and closure of PR #58, continue the two remaining high-risk `user-and-allies` stat moves **one at a time**:

- `Gear Up`: generic output buffs OPPONENT; real semantics apply to friendly Pokémon with Plus/Minus.
- `Magnetic Flux`: generic output buffs OPPONENT; real semantics apply to friendly Pokémon with Plus/Minus.

Do **not** infer their safe representation from Howl or Coaching. Verify source prerequisites and recipient sets separately.

Recommended sequence:

1. Confirm PR #58 final exact HEAD is 18/18 green and close without merge.
2. Start the next branch from that exact SHA.
3. Inspect immutable source + exact generated record for `Gear Up` or `Magnetic Flux`.
4. Decide whether any faithful SELF subset exists; if not, neutralize false effects and keep DATA_ONLY.
5. Add fail-fast adapter contract + independent regenerated-output assertion.
6. Require DATA V3 focal success and 18/18 on the engineering HEAD.
7. Measure the exact artifact.
8. Synchronize notebooks and require 18/18 again on the final HEAD.
9. Close without merge.

## Important known exclusions for now

Do not casually implement/promote:

- `Rest`: intentional `DATA_ONLY` until status replacement/specific sleep semantics exist.
- `Wish`: intentional `DATA_ONLY` until persisted delayed effects exist.
- `Strength Sap`: `PARTIAL_RUNTIME`; Attack drop works, stat-derived healing does not.
- `Roost`: `PARTIAL_RUNTIME`; heal works, temporary Flying-type suppression does not.
- Weather heals: `PARTIAL_RUNTIME` until weather-dependent ratios exist.
- Team-side heals: `PARTIAL_RUNTIME` while effect targets remain SELF/OPPONENT only.
- `Autotomize`, `Charge`, `Defense Curl`, `Minimize`: extra mechanics beyond visible stat changes.
- `Stuff Cheeks`: safely `DATA_ONLY`/effect-free until held-Berry prerequisite + consumption semantics exist.
- `Silk Trap`: safely `DATA_ONLY`/effect-free until protection + contact-response mechanics exist.
- `Aromatic Mist`: safely `DATA_ONLY`/effect-free until ally targeting exists.
- `Howl`: `PARTIAL_RUNTIME`; SELF subset is correct, ally subset remains missing.
- `Coaching`: safely `DATA_ONLY`/effect-free until ally targeting + adjacent-ally failure semantics exist.
- `Purify`, `Swallow`, `Beat Up`: not yet audited; handle separately.

## Stop condition

If any focal or regression test fails, **do not move to another family**. Diagnose and fix the failure first, rerun the focal workflow, then the full regression matrix.
