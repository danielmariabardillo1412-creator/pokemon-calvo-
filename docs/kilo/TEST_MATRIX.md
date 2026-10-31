# Matriz de comprobaciones

Matriz histórica de T001–T006B, aceptada en 208c06c0. Conserva comandos y
evidencia de esas versiones. Los sellos de entonces no certifican cambios
posteriores. Estado vivo y verificaciones nuevas: `docs/current/START_HERE.md`.

Todos los comandos se ejecutan desde `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Las pruebas usan el directorio de usuario de esta copia. El runner captura stdout
y stderr, exige exit code cero y rechaza SCRIPT ERROR/ERROR aunque el proceso
termine con cero. No mide éxito por frases sueltas ni oculta grupos fallidos.

## Baseline S0 — lo prepara Codex

Importación: `& 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe' --headless --path . --editor --import --quit`.
Después: `python tools/architecture_handoff/run_checks.py --phase baseline`.

La evidencia queda en `docs/kilo/evidence/baseline/results.json`. Debe dar PASS.
Los contadores son resultados de esta copia; no copiar números históricos al informe.

## T001 — comprobación dirigida

`python tools/architecture_handoff/run_checks.py --phase T001 --quick`

Importa primero las clases/UID de las piezas nuevas y después ejecuta el
contrato nuevo del HUD, campo nativo, objetos de campo y conexiones
de equipo/MT/evolución. Además verifica límites de archivos antes y después.

## T002 — regresión completa del piloto

`python tools/architecture_handoff/run_checks.py --phase T002`

| Grupo | Qué protege |
| --- | --- |
| HUD nuevo | Construcción aislada, callbacks y referencias de controles. |
| field_native | Recorrido activo, autoridad nativa, captura, cierre, guardado y actividad de UI. |
| map_runtime | Movimiento, salto, aterrizaje y captura del laboratorio anterior; `--legacy-field` explícito. |
| visual_legacy | Laboratorio anterior con `--legacy-field` explícito; no sustituye las pruebas de la ruta nativa. |
| field_items | Medicinas, PP, EV, reloj de sueño, guardado/carga y entrada al combate. |
| item_connections | Equipados, MT, evolución, mochila y bloqueo durante combate. |
| medicine | Contrato de medicinas del motor nativo. |
| savegame y save_adversarial | Persistencia y rechazo atómico de estados inválidos. |
| item_policy | Vetos y selección. |
| inventory_capture | Propiedad, cantidades y captura. |

El runner completo también ejecuta la prueba GPU siguiente en proceso secuencial
y con ventana oculta, conservando log y captura en la evidencia de la fase:

`& 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe' --path . --resolution 1280x720 --script tests/gameplay/item_field_effects_v4.gd -- --capture`

También puede abrirse JUGAR_DEMO.cmd para comparar HUD caminando, F1, F2, F3,
B, cierre de mochila y ocultación del HUD al entrar a combate. Registrar lo
ejecutado realmente. No anunciar una prueba manual que no se hizo. Copiar las
capturas pertinentes a la evidencia T002 y mantener el arte intacto.

## Integridad

`python tools/architecture_handoff/guard.py` comprueba hashes de texto y metadatos
de recursos; si un recurso cambia de tamaño/fecha, comprueba también su hash.
`--full` calcula todos los hashes y se usa en la revisión completa. La copia
original de cada archivo ya se verificó por SHA-256 antes del aislamiento.
Los `.import` y caches regenerables no son reglas de juego ni están sellados.

Una prueba que necesita otra dependencia queda BLOCKED con su motivo, nunca PASS.
No regenerar recursos ni modificar el runner para salvarla. Guardar el error y
pedir revisión mediante PROGRESS. No hacer cambios en el proyecto original.

## T003 — aceptado

