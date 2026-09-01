# DATA V3 ABILITY CONTACT REACTIONS — V1

## Purpose
Operational record for the bounded defender-owned contact-reaction tranche following certified PR #83.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the original 367-record family triage;
- `13_DATA_V3_ABILITY_MOVE_PROPERTIES.md` for the immediately preceding certified tranche.

## Certified parent
- PR #83: `DATA V3 — audit move-property ability contracts`.
- Certified final HEAD: `f4a1f76850d8737c4d9847045335e703d5ecaa23`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 6 PARTIAL_RUNTIME / 354 DATA_ONLY / 373 total**.

## PR #84
- Branch: `audit/data-v3-ability-contact-reactions-v1`.
- Exact parent: certified #83 final `f4a1f76850d8737c4d9847045335e703d5ecaa23`.
- PR: #84 `DATA V3 — audit defender contact reaction abilities`.
- Engineering SHA: `27a9d2b429334ea6f809009de219bb3fce0bb813`.
- Engineering SHA: **18/18 SUCCESS**, including DATA Foundation V3 and Godot 4.7 global.

## Shared runtime boundary
All three promoted abilities reuse the already-certified defender-owned primitive:

`AFTER_DAMAGE + requires_contact`

No Battle Core trigger type, generic condition, status engine rule, damage formula or context plumbing was added.

The current trigger boundary remains intentionally visible:
- `TurnExecutor` requests defender `AFTER_DAMAGE` only when positive damage was dealt and the defender survives;
- `_execute_triggers` also rejects knocked-out owners;
- multi-hit damage is resolved internally before this defender `AFTER_DAMAGE` request, so the contact reaction is not evaluated separately for each strike.

Therefore the ordinary surviving-contact subset is useful and faithful, but fatal-hit/per-strike semantics are not complete. The three abilities are **PARTIAL_RUNTIME**, matching the same conservative principle already used for Static.

## Source decisions

### Flame Body — PARTIAL_RUNTIME
Pinned immutable source:
- `data/api/v2/ability/49/index.json`;
- main-series Generation III;
- when a move makes contact, the move user has a 30% chance to be burned;
- source also contains an overworld egg-hatching effect;
- `effect_changes` contains only the historical statement that the ability had no overworld effect.

The source-contract layer explicitly verifies that the historical change remains overworld-only and contains no changed battle tokens.

Runtime:
- trigger: `AFTER_DAMAGE`;
- owner: defender with Flame Body;
- condition: `requires_contact=true`;
- effect: 30% CHANCE -> `INFLICT_STATUS burn` on `OPPONENT` (the attacker).

Decision: **PARTIAL_RUNTIME** because fatal/per-strike contact semantics are absent.

### Poison Point — PARTIAL_RUNTIME
Pinned immutable source:
- `data/api/v2/ability/38/index.json`;
- main-series Generation III;
- contacting move user has a 30% chance to be poisoned;
- `effect_changes=[]`.

Runtime:
- trigger: `AFTER_DAMAGE`;
- `requires_contact=true`;
- 30% CHANCE -> `INFLICT_STATUS poison` on attacker.

Decision: **PARTIAL_RUNTIME** for the same shared trigger boundary.

### Gooey — PARTIAL_RUNTIME
Pinned immutable source:
- `data/api/v2/ability/183/index.json`;
- main-series Generation VI;
- lowers the attacking Pokémon's Speed by one stage on contact;
- `effect_changes=[]`.

Runtime:
- trigger: `AFTER_DAMAGE`;
- `requires_contact=true`;
- `MODIFY_STAT_STAGE` on opponent Speed by `-1`.

Decision: **PARTIAL_RUNTIME** for the same fatal/per-strike boundary.

## Runtime registration
`modules/battle/effects/battle_effect_registry.gd` adds only the three explicit ability specs above. Static remains unchanged. No generic Battle Core file outside the registry changed in this tranche.

## Source-contract layer
`tools/pokeapi_ability_runtime_contracts.py`:
- classifies `flame_body`, `poison_point`, `gooey` as PARTIAL_RUNTIME;
- validates exact generation/main-series/source tokens;
- validates Poison Point and Gooey have no effect history;
- validates Flame Body history remains overworld-only.

