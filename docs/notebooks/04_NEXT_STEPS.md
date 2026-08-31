# NEXT STEPS — LIVE CHECKPOINT

This file is intentionally short and should be updated frequently. A fresh context should read this immediately after `00_READ_FIRST.md`.

## Current certification chain

Previous certified tranche:

- Branch: `fix/data-v3-coaching-semantics`
- Final HEAD: `3c4ac4d772a5869b45de592be7dd7f4d9b2a389b`
- PR #58: closed without merge.
- CI: 18/18 SUCCESS on that exact notebook-bearing HEAD.

Current tranche:

- Branch: `fix/data-v3-gear-up-semantics`
- PR #59.
- Parent: `3c4ac4d772a5869b45de592be7dd7f4d9b2a389b`.
- Engineering SHA before notebook synchronization: `d0dc2a82f8c6dcd4112b2b47d64612b56270e38c`.
- Engineering SHA CI: 18/18 SUCCESS, including the independent regenerated-dataset assertion for Gear Up.
- Notebook synchronization intentionally moves the branch tip. **Before continuing to another tranche, require 18/18 workflows on the final exact notebook-bearing HEAD and then close PR #59 without merge.** GitHub is authoritative for that final SHA.

## Current workstream

**Move Effects V3 semantic audit.**

Do not switch to trainer AI/archetypes yet.

## Latest exact artifact metrics

From PR #59 engineering SHA `d0dc2a82f8c6dcd4112b2b47d64612b56270e38c`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 67
- `DATA_ONLY`: 285
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: **60**.

- 57 stat-change cases.
- 2 heal cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

## Tranche just completed in PR #59

`Gear Up` had two actively wrong generic effects:

- `OPPONENT Attack +1`
- `OPPONENT Special Attack +1`

Immutable source semantics:

- source target `user-and-allies`;
- boosts Attack and Special Attack by one stage;
- only **friendly Pokémon with Plus or Minus** are beneficiaries.

Current Battle Core cannot select a friendly side with an Ability predicate. Rewriting the effects to SELF would also be false because the user is only a legal beneficiary when it has Plus or Minus.

Therefore:

- source target is preserved;
- `Gear Up` remains `DATA_ONLY`;
- `effect_specs` is deliberately empty;
- both false opponent buffs are removed;
- DATA V3 independently verifies the regenerated output.

## Exact next technical task

After final exact-head certification and closure of PR #59, audit **`Magnetic Flux` only**.

It is the last known `user-and-allies` DATA_ONLY record with false generic OPPONENT buffs. Current artifact shape before correction:

- `OPPONENT Defense +1`
- `OPPONENT Special Defense +1`

Expected source family: friendly Pokémon with Plus/Minus, but **verify the immutable source independently** before reusing any Gear Up assumption.

Recommended sequence:

1. Confirm PR #59 final exact HEAD is 18/18 green and close without merge.
2. Branch from that exact SHA.
3. Inspect immutable Magnetic Flux source + exact generated record.
4. Decide representation from source semantics; do not infer blindly from Gear Up.
5. Add fail-fast adapter contract + independent regenerated-output assertion.
6. Require DATA V3 focal success and 18/18 on the engineering HEAD.
7. Measure exact artifact.
8. Synchronize notebooks and require 18/18 again on final HEAD.
9. Close without merge.

After Magnetic Flux, regroup the remaining 56 stat-change DATA_ONLY candidates by semantic family before editing anything: likely clean multi-stat self boosts vs condition/cost/field/switch/stateful moves.

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
- `Gear Up`: safely `DATA_ONLY`/effect-free until friendly-side + Plus/Minus filtering exists.
- `Purify`, `Swallow`, `Beat Up`: not yet audited; handle separately.

## Stop condition

If any focal or regression test fails, **do not move to another family**. Diagnose and fix the failure first, rerun the focal workflow, then the full regression matrix.
