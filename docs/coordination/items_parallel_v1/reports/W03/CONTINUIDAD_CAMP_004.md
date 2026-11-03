# IA3/W03 — Continuidad CAMP004 08/10

Bloque 08: fighting_tera_shard;fire_tera_shard;flying_tera_shard;ghost_tera_shard;grass_tera_shard. Pruebas Godot y Python acumuladas, inventario positivo y uso Tera todavía no funcional. El progreso CSV ya registra 08; verificar la CI del último SHA antes de certificar. Siguiente p: bloque 09 (ground_tera_shard;ice_tera_shard;normal_tera_shard;poison_tera_shard). Mantener main y V28 sin cambios.

---

# IA3/W03 — CONTINUIDAD CAMP004 07/10

**Rama única:** `codex/calvo-items-20261103-w03-camp004`. **Bloque 07 publicado:** `bug_tera_shard;dark_tera_shard;dragon_tera_shard;electric_tera_shard;fairy_tera_shard`. Se verifican mediante Godot real la selección, conservación y roundtrip de mochila y rechazo de uso sin API Tera; el auditor Python comprueba código y contrato, sin inventar transformación. **Estado de función por ID: `DEPENDENCIA_COMPARTIDA`; no `FUNCIONAL_VERIFICADO`.**

**CI previa 06 confirmada:** [#41575966667](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575966667), SHA `0fd53a96369fabc310e70b35a44f94477381aa7e`: CAMP004 Python 115/Godot 598 PASS; regresión CAMP003 Python 279/Godot 986 PASS.

**CI 07:** comprobar recibos Python y Godot `blocks=7` en último SHA de progreso. No confundir CI verde con capacidad Tera. Mantener separación de SaveV2 integral vs roundtrip `PlayerInventory`.

**Siguiente `p`: bloque 08** `fighting_tera_shard;fire_tera_shard;flying_tera_shard;ghost_tera_shard;grass_tera_shard` (cinco IDs). No adelantar sin nuevo `p`. Prohibido tocar `main`, V28, producción, PR #118 o ramas ajenas.

---

# IA3/W03 — CONTINUIDAD CAMP004 05/10

**Rama:** `codex/calvo-items-20261103-w03-camp004`. Se ejecutó solo bloque 05: `repel;silver_razz_berry;super_lure`. Estado de los tres `DEPENDENCIA_COMPARTIDA`: sus usos directos no tienen ejecutor actual; pruebas Godot y Python comprueban rechazo `field_effect_not_connected`, no consumo, mochila guardada/reconstruida, relojes intactos, confusión, dormido y bloqueos.

**CI previa 04 confirmada:** [#41574038050](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574038050), SHA `f99415d94bf3503b18f80213e555c284142b0463`, CAMP004 Python 82/Godot 360 PASS; regresiones CAMP003 Python 279/Godot 986 PASS. Gates aprobados.

**CI 05:** comprobar último SHA con progreso en 5 filas y recibos `CAMP004_W03_PY PASS blocks=5` y `CAMP004_W03_GODOT PASS blocks=5`. No afirmar PASS por runs previos/cancelados. Reparar errores propios en W03. Dependencias compartidas para IA6: encuentros con pasos/nivel de líder; baya de captura; duración de Supercolonia.

**Siguiente `p`: bloque 06** exactamente `super_repel;white_flute;yellow_flute`. No ejecutar otro bloque en este turno. No tocar `main`, V28, otras ramas ni módulos compartidos.

---

# IA3/W03 — CONTINUIDAD CAMP004 04/10

**Rama única:** `codex/calvo-items-20261103-w03-camp004`. **Bloque 04 entregado:** `max_lure;max_repel;red_flute`. Tres objetos seleccionados pero sin ejecución de campo autorizada. El runner prueba rechazo sin consumo/mutación para estado normal/dormido/confundido, bloqueo de campo, corrupción, objetivo ajeno y persistencia pura de inventario. No fingir curación, modificación de encuentros, contador de pasos o SaveV2.

**BLOQUE 03:** CI [#41573762889](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573762889) seguía en ejecución al arrancar 04; comprobar su estado, sin atribuirle PASS. La CI de 04 acumulativa vuelve a ejecutar bloques 01–04 y regresión CAMP003. Ejecutar reparaciones locales del arnés cuando proceda; no modificar APIs compartidas para forzar funcionalidad.

**Siguiente `p`: bloque 05** exclusivamente `repel;silver_razz_berry;super_lure`, previa comprobación del último run. Sin cambios de `main`, V28, ramas ajenas, políticas o producción. Dependencias para IA6: encontros/duración/pasos y cura de confusión.

---

# IA3/W03 — CONTINUIDAD CAMP004 03/10

**Bloque 03:** `fluffy_tail;golden_razz_berry;lure`. Los tres seleccionados pero sin ruta autorizada de efecto directo en `FieldItemService`; caracterización de rechazo sin consumo, estado intacto y roundtrip de mochila. Dependencias: acción de huida del combate, aplicación de baya de captura, y modificador/duración de encuentros. **No certificados funcionalmente.**

**CI 02 verificada:** [#41573170728](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573170728), SHA `539c5dcbdc3e3ffe59bf3b3764e290656a283e5e`, Python 43 y Godot 155, gates PASS; regresión CAMP003 Python 279/Godot 986 PASS. Flauta Azul sí funcional, no consumible.

**CI 03:** comprobar en el último SHA posterior a CSV. Si falla, reparar en rama propia; no ocultar dependencias. Próximo `p` será **bloque 04**, exactamente `max_lure;max_repel;red_flute`. Sin autorizar otros bloques ni campañas.

---

# Corrección de auditoría W03 / bloque 02

**Flauta Azul sí es funcional** según `imported_recovery_v19.json`: cura el sueño y no se consume. Pruebas Godot/Python actualizadas con caso positivo, sin sueño, sin objeto, guardas, serialización de inventario y limpieza de reloj. **No confundir con Flauta Negra/Cuerda Huida**, que siguen sin conexión de campo. Última CI debe ejecutarse con SHA actualizado tras esta corrección. El siguiente `p` sigue siendo bloque 03; no ejecutarlo en esta orden.

---

# IA3/W03 — CONTINUIDAD CAMP004 02/10

**Rama:** `codex/calvo-items-20261103-w03-camp004`. **Bloques publicados:** 01 Buceo/Ocaso/Acopio; 02 Flauta Negra/Azul/Cuerda Huida. **Próximo `p`: bloque 03 `fluffy_tail;golden_razz_berry;lure`, después de revisar CI.**

- Bloque 01 CI real [#41572312334](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572312334): Python 22 y Godot 69, además CAMP003 Python 279 y Godot 986, sin regresiones.
- Bloque 02: todos seleccionados en catálogo pero `FieldItemService.use_item` acaba en `field_effect_not_connected`. Suite nueva de rechazo real con y sin posesión, criatura dormida, guardas, objetivo ajeno y serialización de bolsa; no simula curación, encuentros, huida ni SaveV2 completo.
- **Dependencia compartida:** servicio de encuentros/efectos temporales para Flauta Negra; curación y regla de consumo para Flauta Azul; navegación/mapa/transición para Cuerda Huida. No modificar producción de otro dominio.
- Fixture y runner/Python acumulativos, `CAMP_004_ITER_02.md`, CSV 02 y cuaderno publicados. CI 02 debe dar `CAMP004_W03_PY PASS blocks=2` y `CAMP004_W03_GODOT PASS blocks=2` en el mismo SHA. Aún sin PASS hasta comprobar logs.
- Ningún cambio de `main`, V28, ramas ajenas ni workflows. No adelantar el bloque 03 sin otra `p`.

---

# IA3/W03 — CAMPAÑA_004: CONTINUIDAD 01/10

**Rama:** `codex/calvo-items-20261103-w03-camp004`. **Bloque 01:** `dive_ball;dusk_ball;repeat_ball`. **Siguiente `p`**: bloque 02 `black_flute;blue_flute;escape_rope`, tras revisar CI 01. No saltar fila ni recuperar CAMP003.

- Gate/cola: 10 bloques y 36 IDs; autorrreparación V5 aplicada solo en ámbito de captura. El bloque 01 no modificó producción.
- Diagnóstico: tres bolas sin entrada operativa en `CaptureRuleset`; faltan señales autoritativas de medio acuático, noche/cueva y especies capturadas antes. No hay permiso para inventarlas ni modificar productores de sesión.
- Pruebas nuevas: runner Godot real y auditor Python + fixture bloque01; contratos de `INVALID/unknown_ball` sin gasto/uso de RNG ni mutación, dos especies, dos modos PS y negativos prioritarios.
- Informe: `CAMP_004_ITER_01.md`. El CSV debe contener exactamente una fila tras publicar este lote. Verificar workflow sobre SHA final y salidas `CAMP004_W03_PY PASS blocks=1 checks=M`, `CAMP004_W03_GODOT PASS blocks=1 checks=M`, además de regresiones CAMP002/CAMP003.
- Estado: **CI pendiente** hasta validación de ejecución de HEAD. No dar PASS funcional a las tres bolas.
- Protección: `main`, V28, ramas ajenas, catálogo y workflows intactos. Si CI falla por test propio, reparar en esta rama; si se requiere política o productor compartido, documentar para IA6.
