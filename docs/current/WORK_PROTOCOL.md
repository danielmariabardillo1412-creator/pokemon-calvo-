# Protocolo de trabajo de esta copia

Trabajar solo en `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
El original `D:/Proyectos/Pokemon Calvo` está protegido. Un escritor, sin agentes
paralelos. El usuario autorizó la publicación V27 en GitHub el 2026-10-31:
`codex/organized-update-v27`, sin merge de main ni retirada de ramas antiguas.
Ver GITHUB_UPDATE_V27.md. La prohibición anterior de configurar remoto/publicar
queda sustituida solo para esta entrega; los sellos históricos no se modifican.

## Cambios y comprobación

Identificar consumidores antes de retirar código o recursos. Limpiar por bloques,
revisar el diff y ejecutar pruebas pertinentes. Si aparece un fallo, explicar su
causa, corregirla y repetir el bloque afectado antes de seguir. Un archivo antiguo
puede seguir siendo necesario para ejecutar o reproducir una prueba.

Conservar checkpoints locales en Git. No crear copias dispersas de documentación
retirada. Mantener contratos, evidencia, fuentes y créditos que aún tengan uso.
El comparador se ejecuta en copias físicas con partidas aisladas; una nueva versión
requiere una nueva carpeta de resultados. No ejecutar pruebas contra el original.

Un exit 0 no basta si hay errores de script, asserts fallidos o cero comprobaciones.
Un timeout no es PASS. Una prueba repetida debe conservar el fallo anterior.
Un fallo común a ambos juegos sigue requiriendo análisis. Una igualdad de estados
no demuestra ausencia de errores compartidos.

## Autoridad y límites

Las instrucciones humanas vigentes y el alcance acordado prevalecen. Contrastar
afirmaciones con el código real y contratos de referencia. CI, snapshots y cuadernos
históricos describen sus bytes exactos; no son órdenes para repetir promociones
de ramas ni tareas ya aceptadas.

Datos, políticas y arte quedan fuera de esta limpieza. No regenerar datasets
ni modificar fuentes inmutables para hacer pasar una prueba. Distinguir presencia
en catálogo, efectos implementados y mecánicas verificadas.

Los verificadores de `tools/architecture_handoff/` conservan los sellos originales
de T006B y tienen consumidores en los runners de objetos. No resellarlos ni
usarlos para certificar cambios nuevos fuera de aquel alcance.

Documentar decisiones materiales en el estado vivo o cuaderno temático; mantener
la evidencia detallada por ejecución. No certificar cobertura global a partir
de un lote. Pruebas técnicas de imágenes no son aprobación artística.
