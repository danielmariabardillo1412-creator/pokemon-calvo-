# DATA V3 ABILITY EXISTING PRIMITIVES — V1

## Purpose
Operational checkpoint for the bounded ability-reliability tranche following certified PR #87.

## Certified parent
- PR #87: `DATA V3 — audit conditional offensive stat abilities`.
- Certified final HEAD: `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **18 RUNTIME_SUPPORTED / 12 PARTIAL_RUNTIME / 343 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-existing-primitives-v1`.
- Exact parent: certified #87 final `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`.

## Source-first candidate audit
Bounded candidate set:
- `water_bubble`;
- `dry_skin`;
- `gorilla_tactics`;
- `steely_spirit`.

Current decisions from immutable source:
- `water_bubble`: candidate **PARTIAL_RUNTIME**. Source gives exact Water x2 outgoing and Fire x0.5 incoming values; burn immunity/immediate cure is not currently represented.
- `dry_skin`: candidate **PARTIAL_RUNTIME**. Source gives exact Fire incoming x1.25 value; weather transactions and Water absorption/heal are not currently represented.
- `gorilla_tactics`: remains **DATA_ONLY**. Pinned source says Attack is boosted and the first selected move is locked, but does not encode a numeric boost value. Do not invent one.
- `steely_spirit`: remains **DATA_ONLY**. Pinned source says Steel moves of the holder/allies are powered up, but does not encode a numeric boost value. Do not invent one.

Source guards are being added for all four decisions so a future immutable-source change forces re-audit.

## Root-cause discovery — MODIFY_DAMAGE role isolation
Before registering Water Bubble, Battle Core inspection found a pre-existing semantic bug in `BattleTriggerSystem.damage_modifiers()`:
- actor-owned ability `MODIFY_DAMAGE` specs are evaluated in the actor loop;
- target-owned ability `MODIFY_DAMAGE` specs are evaluated again in the target loop;
- there is currently no explicit actor-vs-target role predicate.

Therefore any current final-damage `multiplier_bp` ability can be evaluated from the wrong side if its move predicate matches. Examples of the invalid possibility:
- an attacking Fur Coat holder can match the physical condition and reduce its own outgoing damage;
- a defending Blaze holder at low HP can match an incoming Fire move and increase damage received.

This is a root-cause correctness issue that predates the current candidates. Water Bubble would make it worse because it needs opposite-direction modifiers in the same ability.

### Required correction before candidate runtime registration
Introduce an explicit damage role contract for every ability `MODIFY_DAMAGE` spec:
- `damage_role = actor` for outgoing/offensive modifiers;
- `damage_role = target` for incoming/defensive modifiers and immunities.

`BattleTriggerSystem.damage_modifiers()` must reject a spec in the wrong loop. The default must not silently allow both directions.

Add real-battle regressions proving both directions are isolated, at minimum:
- offensive ability on defender does not change incoming damage;
- defensive ability on attacker does not change outgoing damage.

Only after this role isolation passes focal tests may Water Bubble / Dry Skin be registered.

## Scope rule after discovery
The tranche remains one coherent ability-damage semantics block:
1. fix the shared actor/target modifier-role bug;
2. pin role regressions for already-certified offensive/defensive abilities;
3. implement Water Bubble and Dry Skin only on the corrected role-aware surface;
4. keep Gorilla Tactics and Steely Spirit DATA_ONLY with source guards.

Do not add unrelated Battle Core mechanics (weather, burn immunity, Water absorption, move locking, ally boosts) in this tranche.

## General rules
1. immutable source first;
2. prefer existing trigger predicates and modifier channels;
3. fix root-cause correctness before expanding coverage;
4. partial support is acceptable only for an explicitly faithful subset;
5. source-required secondary mechanics must remain explicit blockers rather than being approximated;
6. do not reopen Guts/Hustle blockers from #87 in this tranche.

Closure protocol: source audit -> role isolation + focal regressions -> bounded candidate implementation -> 18/18 engineering -> exact artifact diff against #87 -> sync `01`, `04`, `18` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
