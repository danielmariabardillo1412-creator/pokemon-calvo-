# NEXT STEPS — LIVE CHECKPOINT

This file is intentionally short and should be updated frequently. A fresh context should read this immediately after `00_READ_FIRST.md`.

## Current certification chain

Previous certified tranche:

- Branch: `fix/data-v3-stuff-cheeks-semantics`
- Final HEAD: `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`
- PR #56: closed without merge.
- CI: 18/18 SUCCESS on that exact notebook-bearing HEAD.

Current tranche:

- Branch: `fix/data-v3-howl-target-semantics`
- PR #57.
- Parent: `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`.
- Engineering SHA before notebook synchronization: `fc118cb3a06d3f1724b65aac5ba5c8893d0ea83b`.
- Engineering SHA CI: 18/18 SUCCESS, including the independent regenerated-dataset assertion for Howl.
- Notebook synchronization intentionally moves the branch tip. **Before continuing to another tranche, require 18/18 workflows on the final exact notebook-bearing HEAD and then close PR #57 without merge.** GitHub is authoritative for that final SHA.

## Current workstream

**Move Effects V3 semantic audit.**

Do not switch to trainer AI/archetypes yet.

## Latest exact artifact metrics

From PR #57 engineering SHA `fc118cb3a06d3f1724b65aac5ba5c8893d0ea83b`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 67
- `DATA_ONLY`: 285
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: 62.

The previous 60 stat-change DATA_ONLY records drop to 59 because Howl is now honestly `PARTIAL_RUNTIME`; `Purify`, `Swallow`, and `Beat Up` remain separate unaudited cases.

## Tranche just completed in PR #57

Modern `Howl` had an actively wrong generated target:

`OPPONENT Attack +1`

The immutable snapshot has `target=user-and-allies`. Sword/Shield and Scarlet/Violet flavor text explicitly state that Howl raises the Attack of the user and its allies. The legacy converter failed to recognize `user-and-allies` as a self-side target and therefore mapped the stat change to OPPONENT.

Therefore:

- Source target `user-and-allies` is preserved.
- The executable subset is now exactly `SELF Attack +1`.
- `Howl` is `PARTIAL_RUNTIME`, because the user subset is faithful but ally boosting is still unimplemented.
- The false opponent buff is removed.
- A DATA V3 domain test independently verifies target, classification, stat, value, chance, and SELF runtime target.

## Exact next technical task

After final exact-head certification and closure of PR #57, continue the remaining high-risk `user-and-allies` stat moves **one at a time** before returning to ordinary stat families.

Known remaining records from the PR #56 artifact:

- `Coaching`: generic output buffs OPPONENT; real semantics involve an adjacent ally and failure when no suitable ally exists.
- `Gear Up`: generic output buffs OPPONENT; real semantics apply to friendly Pokémon with Plus/Minus.
- `Magnetic Flux`: generic output buffs OPPONENT; real semantics apply to friendly Pokémon with Plus/Minus.

Do **not** apply the Howl rewrite generically to those three. Their prerequisites/recipient sets are different and may require `DATA_ONLY` effect-free handling rather than a SELF partial subset.

Recommended sequence:

1. Confirm PR #57 final exact HEAD is 18/18 green and close without merge.
2. Start the next branch from that exact SHA.
3. Inspect the immutable source and exact generated record for one of `Coaching`, `Gear Up`, or `Magnetic Flux`.
4. Decide representable subset only after checking prerequisites and whether SELF is actually a legal recipient.
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
- `Autotomize`, `Charge`, `Defense Curl`, `Minimize`: extra mechanics beyond their visible stat boost.
- `Stuff Cheeks`: safely `DATA_ONLY`/effect-free until held-Berry prerequisite + consumption semantics exist.
- `Silk Trap`: safely `DATA_ONLY`/effect-free until protection + contact-response mechanics exist.
- `Aromatic Mist`: safely `DATA_ONLY`/effect-free until ally targeting exists.
- `Howl`: now `PARTIAL_RUNTIME`; SELF subset is correct, ally subset remains missing.
- `Purify`, `Swallow`, `Beat Up`: not yet audited; handle separately.

## Stop condition

If any focal or regression test fails, **do not move to another family**. Diagnose and fix the failure first, rerun the focal workflow, then the full regression matrix.
