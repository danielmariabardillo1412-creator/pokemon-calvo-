# CUADERNOS DEL PROYECTO

Esta carpeta contiene **memoria temática consolidada**, no diarios cronológicos.

## Regla principal

No crear un cuaderno por cada PR, microfase o sesión. Un cuaderno existe mientras un tema necesite memoria operativa propia; al cerrar, queda como resumen humano y la evidencia detallada permanece en `../history/worklogs/`.

GitHub/CI/artefactos del SHA exacto tienen prioridad sobre cualquier cuaderno.

## Cuadernos actuales

### `GAME_FOUNDATION.md`

Estado: **ACTIVO — GF1-A**.

Workstream actual para convertir los subsistemas certificados en una mini-campaña real: game state, mapas/transiciones, NPC/eventos, Save V3, servicios/UI mínima y vertical slice E2E.

### `DATA_V3.md`

Estado: **CERRADO / CERTIFICADO**.

Resume fuente, contrato estructural, fronteras runtime, certificación final y condiciones para reabrir DATA V3.

### `TRAINER_AI.md`

Estado: **CERRADO / COMPLETED**.

Conserva la memoria completa de la línea FASE19–33 y C1–C3f que culminó en el cierre runtime 26.67.

### `TRAINER_AI_GAME_READY.md`

Estado: **CERRADO / VALIDATED**.

Conserva la fase post-cierre que añadió desempate game-ready, full-battle adversarial y benchmark, congelada en 27.1.

### `TRAINER_AI_EXPERTISE.md`

Estado: **CERRADO / CERTIFIED / FROZEN**.

Separa estilo táctico de competencia/expertise sin modificar la frontera anti-cheat.

### `TRAINER_AI_CAMPAIGN_PERSISTENCE.md`

Estado: **CERRADO / CERTIFIED / FROZEN**.

Conserva el cierre P1-A..P1-D de ownership, persistencia de consecuencias entre combates, recovery/replacement explícitos y rematch E2E.

### `TRAINER_AI_HANDOFF_2026-09-03.md`

Referencia histórica de relevo. No representa estado vivo posterior al freeze final.

## Cuándo crear otro cuaderno

Solo cuando empiece un workstream suficientemente grande y distinto como para que mezclarlo en otro cuaderno cree confusión.

## Diferencia con otras carpetas

- `../current/`: dónde estamos y qué toca ahora.
- `../architecture/`: cómo está construido el sistema.
- `../adr/`: por qué se tomó una decisión arquitectónica.
- `../history/`: evidencia y diarios cerrados.
