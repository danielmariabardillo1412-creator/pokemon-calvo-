# T005 — API pública de campo y conexión de mochila

Base aceptada: 66be8f932ea6fdc50b6d82004deb4238bfeb3759 (T001–T004).
Raíz única: D:/Proyectos/Pokemon Calvo - Arquitectura Kilo.
Un solo ejecutor OpenCode. T006 continúa bloqueado.

## Resultado buscado

field_item_bag accede hoy a _session, _catalogs, _native_battles.clocks,
_can_configure, _can_use_field_items, _refresh_hud y player/test_panel del mapa.
Crear una frontera pública pequeña en el dueño y migrar SOLO este consumidor.
La colección actual y los relojes pueden cambiar de identidad tras cargar:
ningún servicio antiguo debe poder gastar objetos o curar una colección retirada.
No mover publicación, carga, guardado, reglas o servicio a otra autoridad.

## Archivos permitidos

- scenes/visual/field_demo.gd: añadir API y, como mucho, helpers de enlace descritos.
- scenes/visual/field_item_bag.gd: sustituir accesos del mapa por API; guards de enlace.
- tests/gameplay/field_api_test_runner.gd y .uid: prueba de API con escena real.
- tests/gameplay/field_api_integration_test_runner.gd y .uid: identidad y mochila real.
- docs/kilo/PROGRESS.md, TASKS.json y evidence/T005/, T005_quick/: estado/evidencia.

NO modificar módulos, FieldItemService, puente/presentación nativos, guardado,
clases de colección, escena .tscn, HUD, diagnóstico T004, datos, arte, reglas,
pruebas existentes, planes, verificadores, sellos o configuración. No descargas.
No introducir bus/eventos genérico, container global ni otro espejo de estado.

## A — interfaz en el dueño, todavía sin migrar UI

Añadir estos métodos públicos (ajustes de tipos seguros permitidos, no ampliar API):

- field_collection() -> PlayerCollection: devuelve _session.player ACTUAL por llamada,
  o null si aún no hay sesión. No cachear ni duplicar; no publicar un setter.
- field_definitions() -> DefinitionCatalog: el catálogo actual, sin copia/cache nueva.
- field_can_configure() -> bool: sin sesión/listo devuelve false; cuando está
  listo delega exactamente en _can_configure.
- field_can_use_items() -> bool: sin sesión/listo devuelve false; cuando está
  listo delega exactamente en _can_use_field_items.
- field_can_open_item_bag() -> bool: requiere contexto nativo disponible,
  _can_configure y panel de configuración cerrado. Sin contexto devuelve false,
  nunca desreferencia null ni activa medicinas del legado.
- field_activity_snapshot() -> Dictionary: diccionario NUEVO solo de booleanos:
  native_available, native_occupied, traversal_busy, panel_open, gallery_open,
  doubles_open, bag_open, can_configure, can_use_items, can_open_bag.
  Es informativo: no se guarda como autoridad ni reemplaza guards vivos.
- field_encounter_snapshot() -> Dictionary: copia de encounter_expectation con
  region_id como String. No cambiar porcentajes/fórmulas/RNG ni exponer referencias.
- field_show_notice(message: String) -> void: solo _notice_label.text si existe.
  No cambiar status_label, logs del combate o semántica de bridge.notify.
- field_refresh_hud() -> void: delega en _refresh_hud, sin reformar el HUD aceptado.
- field_item_bag_opened() -> void: dueño pone player.movement_enabled=false,
  trasladando la línea ya existente de open_bag; no es un setter general.
- field_bind_item_service(service: RefCounted) -> bool: valida contexto actual y
  field_can_use_items; configura el servicio real existente con colección actual,
  catálogo y EXACTO diccionario de _native_battles.clocks. Rechazar null/contexto
  inválido antes de configurar. No crear ni clonar colección/clocks/servicio.
- field_item_service_is_current(service: RefCounted) -> bool: comprueba identidad
  de service.owner con colección actual, service.catalogs con catálogo actual y
  service.sleep_clocks con diccionario actual. Distinguir diccionarios diferentes
  con igual contenido (is_same), no usar == para identidad de relojes.

Al enlazar, el Callable may_mutate de FieldItemService comprueba EN CADA operación
field_can_use_items Y las identidades de colección/catálogo/clocks capturadas
al enlace contra las actuales. No capturar una foto de 'idle=true'. Puede añadirse
un helper privado de enlace del dueño para estas comprobaciones; no capturar el
propio servicio en su guard ni generar un ciclo de referencias innecesario.

Esto conserva el guard de actividad y añade rechazo seguro de enlaces retirados.
Un servicio configurado antes de una carga NO debe actuar sobre el owner viejo,
aunque conserve referencia, ni sobre el nuevo hasta un enlace explícito válido.
Los guards de campo existentes y sus expresiones siguen intactos; no unificarlos
ni simplificarlos durante esta fase. Tampoco cambiar _on_configuration_applied,
_process, entradas/diagnóstico, _ready, bootstrap, guardado o carga.

Crear el runner field_api_test_runner con escena REAL y hacerlo funcionar en
nativo y --legacy-field. Cubrir todos los métodos, tipos, referencias idénticas,
snapshots nuevos e inmutabilidad respecto al dueño, guards vivos (panel/overlay),
notificación sin efectos colaterales y enlace directo de Service real. Confirmar
que leer la API repetidamente no modifica inventario/equipo/clocks/RNG/posición.
Antes del arranque los getters permiten null y las consultas de disponibilidad
son false sin errores; no forzar inicialización. Sin contexto nativo rechazar
enlace/apertura, no fabricar relojes.
Antes de migrar mochila: run_checks.py --phase T005 --piece (2 perfiles).

