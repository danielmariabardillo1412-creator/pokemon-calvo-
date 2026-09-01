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

## Latest certified ability baseline — PR #83
Detailed notebooks: `06`, `07`, `08`, `09`, `10`, `11`, `12`, `13`.

Certified #83 coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **6** — `heatproof`, `intimidate`, `levitate`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **354**
- total: **373**.

# Current tranche — PR #84 Defender contact reactions
- Branch: `audit/data-v3-ability-contact-reactions-v1`.
- Exact parent: certified #83 final `f4a1f76850d8737c4d9847045335e703d5ecaa23`.
- PR: #84 `DATA V3 — audit defender contact reaction abilities`.
- Engineering SHA: `27a9d2b429334ea6f809009de219bb3fce0bb813`.
- Engineering SHA: **18/18 SUCCESS**.
- DATA V3 domain: **451 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/14_DATA_V3_ABILITY_CONTACT_REACTIONS.md`.

## #84 decisions
### Flame Body
Pinned Generation III source: contacting move user has 30% chance to be burned. Historical `effect_changes` is overworld-only.

Runtime subset:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- 30% CHANCE -> burn attacker.

Decision: **PARTIAL_RUNTIME**.

### Poison Point
Pinned Generation III source: contacting move user has 30% chance to be poisoned; no effect history.

Runtime subset:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- 30% CHANCE -> poison attacker.

Decision: **PARTIAL_RUNTIME**.

### Gooey
Pinned Generation VI source: lowers attacking Pokémon's Speed one stage on contact; no effect history.

Runtime subset:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- attacker Speed stage `-1`.

Decision: **PARTIAL_RUNTIME**.

## Shared #84 partial boundary
No generic Battle Core code changed in #84. All three reuse the same machinery already used by Static.

Current limitations:
- defender `AFTER_DAMAGE` is requested only when positive damage was dealt and the defender survives;
- knocked-out trigger owners are rejected;
- multi-hit strikes are resolved before the single defender `AFTER_DAMAGE` request.

Therefore fatal-contact and per-strike contact-reaction semantics remain incomplete. A real-battle regression explicitly verifies a 1-HP Gooey holder is KO'd by contact and does not react.

## #84 real-battle coverage
New `DataFoundationV3AbilityContactReactionTestSuite` verifies:
- Tackle contact vs Water Gun non-contact metadata;
- Flame Body real 30% burn path using deterministic seed search;
- Poison Point real 30% poison path using deterministic seed search;
- both status abilities inert for Water Gun;
- Gooey Tackle lowers attacker Speed exactly one stage and emits defender-owned ability event;
- Gooey inert for Water Gun;
- fatal-contact missing behavior is explicit.

## #84 artifact drift
Certified #83 artifact → successful #84 engineering artifact:
- raw: exactly `flame_body`, `gooey`, `poison_point` classification changes `DATA_ONLY → PARTIAL_RUNTIME`;
- normalized: exactly the same three one-field changes;
- `RUNTIME_SUPPORTED`: remains **13**;
- `PARTIAL_RUNTIME`: **6 → 9**;
- `DATA_ONLY`: **354 → 351**;
- every other ability unchanged;
- species/Pokémon, moves/effects, items/statuses, learnsets/evolutions, types/stats, manifest/forms/auxiliary unchanged;
- `pokeapi_v3_audit.json` changes only partial 6→9 and data-only 354→351;
- `import_time_ms` 705→524 ms is non-semantic.

## Ability coverage after #84 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **9** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **351**
- total: **373**.

## Known blockers after #84
- `static`, `flame_body`, `poison_point`, `gooey`: full support needs a deliberate faint-safe/per-strike contact-reaction policy.
- `reckless`: full support needs structured crash-on-miss move semantics.
- `long_reach`: needs shared effective-contact context exposing the move user.
- `technician`: needs resolved/transactional move-power semantics, not static base-power approximation.
- `iron_fist`, `strong_jaw`, `mega_launcher`, `sharpness`: need provenance-backed move-property tags.
- `filter`, `solid_rock`: need shared super-effective/effectiveness predicate.
- `heatproof`: full support needs burn residual ability interaction.
- `fluffy`: needs modifier composition/event aggregation.
- `huge_power`, `pure_power`: need genuine offensive-stat multiplier abstraction.
- `transistor`: version-sensitive multiplier contract unresolved.
- `water_compaction`: requires Water-specific AFTER_DAMAGE predicate.
- `weak_armor`: requires dual stat transaction plus per-hit/version semantics.
- remaining contact family: Cute Charm needs gender/infatuation; Effect Spore needs mutually exclusive random statuses; Iron Barbs/Rough Skin need max-HP contact damage; Mummy/Wandering Spirit need ability replacement; Pickpocket needs item transfer; Poison Touch needs attacker-owned post-hit contact handling.

## Current certification step
Notebook synchronization follows engineering SHA `27a9d2b429334ea6f809009de219bb3fce0bb813`.

Before closing #84:
1. verify engineering → final HEAD changes only `01`, `04`, `14` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #84 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #84
Continue DATA FOUNDATION V3 ability reliability with one bounded compatible subgroup from the remaining 351 DATA_ONLY records. Do not mass-promote the rest of the contact family and do not return to Trainer AI/archetypes yet.
