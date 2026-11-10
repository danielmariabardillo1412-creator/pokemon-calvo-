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
