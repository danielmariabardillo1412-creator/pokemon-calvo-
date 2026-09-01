# DATA V3 ABILITY CONTACT DAMAGE — V1

## Purpose
Operational record for the bounded contact-retaliation damage tranche following certified PR #84.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the original 367-record family triage;
- `14_DATA_V3_ABILITY_CONTACT_REACTIONS.md` for the immediately preceding certified tranche.

## Certified parent
- PR #84: `DATA V3 — audit defender contact reaction abilities`.
- Certified final HEAD: `67c483899dadb2e3d1b5314a779d4c71b1bc8708`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 9 PARTIAL_RUNTIME / 351 DATA_ONLY / 373 total**.

## PR #85
- Branch: `audit/data-v3-ability-contact-damage-v1`.
- Exact parent: certified #84 final `67c483899dadb2e3d1b5314a779d4c71b1bc8708`.
- PR: #85 `DATA V3 — audit contact retaliation damage ability`.
- First engineering candidate: `afe9f6fa558fffbd7347a2cca33a1c94dc5eec58` — **FAILED DATA V3 domain, 459 PASS / 2 FAIL**.
- Corrected engineering SHA: `146285fc4e85c0d50036c12454af641c2ebf4aa5`.
- Corrected engineering SHA: **18/18 SUCCESS**, including DATA Foundation V3 and Godot 4.7 global.
- Corrected DATA V3 domain: **461 PASS / 0 FAIL**.

## Source decisions

### Iron Barbs — PARTIAL_RUNTIME
Pinned immutable source:
- `data/api/v2/ability/160/index.json`;
- main-series Generation V;
- when a move makes contact, the move user loses **1/8 of its own maximum HP**;
- source says it functions identically to Rough Skin under current semantics;
- `effect_changes=[]`.

The runtime can represent a useful exact subset:
- ordinary damaging contact move;
- Iron Barbs owner survives the move;
- reaction occurs after the completed move;
- attacker loses exactly `floor(max_hp / 8)`, minimum 1.

Decision: **`iron_barbs → PARTIAL_RUNTIME`**.

Why not full support:
1. main-series contact multi-hit attacks trigger the retaliation once per contact strike;
2. current Battle Core requests defender `AFTER_DAMAGE` only once after the completed move;
3. current `TurnExecutor` does not request defender `AFTER_DAMAGE` when the defender was KO'd by the contact hit;
4. therefore fatal-owner/double-KO ordering and per-strike retaliation remain absent.

No generic faint-safe/per-strike trigger policy was changed in this tranche.

### Rough Skin — remains DATA_ONLY
Pinned immutable source:
- `data/api/v2/ability/24/index.json`;
- main-series Generation III;
- current English effect is the same **1/8 of the attacker's maximum HP** on contact;
- however `effect_changes` preserves a Diamond/Pearl battle value of **1/16 of the attacker's maximum HP**.

The current ability runtime contract is not version-group aware. A universal 1/8 mapping would therefore erase source-preserved historical battle semantics.

Decision: **`rough_skin → DATA_ONLY`** until a deliberate version-aware ability contract exists.

This follows the same conservative rule used for other version-sensitive ability values: do not choose one universal number merely because it matches the newest prose.

## Generic Battle Core primitive
The existing `BattleEffectSpec` already had:
- `target`;
- `ratio_basis_points`;
- `to_dict()` / `from_dict()` serialization.

This tranche adds one generic effect kind only:

`BattleEffectSpec.MAX_HP_DAMAGE = "max_hp_damage"`

Execution contract:
1. resolve the normal effect target;
2. compute `maxi(1, recipient.stats.max_hp * ratio_basis_points / 10000)`;
3. apply that amount of damage to the recipient;
4. emit `BattleEvent.DAMAGE_APPLIED` with metadata:
   - `cause = "max_hp_fraction"`;
   - `ratio_basis_points = <configured ratio>`.

The effect does **not** overwrite `context.last_damage`, because retaliation damage is not the original move's damage transaction.

The new primitive is not hard-coded to Iron Barbs and round-trips through `BattleEffectSpec.to_dict()/from_dict()`.

## Iron Barbs runtime registration
`modules/battle/effects/battle_effect_registry.gd` registers:
- trigger: `AFTER_DAMAGE`;
- source: ability `iron_barbs`;
- condition: `requires_contact=true`;
- effect: `MAX_HP_DAMAGE`;
- target: `OPPONENT` — the attacker in this defender-owned trigger context;
- `ratio_basis_points=1250` = 1/8.

Rough Skin receives no runtime trigger.

## Source-contract layer
`tools/pokeapi_ability_runtime_contracts.py`:
- classifies `iron_barbs` as PARTIAL_RUNTIME;
- validates Gen V, main-series, 1/8 attacker-max-HP contact semantics and no history;
- adds `rough_skin` to an explicit version-sensitive guard set while keeping it DATA_ONLY;
- validates Rough Skin Gen III current 1/8 prose;
- requires exactly one pinned historical change;
- requires the change marker `diamond-pearl`;
- requires the historical English **1/16 attacker max HP** token.

This makes source drift fail regeneration rather than silently invalidating the support/blocker decision.

## Exact contract tests
`tests/data/data_foundation_v3_ability_runtime_contract_test_suite.gd` now requires:
- exact 13 RUNTIME_SUPPORTED IDs;
- exact 10 PARTIAL_RUNTIME IDs;
- exactly 350 DATA_ONLY;
- exact 373 partition;
- exact implemented ability registry inventory;
- exact Iron Barbs `AFTER_DAMAGE + requires_contact + MAX_HP_DAMAGE(OPPONENT, 1250bp)` shape;
- Rough Skin remains DATA_ONLY and has no AFTER_DAMAGE mapping.

