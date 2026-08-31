# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
DATA V3 structural correctness is not enough: every executable `effect_spec` and every battle-relevant move field must be semantically faithful. If Battle Core cannot represent a mechanic, preserve only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Coverage labels do not gate execution.

A retained effect can be individually true yet still unsafe if an omitted mechanic is a mandatory cost, transaction, prerequisite, target predicate, or strategic drawback. In those cases prefer effect-free `DATA_ONLY`.

## Canonical source
- immutable `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- `data/api/v2` + `data/schema/v2`
- compatibility corrections: `tools/pokeapi_adapter.py`
- source-selection/canonical conversion: `tools/pokeapi_adapter_v3.py`
- selected-stateful audit: `tools/pokeapi_adapter_selected_stateful.py`
- all-opponents audit: `tools/pokeapi_adapter_all_opponents.py`
- archived V2 is provenance-only and must remain untouched.

## Certified recent heads
- #63 always-hit accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
All certified 18/18 on exact notebook-bearing HEAD and closed without merge.

## Accuracy contract
- numeric PokéAPI accuracy is preserved;
- source `accuracy=null` becomes canonical `-1`;
- `MoveDefinition` preserves `-1`;
- `BattleRuleset` treats negative base accuracy as always-hit, while genuine 100 remains Accuracy/Evasion-stage-sensitive.

# PR #66 — all-opponents stat semantics (CURRENT)
Branch `fix/data-v3-all-opponents-stat-audit`.
Parent: certified #65 final `b13af37c350156bc7a9a7d7faf63742245afd801`.
Engineering SHA before notebook sync: `4773a8ce33854f987f2cc09bb4f14ef5db678d0b`.
Engineering SHA: **18/18 SUCCESS**.

The eight remaining `all-opponents` DATA_ONLY-with-specs stat moves were checked against the immutable snapshot and current public core-series mechanics before runtime exposure changed.

## Fully representable base effects in current singles
Because current battle is singles, `all-opponents` has exactly one opposing active target and can collapse to `OPPONENT` for these unconditional base effects:

### Growl
- target `all-opponents`
- accuracy 100
- Attack -1
- no move-intrinsic prerequisite in the source effect contract
- decision: `RUNTIME_SUPPORTED`.

Soundproof is an ability interaction and remains for the ability interaction audit, consistent with previously certified sound moves.

### Leer
- target `all-opponents`
- accuracy 100
- Defense -1
- decision: `RUNTIME_SUPPORTED`.

### String Shot
- target `all-opponents`
- accuracy 95
- modern Speed -2
- decision: `RUNTIME_SUPPORTED`.

### Sweet Scent
- target `all-opponents`
- accuracy 100
- structured snapshot `stat_changes`: Evasion -2
- current mechanics: Evasion -2 since Generation VI
- decision: `RUNTIME_SUPPORTED`.

Snapshot inconsistency discovered: generic `effect_entries` prose still described Evasion -1. #66 keeps immutable JSON untouched and normalizes only loaded in-memory English prose so canonical `effect_summary` matches the structured/current -2 mechanic.

### Tail Whip
- target `all-opponents`
- accuracy 100
- Defense -1
- decision: `RUNTIME_SUPPORTED`.

## Conditional/unsafe all-opponents effects neutralized
### Captivate
Source states Special Attack -2 only for opposite gender; same gender or genderless cases fail. Current effect model has no gender predicate. An unconditional -2 is false.
Decision: `DATA_ONLY`, `effect_specs=[]`.

### Venom Drench
Source states Attack/SpAtk/Speed -1 only if the target is poisoned. Current effect model cannot predicate stat effects on existing poison state. Unconditional -1/-1/-1 is false.
Decision: `DATA_ONLY`, `effect_specs=[]`.

### Cotton Spore
Source base package is Speed -2, but modern powder/spore rules intrinsically exclude Grass-type targets, in addition to ability/item interactions. Current effect model lacks the move-class/type predicate. Even before ability/item audit, an unconditional Speed -2 against Grass is false.
Decision: `DATA_ONLY`, `effect_specs=[]`.

## Independent #66 output tests
Regenerated raw data must verify:
- Growl: RUNTIME_SUPPORTED, accuracy 100, exact OPPONENT Attack -1.
- Leer: RUNTIME_SUPPORTED, accuracy 100, exact OPPONENT Defense -1.
- String Shot: RUNTIME_SUPPORTED, accuracy 95, exact OPPONENT Speed -2.
- Sweet Scent: RUNTIME_SUPPORTED, accuracy 100, exact OPPONENT Evasion -2, summary no longer says one stage.
- Tail Whip: RUNTIME_SUPPORTED, accuracy 100, exact OPPONENT Defense -1.
- Captivate/Cotton Spore/Venom Drench: DATA_ONLY with empty specs.

## Exact #66 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **589**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **250**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **18**.
- 15 stat-change
- `Beat Up`, `Purify`, `Swallow`.

Exact #65→#66 raw comparison:
- exactly eight move records changed;
- Captivate/Cotton Spore/Venom Drench: `effect_specs` only → empty;
- Growl/Leer/String Shot/Tail Whip: `classification` only → RUNTIME_SUPPORTED;
- Sweet Scent: `classification` plus stale canonical `effect_summary` correction; target, accuracy and effect specs unchanged;
- no unrelated record changed.

Notebook synchronization moves the SHA. #66 requires a second exact-head 18/18 before closure without merge.

# Audit frontier after #66
`selected-pokemon` and `all-opponents` DATA_ONLY-with-specs families are complete.

## User — 13 conditional/stateful
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.

Do not mass-promote. Likely dimensions to inspect:
- HP cost/prerequisite: Clangorous Soul, Fillet Away;
- delayed/two-turn execution: Geomancy;
- weather-dependent stat magnitude: Growth;
- stored counters/state: Stockpile;
- secondary persistent flags/interactions: Charge, Defense Curl, Minimize, Autotomize;
- switching restrictions/state: No Retreat;
- cleanup/field side effects: Tidy Up;
- multi-stat packages that may otherwise be representable: Shell Smash, Extreme Evoboost.

## All-pokemon — 2
`flower_shield`, `rototiller`.
Both require all-Pokémon/type predicates not directly representable with SELF/OPPONENT-only targeting.

## Non-stat — 3
`Purify`, `Swallow`, `Beat Up` require separate semantic audits.

## Audit protocol
1. Inspect immutable source.
2. Cross-check public mechanics when source text is incomplete/version-ambiguous.
3. Inspect exact generated artifact.
4. Identify all battle-relevant mechanics, costs, predicates and state changes.
5. Choose coverage from semantics, not convenience.
6. Add fail-fast source/generated contract.
7. Add independent regenerated-output/runtime assertion.
8. Batch only genuinely homogeneous contracts.
9. DATA V3 focal.
10. 18/18 engineering SHA.
11. Measure artifact and compare changed fields.
12. Sync notebooks.
13. 18/18 final HEAD.
14. Close without merge.

Stop on any failure; fix root cause before another family.
