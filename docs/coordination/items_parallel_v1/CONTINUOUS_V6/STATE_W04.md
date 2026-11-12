# W04 — CONTINUOUS V6 · READY_FOR_IA6_MERGE_CONSUMER_CANDIDATE / STOP

- worker: W04
- branch: `codex/calvo-items-20261112-w04-evolution-consumer-v6`
- phase: **A causal reproduction, B consumer and UI, C CI/regressions completed**
- status: **READY_FOR_IA6_MERGE_CONSUMER_CANDIDATE** (**NOT merged**)
- certified_code_sha: **`1dd5bb05e987b75cedadeefa09c64925ff4cb35b`**
- certified_ci: **#43126697924 COMPLETED/SUCCESS** (Godot 4.7 headless + pinned Showdown)
- CI_link: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43126697924
- real_native_pilots: **2/2** (diglett_alola -> dugtrio_alola, meowth_galar -> perrserker)
- native_battle_ui_cases: **4/4** (2 routes x accept/decline) **66 checks**; signal-driven actual presentation, not mouse/GPU
- consumer_party_storage_cases: **8/8** (2 routes x Party/Storage x accept/decline), **135 checks**
- V5_level_routes_regression: **10/10**, **526 checks** PASS
- V4_item_routes_regression: **7/7**, **396 checks**, 14 owner cases, 2 rollback PASS
- regional_encounters: **55/56**, 968 checks, 1 blocked as before
- regional_ability_regression: **64 checks PASS**
- Python_canonical_inventory: 57 species, 28 evolution records, 10 plain level, 6 conditioned, 1 trade, 4 special PASS
- excluded: **dynamax_candy** PASS
- new_objects: **0**
- production_changes: new `modules/gameplay/w04_postbattle_evolution_consumer_v6.gd`, narrow hunks `scenes/visual/field_native_presentation.gd` and `scenes/visual/field_native_bridge.gd`, W04-only tests and workflow
- critical_negative: event/owner/target/level/Everstone/stale/duplicate refusal; decline unchanged; SaveV2 after decision; save/load/exit blocked during pending
- W04-V6-DEP-01: **W02 minted nature stat mismatch in native Showdown** (hardy->adamant), #43124774406; native pilot uses effective nature == natal; standalone consumer tests distinct mint PASS. Owner: IA6/W02/native integration.
- W04-V6-DEP-02: **graceful native worker close timed out after completed accepted evolution** in headless CI #43125581953; test cleanup uses existing `session.stop_now()`; **return-to-map not certified**. Owner: IA6/native owner.
- game_graphical_GPU_manual: **NOT RUN / NOT CERTIFIED**
- CAMP003_006_in_this_branch: **NOT RUN**, missing suites/dependencies in V6 base; IA6 central gate
- IA6_official_integration: **NO**
- main_V28_PR118_other_worker_branches: untouched
- final_report: `docs/coordination/items_parallel_v1/reports/W04/CONTINUOUS_V6_FINAL.md`
- next_safe_action: **IA6** selective integration of exact hunks, cross-worker QA, GPU UI, DEP-01/DEP-02. W04 STOP until new order.

**Evidence rule:** #43126697924 certifies exact code SHA `1dd5bb05e987b75cedadeefa09c64925ff4cb35b`. Subsequent report-only commit `98b863a9daabd42b722e51cdf063caf74771a0c6` and this state commit are not that certified code SHA; do not describe them as independently QA-validated.
