# SIGUIENTE TRABAJO

## Workstream activo — Trainer AI Expertise V1

Rama:

`feature/trainer-ai-expertise-v1`

Baseline cerrado de entrada:

`337a4f787c7da18f9cf649aea929e79912840b2a`

PR del workstream:

`#106 — Trainer AI Expertise V1 — contract audit`

Trainer AI runtime y Game-Ready siguen cerrados. Expertise V1 es una feature separada.

## Plan fijo — 4/4

1. E1-A contrato/hueco runtime — **COMPLETADO / CERTIFICADO**.
2. E1-B seguridad de knobs — **ACTUAL / TEST-AUDIT-ONLY**.
3. E1-C integración mínima de estilo + expertise.
4. E1-D E2E/regresión/doble certificación/freeze.

No añadir una quinta tranche por inercia.

## E1-A certificado

SHA:

`f8ca9d8ecfe7e2cd259e3affdd2fd048a73d1021`

Resultado:

- **18/18 workflows SUCCESS**;
- Evaluation: **426 PASS / 0 FAIL**;
- aggregate `TRAINER_AI_EXPERTISE_CONTRACT_AUDIT_COMPLETE`;
- cero producción.

Hallazgo confirmado:

- los perfiles de estilo existen y son distintos;
- el runtime proposal sigue usando `TrainerProfile.balanced()` fijo;
- no existe expertise/difficulty runtime;
- estilo y expertise siguen sin confundirse;
- anti-cheat y tie resolver no dependen de difficulty.

## E1-B — seguridad de knobs

Scope: **TEST/AUDIT-ONLY**.

Debe clasificar parámetros antes de usarlos en producción:

### Prohibido como shortcut

- `depth_turns=1`: el proposal Game-Ready exige profundidad 2;
- presupuestos que terminen con `budget_exhausted=true` o horizonte incompleto.

### Candidato a demostrar

- `max_actions_per_side` como branching interno: comparar cap 1 vs cap 3 con depth 2, determinismo, horizonte completo y misma frontera anti-cheat.

### No autorizado todavía

- bajar `MAX_WORLDS=4`;
- fijar un mínimo universal de simulaciones;
- errores artificiales/aleatoriedad para entrenadores débiles.

La nueva suite debe aportar 18 checks. Si pasa completa, Evaluation debería pasar de 426/0 a **444/0**.

## Barreras permanentes

- todas las dificultades comparten el mismo action-space legal;
- no leer acción actual del jugador;
- no conceder movimientos rivales ocultos;
- no usar RNG privado/live de Battle Core;
- no relajar completeness guards;
- profile no se usa como tiebreak oculto;
- PR #105 permanece OPEN / unmerged;
- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
