# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- PR #65 — `fix/data-v3-selected-special-stateful-b`
- Final HEAD `b13af37c350156bc7a9a7d7faf63742245afd801`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #66
- Branch `fix/data-v3-all-opponents-stat-audit`
- Parent `b13af37c350156bc7a9a7d7faf63742245afd801`
- Engineering SHA before notebook sync: `4773a8ce33854f987f2cc09bb4f14ef5db678d0b`
- Engineering SHA CI: **18/18 SUCCESS**
- Artifact comparison changed exactly 8 move records and no unrelated moves.
- Notebook synchronization moves branch tip. Require **18/18 on the final exact notebook-bearing HEAD**, then close #66 without merge.

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## What #66 resolves
The entire remaining `all-opponents` DATA_ONLY-with-specs family is resolved.

RUNTIME_SUPPORTED in current singles:
- `growl`: OPPONENT Attack -1, accuracy 100.
- `leer`: OPPONENT Defense -1, accuracy 100.
- `string_shot`: OPPONENT Speed -2, accuracy 95.
- `sweet_scent`: OPPONENT Evasion -2, accuracy 100.
- `tail_whip`: OPPONENT Defense -1, accuracy 100.

Neutralized as DATA_ONLY with `effect_specs=[]`:
- `captivate`: opposite-gender prerequisite unsupported.
- `venom_drench`: poisoned-target prerequisite unsupported.
- `cotton_spore`: powder/spore target predicate includes intrinsic Grass-type immunity; unconditional effect would be false.

Sweet Scent source inconsistency repaired canonically:
- structured snapshot/current mechanics = Evasion -2;
- stale generic source prose said -1;
- immutable source stays untouched;
- loaded in-memory English prose is normalized before `effect_summary` is built.

## Exact #66 engineering artifact
- `RUNTIME_SUPPORTED`: **589**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **250**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **18**
  - 15 stat-change
  - Beat Up
  - Purify
  - Swallow

Exact #65→#66 comparison:
- only 8 move records changed;
- Captivate/Cotton Spore/Venom Drench: only specs removed;
- Growl/Leer/String Shot/Tail Whip: only classification changed;
- Sweet Scent: classification + canonical summary correction;
- no unrelated move changed.

## Exact next task after #66 closure
Audit the **13 `user` conditional/stateful stat moves**. Do not mass-promote them.

List:
1. `autotomize`
2. `charge`
3. `clangorous_soul`
4. `defense_curl`
5. `extreme_evoboost`
6. `fillet_away`
7. `geomancy`
8. `growth`
9. `minimize`
10. `no_retreat`
11. `shell_smash`
12. `stockpile`
13. `tidy_up`

Recommended split before editing:
- **HP cost/prerequisite:** Clangorous Soul, Fillet Away.
- **two-turn/delayed:** Geomancy.
- **weather-dependent magnitude:** Growth.
- **stored counter/state:** Stockpile.
- **persistent flags/special interactions:** Autotomize, Charge, Defense Curl, Minimize, No Retreat, Tidy Up.
- **multi-stat packages to verify for completeness:** Shell Smash, Extreme Evoboost.

For each move inspect immutable source + current public mechanics + exact generated specs. A stat package may be true but still unsafe if a missing cost/prerequisite/state transaction materially changes the move.

After the 13 user moves:
- `flower_shield`, `rototiller` (`all-pokemon`/type predicates).
- `Purify`, `Swallow`, `Beat Up` (non-stat remaining specs).

## Safety rule
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. If a generated spec is known false or unsafe, remove/correct it before proceeding.

## Certification sequence
1. immutable source + public mechanic audit;
2. exact generated record inspection;
3. narrow implementation + fail-fast contracts;
4. independent regenerated-output tests;
5. DATA V3 focal;
6. 18/18 engineering SHA;
7. artifact diff/counts;
8. notebooks;
9. 18/18 exact final HEAD;
10. close PR without merge.

## Stop condition
If any focal or regression test fails, stop immediately, diagnose/fix root cause, rerun focal, then full matrix. Never accumulate failures.
