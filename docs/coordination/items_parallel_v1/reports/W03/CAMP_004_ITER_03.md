# IA3/W03 — CAMPAÑA_004 / MICROBloque 03

**IDs oficiales:** `fluffy_tail;golden_razz_berry;lure`. **Rama:** `codex/calvo-items-20261103-w03-camp004`.

## Evidencia de comportamiento actual

Los tres IDs están seleccionados en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` como `FIELD_USE`, pero las rutas actuales de `FieldItemService.use_item`, `FieldEffects`, `EncounterModifiers` y el perfil de recuperación no acreditan su ejecución. Su uso directo en campo termina en `DEPENDENCY_MISSING/field_effect_not_connected`. Esto **no significa que estén implementados**, sino que el rechazo actual evita gastar objetos sin un efecto válido.

- `fluffy_tail`: falta acción autorizada de huida en contexto de combate/encuentro. No inventar probabilidad ni forzar transiciones.
- `golden_razz_berry`: falta ruta confiable de uso de baya de captura (efecto, validez, consumo y ámbito). No tratarla como una baya curativa estándar.
- `lure`: falta integración con encuentros de mundo, duración y eventual persistencia. No aplicar un multiplicador arbitrario de encuentros.

## Pruebas añadidas

El runner Godot ejecuta `FieldItemService.use_item` sobre servicios reales, para cada ID con inventario 0/2 y criatura normal/dormida. Verifica rechazo y motivo, snapshot de Pokémon/inventario/relojes intacto, serialización autónoma de `PlayerInventory`, bloqueo de campo, corrupción de mochila y objetivo ajeno; no simula huida, captura con baya ni generación de encuentros. El auditor Python confirma selección, ausencia de registros funcionales, conexión de la prueba y negativos. Se mantienen las suites 01 y 02 de CAMPAÑA_004 y la regresión CAMP003 en CI.

**Interpretación:** `DEPENDENCIA_COMPARTIDA` para los tres; una CI verde acredita solo el rechazo seguro actual, no efectos de campo ni SaveV2 integral. La serialización de inventario es un roundtrip local, no un flujo de guardado real.

## Acción para IA6

Definir propietario y API de huida, uso de baya de captura y modificador/duración del Señuelo antes de integración en producción compartida. No tocar arquitectura ajena ni inventar reglas.

No se editaron `main`, V28, producción, workflows, catálogo, otras ramas ni PR #118. CI del SHA final de progreso: pendiente.
