# DATA V3 ABILITY TYPE BOOSTS — V1

## Purpose

Operational checkpoint for the bounded ability tranche that follows certified PR #77.

Use together with:
- `01_PROJECT_STATE.md` for broad state;
- `04_NEXT_STEPS.md` for the live pointer;
- `06_DATA_V3_ABILITY_RUNTIME_AUDIT.md` for the initial six-ability audit;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family inventory and Swarm certification.

## Certified parent

- PR #77: `DATA V3 — inventory ability families and audit Swarm`.
- Certified final HEAD: `78da22438d0866193b0d1154814464531ac55641`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent:
  - `RUNTIME_SUPPORTED`: 4 (`blaze`, `overgrow`, `swarm`, `torrent`)
  - `PARTIAL_RUNTIME`: 3 (`intimidate`, `levitate`, `static`)
  - `DATA_ONLY`: 366
  - total: 373.

## Current tranche — PR #78

- Branch: `audit/data-v3-ability-type-boosts-v1`.
- PR: #78 `DATA V3 — audit unconditional ability type boosts`.
- Exact parent: certified #77 final `78da22438d0866193b0d1154814464531ac55641`.
- Engineering SHA: `f01b1d0553b7dfa1e5998ee1de99ace9fad1534b`.
- Engineering SHA certification: **18/18 workflows SUCCESS**, including DATA Foundation V3 and Godot 4.7 global.

The tranche is deliberately bounded to abilities whose battle transaction fits the already-certified `MODIFY_DAMAGE` primitive as:
- user's move has one specified type;
- unconditional 1.5x / +50% multiplier;
- no weather, terrain, item, status, switch, form or party transaction is required.

## Source audit — promoted allowlist

### Steelworker

Snapshot: `data/api/v2/ability/200/index.json`.

- main-series;
- Generation VII;
- current English effect explicitly says the Pokémon's Steel moves have **1.5x power**;
- `effect_changes=[]`.

Decision: `steelworker -> RUNTIME_SUPPORTED`.

### Dragon's Maw

Snapshot: `data/api/v2/ability/263/index.json`.

- main-series;
- Generation VIII;
- current English effect explicitly says Dragon-type moves used by the Pokémon gain **50% power**;
- `effect_changes=[]`.

Decision: `dragons_maw -> RUNTIME_SUPPORTED`.

### Rocky Payload

Snapshot: `data/api/v2/ability/276/index.json`.

- main-series;
- Generation IX;
- current English effect explicitly says Rock-type moves used by the Pokémon gain **50% power**;
- `effect_changes=[]`.

Decision: `rocky_payload -> RUNTIME_SUPPORTED`.

### Fire Mane

Snapshot: `data/api/v2/ability/313/index.json`.

- main-series;
- Generation IX;
- current English effect explicitly says the Pokémon's Fire-type moves gain **50% power**;
- `effect_changes=[]`.

Decision: `fire_mane -> RUNTIME_SUPPORTED`.

## Explicit rejection — Transistor

Snapshot: `data/api/v2/ability/262/index.json`.

The pinned source currently states +50% Electric-type move power and has `effect_changes=[]`, but the ability is version-sensitive and the snapshot does not preserve enough historical/versioned semantic information to justify one universal runtime multiplier across the project's version-aware data policy.

Decision: **keep `transistor -> DATA_ONLY`** until a dedicated version-aware ability contract exists. Do not choose a convenient universal multiplier merely to increase coverage.

The runtime-contract suite explicitly checks that Transistor stays `DATA_ONLY` in this tranche.

## Runtime implementation

No new Battle Core primitive was introduced.

`BattleEffectRegistry._register_abilities()` adds four `MODIFY_DAMAGE` registrations:

- `steelworker` -> `move_type_id=steel`, `multiplier_bp=15000`
- `dragons_maw` -> `move_type_id=dragon`, `multiplier_bp=15000`
- `rocky_payload` -> `move_type_id=rock`, `multiplier_bp=15000`
- `fire_mane` -> `move_type_id=fire`, `multiplier_bp=15000`

There is deliberately **no** `hp_at_or_below_divisor` or another hidden condition on these four.

`DamageCalculator` consumes the same `damage_multiplier_basis_points` abstraction already certified for Blaze / Overgrow / Torrent / Swarm. This tranche therefore does not invent a new approximation layer or change damage ordering globally.

