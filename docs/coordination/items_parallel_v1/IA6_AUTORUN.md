# IA6 — RELEVO AUTORIZADO W01 · TANDA 03 (orden vigente)

**La tanda anterior está revisada y cerrada; no la repitas.** IA6 ha actualizado esta misma ruta, que es tu memoria operativa permanente. Al recibir `p` o `sigue`: 1) lee este archivo en TU rama, 2) recupera el CSV/checkpoint de TANDA 03, 3) ejecuta la primera fila pendiente, 4) continúa las 10 filas sin pedir autorización por microbloque y guarda checkpoints cuando se interrumpa el turno. No contestes solo «entendido» ni afirmes trabajo entre turnos.

**Única rama de trabajo:** `codex/calvo-items-20261110-w01-gems-autobatch01`. **Reglas generales:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` en la rama árbitra `codex/calvo-items-20261101-arbitro`. **Cola maestra:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W01_TANDA_03.md` en rama árbitra. La cola íntegra queda reproducida abajo para no depender de contexto de conversación. No trabajar en `main`, V28 ni PR118. No modificar archivos fuera de permiso. No declarar CI SUCCESS de otra SHA. Al acabar TANDA 03, informe único y STOP hasta próxima orden IA6.

**Métrica obligatoria separada en tu respuesta:** `hitos N/10 | objetos nuevos X | pruebas/QA Y | integración IA6: no` (salvo integración expresamente certificada sobre la rama de IA6). Una barra 10/10 NO significa diez objetos terminados.

---

# IA6 — W01 TANDA 03 · CERRAR GAP DE GEMAS ENTRE MOCHILA Y COMBATE
Rama: `codex/calvo-items-20261110-w01-gems-autobatch01`.
**CI previa:** #42869207766 completed/success en `0871aa6751faecb7342376134ddbcaa5acf1ce5a`, 5 gemas T02 + matriz de 18 con las 3 CAMP005 y las 10 T01. El cierre documental T02 existe. No volver a contar ninguna de las 18 como NUEVA.
**Regla de trabajo IA6:** 10 hitos, sin pedir permiso por cada uno. `p` inicia o reanuda desde checkpoint; no existe ejecución garantizada entre turnos. Probar efecto real y negativos, documentar SHA de código y CI completada SUCCESS, distinguir `HITOS`, `OBJETOS NUEVOS` y `INTEGRADOS EN IA6`. Un hito QA no cuenta como objeto nuevo. No tocar main, V28, PR118, otras ramas ni serializadores compartidos no autorizados. El cierre impide nueva fila 11 sin nota posterior.

**Problema:** la mecánica de daño nativa está comprobada con equipamiento dispuesto en el test, pero el informe T02 no acredita *todo el recorrido* desde `PlayerInventory` mediante `FieldItemService.equip` al combate, al consumo, al retorno y al guardado. Ya existen `FieldItemService.equip` y `unequip`; comprobar uso real y mantenerlos sin modificar.

| Hito | Entrega |
|---|---|
| 01 | Trazar fuente exacta de 18 gemas, inventario+propiedad+equip, SaveV2 y entrada al motor; enumerar referencias |
| 02 | Prueba roja si falla el ciclo `inventory → FieldItemService.equip → party.held` en 3 gemas CAMP005, sin falsear L3 |
| 03 | Ciclo completo con gemas T01 IDs 01–05, efecto real en combate y consumo correcto |
| 04 | Ciclo completo con gemas T01 IDs 06–10, efecto real en combate y consumo correcto |
| 05 | Ciclo completo con gemas T02 5 IDs, efecto real en combate y consumo correcto |
| 06 | Inventario con cero, Pokémon ajeno, equipar ya equipado, sustituir held y devolución segura sin duplicaciones |
| 07 | Reserva/entrada/salida/derrota/captura/Transformación, estado consumido no reactivable por cambio de miembro |
| 08 | Persistencia real de inventario y criatura antes/después del uso, SaveV2 normal y legacy, sin gemas fantasma |
| 09 | Prueba de integración con adaptador **existente** de sesión de combate, no una ventana UI inventada; si no existe acoplamiento, ticket con interfaz exacta |
| 10 | CI acumulativa con T01+T02+CAMP004/005, informe `AUTORUN_V3_FINAL.md` e inventario de casos L2 y L3 genuinos |

**Propiedad:** crear tests, fixtures, workflow W01 y helpers exclusivos, y modificar solo seam ESPECÍFICO de gemas en backend W01 si una prueba roja lo demuestra. `FieldItemService`, `FieldItemBag`, `PlayerCollection`, `CreatureInstance`, `SaveGameRepository`, `SaveV2`, escena nativa y motor de batalla global SOLO LECTURA; no copiar cambios de otras ramas. Si una unión es imposible sin tocar compartido, dejar prueba roja y ticket IA6 y pasar al resto. **Objetos nuevos de esta tanda = 0** (solo completar ruta de 18 gemas históricas), salvo que se identifique ID previamente no acreditado con autorización explícita nueva.

