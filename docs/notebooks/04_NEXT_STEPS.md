# NEXT STEPS — LIVE CHECKPOINT

This file is intentionally short and should be updated frequently. A fresh context should read this immediately after `00_READ_FIRST.md`.

## Current certification chain

Previous certified tranche:

- Branch: `fix/data-v3-simple-self-stat-boosts-c`
- HEAD: `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`
- PR #53: closed without merge.
- CI: 18/18 SUCCESS on that exact notebook-bearing HEAD.

Current tranche:

- Branch: `fix/data-v3-silk-trap-semantics`
- PR #54.
- Parent: `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`.
- Engineering SHA before notebook synchronization: `0bf50ab5e6eb17d4b8d768d38fa274b97387741b`.
- Engineering SHA CI: 18/18 SUCCESS, including the new independent Silk Trap dataset assertion.
- Notebook synchronization intentionally moves the branch tip. **Before continuing to another tranche, confirm PR #54 is closed without merge and all 18 workflows passed on its final exact head SHA.** Use GitHub as authority for that final SHA.

## Current workstream

**Move Effects V3 semantic audit.**

Do not switch to trainer AI/archetypes yet.

## Latest exact artifact metrics

From PR #54 engineering SHA `0bf50ab5e6eb17d4b8d768d38fa274b97387741b`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 66
- `DATA_ONLY`: 286
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: 65.

- 62 stat-change cases.
- 2 heal cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

## Tranche just completed in PR #54

`Silk Trap` had an incorrect generated runtime effect:

`SELF Speed -1`

The immutable source actually describes a protection move whose Speed -1 applies only to an attacker that makes direct contact. Current Battle Core cannot model protection + contact-trigger + attacker targeting faithfully.

Therefore:

- `Silk Trap` remains `DATA_ONLY`.
- `effect_specs` is now deliberately empty.
- The false self-debuff is removed.
- A DATA V3 domain test independently verifies the regenerated JSON stays effect-free.

## Exact next technical task

After final exact-head certification and closure of PR #54, continue the remaining 62 stat-change `DATA_ONLY` moves by **small semantic family**.

Recommended next selection strategy:

1. Use the exact DATA V3 artifact from PR #54 engineering/final head.
2. Group remaining stat-change cases by target and number/type of generated effects.
3. Prioritize cases where target semantics can create false runtime behavior, as happened with Silk Trap.
4. `Aromatic Mist` is a useful next candidate: source target is an ally while the current generic output uses SELF Special Defense +1. Audit it separately before any mass treatment of ally-targeted stat moves.
5. Otherwise pick another small pure family only after immutable-source verification.
6. Confirm Battle Core can faithfully execute every represented subset.
7. Add fail-fast adapter contracts and independent output protection when correcting effect shape/target.
8. Open the next small PR against the final certified PR #54 branch/head chain.
9. Require focal DATA V3 success and then 18/18 workflows on the exact engineering HEAD.
10. Synchronize notebooks, then require 18/18 again on the final notebook-bearing HEAD before closure.
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
- `Aromatic Mist`: ally target; current generic SELF effect is suspicious and must be audited separately.
- `Silk Trap`: now safely DATA_ONLY/effect-free until protection/contact-response mechanics exist.
- `Purify`, `Swallow`, `Beat Up`: not yet audited; handle separately.

## Stop condition

If any focal or regression test fails, **do not move to another family**. Diagnose and fix the failure first, rerun the focal workflow, then the full regression matrix.
