# Progreso vigente — 2026-10-29

Estado: **T006B_READY**.

T003: **ACCEPTED_BY_CODEX**. T004: **ACCEPTED_BY_CODEX**.
T005: **ACCEPTED_BY_CODEX**. T006: **IN_PROGRESS**.
T006A: **ACCEPTED_BY_CODEX**. T006B: **BLOCKED_REVIEW**.
T001/T002 continúan aceptados en 866b009bb2abde67014ffe6d0b4ad1dc3cc5e8b5.

S0: copia aislada y baseline de 11 grupos PASS. Rama codex/kilo-architecture-v1,
sin remotos y con partidas separadas del original. Datos, recursos y packs se
conservan. El baseline y las incidencias de preparación están en baseline/.

T001: Kilo extrajo la construcción del HUD conservando aspecto, acciones y alias.
Su quick pasó. T002 quedó interrumpido al llegar a medicine y el estado PASS
inicial era prematuro. Codex revisó el diff y terminó las comprobaciones.

Codex reforzó el contrato nuevo del HUD: pasó de una comprobación parcial de
botones a 116 comprobaciones de las nueve acciones y controles reales. No fue
necesario cambiar el código del juego entregado por Kilo.

Cierre T001/T002: 12 grupos PASS, incluida GPU; 21.704 archivos protegidos
verificados por hash; comparación baseline/candidato de 16 comprobaciones PASS
y cero diferencias en las regiones capturadas del HUD. Ver evidence/T002/REVIEW.md
y CODEX_REVIEW.json para alcance, hashes y límites.

T003 fue entregado por Kilo y devuelto por Codex con CHANGES_REQUESTED: la prueba
nueva solo cubría cinco textos de ruta, faltaban los escenarios y la escena real,
la suite completa no cerró y se había limpiado un helper fuera de alcance.

Corrección T003 por OpenCode (esta entrega):
- `scenes/visual/field_hud.gd`: `build()`, `create_action_button` y
  `_create_action_button` repuestos exactamente desde e3d7330; solo se conserva
  la adición de `render_snapshot`. El diff queda en 21 líneas añadidas.
- `scenes/visual/field_demo.gd`: `_hud_snapshot()` devuelve exclusivamente
  String/bool/int/float con las 16 claves del contrato; `_refresh_hud()` solo
  obtiene la instantánea y delega en `render_snapshot`. Se mantienen los defectos
  deliberados 8/12 para la cabecera de cueva y 4/6 para la colección.
- `tests/gameplay/field_hud_render_test_runner.gd`: 431 comprobaciones con ruta,
  refugio y cueva; transición ruta→refugio→cueva→ruta sobre la misma vista;
  frecuencia 0/100; medias decimales; contadores cero y no cero; especie traducida
  y pool; niveles por defecto y sobrescritos; avisos, referencias, controles y
  entrada intactos; callbacks silenciosos. Incluye la escena REAL de field_demo:
  frontera de escalares, correspondencia con las fuentes del dueño, actualización
  de los cinco textos por configuración/región y ausencia de cambios en
  inventario, equipo, guardado, sesión, posición y RNG al refrescar.

Comprobaciones reales ejecutadas:
- `python tools/architecture_handoff/guard.py`: PASS, 23042 archivos.
- Quick T003: PASS, 5 grupos — hud_render 431, hud_contract 116, field_native 118,
  field_items 1814, item_connections 4994.
- Suite completa T003: PASS, 13 grupos, incluida GPU — map_runtime 103/0,
  visual_legacy 45/0, medicine 120, savegame 40/0, save_adversarial 8/0,
  item_policy 19, inventory_capture 133 y field_items_gpu 1816 con captura.
- `python tools/architecture_handoff/guard.py --full`: PASS, 23042 archivos,
  FULL_CONTENT_HASHES.

Incidencia de proceso: el primer intento de suite completa quedó interrumpido por
un reinicio del servidor de herramientas tras tres grupos PASS y terminó con
`[Errno 22] Invalid argument`; no se contó como PASS. El resultado parcial se
conserva en `docs/kilo/evidence/T003/results_interrupted_2250.json`. La suite se
repitió desde el principio en segundo plano (PID 114476), se esperó su salida
real y solo entonces se registró el PASS anterior. `full_suite_stderr.log` está
vacío.

