# SIGUIENTE TRABAJO

## Workstream activo — Trainer AI Campaign Persistence V1

Rama:

`feature/trainer-ai-campaign-persistence-v1`

Parent certificado de entrada:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Ese parent es el freeze final de **Trainer AI Expertise V1**.

## Plan fijo inicial — 1/4 actual

1. **P1-A — ownership/persistence boundary audit** — ACTUAL / TEST-AUDIT-ONLY.
2. **P1-B — contrato persistente + recovery/replacement** — PENDIENTE.
3. **P1-C — integración productiva mínima** — PENDIENTE.
4. **P1-D — rematch/cross-session E2E + freeze** — PENDIENTE.

No añadir una quinta tranche por inercia.

## P1-A — frontera exacta a certificar

Suite:

`TrainerCampaignPersistenceBoundaryAuditTestSuite`

Audit ID:

`p1_a_campaign_persistence_ownership_boundary_audit_v1`

Resultado objetivo:

`CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`

Debe certificar:

- `TrainerBattleSession` recibe roster rival owned externamente;
- el filtro de living roster conserva referencias de `CreatureInstance`, no clona criaturas;
- BattleState y roster de sesión comparten identidad durante la batalla;
- settlement reconcilia el roster y después la sesión libera su referencia;
- reset limpia la identidad runtime del oponente;
- `technical_overworld.gd` ya posee el roster fuera de la sesión;
- la vertical slice actual bloquea rematch tras completar el combate;
- no existe un owner/policy dedicado de campaign/recovery/replacement en las superficies esperadas;
- proposal/substitution sigue declarando esas policies como no usadas;
- producción y Battle Core permanecen en **0 cambios**.

## Barreras

P1-A no autoriza:

- curar automáticamente al entrenador;
- resetear HP/PP por intuición;
- reemplazar miembros KO fuera de batalla;
- permadeath;
- persistir `BattleState` completo;
- usar campaign/recovery/replacement para decidir una acción;
- modificar search/proposal/brain;
- tocar Battle Core;
- reabrir scheduler/shared budget/660;
- abrir FASE34;
- mergear PR #105.

## Invariantes externas

- PR #105 permanece OPEN / unmerged.
- PR #106 permanece CLOSED / not merged.
- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- El siguiente tramo debe partir del HEAD certificado de P1-A, no de `main`.
