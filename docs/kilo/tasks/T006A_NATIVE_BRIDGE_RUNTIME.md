# T006A — puente nativo durante ejecución y mapa del arranque

Base aceptada: 291861ca706e075b0df546abd8c15102024cf865 (T001–T005).
Raíz: D:/Proyectos/Pokemon Calvo - Arquitectura Kilo. Un ejecutor OpenCode.
T006 se divide por riesgo: A ejecución; B publicación/carga/recuperación después
 de otra revisión. No cerrar T006 global ni iniciar B al terminar A.

## Objetivo y alcance

El puente conoce ahora privados del mapa, director, recorder, UI y colección.
Usar una API concreta del dueño durante encuentros/inicio/cierre de combate.
El puente sigue siendo coordinador de su sesión/presentación, busy, kind,
format_id y clocks. La colección, catálogo, director/RNG, métricas y recorder
siguen en el dueño; sesiones nativas y settlement conservan toda su autoridad.
No se permite un objeto que reciba self y simplemente exponga todos sus privados.

Archivos permitidos:
- scenes/visual/field_demo.gd: añadir métodos públicos y mínimos helpers de mundo.
- scenes/visual/field_native_bridge.gd: solo las funciones de ejecución enumeradas.
- tests/gameplay/field_bridge_world_test_runner.gd y .uid: contrato nuevo.
- tests/gameplay/field_bridge_runtime_test_runner.gd y .uid: integración nueva.
- docs/kilo/PROGRESS.md, TASKS.json, evidence/T006A/ y T006A_quick/: evidencia.

No tocar technical_overworld.gd, .tscn, FieldItemService, módulos/backends/worker,
serializadores, UI de combate, mochila, HUD, diagnóstico, API T005, datos, arte,
reglas, tests anteriores, planes, verificadores, sellos o configuración.

CUATRO MÉTODOS CONGELADOS del puente, idénticos a 291861c:
save_game(), load_game(), _tables_for(), recover_battle(). Sus accesos privados
son deuda EXPLÍCITA para T006B; inventariarlos, no migrarlos en esta entrega.
Tampoco modificar _idle_boundary, occupied o _exit_tree. El guard comprueba
hashes por función de estos métodos y de las funciones existentes de field_demo. No alterar firmas,
variables públicas del puente ni aliases usados por tests anteriores.

## 1 — caracterización y contrato de mundo en el dueño

Antes de cambiar, leer puente/base/field_demo y documentar el recorrido actual en
evidence/T006A/BOOT_MAP.md (ver sección final). Consultar la base con git show,
registrar condiciones/orden/avisos/eventos. No ejecutar ni editar el original.

Reutilizar API T005 intacta: field_collection, field_definitions, field_show_notice.
Añadir SOLO operaciones concretas siguientes (tipado más preciso permitido):

1. field_trainer_owner() -> TrainerCampaignRosterOwner: dueño actual, no cache.
2. field_has_living_party() -> bool: mismo any(not is_knocked_out) sobre el equipo
   actual; false sin colección. No ejecutar ni simular combate.
3. field_has_world_overlay() -> bool: MISMA expresión que _world_overlay_open
   actual (panel, galería, mochila, dobles). No reutilizar _can_configure: guarda
   y carga pueden operar dentro de combate estable y no tienen el mismo guard.
4. field_attach_battle_view(view: Control) -> void: añadir a CanvasLayer como ahora,
   sin cambiar orden ni conservar otro registro de presentaciones.
5. field_forward_battle_diagnostic(kind: String, entry: Dictionary) -> void:
   rama trainer/wild y callbacks heredados exactos; no agregar eventos duplicados.
6. field_note_native_step(position: Vector2) -> StringName: resolver zona con
   zone_at_position, note_step y record step_completed exactamente una vez,
   con payload x/y/zone_id/backend=native. Devolver la zona. No tirar RNG aquí.
7. field_prepare_native_encounter(zone_id: StringName) -> Dictionary: vacío si
   zona vacía/no registrada o equipo sin vivos, en ese orden, sin resolver ni RNG.
   Si procede, clonar RNG por estado y llamar a WildEncounterSystem.resolve
   con la tabla actual, catálogo y ProgressionRuleset original. Registrar
   note_encounter_roll exactamente una vez. Devolver {result: WildEncounterResult,
   next_rng: int}; no exponer director, tabla, RNG vivo o sesión.
   Si NONE, publicar staged.state en el director en este punto, como la base.
   Si INVALID u otro estado distinto de NONE/ENCOUNTER, no publicar RNG ni abrir. Si ENCOUNTER, NO publicar RNG todavía;
   conservar force_shiny y comprobación de arte tal como el puente actual.
   La criatura generada es candidata, no se publica en colección por este método.
