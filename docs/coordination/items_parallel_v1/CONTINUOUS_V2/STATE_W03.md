# W03 — CONTINUOUS_V2: campaña 25/25 examinados, último gate CI pendiente

- **branch**: `codex/calvo-items-20261104-w03-camp006`
- **mission_version**: `CONTINUOUS_V2/PLAN_W03.md`, publicado en IA6 y activado en `IA6_AUTORUN.md`.
- **phase**: `B03_CONTEXT_BLOCKS_REVIEWED` — 25/25 IDs examinados, final técnico condicionado a la CI acumulativa.
- **block**: B01 10/10 certificados; B02 10/10 examinados (8 lanzamientos nativos, Safari/Sport solo parciales, Dive/Dusk bloqueadas); B03 5/5 bloqueadas por productores auténticos ausentes.
- **next_id**: ninguno dentro del plan de 25. No inventar otra familia.
- **checked/functional/new/blocked**: 25 IDs; 16 rutas L3 completas de existentes; 2 rutas de zona parciales; 7 `BLOCKED_CONTEXT`; objetos nuevos=0; integración IA6=NO.
- **QA nueva por suite**: B01 `156 PASS` y B02 `125 PASS`, productores `58 PASS`, más sonda Magikarp y 3 ramas de Fast/Quick/Level a certificar con CI final.
- **last_green_code_sha**: `eb42cfee9236a17fbae58b697144c8fc22bb530d`.
- **last_green_run_id**: [42930597727](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42930597727), `completed/success`, contiene B01+B02+auditoría de 7 ausencias y 2 parciales.
- **ci_pending**: [42931723587](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42931723587), SHA código/workflow `2c4b0a63f04572be1dd86d565e7b71e78d897c65` (sonda Magikarp y ramas Fast/Quick/Level). Nunca declarar PASS antes de `completed/success`.
- **owned_files_changed**: runners `parallel_items_w03_continuous_v2_b01.gd`, `_b02.gd`, `_magikarp_probe.gd`, `_context_edges.gd`; auditoría `test_parallel_items_w03_continuous_v2_sources.py`; workflow W03; manifiesto, ticket y STATE.
- **protected_tickets**: `W03_CONTEXT_PRODUCERS_TICKET.md` documenta siete productores regionales ausentes y dos zonas parciales. Magikarp L5 `move_policy` reproducido como fallo previo a captura; sin corregir política o generador protegidos.
- **next_safe_action**: revisar el resultado final de #42931723587. Ante PASS publicar `W03_CAMPAIGN_FINAL.md` y estado `READY_FOR_IA6`. Ante FAIL reparar únicamente runner/fixture o seam específica autorizada, mantener CI previa verde y reintentar.

---
## Historia anterior preservada
# IA6 — ACTIVACIÓN CONFIRMADA V2 DE W03 (prevalece sobre checkpoint provisional)
**Plan ya publicado y vigente en `IA6_AUTORUN.md` de esta misma rama.** La espera `AWAITING_IA6_W03_PLAN` descrita abajo quedó SUPERADA; se escribió mientras IA6 publicaba los archivos en paralelo.
- mission_version: `CONTINUOUS_V2/PLAN_W03.md` de rama árbitra (copia íntegra también en `IA6_AUTORUN.md` de W03).
- phase: B01 — 25 bolas autorizadas, varios bloques de hasta diez; NO parar al acabar uno.
- next_id: `poke_ball` (confirmar contra el checkpoint/HEAD más reciente antes de ejecutar).
- last_green_code_sha: `56155f824dd684989192407622c7c46d28836110`
- last_green_run_id: `42922912695`
- next_safe_action: leer la nota nueva `IA6_AUTORUN.md` y ejecutar el primer hito de la campaña continua; registrar cada resultado, pasar al siguiente bloque sin pedir IA6.
- riesgo: solo seam específica de bolas W03, no otros módulos protegidos.

---

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
