# SIGUIENTE TRABAJO

## Estado operativo actual — Trainer AI Random Cup pre-FASE34

Rama activa:

`audit/trainer-ai-v3-random-cup-redesign-v1`

Modernización cerrada/certificada antes del checkpoint actual:

- C1 — `campaign_snapshot` seguro en `TrainerDecisionContext`;
- C1b — transporte sanitizado por `TrainerIntelligenceController`;
- C2a — fixtures/invariantes de role inference;
- C2b — evidencia intrínseca de capacidades;
- C2c — afinidades funcionales multirole `0..10000`;
- C2d — auditoría contra DATA V3 real;
- C2e-a — auditoría jerárquica de etiquetas.

C2e-b está abierto y ya produjo dos resultados útiles:

1. diagnosticó saturación excesiva de `support`;
2. descubrió una regresión semántica real de DATA V3/Battle Core en ataques cuyos `stat_changes` afectan al usuario.

La regresión DATA V3 ha sido reparada y está en proceso de recertificación del HEAD final. C2e-b NO debe calibrar thresholds hasta volver a medir sus estadísticas sobre el dataset corregido.

Todavía NO están integrados con la nueva inferencia:

- `TrainerTeamAnalyzer`;
- switching/search con valor de campaña;
- C3 `TrainerRosterStrategicValueEvaluator`;
- FASE34 difficulty/expertise.

Referencias temáticas:

- `docs/project_book/TRAINER_AI.md`;
- `docs/project_book/DATA_V3.md` sección 11 para la corrección semántica descubierta durante C2e-b.

---

## C2d — auditoría real DATA V3

Sonda exclusivamente de test:

`TrainerRosterRoleRealDataTestSuite`

Probe:

`runtime_levelup_l50_neutral_probe_v1`

No es política Random Cup. Usa DATA V3 real, nivel 50, IV31, EV0, naturaleza neutral, hasta cuatro últimos movimientos `level_up <= 50` y solo `RUNTIME_SUPPORTED`.

Cobertura histórica antes de la corrección DATA V3:

- 1.025 especies totales;
- 1.011 elegibles bajo el probe;
- 14 sin movimiento elegible.

Afinidades `>= 7500` históricas:

- 0 roles: 29;
- 1: 101;
- 2: 312;
- 3: 280;
- 4: 210;
- 5: 71;
- 6: 8.

Por tanto 569/1.011 tenían 3 o más roles altos y 289/1.011 tenían 4 o más. El vector continuo conserva información útil, pero un threshold global fijo no sirve para derivar etiquetas discretas.

Empates históricos del máximo en el modelo plano de seis ejes:

- máximo único: 512;
- empate de 2: 428;
- empate de 3: 49;
- empate de 4: 15;
- empate de 5: 7.

Separación confirmada y todavía canónica:

- `role_scores_bp` = afinidad/forma funcional relativa;
- `intrinsic_evidence` C2b = magnitud objetiva;
- C3 deberá consumir ambas dimensiones sin convertir afinidad en fuerza.

C2d final histórico:

- HEAD `35c689e657816f62b7428d6128ae3cfdc6ce15eb`;
- 18/18 workflows SUCCESS;
- Trainer Loadouts 290 PASS / 0 FAIL;
- PR #103 cerrado sin merge.

Los números de distribución deben considerarse **pre-corrección DATA V3** hasta volver a ejecutar el audit sobre el dataset reparado.

---

## C2e-a — auditoría jerárquica de etiquetas

Sonda de test:

`TrainerRosterRoleLabelCalibrationTestSuite`

Hallazgo histórico principal:

`fast_attacker` es compuesto por construcción (`speed ∩ offense`) y competir como rol primario plano fabrica empates. Al retirarlo del conjunto de candidatos primarios:

- empates múltiples: 499 -> 373;
- primarios únicos: 512 -> 638;
- `fast_attacker == best_offense` en 318 especies;
- `fast_attacker >=7500` en 442.

Dominancia histórica entre los 638 primarios core únicos:

- margen >=500 bp: 573;
- margen >=1000 bp: 456;
- margen >=1500 bp: 345;
- top >=7500 y margen >=1000: 446.

Distribución provisional histórica de primarios únicos:

- physical_attacker: 269;
- special_attacker: 141;
- bulky_physical: 94;
- bulky_special: 71;
- support: 63.

`support` colisionaba en el máximo en 302 especies.

También se confirmó que la etiqueta funcional NO equivale a valor estratégico.

C2e-a final histórico:

- HEAD `00b0369b016b9c0c7b6643203cd49130ccddb166`;
- 18/18 workflows SUCCESS;
- Trainer Loadouts 297 PASS / 0 FAIL;
- PR #104 cerrado sin merge.

Los contadores de distribución deben remedirse después de la reparación DATA V3; la conclusión arquitectónica sobre `fast_attacker` como eje compuesto sigue siendo válida, pero no se congelan thresholds a partir de cifras pre-corrección.

---

## C2e-b — auditoría de saturación de `support`

PR temporal abierto:

`#105 — Trainer AI Random Cup modernization — C2e-b support saturation audit`

SHA del audit test-only inicial:

`b65b98a142405f714d92572764a58ec5d480f4f1`

Cambios de esa tranche:

