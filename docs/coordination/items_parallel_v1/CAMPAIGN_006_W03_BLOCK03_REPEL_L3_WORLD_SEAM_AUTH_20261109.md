# IA6 — W03 CAMP006 B03 · AUTORIZACIÓN EXCEPCIONAL DE REPELENTES L3 EN MUNDO REAL

**Fecha:** 2026-11-09 · **Emite:** IA6 · **Rama W03 exclusiva:** `codex/calvo-items-20261104-w03-camp006`  
**Base de diagnóstico:** `reports/W03/CAMP_006_BLOCK03_L3_SEAM_AUDIT_20261109.md` en W03.  
**Rama IA6 de integración, solo de consulta:** `codex/calvo-ia6-integration-20261109`.

**Decisión:** se autoriza a W03 a tocar **únicamente en SU rama** los seams protegidos del mundo listados abajo, después de certificar la reparación YAML #42696154023. La autorización anterior prohibía editar `field_demo.gd` y `field_native_bridge.gd`; esta puerta **levanta ese veto solo para estas funciones y solo para repelentes**. IA6 revisará todos los diffs antes de importar cambios. No se autoriza cambio global de SaveV2, motor, sesión de batalla, catálogos ni `main`.

## Contrato funcional obligatorio

1. **Un efecto de repelente por mundo.** `FieldRepelStepEffect` pertenece al campo real y se conecta exactamente una vez a `OverworldPlayer.step_completed`. Mantener `repel=100`, `super_repel=200`, `max_repel=250` pasos **físicos reales**, sin descontar movimiento bloqueado; el último paso debe tener una semántica consistente con la prueba L2 existente. No acumular ni reemplazar un repelente aún activo salvo nueva política posterior.
2. **Mochila y transacción.** En `FieldItemBag._refresh_choices/_apply` puede añadirse exclusivamente el uso de estos tres IDs: verificar stock/mundo desbloqueado, activar estado una sola vez y descontar **una** unidad únicamente si `start()` acepta. Rechazo por efecto activo, bolsa obsoleta, falta de stock, bloqueo, doble pulsación y estado malformado sin gasto ni mutación; si falla el consumo, revertir el estado a la copia anterior. **Nunca autoguardar** por activar el repelente. Mantener la ruta W03 Cuerda Huida y W05 libros si están presentes, sin reescribir `use_item` general.
3. **Preencuentro real, no retrospectivo.** `scenes/visual/field_demo.gd::field_prepare_native_encounter` ya resuelve `WildEncounterSystem.resolve` con RNG clonado. Filtrar por `encounter.creature.level < leader.level` después del resultado de RNG pero **ANTES** de `field_native_bridge.gd::_open` o de crear sesión de batalla; `leader` será el primer Pokémon vivo y elegible de la party real (si no existe, no hay repeler con líder ficticio). Devolver bandera de supresión tipada y `next_rng`, no convertir un encuentro en otro ni reponderar tablas.
4. **Política RNG explícita IA6:** ante ENCOUNTER suprimido, **avanzar el RNG canónico exactamente al `staged.state` ya resuelto** (se ha consumido el mismo roll; no se repite roll ni se devuelven resultados falsos). **NO** incrementar `_next_battle_seed` y **NO** emitir `battle_started`, porque no hay combate. Implementar un único seam `field_commit_repelled_encounter_rng(next_rng)` que solo persista el estado RNG preparado; `field_native_bridge.gd::on_step` recibe `blocked_by_repel` y retorna sin `_open`. Los encuentros no suprimidos siguen intactos, incluido su avance original RNG y semilla. No usar `field_commit_native_battle_start` para supresiones.
5. **Persistencia en campo compatible con saves antiguos:** en `field_demo.gd::field_native_world_snapshot` añadir `repel: {schema_version:1,active_id,remaining_steps}`; en `field_validate_native_loaded_world` validar **estrictamente** tipo/versión/ID/duración (sin coercionar strings a int); ante campo ausente de partida antigua asumir inactivo; ante campo malformado rechazar toda la carga antes de publicar colección/posición/estado. En `field_publish_native_loaded_world` aplicar el estado validado y conectar el mismo listener sin duplicarlo. El campo `world` se conserva ya como diccionario en el envelope existente `field_native_save.gd`; **NO editar** `modules/save/field_native_save.gd`, `SaveGameData`, `SaveGameSerializer`, hashes ni estructura general.
6. **Pruebas L3 acumulativas** desde `field_demo.tscn`: botón real → gasto uno → paso real → filtro de nivel con semilla reproducible → NO iniciar batalla tras suprimir → RNG tras resolución exactamente correcto y semilla de batalla intacta → nivel igual o superior permite combate → guardado MANUAL a mitad del efecto y carga con mismos pasos restantes; probar cada duración, expiración y rechazos sin efectos colaterales. Guardado antiguo sin repel y guardado corrupto deben conservar estado vivo. Conservar CAMP006 01–03 y CAMP005 Python/Godot, además de la batería de `field_native_bridge` / SaveV2 del área modificada.

## Cambios autorizados, exactamente

- `modules/overworld/field_repel_step_effect.gd`: únicamente validación/serialización y hook propio.
- `modules/overworld/overworld_encounter_director.gd`: solo seam de repelente si resulta necesario para ruta legacy y sin tocar distribución; **no sustituye el flujo de la demo**.
- `scenes/visual/field_item_bag.gd`: únicamente rutas de repelente en UI, preservando Cuerda Huida, libros, MT y medicinas.
- `scenes/visual/field_demo.gd`: exclusivamente `field_prepare_native_encounter`, `field_native_world_snapshot`, `field_validate_native_loaded_world`, `field_publish_native_loaded_world` y un helper local `field_commit_repelled_encounter_rng`; también el hook mínimo de attach/owner de repelente necesario al iniciar mundo.
- `scenes/visual/field_native_bridge.gd`: exclusivamente `on_step` para la rama `blocked_by_repel`.
- Nuevos adaptadores locales, tests/fixtures/CI propios de W03, sin rebajar pruebas históricas.

**Prohibido:** `modules/save/**`, `CreatureInstance`, `FieldItemService` central, `ProgressionSystem`, `Showdown`, `WildAdventureSession`, RNG de captura, lógica de flautas/señuelos, pesca/surf/buceo, `main`/V28/PR118/árbitra/otras ramas. Si un seam excede la lista, ticket y pausa antes de editar.

## Contabilidad y condiciones de cierre

No iniciar bloque 06 ni cerrar 04/05 por este permiso. B03 permanece `CI_PASS_L2_VERIFICADO` hasta que la CI L3 real con todas las comprobaciones termine SUCCESS en un SHA concreto. No duplicar progreso ni declarar la cobertura de la demo igual a gameplay visual/GPU manual. IA6 verificará diffs compartidos **antes** de incorporar a la rama aislada.

**Acción W03:** retomar recuperación L3 del **mismo bloque 03** con una `p`; si el contrato exige modificar una API no listada, entregar prueba roja, interfaz exacta y STOP.
