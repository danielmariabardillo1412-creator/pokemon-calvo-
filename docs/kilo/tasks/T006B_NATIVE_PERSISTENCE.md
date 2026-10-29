# T006B — persistencia, publicación validada y recuperación

Base aceptada: 4535c2802a037838f7079ef3af0a6011d0964428 (T001–T005/T006A).
Raíz: D:/Proyectos/Pokemon Calvo - Arquitectura Kilo. Un ejecutor OpenCode.
Es la entrega B del bloque T006. Al acabar se detiene para revisión, sin autoaceptar.

## Problema y resultado

Quedan privados del mapa en save_game, load_game, _tables_for y recover_battle.
Migrarlos a operaciones públicas concretas del dueño. No trasladar guardado ni
worker al mapa; no copiar colección, trainer, clocks o BattleState para crear otra
autoridad. El candidato se valida antes de retirar la sesión anterior y antes de
publicar. El mapa solo publica sus referencias cuando el puente ha completado
TODAS las validaciones y esperas. Preservar efectos/orden/errores del checkpoint.

## Superficie exacta

- scenes/visual/field_demo.gd: añadir API de persistencia y sus helpers nuevos.
- scenes/visual/field_native_bridge.gd: modificar SOLO save_game, load_game,
  _tables_for, recover_battle. Mismas firmas, vars públicas y aliases.
- tests/gameplay/field_restore_contract_test_runner.gd y .uid: contrato nuevo.
- tests/gameplay/field_restore_integration_test_runner.gd y .uid: integración nueva.
- docs/kilo/PROGRESS.md, TASKS.json, evidence/T006B/, T006B_quick/: evidencia.

Todas las funciones previas de field_demo están congeladas por hash, incluidas
las APIs de objetos y de runtime. Todas las funciones del puente excepto las
CUATRO anteriores están congeladas. No modificar _load_failed, runtime T006A,
_idle_boundary, occupied, notify, bootstrap, _ready, _process, señales o teclado.
No tocar serializadores/SaveGameRepository, field_native_save.gd, módulos, sesión,
worker, UI, .tscn, HUD, mochila, diagnósticos, datos, reglas, arte o tests anteriores.
No cambiar formato, schema, límites, checksum/hash, políticas, RNG o mecánicas.

## A — API pública específica del dueño y preparación sin publicación

Reutilizar field_collection, field_definitions y field_trainer_owner de T005/A.
Añadir SOLO estos métodos (tipado más preciso y helpers privados nuevos permitidos):

1. field_player_position() -> Vector2: posición actual por valor.
2. field_player_movement_enabled() -> bool: disponibilidad actual del jugador,
   false sin jugador. No cache ni setter general.
3. field_native_world_snapshot(format_id: String) -> Dictionary: la MISMA forma
   world de save_game: position [x,y], region String, config duplicate(true),
   rng String del estado actual, next_seed int y format String; mismo orden de
   claves. No referencias vivas a configuración ni otro estado duplicado.
4. field_build_native_encounter_tables(config: Dictionary) -> Dictionary:
   mover el CUERPO de _tables_for al dueño, con validación, límites y builder
   EXACTOS. Dict nuevo o vacío al fallar. No modificar tablas vivas, RNG o mundo.
5. field_validate_native_loaded_world(world: Dictionary) -> Dictionary:
   mover los checks de mundo actuales de load_game, en el MISMO orden:
   - shape de position/config/format/rng/next_seed -> world_shape;
   - position dos números finitos, límites 16..1280/16..850, misma región calculada
     con _region_at_position y destino _destination_is_clear -> world_position;
   - next_seed entero 1..2147483646 -> world_seed;
   - field_build_native_encounter_tables(config), vacío -> world_encounters.
   Retornar {ok:false,error:<mismo motivo>} o {ok:true,position:Vector2,tables:Dictionary}.
   No alterar world/config ni live state. No nuevos formatos, coerciones, errores
   o validaciones adicionales: mantener compatibilidad y prioridad de rechazos.
   Los checks del envelope/colección/trainer/clocks/battle siguen en Saves.read.
6. field_publish_native_loaded_world(collection:PlayerCollection,
   trainer:TrainerCampaignRosterOwner,world:Dictionary,position:Vector2,
   tables:Dictionary) -> void: publicar SOLO las asignaciones de mapa que ahora
   están en load_game, en su orden original:
   crear _session WildAdventureSession y _trainer_session TrainerBattleSession
   con la colección cargada/catálogo actual/ProgressionRuleset.new(); asignar trainer;
   config duplicate(true); restaurar panel; perfil/pericia y force_shiny;
   conectar director.session, tablas, RNG y next_seed; posición y reset_step_meter.
   No asignar clocks, view/session del puente, busy/kind ni format_id desde el dueño.
   PRECONDICIÓN: validación completa y candidato restaurado; no método genérico
   de setear propiedades. No es un endpoint para la UI. Sin await, diferidos,
   timers, procesos, IO, callbacks nuevos ni validación fallible después de la
   primera asignación. No publicar parcialmente y luego intentar rollback.
