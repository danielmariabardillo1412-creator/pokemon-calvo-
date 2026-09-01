# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #84 — `audit/data-v3-ability-contact-reactions-v1`
- Final HEAD `67c483899dadb2e3d1b5314a779d4c71b1bc8708`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #84 ability coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **9** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **351**
- total: **373**.

Prior detailed ability notebooks: `06`, `07`, `08`, `09`, `10`, `11`, `12`, `13`, `14`.

# Current tranche — PR #85
- Branch: `audit/data-v3-ability-contact-damage-v1`
- Parent: certified #84 final `67c483899dadb2e3d1b5314a779d4c71b1bc8708`
- PR: #85 `DATA V3 — audit contact retaliation damage ability`
- First candidate `afe9f6fa558fffbd7347a2cca33a1c94dc5eec58`: DATA V3 **459 PASS / 2 FAIL**.
- Corrected engineering SHA: `146285fc4e85c0d50036c12454af641c2ebf4aa5`
- Corrected engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Corrected DATA V3 domain: **461 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/15_DATA_V3_ABILITY_CONTACT_DAMAGE.md`.

## #85 result
### Iron Barbs
Decision: **PARTIAL_RUNTIME**.

Pinned Gen V source: a contacting move user loses **1/8 of its own maximum HP**; no effect history.

Battle Core gains one generic effect primitive:
- `MAX_HP_DAMAGE`;
- uses the existing effect target and `ratio_basis_points`;
- applies `maxi(1, recipient.max_hp * ratio / 10000)`;
- emits fraction-damage metadata;
- serializes/deserializes normally.

Iron Barbs runtime:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- `MAX_HP_DAMAGE(OPPONENT, 1250bp)`.

Real-battle coverage verifies:
- Tackle removes exactly 30 HP from a 240-max-HP attacker;
- Water Gun is inert;
- retaliation can KO a low-HP attacker;
- a fatal hit on the Iron Barbs owner remains inert, explicitly documenting the faint-owner gap;
- a canonical contact multi-hit move triggers retaliation only once after the completed move, explicitly documenting the missing per-strike behavior.

### Rough Skin
Remains **DATA_ONLY**.

Its current source prose is 1/8 attacker max HP, but pinned history preserves a Diamond/Pearl **1/16** battle value. Runtime ability contracts are not version-aware, so do not copy Iron Barbs' universal 1/8 mapping onto Rough Skin.

## First CI failure — fixed at the test fixture
The initial focal test used Double Kick as the multi-hit contact control. The failed-run generated artifact proved Double Kick is structurally 2-hit but **non-contact** in canonical DATA V3.

Canonical replacement:
- `double_slap`: RUNTIME_SUPPORTED;
- contact;
- MULTI_HIT 2-5.

Only `data_foundation_v3_ability_contact_retaliation_test_suite.gd` changed between failed and corrected SHAs. Runtime/source-contract code did not change.

Corrected result: **18/18 SUCCESS**.

## Exact #84 → #85 artifact
Raw + normalized:
- exactly one semantic difference;
- `iron_barbs.classification: DATA_ONLY → PARTIAL_RUNTIME`.

Rough Skin is unchanged and remains DATA_ONLY.

Reports:
- runtime remains 13;
- partial 9→10, adding only Iron Barbs;
- data-only 351→350, removing only Iron Barbs;
- `pokeapi_v3_audit.json` changes only partial/data-only counts.

Explicitly unchanged:
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms` 503→395 ms is non-semantic.

## Ability coverage after #85 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **350**
- total: **373**.

## Current certification step
Notebook synchronization now moves the branch after corrected engineering SHA `146285fc4e85c0d50036c12454af641c2ebf4aa5`.

Before closing #85:
1. verify engineering SHA → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `15_DATA_V3_ABILITY_CONTACT_DAMAGE.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #85 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #85 closure
Continue **DATA FOUNDATION V3 ability reliability** with one bounded subgroup selected from the remaining 350 DATA_ONLY records only after comparing immutable source requirements with current Battle Core primitives.

Do not upgrade Iron Barbs until per-strike/faint-safe contact retaliation and KO ordering are deliberately modeled. Do not promote Rough Skin until version-aware ability semantics exist. Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
