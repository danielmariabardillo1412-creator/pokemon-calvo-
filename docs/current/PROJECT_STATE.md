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

---

## CHECKPOINT ACTUAL — TRAINER AI RANDOM CUP PRE-FASE34

**Este bloque supersede para el trabajo Trainer AI las secciones históricas `Trabajo actual` / `Después de #96` anteriores.** La autoridad exacta de refs, PRs y CI sigue siendo GitHub.

Rama activa:

`audit/trainer-ai-v3-random-cup-redesign-v1`

Estado de modernización:

- C1 `campaign_snapshot` en `TrainerDecisionContext`: **IMPLEMENTADO / CERTIFICADO**;
- C1b transporte sanitizado por `TrainerIntelligenceController`: **IMPLEMENTADO / CERTIFICADO**;
- C2a fixtures e invariantes de inferencia: **IMPLEMENTADO / CERTIFICADO**;
- C2b evidencia intrínseca de capacidades: **IMPLEMENTADA / CERTIFICADA**;
- C2c afinidades funcionales multirole: **IMPLEMENTADA / CERTIFICADA EN SHA DE CÓDIGO**;
- `TrainerTeamAnalyzer`: **NO INTEGRADO TODAVÍA**;
- switching/search con valor de campaña: **NO INTEGRADOS TODAVÍA**;
- C3 valor estratégico/permadeath: **NO INICIADO**;
- FASE34 dificultad/expertise: **PAUSADA HASTA CERRAR MODERNIZACIÓN PREVIA**.

### C2b — evidencia intrínseca implementada y cierre final

Clase:

`TrainerRosterRoleInference`

`extract_intrinsic_evidence()` extrae una capa auditable de hechos/evidencias desde el `member_view` propio sanitizado + `DefinitionCatalog`:

- stats estructurales reales;
- suma de potencia física de movimientos ejecutables;
- suma de potencia especial de movimientos ejecutables;
- señal física `attack × physical_power_sum`;
- señal especial `special_attack × special_power_sum`;
- bulk físico `max_hp × defense`;
- bulk especial `max_hp × special_defense`;
- speed estructural;
- prioridad máxima ejecutable;
- señal de control desde `BattleEffectSpec` estructurado;
- señal de setup desde `BattleEffectSpec` estructurado;
- señal de sustain desde `BattleEffectSpec` estructurado.

Gate Random Cup V1:

- solo `MoveDefinition.classification == RUNTIME_SUPPORTED` aporta evidencia;
- `PARTIAL_RUNTIME`, `DATA_ONLY`, `UNSUPPORTED` y movimientos desconocidos fallan de forma cerrada y no inflan capacidades;
- la salida registra por separado movimientos runtime, excluidos y desconocidos para auditoría.

La identidad intrínseca ignora deliberadamente HP actual, PP actual, `role_id` authored, `TrainerProfile` y ruido/datos rivales añadidos al input. Esos factores pertenecen a readiness, personalidad o información de batalla, no a la capacidad estructural del miembro.

SHA de código/test C2b inicialmente certificado:

`2b754f63def1632117e54fbd8aa11cb2f089ccc3`

Tras registrar el checkpoint documental, el HEAD final exacto de C2b fue:

`6bceaeda1a1439c9ad690e5c48745c112b74ba2a`

Resultado sobre ese HEAD final:

- **18/18 workflows GitHub Actions: SUCCESS**;
- `Trainer Loadouts Tests`: **261 PASS / 0 FAIL**;
- C2b añadió **27 checks nuevos** sobre C2a;
- PR temporal **#101 cerrado SIN merge**;
- `main` permaneció sin mover.

Incidente operativo no funcional durante C2b:

- se creó accidentalmente `tests/trainer_ai/.c2b_ci_placeholder` en un commit transitorio;
- se eliminó inmediatamente en el commit siguiente;
- no quedó ningún placeholder en el árbol final certificado.

### C2c — afinidades funcionales multirole

C2c añade:

`TrainerRosterRoleInference.infer_role_scores(member_view, catalog)`

Modelo:

`trainer_roster_role_affinity_v1`

La salida `role_scores_bp` usa basis points `0..10000`, pero **estos scores NO representan fuerza total ni valor estratégico**. Representan afinidad funcional intrínseca: qué funciones puede desempeñar el miembro según sus stats materializados y su loadout realmente ejecutable.

La magnitud bruta de combate continúa en `intrinsic_evidence` de C2b y será una entrada separada para C3. Así se evita confundir “tiene forma de tanque” con “es un tanque fuerte/valioso” o convertir el mejor miembro de un roster mediocre en élite por puro ranking interno.

Normalización C2c:

- `stat_ceiling` = máximo entre Attack, Defense, Speed, Special Attack y Special Defense del propio miembro;
- cada `*_focus_bp` compara ese stat contra dicho techo intrínseco;
- `damage_route_ceiling` = máximo entre las señales físicas/especiales ejecutables de C2b;
- `physical_route_bp` y `special_route_bp` describen el reparto real de sus rutas ofensivas;
- no existe comparación contra los otros cinco miembros del roster.

Roles:

- `physical_attacker = min(attack_focus_bp, physical_route_bp)`;
- `special_attacker = min(special_attack_focus_bp, special_route_bp)`;
- `fast_attacker = min(speed_focus_bp, max(physical_attacker, special_attacker))`, y requiere ruta ofensiva real;
- `bulky_physical = defense_focus_bp`;
- `bulky_special = special_defense_focus_bp`;
- `support = max(control_signal_bp, sustain_signal_bp)`.

Decisiones deliberadas:

- Attack alto sin movimiento físico `RUNTIME_SUPPORTED` no fabrica `physical_attacker`;
- Special Attack alto sin ruta especial no fabrica `special_attacker`;
- Speed alta sin presión ofensiva real no fabrica `fast_attacker`;
- prioridad se conserva como señal auditable pero **no convierte por atajo a un Pokémon lento en fast attacker**;
- self-setup se conserva en `setup_signal_bp`, pero **no convierte por sí solo en support**;
- un híbrido puede poseer simultáneamente afinidad física y especial alta;
- no se fuerza todavía un único `primary_role_id` ni secundarios;
- `balanced` sigue reservado como posible resumen/fallback posterior, no como bolsa que oculte capacidades;
- `role_id` authored, `TrainerProfile`, rival/beliefs y datos ocultos no intervienen;
- el gate C2b mantiene fuera `PARTIAL_RUNTIME`, `DATA_ONLY`, `UNSUPPORTED` y movimientos desconocidos.

Commits C2c:

- `8ba235915b2556921e8be39b4187a5b431647161` — `feat(trainer-ai): add intrinsic role affinity scores`;
- `d4866e74b7c436c728d19174c68e96560c102d8b` — `test(trainer-ai): cover multi-role affinity inference`.

Diff C2c frente al HEAD C2b:

- **2 commits**;
- **2 archivos modificados**;
- `modules/trainer_ai/trainer_roster_role_inference.gd`: +73 / -0;
- `tests/trainer_ai/trainer_roster_role_inference_test_suite.gd`: +121 / -0;
- consumidores: **0 modificados**.

### C2c — regresiones y certificación de código

C2c añadió **19 checks nuevos**. Entre ellos:

- físico claro → rol físico máximo y especial cero;
- especial claro → rol especial máximo y físico cero;
- speed limita `fast_attacker`;
- un no-atacante rápido no obtiene rol fast por sí solo;
- bulk físico/especial sigue el foco defensivo correspondiente;
- control/sustain estructurados producen support;
- setup se conserva sin convertirse automáticamente en support;
- híbrido puede conservar dos roles ofensivos simultáneos;
- `DATA_ONLY` no puede fabricar rol ofensivo;
- prioridad queda auditable sin shortcut de fast role;
- `role_id`/perfil/ruido rival no cambian el resultado;
- todos los role scores quedan en `0..10000`;
- salida JSON-serializable y model id estable.

SHA exacto de código/test C2c:

`d4866e74b7c436c728d19174c68e96560c102d8b`

PR temporal:

`#102 — Trainer AI Random Cup modernization — C2c multi-role affinities`

Resultado confirmado sobre ese SHA:

- **18/18 workflows GitHub Actions: SUCCESS**;
- `Trainer Loadouts Tests`: **280 PASS / 0 FAIL**;
- los **19 checks C2c** son verdes;
- `Godot 4.7 Tests`: SUCCESS;
- `Data Foundation V3 Tests`: SUCCESS;
- resto de gates Trainer AI: SUCCESS.

Por tanto, **C2c de código queda CERTIFICADO en `d4866e74b7c436c728d19174c68e96560c102d8b`**.

### Límites tras C2c

Todavía no existe:

- selección de `primary_role_id`/secondary roles;
- calibración sobre una muestra representativa de Pokémon reales DATA V3;
- integración con `TrainerTeamAnalyzer`;
- cálculo de unicidad/redundancia entre miembros;
- `TrainerRosterStrategicValueEvaluator`;
- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`;
- integración switching/search;
- corpus Random Cup multi-batalla.

El siguiente bloque recomendado antes de conectar consumidores es **C2d — calibración/regresión con miembros reales materializados desde DATA V3**, para comprobar que las afinidades relativas no producen distribuciones patológicas fuera de los fixtures sintéticos. Solo después conviene adaptar `TrainerTeamAnalyzer` o empezar C3.

Este commit documental es posterior al SHA de código verde. Debe obtener **18/18 workflows sobre su SHA exacto** antes de considerar cerrado C2c a nivel de HEAD final de rama. PR #102 debe cerrarse **sin merge** después de esa certificación.
