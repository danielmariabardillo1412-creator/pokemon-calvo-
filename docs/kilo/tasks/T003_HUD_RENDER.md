# T003 — presentar el HUD a partir de datos simples

Predecesor aceptado: T001/T002, commit 866b009bb2abde67014ffe6d0b4ad1dc3cc5e8b5.
Ejecutar únicamente en D:/Proyectos/Pokemon Calvo - Arquitectura Kilo.
Objetivo: sacar el formateo de textos de field_demo sin alterar consultas,
estado, tiempos, acciones, controles o aspecto. No es una reforma general.

## Superficie exacta

Se permite modificar únicamente:
- scenes/visual/field_demo.gd: `_refresh_hud` y un nuevo método de instantánea.
- scenes/visual/field_hud.gd: añadir `render_snapshot(snapshot: Dictionary) -> void`.
- tests/gameplay/field_hud_render_test_runner.gd y su .uid: runner nuevo.
- docs/kilo/PROGRESS.md y TASKS.json: estado de T003, sin desbloquear otras tareas.
- docs/kilo/evidence/T003/ y T003_quick/: evidencia real de esta fase.

No cambiar build(), controles, callbacks, alias, `_process`, visibilidad, fuentes,
colores, posiciones o tamaños. Los avisos `_notice_label` pertenecen a sus acciones:
render_snapshot no debe borrarlos ni reescribirlos. No reformar helpers duplicados.
No modificar el contrato existente del HUD (116 checks), otros tests, verificadores,
planes, sellos, motor, datos, arte, guardados o servicios. No ampliar la lista.

## Frontera de datos

field_demo conserva toda lectura de configuración, región, colección, auditoría,
catálogos y el cálculo encounter_expectation(). Añadir `_hud_snapshot() -> Dictionary`
que consulta esas fuentes y devuelve SOLO valores String, bool, int y float,
sin Objects, Nodes, Resources, Callables, colecciones vivas ni referencias al mapa.
Resolver StringName y el nombre de especie localizado en el dueño, como ahora.
No cambiar el orden semántico, RNG ni resultados de esas consultas.

Claves explícitas de la instantánea:
- region_id (String), cave_title_min_level (int, defecto 8), cave_title_max_level (12).
- encounters_enabled (bool), encounter_percent (int), mean_steps y mean_walking_seconds (float).
  Si están deshabilitados, medias 0.0; no consultar claves ausentes sin defecto.
- rolls, encounters, captures (int) y grass_walking_seconds (float).
- party_size, poke_balls (int), species_label (String, ya traducido o Pool aleatorio).
- min_level y max_level (int): valores de cueva o salvaje según región, con los
  mismos defectos 4 y 6 que usa hoy la línea de colección.

La cabecera de cueva usa actualmente defectos 8/12 y su línea de colección 4/6.
Conservar esa diferencia deliberadamente: corregirla sería otro cambio.
`_refresh_hud()` solo obtiene instantánea y llama `_hud.render_snapshot(...)`.
El nuevo render aplica exclusivamente los cinco textos (lugar, botón frecuencia,
media, observado, colección). Copiar literalmente formatos, tildes, signos,
espacios, decimales y ramas de la versión aceptada. No precalcular todos los
textos en el dueño para aparentar separación. No guardar el diccionario en la vista.

## Secuencia y comprobaciones

1. Confirmar ruta, rama codex/kilo-architecture-v1, estado Git y guard PASS.
   Leer guard baseline/T003/BASELINE_COMMIT.txt. Si hay trabajo inesperado, conservar
   e informar; no restaurar a ciegas. No preparar de nuevo la copia.
2. Leer `_refresh_hud` del checkpoint aceptado con git show 866b009:scenes/visual/field_demo.gd.
   Añadir render_snapshot y el runner nuevo; comprobar la pieza aislada primero.
3. En el runner nuevo usar resultados esperados literales tomados de la versión
   aceptada, no una segunda implementación del formateador. Cubrir ruta, cueva,
   refugio; frecuencia 0 y 100, medias decimales, contadores cero y no cero,
   nombre traducido/pool aleatorio, valores predeterminados y sobrescritos de nivel.
   Incluir transición ruta→refugio→cueva→ruta sobre la misma vista para detectar
   textos antiguos. Comprobar que los avisos y las referencias UI no cambian,
   no se dispara ninguna acción y la entrada no se modifica.
4. Conectar el dueño mediante `_hud_snapshot` y `_refresh_hud`. Añadir al mismo
   runner al menos una prueba con la escena REAL: la instantánea tiene solo
   escalares permitidos; sus valores coinciden con las fuentes del dueño y los
   cinco textos se actualizan al cambiar configuración/región. No sustituir
   la escena por un mock que repita el código bajo prueba. Usar inicialización
   y acceso de pruebas ya existentes como referencia, sin editar esas pruebas.
   Repetir actualización no debe consumir inventario, modificar equipo/guardado,
   reiniciar la partida o consumir RNG. No crear setters de juego para el test.
5. Ejecutar quick y suite completa de TEST_MATRIX. Si falla por dependencia fuera
   de alcance, registrar BLOCKED; tras dos intentos sin progreso, detenerse.
6. Ejecutar guard --full. Revisar diff: solo dos archivos de juego y test nuevo,
   más estado/evidencia autorizados. No arreglar la barra inferior fuera de pantalla:
   ya existía y está documentada en la revisión del piloto.
7. Crear evidence/T003/REVIEW.md: cambios, contrato de datos, comandos/resultados,
   ficheros tocados, fallos/omisiones, límites. Capturas nuevas si se ejecutaron;
   nunca reutilizar capturas del piloto presentándolas como prueba nueva.
   Actualizar T003 como IMPLEMENTED_AWAITING_REVIEW si todo pasa; estado global
   READY_FOR_REVIEW. No escribir ACCEPTED_BY_CODEX. No iniciar T004.

## Comandos autorizados

python tools/architecture_handoff/guard.py
python tools/architecture_handoff/run_checks.py --phase T003 --quick
python tools/architecture_handoff/run_checks.py --phase T003
python tools/architecture_handoff/guard.py --full

Quick conserva results.json en evidence/T003_quick, separado del completo T003.
Un timeout o un test no ejecutado no es PASS. Si se corta, retomar desde logs
sin saltar grupos; no cambiar verificadores ni ocultar la causa. Entregar
READY_FOR_REVIEW solo con resultados completos o BLOCKED con explicación clara.
