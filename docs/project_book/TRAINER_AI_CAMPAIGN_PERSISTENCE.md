# Trainer AI — Campaign Persistence V1

## P1.0 — apertura audit-first

Estado: **OPEN / P1-A CERTIFIED / P1-B NEXT**.

Parent exacto certificado:

`f43dc6b158c35fe25139de5524b83f6fe2d3426f`

Ese parent corresponde al freeze final de **Trainer AI Expertise V1 — CLOSED / CERTIFIED / FROZEN**.

Rama:

`feature/trainer-ai-campaign-persistence-v1`

PR:

`#107 — OPEN / DRAFT / NOT MERGED`

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

### `campaign_snapshot` histórico

Existe transporte histórico de `campaign_snapshot` en `TrainerIntelligenceController`/`TrainerDecisionContext`, con copia profunda del DTO. Ese transporte **no es el owner persistente de campaña** y no puede convertirse en source of truth.

Además, el path autónomo Game-Ready actual de `TrainerItemAwareActionProposal` crea su `TrainerDecisionContext` sin conectar ese snapshot. P1-A fija esta diferencia para evitar fusionar accidentalmente dos responsabilidades distintas.

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

## Plan fijo — 4 tramos

1. **P1-A — ownership/persistence boundary audit** — **CLOSED / CERTIFIED / TEST-AUDIT-ONLY**.
2. **P1-B — contrato de estado persistente + recovery/replacement** — **NEXT / CONTRACT-FIRST**.
3. **P1-C — integración productiva mínima del owner persistente** — PENDIENTE.
4. **P1-D — rematch/cross-session E2E + regresión + freeze** — PENDIENTE.

No añadir una quinta tranche por inercia. Si P1-B descubre un blocker real que invalide este plan, debe documentarse antes de ampliarlo.

## P1-A — CLOSED / CERTIFIED

Scope: **TEST/AUDIT-ONLY**.

Suite:

`TrainerCampaignPersistenceBoundaryAuditTestSuite`

Audit ID:

`p1_a_campaign_persistence_ownership_boundary_audit_v1`

Resultado certificado:

`CAMPAIGN_PERSISTENCE_OWNERSHIP_SEAM_LOCALIZED`

Checkpoint técnico exacto:

`26c11caa635cecb851b95cd636580cb250683a32`

### Evidencia ejecutable

- P1-A: **23/23 PASS**.
- Trainer Evaluation Corpus: **521 PASS / 0 FAIL**.
- Workflow Team Composition: **SUCCESS**.
- Full CI del checkpoint técnico: **18/18 workflows SUCCESS**, 0 failures/cancellations observados.
- El conteo agregado literal interno de Team Composition no fue expuesto por la extracción del conector para este job; por rigor, no se reutiliza ni se infiere el `1258/0` de checkpoints anteriores.
- Diff contra el freeze Expertise V1: **6 archivos**, todos docs/tests; **0 producción / 0 Battle Core**.

### Ownership seam certificado

P1-A demuestra que:

- `TrainerBattleSession` recibe roster rival owned externamente;
- BattleState y roster de sesión comparten la misma identidad de `CreatureInstance`;
- mutaciones runtime sobre esas criaturas son visibles desde el roster owned por el caller;
- `_roster_with_living_active(...)` conserva referencias y solo reordena;
- settlement reconcilia las criaturas y luego la sesión libera su roster interno;
- reset elimina identidad/configuración runtime del oponente;
- `technical_overworld.gd` ya actúa como owner externo de `_trainer_roster`;
- la vertical slice actual sigue siendo one-shot y no ejerce revancha;
- existe transporte histórico deep-detached de `campaign_snapshot`, pero el proposal Game-Ready actual no lo usa;
- no existe un owner/policy dedicado de campaign/recovery/replacement en las superficies esperadas;
- campaign/recovery/replacement continúan fuera de proposal/search/tie resolution;
- no se tocó producción ni Battle Core.

### Conclusión P1-A

La frontera correcta queda localizada: **Battle Core/TrainerBattleSession consumen temporalmente las mismas `CreatureInstance`, pero el lifecycle persistente debe pertenecer a un owner exterior estable**. No hay justificación para persistir `BattleState`, clonar el roster o introducir curación implícita.

## P1-B — NEXT / CONTRACT-FIRST

P1-B debe fijar mediante tests/audits el contrato del futuro owner antes de escribir producción.

Contrato de partida:

1. El owner persistente vive fuera de `BattleState` y `TrainerBattleSession`.
2. Conserva la identidad exacta de cada `CreatureInstance`; no crea copias de identidad.
3. La transición post-battle por defecto es `reconcile_post_battle()`; **no existe auto-heal**.
4. HP, PP y persistent status sobreviven conforme al contrato actual de `CreatureInstance`; el estado transitorio/volatile de batalla se limpia.
5. Recovery es una acción/policy inter-battle explícita, no una consecuencia silenciosa de settlement.
6. Campaign replacement es una operación fuera de batalla y distinta del forced replacement de Battle Core.
7. IDs duplicados/double ownership deben fallar cerrado; no se corrigen silenciosamente.
8. No se persiste el `BattleState` completo.
9. `campaign_snapshot` histórico, si llega a proyectarse, solo puede ser DTO sanitizado/detached; nunca owner autoritativo.
10. P1-B no conecta `campaign_snapshot` al proposal Game-Ready.

P1-B no autoriza modificar Save V2, search, proposal, tie resolver, FASE34, scheduler/shared-budget/660 ni Battle Core. La implementación productiva del owner queda reservada para P1-C.

## Invariantes externas

- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- PR #105 permanece OPEN / unmerged.
- PR #106 permanece CLOSED / not merged.
- PR #107 permanece OPEN / DRAFT / unmerged durante el workstream.
- El parent de esta feature es el freeze Expertise V1 `f43dc6b...`, no `main`.
- El PR de esta feature deberá cerrarse sin merge tras su freeze, siguiendo la cadena de snapshots certificados.
