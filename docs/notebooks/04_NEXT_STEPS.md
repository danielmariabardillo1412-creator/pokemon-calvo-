# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- PR #63 — `fix/data-v3-always-hit-accuracy`
- Final HEAD `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #64
- Branch `fix/data-v3-selected-special-stat-packages-a`
- Parent `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- Engineering SHA before notebook sync: `3c9c83d3ff99c0e9a98506343db4e28b6de65af2`
- Engineering SHA CI: **18/18 SUCCESS**
- DATA V3 independently verified Decorate and Spicy Extract target, accuracy=-1, classification and exact OPPONENT stat packages.
- Notebook synchronization moves branch tip. Require **18/18 on the final exact notebook-bearing HEAD**, then close #64 without merge.

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## What #64 certifies
`Decorate`:
- selected-pokemon
- always-hit canonical accuracy -1
- Attack +2 / SpAtk +2 on target
- no additional current battle mechanic in audited source
- promoted to RUNTIME_SUPPORTED without effect rewrite.

`Spicy Extract`:
- selected-pokemon
- always-hit canonical accuracy -1
- Attack +2 / Defense -2 on target
- current Scarlet/Violet semantics fully match generated package
- promoted to RUNTIME_SUPPORTED without effect rewrite.

Exact #63→#64 artifact comparison:
- only `decorate` and `spicy_extract` changed
- only `classification` changed on those two
- accuracy unchanged
- effect_specs unchanged
- no unrelated move changed.

## Exact #64 engineering artifact
- `RUNTIME_SUPPORTED`: **584**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **256**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **30**
  - 27 stat-change
  - Beat Up
  - Purify
  - Swallow

Remaining stat target distribution:
- 13 user
- 8 all-opponents
- 4 selected-pokemon
- 2 all-pokemon

## Exact next task after #64 closure
Finish the selected-pokemon family by auditing these **four only**:
1. `Defog`
2. `Memento`
3. `Parting Shot`
4. `Tar Shot`

Recommended approach: inspect source + exact generated record for all four first, then decide whether any can share a safe tranche. Do not infer coverage from their visible stat changes alone.

Known/suspected missing semantics to verify:
- Defog — Evasion drop plus field/hazard/screen/terrain cleanup.
- Memento — Attack/SpAtk drops plus user faint.
- Parting Shot — Attack/SpAtk drops plus user switch.
- Tar Shot — Speed drop plus Fire-damage vulnerability/state.

For each, choose:
- `RUNTIME_SUPPORTED` only if full current singles semantics are representable;
- `PARTIAL_RUNTIME` only if the executing subset is itself faithful and not strategically misleading;
- `DATA_ONLY`/effect-free if the current generated subset would create materially false behavior.

Then continue with either the 8 all-opponents cases or small groups from the 13 user/stateful cases, depending on source homogeneity.

## Remaining user conditional/stateful
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.

## Remaining all-opponents
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.

## Remaining all-pokemon
`flower_shield`, `rototiller`.

## Remaining non-stat with specs
`Purify`, `Swallow`, `Beat Up`.

## Stop condition
If any focal or regression test fails, stop immediately, diagnose/fix root cause, rerun focal, then full matrix. Never accumulate failures.
