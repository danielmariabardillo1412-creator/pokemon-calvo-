# SIGUIENTE TRABAJO

## Workstream activo — Trainer AI Campaign Persistence V1

Rama:

`feature/trainer-ai-campaign-persistence-v1`

Parent original certificado:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

PR #107: **OPEN / DRAFT / NOT MERGED**.

## Plan fijo — P1-A/P1-B cerrados, P1-C siguiente

1. **P1-A — ownership/persistence boundary audit** — **CLOSED / CERTIFIED / TEST-AUDIT-ONLY**.
2. **P1-B — contrato persistente + recovery/replacement** — **CLOSED / CERTIFIED / CONTRACT-FIRST**.
3. **P1-C — integración productiva mínima** — **NEXT**.
4. **P1-D — rematch/cross-session E2E + freeze** — PENDIENTE.

No añadir una quinta tranche por inercia.

## P1-B — evidencia cerrada

Checkpoint técnico exacto:

`f900fb79fb324c6e05d218eb741352e4d3a5db1f`

- suite P1-B: **27/27 PASS**;
- Trainer Evaluation Corpus: **548 PASS / 0 FAIL**;
- Team Composition: **SUCCESS**;
- full CI técnico: **18/18 workflows SUCCESS**;
- **0 producción / 0 Battle Core**.

Probe runtime certificado sobre la misma `CreatureInstance`:

- HP `118 -> 115` persiste;
- PP `20 -> 19` persiste;
- `burn` persistente sobrevive;
- volatile se elimina;
- Attack stage `+2 -> 0`;
- identidad preservada.

Esto fija sin ambigüedad que el futuro owner no puede auto-curar, clonar identidades ni persistir BattleState.

## Gate antes de P1-C

El HEAD documental que sincroniza el cierre de P1-B debe pasar **18/18 workflows SUCCESS**. Solo ese HEAD verde puede utilizarse como parent certificado de producción P1-C.

## P1-C — trabajo autorizado tras gate documental

P1-C debe ser una integración productiva **mínima**.

Objetivo:

1. Introducir un owner persistente dedicado fuera de `BattleState` y `TrainerBattleSession`.
2. Hacer que posea las mismas `CreatureInstance`, sin clones de identidad.
3. Validar IDs/ownership en modo fail-closed.
4. Mantener por defecto las consecuencias post-battle que deja `reconcile_post_battle()`; **sin auto-heal**.
5. Exponer recovery como operación inter-battle explícita, no automática.
6. Exponer campaign replacement como operación fuera de batalla, separada del forced replacement de Battle Core.
7. Sustituir el ownership ad-hoc del punto de integración actual por este owner con el menor cambio posible.
8. Mantener la vertical slice one-shot durante P1-C si ello permite separar producción del E2E de revancha; P1-D es el tramo que debe probar dos encuentros/cross-session reales.

### Barreras P1-C

No autoriza:

- tocar Save V2;
- persistir `BattleState` completo;
- conectar `campaign_snapshot` histórico al proposal Game-Ready;
- auto-heal o reset automático de HP/PP;
- reemplazo silencioso de Pokémon KO;
- permadeath;
- modificar search/proposal/brain/tie resolver;
- tocar Battle Core;
- reabrir scheduler/shared-budget/660;
- abrir FASE34;
- mergear PR #105 o PR #107.

## Criterio de salida P1-C

P1-C no se cierra por mera compilación. Debe demostrar mediante tests ejecutables al menos:

- creación/configuración válida del owner;
- roster conserva identidad exacta;
- duplicados/ownership inválido fallan cerrado;
- conexión de integración entrega al battle session las mismas referencias;
- settlement/reconciliation no introduce auto-heal;
- recovery/replacement explícitos no contaminan Battle Core;
- regresión completa verde.

Después de certificar P1-C, **P1-D** será el único tramo restante para rematch/cross-session E2E, regresión global y freeze final.

## Invariantes externas

- PR #105 permanece OPEN / unmerged.
- PR #106 permanece CLOSED / not merged.
- PR #107 permanece OPEN / DRAFT / unmerged.
- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- P1-C parte del HEAD documental certificado de P1-B, no de `main`.
