# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
DATA V3 structural correctness is not enough: every executable `effect_spec` and every battle-relevant move field must be semantically faithful. If Battle Core cannot represent a mechanic, preserve only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Coverage labels do not gate execution.

## Canonical source
- immutable `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- `data/api/v2` + `data/schema/v2`
- move-effect compatibility corrections in `tools/pokeapi_adapter.py`
- source-selection/canonical-field conversion in `tools/pokeapi_adapter_v3.py`
- archived V2 is provenance-only and must remain untouched.

## Recent certified heads
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- #61 pure SELF stat packages A — `623930ca0b98b00099288bcf542e7e0a922ac180`
- #62 pure opponent stat drops A — `6d1335b8c5cee0b1cf1e99910a7707734b4aef85`
- #63 always-hit accuracy semantics — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
All: 18/18 and closed without merge.

## Certified transversal accuracy contract from #63
- numeric PokéAPI accuracy is preserved;
- source `accuracy=null` becomes canonical `-1`;
- `MoveDefinition` preserves `-1`;
- `BattleRuleset` treats negative base accuracy as always-hit (10000 bp), while a genuine 100 remains Accuracy/Evasion-stage-sensitive.

# PR #64 — selected special stat packages A (CURRENT)
Branch `fix/data-v3-selected-special-stat-packages-a`.
Parent: certified #63 final `9f8b3e01bec1f86cff75380d68dd98d76e738e78`.
Engineering SHA before notebook sync: `3c9c83d3ff99c0e9a98506343db4e28b6de65af2`.
Engineering SHA: **18/18 SUCCESS**.

## Decorate
Immutable source (`move/777`):
- target `selected-pokemon`
- `accuracy=null` → canonical `-1`
- status move, priority 0
- Attack +2
- Special Attack +2
- `effect_changes=[]`
- meta category `net-good-stats`, ailment none, `stat_chance=100`
- no healing/drain/flinch/ailment chance
- English effect text states target Attack and Special Attack +2 stages.

Legacy/generated output after #63:
- `OPPONENT Attack +2`, 10000 bp
- `OPPONENT Special Attack +2`, 10000 bp
- `accuracy=-1`

This is the complete battle effect in the current singles model. #64 validates source/output fail-fast and promotes to `RUNTIME_SUPPORTED` without rewriting effects.

## Spicy Extract
Immutable source (`move/858`):
- target `selected-pokemon`
- `accuracy=null` → canonical `-1`
- status move, priority 0
- Attack +2
- Defense -2
- `effect_changes=[]`
- snapshot `meta=null`, `effect_entries=[]`
- current Scarlet/Violet English flavor text explicitly says target Attack sharply rises and target Defense harshly falls.

Legacy/generated output after #63:
- `OPPONENT Attack +2`, 10000 bp
- `OPPONENT Defense -2`, 10000 bp
- `accuracy=-1`

This is the complete current singles battle effect. #64 validates source/output fail-fast and promotes to `RUNTIME_SUPPORTED` without rewriting effects.

## Independent #64 output tests
For both moves, regenerated raw data must have:
- target `selected-pokemon`
- accuracy `-1`
- classification `RUNTIME_SUPPORTED`
- exactly two effects
- each effect is `modify_stat_stage`, target `opponent`, 10000 bp
- exact expected stat dictionary.

## Exact #64 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **584**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **256**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **30**.
- 27 stat-change
- `Beat Up`, `Purify`, `Swallow`

Exact #63→#64 raw comparison:
- only two moves changed: `decorate`, `spicy_extract`
- each changed only `classification: DATA_ONLY → RUNTIME_SUPPORTED`
- accuracy unchanged (`-1`)
- effect specs unchanged
- no unrelated record changed.

Notebook synchronization moves the SHA. #64 requires a second exact-head 18/18 before closure without merge.

## Remaining selected-pokemon special family — four only
- `defog`
- `memento`
- `parting_shot`
- `tar_shot`

Do not batch/promote blindly:
- Defog: visible Evasion drop plus field/hazard/screen/terrain cleanup semantics.
- Memento: target Attack/SpAtk drops plus user faint.
- Parting Shot: target Attack/SpAtk drops plus user switch.
- Tar Shot: target Speed drop plus Fire-damage vulnerability/state interaction.

Each needs immutable-source inspection, exact current generated output, and a decision between faithful partial subset versus effect-free DATA_ONLY if the missing mechanic makes the executable subset strategically misleading.

## Other remaining families
### User — 13 conditional/stateful
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote.

### All-opponents — 8
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.
Conditions such as gender/poisoned-only must be preserved.

### All-pokemon — 2
`flower_shield`, `rototiller`; current singles SELF/OPPONENT model cannot directly express all-Pokémon/type predicates.

### Non-stat — 3
`Purify`, `Swallow`, `Beat Up` require separate semantic audits.

## Audit protocol
1. Inspect immutable source.
2. Inspect exact generated artifact.
3. Determine all battle-relevant fields, not only `effect_specs`.
4. Determine representable semantics in current Battle Core.
5. Choose coverage from semantics, not convenience.
6. Add exact fail-fast source/generated contract.
7. Add independent regenerated-output/runtime assertion.
8. Batch only genuinely homogeneous contracts.
9. DATA V3 focal.
10. 18/18 engineering SHA.
11. Measure artifact and compare changed fields.
12. Sync notebooks.
13. 18/18 final HEAD.
14. Close without merge.

Stop on any failure; fix root cause before another family.
