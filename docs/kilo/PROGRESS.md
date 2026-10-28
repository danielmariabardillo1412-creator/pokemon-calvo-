# Progreso vigente — 2026-10-28

Estado: **T003_ACCEPTED_WAITING_NEXT_PLAN**.

T003: **ACCEPTED_BY_CODEX**. T004–T006: **BLOCKED_REVIEW**.
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