8. field_native_seed() -> int: leer _director._next_battle_seed actual sin avanzar.
9. field_commit_native_battle_start(next_rng: int, kind: StringName, format_id: String)
   -> void: tras begin exitoso, publicar next_rng si != -1, incrementar seed UNA
   vez, note_battle_started y record battle_started con mismos payloads/orden.
   No consumir RNG adicional, no llamar begin ni publicar consecuencias de batalla.
10. field_lock_battle_world() -> void: movement_enabled=false y velocity=Vector2.ZERO.
11. field_show_battle_view(view: Control) -> void: ventana 1280x720, view.show,
    _hud.hide en el MISMO orden. No mover _working ni controles del combate.
12. field_unlock_battle_world() -> void: ventana 960x540, reset_step_meter y
    movement_enabled=not test_panel.is_panel_open, exactamente la base.
    No mejorar aquí el guard de galería/dobles ni agregar condiciones nuevas.
13. field_record_native_battle_closed(reason: String) -> void: mismo evento
    category=native/event=battle_closed/payload reason, una sola vez.

No exponer getters de _director/_session/_metrics/_recorder, diccionarios
'context' con todo el mapa ni un set/get genérico de propiedades. No estado
paralelo: se consultan fuentes actuales y se conserva la propiedad ya establecida.
No modificar métodos existentes de field_demo, especialmente los aceptados T005,
_ready, _process, configuración, HUD o teclado. Solo añadir API específica.

Crear field_bridge_world_test_runner con escena REAL en nativo y --legacy-field.
Cubrir API, referencias actuales, overlays, efectos mínimos de lock/show/unlock,
parent real de la vista, flags y avisos/eventos exactos. Las consultas no mutan
colección/relojes/RNG. Ejercitar candidato y tiempo de publicación RNG/seed con
fixtures deterministas: usar el resolver existente como referencia o valores
caracterizados de la base; no duplicar el nuevo helper como su propio oráculo.
Caso NONE y candidato ENCOUNTER, zona inexistente, equipo sin vivos, métricas y
records. Documentar qué son fixtures/qué son combate real. No activar motor
nativo en la ruta legacy por probar métodos. Sin setters nuevos de producción.

python tools/architecture_handoff/run_checks.py --phase T006A --piece

## 2 — migración del puente, solo ejecución

Funciones del puente permitidas:
configure, _world_overlay_open, on_step, start_trainer, _open, _lock_world,
_show_battle, _unlock_world, leave_battle, notify.

- configure conserva construcción de Presentation, conexiones y elección de
  formato. Usar definiciones públicas, field_attach_battle_view y forwarding de
  diagnóstico. Mantener owner_bridge=self y field=world como referencias existentes.
- on_step conserva orden: ocupado/transición/overlays -> nota de paso -> prioridad
  de entrenador -> candidato -> resultado -> busy/kind/lock -> await _open.
  Usar field_note_native_step y field_prepare_native_encounter. Un NONE no abre;
  error notifica exactamente 'Encuentro rechazado: ' + reason. El puente no aplica
  de nuevo el RNG ya publicado para NONE ni adelanta el de ENCOUNTER.
- start_trainer usa trainer owner y colección actuales; mismo bloqueo, vivos y
  _open.call_deferred. No sustituir el roster ni fabricar entrenador genérico.
- _open resuelve referencias actuales por getters; Session y view siguen en puente,
  semilla [seed,12004,12006,1] idéntica. Solo después de begin exitoso se llama a
  field_commit_native_battle_start. Mantener secuencia view._working/busy,
  fracaso/close/hide/unlock/notify, y emit/refresh posterior exactos.
- _lock/_show/_unlock delegan a las operaciones del dueño, conservando firmas.
- leave_battle no cambia sus condiciones ni cierre; solo usa API para registrar.
- notify conserva last_error y append de event_log si view.visible; solo cambia
  escritura de _notice_label por field_show_notice. Sin duplicar mensajes/logs.

