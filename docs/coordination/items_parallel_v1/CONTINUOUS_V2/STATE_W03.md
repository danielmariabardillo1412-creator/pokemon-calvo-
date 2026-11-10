# IA3/W03 — CHECKPOINT DE CONTINUIDAD V2 (PENDIENTE DE PLAN)
Fecha de verificación: 2026-11-11. Rama propietaria: `codex/calvo-items-20261104-w03-camp006`.

## Estado contractual
- `branch`: `codex/calvo-items-20261104-w03-camp006`
- `mission_version`: `CONTINUOUS_V2` publicada en árbitra; **NO activada aún en nota propia W03**.
- `phase`: `AWAITING_IA6_W03_PLAN` (no es un bloqueo de código).
- `block`: **TANDA_05 cerrada 10/10**; ningún siguiente bloque preautorizado.
- `next_id`: **NO ASIGNADO**. No inventar `TANDA_06`.
- `checked/functional/new/blocked`: TANDA05 10/10 hitos; 1 Net Ball preexistente con QA L3 nativa; 0 objetos nuevos; 0 bloqueos técnicos de esa tanda.
- `last_green_code_sha`: `56155f824dd684989192407622c7c46d28836110`.
- `last_green_run_id`: [42922912695](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42922912695), `completed/success` para ese SHA.
- `ci_pending`: no. El HEAD `ede34010c57cffc7ea89cc36eabc8ea78b0038a5` es cierre documental `[skip ci]`, no SHA de CI.
- `owned_files_changed`: solo este checkpoint documental V2, sin modificaciones en el código.
- `protected_tickets`: `move_policy` de encuentro Magikarp nivel 5, fuera de permisos W03; consignado en `reports/W03/AUTORUN_V5_FINAL.md`.
- `next_safe_action`: IA6 debe activar protocolo V2 en **`IA6_AUTORUN.md` de la propia rama W03**, publicar un `PLAN_W03.md` autorizado con dominio, IDs verificables, orden y archivos permitidos, y vincularlo a ese archivo. Después un `p` puede comenzar el primer hito sin nueva puerta por cada diez.

## Pruebas de estado publicadas
1. `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` en W03 sigue indicando **TANDA 05** y únicamente sus diez hitos.
2. En `codex/calvo-items-20261101-arbitro`, `AUTONOMY_V1` contiene `QUEUE_W03_TANDA_05.md` pero no `QUEUE_W03_TANDA_06.md`.
3. El nuevo `CONTINUOUS_V2/README.md` arbitral dice literalmente que V2 es aplicable **desde la nota activa de cada rama**, y exige `PLAN_W0X.md` con backlog preautorizado; el directorio arbitral V2 solo incluye `README.md`, sin `PLAN_W03.md`.
4. La rama propia W03 no tenía directorio `CONTINUOUS_V2` antes de este checkpoint.

**Decisión de seguridad y trazabilidad:** no repetir TANDA05, no extrapolar del protocolo global una lista indefinida de objetos, no tocar `main`, V28, PR118 ni la rama árbitra desde W03, no declarar integración IA6. Estado: **READY_FOR_IA6_PLAN**.
