# W04 — CONTINUOUS_V4 · READY_FOR_IA6_MERGE_CANDIDATE (2026-11-11)

- worker: W04
- branch: `codex/calvo-ia6-staging-20261111-w04-evolution`
- base_IA6_sha: `e63b2e6c7e175fba318cc2f562bebd1769589092`
- mission_version: `CONTINUOUS_V4/PLAN_W04.md`
- phase: **A/B completed, C staging-specific QA completed; historic CAMP003–006 cross-suite remains central**
- current_status: **READY_FOR_IA6_MERGE_CANDIDATE** (NOT merged, NOT global integration certified)
- last_green_code_sha: `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`
- last_green_run_id: **42965322073**
- last_green_result: **completed / SUCCESS**
- source_V3_green: `db24e6f38943e5782b0d028b2d6553267adecd6f` / #42959076143
- objects_new: **0**
- actual_L3_regional_routes_staging: **7/7**
- ownership_cases: **14/14**, Party/Storage
- QA: **396 checks** (W02 effective nature+stats, IV/EV/PP, SaveV2, inactive session, wrong item/source/target, one-item consumption, id, 2/2 forced atomic rollback)
- regional_encounters: **55/56** certified, Exeggutor Alola still blocked
- historical_staging: V2 pilot PASS, V3 regional forms PASS, V4 normal abilities PASS, V5 Galarica PASS, V2 L2/B03 PASS
- excluded: **dynamax_candy** verified excluded via staged CI
- historical_CAMP003_006_on_staging: **NOT RUN** because dependency files absent from base; source CI green is not stage CI
- visual_bag_on_staging: **NOT RUN**
- integrated_official_IA6: **NO**
- files: `CreatureInstance.form_id` optional, W02 effective_nature untouched, `CreatureFactory.create` canonical form+normal ability, `EvolutionSystem.apply_evolution` canonical target+effective nature stats, `FieldItemService.evolution_options/evolve`, structural/native SaveV2 form guard, W04 helpers/tests/workflow
- final_report: `docs/coordination/items_parallel_v1/reports/W04/CONTINUOUS_V4_STAGING_FINAL.md`
- next_safe_action: IA6 review source-to-staging hunks, run CAMP003–006 and full W02/W03/W05 integration/visual FieldItemBag CI in its OWN official integration branch; do not merge blindly.
- stop_reason: all independent V4 work possible on isolated staging completed; remaining gates are integration-owner scope, not permission to invent another W04 mission

**Evidence rule:** the completed CI #42965322073 validates exactly `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`; later documentation SHA `c43a37b258708fb1510397a32b4b38b695a10722` and this checkpoint SHA are not separately certified by that code run.
