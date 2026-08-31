# DATA V3 ABILITY MOVE PROPERTIES — V1

## Purpose
Operational record for the bounded move-property ability tranche following certified PR #82.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the original 367-record family triage;
- `12_DATA_V3_ABILITY_DEFENSIVE_PREDICATES.md` for the immediately preceding certified tranche.

## Certified parent
- PR #82: `DATA V3 — audit defensive predicate abilities`.
- Certified final HEAD: `089140a8439390758d688636f715a311ec175163`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 5 PARTIAL_RUNTIME / 355 DATA_ONLY / 373 total**.

## PR #83
- Branch: `audit/data-v3-ability-move-property-v1`.
- Exact parent: certified #82 final `089140a8439390758d688636f715a311ec175163`.
- PR: #83 `DATA V3 — audit move-property ability contracts`.
- Engineering SHA: `f9d3538dec9c443e60070b0e4bf7d7904c984e55`.
- Engineering SHA: **18/18 SUCCESS**, including DATA Foundation V3 and Godot 4.7 global.

## Runtime metadata boundary
Current `MoveDefinition` retains core data including:
- power;
- type;
- damage class;
- priority;
- contact flag;
- executable `effect_specs`;
- accuracy/PP/target and related battle metadata.

It does **not** retain generic punch/bite/pulse/slicing flags. This tranche does not infer those categories from move names, Spanish/English labels, effect prose, or hand-maintained move allowlists.

## Source decisions

### Reckless — PARTIAL_RUNTIME
Pinned immutable source:
- `data/api/v2/ability/120/index.json`;
- main-series Generation IV;
- recoil moves **and crash moves** receive 1.2x base power;
- Struggle is unaffected;
- source explicitly names Jump Kick / High Jump Kick as crash moves;
- `effect_changes=[]`.

Current DATA V3 has a trustworthy structured subset:
- ordinary recoil moves expose `BattleEffectSpec.RECOIL` in `move.effect_specs`;
- examples include Double-Edge, Take Down, Brave Bird, Flare Blitz, Head Smash, Wild Charge, Volt Tackle and Wood Hammer;
- Struggle has no structured RECOIL effect, which correctly keeps it outside this subset;
- Jump Kick and High Jump Kick currently have no structured crash/recoil transaction even though their prose describes crash-on-miss behavior.

Decision: **`reckless → PARTIAL_RUNTIME`**.

Faithful executable subset:
- actor-side `MODIFY_DAMAGE`;
- `requires_recoil=true`;
- `multiplier_bp=12000`.

Missing source-required subset:
- crash moves such as Jump Kick / High Jump Kick.

Do not upgrade Reckless to RUNTIME_SUPPORTED until crash-on-miss is represented structurally and the same property contract can classify those moves safely.

### Long Reach — remains DATA_ONLY
Pinned immutable source:
- `data/api/v2/ability/203/index.json`;
- main-series Generation VII;
- moves used by the owner do not make contact;
- `effect_changes=[]`.

The mechanic itself is clean, but the current generic trigger API is not owner-context complete for this use case:
- defender-owned `AFTER_DAMAGE` contact reactions such as Static call `conditions_met(spec, owner, move)`;
- there, `owner` is the defender/ability owner;
- the attacking creature is not available to the condition evaluator;
- therefore the evaluator cannot safely determine that the move user has Long Reach.

Decision: **remain DATA_ONLY**.

Rejected shortcuts:
- no hidden `if attacker.ability_id == long_reach` special-case in Static/contact code;
- no mutation of canonical `MoveDefinition.makes_contact`;
- no broad trigger-context API expansion solely to increase one coverage number.

Long Reach can be revisited when effective-contact semantics have an explicit shared context contract.

### Technician — remains DATA_ONLY
Pinned immutable source:
- `data/api/v2/ability/101/index.json`;
- main-series Generation IV;
- 1.5x power for moves whose relevant power is 60 or less;
- explicitly covers variable-power moves when their resolved power is <=60;
- Helping Hand / Defense Curl ordering/interactions matter;
- historical `effect_changes` exist and are source-guarded.

Current DATA V3 already contains runtime-supported moves whose static `power` field is not the whole power transaction, e.g. variable/stateful families such as Hidden Power, Rollout, Eruption/Water Spout, Triple Kick and Stored Power.

Decision: **remain DATA_ONLY**. A simple `move.power <= 60` predicate is known to be semantically false in current runtime space and is therefore not an acceptable partial implementation.

### Iron Fist / Strong Jaw / Mega Launcher / Sharpness — remain DATA_ONLY
These mechanics depend on explicit move-property categories:
- Iron Fist: punch-based flag;
- Strong Jaw: biting flag;
- Mega Launcher: aura/pulse flag;
- Sharpness: slicing flag.

Current `MoveDefinition` does not retain those tags. Do not infer them from move names or prose. These abilities stay DATA_ONLY until the move data contract gains provenance-backed structural tags.

## Battle Core change
`modules/battle/effects/battle_trigger_system.gd` gains one generic condition:

`requires_recoil=true`

Its implementation is structural:
1. inspect `move.effect_specs`;
2. recursively inspect child specs;
3. match only `BattleEffectSpec.RECOIL`;
4. never inspect move names or descriptions.

