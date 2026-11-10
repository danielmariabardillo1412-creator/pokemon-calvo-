# IA6 — RELEVO AUTORIZADO W03 · TANDA 04 (orden vigente)

**La tanda anterior está revisada y cerrada; no la repitas.** IA6 ha actualizado esta misma ruta, que es tu memoria operativa permanente. Al recibir `p` o `sigue`: 1) lee este archivo en TU rama, 2) recupera el CSV/checkpoint de TANDA 04, 3) ejecuta la primera fila pendiente, 4) continúa las 10 filas sin pedir autorización por microbloque y guarda checkpoints cuando se interrumpa el turno. No contestes solo «entendido» ni afirmes trabajo entre turnos.

**Única rama de trabajo:** `codex/calvo-items-20261104-w03-camp006`. **Reglas generales:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` en la rama árbitra `codex/calvo-items-20261101-arbitro`. **Cola maestra:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W03_TANDA_04.md` en rama árbitra. La cola íntegra queda reproducida abajo para no depender de contexto de conversación. No trabajar en `main`, V28 ni PR118. No modificar archivos fuera de permiso. No declarar CI SUCCESS de otra SHA. Al acabar TANDA 04, informe único y STOP hasta próxima orden IA6.

**Métrica obligatoria separada en tu respuesta:** `hitos N/10 | objetos nuevos X | pruebas/QA Y | integración IA6: no` (salvo integración expresamente certificada sobre la rama de IA6). Una barra 10/10 NO significa diez objetos terminados.

---

# IA6 — W03 TANDA 04 · CERRAR LOS DOS QA PARCIALES DE REPEAT BALL NATIVA
Rama: `codex/calvo-items-20261104-w03-camp006`.
**CI previa:** #42869862584 SUCCESS y `W03_REPEAT_NATIVE_V3 PASS checks=26`: Repeat Ball L3 nativa desde historial de especie guardado. T03 cerrada 10/10 hitos, pero QA07 (party+storage llenos/fallo real) y QA08 (tras Transformación) **PARCIALES**. No añadir 10 bolas ficticias ni repetir el cierre.
**Regla de trabajo IA6:** 10 hitos, sin pedir permiso por cada uno. `p` inicia o reanuda desde checkpoint; no existe ejecución garantizada entre turnos. Probar efecto real y negativos, documentar SHA de código y CI completada SUCCESS, distinguir `HITOS`, `OBJETOS NUEVOS` y `INTEGRADOS EN IA6`. Un hito QA no cuenta como objeto nuevo. No tocar main, V28, PR118, otras ramas ni serializadores compartidos no autorizados. El cierre impide nueva fila 11 sin nota posterior.

**10 pruebas de aceptación independientes del mismo objeto (0 objetos nuevos):**
| Hito | Escenario |
|---|---|
| 01 | Preparar harness que ejercite dos batallas nativas consecutivas con ledger vivo, seed determinista y stock |
| 02 | Party llena + STORAGE llena: primer intento real y respuesta de routing, sin perder/duplicar criatura ni bola |
| 03 | Captura que FALLA por RNG real, turno/stock/semilla y ledger sin mutación indebida |
| 04 | Captura rechazada por inventario sin bola: ledger/PP/RNG/SaveV2 intactos |
| 05 | Un movimiento Transformación en batalla nativa → captura con Repeat, identidad de especie base correcta |
| 06 | Guardar checkpoint nativo DURANTE combate antes de Repeat, restaurar y verificar misma probabilidad y semilla |
| 07 | Captura con Party llena pero STORAGE disponible, routing positivo, un único registro de base species |
| 08 | Corrupción/legacy del ledger SaveV2: falla sin publicar estado, y legacy crea historial vacío |
| 09 | Probar Repeat tras una captura real previa con otra Ball, bonus ×3.5; especie distinta ×1 con mismo control |
| 10 | Regresión completa Native/Repels/Escape Rope/CAMP005-006 + informe `AUTORUN_V4_FINAL.md` con nuevos checks, L3 y límites |

**Propiedad:** tests W03, fixtures, workflow, helpers de captura W03; `showdown_adventure_session.gd::capture` y rama específica de `_finish` exclusivamente si la prueba roja exige corrección de Repeat, preservando contexto/RNG/bolas previas. `FieldNativeSave`, `SaveV2`, `CreatureInstance`, mochila y backend Showdown general SOLO LECTURA. No fije pruebas para forzar éxito de una captura que debía fallar; registrar seeds y probabilidades. Integración IA6 pendiente y no acreditada por CI de W03.