7. field_refresh_legacy_presentations() -> void: solo _configure_presentations().
   Su llamada continúa DESPUÉS de asignar clocks/format/view/toggles del puente,
   en el mismo punto donde estaba la llamada privada. No moverla dentro de 6.

No getter de director/sesiones/recorder, set/get genérico, diccionario 'context'
con todo el mundo ni cambio de ownership. Se publican las referencias VALIDADAS,
no otra copia de colección/trainer/tablas. El catálogo vigente no se reemplaza.
No llamar métodos 6/7 durante validación o mientras restore candidato está pendiente.

Crear field_restore_contract_test_runner con escena REAL en nativo y --legacy-field.
Comprobar getters/snapshot (valores, tipos, copia aislada, sin RNG/estado consumido),
builder y validador con casos válidos y cada rechazo, incluidos errores simultáneos
para verificar prioridad. Probar claves/tipos/decimales/niveles/config/formatos,
región y colisión, destino válido, seed extremo y variante shiny permitida/no admitida.
No imitar el método nuevo para fabricar expectativas: usar motivos literales,
valores de la base y tablas validadas por reglas existentes. Comparar colección,
trainer, clocks, tablas vivas, config, posición y RNG antes/después de validación.
No forzar publicación de datos inválidos directamente en el dueño ni añadir setters.

python tools/architecture_handoff/run_checks.py --phase T006B --piece

## B — migración de las cuatro funciones del puente

save_game:
- Mantener _idle_boundary y la prohibición original por movimiento deshabilitado
  fuera de batalla. No sustituirlos por field_can_configure (prohibiría guardar
  en un combate estable, que sí se admite).
- Obtener world con snapshot público; mantener snapshot de batalla y poda de
  clocks en el MISMO punto. La poda sigue en el dueño del diccionario (puente),
  usando colección/trainer por getters; mismo criterio huérfano/no dormido.
  No fabricar relojes ni retrasar la poda. Esta poda precede a saves.write también
  cuando write falla: no cambiar esa semántica durante la reorganización.
- saves.write/argumentos/path/avisos/formato idénticos; catálogo/colección/trainer
  actuales por API, sin cachés de una sesión anterior.

_tables_for:
- Conservar firma como delegación a field_build_native_encounter_tables.
  No tener dos implementaciones que diverjan.

load_game, orden OBLIGATORIO:
1. Mismos guards y flags busy/_working/lock/refresh.
2. saves.read con catálogo público; si falla, mismo _load_failed y motivo.
3. Validar/preparar mundo por API. Si falla, mismo motivo. NO publicar nada.
4. Si loaded.battle no está vacío: crear Session con catálogo, loaded.collection,
   loaded.clocks, formato y trainer cargado solo cuando kind==trainer. Esperar
   candidate.restore_saved. Si falla, cerrar candidato y _load_failed; conservar
   sesión anterior y campaña. No saltarse restore ni usar su proyección de UI.
5. SOLO después del éxito, await cierre de view.session anterior si existe.
6. Llamar una vez al publicador de mapa (método 6), con datos/candidato ya validados.
7. Sin await entre 6 y las asignaciones actuales del puente: clocks=loaded.clocks,
   format_id, cancel playback, hide medicina, view.session=candidate,
   view.player=loaded.collection, settlement/working/toggles, y método 7.
8. Mismo busy=false/kind, rama candidato visible+diagnostic/refresh o campo
   oculto+unlock, y aviso final. No eventos adicionales que observen estado a medias.

No await oculto, lambda async o call_deferred dentro de 6/7 ni entre las referencias
publicadas. No cerrar sesión anterior antes de validar/restaurar candidata. No
modificar Saves.read/decode, checksum, contrato de snapshot o validadores del worker.
La ausencia de yield conserva la publicación síncrona existente; no inventar una
transacción genérica ni nuevas señales. No tocar settlement/XP/captura/inventario.

recover_battle:
- Solo reemplazar accesos privados al mapa por getters públicos actuales.
- Mantener checkpoint/restauración y orden: replacement.restore_saved; si éxito
  cerrar old, reemplazar view.session y emitir; si falla cerrar replacement,
  conservar old. Clocks, colección, trainer y RNG no se sustituyen por recuperarse.
- Mismos guards, busy/_working/refresh y retorno. No recompensar ni reejecutar
  acciones al restaurar. No cambiar worker ni su criterio needs_recovery.

Al terminar: CERO field._*, field.player, field.test_panel o
field.traversal_controller en TODO field_native_bridge.gd. Tampoco get/set/get_node
para buscar privados por otra ruta. Referencias a su propia presentación view._*
se conservan: su limpieza no es parte de este encargo.

