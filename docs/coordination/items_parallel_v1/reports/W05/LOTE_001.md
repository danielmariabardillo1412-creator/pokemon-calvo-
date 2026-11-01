# W05 / LOTE_001 — auditoría de la familia MACHINE

**Reserva y responsable:** IA5 / W05, rama exclusiva `codex/calvo-items-20261101-w05`. **Estado final: `LISTA_PARA_REVISION`**. La marca inicial `OCUPADO_EN_AUDITORIA` se publicó con el commit `8a8edafb6eee131a8c39fcb041166d50a6958cfd`; este informe la sustituye por una entrega cerrada. Ninguna otra trabajadora debe asumir W05 hasta que IA6 revise.

- **Encargo original:** [LOTE_001_W05](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_001_W05.md).
- **Base propia de código/catálogo:** `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af` (V27). No se ha hecho merge ni rebase.
- **Referencia solo lectura V28:** `codex/items-v28-from-main` @ `7d49a23d15432b9e7845f2c8cd6b0ee5a88e286e`.
- **CSV exhaustivo por ID:** [MACHINE_GAP_LOTE_001.csv](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/MACHINE_GAP_LOTE_001.csv), **248 filas**, commit `1ccdccc1ffc0e7e20b59595fc583fa3e951ca83d`.
- **Archivos de producción modificados:** **NINGUNO**; únicamente marca/informe y CSV bajo `reports/W05/`.

## Resultado de la intersección exacta, sin confundir datos con funcionalidad

