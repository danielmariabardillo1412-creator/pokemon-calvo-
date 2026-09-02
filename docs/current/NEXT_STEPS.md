# SIGUIENTE TRABAJO

## Estado operativo actual — Trainer AI Random Cup pre-FASE34

Rama activa:

`audit/trainer-ai-v3-random-cup-redesign-v1`

PR temporal activo:

`#105 — Trainer AI Random Cup modernization — C2e-b support saturation audit`

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

## Decisión requerida antes de tocar producción

C2e-c cambia una premisa del modelo y no debe convertirse automáticamente en un parche.

Hay que separar tres conceptos:

1. **probabilidad runtime del efecto** — debe reflejar la semántica real de `CHANCE` sin multiplicar metadata duplicada del hijo;
2. **fiabilidad de la acción** — accuracy base y, más adelante, contexto de accuracy/evasion si corresponde;
3. **breadth/densidad de control** — cuántas rutas de control independientes tiene el miembro y si son moves dedicados o secundarios dañinos.

La siguiente tranche debe ser pequeña y explícita. Antes de modificar `TrainerRosterRoleInference`, decidir si el score intrínseco de control debe representar:

- expectativa por intento (`effect_probability × base_accuracy`),
- potencia condicional al impacto + fiabilidad como eje separado,
- o un par de señales (`control_potency_bp`, `control_reliability_bp`) del que `support` derive después.

No bajar thresholds ni añadir bonus de breadth hasta resolver esta semántica.

No modificar todavía `TrainerTeamAnalyzer`, switching/search, C3 ni FASE34.

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
