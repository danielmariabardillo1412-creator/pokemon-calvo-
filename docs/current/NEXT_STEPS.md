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

C2e-b continúa abierto. Su primer audit descubrió una regresión semántica real de DATA V3/Battle Core, ya corregida y recertificada. La remedición posterior demuestra que la saturación de `support` persiste y **no puede atribuirse principalmente a aquel bug de datos**.

Todavía NO integrar:

- `TrainerTeamAnalyzer` con la nueva inferencia;
- switching/search con valor de campaña;
- C3 `TrainerRosterStrategicValueEvaluator`;
- FASE34 difficulty/expertise.

Referencias:

- `docs/project_book/TRAINER_AI.md`;
- `docs/project_book/DATA_V3.md`, sección 11.

---

## DATA V3 — regresión descubierta durante C2e-b y cierre

### Defecto

El conversor legado derivaba el objetivo de todos los `stat_changes` desde el `target` general del movimiento. En ataques como `close_combat`, `superpower` o `hammer_arm`, el daño se dirige al rival pero el cambio secundario de stats pertenece al usuario. El resultado anterior era un `MODIFY_STAT_STAGE target=opponent` falso que Battle Core ejecutaba literalmente sobre el rival.

La fuente inmutable `data/api/v2/move-category/7/index.json` contiene exactamente **28 movimientos** de esta familia `damage-raise`.

### Reparación

Commit canónico de adaptador + regeneración:

`a2341d4f77f22f54b89916fd8e91ac7b26d2c8d5`

El adaptador V3 ahora:

1. entra únicamente para `meta.category == "damage-raise"`;
2. exige movimiento físico/especial con `power > 0` y `stat_changes` mapeables;
3. verifica que el paquete generado coincide con la fuente antes de modificar targets;
4. retargetea únicamente esos subárboles `MODIFY_STAT_STAGE` a `self`;
5. mantiene coherentes los wrappers `CHANCE` que contienen dichos cambios.

Se regeneraron `data/raw/pokemon_api.json` y `data/normalized/pokemon_api.json` desde el snapshot inmutable; no se editaron manualmente.

Regresión permanente:

`DataV3DamageUserStatTargetTestSuite`

Protege:

- categoría 7 exacta de 28 miembros;
- 28/28 presentes en el catálogo normalizado;
- 28/28 con stat changes ejecutables;
- todos sus `MODIFY_STAT_STAGE` apuntando a `SELF`;
- Close Combat exacto: Defense -1 y Special Defense -1;
- ejecución real mediante `AuthoritativeBattleServer`: baja al actor, no al rival;
- eventos `STAT_STAGE_CHANGED` emitidos sobre el actor.

### Recertificación DATA V3

HEAD exacto ya certificado:

`816c8ab1d1a9b0936ccf07bf454b94a13d2a257e`

Resultado:

- **18/18 workflows SUCCESS**;
- DATA domain: **567 PASS / 0 FAIL**;
- Spanish/type/runtime: **314 PASS / 0 FAIL**;
- 1.025 especies;
- 326 formas;
- 18 tipos;
- 919 movimientos;
- 373 habilidades;
- 2.222 objetos;
- 61.102 learnset entries;
- 554 evoluciones;
- broken references: **0**;
- rejected definitions: **0**;
- source provenance: `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`.

DATA V3 vuelve por tanto a estado **CERRADO / CERTIFICADO**. No continuar reabriéndolo salvo que aparezca otra regresión demostrable.

---

## C2e-b — remedición sobre DATA V3 corregido

La misma batería de Trainer AI se ejecutó sobre `816c8ab1...` después de la reparación.

Trainer Loadouts:

**305 PASS / 0 FAIL**.

### Cobertura del probe

Antes del fix:

- 1.011 especies elegibles;
- 14 sin movimientos del probe.

Después del fix:

- **1.021 especies elegibles**;
- **4 sin movimientos del probe**.

La regeneración cambia legítimamente qué últimos movimientos `level_up <= 50` pasan el filtro del probe, por lo que no debe compararse un solo contador aislado como si el roster de observación fuera idéntico.

### C2d corregido — forma multirole

Histograma de roles `>=7500`:

- 0 roles: 19;
- 1: 123;
- 2: 295;
- 3: 289;
- 4: 191;
- 5: 94;
- 6: 10.

Empates en el máximo:

- máximo único: 524;
- empate de 2: 420;
- empate de 3: 55;
- empate de 4: 14;
- empate de 5: 8.

Medianas absolutas de bulk:

- físico: 13.050;
- especial: 12.750.

`support` sobre el dataset corregido:

- `==10000`: **441**;
- `>=7500`: **444**;
- media: **5233**;
- cero: **129**.

La separación arquitectónica se mantiene:

- `role_scores_bp` = afinidad/forma relativa;
- `intrinsic_evidence` = magnitud objetiva;
- C3 deberá consumir ambas, no convertir afinidad en fuerza.

