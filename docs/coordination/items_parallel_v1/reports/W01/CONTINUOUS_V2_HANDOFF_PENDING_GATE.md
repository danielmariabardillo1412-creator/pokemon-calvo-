# W01 / IA1 — CONTINUOUS_V2 · PRE-HANDOFF PENDIENTE DE GATE

**Estado vinculante: NO READY_FOR_IA6.** Este documento prepara el relevo pero **NO CERTIFICA** las 16 placas hasta `completed/success` y 38/38 jobs verdes en GitHub. No fusionar ni integrar mediante este documento.

## Rama y controles
- Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`; rama exclusiva: `codex/calvo-items-20261110-w01-gems-autobatch01`.
- CI integral: [#42958587809](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958587809), **SHA funcional fijo `dead5a21679c0aa8f635f3ce12fce0279ada0fc0`**; en último chequeo **36/38 jobs PASS**, con `camp004_regression` y `camp005_regression` aún en ejecución. Conservar ambos: jamás desactivar, saltar, reducir ni sustituir por pilotos.
- Fase A: 10/10 coberturas L3 certificadas con [CI #42939814729](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42939814729) 16/16 sobre `83dacee5c924505f5234503a4fef126ea0bb0e01`.
- Fase B/B01: 6/10 certificados por [CI #42954745915](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42954745915) 22/22 sobre `1bfd86991cfbd01509b29a245f2e8ee7ada45e93`; otras cuatro `DEPENDENCIA_FUERA_W01` (`amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`).
- Fase B/B02–B03: 16 placas `EN_CI_AUTOMATICA`; **16 pilotos individuales completed/success**, incluidos [Dread #42955088591](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955088591), [Earth #42955023454](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955023454), las otras 13 del commit `01a10594b98de4ed596828421c5fab797f87efb3` y Mind con corrección exclusiva de prueba [#42958106006](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958106006). Acreditan el L2/L3 individual, **no todavía la puerta integral**.
- Auditoría Fase C [#42958901216](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958901216) **SUCCESS** sobre `9fc865619293652f7c230a7d3bcdcdc7b3346585`: `A=10, B_cert=6, B_pilots_pending=16, external=4, candidate_total=36, implemented_new=0`. Una vez certificado el total, ejecutar de nuevo y exigir `W01_PHASE_C_LEDGER_READY total_certified=32 external=4`.

## Matriz real de entrega
- `reports/W01/AUTORUN_V4_PROGRESS.csv`: 10 filas de Fase A `CERTIFICADO` con SHA y CI por fila.
- `reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv`: 26 IDs en orden canónico; 6 certificados, 4 dependencias, 16 placas con piloto individual validado pendiente de gate.
- `reports/W01/CONTINUOUS_V2_PLATES_RUN_MATRIX.csv`: IDs y SHA/CI individual de las dieciséis placas. **Mind debe referenciar CI #42958106006, no su CI roja original.**
- Workflow completo: `.github/workflows/w01-continuous-v2-held-complete.yml` (22 jobs congelados + 16 placas, 38 jobs). Auditor fase C: `tests/tools/test_w01_continuous_v2_phase_c_ledger.py`.
- Pruebas positivas/negativas de los equipables: portador, sin objeto, reserva, tipo incompatible y persistencia de PS/estado/equipo en `FieldItemService.equip → Showdown real → settle_finished_battle → SaveV2`. Las placas prueban solo potencia por tipo; no se toca la transformación de Arceus ni formas de W04.

## Contabilidad e integración
- **Hechos al momento de este documento:** 16 objetos certificados en conjunto (A=10 + B=6), 16 placas aún bajo gate, 4 dependencias fuera de W01, **0 objetos de producción implementados nuevos**, 0 integración IA6 demostrada. No llamar a 32 `CERTIFICADO` todavía.
- Trabajos propios de W01: tests, fixtures, workflows, documentación; no cambios de `main`, V28, PR #118 ni fusión con árbitra. La interfaz visual y la integración inter-IA necesitan verificación específica independiente.

## Lista de cierre, autorizada por IA6
1. Recuperar CI #42958587809: comprobar el estado del run, SHA exacto y **38 jobs** mediante endpoint `jobs?per_page=100` (la paginación por defecto devuelve solamente 30).
2. Solo con 38/38 SUCCESS, cambiar las 16 filas B02/B03 a `CERTIFICADO` en CSV B, `sha_pruebas=dead5a21679c0aa8f635f3ce12fce0279ada0fc0`, `ci_run=42958587809`, `qa_funcional=si`, `objetos_nuevos=0`. Cerrar matriz de placas.
3. Ejecutar y comprobar el workflow de auditoría Fase C (debe emitir `LEDGER_READY` con 32 certificados + 4 dependencias). Conservar los 38 jobs globales aprobados.
4. Escribir `CONTINUOUS_V2_FINAL.md` y **READY_FOR_IA6** en rama W01, sin tocar rama de IA6 ni atribuir integración/merge no ocurridos. IA6 decide lectura/cross integration.
5. Si cualquier job de CAMP004/005 falla, **NO cerrar**: leer log, identificar problema y reparar únicamente si el fallo pertenece a W01 autorizado. No blanquear CI roja.
