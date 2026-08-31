# NEXT STEPS — LIVE CHECKPOINT

This file is intentionally short and should be updated frequently. A fresh context should read this immediately after `00_READ_FIRST.md`.

## Current certification chain

Persistent notebook baseline:

- Branch: `docs/project-notebooks-v1`
- HEAD: `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`
- PR #52: closed without merge.
- CI: 18/18 SUCCESS on that exact HEAD.

Current tranche:

- Branch: `fix/data-v3-simple-self-stat-boosts-c`
- PR #53.
- Parent: `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`.
- Engineering SHA before notebook synchronization: `4d6f0dbf205ffd41fdbbfae490e8efaedea54d3f`.
- Engineering SHA CI: 18/18 SUCCESS.
- Notebook synchronization intentionally moves the branch tip. **Before continuing to another tranche, confirm PR #53 is closed without merge and that all 18 workflows passed on its final exact head SHA.** Use GitHub as authority for that final SHA.

## Current workstream

**Move Effects V3 semantic audit.**

Do not switch to trainer AI/archetypes yet.

## Latest exact artifact metrics

From PR #53 engineering SHA `4d6f0dbf205ffd41fdbbfae490e8efaedea54d3f`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 66
- `DATA_ONLY`: 286
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: 66.

- 63 stat-change cases.
- 2 heal cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

## Tranche just completed in PR #53

Promoted through the already-certified pure-self-stat-boost contract:

- `Cotton Guard`: Defense +3
- `Double Team`: Evasion +1
- `Withdraw`: Defense +1

Do not fold superficially similar moves into this family without separate audits. Known exclusions already identified: `Autotomize`, `Charge`, `Defense Curl`, `Minimize`, `Stuff Cheeks`, `Aromatic Mist`, `Silk Trap`.

## Exact next technical task

After final exact-head certification and closure of PR #53, continue the remaining 63 stat-change `DATA_ONLY` moves by **small semantic family**.

Recommended next selection strategy:

1. Obtain/use the exact DATA V3 artifact from the final certified PR #53 head (or its engineering artifact if the final head only changes notebooks; verify data code is identical).
2. Separate stat-change candidates by generated effect count/target/stat pattern.
3. Verify immutable PokéAPI source semantics for every candidate before changing coverage.
4. Prefer another small clean family, or deliberately audit one suspicious case if it can expose a systematic bug.
5. In particular, consider auditing `Silk Trap` separately soon: its generic output currently resembles a self Speed drop even though its real mechanic is protection plus a contact-triggered Speed drop on the attacker. Treat this as suspicious until source/runtime analysis proves the correct representation.
6. Confirm Battle Core can faithfully execute every represented subset.
7. Add fail-fast adapter contracts and appropriate CI protection.
8. Open the next small PR against the final certified PR #53 branch/head chain.
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
- `Aromatic Mist`: ally targeting is outside the current effect-target contract.
- `Silk Trap`: dedicated audit required; current generic stat effect is suspicious.
- `Purify`, `Swallow`, `Beat Up`: not yet audited; handle separately.

## Stop condition

If any focal or regression test fails, **do not move to another family**. Diagnose and fix the failure first, rerun the focal workflow, then the full regression matrix.
