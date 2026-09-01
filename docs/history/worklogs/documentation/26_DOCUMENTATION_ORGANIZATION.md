# CUADERNO 26 — REORGANIZACIÓN DOCUMENTAL

Estado: **MIGRACIÓN EJECUTADA / PENDIENTE DE CERTIFICACIÓN CI**

## Objetivo

Reorganizar la documentación del proyecto antes de retomar la expansión de la IA de entrenadores, reduciendo ruido y duplicación sin perder trazabilidad histórica ni modificar lógica del juego.

## Baseline de partida

- Baseline certificado: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- Origen: cierre DATA V3, PR #95, cerrado sin merge.
- Rama: `chore/documentation-consolidation-v1`
- Regla: `main` no es autoridad actual y no se sustituye en esta operación.

## Descubrimientos

### 1. Exceso de notebooks activos

`docs/notebooks/` contenía 26 documentos 00–25 antes de iniciar esta reorganización.

De ellos, 20 eran diarios/auditorías específicos de DATA V3: notebook 02 y notebooks 06–25. DATA V3 ya estaba cerrado, de modo que estos archivos eran valiosos como trazabilidad pero no como memoria activa.

### 2. Estado vivo contradictorio

Se detectaron varios documentos operativos desactualizados:

- `00_READ_FIRST.md` todavía presentaba Move Effects V3 como workstream activo;
- `01_PROJECT_STATE.md` y `04_NEXT_STEPS.md` todavía describían el cierre final de #95 como pendiente;
- `05_DEFERRED_WORK_AND_ROADMAP.md` todavía marcaba DATA V3 como prioridad;
- `docs/STATUS.md` y el `README.md` raíz anunciaban el antiguo baseline `304035e2...` / `feature/data-foundation-v3` en vez del cierre real `b4f6adc2...`.

El problema no era solo cantidad de archivos, sino varias fuentes que podían parecer simultáneamente “actuales”.

### 3. Research y cuadernos eran conceptos parcialmente solapados

`docs/history/research/TRAINER_AI_RESEARCH_FASE21.md` contiene decisiones que siguen siendo relevantes para Trainer AI aunque la investigación FASE21 esté cerrada. Se decidió conservar la fuente histórica e integrar sus conclusiones vigentes en el cuaderno temático Trainer AI.

### 4. FASE34 no debe duplicar perfiles existentes

Durante la consolidación se verificó que `TrainerProfile` ya define `balanced`, `aggressive`, `cautious` y `technical`, y explícitamente establece que dificultad no puede conceder información oculta.

La continuación de Trainer AI deberá separar **estilo** de **competencia/expertise**, no crear otra capa genérica de personalidad que duplique FASE21.

## Estructura decidida

La estructura operativa final queda:

- `docs/current/` — única fuente documental de estado vivo;
- `docs/project_book/` — pocos cuadernos temáticos consolidados;
- `docs/architecture/` — arquitectura y rulesets vigentes;
- `docs/adr/` — decisiones arquitectónicas numeradas;
- `docs/reference/` — entorno y procedencia técnica;
- `docs/history/` — material cerrado, research, informes y worklogs.

## Política final de cuadernos

Se redujo deliberadamente la propuesta inicial.

No se crean cuadernos vacíos para Battle, UI, Overworld o ingeniería general “por si acaso”. Solo existen actualmente:

- `docs/project_book/DATA_V3.md` — **CERRADO**;
- `docs/project_book/TRAINER_AI.md` — **ACTIVO / siguiente workstream**.

`docs/project_book/README.md` define la política: abrir un nuevo cuaderno solo cuando un workstream grande y distinto realmente necesite memoria propia.

## Migración ejecutada

Commit estructural:

`002b8b4ef275cc239ada9c540f0fc84351b0ea44`

### Estado vivo

Se crearon:

- `docs/current/START_HERE.md`
- `docs/current/PROJECT_STATE.md`
- `docs/current/NEXT_STEPS.md`
- `docs/current/WORK_PROTOCOL.md`

### Cuadernos consolidados

Se crearon:

- `docs/project_book/README.md`
- `docs/project_book/DATA_V3.md`
- `docs/project_book/TRAINER_AI.md`

### DATA V3 archivado sin reescritura

Los 20 diarios DATA V3 originales se movieron a:

`docs/history/worklogs/data_v3/`

Los movimientos son renames de **0 adiciones / 0 eliminaciones**: el contenido histórico permanece byte-identical.

### Documentos operativos antiguos

Los antiguos notebooks 00, 01, 03, 04 y 05, junto al antiguo `docs/STATUS.md`, se preservaron en:

`docs/history/worklogs/pre_consolidation/`

No son autoridad actual.

### Arquitectura y referencia

Los documentos formales que estaban sueltos en `docs/` se movieron a `docs/architecture/` sin modificar contenido.

`DEVELOPMENT_ENVIRONMENT.md` y `THIRD_PARTY_CODE.md` pasaron a `docs/reference/`.

Los ADR permanecen en `docs/adr/` sin cambios.

La investigación histórica permanece en `docs/history/research/`.

### `docs/notebooks/`

Deja de existir como superficie activa. El propio cuaderno 26 se conserva bajo:

`docs/history/worklogs/documentation/26_DOCUMENTATION_ORGANIZATION.md`.

## Verificación del diff

Comparación:

- base: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- engineering de reorganización: `002b8b4ef275cc239ada9c540f0fc84351b0ea44`

Resultado:

- ahead_by: 2 commits (creación inicial del cuaderno 26 + migración);
- cambios exclusivamente en `README.md` y `docs/**`;
- **0 archivos de código modificados**;
- **0 tests modificados**;
- **0 workflows modificados**;
- **0 datos canónicos modificados**;
- los movimientos de arquitectura, reference y worklogs preservan los blobs originales.

## Reglas de seguridad preservadas

- no se modifica runtime;
- no se modifica DATA V3;
- no se modifica Battle Core;
- no se reescribe la historia para aparentar otra decisión;
- GitHub/CI/artefactos siguen por encima de cualquier resumen;
- `main` se mantiene intacta hasta una operación posterior.

## Criterio de cierre

La reorganización quedará certificada cuando:

1. se abra PR contra el snapshot #95 inmediatamente anterior;
2. se ejecute la matriz normal sobre el HEAD documental final;
3. todos los workflows queden verdes;
4. se actualicen `docs/current/PROJECT_STATE.md`, `docs/current/NEXT_STEPS.md` y este worklog con la certificación exacta;
5. ese HEAD final vuelva a quedar completamente verde si la actualización mueve el SHA;
6. se cierre el PR sin merge.

## Siguiente workstream después del cierre

Trainer AI.

Primera tarea: auditar la arquitectura/prototipos de difficulty/archetype/expertise y diseñar una capa de competencia separada de `TrainerProfile`, construida sobre `StrategicSwitchingTrainerBrain`, loadouts y composición de equipos, sin cheating y sin ampliar search/MCTS sin evidencia.
