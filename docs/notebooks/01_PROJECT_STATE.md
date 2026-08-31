# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, immutable source data, and tested artifacts are authoritative if anything conflicts with this notebook.

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
All above: 18/18 on exact final HEAD, closed without merge.

## Certified transversal accuracy contract from #63
PokéAPI `accuracy=null` maps to canonical `accuracy=-1`, matching Battle Core's existing always-hit sentinel. Numeric accuracy remains numeric. The correction affected exactly 285/919 move records and changed only `accuracy`; classifications and `effect_specs` were unchanged.

# Current tranche — PR #65 selected stateful semantics
- Branch: `fix/data-v3-selected-special-stateful-b`
- Parent: certified #64 final `674ccaf0928c93749c581565d53eb1f672dfd7b4`.
- Engineering SHA before notebook synchronization: `01854416bf54179b0caa32b99459667d40d369c7`.
- Engineering SHA passed **18/18**, including DATA V3 independent regenerated-output assertions and Godot global.
- Notebook synchronization moves the SHA; final exact HEAD must pass 18/18 again before #65 closes without merge.

## #65 source/web audit decisions
The four remaining `selected-pokemon` cases were cross-checked against the immutable PokéAPI snapshot and current public Pokémon mechanics documentation before changing runtime exposure.

### Defog
Real/current semantics include target Evasion -1 plus field cleanup (hazards/screens/terrain; modern mechanics include hazard removal across both sides in relevant generations).
Current Battle Core cannot express that field transaction. Keeping only Evasion -1 can remove a strategic drawback and create a stronger fake move.
Decision: `DATA_ONLY`, `effect_specs=[]`.
Canonical accuracy remains `-1` because source accuracy is null.

### Memento
Real semantics: target Attack -2 / Special Attack -2 and the user faints.
Without mandatory self-faint, the generated -2/-2 package would become a free massive debuff.
Decision: `DATA_ONLY`, `effect_specs=[]`.
Accuracy remains genuine numeric `100`.

### Parting Shot
Real semantics: target Attack -1 / Special Attack -1 and then the user switches out.
Without the move-driven switch, the user could remain active and repeat a strategically different debuff.
Decision: `DATA_ONLY`, `effect_specs=[]`.
Accuracy remains genuine numeric `100`.

### Tar Shot
Real semantics: target Speed -1 plus a persistent Fire-type vulnerability (double Fire effectiveness until switching under the source contract).
Speed -1 is independently faithful. Omitting the vulnerability only makes the move weaker; it does not remove a cost or grant a false advantage.
Decision: `PARTIAL_RUNTIME`, keep exactly one `OPPONENT Speed -1` effect.
Accuracy remains `100`.

Implementation is isolated in `tools/pokeapi_adapter_selected_stateful.py` and applied after the legacy converter from `tools/pokeapi_adapter_v3.py`.

## Exact #65 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **584**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **255**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **26**.
- 23 stat-change records.
- 3 non-stat: `Beat Up`, `Purify`, `Swallow`.

Exact #64 → #65 raw comparison:
- changed move records: **4 only**.
- `defog`: only `effect_specs` changed, one Evasion -1 effect → empty.
- `memento`: only `effect_specs` changed, Atk/SpAtk -2/-2 → empty.
- `parting_shot`: only `effect_specs` changed, Atk/SpAtk -1/-1 → empty.
- `tar_shot`: only `classification` changed `DATA_ONLY → PARTIAL_RUNTIME`; Speed -1 effect unchanged.
- no unrelated move changed.

## Move Effects audit frontier after #65
The entire `selected-pokemon` DATA_ONLY-with-specs family is resolved.

Remaining 23 stat-change DATA_ONLY target distribution:
- 13 `user`
- 8 `all-opponents`
- 2 `all-pokemon`

User conditional/stateful:
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote them.

All-opponents:
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.
Audit conditions such as gender/poisoned-only and current singles target semantics before batching.

All-pokemon:
`flower_shield`, `rototiller`.
Current SELF/OPPONENT model cannot directly express all-Pokémon/type predicates.

Non-stat:
`Purify`, `Swallow`, `Beat Up`.

## Runtime safety invariant
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. A known-false or strategically unsafe spec must be removed/corrected.

Current effect targets are effectively SELF and OPPONENT. Missing/general mechanics include ally/team/side targeting, ability-filtered recipients, delayed effects, weather ratios, temporary type effects, protection/contact triggers, held-item transactions, field/hazard cleanup, move-driven self-faint/switch behavior, persistent damage-vulnerability state, and other move-specific state machines.

Coverage:
- `RUNTIME_SUPPORTED`: audited semantics fully faithful in current battle model.
- `PARTIAL_RUNTIME`: faithful executable subset whose omissions do not create materially false/advantageous behavior.
- `DATA_ONLY`: data retained without exposing unsafe executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.
