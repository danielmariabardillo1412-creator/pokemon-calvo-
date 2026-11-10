# IA6 — RELEVO AUTORIZADO W02 · TANDA 03 (orden vigente)

**La tanda anterior está revisada y cerrada; no la repitas.** IA6 ha actualizado esta misma ruta, que es tu memoria operativa permanente. Al recibir `p` o `sigue`: 1) lee este archivo en TU rama, 2) recupera el CSV/checkpoint de TANDA 03, 3) ejecuta la primera fila pendiente, 4) continúa las 10 filas sin pedir autorización por microbloque y guarda checkpoints cuando se interrumpa el turno. No contestes solo «entendido» ni afirmes trabajo entre turnos.

**Única rama de trabajo:** `codex/calvo-items-20261109-w02-mints-integration`. **Reglas generales:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` en la rama árbitra `codex/calvo-items-20261101-arbitro`. **Cola maestra:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W02_TANDA_03.md` en rama árbitra. La cola íntegra queda reproducida abajo para no depender de contexto de conversación. No trabajar en `main`, V28 ni PR118. No modificar archivos fuera de permiso. No declarar CI SUCCESS de otra SHA. Al acabar TANDA 03, informe único y STOP hasta próxima orden IA6.

**Métrica obligatoria separada en tu respuesta:** `hitos N/10 | objetos nuevos X | pruebas/QA Y | integración IA6: no` (salvo integración expresamente certificada sobre la rama de IA6). Una barra 10/10 NO significa diez objetos terminados.

---

# IA6 — W02 TANDA 03 · REPARACIÓN ÚNICA DE NATURALEZA EFECTIVA AL EVOLUCIONAR
Rama: `codex/calvo-items-20261109-w02-mints-integration`.
**CI previa:** #42869765262 completed/success sobre `ba2af91278a6e79df30532b66855f7ccdb4278d8`, diez hitos T02 cerrados. Ticket `reports/W02/AUTORUN_V2_EVOLUTION_SHARED_SEAM_TICKET.md` confirmado. No volver a contar mentas ni chocolates/objetos antiguos.
**Regla de trabajo IA6:** 10 hitos, sin pedir permiso por cada uno. `p` inicia o reanuda desde checkpoint; no existe ejecución garantizada entre turnos. Probar efecto real y negativos, documentar SHA de código y CI completada SUCCESS, distinguir `HITOS`, `OBJETOS NUEVOS` y `INTEGRADOS EN IA6`. Un hito QA no cuenta como objeto nuevo. No tocar main, V28, PR118, otras ramas ni serializadores compartidos no autorizados. El cierre impide nueva fila 11 sin nota posterior.

**Decisión IA6:** autorizo EXCEPCIONALMENTE **solo** `modules/creatures/progression/evolution_system.gd::apply_evolution`, porque hoy copia `nature_id` y después calcula stats con la naturaleza original, pero omite `effective_nature_id`. Este defecto afecta todas las evoluciones que pasan por el constructor general. No hay autorización para modificar la factoría regional, `form_id` de W04 ni otras funciones de evolución.

| Hito | Entrega |
|---|---|
| 01 | Prueba roja directa del `apply_evolution` original: Pokémon con menta real → evolución → pierde naturaleza efectiva; fixture inmutable |
| 02 | Parche mínimo para propagar `effective_nature_id` (si presente) antes de calcular stats, respetando `nature_id` original |
| 03 | Vía evolución por subida de nivel, bajo regla canónica existente y sin trade ficticio |
| 04 | Vía evolución por objeto válida desde `FieldItemService.evolve`, manteniendo inventario y rollback |
| 05 | Evolución de Pokémon SIN menta sigue idéntica: IV/EV, PP, naturaleza, PS, habilidades |
| 06 | Naturaleza efectiva que coincide con original, recambio de menta y evolución posterior |
| 07 | Party y STORAGE: mismo `instance_id`, pertenencia, no pérdida ni duplicación |
| 08 | SaveV2 normal + legacy + corrupción posterior a evolución; rechazo antes de publicar datos malos |
| 09 | Interoperabilidad `Growth.plan` T02, evitar dobles recálculos y estados inconsistentes; contrato con futura `form_id` W04 sin editarla |
| 10 | CI Python/Godot con todas campañas y T01/T02 y nuevos negativos; `AUTORUN_V3_FINAL.md` con CI y SHA |

**Propiedad:** únicamente `evolution_system.gd::apply_evolution`, nuevos tests/fixtures/runner/workflow W02. `CreatureInstance`, `StatCalculator`, `SaveV2`, `FieldNativeSave`, `FieldItemService`, `FieldGrowthEffects`, `Factory` y `form_id` de W04 NO se editan. Si futuras formas requieren copia de estado adicional, dejar ticket IA6 sin mutación. **Es UN defecto compartido, no diez objetos nuevos.**

