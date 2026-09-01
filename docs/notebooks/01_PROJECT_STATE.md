# PROJECT STATE NOTEBOOK

## Purpose / authority
Fast recovery for engineering work. GitHub commits, PR state, CI, immutable source and tested artifacts override this notebook on conflict.

## Certification policy
- Repo: `danielmariabardillo1412-creator/pokemon-calvo-`; Godot 4.7.
- Certified snapshots stay as closed PR branches **without merge**.
- New tranches start from the latest exact certified HEAD.
- Require all 18 normal workflows green on the same exact final SHA.
- Notebook commits move SHA, therefore the final notebook-bearing HEAD requires a second 18/18.
- Any focal/regression failure stops the tranche until root cause is fixed.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2`, `data/schema/v2` are read-only.

Structural facts: 1,025 species; 326 forms; 18 runtime types; 919 runtime moves; 373 abilities; 2,222 items; 61,102 learnset entries; 554 evolutions; 0 broken refs; 0 rejected defs; 18 XD Shadow moves explicitly excluded.

Pipeline:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Recent certified chain
- #75 final DATA_ONLY executable effects `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`
- #76 initial ability runtime contracts `a596a38680b60db317f1dfd6b6beb8d7ded7b813`
- #77 ability family inventory + Swarm `78da22438d0866193b0d1154814464531ac55641`
- #78 unconditional ability type boosts `eda483d9cd6423d32bdf1a156372416b2fbcb639`
- #79 hit-triggered stat reactions `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`
- #80 contact damage + attack-doubling audit `232a3e787fe2d7d58b1feb693272b63bd7a699bf`
- #81 defensive damage modifiers `e2eeef1d23def1d9fd124b5e2eeb437270212b68`
- #82 defensive predicates `089140a8439390758d688636f715a311ec175163`
- #83 move-property ability contracts `f4a1f76850d8737c4d9847045335e703d5ecaa23`
- #84 defender contact reactions `67c483899dadb2e3d1b5314a779d4c71b1bc8708`

All entries above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
Move coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- `DATA_ONLY` with executable `effect_specs`: **0**.

## Ability coverage principle
Preserved metadata is not executable support.
- `RUNTIME_SUPPORTED`: modeled battle mechanic is faithful.
- `PARTIAL_RUNTIME`: useful faithful subset works but known source-required behavior is absent.
- `DATA_ONLY`: data retained without claiming executable mechanics.

Battle Core ability execution is controlled by trigger registration; DATA V3 classification describes semantic completeness.

## Latest certified ability baseline — PR #84
Detailed notebooks: `06`, `07`, `08`, `09`, `10`, `11`, `12`, `13`, `14`.

Certified #84 coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **9** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **351**
- total: **373**.

# Current tranche — PR #85 Contact retaliation damage
- Branch: `audit/data-v3-ability-contact-damage-v1`.
- Exact parent: certified #84 final `67c483899dadb2e3d1b5314a779d4c71b1bc8708`.
- PR: #85 `DATA V3 — audit contact retaliation damage ability`.
- First candidate SHA `afe9f6fa558fffbd7347a2cca33a1c94dc5eec58`: DATA V3 domain **459 PASS / 2 FAIL**.
- Corrected engineering SHA: `146285fc4e85c0d50036c12454af641c2ebf4aa5`.
- Corrected engineering SHA: **18/18 SUCCESS**.
- Corrected DATA V3 domain: **461 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/15_DATA_V3_ABILITY_CONTACT_DAMAGE.md`.

## #85 decision — Iron Barbs
Pinned Generation V source requires the contacting move user to lose **1/8 of its own maximum HP**; `effect_changes=[]`.

Decision: **`iron_barbs → PARTIAL_RUNTIME`**.

New generic Battle Core effect:
- `BattleEffectSpec.MAX_HP_DAMAGE`;
- reuses existing `target + ratio_basis_points` fields;
- executor applies `maxi(1, recipient.max_hp * ratio / 10000)`;
- emits `DAMAGE_APPLIED` with `cause=max_hp_fraction`;
- round-trips through effect serialization.

