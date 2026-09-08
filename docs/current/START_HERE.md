# EMPEZAR AQUÍ

Este archivo es el punto de entrada para recuperar el proyecto en una conversación, agente o sesión nueva.

## Lectura mínima

1. `PROJECT_STATE.md`
2. `NEXT_STEPS.md`
3. `WORK_PROTOCOL.md`
4. `docs/project_book/GAME_FOUNDATION.md` mientras GF1 esté activo.

## Autoridad

Si dos fuentes se contradicen:

1. GitHub/CI del SHA exacto;
2. fuente canónica/inmutable del dominio;
3. `docs/current/`;
4. arquitectura/ADR;
5. cuadernos;
6. historial;
7. memoria del chat.

## Baseline canónico

La consolidación de la antigua cadena de snapshots terminó el 2026-09-08.

`main = d2ad6796a93e6db56ef24c98431a3909e3874cdf`

Ese SHA pasó **18/18 workflows SUCCESS** y vuelve a ser el baseline normal del repositorio.

No usar ya la regla histórica “main no es autoridad”.

## Workstream activo

**Game Foundation V1 — GF1-A**

Rama:

`feature/game-foundation-v1`

Objetivo final GF1:

`nueva partida -> inicial -> pueblo/mapa -> ruta -> encuentro/captura -> entrenador -> servicio -> save/load -> continuar`

GF1-A introduce `GameCampaignState` como autoridad separada para identidad/progreso de campaña. Save V2 permanece sin cambios hasta GF1-D.

La nueva matriz de GF1 contiene **19 workflows**, al añadirse `Game Foundation Tests`. GF1-A no se considera certificado hasta que los 19 estén SUCCESS sobre el mismo HEAD exacto.

## Sistemas congelados

- DATA V3 — CLOSED / CERTIFIED;
- Trainer AI runtime 26.67 — CLOSED;
- Game-Ready 27.1 — CLOSED;
- Expertise V1 — CLOSED / FROZEN;
- Campaign Persistence V1 — CLOSED / FROZEN;
- no existe P1-E.

## PR externos

- #105 OPEN / unmerged;
- #106 CLOSED / not merged;
- #107 CLOSED / not merged;
- #108 cerró la consolidación de `main` en el mismo SHA `d2ad6796...`.

## Regla de memoria

Toda decisión material debe quedar en GitHub + `docs/current/`, cuaderno, ADR o historial; nunca depender solo del chat.
