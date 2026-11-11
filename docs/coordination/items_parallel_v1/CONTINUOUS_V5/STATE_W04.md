# W04 — CONTINUOUS V5 · CHECKPOINT INICIAL (2026-11-11)
- worker: W04
- branch: codex/calvo-items-20261111-w04-regional-level-v5
- phase: A / DIAGNOSTICO_AUTENTICO, pendiente inicio
- mission_version: CONTINUOUS_V5/PLAN_W04.md
- source_delivered: V4 staging codex/calvo-ia6-staging-20261111-w04-evolution
- previous_green_ci: #42965322073 SUCCESS
- previous_green_code_sha: cdd53fb1d61a3aeb8790818aa571e13f9afbaed8
- source_V4_status: READY_FOR_IA6_MERGE_CANDIDATE, no integrada oficialmente
- new_V5_green_sha: ninguno
- new_V5_ci: PENDIENTE
- candidate_records: 10 unconditional level_up (of 16 level_up / 28 regional evolution records)
- validated_L3_V5: 0/10 (no confundir con 7/7 item evolutions V4)
- blocked_conditions: 6 conditional level_up + 1 trade + 4 special; no activar
- new_items: 0
- integration_IA6: NO
- next_safe_action: inventario de 10 registros y prueba roja con ProgressionSystem.gain_experience, EVOLUTION_AVAILABLE y apply_evolution, sin tocar XP global
- protected: no main, V28, PR118, IA6 integración, V4 entregada, ni ramas ajenas; preservar effective_nature_id y veto dynamax_candy

Una p reanuda A/B/C según plan; documentar cada gate con SHA + CI exactos; jamás inventar L3 si solo hay contrato aislado.
