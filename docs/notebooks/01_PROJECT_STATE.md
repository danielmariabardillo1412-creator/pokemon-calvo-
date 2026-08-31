# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, immutable source data, and tested artifacts are authoritative if anything conflicts with this notebook.

## Repository / certification policy
- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are retained as branches / closed PRs **without merge**.
- New tranches branch from the latest exact certified HEAD.
- Certification requires all 18 normal workflows green on the same exact final SHA.
- Notebook updates move the SHA, so the notebook-bearing HEAD requires a second 18/18 run before PR closure.
- Stop on any failing focal/regression test and fix root cause before continuing.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- paths `data/api/v2`, `data/schema/v2`
- source JSON is read-only.

Pipeline:
`snapshot → tools/pokeapi_adapter_v3.py → tools/pokeapi_adapter.py + narrow audit layers → data/raw/pokemon_api.json → Godot DataImporter → data/normalized/pokemon_api.json → runtime`.

Archived V2 remains provenance-only at `tools/archive/pokeapi_adapter_v2_legacy.py`.

## Structural V3 facts
- 1,025 base species; 326 forms.
- 18 runtime battle types.
- 919 runtime moves.
- 373 abilities; 2,222 items.
- 61,102 learnset entries.
- 554 evolution records.
- 0 broken refs; 0 rejected definitions.
- 18 XD Shadow moves explicitly excluded instead of remapped.

## Recent certified Move Effects chain
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- #61 pure SELF stat packages A — `623930ca0b98b00099288bcf542e7e0a922ac180`
- #62 pure opponent stat drops A — `6d1335b8c5cee0b1cf1e99910a7707734b4aef85`
- #63 always-hit accuracy semantics — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stat packages A — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful semantics — `b13af37c350156bc7a9a7d7faf63742245afd801`
All above: 18/18 on exact final HEAD, closed without merge.

## Certified transversal accuracy contract from #63
PokéAPI `accuracy=null` maps to canonical `accuracy=-1`, matching Battle Core's always-hit sentinel. Numeric accuracy remains numeric. Exactly 285/919 records changed only in `accuracy`.

# Current tranche — PR #66 all-opponents stat semantics
- Branch: `fix/data-v3-all-opponents-stat-audit`
- Parent: certified #65 final `b13af37c350156bc7a9a7d7faf63742245afd801`.
- Engineering SHA before notebook synchronization: `4773a8ce33854f987f2cc09bb4f14ef5db678d0b`.
- Engineering SHA passed **18/18**, including DATA V3 independent regenerated-output assertions and Godot global.
- Artifact comparison #65→#66 changed exactly eight move records and no unrelated moves.
- Notebook synchronization moves the SHA; final exact HEAD must pass 18/18 again before #66 closes without merge.

## #66 audited decisions
The eight remaining `all-opponents` DATA_ONLY-with-specs stat moves were checked against the immutable snapshot and current public core-series mechanics.

### Fully representable base effects in the current singles model
In singles, `all-opponents` collapses faithfully to the one opposing active Pokémon. The following generated stat packages are complete base move effects:
- `growl`: Attack -1, accuracy 100 → `RUNTIME_SUPPORTED`.
- `leer`: Defense -1, accuracy 100 → `RUNTIME_SUPPORTED`.
- `string_shot`: Speed -2, accuracy 95 → `RUNTIME_SUPPORTED`.
- `sweet_scent`: Evasion -2, accuracy 100 → `RUNTIME_SUPPORTED`.
- `tail_whip`: Defense -1, accuracy 100 → `RUNTIME_SUPPORTED`.

Ability/item interactions such as Soundproof are intentionally handled by the later ability/item interaction audit, consistent with already-certified sound moves such as Screech and Metal Sound.

### Unsafe conditional effects neutralized
- `captivate`: requires opposite gender and fails for same-gender/genderless targets; current effect model has no gender predicate. Result: `DATA_ONLY`, `effect_specs=[]`.
- `venom_drench`: stat drops require a poisoned target; current generated package was unconditional. Result: `DATA_ONLY`, `effect_specs=[]`.
- `cotton_spore`: modern powder/spore rules include intrinsic Grass-type immunity; the current effect model has no powder/type target predicate. Result: `DATA_ONLY`, `effect_specs=[]`.

### Sweet Scent canonical text repair
The immutable snapshot's structured `stat_changes` says current Evasion -2, matching current mechanics, while generic `effect_entries` prose was stale at -1. #66 leaves the source JSON untouched and normalizes only the loaded in-memory English prose before canonical `effect_summary` is produced. Canonical summary now matches Evasion -2.

Implementation is isolated in `tools/pokeapi_adapter_all_opponents.py`, chained after `tools/pokeapi_adapter_selected_stateful.py`.

## Exact #66 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **589**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **250**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **18**.
- 15 stat-change records.
- 3 non-stat: `Beat Up`, `Purify`, `Swallow`.

Exact #65 → #66 raw comparison:
- changed move records: **8 only**.
- `captivate`, `cotton_spore`, `venom_drench`: only `effect_specs` removed.
- `growl`, `leer`, `string_shot`, `tail_whip`: only `classification` changed `DATA_ONLY → RUNTIME_SUPPORTED`.
- `sweet_scent`: `classification` changed to `RUNTIME_SUPPORTED` and canonical `effect_summary` corrected from the stale -1 wording to -2; its accuracy/target/effect package remained unchanged.
- no unrelated move changed.

## Move Effects audit frontier after #66
The entire `selected-pokemon` and `all-opponents` DATA_ONLY-with-specs families are resolved.

Remaining 15 stat-change DATA_ONLY target distribution:
- 13 `user`
- 2 `all-pokemon`

User conditional/stateful:
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote them; inspect costs, delayed turns, weather/state dependencies and additional battle-state effects.

All-pokemon:
`flower_shield`, `rototiller`.
Current SELF/OPPONENT model cannot directly express all-Pokémon/type predicates.

Non-stat:
`Purify`, `Swallow`, `Beat Up`.

## Runtime safety invariant
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. A known-false or strategically unsafe spec must be removed/corrected.

Coverage:
- `RUNTIME_SUPPORTED`: audited semantics fully faithful in current battle model.
- `PARTIAL_RUNTIME`: faithful executable subset whose omissions do not create materially false/advantageous behavior.
- `DATA_ONLY`: data retained without exposing unsafe executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.
