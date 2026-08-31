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
- #53 simple self boosts C — `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`
- #54 Silk Trap — `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`
- #55 Aromatic Mist — `844efde0eed27e1a5ca8790ae95a183fba6ba98c`
- #56 Stuff Cheeks — `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`
- #57 Howl — `53e20600d372d44bc21eb145f598448a41828e5d`
- #58 Coaching — `3c4ac4d772a5869b45de592be7dd7f4d9b2a389b`
- #59 Gear Up — `ef7dd6a41b1cf4bccacf0a8d5098a755bb9fd3e9`
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- #61 pure SELF stat packages A — final `623930ca0b98b00099288bcf542e7e0a922ac180`
All: 18/18 on exact final HEAD, closed without merge.

## Current tranche — PR #62 pure opponent stat drops A
- Branch: `fix/data-v3-simple-opponent-stat-drops-a`
- Parent: certified #61 final `623930ca0b98b00099288bcf542e7e0a922ac180`.
- Engineering SHA before notebook synchronization: `e384cb3a5b19a158e11da4925e7c2c23c929d9ca`.
- Engineering SHA passed **18/18**, including DATA V3, independent regenerated-output assertions for all 17 moves, and Godot global.
- Notebook synchronization moves the SHA; final exact HEAD must pass 18/18 again before #62 closes without merge.

Source-audited and promoted in #62:
- Baby-Doll Eyes — opponent Attack -1
- Charm — Attack -2
- Confide — Special Attack -1
- Eerie Impulse — Special Attack -2
- Fake Tears — Special Defense -2
- Feather Dance — Attack -2
- Flash — Accuracy -1
- Kinesis — Accuracy -1
- Metal Sound — Special Defense -2
- Noble Roar — Attack -1 / Special Attack -1
- Play Nice — Attack -1
- Sand Attack — Accuracy -1
- Scary Face — Speed -2
- Screech — Defense -2
- Smokescreen — Accuracy -1
- Tearful Look — Attack -1 / Special Attack -1
- Tickle — Attack -1 / Defense -1

The legacy generator already emitted the correct complete OPPONENT stat packages. #62 adds an exact allowlist, exact source `stat_chance`, `effect_changes=[]`, target/category/damage-class/metadata checks, generated package checks, and promotes only these 17 to `RUNTIME_SUPPORTED`.

## Exact coverage from PR #62 engineering artifact
- `RUNTIME_SUPPORTED`: **582**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **258**
- `UNSUPPORTED`: **12**

Remaining `DATA_ONLY` records with non-empty `effect_specs`: **32**.
- **29 stat-change** records.
- `Beat Up`, `Purify`, `Swallow` are the 3 non-stat cases.

Remaining 29 stat-change target distribution:
- 13 `user`
- 8 `all-opponents`
- 6 `selected-pokemon`
- 2 `all-pokemon`

Remaining six `selected-pokemon` special cases:
`decorate`, `defog`, `memento`, `parting_shot`, `spicy_extract`, `tar_shot`.
No simple selected-target stat drops remain unaudited.

Remaining 13 `user` cases are conditional/stateful:
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote them.

All-opponents remainder:
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.

All-pokemon remainder:
`flower_shield`, `rototiller`.

## Runtime safety invariant
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. A known-false spec must be removed/corrected.

Current effect targets are effectively SELF and OPPONENT. Missing/general mechanics include ally/team/side targeting, ability-filtered recipients, delayed effects, weather ratios, temporary type effects, protection/contact triggers, held-item transactions, and move-specific state machines.

Coverage:
- `RUNTIME_SUPPORTED`: audited semantics fully faithful in current battle model.
- `PARTIAL_RUNTIME`: faithful executable subset with explicit missing mechanics.
- `DATA_ONLY`: data retained without claiming faithful executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.