## B — migrar solo la mochila y conservar compatibilidad

Conservar var field y var service, widgets, callbacks, señales, tamaños, posiciones,
textos, arte, selección, códigos de resultado y firmas públicas de bag. Las pruebas
existentes los usan. No cambiar layout ni quitar alias para 'limpiar'.

- open_bag usa field_can_open_item_bag y field_bind_item_service, y avisa al dueño
  mediante field_item_bag_opened después de mostrar, en el mismo orden de efectos.
- Todas las traducciones usan field_definitions, nunca field._catalogs.
- refresh/_refresh_choices/_apply usan la API y service, sin field._*, ni acceso
  a field.player, field.test_panel o field._native_battles por rutas indirectas.
- Refrescar con enlace obsoleto puede reenlazar/repoblar solo si el dueño lo permite.
  Una acción de usuario con selección de una colección retirada se rechaza antes
  de aplicar a cualquiera de las dos colecciones. Puede refrescar UI después,
  pero NO ejecutar la misma acción automáticamente sobre la colección nueva.
- Rechazo por contexto inválido usa el resultado existente field_locked y su texto,
  no una mecánica o mensaje nuevo. No consumir ni tocar criaturas/relojes/RNG.
  Asegurar que los botones no permiten aparentar éxito con un enlace inválido.
- Refresco final del HUD mediante field_refresh_hud. La lógica de consumo/equipado,
  MT, evolución, curas y PP sigue exclusivamente en FieldItemService intacto.
- El guard de servicio sigue funcionando si se llama directamente a bag.service
  fuera de la UI. No basta con desactivar botones o reconfigurar solo al abrir.

Se admite únicamente el cambio de seguridad de no desreferenciar contexto nativo
inexistente al abrir mochila y de rechazar enlaces obsoletos. No añadir funciones
al legado ni arreglar otras diferencias de los perfiles. Si surge otra regresión
preexistente fuera de este alcance, documentarla y entregar BLOCKED.

## Integración nueva sobre escena real

Runner field_api_integration_test_runner, nativo. Guardados en
res://.godot/field_api_checks/, nunca partida del usuario. Sin mock de colección,
servicio, carga, relojes o backend; fixtures controlados solo dentro del runner.

1. Abrir mochila, probar cura/PP y/o equipado, identidad del owner actual y reloj
   de sueño compartido (Awakening elimina la entrada del MISMO diccionario real).
   Los grupos existentes siguen protegiendo toda la matriz de objetos.
2. Conservar referencias a servicio, colección y relojes previos. Cerrar mochila,
   guardar/cargar con puente REAL y ruta aislada. Getter debe devolver nueva
   colección publicada. Servicio antiguo rechaza sin mutar colección vieja/nueva,
   sus inventarios, criaturas o relojes. Reabrir/reenlazar y aplicar sobre el actual;
   cantidad y destino correctos, owner/clocks anteriores siguen intactos.
3. Repetir carga o reinicio por configuración y comprobar que no queda un enlace
   de otra sesión. Guardar/cargar no consume objetos por sí solo. No vaciar relojes
   para 'sincronizar': se usa el diccionario vigente por identidad.
4. Caso de dos diccionarios de relojes distintos con contenido igual: fixture
   controlado del runner demuestra rechazo del enlace viejo hasta reenlace.
5. Simular selección UI obsoleta, _apply debe rechazar y conservar ambos owners;
   actualizar la UI por separado no ejecuta la acción pendiente.
6. Apertura/uso bloqueados durante combate nativo REAL, transición u overlay y
   panel abierto. Guard vivo directo del servicio también rechaza; comparar datos
   antes/después, no solo retorno false. Repetir al desbloquear y comprobar vigencia.
7. Carga inválida/rechazada no publica otra colección ni invalida un enlace que
   conserva el contexto, tras desbloqueo. Usar archivo aislado corrupto; no cambiar
   validador, datos, reglas o parser de guardado para hacerlo pasar.
8. Validar mochila B/Esc, selección de objetivos/movimientos y refresco del HUD;
   test protegido GPU conserva tamaño/apariencia. Diagnóstico/HUD previos intactos.

Puede leerse estado privado desde el runner para observar invariantes, no desde
la mochila. No añadir setters al juego para simular estados. Registrar prueba real
frente a fixtures; no declarar probado lo que solo se supuso por retorno.

## C — comprobaciones, evidencia y parada

python tools/architecture_handoff/run_checks.py --phase T005 --quick
python tools/architecture_handoff/run_checks.py --phase T005
python tools/architecture_handoff/guard.py --full

Pieza: API nativa y legado. Quick: API nativa/legado + integración nueva + todos
los grupos quick T004 (11 en total). Completo: mismos 3 grupos nuevos + los 16
anteriores, 19 en total incluida GPU. Ejecutar secuencialmente; no suites paralelas.
Si una herramienta corta procesos largos, usar segundo plano con ventana oculta,
PID/log y esperar salida REAL. Preservar parciales; no PASS por timeout.

No editar ni rebajar pruebas anteriores, verificadores, planos, permisos o sellos.
Dos intentos fallidos sin progreso reproducible: BLOCKED con caso mínimo y logs.
Escribir evidence/T005/REVIEW.md: API y consumidores migrados, cobertura, identidades,
resultados reales, hashes, cambios de seguridad permitidos, pendientes y límites.
Actualizar PROGRESS/TASKS con IMPLEMENTED_AWAITING_REVIEW y READY_FOR_REVIEW solo
al terminar todo. No ACCEPTED_BY_CODEX; no iniciar T006. Codex revisará primero.
