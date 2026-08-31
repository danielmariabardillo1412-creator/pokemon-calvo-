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

## Certified history summary
Move Effects V3 has already certified healing targets/self heals/weather heals/Roost/Rest/Wish/Strength Sap, simple SELF stat boosts, false-target/resource cases including Silk Trap, Aromatic Mist, Stuff Cheeks, Howl, Coaching, Gear Up and Magnetic Flux, and the simple selected-target opponent stat-drop family.

Recent exact certified heads:
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- #61 pure SELF stat packages A — `623930ca0b98b00099288bcf542e7e0a922ac180`
- #62 pure opponent stat drops A — `6d1335b8c5cee0b1cf1e99910a7707734b4aef85`
All: 18/18 and closed without merge.

## PR #63 — always-hit accuracy semantics (CURRENT)
Branch `fix/data-v3-always-hit-accuracy`.
Parent: certified #62 final `6d1335b8c5cee0b1cf1e99910a7707734b4aef85`.
Engineering SHA before notebook sync: `428e1f2e387301899d749a9b97127f9e1a0a5b45`.
Engineering SHA: **18/18 SUCCESS**.

### Root cause
During the special-move audit of `Decorate` and `Spicy Extract`, both immutable source records were found to use PokéAPI `accuracy=null`. Their generated records used canonical `accuracy=100`.

That mapping was unsafe because the runtime contract is explicit:
- `TurnExecutor` passes `move.accuracy` directly to `BattleRuleset.accuracy_threshold_basis_points()`.
- `BattleRuleset` treats `base_accuracy < 0` as always-hit and returns 10000 bp immediately.
- `base_accuracy=100` remains subject to Accuracy/Evasion stage multipliers.

Therefore `null → 100` could make moves that should bypass accuracy checks miss when stages were unfavorable.

### Fix
In `tools/pokeapi_adapter_v3.py` only:
- numeric PokéAPI accuracy remains unchanged;
- PokéAPI `accuracy=null` now maps to canonical `-1`.

No Battle Core implementation change is required. `MoveDefinition.accuracy` is already an integer and `from_dict()` preserves negative values. `DataImporter` does not reject negative accuracy.

### Independent regression suite
A dedicated DATA V3 accuracy suite verifies regenerated output and runtime contract:
- `Confide` → -1
- `Play Nice` → -1
- `Tearful Look` → -1
- `Decorate` → -1
- `Spicy Extract` → -1
- `Charm` remains 100 as a genuine numeric-100 control.

For each always-hit sentinel, `MoveDefinition.from_dict()` must preserve `-1`.

BattleRuleset checks:
- `accuracy_threshold_basis_points(-1, -6, 6) == 10000`;
- `accuracy_threshold_basis_points(100, -6, 6) < 10000`.

This explicitly prevents future conflation of “100 accuracy” with “bypasses accuracy checks”.

### Exact engineering artifact comparison against certified #62
- runtime moves: 919 both before and after.
- changed records: **285**.
- changed field: **accuracy only** on all 285.
- non-accuracy differences: **0**.
- classification differences: **0**.
- `effect_specs` differences: **0**.

Always-hit records by current coverage:
- 66 `RUNTIME_SUPPORTED`
- 28 `PARTIAL_RUNTIME`
- 180 `DATA_ONLY`
- 11 `UNSUPPORTED`

Coverage counts remain exactly:
- `RUNTIME_SUPPORTED`: **582**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **258**
- `UNSUPPORTED`: **12**

Notebook sync moves the SHA. #63 must pass a second exact-head 18/18 before closure without merge.

## PR #62 family retained as certified
17 simple selected-target stat packages are certified `RUNTIME_SUPPORTED`:
Baby-Doll Eyes, Charm, Confide, Eerie Impulse, Fake Tears, Feather Dance, Flash, Kinesis, Metal Sound, Noble Roar, Play Nice, Sand Attack, Scary Face, Screech, Smokescreen, Tearful Look, Tickle.

The #63 accuracy correction does not alter any of their effect packages or coverage; it fixes the canonical accuracy semantics for members whose source accuracy is null.

## Remaining selected-pokemon special cases
Only these six remain:
- `decorate`
- `defog`
- `memento`
- `parting_shot`
- `spicy_extract`
- `tar_shot`

`Decorate` and `Spicy Extract` have already had an initial source/output inspection:
- Decorate source: selected-pokemon; Attack +2 and Special Attack +2; `accuracy=null`.
- Generated package: OPPONENT Attack +2 / SpAtk +2, both unconditional.
- Spicy Extract source: selected-pokemon; Attack +2 and Defense -2; `accuracy=null`.
- Generated package: OPPONENT Attack +2 / Defense -2, both unconditional.

Those packages appear representable in the current single-opponent model, but their promotion was intentionally stopped when the transversal accuracy bug was discovered. Resume only after #63 final certification, then add exact move-specific source/output contracts before changing coverage.

Other four specials remain separate:
- Defog: stat drop plus field/hazard/screen cleanup.
- Memento: stat drops plus user faint.
- Parting Shot: stat drops plus user switch.
- Tar Shot: Speed drop plus Fire-damage/type-state interaction.

## Other remaining families
### User — 13 conditional/stateful
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote.

### All-opponents — 8
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.
Conditions such as gender or poisoned-only must be preserved.

### All-pokemon — 2
`flower_shield`, `rototiller`; current single-opponent target model cannot represent all-Pokémon/type predicates fully without further mechanics.

### Non-stat — 3
`Purify`, `Swallow`, `Beat Up` require separate semantic audits.

## Audit protocol
1. Inspect immutable source.
2. Inspect exact generated artifact.
3. Determine all battle-relevant fields, not only `effect_specs`.
4. Determine representable semantics in current Battle Core.
5. Choose coverage from semantics, not convenience.
6. Add exact fail-fast adapter/source contract.
7. Add independent regenerated-output/runtime assertion.
8. Batch only genuinely homogeneous source contracts.
9. DATA V3 focal.
10. 18/18 engineering SHA.
11. Measure artifact and compare changed fields.
12. Sync notebooks.
13. 18/18 final HEAD.
14. Close without merge.

Stop on any failure; fix root cause before another family.