Iron Barbs registration:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- `MAX_HP_DAMAGE` targeting attacker;
- `ratio_basis_points=1250`.

Exact supported subset:
- ordinary contact hit;
- defender survives;
- attacker loses floor(max HP / 8), minimum 1;
- retaliation can KO the attacker.

Partial boundary remains explicit:
- defender AFTER_DAMAGE is once after the completed move, not per multi-hit strike;
- defender AFTER_DAMAGE is not requested if the owner is KO'd by the hit;
- therefore per-strike and fatal-owner/double-KO semantics are absent.

## #85 decision — Rough Skin
Pinned Generation III current effect is also 1/8 attacker max HP, but source preserves a Diamond/Pearl historical battle value of **1/16**.

Decision: **remain DATA_ONLY**. Current ability contracts are not version-aware, so one universal 1/8 mapping would erase source-preserved semantics.

## #85 first CI failure and correction
The first candidate failed only two new assertions:
- contact-retaliation move metadata;
- multi-hit partial boundary.

Root cause: the test assumed `Double Kick` was contact. The generated DATA V3 artifact proves:
- Double Kick: RUNTIME_SUPPORTED, fixed 2-hit, **non-contact**;
- Double Slap: RUNTIME_SUPPORTED, **contact**, 2-5-hit MULTI_HIT.

Only the new focal test file changed after the failure. It now uses Double Slap plus deterministic landing-seed search.

Failed SHA → corrected engineering SHA:
- **1 commit**;
- **1 changed test file**;
- **zero runtime changes**.

Corrected result: **18/18 SUCCESS**, DATA V3 **461 PASS / 0 FAIL**.

## #85 artifact drift
Certified #84 artifact → successful #85 engineering artifact:
- raw: exactly `iron_barbs.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- normalized: exactly the same one-field change;
- Rough Skin identical and remains DATA_ONLY;
- every other ability unchanged;
- Pokémon/species, moves/effects, items/statuses, learnsets/evolutions, types/stats unchanged;
- manifest/forms/auxiliary unchanged;
- runtime remains **13**;
- partial **9 → 10**;
- data-only **351 → 350**;
- `pokeapi_v3_audit.json` changes only those two counts;
- `import_time_ms` 503→395 ms is non-semantic.

## Ability coverage after #85 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **350**
- total: **373**.

## Known blockers after #85 engineering
- `iron_barbs`: full support needs deliberate per-strike and faint-safe/double-KO ordering.
- `rough_skin`: needs version-aware ability semantics before its 1/16→1/8 history can be represented honestly.
- `static`, `flame_body`, `poison_point`, `gooey`: full support needs a deliberate faint-safe/per-strike contact-reaction policy.
- `reckless`: full support needs structured crash-on-miss move semantics.
- `long_reach`: needs shared effective-contact context exposing the move user.
- `technician`: needs resolved/transactional move-power semantics.
- `iron_fist`, `strong_jaw`, `mega_launcher`, `sharpness`: need provenance-backed move-property tags.
- `filter`, `solid_rock`: need shared super-effective/effectiveness predicate.
- `heatproof`: full support needs burn residual ability interaction.
- `fluffy`: needs modifier composition/event aggregation.
- `huge_power`, `pure_power`: need genuine offensive-stat multiplier abstraction.
- `transistor`: version-sensitive multiplier contract unresolved.
- `water_compaction`: requires Water-specific AFTER_DAMAGE predicate.
- `weak_armor`: requires dual stat transaction plus per-hit/version semantics.

## Current certification step
Notebook synchronization follows corrected engineering SHA `146285fc4e85c0d50036c12454af641c2ebf4aa5`.

Before closing #85:
1. verify engineering → final HEAD changes only `01`, `04`, `15` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #85 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #85
Continue DATA FOUNDATION V3 ability reliability with one bounded compatible subgroup from the remaining 350 DATA_ONLY records. Do not reopen Iron Barbs/Rough Skin blockers until their required shared semantics exist, and do not return to Trainer AI/archetypes yet.
