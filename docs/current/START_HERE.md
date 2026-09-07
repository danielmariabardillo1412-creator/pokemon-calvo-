# EMPEZAR AQUÍ

Este archivo es el punto de entrada para recuperar el proyecto en una conversación, agente o sesión nueva.

## Lectura mínima

1. `PROJECT_STATE.md` — baseline certificado y estado real.
2. `NEXT_STEPS.md` — trabajo autorizado ahora.
3. `WORK_PROTOCOL.md` — reglas de ejecución/certificación.
4. El cuaderno temático activo en `../project_book/`.

## Autoridad

Si dos fuentes se contradicen:

1. commit/branch/PR/CI/artefactos del SHA exacto en GitHub;
2. fuente canónica o inmutable del dominio;
3. `docs/current/`;
4. arquitectura y ADR vigentes;
5. cuadernos temáticos;
6. historial/worklogs;
7. memoria del chat.

## Baseline moderno de continuidad

Último baseline funcional certificado antes del workstream actual:

`337a4f787c7da18f9cf649aea929e79912840b2a`

Corresponde a:

`docs(trainer-ai): freeze 27.1 game-ready hardening`

Trainer AI de combate queda **CLOSED / VALIDATED** en ese SHA.

Rama del nuevo workstream:

`feature/trainer-ai-expertise-v1`

El nuevo trabajo es una feature separada: **Trainer AI Expertise V1**. No reabre C3f ni Game-Ready 27.x.

## Invariantes externos

- `main` sigue siendo histórica y debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197` mientras este workstream no autorice otra cosa.
- PR #105 permanece OPEN / unmerged y no debe mergearse casualmente.
- El siguiente tramo parte del último SHA certificado exacto, no de `main` por nombre.

## Regla de memoria

Las decisiones materiales no deben vivir solo en el chat:

- estado y continuación: `docs/current/`;
- conocimiento de workstream: `docs/project_book/`;
- decisión arquitectónica duradera: `docs/adr/`;
- evidencia histórica cerrada: `docs/history/worklogs/`.