Fuera de los CUATRO métodos de persistencia congelados no debe quedar ningún
field._*, field.get('_...'), get_node para buscar privados ni acceso a director,
colección duplicada, UI del mapa o sesiones heredadas por una ruta indirecta.
Se permiten los métodos públicos existentes y APIs anteriores. Publicación final
de combate sigue en FieldNativeSession._finish, SIN CAMBIOS. No moverla al puente
ni al mapa. Clocks sigue siendo el mismo diccionario del puente con su carga actual.

## 3 — integración y mapa de arranque

Crear field_bridge_runtime_test_runner, escena real NATIVA, sin mocks de backend,
colección, inicio o guardado. Save_path en res://.godot/field_bridge_checks/.

- Arranque: presentación en CanvasLayer, catálogo/colección/dueño correctos; dos
  sesiones heredadas inactivas y sin una segunda autoridad de combate.
- Paso fuera de zona, overlay y equipo sin vivos: ningún combate ni avance extra
  de RNG/seed; métricas/registro según momento exacto del bloqueo original.
- Intento NONE: comparar estado del RNG publicado con el resolver de referencia,
  sin incremento de seed ni battle_started. Candidato ENCOUNTER no adelanta RNG
  hasta begin exitoso. El comienzo exitoso confirma RNG/seed/registro una vez.
- Fallo REAL de begin, sin mock: fixture explícito _open(null,next_rng) en kind=wild
  produce 'no_available_creature' en la sesión real antes del worker. Comparar
  RNG/seed/colección/relojes: no commit, unlock/avisos exactos. No invalidar motor
  o cambiar timeout. Separar este fixture del encuentro real exitoso.
- Encuentro/captura o huida reales con worker: entrar, visibilidad/escala/HUD/lock,
  diagnostic_event, cierre y desbloqueo, sin pago/publicación extra al cerrar.
- Inicio entrenador real, roster existente, seed/battle_started una sola vez;
  cierre limpio. Los resultados y progresión amplios siguen cubiertos por suites.
- Notify en campo y combate: aviso/last_error/log correctos; no duplicados.
- Diagnóstico, mochila T005, guardado/carga y recuperación siguen protegidos por
  suites anteriores. Probar que el inicio/cierre no retira la colección ni relojes
  salvo la autoridad de settlement ya existente; no romper guards T005.

BOOT_MAP.md en evidence/T006A debe describir, con referencias a fuentes reales:
1. project.godot -> field_demo.tscn -> herencia technical_overworld._ready.
2. Catálogos/variantes, colección/equipo/inventario, trainer owner, director y RNG;
   sesiones heredadas y presentaciones (por qué aún existen aunque estén ociosas).
3. _ready derivado: HUD/galería/puente nativo/mochila, orden de sus conexiones.
4. Autoridad nativa, vista BattleState como proyección y settlement de colección
   y trainer; identidad de clocks. No describir la proyección como segundo motor.
5. Recorrido de carga actual: validación, candidato, await restore, cierre viejo,
   publicación síncrona, refresh. Listar privados que persisten en los 4 métodos
   congelados para T006B. NO moverlos ahora ni afirmar que ya están migrados.
6. Tabla de ownership y diagrama pequeño de llamadas; deuda real fuera del alcance.
   No borrar código, cambiar la herencia o retocar bootstrap para ajustar al dibujo.

## 4 — cierre y revisión

python tools/architecture_handoff/run_checks.py --phase T006A --quick
python tools/architecture_handoff/run_checks.py --phase T006A
python tools/architecture_handoff/guard.py --full

Pieza: 2 perfiles del contrato nuevo. Quick: esos 2 + integración nueva + todos los
11 grupos quick T005 = 14. Completo: 3 nuevos + 19 anteriores = 22, incluida GPU.
No modificar ni saltar tests previos, scripts de verificación o sellos. Un proceso
interrumpido o activo no es PASS; segundo plano oculto+PID/log si la herramienta
necesita esperas cortas. Preservar resultados parciales y esperar salida REAL.

Escribir evidence/T006A/REVIEW.md con API, cobertura, orden/RNG, compatibilidad,
privados restantes, resultados, hashes, BOOT_MAP y límites de pruebas/capturas.
Actualizar PROGRESS/TASKS: solo T006A IMPLEMENTED_AWAITING_REVIEW y global
READY_FOR_REVIEW, padre T006 IN_PROGRESS. T006B sigue BLOCKED_REVIEW.
No marcar ACCEPTED_BY_CODEX ni T006 terminado. Detenerse para revisión. Dos
intentos fallidos sin progreso o necesidad de salir del alcance: BLOCKED con logs.
