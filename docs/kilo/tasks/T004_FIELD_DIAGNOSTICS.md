# T004 — catálogo y controles de ensayos de campo

Base aceptada: 513dd738eb4b30097190782d2fcc762bbe652983 (T001–T003).
Raíz única: D:/Proyectos/Pokemon Calvo - Arquitectura Kilo.
Ejecutor: OpenCode; un solo escritor. T005/T006 siguen bloqueados.

Es un bloque completo con tres pasos A/B/C, no una autorización para otras
reformas. Hacer A, verificar; conectar B, verificar; cerrar C y detenerse.
Solo reorganización con equivalencia de comportamiento: ningún ensayo nuevo.

## Superficie permitida

- scenes/visual/field_diagnostics.gd y .uid: componente nuevo.
- scenes/visual/field_demo.gd: límites de cambio enumerados abajo.
- tests/gameplay/field_diagnostics_test_runner.gd y .uid: contrato aislado nuevo.
- tests/gameplay/field_diagnostics_integration_test_runner.gd y .uid: conexión nueva.
- docs/kilo/PROGRESS.md y TASKS.json: estado T004 sin habilitar T005/T006.
- docs/kilo/evidence/T004/ y T004_quick/: evidencia.

NO modificar field_hud, el contrato HUD de 116 checks, el runner T003 de 431,
pruebas anteriores, puente nativo, módulos, escena .tscn, datos, arte, reglas,
guardados, catálogos del juego, verificadores, planes, sellos o configuración.
No eliminar laboratorio anterior ni introducir un segundo backend.

## Problema y frontera

field_demo contiene constantes de movimientos de diagnóstico, siete índices,
selección de ensayos, sus efectos y teclas, mezclados. Separar selección/catálogo
sin trasladar el mapa entero a un helper que conozca todos sus miembros privados.

Crear FieldDiagnostics, extends RefCounted. Conserva SOLO constantes de ensayos y
siete cursores, con métodos explícitos para seleccionar y avanzar. No retener
self/mapa, Nodes, servicios, catálogo, colección, sesión, widgets ni Callables que
encapsulen esas autoridades. No consultar Godot tree, RNG, disco o procesos.
Devuelve diccionarios nuevos de petición con IDs/booleanos; no textos de HUD ni
referencias mutables. El dueño valida y ejecuta efectos como antes.

Interfaz prevista (se puede tipar más, sin ampliar dependencias):
- action_for_key(keycode: int) -> StringName: F4–F11; desconocido devuelve &"".
- request_for(action: StringName) -> Dictionary: petición del cursor actual,
  sin avanzarlo; vacío si acción desconocida. Claves: move_id, switch_rules,
  weather_rules, substitute_rules, transform_rules y target_species (vacío
  excepto Transformación). Usar StringName y bool, sin Objects/Arrays vivos.
- commit_success(action: StringName) -> void: solo avanza el cursor de esa acción;
  desconocido/Tera no hacen nada. Llamar únicamente tras preparación exitosa.
- index_for(action: StringName) -> int: exponer para compatibilidad, sin estado doble.
- describe_move(move_id: StringName) -> Dictionary: clasificación del conjunto
  admitido para prepare_visual_move_test (supported, external_damage,
  status_switch, weather, substitute, transform). No acepta movimientos nuevos.

No es un framework genérico ni un sistema de movimientos del juego. Su catálogo
es SOLO para los presets explícitos del laboratorio ya existentes.

## Tabla exacta de selección

| Acción / tecla | Secuencia | switch,weather,substitute,transform |
| --- | --- | --- |
| tera / F4 | tera_blast, sin cursor | false,false,false,false |
| elemental / F5 | flamethrower, thunderbolt, ice_beam | false,false,false,false |
| external / F6 | circle_throw, dragon_tail, flip_turn, u_turn, volt_switch | false,false,false,false |
| switch / F7 | misma lista external, cursor independiente | true,false,false,false |
| status_switch / F8 | roar, whirlwind, teleport, baton_pass, parting_shot | true,false,false,false |
| weather / F9 | rain_dance, hail, sandstorm, snowscape, chilly_reception | true,true,false,false |
| substitute / F10 | substitute, shed_tail | true,false,true,false |
| transform / F11 | transform frente a wailord,pikachu,charizard | true,true,true,true |

