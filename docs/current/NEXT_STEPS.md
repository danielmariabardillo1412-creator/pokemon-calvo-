# SIGUIENTE TRABAJO

## Estado operativo actual — Trainer AI Random Cup pre-FASE34

Rama activa:

`audit/trainer-ai-v3-random-cup-redesign-v1`

Modernización cerrada/certificada antes del bloqueo actual:

- C1 — `campaign_snapshot` seguro en `TrainerDecisionContext`;
- C1b — transporte sanitizado por `TrainerIntelligenceController`;
- C2a — fixtures/invariantes de role inference;
- C2b — evidencia intrínseca de capacidades;
- C2c — afinidades funcionales multirole `0..10000`;
- C2d — auditoría contra DATA V3 real;
- C2e-a — auditoría jerárquica de etiquetas.

Todavía NO están integrados con la nueva inferencia:

- `TrainerTeamAnalyzer`;
- switching/search con valor de campaña;
- C3 `TrainerRosterStrategicValueEvaluator`;
- FASE34 difficulty/expertise.

Referencia temática principal:

`docs/project_book/TRAINER_AI.md`.

---

## C2d — auditoría real DATA V3

Sonda exclusivamente de test:

`TrainerRosterRoleRealDataTestSuite`

Probe:

`runtime_levelup_l50_neutral_probe_v1`

No es política Random Cup. Usa DATA V3 real, nivel 50, IV31, EV0, naturaleza neutral, hasta cuatro últimos movimientos `level_up <= 50` y solo `RUNTIME_SUPPORTED`.

Cobertura:

- 1.025 especies totales;
- 1.011 elegibles bajo el probe;
- 14 sin movimiento elegible.

Afinidades `>= 7500`:

- 0 roles: 29;
- 1: 101;
- 2: 312;
- 3: 280;
- 4: 210;
- 5: 71;
- 6: 8.

Por tanto 569/1.011 tienen 3 o más roles altos y 289/1.011 tienen 4 o más. El vector continuo conserva información útil, pero un threshold global fijo no sirve para derivar etiquetas discretas.

Empates del máximo en el modelo plano de seis ejes:

- máximo único: 512;
- empate de 2: 428;
- empate de 3: 49;
- empate de 4: 15;
- empate de 5: 7.

Separación confirmada:

- `role_scores_bp` = afinidad/forma funcional relativa;
- `intrinsic_evidence` C2b = magnitud objetiva;
- C3 deberá consumir ambas dimensiones sin convertir afinidad en fuerza.

Medianas absolutas de bulk del probe:

- físico: 13.050;
- especial: 12.825.

Había 83/79 casos respectivamente con afinidad defensiva `>=9000` pero magnitud absoluta igual o inferior a la mediana.

C2d final:

- HEAD `35c689e657816f62b7428d6128ae3cfdc6ce15eb`;
- 18/18 workflows SUCCESS;
- Trainer Loadouts 290 PASS / 0 FAIL;
- PR #103 cerrado sin merge.

---

## C2e-a — auditoría jerárquica de etiquetas

Sonda de test:

`TrainerRosterRoleLabelCalibrationTestSuite`

Hallazgo principal:

`fast_attacker` es compuesto por construcción (`speed ∩ offense`) y competir como rol primario plano fabrica empates. Al retirarlo del conjunto de candidatos primarios:

- empates múltiples: 499 -> 373;
- primarios únicos: 512 -> 638;
- `fast_attacker == best_offense` en 318 especies;
- `fast_attacker >=7500` en 442.

Dominancia entre los 638 primarios core únicos:

- margen >=500 bp: 573;
- margen >=1000 bp: 456;
- margen >=1500 bp: 345;
- top >=7500 y margen >=1000: 446.

Distribución provisional de primarios únicos:

- physical_attacker: 269;
- special_attacker: 141;
- bulky_physical: 94;
- bulky_special: 71;
- support: 63.

`support` seguía colisionando en el máximo en 302 especies.

También se confirmó que 74 de los 638 primarios únicos tenían magnitud absoluta igual o inferior a la mediana de su propia familia: la etiqueta funcional NO equivale a valor estratégico.

C2e-a final:

- HEAD `00b0369b016b9c0c7b6643203cd49130ccddb166`;
- 18/18 workflows SUCCESS;
- Trainer Loadouts 297 PASS / 0 FAIL;
- PR #104 cerrado sin merge.

---

## C2e-b — auditoría de saturación de `support`

PR temporal abierto:

`#105 — Trainer AI Random Cup modernization — C2e-b support saturation audit`

SHA de audit test-only:

`b65b98a142405f714d92572764a58ec5d480f4f1`

Cambios de esa tranche:

- nuevo `TrainerRosterSupportCalibrationTestSuite`;
- una línea de conexión en `trainer_loadouts_test_runner.gd`;
- producción sin cambios.

CI sobre `b65b98a1...`:

- 18/18 workflows SUCCESS;
- Trainer Loadouts: 305 PASS / 0 FAIL.

### Distribución observada de support

Sobre 1.011 especies elegibles:

- support > 0: 901;
- support >=7500: 374;
- support ==10000: 365;
- support máximo único: 63;
- support empatado en el máximo: 302;
- colisión con rol ofensivo: 182;
- colisión con bulk: 139;
- support >=7500 coexistiendo con ofensiva >=7500: 300;
- support ==10000 coexistiendo con ofensiva >=7500: 291.

Fuentes de la señal:

- solo control: 793;
- solo sustain: 17;
- control + sustain: 91;
- ninguna: 110.

Entre los 365 casos `support ==10000`:

- control-only: 323;
- control+sustain: 42;
- sustain-only: 0;
- una sola fuente/movimiento de utilidad: 62;
- múltiples movimientos de utilidad: 303;
- 35 de los 62 casos de fuente única proceden además de un movimiento dañino.

Este audit confirmó que `support = max(control, sustain)` es demasiado fácil de saturar, pero descubrió además un problema más profundo que bloquea cualquier calibración honesta.

---

# BLOQUEO ACTUAL — defecto semántico DATA V3 en self-debuffs dañinos

**C2e-b NO se considera cerrado todavía. NO calibrar thresholds ni modificar `support` hasta resolver este defecto.**

La sonda encontró ejemplos donde movimientos ofensivos con coste propio aparecen como `control=10000`.

Sentinelas observados:

- `close_combat`;
- `superpower`;
- `hammer_arm`.

Ejemplo real del probe:

- Annihilape: su única fuente de `support` puede ser `close_combat`, y la inferencia recibe `control_bp=10000`;
- Clobbopus/Grapploct/Croconaw muestran el mismo patrón con `superpower`;
- Bewear lo muestra con `hammer_arm`.

Esto NO debe corregirse con una lista de nombres dentro de Trainer AI si Battle Core está recibiendo el mismo objetivo incorrecto.

## Evidencia del defecto

### 1. Fuente PokeAPI inmutable

`data/api/v2/move/370/index.json` (`close-combat`) declara explícitamente que, después de hacer daño, baja Defense y Special Defense **del usuario**. Sus `stat_changes` son -1 Defense y -1 Special Defense.

`data/api/v2/move/276/index.json` (`superpower`) declara explícitamente que baja Attack y Defense **del usuario**.

El `target = selected-pokemon` de estas entradas describe el objetivo del ATAQUE, no necesariamente el destinatario de sus cambios secundarios de stats.

### 2. Conversor heredado

`tools/archive/pokeapi_adapter_v2_legacy.py::generate_move_specs()` calcula:

- `self_target` a partir del `move.target` general;
- `stat_target = self` si el move target es user/self;
- de lo contrario `stat_target = opponent`;
- después aplica ese mismo `stat_target` a TODOS los `stat_changes`.

Esto es insuficiente para movimientos dañinos cuyo golpe va al rival pero cuyo coste secundario afecta al usuario.

### 3. Shim DATA V3

`tools/pokeapi_adapter.py` envuelve el conversor legado y contiene correcciones estrechas para familias auditadas durante Move Effects V3, pero no se encontró una corrección específica ya existente para `close_combat`, `superpower` o `hammer_arm`.

### 4. Battle Core ejecuta literalmente el target generado

`BattleEffectExecutor` llama `context.resolve_target(spec.target)` antes de ejecutar `MODIFY_STAT_STAGE`.

`BattleEffectContext.resolve_target()` devuelve al actor únicamente si el selector es `SELF`; cualquier otro selector resuelve al target/rival.

Por tanto un `modify_stat_stage` generado como `opponent` no es solo una etiqueta incorrecta para Trainer AI: Battle Core lo aplicará al Pokémon rival.

## Interpretación del 18/18 verde

Que `b65b98a1...` tenga 18/18 SUCCESS NO demuestra que esta semántica sea correcta. Demuestra que las regresiones existentes no estaban comprobando esta familia de targeting secundario. C2e-b la descubrió por una consecuencia indirecta en el análisis de roles.

---

## Paso inmediato — diagnóstico y reparación canónica de DATA V3

Antes de volver a C2e:

1. añadir regresiones fuente/runtime para self-debuffs dañinos conocidos, empezando por `close_combat`, `superpower` y `hammer_arm`;
2. medir el alcance completo de la familia en el snapshot, no asumir que son solo tres movimientos;
3. corregir `tools/pokeapi_adapter.py` mediante una regla/familia explícitamente auditada y fail-closed, no mediante una heurística genérica insegura;
4. regenerar el dataset normalizado por la ruta autoritativa;
5. verificar que los `effect_specs` afectados usan `target=self` y que Battle Core baja los stats del actor, no del rival;
6. ejecutar DATA V3 domain + Spanish/type/runtime + Godot general + toda la matriz de Trainer AI;
7. registrar los contadores/clasificaciones que cambien, si cambian;
8. solo entonces volver a ejecutar C2d/C2e-a/C2e-b y recalcular la distribución de roles/support.

Si el alcance obliga a reabrir formalmente DATA V3, se hará como corrección semántica de un contrato existente, no como expansión por aumentar contadores.

PR #105 debe permanecer abierto mientras este hallazgo sea el checkpoint activo; no mergear a main.

---

## Después de reparar DATA V3 y cerrar C2e

Solo cuando la semántica de efectos vuelva a estar certificada y la distribución de roles sea razonablemente discriminativa:

1. integrar `TrainerTeamAnalyzer` con inferencia dinámica en una tranche separada;
2. mantener el flujo authored histórico con `role_id` donde corresponda;
3. iniciar C3 `TrainerRosterStrategicValueEvaluator` usando afinidad + evidencia absoluta;
4. resolver las políticas de campaña que bloqueen `permadeath_loss_cost_bp` completo;
5. integrar después switching/search;
6. construir corpus Random Cup multi-batalla antes de calibrar pesos de preservación/permadeath;
7. retomar FASE34 difficulty/expertise solo después de cerrar esta modernización.

Continúan fuera de alcance inmediato:

- MCTS/red neuronal sin bottleneck demostrado;
- mover `main`;
- crear una autoridad Random Cup ficticia solo para tests;
- inventar reglas todavía abiertas de gameplay;
- esconder un bug de DATA/Battle Core mediante excepciones privadas de Trainer AI.