T001/T002 son historia aceptada; no volver a implementar sus contratos.
Ejecutar `python tools/architecture_handoff/run_checks.py --phase T003 --quick`
y después `python tools/architecture_handoff/run_checks.py --phase T003`.
El runner exige el nuevo field_hud_render_test_runner.gd, conserva también los
116 checks del contrato previo y todos los grupos completos/GPU de T002.
Quick y completo escriben T003_quick y T003 separados. Los contadores deben ser
reales; no se fija un número para el nuevo runner ni se autoriza reducir los previos.
Finalizar con `python tools/architecture_handoff/guard.py --full`.
El sello vigente está en baseline/T003; no regenerarlo. El anterior se preserva.

## T004 — aceptado

Pieza aislada: `python tools/architecture_handoff/run_checks.py --phase T004 --piece`.
Solo requiere el runner nuevo field_diagnostics_test_runner.gd. No acredita integración.

Quick: `python tools/architecture_handoff/run_checks.py --phase T004 --quick`.
Exige ambos runners nuevos, ejecuta contrato aislado, integración nativa, integración
con --legacy-field, contratos HUD (431/116), campo nativo y objetos/conexiones.

Completo: `python tools/architecture_handoff/run_checks.py --phase T004`.
Añade a los 13 grupos del cierre T003 los 3 grupos de diagnóstico anteriores:
16 grupos, incluida GPU, ejecutados secuencialmente. No contar como tres grupos
una sola ejecución ni eliminar pruebas anteriores para acelerar.
Pieza, quick y completo usan T004/piece, T004_quick y T004 respectivamente.
Final: `python tools/architecture_handoff/guard.py --full`.
El sello activo es baseline/T004; el ejecutor no lo edita ni regenera.

## T005 — aceptado

`python tools/architecture_handoff/run_checks.py --phase T005 --piece`: runner
field_api_test_runner.gd en nativo y --legacy-field (2 grupos). No acredita mochila.
`python tools/architecture_handoff/run_checks.py --phase T005 --quick`: API en
ambos perfiles + field_api_integration_test_runner.gd + 8 grupos quick T004 = 11.
`python tools/architecture_handoff/run_checks.py --phase T005`: los 3 nuevos y los
16 anteriores = 19 grupos, incluida GPU. Sin omitir grupos anteriores.
Pieza/quick/completo escriben T005/piece, T005_quick y T005 por separado.
Cierre: `python tools/architecture_handoff/guard.py --full`. Sello baseline/T005.

## T006A — aceptado

Pieza: `python tools/architecture_handoff/run_checks.py --phase T006A --piece`:
field_bridge_world_test_runner.gd en nativo/--legacy-field (2 grupos).
Quick: `python tools/architecture_handoff/run_checks.py --phase T006A --quick`:
2 anteriores + field_bridge_runtime_test_runner.gd nativo + 11 de T005 = 14.
Completo: `python tools/architecture_handoff/run_checks.py --phase T006A`:
3 nuevos + 19 de T005 = 22 grupos incluida GPU; no omitir suites anteriores.
Cierre: `python tools/architecture_handoff/guard.py --full`.
Evidencia: T006A/piece, T006A_quick y T006A. Sello vigente baseline/T006A.
Las cuatro funciones de persistencia del puente siguen textualmente congeladas.
T006A PASS no implica T006 completo: T006B requiere otra revisión y contrato.

## T006B — fase vigente

`python tools/architecture_handoff/run_checks.py --phase T006B --piece`:
field_restore_contract_test_runner en nativo y --legacy-field, 2 grupos.
`python tools/architecture_handoff/run_checks.py --phase T006B --quick`:
2 anteriores + field_restore_integration_test_runner + 14 quick de A = 17.
`python tools/architecture_handoff/run_checks.py --phase T006B`:
3 nuevos + 22 anteriores = 25 grupos incluida GPU, sin omitir suites previas.
Cierre: `python tools/architecture_handoff/guard.py --full`.
Evidencia T006B/piece, T006B_quick y T006B. Sello activo baseline/T006B.
Funciones anteriores del mapa y runtime del puente aceptados en A congelados;
solo los 4 métodos de persistencia se abren a edición en esta fase.