`modules/battle/effects/battle_effect_registry.gd` registers Reckless as:
- trigger: `MODIFY_DAMAGE`;
- source: ability `reckless`;
- effect: DAMAGE modifier;
- conditions: `requires_recoil=true`, `multiplier_bp=12000`.

No new trigger kind, crash mechanic, move-property tag, name heuristic or context-plumbing change was introduced.

## Source-contract layer
`tools/pokeapi_ability_runtime_contracts.py`:
- classifies `reckless` as PARTIAL_RUNTIME;
- fail-fast validates its Gen IV source, recoil/crash 1.2x semantics, Struggle exclusion, and Jump Kick / High Jump Kick wording;
- adds source guards for Long Reach and Technician while keeping both DATA_ONLY;
- Technician guard also requires the expected historical semantics so source drift cannot silently invalidate the blocker rationale.

## Exact contract tests
`tests/data/data_foundation_v3_ability_runtime_contract_test_suite.gd` now requires:
- 13 exact RUNTIME_SUPPORTED IDs;
- 6 exact PARTIAL_RUNTIME IDs;
- 354 DATA_ONLY;
- exact 373 partition;
- Reckless one-spec runtime contract with `requires_recoil=true` and 12000 bp;
- Long Reach, Technician, Iron Fist, Strong Jaw, Mega Launcher and Sharpness remain DATA_ONLY with no runtime mappings.

`tests/data/data_foundation_v3_ability_family_inventory_test_suite.gd` adds only `reckless` to the explicit post-#76 promotion allowlist. The original 367-record family partition remains unchanged and still prevents mass promotion.

## Real-battle focal tests
New suite:
`tests/data/data_foundation_v3_ability_move_property_test_suite.gd`

It is run by the DATA V3 domain runner and verifies:

### Structured metadata boundary
- canonical Double-Edge contains structured RECOIL;
- Tackle does not;
- Jump Kick does not.

### Double-Edge positive path
Matched seed/state with and without Reckless:
- Reckless Double-Edge deals more target damage;
- `ABILITY_TRIGGERED` is emitted for attacker-owned Reckless;
- recoil still occurs normally;
- increased outgoing damage feeds the existing recoil transaction rather than replacing it.

### Tackle negative path
Matched seed/state:
- target damage is identical with and without Reckless;
- no Reckless trigger is emitted.

### Jump Kick explicit partial boundary
The suite finds a deterministic seed where canonical Jump Kick lands, then compares the same seed with and without Reckless:
- damage remains identical;
- no Reckless trigger fires.

This is intentionally a regression for the **known missing crash subset**, not an assertion that Pokémon source mechanics omit the boost.

## Engineering certification
Engineering SHA:
`f9d3538dec9c443e60070b0e4bf7d7904c984e55`

Result: **18/18 SUCCESS**.

DATA Foundation V3 completed successfully through:
- immutable source audit;
- regeneration;
- raw invariants;
- Godot import;
- full domain tests including the new move-property suite;
- normalization;
- Spanish/type/runtime regression;
- artifact upload.

Godot 4.7 global and all trainer workflows also passed.

## Exact #82 → #83 engineering artifact drift
Compared certified #82 final DATA V3 artifact with successful #83 engineering artifact.

Raw data:
- exactly one semantic difference;
- `reckless.classification: DATA_ONLY → PARTIAL_RUNTIME`.

Normalized data:
- exactly the same single classification change.

Explicitly unchanged ability records:
- Long Reach;
- Technician;
- Iron Fist;
- Strong Jaw;
- Mega Launcher;
- Sharpness;
- every other ability.

`unsupported_mechanics.json`:
- RUNTIME_SUPPORTED remains **13**;
- PARTIAL_RUNTIME **5 → 6**, adding only `reckless`;
- DATA_ONLY **355 → 354**, removing only `reckless`;
- total/data-ready remains 373.

`pokeapi_v3_audit.json` changes exactly two ability count values:
- `PARTIAL_RUNTIME: 5 → 6`;
- `DATA_ONLY: 355 → 354`;
- RUNTIME_SUPPORTED remains 13.

Explicitly unchanged domains/reports:
- species/Pokémon;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest;
- forms policy;
- auxiliary report.

`import_time_ms` 396→398 ms is non-semantic execution timing noise.

## Coverage after #83 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **6** — `heatproof`, `intimidate`, `levitate`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **354**
- total: **373**.

## Final certification procedure
After syncing this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md`:
1. compare engineering SHA `f9d3538dec9c443e60070b0e4bf7d7904c984e55` to final HEAD;
2. require only notebook changes (`01`, `04`, `13`);
3. require **18/18 SUCCESS** on that exact notebook-bearing HEAD;
4. close PR #83 without merge;
5. use that exact final HEAD as the next certified baseline.

## Next bounded work after #83 closure
Remain in DATA FOUNDATION V3 ability reliability. Select another small family from the remaining 354 DATA_ONLY records only after comparing source requirements with current Battle Core primitives.

Do not:
- upgrade Reckless until crash mechanics are structured;
- implement Long Reach with a hidden ability special-case;
- implement Technician with a static-power shortcut;
- infer punch/bite/pulse/slicing flags from names or prose;
- return to Trainer AI/archetypes yet.
