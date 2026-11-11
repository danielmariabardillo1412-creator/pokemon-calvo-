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

## V4 progreso de CI en staging tras cierre V2 READY_FOR_IA6
- Misión histórica V2 final: `f73f775a183382607d0eacb450ce25eead1851e3`, READY_FOR_IA6; CI 38/38 `42958587809`, guard Dinamax `42960157622`, ledger `42964085232` recibo 32/4, todos SUCCESS. **No repetir V2.**
- **Diff producción:** objeto Git `native_engine.cjs` SHA `073e5c8523f47a477735b98a766437392c201e33` idéntico entre staging y fuente; held connections y política también SHA idénticos. 9 diferencias en módulos compartidos de IA6 (cuatro modificados y cinco nuevos), son protegidos, NO sobrescribir.
- **Fase A:** comparación funcional cerrada, provisional `NO_DIFF_NEEDED` para código held W01; función restore de Transformación ya presente en base de IA6. Reporte `reports/W01/CONTINUOUS_V4_DIFF_AUDIT.md`. Producción editada en V4: 0 hunks.
- **Fase B pruebas nativas/campaña:** [CI #42964814414](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42964814414), SHA `0c3f4df217c0ad4b4eb7fa8abd04832c370e7810`, **in_progress al último chequeo**. Ejecuta comprobación de SHA exacto, CAMP001 Godot/SaveV2, Transformación y veto IA6. No proclamar PASS hasta resultado global.
- **Fase B L3 nueva:** [CI #42965005816](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965005816), SHA `c27c247b2ba259480b79f8d036862bc098773eee`, **in_progress al último chequeo**. Comprueba diez rutas genuinas (Restos 4, Baya Zidra 3, Tabla Draco 3) desde `FieldItemService.equip` hasta `FieldNativeSession → settle_finished_battle → SaveV2`. Ver `tests/gameplay/w01_continuous_v4_stage_held_l3.gd`.
- **Siguiente `p`:** consultar ambas CI; si FAIL leer log del job y corregir únicamente tests W01; si PASS declarar soporte L3 local. Preparar CI staging de regresiones T01–04/V2/CAMP003–005 solo usando pruebas presentes, sin copiar o hacer merge total ni disminuir checks. Si no hay hunks funcionales ausentes y L3 PASS, redactar `CONTINUOUS_V4_STAGING_FINAL.md` y `READY_FOR_IA6_MERGE` con límites explícitos.
- **Integración oficial IA6:** NO. Rama única de trabajo `codex/calvo-ia6-staging-20261111-w01-held`; `main`/V28/PR118/W02–W05 protegidas. **No hay trabajo de ChatGPT en segundo plano entre mensajes.**

## CI staging L3 inicial ya aprobada; regresión V1/CAMP002 preparada
- [CI W01 staging L3 #42965199759](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965199759) **completed/success**, SHA `4a9e9a775e18c0873736e7ddbd5e9e3b4253fe18`, recibo real `W01_V4_STAGE_L3 PASS modes=10 checks=204`. Ensaya Restos, Baya Zidra y Tabla Draco a través de `FieldItemService → combate nativo → settlement → SaveV2`. Sin modificación de producción.
- CI baseline [#42964814414](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42964814414) `in_progress` al último chequeo: CAMP001, Transformación, política; no declarar PASS.
- Nuevo workflow `.github/workflows/w01-continuous-v4-held-regression-v1-v2.yml` lanza ensayos W01 V1 y CAMP002 completos en staging; informe `reports/W01/CONTINUOUS_V4_REGRESSION_V1_C002.md`. Guardar run/SHA en próxima comprobación.
- Estado fase B: 10 L3 PASS locales, falta CAMP001 y V1/CAMP002; **hunks de producción trasladados 0**, `NO_DIFF_NEEDED` preliminar, CI staging total incompleta, IA6 integración oficial NO.
