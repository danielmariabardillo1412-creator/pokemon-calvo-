# W01 — Fase C V4: puerta PARCIAL de regresión staging
Fecha 2026-11-11.

## Nuevo gate real
- Archivo: `.github/workflows/w01-continuous-v4-phase-c-partial.yml`
- SHA de publicación del workflow: `54cce127b95221ce48c332f55ec5d06ab7367d72`.
- Rama: `codex/calvo-ia6-staging-20261111-w01-held`.
- Tres jobs: `stage_baseline`, `stage_v1_camp002`, `stage_held_l3`.
- Se usan test y recursos de staging existentes: CAMP001, Transformación nativa, política que excluye `dynamax_candy`, V1, CAMP002 y ruta L3 de 10 modos `leftovers`/`sitrus_berry`/`draco_plate` con SaveV2.
- Todos los jobs preparan recursos canónicos, Godot 4.7 y Showdown fijado; sus resultados requieren evidencia de Actions, no basta publicación del workflow.
- `fetch_commit_workflow_runs` solo consulta PR-triggered runs y devolvió lista vacía al instante de comprobación. **No interpretar como CI aprobada ni como garantía de que Actions se haya disparado.** Verificar ejecución vía Actions y SHA.

## Matriz de cobertura honesta
| Área | Evidencia anterior | Nueva puerta | Pendiente |
|---|---|---|---|
| CAMP001, Transform, política | #42964814414 PASS | Reejecuta | Certificar nuevo SHA |
| W01 V1 y CAMP002 | job #42965532842 success | Reejecuta | Certificar nuevo SHA |
| 10 rutas L3 reales | #42965199759 PASS 204 checks | Reejecuta | Certificar nuevo SHA |
| TANDA01–04 completa | Fuente histórica solamente | NO | QA selectiva staging |
| V2 38 jobs completa | #42958587809 PASS en origen | NO | Equivalencia staging |
| CAMP003–005 | Fuente histórica solamente | NO | QA selectiva staging |

## Dependencias identificadas
- CAMP003 hereda de `item_automation_v28.gd`; CAMP004 hereda de CAMP003; CAMP005 de CAMP004.
- TANDA04 leftovers hereda de TANDA03.
- Las pruebas históricas y fixtures exclusivos del origen deben ser auditados por escenario para construir adaptadores autónomos y pequeños; ni importar runners enteros ni usar resultados históricos como PASS staging.

## Bloqueo y criterio de cierre
Este es un **gate parcial**, no `READY_FOR_IA6_MERGE`. Después de un PASS verificable de los tres jobs se exige matriz de los negativos históricos faltantes y solución o ticket por dependencia protegida. Integración oficial IA6: NO. Producción protegida sin cambios. 
