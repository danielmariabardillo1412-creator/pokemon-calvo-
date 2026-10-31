# Limpieza y correcciones — 2026-10-29

Autorizada por el usuario tras terminar el comparador V1. Se trabaja en la copia
organizada; original y resultados V1 intactos. Checkpoint anterior a la limpieza:
`021a9c5`. Los archivos retirados se recuperan con Git, sin nuevas copias dispersas.

## Documentación y herramientas

- Sustituidos los estados/órdenes acumulados de README, inicio, estado, siguientes
  pasos, protocolo e índice. PROJECT_STATE y NEXT_STEPS sumaban casi 300 KB de fases
  anteriores contradictorias. Se conserva el estado vigente, sus referencias y
  los límites; la versión extensa anterior permanece en Git.
- Retirados ocho archivos de ejecutores cerrados: LEEME_KILO, kilo.jsonc,
  .kilocodeignore, la regla oculta .kilocode/rules/00-copy-scope.md, ambos prompts,
  start_kilo.py y prepare_copy.py. Búsqueda de
  consumidores: solo entradas documentales históricas y el propio lanzador.
- `docs/kilo/START_HERE.md` marca el plan como cerrado. La identidad de la copia
  en `.kilo-handoff.json` permanece porque la lee `guard.check_root()`; ya no
  declara T006B activa. No se cambian los sellos históricos.
- Conservados guard.py/run_checks.py: los importa run_field_recovery_v5.py y los
  runners posteriores de objetos. Conservados contratos, evidencia y créditos.
- Motores anteriores conservados: la demo visual hereda del mundo técnico y
  siguen existiendo consumidores reales. Antigüedad no demuestra falta de uso.
- Retiradas ocho cadenas cerradas de comparación antes/después del renderer:
  anchor, art_motif, beam_endpoint, local_effect, motion_path, projection,
  self_body y water_layer. Son 24 archivos (runners, UID y generadores de hojas).
  Exigían ocho versiones previas concretas de preview_before.gd que no forman
  parte del juego. Búsqueda de consumidores en tools/tests/CI: cada runner solo
  lo usaba su generador de hojas; ningún consumidor del juego. Ambos retirados.
  Código e informes históricos recuperables en Git/V1; no se alteran sus fallos.
  El inventario declara la retirada incluso al inspeccionar la fuente antigua.

  Permanecen community_move_preview, move_beam_geometry, move_camera_repair,
  move_self_screen, catálogo, playback, filtros, layout y combate real. Estos
  verifican el estado actual, no una comparación entre dos arreglos históricos.
  No se afirma que sustituyan todas las comparaciones de píxeles de los ocho
  trabajos cerrados ni que supongan nueva aprobación artística completa.
- Retirados también los dos audits de importación de etapas gap/hue y sus
  generadores de prueba de procedencia (seis archivos). Exigían que el índice
  global siguiera siendo exactamente el de aquella ampliación del catálogo;
  los informes V1 señalan solo ese índice antiguo como fallo, sin fallos de los
  oráculos de píxeles/prioridad. No eran comprobaciones del catálogo completo
  actual. Se conservan los convertidores move_sheet_hue/move_gap_repairs y sus
  unit tests, usados por el pipeline actual. Las pruebas e informes retirados
  son recuperables en Git/V1 y no se convierten en PASS.

## Correcciones verificadas

- Escena principal: el contrato comprueba la escena visual, su herencia del mundo
  técnico y sus nodos. Las pruebas de la ruta anterior conservan su fixture técnica;
  no se cambia la configuración del juego para satisfacer una ruta antigua.
- Auditorías de IA: extracción de funciones compatible con CRLF, sin leer funciones
  vecinas; reconocimiento del array de eventos que ahora acumula continuaciones.
  Casos negativos del auditor conservados. No se cambia el algoritmo de IA.
- Prueba de traversal: liberados dos nodos de contrato (portal y salto) que nunca
  entraban en el árbol y quedaban vivos al salir. El primer intento con los avisos
  de fuga se conserva, seguido de la repetición limpia.
- Datos: siete muestras fuente inmutables, 150.126 bytes en total, extraídas de
  blobs Git idénticos en ambos proyectos, con manifest/hashes/licencia. Solo tests;
  no se restaura la biblioteca bruta ni se regenera el dataset. Los contratos de
  procedencia siguen comprobando las fuentes y sus efectos, ahora sin un checkout
  completo de data/api. La clasificación de habilidades comprueba raw/normalized;
  la procedencia de importación usa los tres snapshots CI existentes. No presenta
  los informes locales antiguos como clasificación vigente del motor nativo.
- Escalas: se distinguen las 1.025 referencias base de las 57 parejas regionales
  con métricas propias. No se inventa una referencia externa para las regionales.
- Ataques: se comprueba la reproducción real del catálogo cuando sustituye el
  overlay genérico, incluida su visibilidad y efecto confirmado; no se exigen ambos.
  GPU final: 20 turnos, 37 capturas, 4.916 comprobaciones PASS.
- Clasificador del comparador: `checks=4630 failures=0` ya no se interpreta como
  4.630 fallos; contadores positivos de fallos, errores de script, exits no cero
  y timeouts siguen siendo rojos. 17 unit tests PASS.
- Caché opcional del laboratorio: reconstruida con el builder existente, fuentes
  ya descargadas y hashes verificados. La generación nueva tiene su propia ruta,
  sin sobrescribir la antigua ni cambiar imágenes fuente, datos o combate.
  Se resolvió el rechazo de contexto obsoleto; GPU: 8.048 checks PASS.

## Resultado y límites

38 archivos versionados obsoletos retirados; estado documental consolidado.
Se conserva además el borrado de la carpeta local vacía de Kilo, sin tocar VS Code.
No se borra material por antigüedad si tiene consumidores actuales.

Verificación: 26 grupos de Godot, importación final y cuatro suites Python; todos
PASS en el cierre. Incluye mundo/IA, datos, dibujador, geometría/capas/layout,
API, combate nativo, mochila/objetos, guardado y recuperación. Los checks masivos
de píxeles no equivalen a tantos escenarios independientes de juego.
Detalle reproducible de comandos, contadores y SHA de logs:
[CLEANUP_RESULT.json](CLEANUP_RESULT.json). Logs locales en
`.godot/cleanup_checks/`; no se consideran resultados las cachés anteriores.

Integridad completa contra los manifiestos V1: original 25.251 archivos PASS;
producción de la organizada 6.987 PASS (módulos, escenas, configuración, datos,
arte, workflows y lanzadores). No se ha cambiado el código del juego ni sus
reglas, formatos de guardado, recursos o datasets. Solo pruebas, herramientas,
documentación, identidad histórica del encargo y caché del laboratorio.

El plan de limpieza declarado queda cerrado, no se certifica ausencia universal
de errores ni aprobación artística de todo el catálogo. Los audits retirados
son trabajos de migración históricos, no pruebas actuales aprobadas. Los contratos
y sellos de T006B/V5–V7 siguen describiendo sus checkpoints; no se resellan. Una
fase nueva debe declarar este checkpoint de limpieza y sus cambios autorizados,
sin ejecutar un guard histórico como certificación del árbol nuevo.

El comparador V1 registra 135 casos, incluidos intentos iniciales y repeticiones;
no son 135 defectos independientes. El informe V1 no se modifica con esta limpieza.
Las nuevas pruebas y resultados se registrarán aquí al terminar cada bloque.