`tests/data/data_foundation_v3_ability_family_inventory_test_suite.gd` adds only `iron_barbs` to the explicit post-#76 promotion allowlist. The original 367-record family partition and exact 11-member contact-reactive inventory remain unchanged.

## Real-battle focal suite
New suite:
`tests/data/data_foundation_v3_ability_contact_retaliation_test_suite.gd`

It verifies:
1. Tackle is a damaging contact control;
2. Water Gun is a damaging non-contact control;
3. the chosen canonical multi-hit control is contact and structurally MULTI_HIT;
4. MAX_HP_DAMAGE survives serialization roundtrip;
5. Tackle against Iron Barbs removes exactly **30 HP** from an attacker with **240 max HP**;
6. the ability event is owned by the defender and the retaliation DAMAGE_APPLIED event records 30 HP / 1250bp;
7. Water Gun leaves Iron Barbs inert;
8. a 20-current-HP attacker can be KO'd by the 30-requested retaliation while the defender survives;
9. a 1-HP Iron Barbs owner is KO'd by Tackle and produces no retaliation, explicitly preserving the fatal-owner partial boundary;
10. a contact multi-hit move hits at least twice but current Battle Core emits exactly one Iron Barbs retaliation, explicitly preserving the per-strike partial boundary;
11. Rough Skin remains inert.

## First CI failure — important root-cause record
First engineering candidate:
`afe9f6fa558fffbd7347a2cca33a1c94dc5eec58`

DATA V3 source audit, regeneration, raw invariants, import, ability contracts and all previous suites passed. The domain runner ended:

**459 PASS / 2 FAIL**

The only failures were:
- `data_v3_contact_retaliation_move_metadata`;
- `data_v3_iron_barbs_multihit_partial_boundary`.

The runtime itself was already passing:
- Iron Barbs exact 30-HP Tackle retaliation;
- non-contact Water Gun control;
- attacker KO path;
- fatal-owner missing behavior;
- Rough Skin inert blocker.

### Root cause
The test had assumed canonical `Double Kick` was a contact multi-hit move.

The failed-run generated artifact proved the actual DATA V3 records:
- `double_kick`: RUNTIME_SUPPORTED, MULTI_HIT 2x fixed, **`makes_contact=false`**;
- `bonemerang`: RUNTIME_SUPPORTED, 2x fixed, non-contact;
- `water_shuriken`: RUNTIME_SUPPORTED, 2-5 hits, non-contact;
- `double_slap`: RUNTIME_SUPPORTED, **contact**, MULTI_HIT **2-5**.

Therefore the two failures were a faulty test fixture assumption, not a Battle Core defect.

### Correction
Only `tests/data/data_foundation_v3_ability_contact_retaliation_test_suite.gd` changed:
- replaced Double Kick with canonical Double Slap;
- exact metadata assertion now requires contact + MULTI_HIT 2-5;
- deterministic seed search ensures Double Slap lands and the defender survives before asserting the per-strike gap.

Compare failed SHA → corrected SHA:
- **1 commit**;
- **1 changed file**;
- only the new focal test suite;
- **zero runtime/source-contract changes**.

Corrected engineering SHA:
`146285fc4e85c0d50036c12454af641c2ebf4aa5`

Result:
- **18/18 SUCCESS**;
- DATA V3 domain **461 PASS / 0 FAIL**.

## Exact #84 → #85 engineering artifact drift
Compared certified #84 final artifact with successful #85 corrected engineering artifact.

Raw data:
- exactly one semantic difference;
- `iron_barbs.classification: DATA_ONLY → PARTIAL_RUNTIME`.

Normalized data:
- exactly the same single classification change.

Explicitly unchanged:
- Rough Skin record, including classification and prose;
- every other ability;
- species/Pokémon;
- moves/effect specs;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest;
- forms policy;
- auxiliary report.

`unsupported_mechanics.json` set changes:
- RUNTIME_SUPPORTED remains **13**;
- PARTIAL_RUNTIME **9 → 10**, adding only `iron_barbs`;
- DATA_ONLY **351 → 350**, removing only `iron_barbs`;
- total/data-ready remains 373.

`pokeapi_v3_audit.json` changes exactly two ability count values:
- `PARTIAL_RUNTIME: 9 → 10`;
- `DATA_ONLY: 351 → 350`;
- RUNTIME_SUPPORTED remains 13.

`import_time_ms` **503 → 395 ms** is non-semantic execution timing noise.

## Coverage after #85 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **350**
- total: **373**.

## Final certification procedure
After syncing this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md`:
1. compare corrected engineering SHA `146285fc4e85c0d50036c12454af641c2ebf4aa5` to final HEAD;
2. require only notebook changes (`01`, `04`, `15`);
3. require **18/18 SUCCESS** on that exact notebook-bearing HEAD;
4. close PR #85 without merge;
5. use that exact final HEAD as the next certified baseline.

## Next bounded work after #85 closure
Remain in DATA FOUNDATION V3 ability reliability and select another small subgroup from the remaining 350 DATA_ONLY records only after source-vs-runtime comparison.

Do not:
- upgrade Iron Barbs until contact retaliation is per-strike and faint-safe with deliberate KO ordering;
- promote Rough Skin until version-aware ability semantics exist;
- alter generic AFTER_DAMAGE policy merely to increase coverage;
- return to Trainer AI/archetypes yet.
