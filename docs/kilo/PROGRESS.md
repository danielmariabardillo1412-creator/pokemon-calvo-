# Progreso vigente — 2026-10-28

Estado: **PILOT_ACCEPTED_WAITING_NEXT_PLAN**.

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

T001 y T002 quedan aceptados. T003–T006 siguen BLOCKED_REVIEW. No avanzar por
iniciativa propia, mezclar con el original ni iniciar otra reforma. El siguiente
paso es que Codex prepare y habilite el contrato del siguiente bloque.
