# IA1/W01 · CONTINUOUS_V4 / CHECKPOINT staging

- **phase:** A_COMPLETED_DIFF_AUDIT → B_STAGING_FUNCTIONAL_GATE
- **branch:** `codex/calvo-ia6-staging-20261111-w01-held`
- **staging_base_sha:** `e63b2e6c7e175fba318cc2f562bebd1769589092`.
- **source_w01_v2_ready:** `f73f775a183382607d0eacb450ce25eead1851e3`, documentación READY_FOR_IA6 presente. V2 global 38/38 SUCCESS #42958587809; policy #42960157622; ledger 32/4 SUCCESS #42964085232.
- **held_engine_blob:** `073e5c8523f47a477735b98a766437392c201e33` IGUAL en source y staging.
- **held_connections_blob:** `0525b37021edfc2e74c4fc2cb96e62f6f5b3e261` IGUAL en source y staging.
- **item_selection_blob:** `bf76a361b30e158f613f31ef275006862562cea8` IGUAL; veto `dynamax_candy` conservado.
- **nine_conflicts:** 4 módulos/escenas protegidos IA6 más recientes y 5 archivos nuevos IA6, NO copiar ni reemplazar. Ver `reports/W01/CONTINUOUS_V4_DIFF_AUDIT.md`.
- **production_hunks_to_port:** 0 confirmados hasta la prueba funcional staging; etiqueta provisional `NO_DIFF_NEEDED_FOR_OWNED_HELD_SEAMS`.
- **code_changes_v4:** 0 en producción. Solo tests/CI/checkpoint.
- **green_ci_v4:** ninguna aún; las CI V2 no son staging.
- **integrated_into_official_IA6:** NO.
- **next_safe_action:** ejecutar test de preflight, W01 CAMP001 Godot con SaveV2 nativo real y reproducir Transformación en staging, también IA6 policy. Si rojo, discriminar conflicto con los cuatro módulos compartidos y presentar test rojo sin modificar protección. Después L3 específica de `FieldItemService.equip → FieldNativeSession → settle_finished_battle → SaveV2` y regresiones T01–04, V2, CAMP003–005 en staging.
- **stop_condition:** `READY_FOR_IA6_MERGE` solo con CI en SHA de staging y reporte de hunks/NO_DIFF_NEEDED; NO fusionar.
