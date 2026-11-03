# IA3/W03 — CAMPAÑA_004 / BLOQUE 05

**Reserva:** `repel;silver_razz_berry;super_lure`. **Rama exclusiva:** `codex/calvo-items-20261103-w03-camp004`.

## Estado real

Los tres IDs figuran en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` como objetos `FIELD_USE` seleccionados. La ruta actual `FieldItemService.use_item`, la definición de `FieldEffects`, los modificadores de encuentros y `imported_recovery_v19.json` no acreditan un ejecutor de uso directo para ellos. Su respuesta actual es `DEPENDENCY_MISSING / field_effect_not_connected`.

- **Repelente (`repel`)**: faltan pasos restantes, comparación fiable con el nivel del líder, elección de encuentros y transición de mapa/guardado.
- **Baya Frambu Plateada (`silver_razz_berry`)**: falta la transacción de baya aplicada al encuentro/captura; no debe asumirse que es una baya de curación.
- **Supercolonia (`super_lure`)**: falta la ruta de modificadores de encuentros y duración/persistencia de su efecto.

Los IDs seleccionados no demuestran un efecto operativo. Tampoco se ha creado un consumidor genérico que descuente objetos sin consecuencia.

## Pruebas añadidas

El runner Godot nuevo `_block_05` usa `FieldItemService.use_item` en tres estados de la criatura (normal, confundida, dormida) y con existencias 0/2. Exige rechazo exacto, preservación total del snapshot de equipo/bolsa/relojes, no consumo y conservación de confusión. Además comprueba rechazo por campo bloqueado, mochila corrupta, objetivo ajeno y `PlayerInventory.to_dict/from_dict` sin pérdida de unidades. El auditor Python confirma scope, inexistencia de rutas actuales, integración del runner y negativos. CAMPAÑA_004 acumula los cinco bloques; el workflow también ejecuta la regresión CAMP003.

**Alcance de certificación:** un PASS solo valida seguridad de rechazo y roundtrip básico de mochila, **no** Repelente, Baya Frambu Plateada o Supercolonia funcionales ni SaveV2 integral.

## Dependencias para IA6

Fijar propietarios y contratos de encuentros/pasos, efecto de baya en captura y duración de colonia; autorizar cualquier cambio de arquitectura de sesión/estado compartido antes de integrarlo.

Sin cambios de producción, workflows, catálogo, `main`, V28, PR #118 o ramas ajenas. **CI 05 pendiente** hasta comprobar SHA de CSV y recibos Python/Godot.
