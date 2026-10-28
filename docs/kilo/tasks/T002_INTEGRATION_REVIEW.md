# T002 — verificar las conexiones del piloto y preparar revisión

Requiere T001 con sus comprobaciones PASS. Este bloque no autoriza otra extracción.

1. Revisar el diff del piloto contra el commit baseline. Confirmar que los únicos
   cambios funcionales son los admitidos en T001 y que la vista no recibe el mapa.
2. Ejecutar `python tools/architecture_handoff/run_checks.py --phase T002`.
   Todos los grupos baseline deben seguir pasando. La reducción o salto de
   comprobaciones exige revisión; no se acepta como una mejora de rendimiento.
3. Ejecutar el contrato nuevo del HUD y conservar su resultado junto a los anteriores.
4. Abrir esta copia con GPU mediante las pruebas indicadas en TEST_MATRIX:
   mochila, configuración, galería, HUD visible al caminar y oculto durante combate.
   Mantener capturas comparables al baseline. No editar arte o posiciones para
   mejorar el diseño durante este encargo.
5. Verificar que la aplicación usa su directorio de usuario aislado y que no se
   han modificado archivos protegidos. No cargar la partida real del original.
6. Escribir `docs/kilo/evidence/T002/REVIEW.md`: cambios, comandos, resultados,
   conexión de los nueve callbacks, alias conservados, límites y pendientes.
   Indicar resultados omitidos/fallidos de forma explícita; no sintetizar PASS.
7. Actualizar T001/T002 en TASKS y PROGRESS. Dejar el estado global
   READY_FOR_REVIEW y detenerse. Codex revisará antes de activar T003.

Si aparece una regresión, corregir exclusivamente dentro de T001. Tras dos
intentos sin progreso o si requiere otra superficie, entregar BLOCKED con el
caso mínimo y los logs. No ampliar la reforma para desbloquearla.
