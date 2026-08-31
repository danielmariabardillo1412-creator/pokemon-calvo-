# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- PR #61 — `fix/data-v3-simple-self-stat-packages-a`
- Final HEAD `623930ca0b98b00099288bcf542e7e0a922ac180`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #62
- Branch `fix/data-v3-simple-opponent-stat-drops-a`
- Parent `623930ca0b98b00099288bcf542e7e0a922ac180`
- Engineering SHA before notebook sync: `e384cb3a5b19a158e11da4925e7c2c23c929d9ca`
- Engineering SHA CI: **18/18 SUCCESS**
- DATA V3 independently verified all 17 regenerated opponent stat packages.
- Notebook synchronization moves branch tip. Require **18/18 on the final exact notebook-bearing HEAD**, then close #62 without merge.

## Workstream
**Move Effects V3 semantic audit. Do not switch to trainer AI/archetypes.**

## Exact #62 engineering artifact
- `RUNTIME_SUPPORTED`: **582**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **258**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **32**
  - 29 stat-change
  - Beat Up
  - Purify
  - Swallow

Remaining 29 stat-change targets:
- 13 user
- 8 all-opponents
- 6 selected-pokemon
- 2 all-pokemon

## What #62 certified
17 simple selected-target debuffs are now `RUNTIME_SUPPORTED` with exact OPPONENT packages:
Baby-Doll Eyes, Charm, Confide, Eerie Impulse, Fake Tears, Feather Dance, Flash, Kinesis, Metal Sound, Noble Roar, Play Nice, Sand Attack, Scary Face, Screech, Smokescreen, Tearful Look, Tickle.

No effect rewrites were needed; the legacy generator already produced correct effects. The adapter now fail-fast verifies exact source metadata/package and exact generated output before promotion.

## Exact next task after #62 closure
Finish the `selected-pokemon` family by auditing the **six special cases only**:
- `decorate`
- `defog`
- `memento`
- `parting_shot`
- `spicy_extract`
- `tar_shot`

Do not batch them blindly.

Recommended order:
1. Verify `Decorate` and `Spicy Extract` from immutable source first. They may be fully representable stat packages in the current single-opponent model, but target/mixed-sign semantics must be proved.
2. Audit `Defog`, `Memento`, `Parting Shot`, `Tar Shot` separately because each is known/suspected to include an additional mechanic beyond visible stat changes.
3. For each special move decide among:
   - `RUNTIME_SUPPORTED` if full current battle semantics are representable,
   - `PARTIAL_RUNTIME` if a faithful subset executes,
   - `DATA_ONLY`/effect-free if current generated effects would be misleading.
4. Add exact source assertions + independent output tests.
5. Focal DATA V3 → 18/18 engineering → artifact → notebooks → 18/18 final → close without merge.

After the six selected specials are resolved, choose between the 8 all-opponents family and the 13 stateful user moves based on which can be safely regrouped. Do not mass-promote the 13 user cases.

## Known remaining families
User conditional/stateful:
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.

All-opponents:
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.

All-pokemon:
`flower_shield`, `rototiller`.

Non-stat:
`Purify`, `Swallow`, `Beat Up`.

## Stop condition
If any focal or regression test fails, stop immediately, diagnose/fix root cause, rerun focal, then full matrix. Never accumulate failures.
