# ESTADO FINAL VIGENTE — CAMP_001 / IA5-W05 (2026-11-02)

**`CAMPAÑA_001_FINALIZADA` como entrega, 03/03 microbloques publicados. STOP: no ejecutar más `p` ni una campaña 002 sin orden de IA6. ITER_03 sigue `PREPARADO_PENDIENTE_CI`, NO certificado funcionalmente.** Esta cabecera prevalece sobre las secciones históricas.

- **Autoridad:** `CAMPAIGN_GATE_UPDATE_004.md`, blob `5a96d80793d0c438ee005d366655f42e9cd4074b`; autorización exacta para ITER_03, sin ampliar permisos. `campaigns/CAMP_001_W05.md` blob `ce0e5763accadecc9c4ee971b13dae7dba23a2ef`.
- **Rama:** `codex/calvo-items-20261101-w05`; sincronizada mediante merge de dos padres sin force `dcfce415e94e574a41c8d9da0ec1940a4e12ac9e` con árbitra `eaa7d7fca46dc4f92dedd2acebb0a15894929f26`. Se conservaron todos los informes propios. No se editó ninguna rama ajena.
- **ITER_01:** adaptador solo lectura, certificado anteriormente con 18 checks en Godot por IA6.
- **ITER_02:** etiquetas canónicas y clasificación por tipos de 229 activas, rechazo de 19 heredadas, Godot **959/0** y Python **14 PASS** sobre código integrado, [CI #41362733419](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41362733419), SHA `ef823e0d045c9d63b72905db638db5255ff10f06` (PASS).
- **ITER_03 nuevo:** solo `tests/gameplay/parallel_items_w05_machine_books_v1.gd`, último commit de prueba `c48491a3e50f0386cec76d72402b1e5cdcd4d3e3`, blob `10c1d7a7eeac79a83a2e9a1183f1c663aaf1955e`. Prueba `tm01/tm02/tm77` mediante `FieldItemService.teach`, PP, gasto 2→1, rechazo sin gasto, mismo propietario, guardado/carga aislado y 19 negativas legadas. La verificación estática de GitHub fue favorable (248=229+19, cero IDs faltantes/duplicados); **Godot sobre ITER_03 SIN_EJECUTAR**, sin GPU/arte/UI.
- **Documentación:** `CAMP_001_ITER_03.md`, `CAMP_001_FINAL.md`, `CAMP_001_PROGRESO.csv` al día. Informes anteriores intactos. En el propio informe no incluir SHA final futuro: recuperar HEAD de la rama.
- **Reproducción CI a cargo de IA6:** `godot --headless --path . --script res://tests/gameplay/parallel_items_w05_machine_books_v1.gd`. Si falla, IA6 debe clasificarlo; no asumir resultado verde ni cambiar tests para fabricar PASS.
- **Pendiente:** validación real de ITER_03, revisión final IA6, GPU/arte/UI, política de las 19 heredadas; un cierre de 3 microbloques **no certifica juego completo**.
- **Prohibiciones permanentes:** `main`, V28, PR #118, otras W, árbitra, `FieldItemService`, datos, selección, guardados y archivos compartidos. Nunca activar 19 heredadas por deducción ni crear un nuevo servicio de enseñanza.

---

# ESTADO VIGENTE — CAMP_001 ITER_02 (IA5/W05, 2026-11-01)

- **Estado operativo: `PREPARADO_PENDIENTE_CI`, 02/03 entregados.** Próximo `p`: únicamente ITER_03; no repetir 01/02. Esta sección sustituye el estado antiguo de recuperación del bloque 01, conservado debajo como historial.
- **Autoridad vigente:** `CAMPAIGN_GATE_UPDATE_003.md` (árbitra, blob `59c553bd7a931ebe4ac10bf4b2b3ce43815220dc`) autoriza expresamente ITER_02 W05. CI previa del adaptador 01 verificada 18 checks Godot, integración `39df72c1`, run [#41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378) PASS. La CI final de árbitra [#41354759130](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41354759130) también figura `completed/success` en GitHub.
- **Rama exclusiva:** `codex/calvo-items-20261101-w05`. Sincronizada sin force por merge de dos padres `9d01b3c985915d2070d5d41aa77429df44fc4d01` con árbol de árbitra `8e170550881861daa3a3aefe8aa91909decf84af`, preservando los tres documentos W05 ausentes en árbitra. Sin edición de `main`, V28, otras W ni rama árbitra.
- **ITER_02 producción propia:** `modules/inventory/field_machine_book_profile.gd`, commit `74e68e55d5d5abbdaf49e2afc6a956f828eeebe2`, blob `b37ff2d0610cce8f49a554f4632afa0f33a37c25`. La nueva `presentacion()` reutiliza `consultar()` y `SpanishGameText` para etiqueta y tipo; no implementa `teach`, consumo, gráficos o nuevas políticas.
- **ITER_02 test propio:** `tests/gameplay/parallel_items_w05_machine_books_v1.gd`, commit `6d15aba76b8f69874012cd28aa0a2c06c096adc1`, blob `474b66ea4c643564b431e6ea9f6a3304e45c7802`. Lee el CSV de selección y comprueba 229 descripciones canónicas y 19 rechazos. Comando: `godot --headless --path . --script res://tests/gameplay/parallel_items_w05_machine_books_v1.gd`.
- **Evidencia de ITER_02:** análisis estático de GitHub sobre 248 IDs (229 SV + 19 heredadas), 0 duplicados, 0 faltantes y detección de lectura sin escrituras; **Godot sobre código de ITER_02 SIN_EJECUTAR**, CI nueva PENDIENTE, GPU/visual PENDIENTE. El PASS anterior cubre solo ITER_01.
- **Documentación:** `reports/W05/CAMP_001_ITER_02.md` y segunda fila de `CAMP_001_PROGRESO.csv`; no modificar reportes previos. LOTE_001/LOTE_002 conservados.
- **Puerta antes de ITER_03:** IA6 debe ejecutar CI Godot sobre el nuevo adaptador de ITER_02 y registrar PASS, o emitir una autorización expresa que resuelva la dependencia; un `p` sin esa evidencia solo permite comprobar el estado, no adelantar el bloque. Después, con nuevo `p`, ITER_03 comprobará enseñanza/PP/consumo mediante `FieldItemService.teach` sin duplicarlo; IA6 conserva la propiedad de CI e integración. Al cerrar 03 crear `CAMP_001_FINAL.md` y detenerse.
- **Límites:** no tocar esquema de guardado, selección, `field_item_service.gd`, `field_item_bag.gd`, fuentes de movimiento, assets ni 19 heredadas. La presentación todavía no está incorporada a UI real ni aprobada artísticamente.

---

# RECUPERACIÓN VIGENTE — CAMPAÑA_001 / ITER_01 (IA6, 2026-11-01)

- **Estado operativo actual: `PREPARADO_PENDIENTE_CI`, 01/03 preparado.** Esta sección prevalece sobre el histórico de activación `0/3` que se conserva íntegro más abajo.
- **Motivo:** la conexión utilizada por W05 rechazó varias escrituras después de publicar el adaptador `318e6b96`. IA6 confirmó que la rama acepta escrituras y reconstruyó prueba/informe/progreso mediante intervención puntual solicitada por la persona usuaria.
- **Archivos de la recuperación:** `modules/inventory/field_machine_book_profile.gd` (ya publicado por W05); `tests/gameplay/parallel_items_w05_machine_books_v1.gd` (publicado y ajustado por IA6, `62741e4d`); `CAMP_001_ITER_01.md`; `CAMP_001_PROGRESO.csv`.
- **Comprobación externa disponible:** cotejo estático 248 MACHINE = 229 activas SV + 19 heredadas no habilitadas, sin IDs ausentes del perfil; el probe nuevo Godot NO se ha ejecutado aún.
- **No ejecutar de nuevo ITER_01 para generar archivos iguales.** En el siguiente `p`, revisar antes puerta/STATUS, este informe, HEAD y evidencia CI. El contrato del microbloque incluyó un adaptador de producción nuevo; si la CI Godot del SHA no está disponible, elevar el gate pendiente a IA6 antes de pasar al 02. Si falla, STOP.
- **Permisos sin ampliación:** ninguna edición de `main`, V28, ramas ajenas o ficheros no autorizados. IA6 no toma la propiedad continuada de W05; la trabajadora conserva la responsabilidad de los bloques restantes.

---

# IA5 / W05 — CUADERNO DE CONTINUIDAD · MACHINE

## Actualización de campaña — activación (2026-11-01, anterior al primer `p`)

- **Orden vigente:** `campaigns/CAMP_001_W05.md` en árbitra, blob `ce0e5763accadecc9c4ee971b13dae7dba23a2ef`. `CAMPAIGN_GATE_001.md` `ACTIVADA`, blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`.
- **Base autorizada sincronizada:** rama W05 actualizada por **fast-forward sin force** de `c0683bf49c7de1356266b5e7610af816d941c327` a árbitra `1b52fdd0b7b89e468811a17ad83a917ec7107735` (W05 era ancestro; comparación Git 42 commits ahead/0 behind). Los blobs de `LOTE_001.md`, `LOTE_002.md`, CSV propio y este cuaderno permanecían idénticos antes de esta actualización de cuaderno.
- **CI base acreditada por GitHub:** [Actions #41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), commit `ac34fabbe1a27e69614f0239abee21c29d6fe65e`, resultado `completed/success`. No certifica cambios futuros de libros.
- **Estado de campaña:** `ACTIVADA_PENDIENTE_MICROBLOQUE_01`. **Microbloques ejecutados: 0/3.** El mensaje de activación no cuenta como `p`; siguiente `p` autoriza únicamente bloque 01 (consulta de máquina y movimiento/tipo). No se ha creado `field_machine_book_profile.gd` ni nuevas pruebas, ni se ha tocado producción en este turno.
- **Límites vigentes:** solo las rutas W05 listadas en `CAMP_001_W05.md`, ninguna política nueva y ninguna activación de las 19 heredadas. Ante fallo/parada, no adelantar 02/03.

## 1. Identidad, alcance y autoridad

- **Identidad:** IA5 / W05; familia MACHINE (máquinas/libros de movimientos).
- **Rama de trabajo exclusiva:** `codex/calvo-items-20261101-w05`.
- **Última orden oficial leída:** [`assignments/LOTE_002_W05.md`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_002_W05.md), blob **`b8f8df20cc70ab9ca7004c7b692a59537fc3efd7`**.
- **Estado:** `LISTA_PARA_REVISION` de LOTE_002 (todavía NO integrado ni certificado en Godot). No hay LOTE_003 asignado.
- **Base inicial propia:** `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af`. **Checkpoint autorizado IA6:** `38188cc208e67b19002437ac75160898ce332ec2`. **Fusión segura en W05:** `239edd8083a0980e556dfe04079e03f04b09e89e` (dos padres; sin `--force`, LOTE_001 intacto).
- **Último commit de informe previo a este cuaderno:** `9435b86350c11edd35b190e10acdae1edca8cf41`. Para recuperar el HEAD final leer la rama W05 en GitHub; el propio documento no puede contener su SHA futuro de forma autorreferencial.
- **Pruebas funcionales ejecutadas sobre la base combinada:** **NINGUNA**. Estado de verificación completo: `PENDIENTE_CI`.
- **Rutas permitidas para este lote:** solo `tools/item_audit/parallel_w05_machine_scope.py`, `tests/tools/test_parallel_w05_machine_scope.py`, `tests/fixtures/parallel_items/w05_machine_scope_v1.json` y `reports/W05/{LOTE_002.md,CONTINUIDAD.md}`. Prohibido producción.

## 2. Mapa de implementación existente (NO rehacer)

**Fuentes:** `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (248 seleccionadas), `docs/current/ITEM_FIELD_V8.csv.txt`, `docs/current/ITEM_INVENTORY.csv`, `modules/inventory/item_connections_v1.json` (338 IDs con mapas por versión, solo SV activo), `tests/fixtures/item_connections_v1/primary/sources.json` (fuente PokéAPI fijada).

**Adaptador:** `tools/item_audit/prepare_connections_v1.py` regenera relaciones canónicas `ID→versión→move_id` y fixtures de máquinas activas, sin tocar datos fuente. La ruta nativa ya se implementó antes de W05: `modules/inventory/field_item_service.gd:machine_move(),teach(),use_item()` selecciona versión, valida movimientos, especie, propiedad, estado de mochila y ranura; prepara criatura/bolsa y consume una unidad al éxito, no al rechazo.

**UI/guardado:** `scenes/visual/field_item_bag.gd` presenta una acción de enseñar y previsualiza el movimiento correcto; `tests/gameplay/item_connections_test_runner.gd` incluye una ruta `tm01` de mochila, guardado/carga e integración, **no 229 pruebas por ID en PC/guardado ni libros visuales**. Existe `scenes/visual/item_art_catalog.gd` y manifest de arte; de las 248 solo `tm01` tenía entrada gráfica registrada en LOTE_001.

**Propiedad de archivos:** `field_item_service.gd`, `field_item_bag.gd`, `item_connections_v1.json`, `assets/local_item_catalog/manifest.json`, políticas, tests anteriores y configuración de CI son compartidos/reservados. IA6 debe serializar cualquier edición de producción futura. En LOTE_002 se dejaron intactos.

## 3. Estado comprobable por subfamilia

| Subfamilia | Cantidad seleccionada | Fuente de prueba/estado | Límite actual |
| --- | ---: | --- | --- |
| MT `tm01`–`tm229` | 229 | `ITEM_FIELD_V8.csv.txt` + `ITEM_CONNECTIONS_V1.json` y `item_connections_test_runner.gd:172–197`, **PASS histórico V27 (2026-10-28)** | Una especie/MT en evidencia anterior; no PASS funcional del checkpoint combinado |
| MT antigua `tm00` | 1 | Perfil mapeado en `sword-shield`, no `scarlet-violet` | `DEPENDENCIA`: norma de versión/aprendizaje y consumo |
| MO `hm01/hm04/hm05/hm06/hm08` | 5 | Mapa histórico existente; `hm05` enseña `waterfall` en ORAS y solapa `tm77` SV | No habilitar efecto de campo ni enseñar sin política. `hm08` usa fuente `ruby-sapphire` |
| DT `tr13/tr19/tr28/tr31/tr39/tr41/tr44/tr50/tr72/tr83/tr85/tr91/tr93` | 13 | Mapa `sword-shield`; metadatos nativos de DT existentes | No son jugables en el perfil SV; entrada nativa ≠ ruta de uso |
| 90 máquinas canónicas fuera de selección | 90 | Total 338 mapeadas − 248 seleccionadas | No asignadas: no activarlas por accidente |
| Presentación gráfica tipo libro | 0 certificadas | Solo propuesta; sin escena/art nuevo | Consulta a IA6/diseño, no implementación actual |

**Interpretación obligatoria:** 248 seleccionadas **no** son 248 mecánicas certificadas. 229 pruebas históricas de enseñanza acotadas; 19 requieren perfil/reglas. La ausencia de 247 entradas en manifest no prueba ausencia de imagen fallback.

## 4. Historial de trabajos y pruebas

| Lote | Cambios reales | Prueba y alcance | Informe / estado |
| --- | --- | --- | --- |
| LOTE_001 | Auditoría de 248 IDs, CSV con mapeo/risks y reservas | Cruce **estático**; sin Godot nuevo | [LOTE_001](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_001.md), commit `d9fffd2da1c9e4f2c120557503503292a34844f6`; **ACEPTADO por IA6 como documental** |
| LOTE_002 | Fusión checkpoint y creación de validador Python de solo lectura + suite de negativos + fixture versionado | Python 3.13.5 local **13 PASS + 1 SKIP** (12 controles unitarios más CLI y test real pendiente); cruce independiente de **datos GitHub reales** PASS estático 248/229/19 y solape | [LOTE_002](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_002.md); **LISTA_PARA_REVISION**, pendiente IA6 |

**Rutas de LOTE_002:**
- [`tools/item_audit/parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tools/item_audit/parallel_w05_machine_scope.py) · blob `e1d6015a125f7fe4b5d1d0f9e34b94079f68858f`.
- [`tests/tools/test_parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/tools/test_parallel_w05_machine_scope.py) · blob `e150dd766c976f1fccf7d9fa2d08f633acc95ed4`.
- [Contrato JSON de regresión](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/fixtures/parallel_items/w05_machine_scope_v1.json) · blob `0dbd1f4d299569b63a7b0f0341bf2112e51c9319`.

**Comandos reproducibles, desde raíz del checkout completo:**
```sh
python tools/item_audit/parallel_w05_machine_scope.py
python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v
```

**Ejecución exacta hasta ahora:** el módulo Python y su suite se ejecutaron en contenedor aislado con tests sintéticos; 14 casos, 13 PASS, 1 SKIP (`test_ruta_real_248_si_disponible`, por no estar montado el repo). El chequeo estático **independiente** en sesión leyó blobs reales de GitHub `8b9b723...` y `0525b370...`, confirmó 248/229/19, detectó 5 mutaciones negativas; **no sustituye ejecutar el Python publicado con los 248 del checkout**. Godot 4.7 y GPU **SIN_EJECUTAR**. No se lanzó ningún workflow nuevo, por economía de CI.

## 5. Interfaz futura de libros — PROPUESTA, NO AUTORIZACIÓN

Implementar solo tras decisión IA6 y encargo nuevo, como **capa de presentación** sobre máquina existente, nunca una función de enseñanza por libro:

1. Entrada: `item_id` canónico existente en mochila; leer `machine_rows[item_id][perfil_aprobado]`, `move_id` y tipo del movimiento desde `DefinitionCatalog`; si el perfil no lo autoriza, UI indica «No disponible» y no ofrece usarlo.
2. Modelo de vista sugerido `LibroMovimientoVista` (estructura de datos, **no clase escrita**): `item_id`, `move_id`, `tipo`, `estilo_base_libro`, `paleta_tipo`, `texto_localizado`, `habilitado`, `motivo_bloqueo`. Variantes visuales reutilizables: seis bases de libro y colores por tipo si se confirma el diseño; sin 248 texturas/escenas exclusivas como requisito.
3. Acción: botón de la mochila llama al servicio actual `teach()`, no realiza reglas/consumo en el widget. Persistir únicamente ID y estado de criatura ya existentes, sin schema de guardado nuevo.
4. Validación futura: vista para ID normal/inactivo, color y tipo correctos, rendimiento de 248 entradas, acceso a PC, cancelación/rechazo sin gasto, persistencia y visual/GPU. La regla de MO de campo se diseña separadamente, nunca inferida del libro.
5. Duplicidad `hm05`/`tm77`: IA6 decide contenido; el verificador la mantiene visible y no elimina ningún ID automáticamente. `scarlet_book` y `violet_book` son objetos de historia, no sustitutos de MT.

## 6. Bloqueos, riesgos, siguiente turno

- **BLOQUEO DE VERIFICACIÓN:** el checkpoint V27+V28 está combinado sin CI. Para validar el Python publicado con los 248, hace falta checkout completo en ejecutor; GitHub Actions consolidada de IA6 o entorno Windows del usuario. No afirmar PASS de Godot a partir de test Python.
- **BLOQUEO DE POLÍTICA:** activar 19 legadas exige perfil, compatibilidad learnset, consumo, posibles duplicados y decisión sobre MO/campo. Ningún movimiento antiguo se asigna por similitud de número.
- **Riesgo de colisión:** servicio de inventario, vistas, tests compartidos, arte y políticas; las otras W trabajan familias vecinas. No escribir allí sin contrato de propiedad.
- **Riesgo de snapshot:** si cambian catálogo o versión, el contrato espera 248/229/19 y solape revisado; un FAIL puede indicar evolución legítima, **no** arreglarlo cambiando cifras a ciegas.
- **No tocar:** `main`, `codex/items-v28-from-main`, la árbitra, ramas ajenas, guardados, `config/`, `data/`, `assets/`, `.github/`, reglas Mega y decisiones de selección; no crear 248 scripts ni regenerar bibliotecas.

### Retomar en la siguiente conversación

1. Leer `STATUS.md` y **nuevo encargo oficial** en la rama árbitra; verificar SHA y permisos. Si no hay LOTE_003 asignado, **no trabajar**.
2. Leer este cuaderno y el [último informe](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_002.md), no volver a procesar todo el historial.
3. Confirmar HEAD W05 e identidad de checkpoint `38188cc...`; verificar que IA6 acepte el reporte/runner y confirme si realizó CI consolidada.
4. Ejecutar ambos comandos Python en checkout con datos reales; documentar resultado y logs por commit. Mantener separada evidencia de lógica Python, evidencia de Godot y prueba visual.
5. Solo bajo nueva autorización, preparar contrato funcional/aprendizaje de 19 legacy y diseño de libro por tipo, con propiedad exclusiva de archivos.

**Último paso reproducible:** ejecutar primero `python tools/item_audit/parallel_w05_machine_scope.py` y luego `python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v` sobre el checkout completo de W05; entregar resultados a IA6 para integración. **PENDIENTE_CI; LISTA_PARA_REVISION.**
