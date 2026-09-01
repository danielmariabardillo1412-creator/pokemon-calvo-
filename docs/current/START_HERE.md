# EMPEZAR AQUÍ

Este archivo es el punto de entrada para recuperar el proyecto en una conversación, agente o sesión nueva.

## Lectura mínima

1. `PROJECT_STATE.md` — qué baseline está certificado y qué existe realmente.
2. `NEXT_STEPS.md` — qué trabajo toca exactamente ahora.
3. `WORK_PROTOCOL.md` — cómo trabajar sin romper la cadena de certificación.
4. El cuaderno temático correspondiente en `../project_book/`.

No es necesario leer todos los ADR ni todo el historial antes de continuar.

## Autoridad

Si dos documentos parecen contradecirse, resolver en este orden:

1. commit/branch/PR/CI/artefactos del SHA exacto en GitHub;
2. fuente canónica o inmutable del dominio;
3. documentos de `docs/current/`;
4. arquitectura y ADR vigentes;
5. cuadernos temáticos;
6. historial y worklogs;
7. memoria de conversación.

## Baseline de continuidad

El último baseline funcional certificado anterior a la reorganización documental es:

`b4f6adc200bef18f8ac51b9144f2f9a838f464fd`

Corresponde al cierre final de DATA V3 en PR #95, cerrado sin merge tras 18/18 workflows SUCCESS.

La reorganización documental se desarrolla desde ese SHA en:

`chore/documentation-consolidation-v1`

## Regla sobre `main`

`main` es actualmente una rama histórica antigua. No iniciar trabajo desde ella ni usarla para inferir el estado moderno del proyecto.

La futura sustitución de `main` por el baseline certificado se hará **después** de organizar y certificar esta estructura, como una operación separada y verificable.

## Regla de memoria del proyecto

Las decisiones materiales no deben existir únicamente en el chat.

- estado y continuación: `docs/current/`;
- conocimiento de un workstream: `docs/project_book/`;
- decisión arquitectónica formal: `docs/adr/`;
- diarios y trazabilidad cerrada: `docs/history/worklogs/`.

No crear un cuaderno nuevo por cada microcambio. Actualizar el cuaderno temático correspondiente.
