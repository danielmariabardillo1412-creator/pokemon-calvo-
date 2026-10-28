# Pokémon Calvo — copia de arquitectura para Kilo

La única raíz de escritura autorizada es `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
El juego original es `D:/Proyectos/Pokemon Calvo`: no editarlo ni ejecutar sus pruebas.

Lee `LEEME_KILO.md`, `docs/kilo/START_HERE.md`, `docs/kilo/ARCHITECTURE_TARGET.md`
y solo la tarea vigente en `docs/kilo/TASKS.json`. Estas instrucciones describen
esta copia. Los antiguos `docs/current/START_HERE.md` y documentos de arquitectura
describen etapas anteriores; no autorizan merges, trabajo funcional ni borrados.

Se permite un ejecutor OpenCode en esta copia, sin agentes paralelos. T001–T003
están aceptados; último checkpoint 513dd73. El único bloque activo es T004,
según docs/kilo/tasks/T004_FIELD_DIAGNOSTICS.md. Incluye sus pasos A/B/C como
un solo encargo. T005/T006 siguen bloqueados. Al finalizar T004 y todas sus
comprobaciones, detenerse con READY_FOR_REVIEW. No continuar automáticamente.

Método: preparar pieza, comprobarla, documentarla, preparar conexión, comprobar
conexión, activar. Cada cambio debe conservar el comportamiento. No inventar
mecánicas ni ampliar alcance ante una dependencia nueva: registrarla y detener
la tarea si impide cumplir su contrato. Dos intentos fallidos sobre el mismo
problema sin progreso reproducible obligan a entregar BLOCKED para revisión.

No cambiar datos, imágenes, movimientos, objetos, políticas, RNG, guardados,
autoridad de combate, Node/Showdown o partidas. No eliminar el motor anterior:
la escena principal todavía hereda de su laboratorio y usa su colección.
No debilitar, eliminar ni saltar pruebas para conseguir PASS. No regenerar packs,
datasets o fixtures. No descargar bibliotecas ni visitar F: o Nova para resolver
el encargo. Las dependencias necesarias ya están copiadas o documentadas.

Los únicos cambios autorizados están enumerados en el contrato T004. Ejecutar
`python tools/architecture_handoff/run_checks.py --phase T004 --quick` y después
`python tools/architecture_handoff/run_checks.py --phase T004`. No alterar el verificador, los sellos o la evidencia
baseline. Un fallo de comprobación no es un permiso para ampliar la lista.

No usar `git reset --hard`, `git clean`, restauraciones masivas, rebase, merge o
push. Esta copia no debe tener remotos. Se permite un commit local pequeño por
tarea aceptada por sus pruebas; no incluir caches, logs ni archivos ajenos.
Conservar cualquier trabajo local inesperado y pedir revisión mediante el informe.

Las instrucciones persistentes y los permisos de la herramienta son mecanismos
distintos. No ampliar permisos globales ni cambiar modelo/proveedor para salir
de un bloqueo. Informar exactamente qué comandos se ejecutaron y sus resultados.
