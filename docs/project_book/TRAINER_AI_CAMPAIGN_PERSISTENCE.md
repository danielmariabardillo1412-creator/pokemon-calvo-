# Trainer AI — Campaign Persistence V1

## P1.0 — apertura audit-first

Estado: **OPEN / AUDIT-FIRST / NUEVA FEATURE**.

Parent exacto certificado:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Ese parent corresponde al freeze final de **Trainer AI Expertise V1 — CLOSED / CERTIFIED / FROZEN**.

Rama:

`feature/trainer-ai-campaign-persistence-v1`

Esta feature no reabre C3f, Game-Ready 27.x ni Expertise V1. El sistema de combate Trainer AI continúa cerrado y certificado. El nuevo objetivo es distinto: definir qué estado de un entrenador rival sobrevive entre combates y quién lo posee.

## Distinción canónica

No confundir:

- **estado de batalla**: HP/PP/status/active/turn y forced replacement mientras Battle Core está activo;
- **roster owned por el caller**: `CreatureInstance` que existe fuera de `TrainerBattleSession` y puede reutilizarse;
- **persistencia de campaña**: identidad/roster/configuración y resultado que sobreviven de forma deliberada entre encuentros;
- **recovery policy**: reglas explícitas para curar/restaurar entre encuentros;
- **replacement policy**: reglas explícitas para sustituir miembros fuera de una batalla terminada;
- **forced replacement de Battle Core**: cambio obligatorio durante una batalla; no es campaign replacement.

Campaign/recovery/replacement nunca puede convertirse en un fallback oculto para decidir una acción de combate.

## Evidencia de apertura

Sobre el parent Expertise V1:

1. `TrainerBattleSession.begin_battle(...)` recibe un `Array[CreatureInstance]` externo.
2. `_roster_with_living_active(...)` reordena referencias existentes; no clona criaturas.
3. `BattleState` y `_opponent_roster` trabajan sobre esas mismas instancias durante la batalla.
4. `settle_finished_battle()` reconcilia `_opponent_roster` y después limpia la referencia de sesión.
5. `reset_after_completion()` limpia identidad de oponente y configuración runtime de expertise/profile.
6. `technical_overworld.gd` posee `_trainer_roster` fuera de la sesión.
7. La vertical slice marca `_trainer_demo_completed = true` al cerrar el combate y bloquea cualquier nueva batalla contra ese entrenador demo.
8. Los reports de sustitución mantienen `campaign_policy_used=false`, `recovery_policy_used=false` y `replacement_policy_used=false`.
9. No existe una feature certificada que defina recuperación/reemplazo persistente ni un lifecycle de revancha.

Conclusión de apertura: **ya existe un seam útil de ownership por referencia, pero no existe todavía un contrato deliberado de persistencia de campaña.** No hay que inventar un segundo modelo de criaturas ni copiar el roster por defecto; primero hay que fijar qué debe sobrevivir y qué debe resetearse.

## Plan fijo inicial — 4 tramos

1. **P1-A — ownership/persistence boundary audit** — ACTUAL / TEST-AUDIT-ONLY.
2. **P1-B — contrato de estado persistente + recovery/replacement** — PENDIENTE / CONTRACT-FIRST.
3. **P1-C — integración productiva mínima del owner persistente** — PENDIENTE.
4. **P1-D — rematch/cross-session E2E + regresión + freeze** — PENDIENTE.

No añadir una quinta tranche por inercia. Si P1-A o P1-B descubre un blocker real que invalide este plan, debe documentarse antes de ampliarlo.

## P1-A — ownership/persistence boundary audit

Scope: **TEST/AUDIT-ONLY**.

Suite:

`TrainerCampaignPersistenceBoundaryAuditTestSuite`

Audit ID:

`p1_a_campaign_persistence_ownership_boundary_audit_v1`

Resultado objetivo:

`CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`

P1-A debe demostrar de forma ejecutable/source-trace:

- qué objeto posee realmente el roster durante la batalla;
- si BattleState y sesión comparten identidad de `CreatureInstance`;
- si settlement reconcilia y luego libera el roster de la sesión;
- que el Overworld técnico ya actúa como owner externo del roster;
- que la vertical slice actual es one-shot y no ejerce rematch;
- que campaign/recovery/replacement siguen fuera de la decisión de combate;
- que no se modifica producción ni Battle Core.

P1-A **no** autoriza:

- curación automática;
- regeneración completa por defecto;
- reemplazar Pokémon KO fuera de batalla;
- crear permadeath;
- persistir todo el `BattleState`;
- modificar Battle Core;
- cambiar proposal/search/brain;
- reabrir scheduler/shared budget/660;
- abrir FASE34;
- mergear PR #105.

## Invariantes externas

- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #105 permanece OPEN / unmerged.
- El parent de esta feature es el freeze Expertise V1 `f43dc6b...`, no `main`.
- El PR de esta feature deberá cerrarse sin merge tras su freeze, siguiendo la cadena de snapshots certificados.
