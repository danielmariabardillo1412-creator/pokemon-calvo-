# IA6 — W03 · NUEVA CAMPAÑA CONTINUA V5 ACTIVADA · REPELENTES + MOCHILA + CAMPO

**Rama ÚNICA de trabajo**: `codex/calvo-items-20261111-w03-repel-staging-v5`. Esta rama se creó desde la V4 W03 completada, pero es una misión distinta; NO volver a certificar V4 ni editar la rama entregada. V4 está READY_FOR_IA6_MERGE_CAPTURE con CI #43068968046 SUCCESS; Repel sigue ausente de la staging y de IA6 oficial.

**PRÓXIMA `p` O `sigue`**: comprobar working tree, HEAD, leer `docs/coordination/items_parallel_v1/CONTINUOUS_V5/STATE_W03.md` y el plan íntegro de abajo. Ejecutar **FASE A paso 1**: incorporar la prueba real de repelentes desde W03 histórica como test, demostrar RED en la staging, comparar los cuatro archivos por función. Proseguir fases B→C sin detenerse cada diez tareas, con checkpoint y CI de SHA exacto. No esperar a otra tanda si el plan tiene pendientes. No atribuir trabajo en segundo plano.

**Nueva autorización IA6 acotada** en rama V5: `FieldItemBag` SOLO _refresh_choices/_apply/_apply_repel para los tres repeles; `field_demo.gd` SOLO pasos/encuentro/estado SaveV2; `field_native_bridge.gd::on_step` SOLO bloqueos repel. Proteger libros W05, Cuerda Huida, legado Repeat, menta efectiva, política de exclusión de dynamax_candy y todas las ramas ajenas. No copiar archivos globales ni hacer merges.

**Autoridad central**: `docs/coordination/items_parallel_v1/CONTINUOUS_V5/PLAN_W03.md` en `codex/calvo-items-20261101-arbitro`. El siguiente plan está copiado completo para evitar depender de lecturas cruzadas.

---

# ORDEN IA6 / W03 — CONTINUOUS V5 · REPELENTES EN MOCHILA + CAMPO + SAVEV2

Fecha 2026-11-11. **Rama NUEVA exclusiva**: `codex/calvo-items-20261111-w03-repel-staging-v5`, derivada de `codex/calvo-ia6-staging-20261111-w03-capture`. V4 queda entregada/fijada: captura nativa + Wild legacy, CI **#43068968046 completed/success** SHA `5a82da2a9dd1a868c3f8af9d73551fe16571adea`. NO repetir V4 ni atribuir su CI a V5. Entrega V4 `READY_FOR_IA6_MERGE_CAPTURE / REPEL_SHARED_SEAM_PENDING`; la integración oficial sigue NO realizada.

## Objetivo legítimo y fuente exacta
Resolver el ticket `CONTINUOUS_V4/W03_REPEL_BAG_GAP.md` en una staging **exclusiva W03** sin tocar la integradora oficial ni las ramas de W05. El origen W03 `codex/calvo-items-20261104-w03-camp006` ya tiene código y prueba `tests/gameplay/parallel_items_w03_repel_l3.gd` para:
- `repel` 100 pasos; `super_repel` 200; `max_repel` 250.
- consumo exactamente 1 desde mochila; no consumir si ya hay efecto activo, inventario desactualizado o guard falso;
- supresión de salvajes de nivel inferior al líder (igual o superior se permite), movimiento real `OverworldPlayer.step_completed`, RNG comprometido una vez para encuentro suprimido, sin crear batalla;
- estado persistido manualmente con SaveV2, carga antigua sin campo, rechazo de corrupción sin mutar estado vivo.

La staging W03 V4 actual ya incluye **libros W05 + Cuerda Huida** en la mochila de la base IA6, además de Repeat, Net, Moon y naturaleza efectiva. **IMPORTANTE**: W05 también ha entregado después una staging V4 propia #42965926888, con mejoras en `FieldItemBag`. Esa entrega NO está integrada en esta nueva rama W03. La prueba aquí puede acreditar solo convivencia con el baseline disponible; IA6 integrará después los hunks W05 más recientes y repetirá CI cruzada. No afirmar convivencia total ni merge oficial.

