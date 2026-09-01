# ESTADO ACTUAL DEL PROYECTO

## Baseline funcional certificado

Último baseline funcional certificado anterior a la reorganización documental:

- PR #95 — `DATA V3 — final end-to-end certification`
- rama: `audit/data-v3-end-to-end-closure-v1`
- HEAD final: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- estado: **cerrado sin merge**
- validación: **18/18 workflows SUCCESS** sobre el HEAD final.

## Reorganización documental — PR #96

Rama:

`chore/documentation-consolidation-v1`

Parent exacto:

`b4f6adc200bef18f8ac51b9144f2f9a838f464fd`

PR:

#96 — `Docs — consolidar estado vivo, cuadernos e historial`

Primer checkpoint completo de reorganización:

`ee22bd5bcb5c57f0203ba2a95d19775ba01d5cb0`

Resultado sobre ese SHA:

**18/18 workflows SUCCESS**.

Ese ciclo demuestra que la migración de estructura documental no alteró runtime ni regresiones. Después de ese checkpoint se realizó la auditoría final de documentación formal y se encontraron dos documentos presentados como actuales que todavía contenían estado de fases antiguas: `ARCHITECTURE.md` acumulaba totales y referencias fundacionales obsoletas, y `DATA_FOUNDATION_V3.md` todavía describía la validación inicial de PR #32 en lugar del cierre real #95.

La corrección final:

- reemplaza `docs/architecture/ARCHITECTURE.md` por una visión general actual;
- actualiza `docs/architecture/DATA_FOUNDATION_V3.md` al contrato certificado final;
- añade `docs/architecture/README.md` para distinguir especificación de fase de estado operativo;
- preserva los originales íntegros en `docs/history/worklogs/pre_consolidation/`.

Como estas correcciones mueven el SHA después del primer 18/18, el nuevo HEAD documental final debe obtener **otro 18/18** antes de cerrar #96 sin merge.

`main` continúa intacta y **no representa actualmente el baseline moderno**. Su sustitución se hará más adelante como operación separada.

## Estructura documental activa

La documentación queda separada por función:

- `docs/current/` — única fuente documental de estado vivo;
- `docs/project_book/` — memoria temática consolidada;
- `docs/architecture/` — arquitectura/especificaciones;
- `docs/adr/` — decisiones arquitectónicas;
- `docs/reference/` — referencias técnicas;
- `docs/history/` — research, informes y worklogs cerrados.

Cuadernos temáticos actuales:

- `docs/project_book/DATA_V3.md` — **CERRADO**;
- `docs/project_book/TRAINER_AI.md` — **ACTIVO / siguiente workstream**.

No se crean cuadernos vacíos por anticipación.

## DATA FOUNDATION V3 — CERRADO

Fuente inmutable:

- snapshot branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2` y `data/schema/v2` read-only.

Contrato canónico:

- 1.025 especies
- 326 formas
- 18 tipos runtime
- 919 movimientos
- 373 habilidades
- 2.222 objetos
- 61.102 entradas de learnset
- 554 evoluciones
- 0 referencias rotas
- 0 definiciones rechazadas
- 18 movimientos XD Shadow excluidos.

Fronteras runtime:

- Moves: 590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED.
- Abilities: 21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY.
- Evolutions: 391 RUNTIME_SUPPORTED / 0 PARTIAL_RUNTIME / 149 DATA_ONLY / 14 UNSUPPORTED.
- Items held: `leftovers`, `sitrus_berry`.
- Trainer bag: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.
- Curación Calvo V1: 20 / 60 / 120 / full / full+status.

Cierre end-to-end:

- DATA V3 domain: **567 PASS / 0 FAIL**
- Spanish/type/runtime: **298 PASS / 0 FAIL**.

Referencias:

- `docs/architecture/DATA_FOUNDATION_V3.md`
- `docs/project_book/DATA_V3.md`.

## IA DE ENTRENADORES — STACK EXISTENTE

La línea certificada FASE 19–33 contiene sesión de entrenador, inteligencia táctica, beliefs, búsqueda acotada, self-play/corpus, cobertura adaptativa/pública, items finitos, switching estratégico, loadouts y composición de equipos.

El cerebro serio actual debe evolucionar desde `StrategicSwitchingTrainerBrain`, no volver a una ruta antigua search-only.

`TrainerProfile` ya representa estilo con:

- `balanced`
- `aggressive`
- `cautious`
- `technical`.

Esos perfiles cambian prioridades, no legalidad ni acceso a información oculta.

La siguiente expansión debe separar **estilo** de **competencia/expertise** y mantener la misma frontera anti-cheat.

### Random Cup — regla canónica de curación de bolsa

En Random Cup **no se permiten pociones ni acciones de curación mediante la bolsa durante el combate**, de forma simétrica para jugador y entrenadores IA.

Consecuencias para Trainer AI:

- el flujo Random Cup no debe ofrecer acciones `ITEM` de curación a ningún lado;
- `TrainerItemTacticalEvaluator`, `TrainerItemAwareSearch` y la economía persistente de pociones no forman parte de la política Random Cup;
- FASE30 se conserva como infraestructura válida para otros modos donde los objetos de bolsa sí estén permitidos;
- Revive continúa fuera de Random Cup;
- esta decisión no define por sí sola la recuperación automática de HP/PP/status entre combates ni la política de held items con curación pasiva; esos temas permanecen separados hasta una regla explícita.

Referencia: `docs/project_book/TRAINER_AI.md`.

## Trabajo actual

Cerrar correctamente PR #96:

1. certificar el HEAD documental final exacto con 18/18;
2. comprobar que el diff frente a `b4f6adc2...` sigue siendo exclusivamente `README.md` + `docs/**`;
3. cerrar #96 **sin merge**;
4. usar ese HEAD final como parent del siguiente workstream.

No hacer un commit posterior solo para escribir que el PR quedó cerrado: GitHub es la autoridad de ese estado externo.

## Después de #96

Retomar directamente Trainer AI y auditar difficulty/archetype/expertise antes de escribir FASE34.

Continúan fuera de alcance inmediato:

- reabrir DATA V3 por aumentar contadores;
- MCTS/red neuronal sin límite real demostrado;
- sustitución de `main`;
- traducción masiva del código/runtime.