## Exact contract tests
`tests/data/data_foundation_v3_ability_runtime_contract_test_suite.gd` now requires:
- exact 13 RUNTIME_SUPPORTED IDs;
- exact 9 PARTIAL_RUNTIME IDs;
- exactly 351 DATA_ONLY;
- exact 373 partition;
- exact Flame Body / Poison Point `AFTER_DAMAGE + requires_contact + 3000bp CHANCE + correct status` contracts;
- exact Gooey `AFTER_DAMAGE + requires_contact + Speed -1` contract;
- exact implemented registry inventory.

`tests/data/data_foundation_v3_ability_family_inventory_test_suite.gd` adds exactly these three IDs to the explicit post-#76 promotion allowlist. The original 367-record family partition and 11-record contact-reactive inventory remain unchanged.

## Real-battle focal integration
New suite:
`tests/data/data_foundation_v3_ability_contact_reaction_test_suite.gd`

It verifies:
1. canonical Tackle is contact and Water Gun is non-contact;
2. deterministic seed search finds a real Tackle battle where Flame Body applies burn;
3. deterministic seed search finds a real Tackle battle where Poison Point applies poison;
4. Water Gun leaves Flame Body inert;
5. Water Gun leaves Poison Point inert;
6. Tackle against Gooey lowers attacker Speed exactly one stage and emits defender-owned `ABILITY_TRIGGERED`;
7. Water Gun leaves Gooey inert;
8. a Tackle against a 1-HP Gooey owner KOs the defender and produces no Gooey reaction, explicitly preserving the known partial boundary.

DATA V3 domain result on engineering SHA: **451 PASS / 0 FAIL**.

## Engineering certification
Engineering SHA:
`27a9d2b429334ea6f809009de219bb3fce0bb813`

Result: **18/18 SUCCESS**.

DATA Foundation V3 completed successfully through:
- immutable source audit;
- regeneration;
- raw invariants;
- Godot import;
- domain tests including the new contact-reaction suite;
- normalization;
- Spanish/type/runtime regression;
- artifact upload.

Godot 4.7 global and every trainer workflow also passed.

## Exact #83 -> #84 engineering artifact drift
Compared certified #83 final artifact with successful #84 engineering artifact.

Raw data — exactly three changed records:
- `flame_body.classification: DATA_ONLY -> PARTIAL_RUNTIME`;
- `gooey.classification: DATA_ONLY -> PARTIAL_RUNTIME`;
- `poison_point.classification: DATA_ONLY -> PARTIAL_RUNTIME`.

For all three, **classification is the only changed field**.

Normalized data contains exactly the same three classification-only changes.

`unsupported_mechanics.json`:
- RUNTIME_SUPPORTED remains **13**;
- PARTIAL_RUNTIME **6 -> 9**, adding exactly `flame_body`, `gooey`, `poison_point`;
- DATA_ONLY **354 -> 351**, removing exactly those same three IDs;
- total/data-ready remains 373.

`pokeapi_v3_audit.json` changes exactly two ability count values:
- `PARTIAL_RUNTIME: 6 -> 9`;
- `DATA_ONLY: 354 -> 351`;
- RUNTIME_SUPPORTED remains 13.

Explicitly unchanged:
- every other ability;
- species/Pokémon;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest;
- forms policy;
- auxiliary report.

`import_time_ms` 705 -> 524 ms is non-semantic execution timing noise.

## Coverage after #84 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **9** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **351**
- total: **373**.

## Final certification procedure
After syncing this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md`:
1. compare engineering SHA `27a9d2b429334ea6f809009de219bb3fce0bb813` to final HEAD;
2. require only notebook changes (`01`, `04`, `14`);
3. require **18/18 SUCCESS** on that exact notebook-bearing HEAD;
4. close PR #84 without merge;
5. use that exact final HEAD as the next certified baseline.

## Next bounded work after #84 closure
Remain in DATA FOUNDATION V3 ability reliability. The rest of the original contact-reactive family must not be mass-promoted:
- Cute Charm needs gender/infatuation semantics;
- Effect Spore needs a mutually exclusive random-status transaction;
- Iron Barbs / Rough Skin require contact damage based on the attacker's/owner's max-HP contract to be audited;
- Mummy / Wandering Spirit require ability replacement;
- Pickpocket requires held-item transfer;
- Poison Touch is attacker-owned and needs an attacker-side post-hit contact contract.

Select at most one small compatible subgroup next. Trainer AI/archetypes remain deferred.
