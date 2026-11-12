# IA6 — 2026-11-12 · W01 QA cierre oficial y W04 V7 siguiente puerta

## W01 Casco Dentado — duplicación eliminada
- Oficial `codex/calvo-ia6-integration-20261109` HEAD `03a1d7352f3152af7a44ee3b28b61afd47dffd34` verificado identical.
- Test W01 original `tests/gameplay/w01_continuous_v4_camp003_rocky_helmet.gd` blob `62f41c2dbc6ec0ed45420a414318600ba03326f8` **ya integrado en oficial por operación concurrente**, no por PR #123/#124.
- CI oficial `IA6 Official W01 Rocky Helmet V27-safe cross-worker QA` #43140450107, job #130925876638 **completed/success**, 0 failed steps. W01 candidate histórico #43139064158 también green, pero su antiguo PR #123 falló Windows V27 porque divergía del PR #122 (12 expected-key failures). El error no demuestra fallo funcional Casco Dentado.
- PR #123 y #124 **cerrados sin fusionar**, con explicación en GitHub. #124 tenía solo un workflow redundante; se preservaron las ramas y no se duplicaron tests ni producción.

## W04 V7 — estado nuevo comprobado
- Rama trabajadora `codex/calvo-items-20261112-w04-battle-return-v7`, SHA código certificado `6d483b839ec57c674afc36acc508102f0df10fd5`.
- CI #43139645110 job 130923250260 **completed/success**.
- `CONTINUOUS_V7/STATE_W04.md` declara: 37 checks RETURN_TO_MAP_L3, 2 ciclos (Diglett Alola acepta / Meowth Galar rechaza), battle_closed=2, movimiento restaurado, guardado/carga SaveV2 tras retorno. 66 checks nativos y regresiones V6 135+66, V5 526, V4 396, V3 968, 64 habilidades, Python PASS.
- **Advertencia obligatoria**: no hay cierre graceful RPC del worker. El fichero `modules/battle/backends/showdown/pipe_client.gd::close` W04 V7 sustituye shutdown con `stop_now()`, comprueba `OS.is_process_running(original_pid)`, y emite aviso `forced_shutdown: blocking_graceful_pipe_boundary`. Esto **mitiga** cuelgue de retorno, no repara shutdown limpio. Sin prueba Windows específica y sin test GPU manual. `W04-V6-DEP-01` menta efectiva hardy→adamant sigue sin resolver (stat import mismatch en native Showdown). No afirmar READY_FOR_MAIN.
- Comparación W04 V7 contra IA6 actual: **diverged, 81 commits ahead / 98 behind**. Prohibido merge directo.
- Próxima acción IA6: crear rama candidata **desde SHA oficial actual**; trasplantar solo helper W04 V5 `regional_level_evolution_contract_w04_v5.gd`, consumer V6 `w04_postbattle_evolution_consumer_v6.gd`, cambios acotados en EvolutionSystem/FieldNativeBridge/FieldNativePresentation necesarios, y `pipe_client.gd::close` solo tras análisis del riesgo de force-kill y reversión. Añadir pruebas V5–V7 originales, validar 2 ciclos, SaveV2, W01 Casco Dentado, W02, W03 captura/repel, W05 libros/rope, V27 Windows, V28 Linux. PR draft no fusión hasta gates completos. Si cierre forzoso no pasa Windows o interfiere con procesos, bloquear ese seam y dejar caso documentado.
- No tocar `native_engine.cjs`, `worker.cjs`, `exchange`, motor, XP ni serialización shared sin autorización. No confundir la CI de fuente de W04 con CI sobre la rama IA6.
- Excluir siempre `dynamax_candy`; proteger `main`, V28 y PR #118.

## Estado pendiente
- W02 sigue con dependencia EXP Share V3. Trabajo de W01 W03 W05 antiguo no debe reintegrarse.
- Próxima `p`: empezar auditoría y candidata W04 V5–V7 **sobre HEAD oficial**, o documentar bloqueo exacto si no se puede separar seam del cierre nativo.