Evidencia: `docs/kilo/evidence/T003/REVIEW.md`, `results.json`, logs por grupo,
`full_suite_stdout.log`, `full_suite_stderr.log` y `T003_quick/results.json`.
La única captura nueva es la GPU de la suite (`field_items_gpu.png`, mochila de
medicinas); no se reutilizan capturas del piloto ni se anuncia una prueba manual
del HUD que no se hizo.

Revisión final de Codex: T003 aceptado. Se repitieron los contratos de HUD
(431 y 116 checks PASS), se verificaron los 23.042 archivos protegidos por hash y
los 13 grupos/logs de la suite completa entregada por OpenCode, incluida GPU.
No se cambió código de juego durante la revisión. La suite completa no se repitió
por segunda vez en esta revisión; resultados e identidades están conservados.

Estado vigente: evidence/T003/CODEX_ACCEPTANCE.md y CODEX_ACCEPTANCE.json.
CODEX_REVIEW.* conserva la revisión anterior con correcciones solicitadas.
Se guarda checkpoint local de la entrega aceptada, sin remotos ni publicación.
No se ha mezclado con el original. T004–T006 siguen bloqueados; el próximo paso
es preparar y habilitar el contrato T004 antes de otra ejecución de OpenCode.

Codex habilita T004 desde el checkpoint aceptado 513dd73. Contrato nuevo:
tasks/T004_FIELD_DIAGNOSTICS.md; prompt: OPENCODE_PROMPT.txt. Incluye catálogo,
selección/ciclos, despacho de teclas de diagnóstico y comprobación de conexiones.
Aún no implementado. T005/T006 siguen bloqueados. Un solo ejecutor OpenCode;
no arrancar Kilo, no tocar el original. Volver a revisión al completar T004.

T004 implementado por OpenCode (esta entrega):
- `scenes/visual/field_diagnostics.gd` (+uid): catálogo de seis listas y siete
  cursores; `action_for_key`, `request_for`, `commit_success`, `index_for` y
  `describe_move`; sin mapa, Nodes, servicios, catálogos ni Callables.
- `scenes/visual/field_demo.gd`: preload/instancia, alias constantes, getters de
  los siete índices, wrappers con `request_for`/`commit_success` solo tras éxito,
  `describe_move` en `prepare_visual_move_test` y despacho F4–F11 conservando el
  `handled` del dueño y las prioridades anteriores.
- Tests nuevos: contrato aislado de 973 checks e integración real nativa/legado
  (476/465 checks); snapshots de rechazo, teclas reales, release/echo,
  prioridades, presets de cada familia, reset y guardado/carga aislado.

Comprobaciones reales:
- `python tools/architecture_handoff/run_checks.py --phase T004 --piece`
  → PASS, 973 checks.
- `python tools/architecture_handoff/run_checks.py --phase T004 --quick`
  → PASS, 8 grupos: 973, 476, 465, 431, 116, 118, 1814 y 4994.
- `python tools/architecture_handoff/run_checks.py --phase T004`
  → PASS, 16 grupos incluida GPU (diagnósticos 973/476/465; HUD 431/116;
  field_native 118; map_runtime 103/0; visual_legacy 45/0; field_items 1814;
  item_connections 4994; medicine 120; savegame 40/0; save_adversarial 8/0;
  item_policy 19; inventory_capture 133; field_items_gpu 1816).
- `python tools/architecture_handoff/guard.py --full` → PASS, 23.047 archivos.

Evidencia: `docs/kilo/evidence/T004/REVIEW.md`, `results.json`, logs por grupo,
`full_run.log`, `full_run.err.log`, `full_run.pid` y `T004_quick/`; el paso A en
`T004/piece/`. No se hizo prueba manual ni captura específica de T004; la captura
GPU es la del grupo existente de objetos. No se creó commit. T005/T006 siguen
bloqueados y no se escribe ACCEPTED_BY_CODEX.

Revisión final Codex: T004 aceptado. Repetidos de forma independiente contrato
973, integración nativa 476 y legado 465 checks: todos PASS. Guard completo PASS,
23.047 archivos. Verificados los 16 grupos/logs de la suite completa de OpenCode,
incluida GPU, y hashes de la entrega. No se ha modificado código o tests por Codex.
La suite completa no se repitió en esta revisión. Estado y límites vigentes:
evidence/T004/CODEX_ACCEPTANCE.md y CODEX_ACCEPTANCE.json.
Se guarda checkpoint local aceptado. T005/T006 siguen bloqueados; no continuar
sin que Codex prepare el siguiente contrato. No se mezcla con el original.

