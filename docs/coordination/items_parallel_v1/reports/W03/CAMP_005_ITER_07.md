## CI validada — bloque 07

[GitHub Actions #41727546334](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727546334), SHA `2a944b4c1a70de7ba19ea65106e17ece8271e5ba`, **completed/success**. Recibos `CAMP005_W03_PY PASS blocks=7 checks=126`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=7 checks=148`, `CAMP005_GATE_GODOT_PASS`. Las pruebas acreditan la regla existente de frecuencia de encuentros y las dependencias del mundo; no implementan los cinco efectos de campo.

---

# IA3/W03 — CAMPAÑA_005 / BLOQUE 07

**Reservados de backlog previo, no nuevos:** `black_flute;white_flute;lure;super_lure;max_lure`. Rama única: `codex/calvo-items-20261103-w03-camp005`.

## Evidencia real y frontera compartida

`WildEncounterTable.encounter_chance_bp` y `WildEncounterSystem.resolve()` permiten cambios de probabilidad deterministas bajo un productor válido de tablas. `modules/gameplay/encounter_item_modifiers.gd` ya demuestra un contrato positivo para `cleanse_tag`/`pure_incense`: `modified_chance_bp(6000) == 4000`, con copia validada y sin mutar la tabla original. **Ese contrato no implementa Flauta Negra, Flauta Blanca, Señuelo, Superseñuelo ni Señuelo Máximo.** `FieldItemService.use_item` no publica un efecto duradero de esa familia, y el motor de encuentros no conoce los pasos ni el tiempo del mundo.

**Productor faltante:** coordinador de movimiento/encuentros del mundo que conozca la tabla de zona, el contador de pasos o período del modificador, duración y política de apilamiento/sustitución y persistencia. **Consumidores:** uso de objeto en campo, estado activo de modificación de frecuencia y generador de encuentros previa verificación de tabla. Se necesita un contrato de mínimos pasos entre encuentros; alterar solo la probabilidad no reproduce necesariamente el efecto de un señuelo o flauta.

## Decisiones que debe tomar IA6

- Fijar el perfil/versionado de los cinco efectos (factor de frecuencia, duración, unidades de duración, acumulación y restricciones por zona).
- Asignar dueño del contador de pasos/reloj, manejo de equipamiento/consumo, guardado/restauración y recuperación de estado.
- Determinar la composición con Repelentes (bloque06) y Cleanse Tag/Pure Incense, y el momento de evaluar cada condición sin tiradas de RNG adicionales.

## Pruebas nuevas

`tests/gameplay/parallel_items_w03_campaign_005.gd` ejecuta `_block_07`: positivos del helper real de frecuencia, límites, reconstrucción de tabla, comprobación de validación del nuevo valor, inmutabilidad de origen, cinco IDs seleccionados y ausencia de activación como objetos equipables. `tests/tools/test_parallel_items_w03_campaign_005.py` comprueba productoras y consumidoras fuente, ID exactos, el contrato de mundo y que la prueba Godot es ejecutable. No se limita a repetir antiguos rechazos de uso.

**Estado por ID:** `DEPENDENCIA_COMPARTIDA`; no declarar flautas/señuelos funcionales. **Código de producción:** sin cambios; no se alteraron `main`, V28, PR #118, otras ramas ni APIs compartidas.

**CI:** comprobar recibos `CAMP005_W03_PY PASS blocks=7`, `CAMP005_W03_GODOT PASS blocks=7` y gates IA6 sobre SHA definitivo con 7 filas en CSV antes de marcar el bloque validado.
