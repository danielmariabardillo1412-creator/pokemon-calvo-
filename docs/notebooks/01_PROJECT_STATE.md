# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, and immutable source data are authoritative if anything conflicts with this notebook.

## Repository / certification policy
- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are retained as branches / closed PRs **without merge**.
- New tranches branch from the latest exact certified HEAD.
- Certification requires all 18 normal workflows green on the same exact final SHA.
- Notebook updates move the SHA, so a notebook-bearing HEAD requires a second 18/18 run before PR closure.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- paths `data/api/v2`, `data/schema/v2`
- source JSON is read-only.

Pipeline:
`snapshot → tools/pokeapi_adapter_v3.py → tools/pokeapi_adapter.py compatibility corrections → data/raw/pokemon_api.json → Godot DataImporter → data/normalized/pokemon_api.json → runtime`.

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

## Current certified chain
Repository organization baseline: PR #33, HEAD `1247c4029b8001abd445db2f4155012962c703ee`, 18/18.
Persistent notebook baseline: PR #52, HEAD `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`, 18/18.

Recent Move Effects V3 chain:
- #53 simple self boosts C — `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`
- #54 Silk Trap — `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`
- #55 Aromatic Mist — `844efde0eed27e1a5ca8790ae95a183fba6ba98c`
- #56 Stuff Cheeks — `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`
- #57 Howl — `53e20600d372d44bc21eb145f598448a41828e5d`
- #58 Coaching — `3c4ac4d772a5869b45de592be7dd7f4d9b2a389b`
- #59 Gear Up — `ef7dd6a41b1cf4bccacf0a8d5098a755bb9fd3e9`
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
All above: 18/18 exact final HEAD, closed without merge.

## Current tranche — PR #61 pure SELF stat packages A
- Branch: `fix/data-v3-simple-self-stat-packages-a`
- Parent: certified #60 final `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`.
- Engineering SHA before notebook synchronization: `f3927a99d4d21d711dec77d68e7526757691c47f`.
- Engineering SHA passed 18/18, including independent regenerated-output assertions for all ten moves and Godot global.
- Notebook synchronization moves the branch tip; final exact HEAD must pass 18/18 again before #61 is closed without merge.

Certified in this tranche:
- Bulk Up — Attack +1 / Defense +1
- Calm Mind — Special Attack +1 / Special Defense +1
- Coil — Attack +1 / Defense +1 / Accuracy +1
- Cosmic Power — Defense +1 / Special Defense +1
- Defend Order — Defense +1 / Special Defense +1
- Dragon Dance — Attack +1 / Speed +1
- Hone Claws — Attack +1 / Accuracy +1
- Quiver Dance — Special Attack +1 / Special Defense +1 / Speed +1
- Shift Gear — Attack +1 / Speed +2
- Work Up — Attack +1 / Special Attack +1

For these ten, immutable source semantics are exactly an unconditional `user` stat package. The legacy generator already emitted the complete SELF package correctly; PR #61 adds fail-fast exact package validation and promotes only these named moves to `RUNTIME_SUPPORTED`.

## Exact move coverage from PR #61 engineering artifact
- `RUNTIME_SUPPORTED`: **565**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **275**
- `UNSUPPORTED`: **12**

Remaining `DATA_ONLY` records with non-empty `effect_specs`: **49**.
Breakdown:
- **46 stat-change records**.
- `Purify` and `Swallow` heal-related.
- `Beat Up` multi-hit.

Remaining 46 stat-change targets:
- 23 `selected-pokemon`
- 13 `user`
- 8 `all-opponents`
- 2 `all-pokemon`

The 13 remaining `user` cases are the conditional/stateful family rather than the clean stat-package family: Autotomize, Charge, Clangorous Soul, Defense Curl, Extreme Evoboost, Fillet Away, Geomancy, Growth, Minimize, No Retreat, Shell Smash, Stockpile, Tidy Up. Do not mass-promote them.

## Recently neutralized/corrected active false effects
- Silk Trap: false SELF Speed -1 removed; DATA_ONLY effect-free.
- Aromatic Mist: false SELF ally buff removed; DATA_ONLY effect-free.
- Stuff Cheeks: unconditional Defense +2 without Berry removed; DATA_ONLY effect-free.
- Howl: false OPPONENT Attack +1 corrected to faithful SELF Attack +1 subset; PARTIAL_RUNTIME.
- Coaching: false OPPONENT Attack/Defense buffs removed; DATA_ONLY effect-free.
- Gear Up: false OPPONENT Attack/SpAtk buffs removed; DATA_ONLY effect-free.
- Magnetic Flux: false OPPONENT Defense/SpDef buffs removed; DATA_ONLY effect-free.

## Runtime constraints relevant to audit
Effect targets available today are effectively SELF and OPPONENT. Missing/general mechanics include ally/team/side targeting, ability-filtered recipient sets, delayed effects, weather-conditioned ratios, temporary type changes, protection/contact triggers, held-item transactions, and move-specific counters/state machines.

Crucial fact: `effect_specs` execute regardless of coverage label. `DATA_ONLY` is not a safety gate; known-false specs must be removed.

Coverage meaning:
- `RUNTIME_SUPPORTED`: audited semantics fully faithful.
- `PARTIAL_RUNTIME`: faithful subset executes, known semantics missing.
- `DATA_ONLY`: data preserved; no faithful executable behavior should be implied.
- `UNSUPPORTED`: explicitly outside current contract.
