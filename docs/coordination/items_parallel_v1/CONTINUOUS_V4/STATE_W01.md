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

## W01 V4 · Cierre de preflight/base y siguientes pruebas
- **[CI staging baseline #42964814414](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42964814414)** `completed/success` en SHA `0c3f4df217c0ad4b4eb7fa8abd04832c370e7810`. Recibos: `W01_V4_STAGE_PREFLIGHT PASS held_engine_same=1 policy_same=1 held_catalog_same=1 selected_held=8`; `W01_CAMP_001 PASS checks=2428 rows=24 errors=0`; `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3`; `ITEM_SELECTION_POLICY PASS checks=22 excluded=45`.
- **[CI staging L3 #42965199759](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965199759)** `completed/success` SHA `4a9e9a775e18c0873736e7ddbd5e9e3b4253fe18`, recibo `W01_V4_STAGE_L3 PASS modes=10 checks=204` incluyendo equip real, combate, settle y SaveV2. Primera CI #42965005816 FALLÓ por colisión de constante `OUT` heredada; se reparó exclusivamente en el test, se conserva el historial rojo.
- **No-diff funcional preliminar corroborado en staging:** código del motor nativo, conex. held y selección ya presente; código de producción W01 portado: 0 hunks. Hay que conservar revisiones compartidas de IA6.
- **[CI de W01 V1 y CAMP002 #42965532842](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965532842)** sobre SHA `39570126842821a885e5e5da9803a6bb75ca66b4`, `in_progress` en última consulta. No atribuir PASS hasta run `completed/success`.
- **Siguiente `p`:** comprobar #42965532842, aislar fallos W01 si surgen; si verde, preparar Fase C CI staging más amplia con T01–04, V2, CAMP003–005 y mantener política Dinamax. Los tests T01–04/CAMP003–005 **no se encuentran en la staging** y no hay autorización para copiar clases enteras/merge: diseñar adaptador QA selectivo o proponer a IA6 pruebas faltantes. No declarar `READY_FOR_IA6_MERGE` antes de gate suficiente. Integración oficial IA6: NO.

## Reanudación por p — recepción V1/CAMP002 y control documental (2026-11-11)
- CI #42965532842: el job `held_stage_v1_camp002` figura `completed/success` en consulta directa de Actions. SHA registrado al lanzamiento: `39570126842821a885e5e5da9803a6bb75ca66b4`.
- Reporte nuevo verificado/publicado: `reports/W01/CONTINUOUS_V4_REGRESSION_V1_C002.md`. Commit documental `9cd8f39177f074fe6c7da05be5fd178bd19029ec`; **no atribuirle la CI anterior**.
- Discrepancia documental: `reports/W01/CONTINUOUS_V4_DIFF_AUDIT.md` (citado por checkpoint) devuelve 404 en esta rama. Auditar o regenerar a partir de evidencia antes de cierre final.
- Regresiones pendientes de puerta staging: T01–T04, V2 y CAMP003–005; aún no `READY_FOR_IA6_MERGE`. No se han portado cambios de producción ni fusionado ramas.
- Siguiente `p`: comprobar presencia/ubicación de tests originales y producir adaptador selectivo permitido (o ticket técnico de pruebas inaccesibles), manteniendo suites previas y exclusión `dynamax_candy`; CI final solo contra SHA actual comprobado.

## Continuación `p` — diagnóstico de pruebas históricas ausentes (2026-11-11)
- Publicado informe de auditoría de diferencias `reports/W01/CONTINUOUS_V4_DIFF_AUDIT.md` (commit `4581640ad9b51894917c2ce315daad4aa45cd056`): corrige la referencia 404 anterior.
- Comprobada comparación real source↔staging: ramas divergen; no hacer merge ni copiar el árbol de tests completo.
- Confirmados en origen y ausentes en staging: `parallel_items_w01_campaign_003.gd`, `_004.gd`, `_005.gd`, `parallel_items_w01_autorun_v4_leftovers.gd`, y fixture `w01_campaign_005.json`.
- Herencia QA CAMP005→CAMP004→CAMP003→`item_automation_v28.gd`; TANDA04 leftovers→`parallel_items_w01_autorun_v3.gd`. Pendiente mapear coberturas equivalentes stage para evitar copia de clases.
- CI #42965532842 `held_stage_v1_camp002` completada SUCCESS, recibo en `reports/W01/CONTINUOUS_V4_REGRESSION_V1_C002.md`.
- **Estado:** fase C `QA_MISSING_DEPENDENCIES`. Ningún cambio de producción ni nuevo run CI en esta `p`; integración oficial IA6 = NO; `READY_FOR_IA6_MERGE` todavía NO.
- **Siguiente `p`:** inventario de los runners/fuentes y sus negativos; crear adaptador selectivo de pruebas ausentes sobre staging, sin portar clases enteras, y gate reproducible contra SHA real. Si no se puede, ticket IA6 con dependencia exacta.

## Continuación p — fase C: puerta parcial de CI staging (2026-11-11)
- Publicado workflow `.github/workflows/w01-continuous-v4-phase-c-partial.yml` en commit `54cce127b95221ce48c332f55ec5d06ab7367d72`. Tres jobs reales: `stage_baseline`, `stage_v1_camp002`, `stage_held_l3` con Godot/Node/Showdown, preflight, negativos, políticas y SaveV2.
- Publicado `reports/W01/CONTINUOUS_V4_PHASE_C_PARTIAL_GATE.md` con matriz de cobertura/ausencias, commit `1051a7f29b6f8707fee704cfb68e19b280a517b2`.
- El workflow se leyó de GitHub tras crear. **No hay CI nueva confirmada**: consulta de runs por commit limitada a eventos PR devolvió vacío y no permite concluir si la CI push se lanzó. No declarar PASS ni SHA de ejecución.
- Cobertura nueva que busca revalidación: CAMP001/Transform/policy, V1/CAMP002, 10 rutas L3. No afirmar cobertura completa de T01–04, V2 y CAMP003–005.
- Históricos faltantes: runner CAMP003→CAMP004→CAMP005 y TANDA04 dependiente de TANDA03. No copiar clases completas ni hacer merge de ramas divergentes.
- **Siguiente p:** comprobar CI real de esta puerta y, si GREEN, inspeccionar escenarios/negativos de origen para construir adaptador puntual de los faltantes y puerta incremental; si RED, corregir solo seam de tests W01. `READY_FOR_IA6_MERGE` pendiente, integración IA6 NO, producción modificada 0.

## Continuación p — CI parcial verificada y brechas auditadas (2026-11-11)
- Puerta parcial V4 [CI #43069765360](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43069765360): `stage_baseline`, `stage_v1_camp002`, `stage_held_l3` los tres `completed/success`, commit de workflow probado `54cce127b95221ce48c332f55ec5d06ab7367d72`.
- Informe de gaps `reports/W01/CONTINUOUS_V4_PHASE_C_GAP_MATRIX.md` publicado, commit `1e189e96dd7773f18f7b8a43fae6e01fd0d64177`.
- Analizados runners históricos fuente: CAMP004 exige 79 escenarios/185 pares; CAMP005 90 escenarios/272 pares, con RNG positivo/negativo. CAMP003 cubre Quick Claw, Focus Band y Air Balloon. TANDA03 gemas 18 incluye consumos/legacy/reemplazo. Suite L3 staging actualmente solo 10 rutas de Restos, Baya Zidra y Tabla Draco.
- **Estado:** `PHASE_C_PARTIAL_GATE_PASS`. No promover a `READY_FOR_IA6_MERGE` por regresiones CAMP003–005, TANDA01–04 completas y V2 aún sin cobertura equivalenciada en staging.
- **Siguiente p autorizada:** crear test autónomo pequeño en staging para negativos deterministas de gemas (duplicación, reserva, reemplazo y legacy) usando infraestructura existente; lanzar CI SHA propia. Posteriormente casos RNG de CAMP003–005 y matriz de placas. No importar runners heredados ni tocar producción protegida.
- Integración oficial IA6 NO; cambios de producción en V4 0.

## Continuación p — piloto negativo determinista de gemas en CI (2026-11-11)
- Nuevo test autónomo staging: `tests/gameplay/w01_continuous_v4_gem_negative.gd` (commit `9ec3adbdd1b3532ee402c71e2fb20673e9aae32b`). Usa FieldItemService real, bolsa/propietario, controles de duplicación, reserva, titular ajeno, sustitución Normal Gem↔Fire Gem y dos SaveV2 de disco.
- Workflow `.github/workflows/w01-continuous-v4-gem-negative.yml`, commit `0366d632c51a12152c9418b3a1e0c6ddbbb96cb8`, runner Godot 4.7, recursos canónicos, salida W01_V4_GEM_NEGATIVE solo tras al menos 24 aserciones y sin errores.
- [CI #43072818614](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43072818614) verificada realmente lanzada; al último chequeo `gem_negative_l3` estaba `in_progress`, step 6 `Restore canonical Godot and native runtime`, sin resultado final. **No contar PASS hasta éxito real**.
- La suite no cubre todavía consumo por batalla, legado ni 18 gemas completas; solo controles negativos deterministas. Su PASS parcial no da `READY_FOR_IA6_MERGE`.
- Siguiente `p`: comprobar CI 43072818614; si falla leer logs del job y corregir solo test/runner W01; si PASS, anotar SHA exacto y continuar con consumo nativo/legacy de gemas y negativos históricos restantes. Integración IA6 NO; producción 0 cambios.

## Continuación p — GEM negativa certificada; ciclo nativo publicado (2026-11-11)
- [CI gemas negativas #43072818614](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43072818614) `gem_negative_l3 completed/success`. Contrasta rechazo de duplicados, falta de stock, portador ajeno, reemplazo y persistencia SaveV2. Esta prueba no demuestra consumo en combate ni legado.
- Nuevo test autónomo `tests/gameplay/w01_continuous_v4_gem_lifecycle.gd` commit `1b77af329c8b0be23217162d0ddc8552861330ac`; hereda solo infraestructura stage L3 existente, no runners CAMP003–005. Usa Normal Gem en modos active/none/reserve, daño nativo, consumo real, settlement SaveV2, no reembolso de gema consumida y devolución de reserva sin uso.
- Workflow `.github/workflows/w01-continuous-v4-gem-lifecycle.yml`, commit `e5f4653113aae0090903aec961e3f60f97ca9eca`. [CI #43073243601](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43073243601) lanzada y `gem_lifecycle in_progress` al último chequeo, SIN certificación.
- Próxima `p`: comprobar CI 43073243601. Si falla, recoger pasos/log y reparar solo el nuevo test W01, sin disminuir aserciones; si PASS, ampliar una prueba de legacy V1 sin bolsa fantasma y cobertura histórica CAMP003–005.
- No se ha declarado READY_FOR_IA6_MERGE ni integrado en árbitra. Producción protegida, main, V28 y otras ramas intactas.

## Continuación p — consumo nativo SUCCESS y migración legacy V1 en CI (2026-11-11)
- [CI #43073243601](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43073243601) `gem_lifecycle completed/success`, workflow commit `e5f4653113aae0090903aec961e3f60f97ca9eca`. Tres modalidades (active/none/reserve) de Normal Gem, consumo desde batalla nativa, settlement, SaveV2, no devolución de gema gastada y devolución de reserva no gastada.
- Publicado test independiente `tests/gameplay/w01_continuous_v4_gem_legacy.gd` (commit `897ff9fe97851f2b922621786222bfd3e9dcff59`) para guardado formato V1 con Fairy Gem previamente consumida; valida decodificación inmutable, ausencia de bolsa fantasma, desequipar sin reembolso, regrabación SaveV2 y re-equipamiento imposible sin stock.
- Workflow `.github/workflows/w01-continuous-v4-gem-legacy.yml`, commit `336175d1adc79397518d308954ce5bc5d791d587`; [CI #43075475138](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43075475138) realmente lanzada. Último chequeo `gem_legacy_v1 in_progress` (setup Godot); **no atribuir PASS aún**.
- Alcance: migración legacy V1 simulada como entrada histórica deliberada, no combate nativo de Fairy Gem (este aspecto tiene su ensayo separado con Normal Gem). No equivale a 18 gemas ni CAMP003–005 completas.
- Siguiente `p`: revisar #43075475138 y corregir solo test si falla; si PASS, ampliar matriz held por tipo/portador con pruebas existentes en staging sin importar runners históricos enteros. Integración IA6 NO; 0 producción modificada.

## Continuación p — legacy V1 PASS, piloto cinco gemas por tipo en CI (2026-11-11)
- [CI legacy #43075475138](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43075475138): `gem_legacy_v1 completed/success`, SHA del workflow `336175d1adc79397518d308954ce5bc5d791d587`. Entrada de migración Fairy Gem consumida, guarda sin inventario fantasma y regraba SaveV2.
- Publicado piloto de cinco gemas de tipos distintos con combinaciones constatadas en fixture histórico de TANDA03: `fire_gem/fire_punch`, `water_gem/surf`, `electric_gem/thunderbolt`, `grass_gem/energy_ball`, `ice_gem/ice_beam`. Test `tests/gameplay/w01_continuous_v4_typed_gems.gd` (commit `f99216c86625c2768140b2e9645ab1a03e478860`): 15 rutas (5 × active/none/reserve), primer golpe nativo, no publicación prematura, settle, SaveV2 real, gemas gastadas sin reembolso y devolución de reserva sin uso.
- Workflow `.github/workflows/w01-continuous-v4-typed-gems.yml` (commit `01acf5eafeb75ed8d0d71ef8408e992dbdc5ce38`), [CI #43080974292](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43080974292) realmente lanzada. Última consulta: `typed_gems_l3 in_progress`, aún NO certificada.
- Cobertura histórica 18 gemas no declarada: seis tipos ensayados en staging (Normal + 5 piloto) si la CI piloto termina verde; los otros 12 y negativos RNG siguen pendientes. No contar PASS para el piloto hasta comprobar conclusión.
- Siguiente `p`: comprobar #43080974292, aislar error y corregir test propio si es roja sin reducir garantías; si PASS, avanzar en matriz faltante y gate final gradual. Integración oficial IA6 NO, producción 0 cambios.
