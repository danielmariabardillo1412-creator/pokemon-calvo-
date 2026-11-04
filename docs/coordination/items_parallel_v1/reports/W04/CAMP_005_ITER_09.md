# IA4/W04 — CAMPAÑA_005 — Bloque 09/10 — Formas activas y restauración

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`  
**IDs autorizados:** `gracidea;meteorite;reveal_glass;rotom_catalog;zygarde_cube`  
**Estado inicial:** `EN_CI_AUTOMATICA`, no afirmar PASS sin leer logs GitHub.  
**Objeto del bloque:** identificar fronteras reales de transformación y guardado, sin confundir variantes con evolución ni sumar de nuevo objetos ya auditados.

## Matriz canónica

| Ítem | Especie(s) | Formas alternativas del snapshot | Contrato pendiente |
| --- | --- | --- | --- |
| `gracidea` | Shaymin | `shaymin-sky` (base `shaymin-land`) | uso de Gracídea, condiciones temporales/estado, reversión |
| `meteorite` | Deoxys | `deoxys-attack`, `deoxys-defense`, `deoxys-speed` (base `deoxys-normal`) | selector real de forma, persistencia |
| `reveal_glass` | Tornadus, Thundurus, Landorus, Enamorus | cuatro `*-therian` (base `*-incarnate`) | cambio reversible de forma para cuatro propietarios distintos |
| `rotom_catalog` | Rotom | `rotom-heat`, `rotom-wash`, `rotom-frost`, `rotom-fan`, `rotom-mow` | elección de electrodoméstico, estadísticas/tipos/movimientos y cancelación |
| `zygarde_cube` | Zygarde | `zygarde-10`, `zygarde-10-power-construct`, `zygarde-50-power-construct`, `zygarde-complete` (base `zygarde-50`) | células/núcleos, habilidades y reglas de forma; Complete NO es acción directa del Arca |

**Fuentes:** `data/api/v2/pokemon-species/{492,386,641,642,645,905,479,718}/index.json`; sus cadenas de evolución `{253,202,328,329,332,477,240,370}` contienen **cero aristas evolutivas**. Los datos de variedades son una evidencia de que existen formas; **no** son especificación del desencadenante por objeto. La cadena Zygarde incluye otras variedades que **no** autorizan introducir megaevolución u otros mecanismos en esta campaña.

**Incongruencia canónica conservada:** el snapshot PokeAPI presenta varias variantes de Zygarde pero `forms_switchable=false`. Ni se descartan las variedades por ello ni se inventa un botón de cambio instantáneo.

## Estado del juego y fronteras de implementación

- Los cinco IDs están `SELECCIONADO` como `STORY_KEY_OR_FORM_REVIEW` en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, pero `DATA_ONLY` en `ITEM_INVENTORY.csv` y `NOT_CERTIFIED` en `ITEM_FIELD_V8.csv.txt`.
- Ninguno consta en `modules/inventory/item_connections_v1.json::holdable_ids`. Son **herramientas/acciones de campo**, no objetos equipables que puedan activar una transformación al `equip`.
- `FieldItemService` implementa `use_item`, `evolve` y `equip`, pero no ha demostrado ningún enlace aprobado para las cinco acciones de forma. No insertar una falsa ruta `EvolutionSystem.TRIGGER_USE_ITEM`.
- `CreatureInstance` guarda `species_id` y `battle_transform_original` para transformación temporal, sin identidad persistente de variante (`form_id`), elección de aparatos, células ni reglas de reversión; SaveV2 no ofrece contrato de campos adicional para esas operaciones.

**Dependencias para árbitra IA6**: productor de uso en campo con selección de criatura y forma, condiciones temporalizadas y reversión de Shaymin, selector entre tres formas Deoxys, cuatro cambios con Espejo Veraz, catálogo de aparatos con actualización de movimientos Rotom y acumulador de células/núcleos Zygarde. Debe definirse cuándo la forma es persistente, cuándo se revierte por combate y cómo se migran guardados anteriores. Sin esos contratos, no activar silenciosamente formas ni gastarse objetos.

## Evidencias nuevas

1. `tests/fixtures/parallel_items/w04_campaign_005.json`: quinto conjunto autorizado de IDs, **ocho casos de especie** con variantes y dependencias (bloque 09), preservando 01–08.
2. `tests/tools/test_parallel_items_w04_campaign_005.py`: verifica selección, `DATA_ONLY`, no equipables, snapshot de ocho especies y cadenas sin evoluciones, distinción Power Construct y cinco destinos Rotom, cobertura Godot.
3. `tests/gameplay/parallel_items_w04_campaign_005.gd`: verifica variedades y cadenas; por cada especie crea criatura real, alterna casos PARTY/PC, contrasta uso de mochila/evolución/equipamiento rechazados sin mutación, tercero ajeno, preserva identidad e inventario, guarda/carga SaveV2 con IVs/EVs/experiencia/amistad/movimientos, y comprueba retorno al mismo estado al no ejecutar transformación.
4. `docs/coordination/items_parallel_v1/reports/W04/CAMP_005_PROGRESO.csv`: fila 09 `EN_CI_AUTOMATICA`; fila04 se conserva por bloqueo de conciliación anterior.

## Criterio de aceptación CI09

`CAMP005_W04_MANIFEST_PASS reserved=10 completed=9 ids=46 kind=FUNCTIONAL_BACKLOG`  
`CAMP005_W04_PY PASS blocks=9 checks=N`  
`CAMP005_W04_GODOT PASS blocks=9 checks=N`

con N positivo y **GitHub Actions completed/success real**. El PASS sería evidencia de pruebas de dependencia/guardado/rechazo, **no** de cambios positivos de forma. El workflow puede omitir regresiones históricas CAMP004/003/001 en bloque09, que se preservan para hitos programados.

**Aislamiento estricto:** solo fixture, test Godot, test Python, progreso e informe de W04. Sin modificación de `main`, etiqueta V28, otras ramas, producción compartida, PR118, migraciones, catálogos ni workflows.

**Próxima `p` tras cerrar bloque09:** bloque 10/10 `chipped_pot;cracked_pot;masterpiece_teacup;unremarkable_teacup;sweet_apple;tart_apple;syrupy_apple`, únicamente esa reserva.
