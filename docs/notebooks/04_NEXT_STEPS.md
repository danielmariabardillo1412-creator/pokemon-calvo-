# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #91 — `audit/data-v3-ability-target-state-v1`
- Final HEAD `9a6d559e1c83699d01a54718a1748bca791c034a`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**
- DATA_ONLY moves with executable `effect_specs`: **0**.

Certified #91 ability coverage:
- RUNTIME_SUPPORTED: **21**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **338**
- total: **373**.

# Current tranche — PR #92 Ability closure
- Branch: `audit/data-v3-ability-closure-v1`
- Parent: certified #91 final `9a6d559e1c83699d01a54718a1748bca791c034a`
- PR: #92 `DATA V3 — close ability runtime frontier`
- Engineering SHA: `837ad9da94a88b002d251eb9472a43cbc777d9a1`
- Engineering result: **18/18 SUCCESS**
- DATA V3 domain: **535 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/22_DATA_V3_ABILITY_CLOSURE.md`.

## #92 result — Ability V3 closed
No production/runtime or adapter code changed. No ability classification moved.

A deterministic closure suite freezes the exact **338 DATA_ONLY** frontier into 12 planning/blocker buckets:
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

Additional closure invariants:
- no DATA_ONLY ability may have a hidden registry mapping;
- high-value deferred sentinels remain DATA_ONLY and unmapped;
- source-text-missing remains exactly 60;
- coverage stays **21 / 14 / 338**.

### Battle Armor / Shell Armor final audit
Both have stable Gen III source, no history and source-declared identical critical-prevention semantics.

They stay DATA_ONLY because current trigger/event semantics lack truthful **critical-prevention provenance**. A simple `force_critical=false` can reproduce the outcome but cannot tell whether the ability actually prevented a critical or the roll was ordinary. Do not emit false trigger events or build another subsystem solely for two counters.

## Exact #91 final → #92 engineering artifact
Compared:
- #91 final run `33508792267`, artifact `9800760793`, head `9a6d559e...`
- #92 engineering run `33510073601`, artifact `9801276792`, head `837ad9da...`.

Canonical output is identical:
- raw
- normalized
- manifest
- forms
- unsupported mechanics
- PokeAPI V3 audit
- auxiliary.

Only `import_time_ms 513→512 ms` differs. DATA V3 checks rise from **529 → 535**, all green.

## Current certification step
Notebook synchronization follows engineering SHA `837ad9da94a88b002d251eb9472a43cbc777d9a1`.

Before closing #92:
1. verify engineering → final changed exactly `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `22_DATA_V3_ABILITY_CLOSURE.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #92 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #92 closure
**Do not continue ability micro-tranches.** Ability V3 is closed unless a future subsystem removes a frozen blocker.

Proceed in this order:
1. **Items V3 reliability/coverage** — important before returning to Trainer AI because trainer battles already consume/use item contracts.
2. **Evolutions V3 reliability** — verify conditions/references and close remaining data semantics.
3. **final end-to-end DATA V3 certification** — one consolidated artifact/CI/notebook closure.
4. return to **Trainer AI / trainer systems**.

This means the current DATA detour is now in its final few tranches rather than an open-ended ability audit.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
