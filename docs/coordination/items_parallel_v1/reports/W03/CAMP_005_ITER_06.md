# IA3/W03 — CAMP005 bloque 06: reintento completado y pruebas publicadas

**Reserva:** `repel;super_repel;max_repel`. En el reintento se logró publicar el runner Godot `_block_06` (commit `9ae2821be2e2efda7f97a32e8f28b8d7a3ad4548`) y el auditor Python (commit `ef7cde0aafbeed13ee360ab07306211f23e2aa76`). El bloqueo anterior de actualización ya no afecta a esos dos archivos.

El runner usa `WildEncounterTable` y `WildEncounterSystem.resolve` reales: tabla con probabilidad cero, resultado NONE y RNG intacto, tabla de probabilidad garantizada con Caterpie nivel 8, roundtrip de tabla y selección de tres repelentes. El auditor comprueba el código productor y consumidor actual, la ausencia de ruta funcional Repel en `FieldItemService`/`EncounterItemModifiers` y los tres contratos de mundo.

**Clasificación funcional:** `DEPENDENCIA_COMPARTIDA`. No se ha implementado un contador de pasos del mundo ni el filtro salvaje vs nivel líder. Un cero de probabilidad no equivale a Repel: es solo un caso de control del motor. IA6 debe coordinar propietario de pasos, duración por objeto, estado persistente y filtro previo a encuentro sin perturbar RNG.

**CI:** verificar recibos `CAMP005_W03_PY PASS blocks=6`, `CAMP005_W03_GODOT PASS blocks=6` sobre último commit de progreso antes de declarar cierre. No se tocan producción, `main`, V28 ni ramas ajenas.

---

# IA3/W03 — CAMP005 BLOQUE 06 — ENTREGA PARCIAL / BLOQUEO DE EDICIÓN

Reserva oficial: `repel;super_repel;max_repel`. Rama exclusiva: `codex/calvo-items-20261103-w03-camp005`.

## Trabajo publicado
- Fixture W03 CAMP005, bloque 06, commit `8dbb7e5f02ef0acba93e03a63955ab1693673a26`; declara `DEPENDENCIA_COMPARTIDA` para los tres IDs y especifica productor, consumidor y decisiones.
- Se inspeccionaron `WildEncounterSystem.resolve`, `WildEncounterTable`, `WildEncounterSlot`, `WildEncounterRuleset`, `EncounterItemModifiers` y `FieldItemService`.

## Contrato comprobado en código

El motor de encuentros valida tablas, admite `encounter_chance_bp=0` (sin generar encuentro ni consumir RNG), y permite posiciones y niveles de slots. El componente `EncounterItemModifiers` implementa probabilidad modificada por `Cleanse Tag`/`Pure Incense`, pero **no implementa repelentes** ni contador de pasos, y deja expresamente fuera la semántica de pasos. `FieldItemService.use_item` tampoco gestiona Repel/Super Repel/Max Repel.

Productor faltante: **propietario del mapa/movimiento**, que emita pasos que cuenten y el estado de efecto restante, nivel efectivo del líder y el origen del encuentro; persistencia y recuperación del contador. Consumidor: **coordinador previo a WildEncounterSystem.resolve**. Debe decidirse fuente de cada duración (generación/perfil), activación, reemplazo, caducidad, umbral nivel líder vs salvaje y política de RNG. No debe modelarse un repelente configurando la tabla a probabilidad cero: esa conversión rechazaría también encuentros válidos según nivel.

## Bloqueo técnico y precauciones

Intentada la publicación del runner `tests/gameplay/parallel_items_w03_campaign_005.gd` dos veces mediante la operación oficial de actualización. La herramienta devolvió `Esta llamada a la herramienta se ha bloqueado por los controles de seguridad de OpenAI` en ambos intentos. **No se ha publicado el runner nuevo**, ni el auditor Python del bloque 06, ni la sexta fila del progreso; no se ha lanzado CI nueva. Mantener el bloque **INCOMPLETO**. Próxima `p`: intentar completar este bloque 06, NO iniciar 07, si la herramienta vuelve a permitir las actualizaciones. Sin modificar `main`, V28, producción o ramas ajenas.
