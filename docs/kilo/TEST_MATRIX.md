# Matriz de comprobaciones

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
