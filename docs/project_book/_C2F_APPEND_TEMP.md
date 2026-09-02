---

### 26.15 C2f — `TrainerTeamAnalyzer` consume inferencia en Random Cup

C2f queda **IMPLEMENTADO Y CERTIFICADO** como tranche aislada posterior a la estabilización de `TrainerRosterRoleInference`.

#### Problema auditado

El `TrainerTeamAnalyzer` histórico contaba directamente `TrainerPokemonLoadout.role_id` y su `synergy_score` premiaba, entre otras cosas:

- diversidad de roles authored;
- presencia authored de `support`;
- presencia authored de `fast_attacker`;
- combinación authored de presión física y especial.

Esa semántica sigue siendo válida para equipos históricos/authored y para `TrainerTeamComposer`, pero no puede actuar como autoridad de capacidades en Random Cup.

La auditoría confirmó además que `TrainerTeamComposer` usa `TrainerTeamAnalyzer.analyze()` dentro de su búsqueda greedy. Por tanto, sustituir globalmente la semántica de `analyze()` habría mezclado C2f con la futura retirada/reorientación del Composer y habría roto la separación de responsabilidades congelada en 21.13/22.7.

#### Implementación aislada

SHA de código C2f:

`61b839cb78d15c29c8fa5a8fe62eadda2118be90`

El diff neto desde el checkpoint documental certificado anterior `ba97648cec7777aa747c2c4a95fd0836617a3e57` queda limitado a tres archivos:

- `modules/trainer_ai/trainer_team_analyzer.gd`;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd`;
- `tests/trainer_ai/trainer_team_random_cup_analysis_test_suite.gd`.

`TrainerTeamComposer` **NO fue modificado**.

`TrainerTeamAnalyzer` conserva:

`analyze(team)`

con la semántica authored histórica.

Se añade explícitamente:

`analyze_random_cup(team)`

con modelo:

`trainer_team_analysis_random_cup_v1`.

La ruta Random Cup:

1. materializa cada `TrainerPokemonLoadout` mediante `TrainerLoadoutFactory`;
2. convierte el `CreatureInstance` materializado a la frontera `Dictionary`;
3. llama a `TrainerRosterRoleInference.infer_role_scores()`;
4. no replica fórmulas de daño, bulk ni support dentro del Analyzer;
5. agrega el vector multirole completo en vez de reducir cada miembro a una etiqueta exclusiva.

#### Agregación Random Cup

Roles inferidos agregados:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `bulky_physical`;
- `bulky_special`;
- `support`.

`balanced` **no se trata como capacidad**.

Se conserva como señal continua:

- `role_score_sums_bp`;
- `role_max_scores_bp`;
- `member_role_inference`.

Se usa el umbral ya calibrado de:

`STRONG_ROLE_BP = 7500`

únicamente para resumir **presencia fuerte**, no para borrar secundarios.

El resultado expone:

- `role_counts` de presencia fuerte;
- `absent_strong_roles`;
- `unique_strong_roles`;
- `redundant_strong_roles`;
- `inferred_member_count`;
- `uninferred_member_indices`;
- breakdown por miembro con `role_scores_bp`, `role_model_id` y `support_model_id`.

El `synergy_score` Random Cup reutiliza los componentes no relacionados con roles del Analyzer histórico —tipos, cobertura, debilidades/resistencias y redundancia de tipado— y reemplaza solo la contribución authored de roles por la contribución derivada de presencia fuerte inferida.

#### Compatibilidad demostrada

La nueva suite `TrainerTeamRandomCupAnalysisTestSuite` hereda `TrainerTeamCompositionTestSuite` y ejecuta primero todas las regresiones históricas de FASE33.

Regresiones C2f añadidas:

- modelo Random Cup registrado;
- modelo authored preservado;
- todos los miembros válidos inferidos;
- análisis no muta el equipo;
- threshold fuerte = `7500`;
- sumas/máximos/counts agregados coinciden con el breakdown de miembros;
- absent/unique/redundant forman una partición completa de roles;
- `balanced` no se promociona a capacidad;
- la ruta authored sigue reaccionando a `role_id`;
- la ruta Random Cup ignora cambios de `role_id` cuando stats/moveset reales no cambian;
- cambiar el moveset real sí cambia la inferencia;
- determinismo;
- serialización JSON;
- input nulo falla cerrado.

Prueba adversarial clave:

- mismo roster y mismos loadouts objetivos;
- todos los `role_id` se relabelan a `balanced`;
- `analyze()` histórico cambia su lectura de roles;
- `analyze_random_cup()` produce exactamente el mismo resultado que antes.

Esto demuestra que Random Cup ya no depende de la etiqueta authored.

Prueba de causalidad objetiva:

- se cambia realmente el moveset del primer miembro a una ruta especial;
- su `physical_attacker` inferido cae a `0`;
- aparece señal `special_attacker`;
- el análisis Random Cup cambia.

#### Certificación exacta

Sobre el SHA:

`61b839cb78d15c29c8fa5a8fe62eadda2118be90`

resultado confirmado:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition / FASE33: **269 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- Trainer Loadouts: SUCCESS;
- switching/search y demás gates históricos: SUCCESS;
- PR #105: abierto y sin merge;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, no movido.

Por tanto, **C2f queda CERTIFICADO**.

#### Estado de arquitectura tras C2f

Cerrado/certificado:

- C1 campaign seam;
- C1b controller transport;
- C2a fixtures;
- C2b evidencia intrínseca;
- C2c scores multirole;
- C2d auditoría real-data;
- C2e calibración de labels/control/support;
- C2f consumo de role inference por `TrainerTeamAnalyzer` en Random Cup.

Todavía **NO**:

- integrar switching/search con valor persistente;
- iniciar `TrainerRosterStrategicValueEvaluator` sin revisar antes sus dependencias/políticas abiertas;
- iniciar FASE34;
- convertir `TrainerTeamComposer` en selector Random Cup;
- mergear PR #105 a `main`.

#### Siguiente paso

Antes de implementar C3 debe hacerse una **auditoría de entrada de C3** contra el estado real ya cerrado:

- recuperar el contrato de `TrainerRosterStrategicValueEvaluator`;
- separar qué parte de `structural_value_bp` ya puede implementarse con C2f;
- identificar qué parte de `permadeath_loss_cost_bp` continúa bloqueada por `replacement_policy`, recuperación persistente u otras reglas de gameplay aún abiertas;
- revisar si existe ya algún `TrainerTeamStrategicEvaluator` histórico reutilizable o si su semántica pertenece a otro problema;
- no tocar switching/search hasta tener esa frontera documentada y testeable.

La siguiente tranche, por tanto, es **auditoría C3 previa a código**, no implementación automática de loss-cost con defaults inventados.