The frozen historical `runtime_supported_ability_ids()` Battle V2 compatibility surface is unchanged. DATA V3 reliability continues to inspect the actual trigger registry via `implemented_ability_ids()`.

## Runtime/source regression protection

`tools/pokeapi_ability_runtime_contracts.py` now has an explicit four-ID `_TYPE_POWER_BOOSTS` allowlist with:
- required expected generation;
- required type wording;
- required numeric source token (`1.5x` or `50%`);
- required power semantic;
- required `effect_changes=[]`.

If any of those source contracts changes, DATA V3 generation fails instead of silently retaining a stale support label.

`tests/data/data_foundation_v3_ability_runtime_contract_test_suite.gd` enforces:
- exact runtime/partial/data-only partition;
- exact actual implemented registry IDs;
- exact move type and 15000 multiplier for all four new abilities;
- absence of the pinch HP condition;
- Transistor remains `DATA_ONLY`.

`tests/data/data_foundation_v3_ability_family_inventory_test_suite.gd` still anchors the original #76 367-record DATA_ONLY frontier. Its post-#76 promotion allowlist is now exactly:
- `swarm`
- `steelworker`
- `dragons_maw`
- `rocky_payload`
- `fire_mane`

Every other member of that original frontier must remain `DATA_ONLY` or the test fails.

## Ability coverage after #78 engineering build

For all 373 preserved abilities:

- `RUNTIME_SUPPORTED`: **8**
  - `blaze`
  - `dragons_maw`
  - `fire_mane`
  - `overgrow`
  - `rocky_payload`
  - `steelworker`
  - `swarm`
  - `torrent`
- `PARTIAL_RUNTIME`: **3**
  - `intimidate`
  - `levitate`
  - `static`
- `DATA_ONLY`: **362**
- total: **373**.

## Exact #77 -> #78 engineering artifact comparison

Compared the certified #77 DATA V3 artifact against the artifact generated on engineering SHA `f01b1d0553b7dfa1e5998ee1de99ace9fad1534b`.

Raw dataset:
- exactly four changed abilities;
- exactly one changed field on each: `classification`;
- `dragons_maw: DATA_ONLY -> RUNTIME_SUPPORTED`;
- `fire_mane: DATA_ONLY -> RUNTIME_SUPPORTED`;
- `rocky_payload: DATA_ONLY -> RUNTIME_SUPPORTED`;
- `steelworker: DATA_ONLY -> RUNTIME_SUPPORTED`.

Normalized dataset:
- exactly the same four `classification` changes.

Unchanged in raw + normalized:
- every other ability;
- species/Pokémon;
- moves and `effect_specs`;
- items;
- learnsets;
- evolutions;
- types and stats.

Reports:
- `pokeapi_v3_audit.json`: `RUNTIME_SUPPORTED 4 -> 8`, `DATA_ONLY 366 -> 362`;
- `unsupported_mechanics.json`: exactly those four IDs move from DATA_ONLY to RUNTIME_SUPPORTED, with the same count changes;
- `import_summary.json`: only nondeterministic `import_time_ms` changes (`519 -> 525 ms`).

Unchanged reports/artifacts:
- manifest;
- forms policy report;
- auxiliary report.

No semantic drift outside the four intended classifications was observed.

## Certification state

Engineering SHA `f01b1d0553b7dfa1e5998ee1de99ace9fad1534b`: **18/18 SUCCESS**.

This notebook synchronization now moves branch HEAD. Before PR #78 can be closed without merge:
1. synchronize `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md`;
2. verify engineering SHA -> final HEAD changes **only operational notebooks**;
3. require **18/18 SUCCESS** on that exact final notebook-bearing HEAD;
4. close PR #78 without merge;
5. use that exact final SHA as the next certified parent.

## Next bounded work after #78 certification

Remain in DATA FOUNDATION V3 ability reliability. Do not mass-convert `stat_damage_modifier`.

First candidate for the next bounded audit: `stamina`, because an on-hit self stat-stage reaction may be representable with existing AFTER_DAMAGE + stat-stage primitives. It must still receive a fresh source/runtime audit before any label or trigger change.

Keep the broader contact-reactive family deferred while the known Static fatal-contact trigger gap remains unresolved.
