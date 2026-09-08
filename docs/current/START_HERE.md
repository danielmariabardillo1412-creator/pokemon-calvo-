# EMPEZAR AQUÍ

Este archivo es el punto de entrada para recuperar el proyecto en una conversación, agente o sesión nueva.

## Lectura mínima

1. `PROJECT_STATE.md` — baseline certificado y estado real.
2. `NEXT_STEPS.md` — trabajo autorizado ahora.
3. `WORK_PROTOCOL.md` — reglas de ejecución/certificación.
4. El cuaderno temático del workstream que esté activo.

## Autoridad

Si dos fuentes se contradicen:

1. commit/branch/PR/CI del SHA exacto en GitHub;
2. fuente canónica/inmutable del dominio;
3. `docs/current/`;
4. arquitectura/ADR vigentes;
5. cuadernos temáticos;
6. historial/worklogs;
7. memoria del chat.

## Línea moderna certificada

Freeze moderno de entrada a la consolidación de `main`:

`8552f52158ffc21c27b4e8f1dbc7caa63ac1a467`

Ese SHA pasó **18/18 workflows SUCCESS**.

Trainer AI está cerrado en sus sistemas obligatorios actuales:

- runtime system 26.67 — CLOSED / COMPLETED;
- Game-Ready 27.1 — CLOSED / VALIDATED;
- Expertise V1 — CLOSED / CERTIFIED / FROZEN;
- Campaign Persistence V1 — CLOSED / CERTIFIED / FROZEN.

No existe P1-E.

## Operación actual — consolidación de `main`

Rama:

`chore/main-baseline-consolidation-v1`

Antigua `main`:

`641d4b1fb0bcf964205d616e96f198f05d702197`

Merge histórico inicial:

`2f63312e8dc3e61c8fadbd02e97972fff6d0eacc`

El único cambio exclusivo de la antigua `main` era un archivo vacío `this_should_not_be_called`; el merge inicial conserva la historia de esa rama como parent, pero usa exactamente el tree moderno certificado `89835a6797989a8ef027b6b17baea206b1f97f74`.

Regla de promoción:

- no tocar `main` hasta que el HEAD final de la rama de consolidación pase la matriz normal completa;
- después, promocionar ese SHA exacto por fast-forward;
- no generar después un merge SHA distinto sin certificar.

## Estado del juego

La base técnica incluye Battle Core, DATA V3, criaturas/progresión, captura, party/storage, inventario, Save V2, encuentros/overworld técnico y Trainer AI.

El ejecutable visible sigue siendo una vertical slice técnica. El siguiente objetivo no es ampliar Trainer AI: es construir **Game Foundation V1** para obtener una mini-campaña real jugable.

## Próximo workstream — Game Foundation V1

Objetivo resumido:

`nueva partida -> inicial -> pueblo/mapa -> ruta -> encuentro/captura -> entrenador -> servicio -> save/load -> continuar`

Orden previsto:

- GF1-A Game State + campaña;
- GF1-B mapas/transiciones;
- GF1-C NPC/diálogo/eventos;
- GF1-D Save V3 mundo/campaña;
- GF1-E servicios/UI mínima;
- GF1-F vertical slice E2E.

No iniciar GF1 hasta cerrar la consolidación de `main`.

## Invariantes externas

- PR #105 permanece OPEN / unmerged;
- PR #106 CLOSED / not merged;
- PR #107 CLOSED / not merged;
- DATA V3 y Trainer AI no se reabren salvo regresión real o feature nueva explícita.

## Regla de memoria

Las decisiones materiales deben quedar en `docs/current/`, cuaderno temático, ADR o worklog; nunca solo en chat.
