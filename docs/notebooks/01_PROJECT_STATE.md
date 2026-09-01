# PROJECT STATE NOTEBOOK

## Purpose / authority
Fast recovery for engineering work. GitHub commits, PR state, CI, immutable source and tested artifacts override this notebook on conflict.

## Certification policy
- Repo: `danielmariabardillo1412-creator/pokemon-calvo-`; Godot 4.7.
- Certified snapshots stay as closed PR branches **without merge**.
- New tranches start from the latest exact certified HEAD, never `main`.
- Require all 18 normal workflows green on the same exact engineering SHA.
- Compare DATA V3 tested artifacts against the prior certified final.
- Notebook commits move SHA, therefore final notebook-bearing HEAD requires a second 18/18.
- Engineering → final must be notebooks-only.
- Any focal/regression failure stops the tranche until root cause is fixed.
- PR close is external state; do not move a certified SHA merely to record closure.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2`, `data/schema/v2` read-only.

Structural facts:
- 1,025 species
- 326 forms
- 18 runtime types
- 919 runtime moves
- 373 abilities
- 2,222 items
- 61,102 learnset entries
- 554 evolutions
- 0 broken refs
- 0 rejected definitions
- 18 XD Shadow moves explicitly excluded.

Pipeline:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Closed DATA V3 milestones
### Move Effects V3
- RUNTIME_SUPPORTED: **590**
- PARTIAL_RUNTIME: **71**
- DATA_ONLY: **246**
- UNSUPPORTED: **12**
- DATA_ONLY moves with executable `effect_specs`: **0**.

### Ability V3 — closure tranche #92
Ability micro-tranches are now considered **closed pending final notebook-bearing certification of #92**.

Current certified parent:
- PR #91 `DATA V3 — add shared target-state ability semantics`
- final HEAD `9a6d559e1c83699d01a54718a1748bca791c034a`
- **18/18 SUCCESS**, closed without merge.

Certified #91 ability coverage:
- RUNTIME_SUPPORTED: **21**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **338**
- total: **373**.

Detailed target-state history is in `docs/notebooks/21_DATA_V3_ABILITY_TARGET_STATE.md`.

## Current tranche — PR #92 Ability closure
- Branch: `audit/data-v3-ability-closure-v1`
- Parent: certified #91 final `9a6d559e1c83699d01a54718a1748bca791c034a`
- PR: #92 `DATA V3 — close ability runtime frontier`
- Engineering SHA: `837ad9da94a88b002d251eb9472a43cbc777d9a1`
- Engineering result: **18/18 SUCCESS**
- DATA V3 domain: **535 PASS / 0 FAIL**
- detailed notebook: `docs/notebooks/22_DATA_V3_ABILITY_CLOSURE.md`.

## #92 closure result
The remaining **338 DATA_ONLY abilities** are deterministically frozen into 12 planning/blocker buckets:
- stat_damage_modifier 64
- source_text_missing 60
- immunity_absorb_prevention 52
- move_property_control 36
- weather_terrain 33
- misc_unresolved 26
- status_dependent 18
- item_transaction 13
- form_identity 12
- switch_party 11
- contact_reactive 7
- faint_dependent 6.

The closure suite additionally proves:
- exact DATA_ONLY frontier = 338;
- no DATA_ONLY ability has a hidden `BattleEffectRegistry` mapping;
- high-value deferred sentinels remain DATA_ONLY and unmapped;
- source-text-missing frontier remains exactly 60, so mechanics are never inferred from names.

## Final compatible-subgroup audit
Battle Armor and Shell Armor were source-audited:
- Gen III, main-series, no `effect_changes`;
- both prevent critical hits against the holder and are source-declared identical.

They remain **DATA_ONLY** because Battle Core lacks truthful critical-prevention provenance. A defender-side `force_critical=false` can reproduce the raw outcome, but current trigger/event semantics cannot distinguish a critical actually prevented from an ordinary non-critical roll. Do not emit false `ABILITY_TRIGGERED` events or create a new interception subsystem merely to move two counters.

## #92 exact artifact comparison
Certified #91 final tested artifact:
- head `9a6d559e1c83699d01a54718a1748bca791c034a`
- run `33508792267`
- artifact `9800760793`.

#92 engineering tested artifact:
- head `837ad9da94a88b002d251eb9472a43cbc777d9a1`
- run `33510073601`
- artifact `9801276792`.

Both artifacts contain the same 15 files.

Canonically identical:
- raw `pokemon_api.json`
- normalized `pokemon_api.json`
- manifest
- forms policy report
- unsupported mechanics report
- PokeAPI V3 audit report
- auxiliary report.

Ability coverage remains exactly **21 / 14 / 338**. No species/Pokémon, move/effect, ability classification, item/status, learnset/evolution, type/stat or report-set drift exists.

Only `import_time_ms 513 → 512 ms` differs; this is execution timing noise.

## Ability V3 closure meaning
After #92 final certification, do **not** continue ability micro-tranches merely to increase support count. Reopen an ability only when a future battle subsystem/source change materially removes a frozen blocker (weather, terrain, doubles/ally context, form identity, gender, switch history, accuracy/evasion, move-property metadata, effectiveness provenance, item lifecycle, status interception, per-hit/faint-safe contact handling, etc.).

## Current certification step
Notebook synchronization follows engineering SHA `837ad9da94a88b002d251eb9472a43cbc777d9a1`.

Before closing #92:
1. engineering → final must change exactly `01`, `04`, `22` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #92 without merge;
4. use exact final SHA as next certified baseline.

## Next DATA V3 work after #92
1. **Items V3 reliability/coverage**
2. **Evolutions V3 reliability**
3. **final end-to-end DATA V3 certification**
4. return to **Trainer AI / trainer systems**.

No further ability work is required before returning to Trainer AI unless a closure regression exposes a real issue.