T005 implementado por OpenCode (esta entrega):
- `scenes/visual/field_demo.gd`: API pública pequeña en el dueño
  (`field_collection`, `field_definitions`, `field_can_configure`,
  `field_can_use_items`, `field_can_open_item_bag`, `field_activity_snapshot`,
  `field_encounter_snapshot`, `field_show_notice`, `field_refresh_hud`,
  `field_item_bag_opened`, `field_bind_item_service`,
  `field_item_service_is_current`). El Callable del guard captura dueño, catálogo
  y el diccionario exacto de relojes, no el servicio, y comprueba actividad e
  identidad en cada operación con `is_same`. Sin contexto nativo, abrir mochila
  devuelve false en vez de desreferenciar null; no se añaden mecánicas legacy.
- `scenes/visual/field_item_bag.gd`: migrada solo a la API pública; sin accesos
  `field._*`. Conserva widgets, callbacks, señales, textos, tamaños, posiciones y
  códigos. Un enlace retirado devuelve el resultado/texto existente `field_locked`
  antes de mutar, refresca y no reejecuta la acción pendiente sobre la colección
  nueva; `_ensure_binding` solo reenlaza cuando el dueño lo permite.
- Tests nuevos: contrato de API con escena real, nativo y legado (225/204); e
  integración real nativa (220) con mochila real (curación, PP, equipado y
  Awakening), guardado/carga y segunda carga aislados, reset de configuración,
  relojes de igual contenido, UI obsoleta, combate/panel/galería, carga inválida
  y B/Esc + selección + HUD.

Comprobaciones reales:
- `python tools/architecture_handoff/run_checks.py --phase T005 --piece`
  → PASS: field_api_native 225, field_api_legacy 204.
- `python tools/architecture_handoff/run_checks.py --phase T005 --quick`
  → PASS, 11 grupos: API 225/204, integración 220, diagnósticos 973/476/465,
  HUD 431/116, field_native 118, field_items 1814 y item_connections 4994.
- `python tools/architecture_handoff/run_checks.py --phase T005`
  → PASS, 19 grupos incluida GPU (los 11 anteriores más map_runtime 103/0,
  visual_legacy 45/0, medicine 120, savegame 40/0, save_adversarial 8/0,
  item_policy 19, inventory_capture 133 y field_items_gpu 1816 con GPU=true).
  Todos los grupos con `exit_code: 0`; `guard_before`/`guard_after` del informe
  PASS con 23.053 archivos.
- `python tools/architecture_handoff/guard.py --full` → PASS, 23.053 archivos,
  FULL_CONTENT_HASHES.

Los runners largos se lanzaron en segundo plano con ventana oculta, PID/log y
espera de salida real; ningún timeout o interrupción se contó como PASS.

Evidencia: `docs/kilo/evidence/T005/REVIEW.md`, `results.json`, logs por grupo,
`RUN_PID.txt`, `field_items_gpu.png` y `piece/`; quick en `T005_quick/`. No se
creó commit. T006 sigue bloqueado, no se inicia y no se escribe
ACCEPTED_BY_CODEX.

Revisión final de Codex — 2026-10-29: T005 aceptado. Repetición independiente
API nativa 225, API legado 204 e integración real 220 checks PASS. Guard completo
PASS, 23.053 archivos; verificadas la suite completa de OpenCode (19 grupos
incluida GPU), quick 11 y pieza 2 con sus logs/hashes. No se cambió código ni tests
por Codex. No se volvió a ejecutar toda la suite anterior en esta revisión.
Estado y límites: evidence/T005/CODEX_ACCEPTANCE.md y CODEX_ACCEPTANCE.json.
Checkpoint local aceptado; copia separada, sin publicación ni mezcla con original.
T006 sigue bloqueado; preparar su contrato antes de otra ejecución de OpenCode.

Codex habilita T006A desde 291861c. T006 queda dividido: A ejecución/API/boot;
B carga/publicación/recuperación, bloqueado hasta revisión de A y contrato nuevo.
T006A aún no implementado. Contrato: tasks/T006A_NATIVE_BRIDGE_RUNTIME.md.
Prompt vigente OPENCODE_PROMPT.txt. Un solo ejecutor OpenCode; original protegido.

