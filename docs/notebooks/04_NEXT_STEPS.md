# NEXT STEPS — LIVE CHECKPOINT

This file is intentionally short and should be updated frequently. A fresh context should read this immediately after `00_READ_FIRST.md`.

## Current certification chain

Previous certified tranche:

- Branch: `fix/data-v3-silk-trap-semantics`
- Final HEAD: `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`
- PR #54: closed without merge.
- CI: 18/18 SUCCESS on that exact notebook-bearing HEAD.

Current tranche:

- Branch: `fix/data-v3-aromatic-mist-semantics`
- PR #55.
- Parent: `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`.
- Engineering SHA before notebook synchronization: `7ae7d5c8f20c555e03411e3baacdbd2de1084f1c`.
- Engineering SHA CI: 18/18 SUCCESS, including the independent regenerated-dataset assertion for Aromatic Mist.
- Notebook synchronization intentionally moves the branch tip. **Before continuing to another tranche, require 18/18 workflows on the final exact notebook-bearing HEAD and then close PR #55 without merge.** GitHub is authoritative for that final SHA.

## Current workstream

**Move Effects V3 semantic audit.**

Do not switch to trainer AI/archetypes yet.

## Latest exact artifact metrics

From PR #55 engineering SHA `7ae7d5c8f20c555e03411e3baacdbd2de1084f1c`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 66
- `DATA_ONLY`: 286
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: 64.

- 61 stat-change cases.
- 2 heal cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

## Tranche just completed in PR #55

`Aromatic Mist` had an incorrect generated runtime effect:

`SELF Special Defense +1`

The immutable PokéAPI snapshot explicitly has `target=ally` and describes raising a selected ally's Special Defense by one stage. Current Battle Core cannot target an ally because runtime effect targets are SELF/OPPONENT only.

Therefore:

- `Aromatic Mist` remains `DATA_ONLY`.
- Source target `ally` is preserved.
- `effect_specs` is now deliberately empty.
- The false self-buff is removed.
- A DATA V3 domain test independently verifies the regenerated JSON remains `target=ally`, `classification=DATA_ONLY`, and effect-free.

## Exact next technical task

After final exact-head certification and closure of PR #55, continue the remaining 61 stat-change `DATA_ONLY` moves by **small semantic family**.

Recommended next selection strategy:

1. Use the exact DATA V3 artifact from the final certified PR #55 chain.
2. Group remaining stat-change cases by source target, generated runtime target, and number/type of effects.
3. Prioritize target mismatches and conditional/triggered effects because they can produce actively false runtime behavior even while classification remains DATA_ONLY.
4. Keep ally/team/protection/conditional mechanics effect-free unless the current Battle Core can represent them faithfully.
5. Only promote pure stat moves after immutable-source verification and exact generated-effect validation.
6. Keep `Autotomize`, `Charge`, `Defense Curl`, `Minimize`, and `Stuff Cheeks` out of pure-boost batches because they have extra mechanics.
7. Add fail-fast adapter contracts and independent regenerated-output assertions whenever effect shape/target is corrected.
8. Open one small PR against the final certified PR #55 branch/head chain.
9. Require focal DATA V3 success and 18/18 workflows on the engineering HEAD.
10. Synchronize notebooks, then require 18/18 again on the final notebook-bearing HEAD.
11. Close without merge.

## Important known exclusions for now

Do not casually implement/promote:

- `Rest`: intentional `DATA_ONLY` until status replacement/specific sleep semantics exist.
- `Wish`: intentional `DATA_ONLY` until persisted delayed effects exist.
- `Strength Sap`: `PARTIAL_RUNTIME`; Attack drop works, stat-derived healing does not.
- `Roost`: `PARTIAL_RUNTIME`; heal works, temporary Flying-type suppression does not.
- Weather heals: `PARTIAL_RUNTIME` until weather-dependent ratios exist.
- Team-side heals: `PARTIAL_RUNTIME` while effect targets remain SELF/OPPONENT only.
- `Autotomize`, `Charge`, `Defense Curl`, `Minimize`, `Stuff Cheeks`: extra mechanics beyond their visible stat boost.
- `Silk Trap`: safely `DATA_ONLY`/effect-free until protection + contact-response mechanics exist.
- `Aromatic Mist`: safely `DATA_ONLY`/effect-free until ally targeting exists.
- `Purify`, `Swallow`, `Beat Up`: not yet audited; handle separately.

## Stop condition

If any focal or regression test fails, **do not move to another family**. Diagnose and fix the failure first, rerun the focal workflow, then the full regression matrix.
