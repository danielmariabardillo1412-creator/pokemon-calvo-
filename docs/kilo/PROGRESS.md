# Progreso vigente — 2026-10-28

S0 completado por Codex. Copia SHA-256 verificada: 25.467 archivos, 1.864.986.368
bytes antes de añadir los planos. Se conserva código/arte/datos locales y los
packs necesarios. Se omiten capturas históricas regenerables. Rama propia y
sin remotos; nombre de aplicación distinto para aislar las partidas.

Baseline: 11 grupos PASS, incluida GPU. Ver baseline/BASELINE_STATUS.json y
la evidencia baseline. El primer intento de map_runtime mezclaba dos rutas;
se documentó y se corrigió su invocación de laboratorio, sin cambiar tests o juego.

Siguiente: leer y ejecutar T001. Después T002 y STOP READY_FOR_REVIEW.
No se ha implementado ninguna extracción todavía. No seguir con T003–T006.

El repositorio contiene un punto de partida local completo. Los packs grandes
que siguen ignorados por Git están físicamente copiados y sellados; no borrarlos.
No hacer push, merge, reset, clean o cambios en el original.

Añadir bajo esta línea pasos, resultados y pendientes concretos del ejecutor.

## Preparación del ejecutor

El CLI instalado de Kilo 7.8.18 está disponible. El primer inicio creó la sesión
`ses_e7c14beb8ffeHqUrO1muhlGGWQ`, pero devolvió 401 PAID_MODEL_AUTH_REQUIRED.
Su modelo por defecto era google/gemini-3-pro-image. No comenzó a modificar código.
Se ha solicitado al usuario elegir cuenta/modelo de código o autorizar el modelo
gratuito cuyo proveedor puede utilizar prompts para entrenamiento. No se han
introducido credenciales ni cambiado sus ajustes globales.
