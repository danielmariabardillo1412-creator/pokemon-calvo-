# DATA V3 ABILITY DAMAGE ROLES + EXISTING PRIMITIVES — V1

## Purpose
Operational record for the bounded DATA V3 ability-reliability tranche following certified PR #87.

## Certified parent
- PR #87: `DATA V3 — audit conditional offensive stat abilities`.
- Certified final HEAD: `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **18 RUNTIME_SUPPORTED / 12 PARTIAL_RUNTIME / 343 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-existing-primitives-v1`.
- PR: #88 `DATA V3 — isolate damage modifier roles and audit compound abilities`.
- Exact parent: certified #87 final `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`.
- Engineering SHA: `15543135b42254c8d475db9d3eeb36503a674b6c`.
- Engineering certification: **18/18 workflows SUCCESS**.
- DATA V3 domain: **499 PASS / 0 FAIL**.

## Root-cause discovery — MODIFY_DAMAGE role leakage
Before registering Water Bubble, inspection of `BattleTriggerSystem.damage_modifiers()` exposed a pre-existing correctness bug:
- all actor-owned ability `MODIFY_DAMAGE` specs were evaluated in the actor loop;
- all target-owned ability `MODIFY_DAMAGE` specs were also evaluated in the target loop;
- specs had no explicit actor-vs-target role contract.

Therefore a modifier could run from the wrong side whenever its ordinary predicates matched. Concrete invalid possibilities included:
- an attacking Fur Coat holder reducing its own physical outgoing damage;
- a low-HP defending Blaze holder amplifying an incoming Fire move.

Water Bubble made the flaw impossible to ignore because the same ability needs an outgoing Water modifier and an incoming Fire modifier with opposite directions.

## Root-cause fix — explicit fail-safe damage roles
`BattleTriggerSystem` now requires every ability `MODIFY_DAMAGE` spec to declare one of:
- `damage_role = actor` — outgoing/offensive modifier;
- `damage_role = target` — incoming/defensive modifier or immunity.

The actor loop accepts only actor-role specs. The target loop accepts only target-role specs.

A missing/unknown role is **inert**, not implicitly bidirectional. This is deliberate fail-safe behavior: a future registration that forgets its role should fail tests rather than silently modify damage from both sides.

All pre-existing ability `MODIFY_DAMAGE` registrations were tagged explicitly:
- actor: pinch boosts, unconditional type boosts, Huge/Pure Power, Toxic/Flare Boost, Defeatist, Guts, Hustle, Tough Claws, Reckless;
- target: Fur Coat, Thick Fat, Ice Scales, Multiscale, Heatproof, Levitate.

## Role regressions
New real-battle suite `DataFoundationV3AbilityDamageRoleTestSuite` pins the root fix:
- defender Blaze at low HP receiving Ember is identical to a no-ability defender and emits no Blaze trigger;
- attacker Fur Coat using Tackle is identical to a no-ability attacker and emits no Fur Coat trigger;
- every implemented ability `MODIFY_DAMAGE` spec has explicit `actor` or `target` role.

These tests prove the correction rather than merely checking registry dictionaries.

## Source-first candidate decisions
### Water Bubble — PARTIAL_RUNTIME
Pinned immutable source:
- main-series Generation VII;
- holder's outgoing Water move power is doubled;
- incoming Fire move damage is halved;
- holder cannot be burned and an acquired burn is immediately cured;
- `effect_changes=[]`.

Faithful runtime subset:
- actor-role Water `multiplier_bp=20000`;
- target-role Fire `multiplier_bp=5000`.

Real-battle tests prove:
- outgoing Water damage increases;
- incoming Fire damage decreases;
- actor Fire and target Water opposite-role cases remain inert;
- both correct sides emit the Water Bubble trigger.

Explicit missing mechanic:
- burn prevention / immediate cure. A Will-O-Wisp regression deliberately proves the holder is still burned and Water Bubble does not claim that behavior.

Decision: **`water_bubble → PARTIAL_RUNTIME`**.

### Dry Skin — PARTIAL_RUNTIME
Pinned immutable source:
- main-series Generation IV;
- strong sun: 1/8 max-HP damage each turn;
- rain: heals 1/8 max HP each turn;
- incoming Fire damage x1.25;
- incoming Water is absorbed and heals 1/4 max HP instead;
- `effect_changes=[]`.

Faithful runtime subset:
- target-role Fire `multiplier_bp=12500`.

