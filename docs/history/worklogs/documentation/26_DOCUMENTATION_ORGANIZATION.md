# CUADERNO 26 — REORGANIZACIÓN DOCUMENTAL

Estado: EN CURSO

## Objetivo

Reorganizar la documentación del proyecto antes de retomar la expansión de la IA de entrenadores.

La reorganización debe reducir ruido, duplicación y ambigüedad sin perder trazabilidad histórica ni modificar lógica del juego.

## Baseline de partida

- Baseline certificado: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- Origen: cierre DATA V3, PR #95, cerrado sin merge.
- Rama de trabajo: `chore/documentation-consolidation-v1`
- Regla: no usar `main` como autoridad durante esta reorganización.

## Descubrimiento inicial

`docs/notebooks/` contiene 26 documentos (00–25). De ellos, 20 son diarios/auditorías específicos de DATA V3. Son útiles como trazabilidad, pero no deben seguir presentándose como cuadernos activos una vez cerrado DATA V3.

También existen:

- `docs/history/phase_reports/` para informes de fases cerradas;
- `docs/history/legacy_data/` para DATA V1/V2 y material superado;
- `docs/history/research/` para investigación técnica preservada;
- `docs/adr/` para decisiones arquitectónicas formales;
- documentos de arquitectura y reglas todavía mezclados directamente bajo `docs/`.

Se detectó además que algunos cuadernos vivos quedaron cronológicamente desactualizados tras la certificación final de DATA V3. Por ejemplo, `00_READ_FIRST.md`, `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md` y `05_DEFERRED_WORK_AND_ROADMAP.md` todavía contienen referencias a DATA V3 como trabajo activo o pendiente.

## Decisión de organización

La documentación operativa se reorganizará en cinco capas conceptuales:

1. `docs/current/` — estado vivo, protocolo y próximo paso.
2. `docs/project_book/` — pocos cuadernos temáticos consolidados y mantenidos.
3. `docs/architecture/` — arquitectura y rulesets vigentes.
4. `docs/adr/` — decisiones arquitectónicas numeradas; se conserva su función actual.
5. `docs/history/` — diarios de trabajo, investigación cerrada, informes y material superado.

## Política de cuadernos

No se mantendrá un cuaderno nuevo por cada microtramo.

Los cuadernos activos serán temáticos y acumulativos. Como mínimo se prevén:

- `PROJECT_BOOK.md` o índice equivalente: guía de uso de los cuadernos;
- `TRAINER_AI.md`: estado, arquitectura práctica, decisiones, límites, investigación útil y continuación de IA;
- `DATA_V3.md`: resumen consolidado del DATA V3 cerrado y su autoridad certificada;
- `BATTLE_AND_GAME_SYSTEMS.md`: notas operativas relevantes del Battle Core y sistemas de juego cuando proceda;
- `GENERAL_ENGINEERING.md`: decisiones de trabajo que no pertenecen a un dominio concreto.

El número final podrá reducirse si dos cuadernos resultan artificialmente separados.

## Política de archivo

Los diarios DATA V3 02 y 06–25 no se borrarán. Se moverán como registros históricos de trabajo a un área de archivo de DATA V3.

El nuevo cuaderno consolidado DATA V3 será la referencia humana habitual; los diarios originales quedarán disponibles cuando sea necesario auditar una decisión concreta.

La investigación técnica cerrada, como `TRAINER_AI_RESEARCH_FASE21.md`, se preservará y sus conclusiones todavía vigentes se integrarán en el cuaderno temático correspondiente sin destruir la fuente histórica.

## Reglas de seguridad de esta reorganización

- No modificar código, datos canónicos, tests ni semántica runtime.
- No borrar información histórica material.
- No reescribir retrospectivamente decisiones técnicas para hacerlas parecer distintas.
- Actualizar enlaces/rutas documentales que queden rotos por movimientos.
- Mantener GitHub/CI/commits/PRs como autoridad por encima de cualquier resumen documental.
- El resultado debe permitir que un nuevo contexto recupere el proyecto leyendo pocos documentos.

## Criterio de éxito

Una persona o una IA nueva debe poder recuperar el estado del proyecto siguiendo un recorrido corto:

1. índice de documentación;
2. estado actual;
3. siguiente trabajo;
4. cuaderno temático relevante;
5. arquitectura/ADR solo cuando necesite detalle.

No debería ser necesario leer veinte diarios DATA V3 para continuar con Trainer AI.

## Próximo paso

Completar el inventario de documentos, clasificar cada archivo como ACTUAL / CUADERNO / ARQUITECTURA / ADR / HISTÓRICO y ejecutar la migración con cambios exclusivamente documentales.
