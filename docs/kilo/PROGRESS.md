# Progreso vigente — 2026-10-28

Estado: **T003_READY**.

S0: copia aislada y baseline de 11 grupos PASS. Rama codex/kilo-architecture-v1,
sin remotos y con partidas separadas del original. Datos, recursos y packs se
conservan. El baseline y las incidencias de preparación están en baseline/.

T001: Kilo extrajo la construcción del HUD conservando aspecto, acciones y alias.
Su quick pasó. T002 quedó interrumpido al llegar a medicine y el estado PASS
inicial era prematuro. Codex revisó el diff y terminó las comprobaciones.

Codex reforzó el contrato nuevo del HUD: pasó de una comprobación parcial de
botones a 116 comprobaciones de las nueve acciones y controles reales. No fue
necesario cambiar el código del juego entregado por Kilo.

Cierre: 12 grupos de T002 PASS, incluida GPU; 21.704 archivos protegidos
verificados por hash; comparación baseline/candidato de 16 comprobaciones PASS
y cero diferencias en las regiones capturadas del HUD. Ver evidence/T002/REVIEW.md
y CODEX_REVIEW.json para alcance, hashes y límites.

T001 y T002 aceptados en 866b009bb2abde67014ffe6d0b4ad1dc3cc5e8b5.
Codex habilita T003 con contrato en tasks/T003_HUD_RENDER.md. Aún no implementado.
T004–T006 siguen BLOCKED_REVIEW. Próximo ejecutor: Kilo, sin agentes paralelos.
El guard vigente está sellado en baseline/T003, preservando el baseline anterior.
No mezclar con el original. Al completar T003: READY_FOR_REVIEW y detenerse.