## C — integración real, fallos y cierre

field_restore_integration_test_runner, escena NATIVA real y worker real, rutas
res://.godot/field_restore_checks/ para guardados buenos/corruptos. Sin mocks de
carga, publicación, colección, identidad o backend. Fixtures solo en runner.

- Guardar/cargar en campo: forma del sobre, SHA y mundo compatibles con la base;
  colección/trainer/sesiones/director/config/posición/RNG/seed coherentes al salir.
  Mismos objetos cargados por identidad; no clones extra. Pruebas de copia de config.
- Guardar/cargar combate salvaje y entrenador ESTABLES con worker: checkpoint,
  roster/owner/inventario de batalla/PP/estados/relojes, restore y acción posterior.
  No cobrar dos veces captura/XP/objetos. Dos sesiones heredadas siguen inactivas.
- Fallo de envelope/checksum/posición/seed/tablas/config: comparar campaña vieja,
  trainer, sesión, tablas, config, posición, clocks y RNG por identidad/contenido.
  Mantener motivos/orden. En fallos del mundo usar envelope con checksum recalculado
  para alcanzar el validador de mundo real, no quedarse en checksum siempre.
- Fallo REAL de candidate.restore_saved DESPUÉS de pasar validación de mundo:
  fixture de snapshot de batalla incompatible (p.ej. campaign_stamp de adventure),
  sobre válido/recalculado. No sustituir el método restore por stub. No cerrar
  ni perder la sesión anterior; demostrar que aún puede aceptar comando después.
  La candidatura descartada se cierra y no se publica owner/clocks/RNG parcial.
- Fallo de write_atomic con rename_failure_inject existente: último archivo bueno
  sigue cargable. No cambiar serializer para que pase. Comparar inventario/trainer
  sin exigir que una poda de clocks inválidos desaparezca de la semántica anterior.
- Recuperación real de worker propio muerto: método de tests existentes usa PID
  del worker creado por ESA sesión de prueba. Rechazo de acción mantiene checkpoint,
  recover_battle restaura, acción posterior funciona sin duplicar publicación.
  Probar también restore rechazado: old y checkpoint se conservan y replacement
  se cierra (fixture de checkpoint, no override del método de producción).
- Repetir carga y verificar guards T005: servicio viejo rechaza sin mutar owners
  ni diccionarios de igual contenido; reenlace explícito opera en el actual.
  Debe compartirse EXACTAMENTE loaded.clocks entre puente, sesión nativa y servicio.
- Confirmar guards durante playback/worker ocupado/overlays/transición según
  frontera original. No 'mejorar' su lógica ni convertir vista BattleState en autoridad.

Comparar los invariantes REALES, no solo true/false. Avisos/flags/unlock de error
conservan sus efectos anteriores: no exigir que el aviso o medidor de pasos queden
congelados si la base los cambia. No escribir partidas del usuario ni original.
No añadir setters de producción o cambiar validaciones para preparar los fixtures.

Comprobaciones:
python tools/architecture_handoff/run_checks.py --phase T006B --quick
python tools/architecture_handoff/run_checks.py --phase T006B
python tools/architecture_handoff/guard.py --full

Pieza: contrato en dos perfiles. Quick: esos 2 + integración + 14 quick T006A = 17.
Completo: 3 nuevos + 22 anteriores = 25 grupos incluida GPU. Sin omitir/rebajar
suites protegidas o modificar sus verificadores. Procesos largos en segundo plano
oculto si hace falta: PID/log, salida REAL, preservar parciales; timeout no es PASS.
Dos intentos fallidos sin progreso reproducible o dependencia fuera de alcance:
BLOCKED con caso mínimo/logs; no ampliar permisos, sellos, código o alcance.

## Documentación y parada

Escribir evidence/T006B/REVIEW.md con API, compatibilidad, orden de publicación,
pruebas reales, rechazos, hashes, archivos y límites/capturas no hechas.
Escribir evidence/T006B/ARCHITECTURE_STATUS.md: ownership final de mapa/puente/
sesión/vista/servicio; acceso privado eliminado del puente; herencia/legado que
continúa; deuda de presentación y mecánicas que sigue fuera del encargo. Actualizar
el recorrido de carga y enlazar BOOT_MAP aceptado de A sin reescribir su historia.
No declarar que toda la base de código ha sido auditada ni que no puede haber bugs.

TASKS/PROGRESS: T006B IMPLEMENTED_AWAITING_REVIEW, padre T006 también pendiente de
revisión y global READY_FOR_REVIEW cuando TODO termine. No ACCEPTED_BY_CODEX ni
completar unilateralmente la reforma. Detenerse. No otra tarea, merge, push,
renombrado o mezcla con el original. Codex hará la revisión final.
