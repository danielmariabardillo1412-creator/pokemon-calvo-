# IA3/W03 — CONTINUOUS_V7 · FASE A avanzada / helper B aislado (2026-11-12)

- branch: `codex/calvo-items-20261112-w03-black-white-flutes-v7`
- prior V6: Dusk cave staging L3 1/1 CI #43125138000; **not official IA6-integrated**.
- current V7: **0/2 L3**, no verified native use or end-to-end effect.
- code commits: helper `932b9251`; isolated test script `27d04f95`.
- CI V7: **NOT RUN / no CI claimed**.
- source trace: native bridge `on_step(position)` -> `field_note_native_step` -> `field_prepare_native_encounter(zone)` -> held-item `EncounterItemModifiers.prepare_table` -> `WildEncounterSystem.resolve`. The latter uses `table.encounter_chance_bp` (integer 0..10000) for exactly one conditional RNG roll; chance 0 and 10000 avoid that chance roll per existing semantics; Repel rejection occurs after encounter resolution.
- copy contract: `WildEncounterTable.from_dict(table.to_dict())` and `validate()` already used by `EncounterItemModifiers`; **never mutate** registered authored tables, species/weights or RNG.
- field snapshots: save `position`, `region`, `config`, RNG state, next_seed, format, repel. Map ID not found in native snapshot. Existing `technical_overworld.gd::_on_transition_finished` reports `destination_region_id`; a region is not a unique map ID. Do not claim lifetime until real **map** boundary is available.
- new **isolated, opt-in, unwired** `modules/overworld/field_flute_encounter_rate_v7.gd` implements: `calvo_flutes_classic_encounter_rate_v1`; Black ×0.5, White ×1.5, cap 10000; mutual replacement; no global activation; copy-only table modification; strict state validation and restore. No bag connection or world snapshot yet.
- new isolated script `tests/gameplay/parallel_items_w03_flute_rate_v7.gd` checks rates, mutual replacement, profile guard, bounds and malformed state; **created but NOT EXECUTED**. It does not constitute an authentic step RED or L3.
- RED proof status: source-level absence of bag dispatcher found; executable original baseline RED **NOT RUN**. Must still run native bag/steps RED before declaring Phase A complete.
- no modifications to `field_demo.gd`, `field_item_bag.gd`, `field_native_bridge.gd`, SaveV2 infrastructure, Repel or Dusk production. Zero functional item certifications, zero new item IDs.

## Next p, ordered
1. Execute isolated Godot test and inspect exact output; fix only actual errors.
2. Add authentic native bag + physical grass/cave step RED test against unpatched wiring, with fixed seeds.
3. Wire minimal `field_item_bag.gd` and `field_demo.gd` hunks only once RED and guard checks exist; no automatic item consumption, no second RNG.
4. Validate SaveV2 legacy/corrupt and coexistence with Repel/MT/Rope and capture regression. Lack of reliable map-change producer => `L2_CONTEXT_ONLY/map-transition-pending`, never claim 2/2 L3.
5. Strict CI and evidence on exact SHA; selective IA6 integration later.

Protected: main, V28, PR118, arbiter integration, other W branches, dynamax_candy exclusion.
