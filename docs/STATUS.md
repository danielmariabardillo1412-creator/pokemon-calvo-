# Estado actual del proyecto

## Baseline certificado

- Motor: **Godot 4.7**.
- Baseline previo a esta reorganización: `feature/data-foundation-v3`.
- HEAD certificado: `304035e2e7b39a628c4fece89cf0f3db6caa8664`.
- Validación: **18/18 workflows normales SUCCESS** sobre ese mismo HEAD.
- Política de desarrollo: las ramas validadas se conservan y los PR se cierran sin merge.

## Datos canónicos — DATA FOUNDATION V3

- 1025 especies base y 326 formas auditadas.
- 18 tipos de combate.
- 919 movimientos runtime.
- 373 habilidades y 2222 objetos.
- 61.102 entradas de learnset version-aware.
- 554 registros de evolución.
- 0 referencias rotas y 0 definiciones rechazadas.

Fuente inmutable: `data/api/v2` + `data/schema/v2`. Véase [DATA_FOUNDATION_V3.md](DATA_FOUNDATION_V3.md).

## IA de entrenadores

La línea FASE19–FASE33 está presente en el baseline y cubre sesión de entrenador, inteligencia táctica, beliefs sin cheating, búsqueda simultánea, presupuesto de profundidad, self-play/evaluación, adaptive branching, cobertura pública, objetos finitos, switching estratégico, loadouts y composición de equipos. Las decisiones están en [`adr/`](adr/).

## Organización del repositorio

Los recursos sintéticos/antiguos que todavía sostienen regresiones no son datos de juego canónicos: viven bajo `data/fixtures/`. Los documentos de fases cerradas viven bajo `docs/history/`; los ADR bajo `docs/adr/`.

El estado histórico acumulado anterior se conserva íntegro en [history/STATUS_PHASE_HISTORY.md](history/STATUS_PHASE_HISTORY.md).