- nuevo `TrainerRosterSupportCalibrationTestSuite`;
- una línea de conexión en `trainer_loadouts_test_runner.gd`;
- producción Trainer AI sin cambios.

CI sobre `b65b98a1...`:

- 18/18 workflows SUCCESS;
- Trainer Loadouts: 305 PASS / 0 FAIL.

### Distribución observada antes de reparar DATA V3

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

Fuentes históricas de la señal:

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
- 35 de los 62 casos de fuente única procedían además de un movimiento dañino.

Estos números **NO deben usarse ya para calibrar producción**, porque parte de la señal de control estaba contaminada por targeting secundario incorrecto en DATA V3.

---

## Corrección DATA V3 descubierta por C2e-b

### Defecto

El conversor legado derivaba el destino de todos los `stat_changes` a partir del `target` general del movimiento. En ataques como `close_combat`, `superpower` o `hammer_arm`, el golpe va al rival pero el coste secundario pertenece al usuario. El resultado era un `MODIFY_STAT_STAGE target=opponent` incorrecto que Battle Core ejecutaba literalmente sobre el rival.

### Alcance auditado

La fuente inmutable `data/api/v2/move-category/7/index.json` contiene **28 movimientos** de la familia `damage-raise`. La corrección no usa una lista privada de tres nombres en Trainer AI: el adaptador V3 trata la familia mediante una regla explícita y fail-closed.

### Reparación canónica

Commit de código + regeneración:

`a2341d4f77f22f54b89916fd8e91ac7b26d2c8d5`

Cambios canónicos de ese commit:

- `tools/pokeapi_adapter.py`;
- `data/raw/pokemon_api.json` regenerado desde snapshot;
- `data/normalized/pokemon_api.json` regenerado mediante `DataImporter`;
- nueva `DataV3DamageUserStatTargetTestSuite`;
- conexión de esa suite al runner Spanish/type/runtime.

No cambiaron el manifest ni los contadores estructurales observados durante regeneración.

El adaptador ahora:

1. entra solo para `meta.category == "damage-raise"`;
2. exige clase física/especial, power > 0 y `stat_changes` válidos;
3. compara el paquete generado con el paquete de la fuente antes de modificar targets;
4. retargetea únicamente los subárboles `MODIFY_STAT_STAGE` de esa familia a `self`;
5. conserva wrappers `CHANCE` semánticamente coherentes con `self` cuando contienen esos stat changes.

### Regresión permanente

`DataV3DamageUserStatTargetTestSuite` quedó ampliada para:

- leer directamente la categoría 7 del snapshot inmutable;
- exigir exactamente 28 miembros;
- verificar 28/28 presentes en el catálogo normalizado;
- verificar que 28/28 conservan stat changes ejecutables;
- verificar que todos esos `MODIFY_STAT_STAGE` usan `SELF`;
- comprobar además que Close Combat contiene Defense -1 y Special Defense -1;
- ejecutar Close Combat mediante `AuthoritativeBattleServer`;
- comprobar que baja los stages del actor, no los del rival;
- comprobar que los eventos `STAT_STAGE_CHANGED` apuntan al actor.

Prueba del bridge de regeneración antes de materializar el commit canónico:

- snapshot → raw → DataImporter → normalized: OK;
- Spanish/type/runtime: **308 PASS / 0 FAIL**;
- regresiones Close Combat: todas PASS;
- especies 1.025;
- formas 326;
- tipos 18;
- movimientos 919;
- habilidades 373;
- objetos 2.222;
- learnset entries 61.102;
- evoluciones 554;
- broken references 0;
- rejected definitions 0.

La infraestructura temporal de regeneración fue eliminada del árbol después de producir el JSON canónico. No forma parte del estado final.

### Estado de certificación

La corrección está **IMPLEMENTADA / REGENERADA / PROBADA END-TO-END EN EL BRIDGE**.

Todavía no debe etiquetarse como recertificada hasta que el HEAD final posterior a limpieza, ampliación de la regresión y documentación obtenga la matriz normal completa de CI. GitHub sigue siendo la autoridad del estado exacto de checks.

---

## Paso inmediato después de recertificar el HEAD final

Volver a C2e **sin tocar aún producción**:

1. leer el nuevo informe de `TrainerRosterRoleRealDataTestSuite` sobre DATA V3 corregido;
2. leer el nuevo informe de `TrainerRosterRoleLabelCalibrationTestSuite`;
3. leer el nuevo informe de `TrainerRosterSupportCalibrationTestSuite`;
4. comparar específicamente cuántos falsos `control/support` desaparecen al convertir los self-debuffs dañinos en SELF;
5. comprobar sentinelas que antes eran falsos support: Annihilape/Close Combat, Superpower y Hammer Arm;
6. separar la saturación que permanezca por control real (flinch/status/debuff rival) de la contaminación ya eliminada;
7. solo después decidir si `support` necesita breadth/densidad de utilidad u otra regla de etiqueta.

No cambiar `TrainerRosterRoleInference`, `TrainerTeamAnalyzer`, switching/search ni C3 antes de esa remedición.

---

## Después de cerrar C2e

Solo cuando la semántica de efectos esté recertificada y la distribución de roles sea razonablemente discriminativa:

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
- esconder bugs de DATA/Battle Core mediante excepciones privadas de Trainer AI.
