# Inicio del encargo — 2026-10-28

Raíz: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original protegido: `D:/Proyectos/Pokemon Calvo`.

Esta copia recoge el árbol local completo de código, arte, datos y cuadernos,
incluidos archivos todavía sin commit. No parte solo del antiguo HEAD
`0902de4c10d34a2a451c9acad83fbfea765ef270`. El manifiesto de copia registra
qué se ha copiado y qué capturas/caches históricos se han omitido.

## Lectura y ejecución

1. `AGENTS.md`: límites comunes.
2. `docs/kilo/ARCHITECTURE_TARGET.md`: mapa actual y destino.
3. `docs/kilo/TASKS.json`: tarea y puertas de revisión.
4. `docs/kilo/tasks/T006A_NATIVE_BRIDGE_RUNTIME.md`: único contrato activo; T001–T005 aceptados.
5. `docs/kilo/TEST_MATRIX.md`: comandos y evidencia esperada.
6. Consultar `docs/kilo/PROGRESS.md` antes de retomar una sesión.

Antes de editar, confirmar `Get-Location`, rama actual y `git status --short`.
Leer `docs/kilo/baseline/T006A/BASELINE_COMMIT.txt` y la revisión aceptada
`docs/kilo/evidence/T005/CODEX_ACCEPTANCE.md`. El juego aceptado está en 291861c;
el baseline T006A añade solo planos y comprobadores preparados por Codex.
Ejecutar `python tools/architecture_handoff/guard.py`
para comprobar las superficies protegidas. La preparación de la copia corresponde
a Codex; el ejecutor no debe repetir `prepare_copy.py` ni volver a sellar archivos.

## Dependencias ya disponibles

- Godot: `C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe`.
- Node: `D:/Herramientas/NodeJS/node.exe`.
- Python: `python` en este equipo.
- Motor fijado: `.godot/battle_reference/runtime/node_modules/@pkmn/sim`, versión 0.10.11.
- Perfil normal: `gen9calvounifiedv1`; el laboratorio dobles usa su perfil específico.
- Catálogo: `data/normalized/pokemon_api.json`, 1.082 definiciones de especie/formas
  y 919 movimientos en la demo actual. Tener definición no certifica toda mecánica.
- Arte y animaciones usados desde `.godot/` se han copiado: no son todos caches
  prescindibles. En particular no borrar `move_batch_catalog` ni `battle_reference`.

El nombre de aplicación de esta copia se ha diferenciado para aislar `user://`.
`project.godot` queda protegido después de ese ajuste. No apuntar save_path al
directorio de usuario del original ni importar su partida real para probar.

## Estado funcional preservado

Consultar `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json` y `ITEM_FIELD_V4.md` para
el estado de objetos. Siguen existiendo dependencias pendientes. Este encargo es
una reorganización y no autoriza completarlas, vetarlas ni cambiar sus reglas.

La integración Showdown vigente es autoridad del combate activo; BattleState es
su proyección para la presentación. El motor anterior sigue disponible para el
laboratorio y la escena heredada. No confundir documentación anterior con una
orden de volver al motor anterior o mantener dos autoridades simultáneas.

## Bloque activo

T001–T005 aceptados. Solo T006A: interfaz del mundo para ejecución del puente
nativo, migración de sus accesos y documentación del arranque/herencia.
La carga/publicación/recuperación se mantiene idéntica y espera T006B.
Pieza + integración + regresión antes de READY_FOR_REVIEW; no continuar a B.
Prompt: docs/kilo/OPENCODE_PROMPT.txt. Sello vigente: baseline/T006A.
No modificar configuraciones, verificadores, sellos, reglas ni mecánicas.
