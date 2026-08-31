# DATA V3 ABILITY MOVE PROPERTIES — V1

## Purpose
Operational checkpoint for the bounded ability tranche following certified PR #82.

## Certified parent
- PR #82: `DATA V3 — audit defensive predicate abilities`.
- Certified final HEAD: `089140a8439390758d688636f715a311ec175163`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 5 PARTIAL_RUNTIME / 355 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-move-property-v1`.
- Exact parent: certified #82 final `089140a8439390758d688636f715a311ec175163`.
- Goal: audit a small move-property subgroup using metadata already present in `MoveDefinition`; do not add punch/bite/pulse/slicing tags merely to raise coverage.

## Runtime metadata boundary
Current `MoveDefinition` retains power, type, damage class, priority, contact, effect specs and related core metadata. It does **not** retain generic punch/bite/pulse/slicing tags.

## Source decisions before implementation

### Long Reach
Pinned immutable source `data/api/v2/ability/203/index.json`:
- main-series Generation VII;
- moves used by the owner do not make contact;
- `effect_changes=[]`.

Candidate decision: **RUNTIME_SUPPORTED** if the current contact predicate can be made owner-aware so a Long Reach attacker does not satisfy defender-side `requires_contact` triggers. No move record should be mutated.

### Reckless
Pinned immutable source `data/api/v2/ability/120/index.json`:
- main-series Generation IV;
- recoil **and crash** moves have 1.2x base power;
- Struggle is unaffected;
- `effect_changes=[]`.

Current structured move effects expose ordinary recoil via `BattleEffectSpec.RECOIL`, but crash-on-miss behavior for Jump Kick / High Jump Kick is not represented by that effect transaction.

Candidate decision: **PARTIAL_RUNTIME** for the faithful structured-recoil subset only. A `requires_recoil` predicate must key off structured effect specs, not prose. Crash moves remain an explicit missing semantic.

### Technician
Pinned immutable source `data/api/v2/ability/101/index.json`:
- main-series Generation IV;
- 1.5x power when effective/base power is 60 or less;
- explicitly includes variable-power moves when their resolved power is <=60;
- Helping Hand / Defense Curl interactions matter;
- historical effect changes exist.

Decision for this tranche: **remain DATA_ONLY**. A simple static `move.power <= 60` check is known false for variable-power and prior-power-modifier cases; do not add an unsafe executable approximation.

### Iron Fist / Strong Jaw / Mega Launcher / Sharpness
Decision for this tranche: **remain DATA_ONLY**. Their required punch/bite/pulse/slicing move-property tags are not retained in current runtime move definitions. Do not infer those categories from move names or descriptions.

## Intended minimal Battle Core changes
1. Contact condition evaluation becomes context-aware enough to treat contact as false when the attacking creature has `long_reach`; this must suppress existing contact-triggered reactions without mutating canonical move metadata.
2. Add a generic `requires_recoil` move predicate backed only by structured `BattleEffectSpec.RECOIL` presence.
3. Register Reckless as actor-side `MODIFY_DAMAGE`, `requires_recoil=true`, `multiplier_bp=12000`.
4. Long Reach itself needs no trigger registration if contact suppression is evaluated from the attacker's ability.

## Test requirements
- Long Reach: contact Tackle against Static must not trigger Static; same battle without Long Reach must preserve the contact reaction path.
- Long Reach must not change raw `makes_contact` metadata.
- Reckless: Double-Edge damage increases versus matched control and ability trigger fires.
- Reckless: Tackle unchanged and no trigger.
- Reckless: Jump Kick / High Jump Kick remain explicit unimplemented crash subset; no false Reckless trigger.
- Technician stays DATA_ONLY and has no runtime trigger.
- Iron Fist / Strong Jaw / Mega Launcher / Sharpness stay DATA_ONLY and no new move-property metadata is inferred.
- Preserve exact 373 partition and no mass promotion.

## Expected classification delta if focal tests pass
- `long_reach`: DATA_ONLY -> RUNTIME_SUPPORTED;
- `reckless`: DATA_ONLY -> PARTIAL_RUNTIME;
- RUNTIME_SUPPORTED: 13 -> 14;
- PARTIAL_RUNTIME: 5 -> 6;
- DATA_ONLY: 355 -> 353;
- total remains 373.

## Closure protocol
Focal tests -> 18/18 engineering SHA -> exact artifact diff against #82 -> notebook sync (`01`, `04`, `13`) -> 18/18 exact final notebook-bearing SHA -> close without merge.