Se realizó un cruce **estático automatizado** de `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (`familia=MACHINE`), `ITEM_FIELD_V8.csv.txt`, `ITEM_INVENTORY.csv`, `modules/inventory/item_connections_v1.json` y `assets/local_item_catalog/manifest.json`. Se comprobó correspondencia **uno a uno**, ausencia de IDs sin mapa, categorías, variantes de versión y duplicados de movimientos de los IDs seleccionados.

| Magnitud | Resultado | Alcance |
| --- | ---: | --- |
| Seleccionadas MACHINE | **248** | 230 MT, 5 MO y 13 DT |
| Mapeadas en el adaptador de 338 | **248/248** | Definición **de datos**, no prueba de efecto |
| Seleccionadas con mapeo activo `scarlet-violet` | **229/248** | Son las 229 MT del perfil actual |
| Histórico V27 `TEACH_AND_CONSUMPTION_VERIFIED` | **229** | `FUNCION_Y_PRUEBA` **solo en alcance de V27 y sus tests** |
| Sin mapeo activo `scarlet-violet` | **19** | `DEPENDENCIA`, no 19 scripts nuevos |
| Otras máquinas mapeadas, pero fuera de la selección | **90** | 338 totales - 248 seleccionadas; no son trabajo de W05 |
| Máquinas V27 no activas (de las 338) | **109** | 19 seleccionadas + 90 no seleccionadas |
| Movimientos distintos entre las 229 MT activas | **229** | No se encontró duplicado activo→activo |
| Arte específico registrado para las seleccionadas | **1/248** | `tm01`, icono original; **247 sin entrada en manifest**, no implica que no haya fallback |
| Entradas nativas en inventario entre las 248 | **13** | Son DT; metadato nativo **no** equivale a enseñanza comprobada |

Por tanto, **248−229=19 coincide en esta selección tras el cruce de IDs**, no porque pueda restarse sin verificar. Las **229** ya cuentan con evidencia histórica de enseñanza/consumo; no deberían reprogramarse desde cero. **No se declara PASS nuevo de Godot ni certificación de 229 especies × máquinas ni de libro visual**.

### Diferencia exacta: 19 seleccionadas sin perfil jugable

El campo «movimiento de referencia» procede de la **versión histórica indicada**, NO es el movimiento que enseñaría en el perfil `scarlet-violet`. Se requiere decisión de perfil/compatibilidad antes de habilitarlo:

| ID | Movimiento de referencia | Versión referenciada | Observación |
| --- | --- | --- | --- |
| `hm01` | `cut` | omega-ruby-alpha-sapphire | MO, falta política y learnset |
| `hm04` | `strength` | omega-ruby-alpha-sapphire | MO, falta política y learnset |
| `hm05` | `waterfall` | omega-ruby-alpha-sapphire | **Solapa con `tm77` activa** |
| `hm06` | `rock_smash` | omega-ruby-alpha-sapphire | MO, falta política y learnset |
| `hm08` | `dive` | ruby-sapphire | No tiene mapeo ORAS; evitar inventarlo |
| `tm00` | `mega_punch` | sword-shield | No existe en perfil actual |
| `tr13` | `focus_energy` | sword-shield | DT; entrada nativa ≠ servicio activo |
| `tr19` | `tri_attack` | sword-shield | Ídem |
| `tr28` | `megahorn` | sword-shield | Ídem |
| `tr31` | `iron_tail` | sword-shield | Ídem |
| `tr39` | `superpower` | sword-shield | Ídem |
| `tr41` | `blaze_kick` | sword-shield | Ídem |
| `tr44` | `cosmic_power` | sword-shield | Ídem |
| `tr50` | `leaf_blade` | sword-shield | Ídem |
| `tr72` | `power_whip` | sword-shield | Ídem |
| `tr83` | `ally_switch` | sword-shield | Ídem |
| `tr85` | `work_up` | sword-shield | Ídem |
| `tr91` | `venom_drench` | sword-shield | Ídem |
| `tr93` | `darkest_lariat` | sword-shield | Ídem |

No se ha aprobado que una MO antigua actúe como habilidad de campo ni que una DT pase automáticamente a una MT. Primero debe resolverse diseño, perfil de aprendizaje, duplicación de efectos y consumo. El caso `hm05`/`tm77` es duplicidad **del movimiento** si se habilitan ambas, no duplicidad del ID ni fallo de ejecución actual.

## Código revisado y contratos existentes que hay que reutilizar

1. **Fuente/versiones:** `tools/item_audit/prepare_connections_v1.py` lee CSV de PokéAPI fijados por `tests/fixtures/item_connections_v1/primary/sources.json`, crea `machine_rows[item_id][version]`, valida 338 IDs y genera las 229 fixtures SV. `modules/inventory/item_connections_v1.json` mantiene `active_machine_version=scarlet-violet`. En el propio JSON, `machines.csv` se atribuye al commit externo `2bf639e5572812a67d2b94903fdcb9d095f5aeb2`, SHA-256 `f9df7faaf0a60896fa344abd2b639f83f79c2a24e1fd4bb3560ca7da76e9a6ad`. No se descargaron ni copiaron datos nuevos.
2. **Servicio de enseñanza compartido:** `modules/inventory/field_item_service.gd`, `machine_move` y `teach` (líneas 134–170), `use_item` (185). Comprueba servicio desbloqueado, propietario, inventario, pertenencia a `machine_rows`, versión activa, movimiento permitido y existente, learnset de especie/procedencia, incompatibilidad, ya conocido, sustitución explícita de ranura; aplica en copia de criatura y descuenta **una unidad solo tras éxito**. `owner.owned_creature` permite consultar propiedad, pero no se debe inferir que las 229 se probaron por separado desde PC.
3. **Mochila real:** `scenes/visual/field_item_bag.gd` utiliza `service.machine_move`, muestra movimiento según perfil, pide ranura y llama al servicio. **No existe contrato implementado de representación como libros por tipo para estas 248 entradas**. `manifest.json` registra solo `tm01` con icono original de máquina; los otros 247 carecen de registro específico. `scarlet_book`/`violet_book` son otros objetos de historia, **no** prueba del diseño de libros de MT.
4. **Guardado:** `tests/gameplay/item_connections_test_runner.gd` (líneas 214–257) ejercita la mochila real con `tm01`, evolución, equipamiento y guardado/carga. **No** proporciona un test de campaña/PC/guardado por cada una de las 229 MT.
5. **Selección:** `config/item_selection_v1.json` y `modules/inventory/item_selection_policy.gd` separan elegibilidad de contenido y funcionamiento. `ITEM_INVENTORY.csv:DATA_ONLY` en 235 de las 248 es inventario basal, **no** prueba de que las 229 estén desconectadas: la conexión posterior está en el adaptador/servicio.

### Coincidencia y divergencia frente a V28

Se compararon **SHA de blob de Git** entre W05/V27 y V28 para los archivos relevantes: `item_connections_v1.json` (`0525b37021edfc2e74c4fc2cb96e62f6f5b3e261`), `field_item_service.gd` (`b682c3af93b7af170c8aea66a130176c908b0745`), `item_connections_test_runner.gd` (`03e4b92e60ca870615945fffaedab1926e42aede`), `prepare_connections_v1.py` (`c9fa9e7e655e879abe0ad9d5878ac02b53ff88a9`) y `ITEM_FIELD_V8.csv.txt` (`9509d537622039b2f1919067561631449b8ddc47`). Los cinco son **idénticos por blob** en ambas ramas en el instante de consulta. Ello reduce el riesgo de duplicación de implementación de máquina, pero **NO certifica** una combinación futura con los demás cambios V28 (combate/progresión/CI).

## Pruebas concretas y alcance de resultados

| Prueba/inspección | Rama/versión | Resultado honesto |
| --- | --- | --- |
| Cruce estático de CSV+JSON por IDs (parser y aserciones en sesión de auditoría) | W05 base V27 + selección árbitra | **PASS ESTÁTICO**: 248 filas, 229 activas, 19 bloqueadas, 0 sin mapa, 1 entrada de arte; CSV publicado y releído (249 líneas con cabecera) |
| Presencia del motor local: `command -v godot || command -v godot4 || echo GODOT_NOT_INSTALLED` | Entorno de auditoría | `GODOT_NOT_INSTALLED`; no hay checkout del repo montado aquí |
| `python tools/item_audit/run_connections.py --gpu --regressions` | Comando existente, V27/V28 | **SIN_EJECUTAR**: Godot 4.7 no disponible, el repositorio no está montado para ejecución y el wrapper regenera adaptador/artefactos; no se escribe producción en LOTE_001 |
| Histórico `tests/gameplay/item_connections_test_runner.gd` (líneas 70–87 y 172–197) | Informe `docs/current/ITEM_CONNECTIONS_V1.json`, **2026-10-28** | **PASS HISTÓRICO DOCUMENTADO**: mapeo 338, 229 fixtures/una especie permitida por MT, PP, consumo, repetición sin consumo y guardia de actividad |
| Negativos generales `tests/gameplay/item_connections_test_runner.gd` (198–211) | Histórico V1 | Rechaza `hm03`/`tr00` (ambos **fuera de los 19**), no sustitución implícita con 4 ataques y no reanimar al enseñar `tm01`. **No** prueba los otros 19 por ID |
| Camino real `tm01` + guardado/carga + captura GPU | Histórico V1 | Informe V1: **4994** checks headless, **4996** checks GPU; regresiones registradas `field_native 118`, `savegame_v2 40/0`, `savegame_v2_adversarial 8/0`, `item_selection_policy 19`. No reejecutados aquí |
| Render de libros (aspecto, color por tipo, iconos, equipamiento/uso) | LOTE_001 | **NO REALIZADO**; no se debe presentar como aprobado |

**Evidencia histórica y sus límites:** [ITEM_CONNECTIONS_V1.md](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/current/ITEM_CONNECTIONS_V1.md) y [ITEM_CONNECTIONS_V1.json](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/current/ITEM_CONNECTIONS_V1.json), fase 2026-10-28; `ITEM_FIELD_V8.csv.txt` conserva el campo por ID. Un PASS histórico corresponde a su revisión original, no a pruebas ejecutadas ahora ni a una futura base V27+V28. No están en este informe los logs `.godot/` regenerados en una ejecución actual.

### Propiedad, consumo, PC, persistencia y negativos

- **229 activos, alcance verificado históricamente:** enseñanza por una especie elegible por ID, PP, cantidad −1 únicamente tras éxito, intento repetido sin mutación, bloqueo durante actividad.
- **Comprobaciones generales (no 229 × escenario):** criatura ajena, objeto ausente, movimiento no permitido o incompatible, movimientos ya conocidos, ranura inválida, cuatro ataques, PS cero, mochila real; parte tiene ruta implementada pero no matriz de PASS independiente por ID.
- **Persistencia:** la ruta del juego se prueba con `tm01`; los datos de criatura/mochila usan serialización propia de colección. No hay test por ID de cierre/carga para las 229.
- **PC y UI:** no existe prueba de **cada** máquina sobre objetivo almacenado ni de lista extensa de libros. No extrapolar del uso general de `owner.owned_creature`.
- **19 dependientes:** solo hay mapeo histórico de otras versiones; **no** efecto activo/consumo probado. Una entrada nativa TR o existencia en inventario es mera definición.
- **Verificación visual/GPU en la presente auditoría:** **NO REALIZADA**. La captura/ejecución GPU que cita V1 es histórica y prueba la mochila convencional, no los futuros libros.

## Automatización propuesta para el siguiente lote (NO implementada)

**Una sola capa declarativa reutilizable**, conservando los 338 IDs, su relación `item_id → versión → movimiento`, el servicio de enseñanza, las fuentes primarias fijadas y la política actual. Cuando IA6 apruebe checkpoint V27+V28:

1. Definir **un perfil de máquinas del propio Pokémon Calvo**, explícito por ID, con `move_id`, `learnset provenance`, `consumible`, `elegibilidad`, `formato_libro` y una política de colisiones de movimientos (ej. `hm05` vs `tm77`). No derivar el movimiento solo por número de MT.
2. Poner los libros en una capa de presentación/arte **compartida por familia/tipo**, sin alterar IDs de inventario ni guardar nuevos tipos por cada libro; preservar la ruta de `teach()`. Para todas las MT ya funcionales, no recrear lógica ni generar 248 GDScripts. Requiere revisión explícita del diseño visual antes de producir arte.
3. Añadir pruebas parametrizadas que iteren **exactamente los IDs seleccionados** y verifiquen la política aprobada, incluidos negativos, consumo, guardado/carga, PC y reimportación. Agrupar en un workflow controlado, **sin 248 ejecuciones de CI**.
4. Separar el alcance de **máquinas de enseñar movimientos** del uso de MO como habilidad de campo. Su efecto de campo no está autorizado por el presente encargo.

**Propiedad exclusiva / conflictos potenciales que IA6 debe resolver:**
- `modules/inventory/field_item_service.gd` (W02 medicina, W04 evolución, W05 máquina) y `scenes/visual/field_item_bag.gd` (todos los objetos de campo): archivo compartido, **no editar en paralelo**.
- `tools/item_audit/prepare_connections_v1.py`, `modules/inventory/item_connections_v1.json`, `tests/gameplay/item_connections_test_runner.gd`: comparten mapeo y tests entre familias, reservar propietario.
- `assets/local_item_catalog/manifest.json`, `scenes/visual/item_art_catalog.gd`: arte/UI compartido; un layout de libro debe decidirse antes de editar.
- `config/item_selection_v1.json`, `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, `QUEUE_V1.csv`, `main` y V28: **protegidos**, ninguna modificación autorizada.

## Autocontrol y entrega

**Se tocaron exclusivamente** `docs/coordination/items_parallel_v1/reports/W05/LOTE_001.md` y `docs/coordination/items_parallel_v1/reports/W05/MACHINE_GAP_LOTE_001.csv`, con marca de reserva, contraste de datos, dependencias y recomendaciones. **No** se tocó `main`, V28, ramas de otras W, código, tests, configuraciones, fuentes canónicas, producción, arte, colas ni selección activa. No se efectuaron merges, rebases o nuevas ejecuciones CI. Cualquier integración y asignación posterior depende de IA6.

**Estado final: `LISTA_PARA_REVISION`.** No iniciar LOTE_002 sin nueva asignación de la árbitra.