Real-battle tests prove:
- incoming Fire damage is increased;
- Dry Skin on the attacker does not strengthen its own Fire move;
- incoming Water still deals ordinary positive damage and emits no Dry Skin trigger, pinning the absorption/heal gap.

Explicit missing mechanics:
- sun damage;
- rain healing;
- Water immunity/absorption + heal.

Decision: **`dry_skin → PARTIAL_RUNTIME`**.

### Gorilla Tactics — DATA_ONLY
Pinned Generation VIII source says the ability boosts Attack and restricts the holder to the first selected move, but the immutable effect text contains **no numeric boost value**.

No multiplier is imported from memory or an external mechanics source into canonical DATA V3.

A source guard now requires the known prose and fails if the snapshot later gains a numeric value, forcing explicit re-audit.

Decision: **remain `DATA_ONLY`**.

### Steely Spirit — DATA_ONLY
Pinned Generation VIII source says it powers up Steel-type moves of the holder/allies, but the immutable effect text contains **no numeric boost value**.

No multiplier is invented. A source guard forces re-audit if numeric provenance appears later.

Decision: **remain `DATA_ONLY`**.

## Architecture boundary
The only new Battle Core semantic in #88 is **role isolation for the existing damage-modifier abstraction**. It repairs a shared correctness defect rather than adding a mechanic solely for coverage.

Explicitly not added:
- weather;
- Water absorption/healing;
- burn immunity/cure;
- move locking;
- ally damage boosts;
- Guts/Hustle missing mechanics;
- Trainer AI/archetype work.

## Engineering certification
Engineering SHA:
`15543135b42254c8d475db9d3eeb36503a674b6c`

Result:
- **18/18 workflows SUCCESS**;
- DATA Foundation V3: **499 PASS / 0 FAIL**;
- Godot global: SUCCESS;
- all role regressions and compound-ability focal tests passed.

## Exact artifact drift — certified #87 final → #88 engineering
Both workflow artifacts contain the same 15 expected files.

Raw `pokemon_api.json`:
- exactly `dry_skin.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- exactly `water_bubble.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- no other raw semantic change.

Normalized dataset:
- exactly the same two one-field classification changes;
- no other normalized semantic change.

`unsupported_mechanics.json` set-level change:
- PARTIAL_RUNTIME adds exactly `dry_skin`, `water_bubble`;
- DATA_ONLY removes exactly `dry_skin`, `water_bubble`;
- RUNTIME_SUPPORTED set unchanged.

Counts:
- `RUNTIME_SUPPORTED`: **18 → 18**;
- `PARTIAL_RUNTIME`: **12 → 14**;
- `DATA_ONLY`: **343 → 341**;
- total remains **373**.

`pokeapi_v3_audit.json` changes only partial/data-only counts.

Explicitly unchanged:
- every other ability classification and metadata;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest;
- forms policy report;
- auxiliary report.

`import_time_ms 504 → 406 ms` is non-semantic execution timing noise.

## Ability coverage after #88 engineering
- `RUNTIME_SUPPORTED`: **18**.
- `PARTIAL_RUNTIME`: **14** — `dry_skin`, `flame_body`, `gooey`, `guts`, `heatproof`, `hustle`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`, `water_bubble`.
- `DATA_ONLY`: **341**.
- total: **373**.

## Important blockers after #88
New/confirmed:
- `water_bubble`: full support needs ability-aware burn prevention/immediate cure;
- `dry_skin`: full support needs weather end-turn transactions plus Water absorption/healing;
- `gorilla_tactics`: immutable source lacks numeric Attack boost; also needs move-lock behavior;
- `steely_spirit`: immutable source lacks numeric Steel boost; ally context is also absent.

Existing blockers remain explicit, including Guts burn/sleep, Hustle accuracy, contact faint/per-strike policy, version-sensitive Rough Skin/Transistor, move-property metadata and super-effective predicates.

## Final certification protocol
After engineering SHA `15543135b42254c8d475db9d3eeb36503a674b6c`:
1. synchronize only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, and this notebook `18`;
2. verify engineering → final HEAD changes only those three notebooks;
3. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
4. close PR #88 without merge;
5. use that exact final SHA as the next certified baseline.

Do not make a post-close commit solely to record PR closure; GitHub PR state is authoritative.

## Next work after #88 closure
Continue DATA FOUNDATION V3 ability reliability from the exact certified #88 final HEAD. Select a bounded source-first group from the remaining **341 DATA_ONLY** records. Prefer reuse of the now role-safe damage surface or a genuinely shared correctness primitive; a negative audit remains preferable to speculative mechanics.
