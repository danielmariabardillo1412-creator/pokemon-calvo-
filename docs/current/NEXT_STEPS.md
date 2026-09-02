# SIGUIENTE TRABAJO

## Estado operativo actual — Trainer AI Random Cup pre-FASE34

Rama activa:

`audit/trainer-ai-v3-random-cup-redesign-v1`

PR temporal activo:

`#105 — Trainer AI Random Cup modernization — C2e control evidence calibration`

No mergear a `main`. `main` continúa fuera de este workstream.

Modernización ya cerrada/certificada antes de C2e:

- C1 — `campaign_snapshot` seguro en `TrainerDecisionContext`;
- C1b — transporte sanitizado por `TrainerIntelligenceController`;
- C2a — fixtures/invariantes de role inference;
- C2b — evidencia intrínseca de capacidades;
- C2c — afinidades funcionales multirole `0..10000`;
- C2d — auditoría contra DATA V3 real;
- C2e-a — auditoría jerárquica de etiquetas.

DATA V3 volvió a estado **CERRADO / CERTIFICADO** después de corregir la familia `damage-raise`: los 28/28 `stat_changes` que pertenecen al usuario apuntan a `SELF`, Close Combat se ejecuta correctamente sobre el actor y el checkpoint exacto `816c8ab1d1a9b0936ccf07bf454b94a13d2a257e` obtuvo 18/18 workflows SUCCESS, DATA 567/0 y Spanish/runtime 314/0.

C2e continúa abierto porque la saturación de `support` persiste incluso con DATA V3 corregido.

Todavía NO integrar:

- `TrainerTeamAnalyzer` con la nueva inferencia;
- switching/search con valor de campaña;
- C3 `TrainerRosterStrategicValueEvaluator`;
- FASE34 difficulty/expertise.

Referencias:

- `docs/project_book/TRAINER_AI.md`;
- `docs/project_book/DATA_V3.md`, sección 11.

---

## C2e-b — remedición post-fix de DATA V3

Probe real-data compartido: nivel 50, IV31, EV0, naturaleza neutral, hasta cuatro últimos movimientos `level_up <= 50` y solo `RUNTIME_SUPPORTED`. Es una sonda de auditoría, no política Random Cup.

Cobertura post-fix:

- especies totales: 1.025;
- elegibles: **1.021**;
- sin movimientos del probe: **4**.

Distribución relevante:

- `support > 0`: 892;
- `support >= 7500`: **444**;
- `support == 10000`: **441**;
- `support` máximo único: **103**;
- `support` empatado en el máximo: **338**;
- colisión con ofensiva: **201**;
- colisión con bulk: **164**;
- `support == 10000` coexistiendo con ofensiva >=7500: **354**.

Fuentes:

- control-only: 762;
- sustain-only: 25;
- control+sustain: 105;
- ninguna: 129.

Entre los 441 casos `support == 10000`:

- control-only: 396;
- control+sustain: 45;
- una sola fuente supportive: 79;
- múltiples fuentes supportive: 362;
- fuente única dañina supportive: 22.

Sentinelas confirmaron que Close Combat/Superpower ya no aportan falso control. La saturación restante pertenece al modelo de inferencia/etiquetado, no al bug DATA V3 ya corregido.

---

## C2e-c — auditoría de probabilidad, precisión y densidad de control

Commits test-only:

- `30a4949d8fda685935cd190426907a9ecb9cec97` — añade `TrainerRosterControlProbabilityAuditTestSuite`;
- `6b82df60a0d1f39c7dcd08f39a81439d20d3c7a0` — conecta la sonda al runner de Trainer Loadouts.

Producción Trainer AI no cambió.

Trainer Loadouts sobre `6b82df60...`:

**317 PASS / 0 FAIL**.

### Hallazgo 1 — metadata probabilística duplicada frente a semántica runtime

`BattleEffectExecutor` solo lanza probabilidad cuando ejecuta un nodo `BattleEffectSpec.CHANCE`. Los hijos `INFLICT_STATUS`, `MODIFY_STAT_STAGE` y `FLINCH` no vuelven a consultar su propio `chance_basis_points`.