Cada cursor comienza en cero. Rechazo no avanza; éxito avanza una posición y
vuelve al inicio al completar su lista. Reiniciar/configurar NO reinicia hoy los
cursores: preservar. No compartir cursor external/switch ni entre instancias.
Las peticiones repetidas sin commit deben ser idénticas y sin efectos.

## A — pieza aislada y su contrato

1. Leer las funciones de presets y _unhandled_key_input del checkpoint 513dd73.
   Registrar la tabla, avisos, eventos y condiciones de rechazo observados antes
   de mover código. No tratar documentación antigua de mecánicas como una orden.
2. Crear el componente y su runner aislado con expectativas literales de la
   tabla anterior. Cubrir TODAS las secuencias, vuelta completa+una posición,
   rechazo (no commit), independencia de los siete cursores, instancia nueva,
   entradas desconocidas, todas las teclas y otras ajenas, flags y target.
   Mutar una petición recibida no altera el componente ni la siguiente petición.
3. Para ejecutar SOLO este runner antes de conectar, usar:
   python tools/architecture_handoff/run_checks.py --phase T004 --piece
   No convertir este PASS dirigido en PASS de integración/global.

## B — conectar preservando autoridad y entradas

Límites exactos de field_demo.gd:
- Añadir preload/instancia del componente. Migrar sus constantes y siete índices.
  Mantener los nombres ELEMENTAL_TEST_MOVES, EXTERNAL_DAMAGE_TEST_MOVES,
  STATUS_SWITCH_TEST_MOVES, WEATHER_TEST_MOVES, SUBSTITUTE_TEST_MOVES y
  TRANSFORM_TEST_SPECIES como alias constantes al componente. Mantener getters
  de _elemental_test_index, _external_test_index, _switch_test_index,
  _status_switch_index, _weather_index, _substitute_index, _transform_index.
  Los tests previos los leen: no eliminarlos ni duplicar cursores.
- Conservar firmas/retornos de prepare_tera_visual_test, cycle_elemental_visual_test,
  cycle_external_damage_test, cycle_switch_move_test, cycle_status_switch_test,
  cycle_weather_test, cycle_substitute_test, cycle_transform_test y
  prepare_visual_move_test(move_id, switch_rules=false, weather_rules=false,
  substitute_rules=false, transform_rules=false).
- Sus entradas de ciclo usan request_for y commit_success solo tras éxito. Se
  permite un único helper privado del dueño para aplicar la petición y los efectos
  específicos de la acción. No crear nuevas referencias compartidas a servicios.
- prepare_visual_move_test usa describe_move en vez de repetir pertenencia a
  listas. Las consultas/validaciones de disponibilidad de packs y los efectos
  siguen en el dueño, en su orden original. Conservar el bloqueo por panel/estado
  ocupado, movimientos no admitidos y flags insuficientes; sus rechazos no cambian
  equipo, configuración, cursores, registros ni RNG. Una falta de pack sí conserva
  el aviso original de falta de pack; no ocultarlo.
- En _unhandled_key_input reemplazar SOLAMENTE la cadena F4–F11 por despacho al
  componente y wrappers correspondientes. No reordenar el resto ni saltarse los
  bloqueos anteriores. Un F4–F11 recibido se marca handled aunque el preset falle,
  como ahora. No mover el handled al componente. Conservar pressed/echo,
  prioridades de mochila, Ctrl+S/L, dobles, galería, configuración, F2 y Escape.
