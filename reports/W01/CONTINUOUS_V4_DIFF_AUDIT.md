# IA1/W01 — Auditoría de diferencias y dependencias de QA V4 staging
Fecha: 2026-11-11
Origen: `codex/calvo-items-20261110-w01-gems-autobatch01`
Destino de ensayo: `codex/calvo-ia6-staging-20261111-w01-held`
Base IA6 documentada: `e63b2e6c7e175fba318cc2f562bebd1769589092`
Estado: `QA_MISSING_DEPENDENCIES`, sin READY_FOR_IA6_MERGE.

## Hechos comprobados mediante GitHub
- La comparación HEAD de ambas ramas indica estado `diverged`: 252 commits ahead / 169 behind tomando staging como base (cambios entre ramas, NO un diff seguro para fusionar).
- En el origen existen `tests/gameplay/parallel_items_w01_campaign_003.gd`, `_004.gd`, `_005.gd`, `parallel_items_w01_autorun_v4_leftovers.gd` y `tests/fixtures/parallel_items/w01_campaign_005.json`. En staging estas cinco rutas devuelven 404.
- El runner CAMP003 hereda de `res://tests/gameplay/item_automation_v28.gd`; CAMP004 hereda de CAMP003; CAMP005 hereda de CAMP004. La suite de leftovers TANDA04 hereda de `parallel_items_w01_autorun_v3.gd`. Esto impide ejecutar los runners ausentes por simple referencia desde un workflow.
- El `CONTINUOUS_V4/STATE_W01.md` documenta igualdad de objetos Git para `native_engine.cjs`, conexiones held y política, y 0 hunks de producción W01 por portar. Esa igualdad proviene de la auditoría previa; no implica que todos los runners de QA estén en staging.
- En staging están certificadas pruebas de base y L3; V1/CAMP002 job `held_stage_v1_camp002` de run #42965532842 figura completed/success.
- La política descarta `dynamax_candy`; no abrir de nuevo la selección.
- El informe de auditoría referido anteriormente no estaba presente y se crea ahora para trazabilidad.

## Riesgo detectado
La comparación de ramas muestra muchos ficheros exclusivos de W01 (runners, fixtures, workflows y documentación). Portar todo el árbol, hacer merge o copiar clases enteras sin revisión podría sobrescribir cambios integrados de IA6, introducir nuevas dependencias o presentar un PASS falso.

## Plan de resolución seguro
1. Preparar un inventario exacto de dependencias transitivas de los runners de T01–T04, V2 y CAMP003–005; separar archivos de pruebas y fixtures de módulos de producción protegidos.
2. Para cada suite, comprobar si staging ya tiene un equivalente L3 con la misma condición positiva, negativos, consumo, Transformación, settlement y SaveV2. Marcar `COVERED_BY_STAGE_TEST` solamente con nombre de prueba, SHA y CI.
3. Para cobertura inexistente, crear pruebas/adaptadores pequeños propios de W01 en staging con fixtures locales y sin herencia a runners ausentes. No importar clases enteras ni código de producción del origen por arrastre.
4. Crear gate CI staging por grupos, preservando V1/CAMP002, preflight L3, veto Dinamax y tests de nueva cobertura; exigir `completed/success` y SHA de la ejecución. Si una cobertura no puede reproducirse sin módulo protegido, abrir ticket de dependencia IA6.
5. Solo entonces cerrar reporte final con matriz de cobertura por suite y `READY_FOR_IA6_MERGE` o declarar bloqueo específico. La integración oficial de IA6 es una puerta independiente.

## Alcance de este checkpoint
Auditoría documental y lectura de GitHub, no nuevas pruebas funcionales ni CI lanzada. No modificación de producción, main, V28, PR #118, ramas W02–W05 ni rama árbitra.
