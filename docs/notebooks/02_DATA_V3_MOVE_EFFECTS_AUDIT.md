# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
DATA V3 structural correctness is not enough: every executable `effect_spec` must be semantically faithful. If Battle Core cannot represent a mechanic, preserve only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Coverage labels do not gate execution.

## Canonical source
- immutable `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- `data/api/v2` + `data/schema/v2`
- current semantic corrections in `tools/pokeapi_adapter.py`
- archived V2 is provenance-only and must remain untouched.

## Certified history summary
Move Effects V3 has already certified healing targets/self heals/weather heals/Roost/Rest/Wish/Strength Sap, simple SELF stat boosts, and false-target/resource cases including Silk Trap, Aromatic Mist, Stuff Cheeks, Howl, Coaching, Gear Up and Magnetic Flux.

Recent exact certified heads:
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- #61 pure SELF stat packages A — `623930ca0b98b00099288bcf542e7e0a922ac180`
Both 18/18 and closed without merge.

## PR #62 — pure opponent stat drops A (CURRENT)
Branch `fix/data-v3-simple-opponent-stat-drops-a`.
Parent: certified #61 final `623930ca0b98b00099288bcf542e7e0a922ac180`.
Engineering SHA before notebook sync: `e384cb3a5b19a158e11da4925e7c2c23c929d9ca`.
Engineering SHA: **18/18 SUCCESS**.

### Source-audited family
The following 17 moves were inspected against immutable source before batching. Their current battle contract is exactly an unconditional selected-target stat package; no ailment/heal/drain/flinch/effect-history/switch/faint/field/type/resource mechanic was present in the audited source contract:

- Baby-Doll Eyes: Attack -1
- Charm: Attack -2
- Confide: SpAtk -1
- Eerie Impulse: SpAtk -2
- Fake Tears: SpDef -2
- Feather Dance: Attack -2
- Flash: Accuracy -1
- Kinesis: Accuracy -1
- Metal Sound: SpDef -2
- Noble Roar: Attack -1 / SpAtk -1
- Play Nice: Attack -1
- Sand Attack: Accuracy -1
- Scary Face: Speed -2
- Screech: Defense -2
- Smokescreen: Accuracy -1
- Tearful Look: Attack -1 / SpAtk -1
- Tickle: Attack -1 / Defense -1

Important metadata detail: PokéAPI uses `stat_chance=100` for Confide, Play Nice, Noble Roar and Tearful Look, while the other members use `0`. The adapter records the exact expected source value per move rather than pretending the family has one common metadata value.

### Adapter contract
`_PURE_OPPONENT_STAT_PACKAGES` stores the exact package + exact source stat chance for the 17 names only.
`_require_pure_opponent_stat_package` fail-fast checks:
- source target `selected-pokemon`
- status damage class
- `net-good-stats`, ailment none
- exact source `stat_chance`
- `effect_changes=[]`
- no healing/drain/flinch/ailment chance
- exact source stat dictionary
- exact generated effect count
- every generated effect is `modify_stat_stage`, target `opponent`, 10000 bp
- exact generated stat dictionary

The legacy generator already emitted correct effects; no effect rewrite occurs. Coverage changes to `RUNTIME_SUPPORTED` only after all checks pass.

Independent Godot DATA V3 tests loop all 17 regenerated records and verify target, classification, effect count, OPPONENT shape and exact package.

### Exact engineering artifact
- `RUNTIME_SUPPORTED`: **582**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **258**
- `UNSUPPORTED`: **12**
- DATA_ONLY with specs: **32**
- remaining stat-change DATA_ONLY: **29**
- non-stat with specs: `Beat Up`, `Purify`, `Swallow`

Remaining stat targets:
- 13 user
- 8 all-opponents
- 6 selected-pokemon
- 2 all-pokemon

Notebook sync moves the SHA. #62 must pass a second exact-head 18/18 before closure without merge.

## Remaining selected-pokemon special cases
Only these six remain:
- `decorate`
- `defog`
- `memento`
- `parting_shot`
- `spicy_extract`
- `tar_shot`

They were intentionally excluded from #62 because their semantics are not the simple drop family. Audit separately/small groups. Useful hypotheses to verify, not assumptions:
- Decorate: positive stat package on selected target; target flexibility may matter.
- Spicy Extract: mixed positive/negative stat package may be fully representable.
- Defog: stat drop plus field/hazard/screen cleanup.
- Memento: stat drops plus user faint.
- Parting Shot: stat drops plus forced user switch.
- Tar Shot: Speed drop plus Fire-damage/type-state interaction.

## Other remaining families
### User — 13 conditional/stateful
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote.

### All-opponents — 8
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.
Conditions such as gender or poisoned-only must be preserved.

### All-pokemon — 2
`flower_shield`, `rototiller`; current single-opponent target model likely cannot represent all-Pokémon/type predicates fully.

### Non-stat — 3
`Purify`, `Swallow`, `Beat Up` require separate semantic audits.

## Audit protocol
1. Inspect immutable source.
2. Inspect exact generated artifact.
3. Determine representable semantics in current Battle Core.
4. Choose coverage from semantics, not convenience.
5. Add exact fail-fast adapter contract.
6. Add independent regenerated-output assertion.
7. Batch only genuinely homogeneous source contracts.
8. DATA V3 focal.
9. 18/18 engineering SHA.
10. Measure artifact.
11. Sync notebooks.
12. 18/18 final HEAD.
13. Close without merge.

Stop on any failure; fix root cause before another family.
