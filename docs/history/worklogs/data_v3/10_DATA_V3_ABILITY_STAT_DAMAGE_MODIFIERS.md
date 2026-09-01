# DATA V3 ABILITY STAT/DAMAGE MODIFIERS — V2

## Purpose

Operational record for the bounded ability tranche following certified PR #79.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family triage;
- `09_DATA_V3_ABILITY_HIT_STAT_REACTIONS.md` for Stamina and AFTER_DAMAGE limits.

## Certified parent

- PR #79: `DATA V3 — audit hit-triggered stat ability reactions`.
- Certified final HEAD: `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent:
  - `RUNTIME_SUPPORTED`: 8
  - `PARTIAL_RUNTIME`: 4
  - `DATA_ONLY`: 361
  - total: 373.

## PR #80 — contact damage and attack-doubling audit

- Branch: `audit/data-v3-ability-stat-damage-modifiers-v2`.
- Exact parent: certified #79 final `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`.
- PR: #80 `DATA V3 — audit contact damage and attack-doubling abilities`.
- Engineering SHA: `fecf7995e0284a0c7111239107aa3762f4e1233f`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot 4.7 global.

## Source/runtime audit

### Tough Claws / Garra Dura

Pinned immutable record:
- `data/api/v2/ability/181/index.json`
- main-series Generation VI;
- source English effect says contact moves are `1.33x` power;
- `effect_changes=[]`.

The pinned PokeAPI prose is stale for current main-series mechanics. Current audited mechanics are a 30% contact-move power boost. The immutable source is not edited. Instead, the explicit ability contract:
1. fail-fast validates that the pinned source still has the expected `1.33x` record;
2. normalizes only the project-owned loaded ability record in memory to:
   `Boosts the power of moves that make contact by 30%.`
3. registers runtime as existing `MODIFY_DAMAGE` with:
   - `requires_contact=true`
   - `multiplier_bp=13000`
   - no type gate
   - no physical-only gate.

Decision: **`tough_claws → RUNTIME_SUPPORTED`**.

This tranche adds no new general Battle Core primitive.

### Huge Power / Potencia

Pinned immutable record:
- `data/api/v2/ability/37/index.json`
- main-series Generation III;
- source says the Pokémon's **Attack is doubled** in battle;
- explicitly says the bonus is not a stat-stage modifier;
- identical to Pure Power;
- `effect_changes=[]`.

Decision: **remain `DATA_ONLY`**.

Reason: mapping `Attack x2` to a blanket final physical-damage x2 is not a faithful general implementation. It can diverge through damage-formula order/rounding and mechanics that do not consume the ordinary Attack stat in the same way. A real offensive-stat multiplier primitive is required before promotion.

### Pure Power / Energía Pura

Pinned immutable record:
- `data/api/v2/ability/74/index.json`
- main-series Generation III;
- same Attack-doubling semantics as Huge Power;
- `effect_changes=[]`.

Decision: **remain `DATA_ONLY`** for the same reason.

Both rejected records now have fail-fast source guards and regression tests so a future change cannot silently turn the rejection rationale stale.

## Runtime tests

New DATA V3 real-battle suite:
`tests/data/data_foundation_v3_ability_contact_damage_test_suite.gd`

It imports canonical DATA V3 and uses a real `AuthoritativeBattleServer`.

Contracts:
- `Tackle` is contact; with identical state/seed, Tough Claws damage must exceed plain Tackle and emit `ABILITY_TRIGGERED`.
- `Earthquake` is non-contact; with identical state/seed, Tough Claws damage must equal plain Earthquake and emit no Tough Claws trigger.
- canonical Tough Claws description/effect summary must be the corrected 30% text.
- Huge Power and Pure Power must remain `DATA_ONLY` and have no `MODIFY_DAMAGE` trigger.
- no-mass-promotion family invariant explicitly allowlists only Tough Claws as the new #80 promotion.

## Safety catch during implementation

A draft edit accidentally produced an excessively broad replacement of `tools/pokeapi_adapter_v3.py` (716 changed lines). It was detected by the pre-PR compare check and removed from branch history before PR creation. The branch was reset to the last good commit and the correction was implemented solely in the narrow ability-contract layer.

Final #79 → #80 engineering diff does **not** modify `tools/pokeapi_adapter_v3.py`.

## Engineering certification

Engineering HEAD:
`fecf7995e0284a0c7111239107aa3762f4e1233f`

Result:
- **18/18 normal workflows SUCCESS** on the exact engineering SHA;
- DATA Foundation V3 passes source audit, regeneration, invariants, Godot import, domain tests, normalization and runtime regression;
- global Godot 4.7 regression passes;
- all trainer workflow regressions pass.

## Exact #79 → #80 artifact drift

Compared tested #79 artifact against #80 engineering artifact.

### `data/raw/pokemon_api.json`
Exactly one ability changes: `tough_claws`.
Exactly three fields change:
- `classification`: `DATA_ONLY → RUNTIME_SUPPORTED`
- `description`: stale `1.33x` text → audited 30% text
- `effect_summary`: stale `1.33x` text → audited 30% text.

### `data/normalized/pokemon_api.json`
Exactly the same three Tough Claws changes and nothing else.

### Reports
Ability coverage changes only as expected:
- `RUNTIME_SUPPORTED`: 8 → **9**
- `PARTIAL_RUNTIME`: remains **4**
- `DATA_ONLY`: 361 → **360**
- total: **373**.

`unsupported_mechanics.json` moves only `tough_claws` from DATA_ONLY to RUNTIME_SUPPORTED.
`pokeapi_v3_audit.json` changes only the matching ability counts.

### Explicit negative checks
- `huge_power`: unchanged from #79, remains DATA_ONLY.
- `pure_power`: unchanged from #79, remains DATA_ONLY.
- manifest: unchanged.
- forms report: unchanged.
- auxiliary report: unchanged.
- no species, move/effect, item, learnset, evolution, type or stat drift.
- `import_time_ms` 516 → 495 ms is non-semantic timing noise.

## Coverage after #80 engineering

- `RUNTIME_SUPPORTED`: **9**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **360**
- total: **373**.

Runtime-supported set now includes:
`blaze`, `dragons_maw`, `fire_mane`, `overgrow`, `rocky_payload`, `steelworker`, `swarm`, `torrent`, `tough_claws`.

## Final certification procedure

After this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md` are synchronized:
1. compare engineering SHA `fecf7995e0284a0c7111239107aa3762f4e1233f` to final HEAD;
2. require only notebook changes (`01`, `04`, `10`);
3. require **18/18 SUCCESS** on that exact notebook-bearing HEAD;
4. close PR #80 without merge;
5. use that exact final HEAD as the next certified baseline.

## Next work after #80 closure

Continue DATA FOUNDATION V3 ability reliability with another bounded subgroup. First inventory candidates whose complete or useful-partial semantics already fit existing predicates. Do not bulk-promote the remaining `stat_damage_modifier` bucket.

Huge Power/Pure Power remain deferred until Battle Core has a genuine offensive-stat multiplier abstraction. Avoid opening weather/status/party/form/critical/effectiveness state merely to increase the coverage count.
