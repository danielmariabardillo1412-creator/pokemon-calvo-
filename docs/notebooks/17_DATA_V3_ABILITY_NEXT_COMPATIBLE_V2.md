# DATA V3 ABILITY NEXT COMPATIBLE — V2

## Purpose
Operational checkpoint for the bounded DATA FOUNDATION V3 ability-reliability tranche following certified PR #86.

## Certified parent
- PR #86: `DATA V3 — audit offensive stat ability modifiers`.
- Certified final HEAD: `06b078b02766ff2c85d5ca45798d8293b8c8e557`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **17 RUNTIME_SUPPORTED / 10 PARTIAL_RUNTIME / 346 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-next-compatible-v2`.
- Exact parent: certified #86 final `06b078b02766ff2c85d5ca45798d8293b8c8e557`.

Goal: audit a small source-first subgroup from the remaining 346 DATA_ONLY abilities. Promote only mechanics whose source-faithful semantics fit existing Battle Core abstractions cleanly, or justify one genuinely shared primitive across multiple abilities.

Rules:
1. immutable snapshot source first;
2. bounded scope: normally 2–4 candidates;
3. no keyword/family mass promotion;
4. negative audit is a valid result;
5. do not broaden Battle Core solely to increase coverage;
6. preserve actor/defender direction, calculation phase, trigger granularity and version history;
7. add real battle integration tests whenever timing/calculation placement matters.

Explicit blockers not to reopen in this tranche merely for coverage:
- Iron Barbs full support / Rough Skin version history;
- Static, Flame Body, Poison Point, Gooey fatal/per-strike contact policy;
- Water Compaction / Weak Armor;
- Transistor version-sensitive multiplier;
- Long Reach / Technician;
- Iron Fist / Strong Jaw / Mega Launcher / Sharpness move-category provenance;
- Filter / Solid Rock effectiveness predicate;
- Fluffy modifier composition/event aggregation;
- Heatproof burn residual;
- Reckless crash-on-miss semantics.

## Source-first candidate selection
The first bounded pass selected three DATA_ONLY abilities whose source mechanics line up with primitives already certified in Battle Core. No new trigger condition or effect primitive is justified by this selection.

### Defeatist
Pinned source: `data/api/v2/ability/129/index.json`.

Source contract:
- main-series;
- Generation V;
- Attack and Special Attack are halved at half HP or less;
- `effect_changes=[]`.

Existing primitives already cover the full numeric mechanic:
- `hp_at_or_below_divisor=2`;
- physical/special move predicates;
- `offensive_stat_multiplier_bp=5000`.

Provisional decision: **`defeatist -> RUNTIME_SUPPORTED`**.

Implementation direction: two mutually exclusive actor `MODIFY_DAMAGE` specs, one physical and one special, each applying the 5000-bp offensive-stat multiplier at HP <= 1/2. Do not model this as final-damage multiplication.

### Shadow Shield
Pinned source: `data/api/v2/ability/231/index.json`.

Source contract:
- main-series;
- Generation VII;
- while at full HP, regular move damage is halved;
- fixed damage is excluded by source wording;
- the ability cannot be nullified;
- `effect_changes=[]`.

Current Battle Core already has the exact ordinary-damage path used by Multiscale:
- defender `MODIFY_DAMAGE`;
- `requires_full_hp=true`;
- `multiplier_bp=5000`.

Current Battle Core does not yet implement an ability-nullification/suppression system, so the source clause `cannot be nullified` creates no observable mismatch in the current executable state. If nullification is later implemented, Shadow Shield must be re-audited and explicitly protected from it.

Provisional decision under the current runtime feature set: **`shadow_shield -> RUNTIME_SUPPORTED`**.

Required focal regression: ordinary move at full HP halves damage; missing HP is inert. Also preserve a source-contract guard for the non-nullifiable clause so a future engine feature cannot silently invalidate the classification.

### Tangling Hair
Pinned source: `data/api/v2/ability/221/index.json`.

Source contract:
- main-series;
- Generation VII;
- when the holder takes regular damage from a contact move, the attacker's Speed falls one stage;
- `effect_changes=[]`.

This matches the already-certified Gooey runtime transaction:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- `MODIFY_STAT_STAGE` on opponent Speed -1.

The same known AFTER_DAMAGE boundary therefore applies:
- current engine requests defender AFTER_DAMAGE only after positive damage and only while the defender remains alive;
- current multi-hit execution exposes AFTER_DAMAGE once per completed move, not once per strike.

Therefore ordinary surviving contact-hit behavior is faithful, but fatal-hit/per-strike behavior is incomplete.

Provisional decision: **`tangling_hair -> PARTIAL_RUNTIME`**.

Do not broaden generic AFTER_DAMAGE semantics in this tranche merely to upgrade Tangling Hair to full support.

## Candidate-group conclusion
This tranche currently needs **no new Battle Core primitive**. It should reuse:
- the #86 offensive-stat multiplier for Defeatist;
- the existing Multiscale full-HP damage reducer for Shadow Shield;
- the existing Gooey contact-reaction transaction for Tangling Hair.

Expected coverage if implementation and regression tests confirm the provisional decisions:
- RUNTIME_SUPPORTED: **19** (17 -> 19);
- PARTIAL_RUNTIME: **11** (10 -> 11);
- DATA_ONLY: **343** (346 -> 343);
- total: **373**.

Expected generated artifact drift from certified #86:
- only `defeatist`, `shadow_shield`, `tangling_hair` classifications change in raw/normalized;
- no species, move, item, learnset, evolution, type or stat drift.

## Next implementation block
1. add explicit source guards and classifications for the three candidates;
2. register only the existing trigger primitives described above;
3. extend exact runtime-contract and family-inventory allowlists;
4. add a small real-battle suite proving Defeatist's offensive-stat placement, Shadow Shield full-HP boundary, and Tangling Hair's surviving-contact subset plus fatal-hit partial boundary;
5. run the full 18-workflow engineering certification before notebook finalization.

Closure protocol:
source audit -> bounded decision -> implementation/tests only if justified -> 18/18 engineering -> exact artifact diff against #86 -> sync `01`, `04`, `17` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
