# IA4/W04 — AUTORUN V1, ticket único de productores compartidos

**Responsable de productores:** IA6. **Rama de la auditoría:** `codex/calvo-items-20261104-w04-camp006`.
**Alcance:** 18 IDs de B07–B10 y 23 rutas (ver `AUTORUN_V1_MATRIX.json`). No es solicitud de autorización entre microbloques; es una dependencia técnica de la integración selectiva final.

## Bloqueo transversal preciso

**1. Identidad de forma individual.** `CreatureInstance` serializa `species_id` y `held_item_id`, pero no `form_id` persistente de la captura ni la nueva variante; no hay migración SaveV2. B07 exige `slowpoke-galar` para Galarica, y dos destinos Urshifu distintos para el mismo `species_id`. B08 exige formas de Shaymin, Deoxys, Fuerzas de la Naturaleza, Rotom y Zygarde. B09 exige Origen y Primal sin convertirlo en evolución de especie. **Contrato mínimo:** `form_id` verificado por Factory/captura, migración legacy explícita, validación de forma fuente/destino contra PokeAPI, persistencia con la misma `instance_id` y restauración después de SaveV2. Sin esto, `species_id` jamás basta para la forma correcta.

**2. Productores de evento/política de cambio de forma.** Definir y probar el evento del mundo/batalla correspondiente: Shaymin día/estado/reversión, Deoxys selección de forma, Reveal Glass toggle, Rotom selección de electrodoméstico+movimientos, Zygarde celdas/cores y Power Construct solo en batalla, Kyogre/Groudon Primal al evento de entrada a combate, Dialga/Palkia/Giratina Origen por objeto equipado. Resolver consumo/retiro sin inferir reglas de variedad del catálogo (PokeAPI solo enumera formas). Los cambios dependientes del tiempo precisan reloj jugable persistente; no usar el del sistema como sustituto.

**3. Servicio transaccional y rollback.** `FieldItemService` / batalla / `PlayerCollection` deben validar propiedad, condición y variante **antes** de gasto o mutación. Efectuar de modo atómico equipamiento, entrada/salida de batalla, alteración de habilidad/tipo/movimiento/stats cuando aplique, evolución/cambio de forma, devolución en cancelación/fallo y SaveV2. Un ítem que se equipa no desencadena automáticamente una evolución por `use_item`; no inventar rutas en `EvolutionSystem`.

**4. Fusión de dos ejemplares.** B10 requiere `main_instance_id` y `partner_instance_id` distintos, ambos propiedad real de party/storage, selección de la ruta Kyurem/Kyurem, Calyrex o Necrozma y forma canónica de destino. IA6 debe definir cómo queda aparcado el socio, cómo se conserva todo su estado (objeto, PP, naturaleza, IV/EV, amistad, experiencia, nivel, equipo/almacén), cómo se deshace la fusión con identidades originales y si hay gasto/reembolso. Guardado/carga de un par activo y rollback completo si falla, sin duplicar ni destruir socio.

## Evidencia de ausencia y pruebas de regresión

- Fuente `tests/fixtures/parallel_items/w04_campaign_005.json` (sin modificar): B04 rutas regionales, B09 cambios de forma, B07 Origen/Primal y B08 fusiones; `tests/gameplay/parallel_items_w04_campaign_005.gd` ya verifica rechazo, identidad, inventario y SaveV2 donde existen los seams.
- `data/api/v2/evolution-chain/33/index.json`: Galarica en Slowpoke Galar; `470`: dos formas Urshifu de destino con el mismo `species_id`. Las rutas regionales existen como datos; no se pueden activar sin identidad de forma.
- Chains 198/199/244/245/248, 253/202/328/240/370, 333/476/421: **sin aristas evolutivas** de las formas/fusiones; son variedades o cambios de forma, no evoluciones directas por ítem.
- `modules/creatures/domain/creature_instance.gd` y `modules/creatures/progression/evolution_system.gd` no ofrecen identidad de forma persistente ni motor de fusiones. Guardar/restaurar una criatura base no equivale a restaurar la variante.
- `AUTORUN_V1_MATRIX.json` incluye los 18 ID únicos, 23 rutas y productor, consumidor, persistencia y rollback **por objeto**. Su integridad se valida con runner W04 AUTORUN.

## Desbloqueo exigido

IA6 integra productores en su rama de integración y ejecuta tests positivos L3 desde la acción real: seleccionar especie y forma fuentes, aplicar regla canónica, observar cambio de forma/estilo/pareja, mantener identidad de criaturas y persistencia SaveV2; negativos sin efectos ni pérdidas, más regresiones W04. **La CI de W04 autorun puede demostrar que el bloqueo está bien auditado; no certifica estas mecánicas inexistentes.**

Este ticket evita repetir solicitudes por cada uno de los 18 ítems. W04 continúa autónomamente QA independiente de la misma tanda, sin tocar módulos compartidos.
