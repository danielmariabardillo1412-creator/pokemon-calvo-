# SIGUIENTE TRABAJO

## Workstream activo — Trainer AI Campaign Persistence V1

Rama:

`feature/trainer-ai-campaign-persistence-v1`

PR #107: **OPEN / DRAFT / NOT MERGED**.

## Plan fijo — solo queda P1-D

1. P1-A ownership/persistence boundary audit — **CLOSED / CERTIFIED**.
2. P1-B persistent-state + recovery/replacement contract — **CLOSED / CERTIFIED**.
3. P1-C minimal production integration — **CLOSED / CERTIFIED**.
4. **P1-D rematch/cross-battle E2E + regression + freeze — NEXT / FINAL**.

No añadir una quinta tranche por inercia.

## P1-C — evidencia cerrada

Checkpoint técnico exacto:

`311349938af6c57f4507e2160e157cffbc124afb`

- P1-C: **34/34 PASS**;
- P1-A forward-compatible: **23/23 PASS**;
- Evaluation: **582 PASS / 0 FAIL**;
- Godot 4.7: **SUCCESS**;
- Team Composition: **SUCCESS**;
- full CI: **18/18 workflows SUCCESS**.

Owner productivo:

`TrainerCampaignRosterOwner`

Garantías:

- misma identidad de `CreatureInstance`;
- handoff copia solo el contenedor;
- ownership/IDs fail-closed;
- configuración y replacement atómicos;
- sin auto-heal;
- recovery full explícito;
- campaign replacement separado de forced replacement;
- Overworld ya usa el owner dedicado;
- Save V2/Battle Core/combat AI intactos.

El primer run P1-C `d3238725...` fue 578/4 porque cuatro asserts históricos P1-A exigían la ausencia del owner que P1-C acababa de introducir. P1-C estaba 34/34. La auditoría histórica se hizo forward-compatible sin perder checks; `311349...` quedó 582/0.

## Gate antes de P1-D

El HEAD documental que registra este cierre P1-C debe pasar **18/18 workflows SUCCESS**. Solo ese HEAD puede ser parent certificado de P1-D.

## P1-D — trabajo autorizado después del gate documental

Objetivo final:

1. Retirar el bloqueo one-shot del entrenador técnico para permitir un segundo encuentro.
2. Mantener **cero auto-recovery** al cerrar batalla.
3. Probar que el primer combate usa exactamente la criatura owned por campaign.
4. Terminar el primer combate por la ruta real y comprobar que settlement conserva el estado persistente sobre la misma instancia.
5. Comprobar que, tras quedar KO, el rival no puede iniciar una revancha inmediata.
6. Ejecutar recovery explícito fuera de batalla.
7. Comprobar que recovery conserva exactamente la misma instancia y restaura el estado previsto.
8. Abrir un segundo combate real con esa misma instancia.
9. Ejecutar/cerrar el segundo encuentro por Overworld -> Presentation -> TrainerBattleSession -> Battle Core.
10. Mantener Save V2, BattleState persistence, search/proposal/brain/tie resolver, FASE34 y scheduler/shared-budget/660 fuera de scope.
11. Full regression final verde.
12. Freeze documental final y cierre de PR #107 **sin merge**.

### Criterio de verdad

No vale hacer que el rival se cure al cerrar el primer combate para que el segundo pase. El E2E debe demostrar esta secuencia:

`KO persistente -> rematch bloqueado -> recovery explícito -> rematch permitido`

La criatura antes y después debe ser la **misma `CreatureInstance`**.

## Invariantes

- `main` = `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #105 OPEN / unmerged.
- PR #106 CLOSED / not merged.
- PR #107 OPEN / DRAFT / unmerged hasta freeze.
