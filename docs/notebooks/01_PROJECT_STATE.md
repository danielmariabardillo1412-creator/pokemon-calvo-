# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, and immutable source data are authoritative if anything conflicts with this notebook.

## Repository / certification policy
- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are retained as branches / closed PRs **without merge**.
- New tranches branch from the latest exact certified HEAD.
- Certification requires all 18 normal workflows green on the same exact final SHA.
- Notebook updates move the SHA, so the final notebook-bearing HEAD requires a second 18/18 run before PR closure.
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
`snapshot → tools/pokeapi_adapter_v3.py → tools/pokeapi_adapter.py → data/raw/pokemon_api.json → Godot DataImporter → data/normalized/pokemon_api.json → runtime`.

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
All above: 18/18 on exact final HEAD, closed without merge.

## PR #63 accuracy correction retained as certified
PokéAPI `accuracy=null` is now canonically preserved as `accuracy=-1`, matching Battle Core's existing always-hit sentinel. The correction affected exactly 285/919 move records and changed only the `accuracy` field; classifications and `effect_specs` were unchanged.

## Current tranche — PR #64 selected special stat packages A
- Branch: `fix/data-v3-selected-special-stat-packages-a`
- Parent: certified #63 final `9f8b3e01bec1f86cff75380d68dd98d76e738e78`.
- Engineering SHA before notebook synchronization: `3c9c83d3ff99c0e9a98506343db4e28b6de65af2`.
- Engineering SHA passed **18/18**, including DATA V3 independent regenerated-output assertions and Godot global.
- Notebook synchronization moves the SHA; final exact HEAD must pass 18/18 again before #64 closes without merge.

Source-audited/promoted in #64:
- `Decorate`: selected target, always-hit (`accuracy=-1` canonical), Attack +2 / Special Attack +2.
- `Spicy Extract`: selected target, always-hit (`accuracy=-1` canonical), Attack +2 / Defense -2.

The legacy generator already emitted both complete OPPONENT stat packages correctly. #64 does not rewrite effects. It adds exact move-specific source/generated contracts and promotes only these two records to `RUNTIME_SUPPORTED`.

### Exact #64 engineering artifact
- `RUNTIME_SUPPORTED`: **584**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **256**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty `effect_specs`: **30**
  - 27 stat-change
  - `Beat Up`, `Purify`, `Swallow`

Artifact comparison #63 → #64:
- changed move records: **2** (`decorate`, `spicy_extract`)
- changed key on both: **classification only**
- `accuracy` differences: 0
- `effect_specs` differences: 0

Remaining 27 stat-change DATA_ONLY target distribution:
- 13 `user`
- 8 `all-opponents`
- 4 `selected-pokemon`
- 2 `all-pokemon`

The selected-pokemon family is now reduced to four special/stateful moves:
- `defog`
- `memento`
- `parting_shot`
- `tar_shot`

Remaining 13 `user` cases are conditional/stateful:
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote them.

All-opponents remainder:
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.

All-pokemon remainder:
`flower_shield`, `rototiller`.

## Runtime safety invariant
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. A known-false spec must be removed/corrected.

Current effect targets are effectively SELF and OPPONENT. Missing/general mechanics include ally/team/side targeting, ability-filtered recipients, delayed effects, weather ratios, temporary type effects, protection/contact triggers, held-item transactions, field/hazard cleanup, move-driven self-faint/switch behavior, temporary damage-vulnerability state, and other move-specific state machines.

Coverage:
- `RUNTIME_SUPPORTED`: audited semantics fully faithful in current battle model.
- `PARTIAL_RUNTIME`: faithful executable subset with explicit missing mechanics.
- `DATA_ONLY`: data retained without claiming faithful executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.