- No tocar _ready salvo inicialización mínima si no sirve inicializador de miembro.
  No modificar HUD/_build_hud/_hud_snapshot/_refresh_hud, _process, movimiento,
  guardado/carga, _can_configure ni sus dependencias. cycle_frequency,
  restart_field_run y _on_configuration_applied se conservan; se pueden invocar,
  no reescribir. F12/dobles, F1/F2/F3, B y Ctrl+S/L no se extraen en esta fase.

Efectos que deben continuar EXACTAMENTE como en la base: equipo de ensayo,
especie/nivel/cantidad, flags de sesión, live_moves_enabled=false, selección de
pack/pilot y sus validaciones, Reiniciar restaura, avisos y eventos del recorder.
En particular Baton Pass aplica etapas Ataque +2/Velocidad +1; Clima añade
water_gun/flamethrower/tackle; Sustituto añade tackle/flamethrower/baton_pass;
Transformación usa objetivo antes de avanzar y conserva aviso/evento específicos.
Los efectos no se mueven a FieldDiagnostics ni cambian de backend.

## Prueba nueva de integración

Instanciar field_demo.tscn real, sin mock del dueño. Runner invocable tanto en
perfil nativo como con --legacy-field. Aislar cualquier save_path de prueba en
.godot/field_diagnostics_checks; nunca cargar partidas reales ni escribir user://.

- Comprobar wrappers, alias de listas e índices, rechazo seguro de movimiento
  desconocido/flags insuficientes, bloqueo con panel abierto y otro estado ocupado
  real disponible. Snapshot de estado antes/después del rechazo; los cursores no avanzan.
- Ejercitar presets reales representativos de CADA familia; durante vuelta completa
  de componente ya probada no hace falta repetir cada combate/animación. Verificar
  equipo, moveset, flags, avisos y eventos específicos; reset restaura sin reiniciar
  cursores. No declarar que certifica la mecánica de todos los movimientos.
- Ejercitar F4–F11 con InputEventKey real y las entradas públicas, verificando
  selección/cursor y que un evento no dispare dos acciones. Comprobar release/echo
  y prioridades de overlays (mochila/panel/dobles) antes de diagnóstico.
  Usar eventos en el viewport para al menos una prueba de handled; no contar una
  llamada directa como si demostrase propagación completa. No introducir setters
  de producción para el test. F1/F2/F3/B/guardar/cargar/dobles preservados mediante
  checks concretos existentes o nuevos, registrando qué cubre cada uno.
- Si el perfil nativo o legado ya tiene diferencias en la base, documentarlas y
  mantenerlas: no corregir ahora el motor ni hacer pasar el legado por el nativo.
  Comparar contra la base aceptada usando evidencia aislada antes de ampliar alcance.
- HUD, mochila y guardado/combate siguen pasando en suites protegidas de C.

## C — cierre completo y revisión

python tools/architecture_handoff/run_checks.py --phase T004 --quick
python tools/architecture_handoff/run_checks.py --phase T004
python tools/architecture_handoff/guard.py --full

El runner exige dos tests nuevos; ejecuta integración nativa Y legado, contratos
HUD (431/116), suites previas y GPU. Quick y completo quedan separados. Los tests
protegidos no se modifican, saltan ni reducen. No fabricar PASS por contadores.
Los procesos largos deben seguir vivos en segundo plano con ventana oculta si la
herramienta tiene un timeout corto: guardar PID/log y esperar salida real. Si se
interrumpen, preservar parcial y repetir; nunca PASS mientras está pendiente.
No cambiar comprobadores, límites, permisos ni sellos para resolver el problema.

Escribir evidence/T004/REVIEW.md con cambios, tabla de compatibilidad, cobertura,
comandos/resultados reales, pendientes, hashes y lista de archivos. Indicar si no
se hizo prueba manual o captura específica; no reutilizar imágenes antiguas como
nuevas. Actualizar PROGRESS/TASKS: IMPLEMENTED_AWAITING_REVIEW + READY_FOR_REVIEW
si todo termina. No escribir ACCEPTED_BY_CODEX ni iniciar T005/T006. Tras dos
intentos fallidos sin progreso reproducible, BLOCKED con caso mínimo y logs.