### C2e-a corregido — candidatos primarios

Sobre 1.021 especies elegibles:

- empates múltiples en esquema plano: **497**;
- empates múltiples entre candidatos core sin `fast_attacker`: **397**;
- primario core único: **624**;
- margen >=500: **572**;
- margen >=1000: **462**;
- margen >=1500: **360**;
- top >=7500 y margen >=1000: **455**;
- `fast_attacker == best_offense`: **320**;
- `fast_attacker >=7500`: **438**.

Distribución provisional de primarios únicos core:

- physical_attacker: 243;
- special_attacker: 122;
- bulky_physical: 81;
- bulky_special: 75;
- support: **103**.

`support` colisiona en el máximo con otro rol en **338** especies.

Conclusión sobre `fast_attacker`: sigue siendo razonable tratarlo como descriptor funcional compuesto/secundario en vez de competidor primario plano. Esto todavía no congela thresholds runtime.

### C2e-b corregido — saturación de support

Sobre 1.021 especies elegibles:

- support > 0: **892**;
- support >=7500: **444**;
- support ==10000: **441**;
- support máximo único: **103**;
- support empatado en el máximo: **338**;
- colisión con ofensiva: **201**;
- colisión con bulk: **164**;
- support >=7500 coexistiendo con ofensiva >=7500: **357**;
- support ==10000 coexistiendo con ofensiva >=7500: **354**.

Fuentes de utilidad:

- control-only: 762;
- sustain-only: 25;
- control+sustain: 105;
- ninguna: 129.

Entre los 441 casos `support ==10000`:

- control-only: **396**;
- control+sustain: **45**;
- sustain-only: 0;
- una sola fuente/movimiento supportive: **79**;
- múltiples movimientos supportive: **362**;
- fuente única que además es movimiento dañino: **22**.

Histogramas:

- supportive moves: `0:129, 1:275, 2:344, 3:204, 4:69`;
- control moves: `0:154, 1:303, 2:340, 3:171, 4:53`;
- damaging supportive moves: `0:213, 1:374, 2:304, 3:114, 4:16`;
- sustain moves: `0:891, 1:118, 2:11, 3:1`.

### Qué demuestra la comparación pre/post fix

Pre-fix → post-fix:

- support top collision: `302 → 338`;
- support ==10000: `365 → 441`;
- support máximo único: `63 → 103`;
- support ==10000 + ofensiva alta: `291 → 354`;
- fuente única max: `62 → 79`;
- fuente única dañina supportive: `35 → 22`.

No interpretar el aumento agregado como una regresión del fix: la elegibilidad y los movesets del probe también cambiaron. Lo importante es la auditoría de sentinelas y la semántica de los efectos.

### Sentinelas que confirman que la contaminación DATA desapareció

- Annihilape conserva `close_combat`, pero Close Combat ya **no** aparece como fuente supportive/control; el `support=10000` restante proviene de `screech`.
- Croconaw puede conservar `superpower`, pero Superpower ya no aporta control; la fuente supportive observada es `screech`.
- Crabominable/Crabrawler pueden incluir Close Combat, pero su control proviene de otros movimientos como `dynamic_punch`, no del autocoste de Close Combat.

Por tanto:

**el bug DATA V3 está corregido, pero la saturación de `support` es un problema real del modelo de etiquetado/control y sigue abierta.**

---

## Paso inmediato — C2e-c: auditar probabilidad y densidad de control

No tocar todavía producción ni bajar thresholds a ojo.

El siguiente bloque debe inspeccionar primero la implementación actual de:

`modules/trainer_ai/trainer_roster_role_inference.gd`

En particular:

1. cómo recorre `BattleEffectSpec.CHANCE`;
2. si multiplica correctamente la contribución de los hijos por `chance_basis_points`;
3. cómo trata control procedente de un movimiento dañino con efecto secundario;
4. si `control_signal_bp` representa probabilidad/magnitud real o simplemente alcanza 10000 por presencia de una señal fuerte;
5. cuánto control proviene de status/debuff rival/flinch garantizado frente a proc secundario probabilístico;
6. si la etiqueta `support` necesita combinar **intensidad + probabilidad + breadth/densidad de utilidad** en vez de `max(control,sustain)` puro.

Sentinelas útiles para el audit:

- `flamethrower` / burn probabilístico;
- `flame_wheel`;
- `moonblast`;
- `water_pulse`;
- `dynamic_punch`;
- `icy_wind`;
- status/debuffs puros como `screech` o `thunder_wave` para contraste.

Regla de trabajo:

- primero inspección + test-only audit C2e-c;
- assertions relacionales/monotónicas antes de thresholds exactos;
- no modificar `TrainerRosterRoleInference` hasta demostrar un defecto o una calibración necesaria con datos;
- no integrar `TrainerTeamAnalyzer`, switching/search ni C3 en esta tranche.

---

## Después de cerrar C2e

Solo cuando la distribución de roles sea razonablemente discriminativa:

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
