# CUADERNO 26 — REORGANIZACIÓN DOCUMENTAL

Estado: **FINAL DOC SYNC / PENDIENTE DE SEGUNDO 18/18**

## Objetivo

Reorganizar la documentación antes de retomar Trainer AI, reduciendo ruido, duplicación y fuentes contradictorias sin modificar lógica, datos canónicos, tests ni workflows.

## Baseline

- parent certificado: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- origen: PR #95 DATA V3, cerrado sin merge
- rama: `chore/documentation-consolidation-v1`
- PR: #96 `Docs — consolidar estado vivo, cuadernos e historial`
- `main`: fuera de alcance; permanece histórica e intacta.

## Descubrimiento inicial

`docs/notebooks/` contenía 26 documentos 00–25. Veinte eran diarios DATA V3 (02 y 06–25). Eran valiosos como trazabilidad pero ya no debían presentarse como memoria activa tras el cierre de DATA V3.

También coexistían varias fuentes supuestamente actuales con estados distintos:

- `00_READ_FIRST.md`: Move Effects V3 todavía activo;
- `01_PROJECT_STATE.md` y `04_NEXT_STEPS.md`: cierre #95 todavía pendiente;
- `05_DEFERRED_WORK_AND_ROADMAP.md`: DATA V3 aún prioridad;
- antiguo `docs/STATUS.md` y `README.md`: baseline `304035e2...` / `feature/data-foundation-v3` en vez de `b4f6adc2...`.

## Decisión estructural

La documentación queda separada por función:

- `docs/current/` — única superficie de estado vivo;
- `docs/project_book/` — memoria temática consolidada;
- `docs/architecture/` — arquitectura/especificaciones;
- `docs/adr/` — decisiones arquitectónicas;
- `docs/reference/` — referencias técnicas;
- `docs/history/` — informes, research y worklogs cerrados.

`docs/notebooks/` deja de existir como superficie activa.

## Política final de cuadernos

No se crea un cuaderno por PR o microfase.

Solo existen por ahora:

- `docs/project_book/DATA_V3.md` — **CERRADO**;
- `docs/project_book/TRAINER_AI.md` — **ACTIVO**.

No se abren cuadernos vacíos de Battle/UI/Overworld/etc. Se creará otro únicamente si un workstream futuro realmente necesita memoria propia.

## Migración principal

Commit estructural:

`002b8b4ef275cc239ada9c540f0fc84351b0ea44`

Se crearon:

- `docs/current/START_HERE.md`
- `docs/current/PROJECT_STATE.md`
- `docs/current/NEXT_STEPS.md`
- `docs/current/WORK_PROTOCOL.md`
- `docs/project_book/README.md`
- `docs/project_book/DATA_V3.md`
- `docs/project_book/TRAINER_AI.md`.

Los 20 diarios DATA V3 se movieron byte-identical a:

`docs/history/worklogs/data_v3/`

Los antiguos documentos operativos se preservaron en:

`docs/history/worklogs/pre_consolidation/`

Arquitectura/rulesets se movieron inicialmente byte-identical a `docs/architecture/`; referencias de entorno/terceros a `docs/reference/`; ADR y research permanecieron en sus carpetas.

## Verificación estructural

Comparación `b4f6adc2... → 002b8b4e...`:

- cambios exclusivamente en `README.md` y `docs/**`;
- 0 código;
- 0 tests;
- 0 workflows;
- 0 datos canónicos;
- renames de arquitectura/reference/worklogs con 0 adiciones / 0 eliminaciones.

## Primer checkpoint CI

Tras registrar el checkpoint documental se obtuvo HEAD:

`ee22bd5bcb5c57f0203ba2a95d19775ba01d5cb0`

PR #96 lanzó los 18 workflows normales sobre ese SHA.

Resultado:

**18/18 SUCCESS**.

Esto demuestra que la reorganización estructural no alteró runtime ni regresiones de DATA/Trainer/Godot.

## Auditoría documental posterior al primer 18/18

Se revisó si los documentos movidos a `docs/architecture/` podían presentarse honestamente como arquitectura actual.

### Hallazgo A — `ARCHITECTURE.md`

El documento general seguía acumulando texto de Foundation/FASE6/7/8 y cifras antiguas como 286/429 PASS, además de afirmaciones fundacionales que ya no describían el repositorio completo (por ejemplo, ausencia de Nodes fuera de tests antes de existir overworld/presentation).

Decisión:

- preservar el original en `docs/history/worklogs/pre_consolidation/ARCHITECTURE.md`;
- sustituir `docs/architecture/ARCHITECTURE.md` por una visión general actual que separa dominio, presentación, DATA V3 y Trainer AI y remite el estado vivo a `docs/current/`;
- no reescribir uno por uno todos los documentos de fase.

### Hallazgo B — `DATA_FOUNDATION_V3.md`

El documento formal todavía describía la validación inicial de V3 en PR #32 / `5afdc8b3...` y el siguiente paso posterior a aquella primera importación, aunque DATA V3 terminó realmente en PR #95 / `b4f6adc2...`.

Decisión:

- preservar el original en `docs/history/worklogs/pre_consolidation/DATA_FOUNDATION_V3.md`;
- actualizar `docs/architecture/DATA_FOUNDATION_V3.md` al contrato final: source provenance, counts, fronteras Moves/Abilities/Items/Evolutions y cierre end-to-end #95.

### Hallazgo C — cifras de tests dentro de especificaciones antiguas

Documentos de subsistema como `PROGRESSION_ARCHITECTURE.md` o `SAVEGAME_ARCHITECTURE.md` conservan cifras de sus fases originales. Esas cifras siguen siendo evidencia histórica válida, pero no son el total global actual.

Decisión:

- añadir `docs/architecture/README.md`;
- declarar que `ARCHITECTURE.md` es la visión general actual;
- tratar números de PASS/nombres de fase en especificaciones de subsistema como evidencia local de su cierre, no como estado global;
- no iniciar una reauditoría técnica de todos los subsistemas dentro de una reorganización documental.

## Descubrimiento Trainer AI reutilizable

`TrainerProfile` ya define estilos:

- balanced
- aggressive
- cautious
- technical

y establece que dificultad no puede conceder información oculta.

Consecuencia para FASE34:

**estilo ≠ competencia/expertise**.

No duplicar personalidad. Auditar y diseñar una capa de expertise separada sobre `StrategicSwitchingTrainerBrain`, loadouts y team composition.

## Cierre pendiente

La auditoría posterior al primer 18/18 modifica únicamente documentación, por lo que crea un nuevo HEAD final.

Antes de cerrar #96:

1. generar el commit final con la visión general/contrato DATA actualizados, los originales archivados y `current/` sincronizado;
2. comparar contra `b4f6adc2...` y confirmar que continúa limitado a `README.md` + `docs/**`;
3. exigir **18/18 SUCCESS** sobre ese HEAD final exacto;
4. cerrar #96 **sin merge**;
5. no hacer commit posterior para registrar el cierre.

El HEAD final certificado de #96 será el parent de la siguiente rama Trainer AI.
