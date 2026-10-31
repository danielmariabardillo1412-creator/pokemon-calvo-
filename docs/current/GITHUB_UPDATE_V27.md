# Actualización organizada V27 — 2026-10-31

Se publica la copia organizada existente, con su historial de trabajo, en el
repositorio `danielmariabardillo1412-creator/pokemon-calvo-`, rama
`codex/organized-update-v27`. El checkpoint funcional de partida es
`6629fe570cdf4c891a937c3f2a74b45e960dc902`, con aclaración documental en `34a7c6f1`.
No se fusiona main ni se eliminan ramas, el original protegido o recursos locales.

## Código y recursos

El historial remoto main es antecesor de la copia organizada; esta entrega no
reescribe commits. Conserva arquitectura T001–T006B, correcciones de datos,
integración de combate y objetos, políticas y documentación actual.
La publicación no añade ni modifica reglas del juego.

Los recursos de desarrollo ignorados por Git se distribuyen en la release
`dev-organized-v27-2026-10-31`, junto con inventario y SHA-256 fijados en
`ci/resources_v27.json`. Incluye catálogos base/variantes y los recursos usados por
el catálogo actual de movimientos, sus pilotos activos y referencias de prueba.
Se omiten exportaciones antiguas `generation_*` ajenas al índice/manifiesto
vigentes, cachés de editor, node_modules, partidas y registros locales.
No se borra ninguna exportación del disco. Los paquetes no regeneran imágenes.
Los iconos de objetos ya versionados se conservan en el código.

No se suben bibliotecas externas de F: ni se regenera ningún dataset. Los archivos
`data/api/v2` ya presentes en Git conservan su historia; los 15.647 archivos ausentes
con skip-worktree no se materializan ni se eliminan del árbol de esta copia.

Se conservan créditos/procedencia existentes. Esta es una entrega de desarrollo:
no constituye aprobación artística final, auditoría de permisos de todo el arte
ni certificación de todas las mecánicas de un juego completo.

## Revisión de organización

Revisados los cambios de soporte de mochila nativa, modificadores de encuentro y
fronteras de campo: reglas en helpers, coordinación transaccional en sesiones y
presentación en la UI. `field_native_bridge.gd` y `field_item_bag.gd` no recuperan
accesos `field._*`, `field.player`, `field.test_panel` o `field.traversal_controller`.
No se realiza una nueva reestructuración ni se afirma que todo el proyecto esté
libre de deuda técnica. Se vuelven a ejecutar contratos e integraciones relevantes.

Las guardas locales antiguas prohíben remotos o exigen rutas D:/; son evidencia
de su fase, no puertas portables para esta entrega. No se alteran sus sellos.
El gate independiente de publicación está en `tools/distribution/verify_update.py`.
La evidencia de esta entrega se conserva en `GITHUB_UPDATE_V27_RESULTS.json`;
los logs detallados locales usan `.godot/publication_v27/runs/`.

## Continuación

Primero validar un checkout y sus recursos. La futura misión remota tendrá sus
propios planos y archivos permitidos; esta publicación no reactiva misiones
OpenCode cerradas. Un único escritor y revisión por familias, con pruebas reales
y pendientes explícitos cuando falte una dependencia.

Siguen vigentes los diez objetos evolutivos restaurados y los cuatro originales
restantes. Se elimina solo el intercambio en una fase futura: conservar objeto
equipado y nivel todavía por definir. Cordón Unión continúa excluido. No elegir
niveles ni adaptar evoluciones durante esta publicación. Primero terminar objetos.