T006A implementado por OpenCode (esta entrega):
- `scenes/visual/field_demo.gd`: añadidas solo las 13 operaciones concretas del
  dueño (owner de entrenador, equipo vivo, overlays, vista/diagnóstico de
  combate, paso nativo, preparación de encuentro sobre RNG clonado, semilla,
  commit tras begin, lock/show/unlock y cierre). Sin getters genéricos ni estado
  paralelo; las funciones existentes y la API T005 quedan intactas.
- `scenes/visual/field_native_bridge.gd`: migradas solo las funciones de
  ejecución permitidas a esa API; se conservan firmas, orden, semilla
  `[seed,12004,12006,1]`, avisos, métricas, records y el diccionario `clocks`
  por identidad. Solo los cuatro métodos congelados de persistencia
  (`save_game`, `load_game`, `_tables_for`, `recover_battle`) conservan acceso
  privado, inventariado para T006B.
- Tests nuevos: contrato de mundo con escena real nativo/legado (201/194) e
  integración real nativa (146) con worker, captura, entrenador, fallo real de
  begin, NONE/candidato contra el resolver, overlays, notify, HUD y mochila T005.
- `evidence/T006A/BOOT_MAP.md` documenta entrada, bootstrap, ownership, autoridad
  nativa/proyección/settlement, carga y la deuda privada de los cuatro métodos.

Comprobaciones reales:
- `python tools/architecture_handoff/run_checks.py --phase T006A --piece`
  → PASS: bridge_world_native 201, bridge_world_legacy 194.
- `python tools/architecture_handoff/run_checks.py --phase T006A --quick`
  → PASS, 14 grupos: bridge world 201/194, runtime 146, API 225/204,
  integración 220, diagnósticos 973/476/465, HUD 431/116, field_native 118,
  field_items 1814 y item_connections 4994; todos `exit_code: 0`.
- `python tools/architecture_handoff/run_checks.py --phase T006A`
  → PASS, 22 grupos incluida GPU: los 14 anteriores más map_runtime 103/0,
  visual_legacy 45/0, medicine 120, savegame 40/0, save_adversarial 8/0,
  item_policy 19, inventory_capture 133 y field_items_gpu 1816 (`GPU=true`).
  `guard_before`/`guard_after` PASS con 23.058 archivos; suite lanzada en
  ventana oculta, PID/log y espera de salida real (`EXIT_CODE=0`).
- `python tools/architecture_handoff/guard.py --full` → PASS, 23.058 archivos,
  FULL_CONTENT_HASHES.

Evidencia: `docs/kilo/evidence/T006A/REVIEW.md`, `BOOT_MAP.md`, `results.json`,
logs por grupo, `field_items_gpu.png`, `RUN_PID.txt`, `run_console.log`,
`run_console.err.log` y `guard_full.log`; quick en `T006A_quick/`; pieza en
`T006A/piece/`. No se creó commit, no se marcó ACCEPTED_BY_CODEX y T006B sigue
bloqueado. El ejecutor se detiene para revisión de T006A.

Revisión final de Codex — 2026-10-29: T006A aceptado. Repetidos mundo nativo
201, legado 194 e integración real 146 checks, todos PASS. Sonda canónica adicional
41 checks/8 semillas PASS frente a la llamada original con ProgressionRuleset.new.
Guard completo PASS (23.058 archivos y sellos por función); verificados los 22
grupos/logs del completo de OpenCode, quick 14 y pieza 2. No se cambió código ni
runners entregados; solo correcciones documentales de BOOT_MAP y sonda de revisión.
No se repitió toda la suite anterior. Estado/límites: evidence/T006A/CODEX_ACCEPTANCE.md
 y CODEX_ACCEPTANCE.json. Se guarda checkpoint local separado del original.
T006 global sigue IN_PROGRESS. T006B continúa BLOCKED_REVIEW hasta nuevo contrato.

Codex habilita T006B desde 4535c28. T006A aceptado y congelado; B aún no
implementado. Contrato: tasks/T006B_NATIVE_PERSISTENCE.md. Incluye validación,
publicación síncrona y recuperación con pruebas de identidad y fallos reales.
Prompt OPENCODE_PROMPT.txt. T006 sigue IN_PROGRESS hasta revisión de B.
No mezclar con el original ni realizar otra reforma al terminar la entrega.