`TrainerRosterRoleInference`, en cambio, multiplica `chance_basis_points` en **cada nodo** de la rama. El conversor legado conserva en ciertos status/stat secundarios la misma probabilidad tanto en el wrapper `CHANCE` como en el efecto hijo.

Consecuencia: la inferencia actual **eleva al cuadrado** esas probabilidades respecto a lo que realmente ejecuta Battle Core.

Ejemplos certificados por la sonda:

- Moonblast: inferencia actual 900 bp; semántica runtime del efecto 3000 bp;
- Discharge: 900 bp frente a 3000 bp;
- Rock Slide no duplica la probabilidad: 3000 bp tanto en inferencia como en runtime, porque el hijo FLINCH no lleva un segundo 3000.

En el probe real:

- `production_signal_mismatch_species`: **0** — la sonda reproduce exactamente el cálculo actual;
- producción < probabilidad runtime del efecto: **284** especies;
- producción = runtime: **737**;
- producción > runtime: **0**;
- especies con alguna ruta de control con metadata duplicada: **628**.

Esto es un defecto real de coherencia de inferencia, pero **no explica la saturación por exceso**: actualmente infravalora 284 especies.

### Hallazgo 2 — la precisión base del movimiento no forma parte de `control_signal_bp`

La inferencia actual valora la probabilidad del efecto **condicionada a que el movimiento conecte**, pero no incorpora `MoveDefinition.accuracy`.

Por eso, por ejemplo:

- Screech: control actual/runtime-on-hit 10000; precisión base 85% → proxy 8500;
- Thunder Wave: 10000; precisión base 90% → 9000;
- Dynamic Punch: control on-hit 10000; precisión base 50% → 5000;
- Rock Slide: efecto 3000 y accuracy 90% → proxy 2700.

La sonda usa `base_accuracy_weighted_control_bp = runtime_effect_control_bp * base_accuracy / 10000` únicamente como **proxy de auditoría**, no como fórmula de producción congelada. La probabilidad real de impactar puede cambiar por accuracy/evasion y reglas de always-hit.

Resultados:

- especies cuyo mejor control baja al aplicar accuracy base: **312**;
- control actual `==10000`: **441**;
- control runtime-on-hit `==10000`: **441**;
- proxy con accuracy base `==10000`: **240**;
- control actual `>=7500`: **441**;
- proxy con accuracy base `>=7500`: **411**;
- casos `support ==10000` que caerían por debajo de 10000 con el proxy: **201**;
- casos `support >=7500` que caerían por debajo de 7500: **30**.

Este sí es un candidato material para explicar una parte importante de la saturación de `support`.

### Hallazgo 3 — breadth/densidad sigue siendo independiente

El modelo de producción toma el **máximo** entre rutas de control, no la cantidad/diversidad de rutas.

Histograma de movimientos con alguna ruta de control runtime en el probe:

- 0: 154;
- 1: 303;
- 2: 340;
- 3: 171;
- 4: 53.

Movimientos de control dedicados (`power == 0`):

- 0: 653;
- 1: 316;
- 2: 47;
- 3: 5.

Movimientos dañinos con control:

- 0: 243;
- 1: 394;
- 2: 274;
- 3: 99;
- 4: 11.

Rutas con proxy de control >=7500 tras accuracy base:

- 0: 610;
- 1: 346;
- 2: 57;
- 3: 8.

Por tanto una sola ruta fuerte puede seguir llevando `support` al techo; breadth/densidad no está representada en el score actual.

---

## C2e-d — forma del control: intensidad, fiabilidad y breadth separados

Commits test-only:

- `cc5297119b24acec2972cdbfb0fbdea1b8ccf8c0` — añade `TrainerRosterControlShapeAuditTestSuite`;
- `255cf8db722ca7248bc4a3fd7b648dd8fa8fab07` — conecta la sonda al runner.

Producción no cambió.

Trainer Loadouts sobre `255cf8db...`:

**332 PASS / 0 FAIL**.

La sonda no crea un nuevo `support` ni asigna pesos. Conserva por separado hechos observables:

- número de movimientos con control;
- número de ejes/efectos de control distintos;
- familia del efecto (`stat_debuff`, `status`, `flinch`);
- mejor y segunda mejor fiabilidad por intento (`runtime CHANCE × base accuracy`);
- movimientos de control dedicados frente a secundarios de ataques;
- magnitud cruda máxima de debuff en stages.

### Distribución real

Sobre 1.021 especies elegibles:

- especies con alguna ruta de control: **867**;
- con 2+ movimientos de control: **564**;
- con 2+ efectos/ejes distintos: **506**;
- con exactamente una ruta de alta fiabilidad (`>=7500`): **346**;
- con 2+ rutas de alta fiabilidad: **65**.

Histogramas:

- movimientos de control: `0:154, 1:303, 2:340, 3:171, 4:53`;
- efectos/ejes distintos: `0:154, 1:361, 2:358, 3:132, 4:16`;
- familias distintas: `0:154, 1:472, 2:343, 3:52`;
- movimientos de alta fiabilidad: `0:610, 1:346, 2:57, 3:8`;
- debuff máximo en stages: `0:430, 1:380, 2:211`.

La segunda mejor ruta es especialmente discriminativa:

- sin segunda ruta: **457**;
- segunda ruta entre 1–4999 bp: **478**;
- 5000–7499: **21**;
- 7500–8999: **29**;
- 9000–10000: **36**.

### Qué ocurre dentro de los 441 techos actuales

Entre las especies cuyo `control_signal_bp` actual es 10000:

- **90** tienen un solo movimiento de control;
- **351** tienen varios movimientos de control;
- **30** no tienen ninguna ruta que alcance 7500 al ponderar CHANCE runtime + accuracy base;
- **346** tienen exactamente una ruta de alta fiabilidad;
- solo **65** tienen dos o más rutas de alta fiabilidad.

Esto demuestra que `control=10000` mezcla perfiles funcionalmente muy diferentes. Un Pokémon con un solo Screech, uno con Icy Wind + Swagger y otro con cuatro ataques que contienen efectos secundarios pueden compartir techo aunque su robustez/breadth de control sea muy distinta.

### Sentinelas

- Thunder Wave: status dedicado, reliability proxy **9000**;
- Screech: debuff dedicado de Defense -2, reliability **8500**;
- Dynamic Punch: ataque con control potente on-hit, reliability **5000** por accuracy;
- Rock Slide: flinch secundario, reliability **2700**;
- Moonblast: SpA -1 secundario, runtime chance **3000** y reliability **3000**; confirma que no debe elevarse al cuadrado la metadata;
- Icy Wind: ataque con Speed -1 garantizado on-hit, reliability **9500**.

Además aparecen dos formas de breadth que no deben confundirse:

1. **varios movimientos, mismo eje** — por ejemplo dos ataques que solo intentan burn/paralysis/flinch;
2. **un solo movimiento, varios ejes** — por ejemplo `Noble Roar` aporta Attack -1 y Special Attack -1 desde una sola acción.

Por tanto, contar simplemente movimientos tampoco es suficiente. El modelo debe conservar al menos `move breadth` y `effect breadth` por separado si más adelante quiere resumir soporte.

---

## C2e-e — evidencia de control separada en producción

Tranche de producción aditiva. No recalibra `support` ni integra consumidores.

Commits:

- `00a7b8aa56c10dd022a8b876e610c396c7974737` — añade evidencia de control auditada a `TrainerRosterRoleInference`;
- `8652f3b8facec89f3da7dee57d8e6e5d8fe124f1` — añade `TrainerRosterControlEvidenceTestSuite`;
- `80f19095f7b1b97973d818b8fad364453db9662b` — conecta la suite al runner;
- `bcb7a2036d9750662c14763ab8b1d519e432da47` — corrige el acceso `stat_key` → `stat_id` detectado por CI.

La salida de `extract_intrinsic_evidence()` conserva el `control_signal_bp` legado y añade en paralelo:

- `control_best_runtime_effect_bp`;
- `control_reliability_bp`;
- `control_secondary_reliability_bp`;
- `control_move_count`;
- `control_effect_key_count`;
- `control_effect_family_count`;
- `control_dedicated_move_count`;
- `control_damaging_move_count`;
- `control_strongest_stat_drop_stages`;
- `control_breakdown` determinista por movimiento;
- `control_evidence_model_id = trainer_roster_control_evidence_v1`.

Semántica nueva:

- la probabilidad runtime solo se multiplica al atravesar un nodo `BattleEffectSpec.CHANCE`;
- la fiabilidad por intento combina esa probabilidad runtime con `MoveDefinition.accuracy` base;
- la magnitud del debuff se conserva separada como stages crudos;
- move breadth y effect breadth se conservan por separado;
- se distingue control dedicado (`power <= 0`) de control secundario en movimientos dañinos;
- solo `RUNTIME_SUPPORTED` entra en esta evidencia, igual que el gate C2b.

Compatibilidad deliberada:

- `_effect_signals()` no cambió;
- `control_signal_bp` no cambió;
- `support = max(control_signal_bp, sustain_signal_bp)` no cambió;
- las distribuciones real-data de C2d/C2e anteriores permanecen idénticas en esta tranche.

### Incidente CI C2e-e

Primer HEAD con la suite conectada:

`80f19095f7b1b97973d818b8fad364453db9662b`

Resultado FASE32:

**346 PASS / 3 FAIL**.

Los tres fallos eran exclusivamente de la nueva evidencia (`stat drop magnitude`, `effect breadth`, `one move/two effect keys`). La causa única fue un acceso incorrecto a `BattleEffectSpec.stat_key`; el contrato real usa `stat_id`.

No hubo regresión histórica ni fallo de diseño del modelo. El fix mínimo fue `stat_key → stat_id` en `_accumulate_control_shape()`.

SHA de código/test corregido:

`bcb7a2036d9750662c14763ab8b1d519e432da47`

Resultado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- `Trainer Loadouts Tests`: **349 PASS / 0 FAIL**;
- 332 checks previos conservados + **17 checks nuevos**;
- Godot 4.7 Tests: SUCCESS;
- Data Foundation V3 Tests: SUCCESS;
- `support` histórico y las sondas real-data permanecen sin recalibrar.

Por tanto C2e-e de código queda **CERTIFICADO en `bcb7a203...`**. Este documento crea un HEAD posterior y debe obtener su propio 18/18 antes de certificar el HEAD final de la tranche.

---

## Paso inmediato después de C2e-e

La siguiente microtranche ya puede usar la evidencia separada para **auditar y diseñar el nuevo resumen de `support`**, pero no debe saltar directamente a una fórmula arbitraria.

Orden recomendado:

1. tests relacionales con sentinelas que comparen una sola ruta fiable vs varias rutas fiables;
2. comparar control dedicado vs secundario dañino sin declarar que uno siempre vale más;
3. medir una o más fórmulas candidatas contra las 1.021 especies del probe;
4. elegir una semántica solo si reduce saturación sin borrar casos legítimos de support;
5. en una tranche separada, cambiar `support` y repetir los audits real-data.

Todavía NO integrar `TrainerTeamAnalyzer`, switching/search, C3 ni FASE34.

---

## Después de cerrar C2e

Solo cuando la semántica y distribución de roles sean razonablemente discriminativas:

1. integrar `TrainerTeamAnalyzer` con inferencia dinámica en una tranche separada;
2. mantener el flujo authored histórico con `role_id` donde corresponda;
3. iniciar C3 `TrainerRosterStrategicValueEvaluator` usando afinidad + evidencia absoluta;
4. resolver políticas de campaña que bloqueen `permadeath_loss_cost_bp` completo;
5. integrar después switching/search;
6. construir corpus Random Cup multi-batalla antes de calibrar pesos de preservación/permadeath;
7. retomar FASE34 difficulty/expertise solo después de cerrar esta modernización.

Continúan fuera de alcance inmediato:

- MCTS/red neuronal sin bottleneck demostrado;
- mover `main`;
- crear una autoridad Random Cup ficticia solo para tests;
- inventar reglas todavía abiertas de gameplay;
- esconder bugs de DATA/Battle Core mediante excepciones privadas de Trainer AI.