## Fase A — Prueba roja y diferencias REALES
1. Verificar HEAD/working tree, `IA6_AUTORUN.md`, `CONTINUOUS_V5/STATE_W03.md`, el ticket y las CI/SHAs V4; diferenciar source antiguo y staging. No perder cambios sin publicar de la ventana V4.
2. Reproducir `tests/gameplay/parallel_items_w03_repel_l3.gd` **inalterado** en V5 (traerlo como test desde origen W03), señalar los fallos reales y explicar qué función falta. Probar también los escenarios negativos, no tratar PASS anterior de origen como V5.
3. Comparar por función las siguientes fuentes antiguas vs staging: `modules/overworld/field_repel_step_effect.gd` (nuevo helper), `scenes/visual/field_item_bag.gd` (`_refresh_choices`, `_apply`, `_apply_repel`), `scenes/visual/field_demo.gd` (estado, encuentros, guardado/carga), `scenes/visual/field_native_bridge.gd::on_step`. Registrar diff exacto y dependencias sin copiar ficheros completos.

## Fase B — Trasplante autorizado, acotado
**AUTORIZACIÓN NUEVA ESPECÍFICA DE IA6 EXCLUSIVAMENTE EN ESTA RAMA** para:
- Añadir helper `modules/overworld/field_repel_step_effect.gd` y sus pruebas W03.
- Editar **solo** `_refresh_choices`, `_apply` y nuevo `_apply_repel` en `scenes/visual/field_item_bag.gd` para los 3 IDs. La selección no debe requerir Pokémon para activar repel. PRESERVAR exactamente `_open_machine_books`, `_on_book_teaching_finished`, panel, señales, `_apply_escape_rope` y su callback, y el orden de actualización. Ningún duplicado de panel ni de consumo.
- Editar solo los puntos mínimos de `scenes/visual/field_demo.gd` necesarios para inicializar/adjuntar el efecto a movimiento real, aplicar bloqueo de encuentros, incluir estado en snapshot, validar/restaurar la porción opcional de repel en SaveV2. No cambiar reglas generales de encuentros, especies, combate, generadores o UI.
- Editar **solo** `on_step` de `scenes/visual/field_native_bridge.gd` para aceptar `blocked_by_repel` y aplicar el avance de RNG según el contrato existente, sin abrir batalla ni consumir `next_battle_seed`.
- Añadir tests y workflow W03 V5, CSV/checkpoints/report. NO modificar `FieldItemService`, `FieldNativeSave`, `SaveGameData`, `PlayerCollection`, `WildAdventureSession`, `ShowdownAdventureSession`, `CreatureInstance`, motor JS, RNG global, catálogos/política, W05 staging, IA6 oficial, main, V28 o PR118.

**Puertas B**: para los tres ítems, ejecutar mochila real → efecto → desplazamiento real → encuentro bajo líder bloqueado/igual nivel permitido → decremento hasta expiración → consumo/rollback → guardado/carga manual → legacy sin campo y corrupción. Probar idempotencia, señal única, abrir/cerrar libro y Cuerda Huida sin regresión, menta y SaveV2. Jamás inventar productor `heavy_ball`, `beast_ball` ni de pesca/zona/sexo.

## Fase C — Certificación y entrega
1. Mantener green original Repeat Legacy `W03_REPEAT_V2_GODOT PASS checks=37` **sin waiver** y Repeat/Net/Moon nativa, historia capturas, persistencia, 7/7 rutas W04 solo si están disponibles en esta rama (si no, reportar dependencia). Guardas `dynamax_candy` excluido y W05 libros+Cuerda Huida del baseline. No declarar PASS de suites no ejecutadas.
2. Ejecutar Godot/Python de W03 V4 + nuevo Repel L3, CI de V5 sobre SHA exacto, negativa de corrupción/stock/doble pulsación; si falla reparar únicamente dentro de funciones autorizadas. CAMP003–006 u otras suites ausentes: documentar qué falta y reservar la CI central de IA6; no alterar tests históricos para ocultar FAIL.
3. Publicar `docs/coordination/items_parallel_v1/reports/W03/CONTINUOUS_V5_FINAL.md`, diff por función con blob/SHA, checklist de compatibilidad de W05 V4 más reciente, `CONTINUOUS_V5/STATE_W03.md` como `READY_FOR_IA6_MERGE_REPEL_CANDIDATE`. **No** declarar integración oficial ni activar V6 por iniciativa propia. No rondas de QA vacías.

## Autonomía y reglas de barra
Una `p` reanuda la primera fase/tarea V5 pendiente y enlaza A→B→C en el mismo turno cuando sea posible; checkpoint en GitHub si el turno se agota. Solo detener si todas las tareas independientes certificadas o hay bloqueo real en archivo protegido, con ticket. Métrica `V5 A/B/C | 3 repelentes examinados | L3 por ítem | fallos/rollback | QA books/rope | CI/SHA | integración IA6 NO`. No confundir tres ítems ya existentes con tres objetos creados. No ejecución en background.
