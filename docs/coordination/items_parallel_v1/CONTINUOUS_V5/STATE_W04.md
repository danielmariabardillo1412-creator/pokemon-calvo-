# IA4/W04 — CONTINUOUS V5 · FASE B / CORRECCIÓN EN CI

- worker: W04
- branch: `codex/calvo-items-20261111-w04-regional-level-v5`
- source_v4_staging: `codex/calvo-ia6-staging-20261111-w04-evolution` (intacta)
- source_v4_ci: #42965322073 SUCCESS code `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`
- V5 mission: 10 level_up records with conditions empty
- phase_A_red_ci: **#43071438217 FAILED AS EXPECTED** code `329c26f1ce5da6221a0ea1445db6f1a300eb4a09`
- phase_A_result: **20/20 authentic EVOLUTION_AVAILABLE** from ProgressionSystem.gain_experience, 20/20 SaveV2 persisted, 420 checks, 12 expected failures: form_id lost on six regional destination species in both Party/Storage. Four target independent species must remain with form_id empty.
- phase_B_helper_sha: `24b21931f258e6469f59c2be4159a133180f1c1d`
- phase_B_functional_sha: `cae266e57090336c0d5853b6dacc9f6d47b329b7`
- phase_B_status: correction in EvolutionSystem.apply_evolution with exact route contract; **CI not yet verified**.
- V5_L3_service: not certified pending green; **integration/game UI: not certified**
- conditional: six other level_up with real conditions remain DATA_ONLY; trade/special untouched
- objects_new: 0
- dynamax_candy: excluded, do not alter
- protected: XP global, UI, SaveV2, FieldItemService, PlayerCollection, W02 effective_nature, V4 staging, main/V28/PR118 and IA6 official untouched
- next_safe_action: inspect latest V5 workflow of functional SHA; repair specific failures; then improve negative route tests and V4 regressions, document L2 vs L3 service vs integration.
