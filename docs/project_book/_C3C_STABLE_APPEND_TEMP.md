
### 26.18 C3c — orden léxico estable, reproducibilidad cerrada y comparación canónica

C3c detectó antes de seleccionar ninguna fórmula una contradicción entre las cifras agregadas de la auditoría defensiva C3b al repetir el mismo árbol con una suite adicional. El incidente se trató como bloqueo de calibración: mientras una auditoría usada para elegir pesos no fuera reproducible entre procesos, no se autorizaba congelar `structural_value_bp`.

#### Diagnóstico A/B y causa raíz

Se aislaron progresivamente como no causales:

- el número de clases globales registradas;
- una subclase vacía de la suite real-data;
- la mera herencia de C3b;
- el inicializador `_disjoint_helper`;
- `class_name` de la suite C3c;
- ejecutar o no ejecutar C3c antes de la auditoría disjunta.

El diagnóstico definitivo ejecutó en runners limpios los árboles exactos:

- C3b documental certificado: `e88a953c6453c373dba4692880bc870eca519876`;
- C3c previo al fix: `e8a06165222c3414dc95639dc270bb273dd1d3ac`.

El script de fingerprint se generó después del import de Godot para no alterar el registro de clases. Reconstruyó `GameData.from_dict()` tres veces dentro del mismo proceso y comparó:

- hash del JSON normalizado de entrada;
- hash de la tabla de tipos;
- orden de especies mediante `Array[StringName].sort()`;
- el mismo conjunto convertido a `String` y ordenado léxicamente;
- evidencia defensiva por especie;
- rosters de los schedules C3b;
- métricas disjuntas resultantes.

Resultado:

- el JSON de entrada permanecía idéntico;
- la tabla de tipos permanecía idéntica;
- los dos SHAs daban los mismos fingerprints al partir de procesos limpios;
- pero reconstrucciones sucesivas del mismo catálogo podían producir órdenes diferentes al ordenar `StringName` directamente;
- el mismo conjunto convertido a `String` y ordenado léxicamente era estable.

Hash léxico estable observado para el conjunto de especies:

`8993c5072020adadf7c79e9013687caff0e71dcf6e0ddca97c96ccccd6e6a68e`

Hash estable de la tabla de tipos:

`4d88ebda2100d8f67aaa5a90422b58d5634da653edf13273d4a49649078163b3`

Hash estable del JSON normalizado de entrada:

`9819bba7c6f7893994531ae1aedb86d86d293105a0cf5b42509c4f58960aa1ae`

La causa raíz era por tanto **el harness de auditoría**, no la IA de producción: C3b construía los rosters cíclicos a partir de un orden no canónico de `StringName`.

#### Corrección

Los audits C3 pasan ahora por `_lexically_sorted_species_ids()`:

1. convertir cada ID a `String`;
2. ordenar léxicamente;
3. convertir el resultado ordenado a `StringName`.

Se añadió la regresión:

`structural_real_data_species_order_is_lexical`

La suite C3c volvió además a su forma normal:

- `class_name TrainerRosterStructuralFormulaComparisonTestSuite`;
- ejecución directa desde `trainer_team_composition_test_runner.gd`;
- sin workaround de `load()` dinámico;
- sin workflows ni probes diagnósticos en el árbol final.

El scan posterior de `tests/trainer_ai` no encontró otro schedule/muestreo Trainer AI que dependa de ordenar nativamente `StringName`: los otros usos históricos de `all_ids()` recorren la población completa y no definen los ciclos/muestras marginales C3.

#### Consecuencia sobre 26.17

Las cifras numéricas de C3b registradas en 26.17 se conservan como historia del diagnóstico, pero **quedan superseded como baseline cuantitativo**.

No se invalida la conclusión semántica de 26.17:

- potencia absoluta y contribución marginal deben mantenerse separadas;
- resistencia e inmunidad deben tratarse como familias disjuntas;
- la unicidad depende del roster;
- no debe existir valor fijo por especie;
- HP actual no debe contaminar valor estructural.

Lo que cambia es el roster determinista usado para cuantificar esas relaciones.

#### C3b — métricas canónicas con scheduling léxico

Población y muestreo:

- especies totales DATA V3: `1025`;
- especies elegibles: `1021`;
- schedules: `2` (`173`, `389`);
- rosters: `2042`;
- apariciones de miembros: `12252`.

Auditoría estructural base:

- apariciones con rol fuerte único: `1540`;
- apariciones con rol fuerte redundante: `11920`;
- apariciones con cobertura ofensiva única: `6627`;
- apariciones con resistencia o inmunidad única en evidencia cruda: `7614`;
- retirada marginal: `283 / 288` casos crean nueva unicidad;
- nuevas unidades únicas acumuladas tras retirada: `1204`.

Correlaciones, en basis points:

- `role_max` vs unidades únicas totales: `564`;
- cobertura ofensiva única vs resistencia única cruda: `2273`;
- resistencia única cruda vs inmunidad única: `3897`;
- rol único vs cobertura ofensiva única: `-181`;
- rol único vs resistencia única cruda: `-68`.

Los dos schedules son cercanos:

- cobertura ofensiva única: `3308` / `3319`;
- rol único: `767` / `773`.

#### C3b — defensa disjunta canónica

Separando explícitamente:

- resistencia no inmune;
- inmunidad;

se obtiene:

- delta absoluto de unidades defensivas raw vs disjuntas: `3759`;
- apariciones con diferencia semántica defensiva: `3487 / 12252`;
- raw > disjoint: `1824`;
- raw < disjoint: `1663`;
- raw == disjoint: `8765`;
- net raw - disjoint: `107`;
- apariciones con resistencia exclusiva única: `6663`;
- apariciones low-signal sin contribución única: `53`;
- retirada marginal disjunta: `280 / 288` casos crean nueva unicidad;
- nuevas unidades únicas disjuntas tras retirada: `1100`.

Correlaciones disjuntas, en basis points:

- `role_max` vs unidades únicas totales disjuntas: `722`;
- resistencia exclusiva única vs inmunidad única: `2034`;
- cobertura ofensiva única vs resistencia exclusiva única: `2498`;
- rol único vs resistencia exclusiva única: `39`.

La conclusión defensiva se refuerza: la diferencia raw/disjoint no es ruido y debe permanecer fuera de cualquier suma ingenua.

#### C3c — familias comparadas

C3c compara cinco candidatos test-only:

1. `role_max_only`;
2. `naive_unique_units_additive`;
3. `family_presence_blend`;
4. `capped_units_blend`;
5. `guarded_family_bonus`.

Base absoluta común para los blends/contextuales:

`absolute_capacity_bp = round((3 * role_max + role_second) / 4)`

El floor blend usado en esta primera comparación es:

`max(0.80 * absolute, 0.70 * absolute + 0.30 * context)`

La prueba sigue siendo **AUDIT/TEST-ONLY**: estos pesos no son todavía contrato de producción.

#### Candidatos descartados por la auditoría canónica

`role_max_only`:

- media: `9736`;
- techo `10000`: `9528 / 12252`;
- respuesta marginal positiva tras retirada: `0 / 288`.

Se descarta: satura y no responde a la contribución marginal del roster.

`naive_unique_units_additive`:

- media: `9853`;
- techo: `9603`;
- respuesta marginal positiva: `101 / 288`.

Se descarta: la suma lineal de unidades únicas satura casi toda la población y destruye discriminación.

`guarded_family_bonus`:

- media: `9790`;
- techo: `8374`;
- respuesta marginal positiva: `114 / 288`.

Se descarta: aunque acota el bonus, la suma directa sobre una base absoluta ya alta continúa saturando excesivamente.

#### Dos familias supervivientes

`family_presence_blend`:

- media: `8021`;
- mínimo: `4363`;
- techo: `35`;
- `>= 7500`: `10150`;
- `>= 9000`: `1249`;
- strong-role-redundant mean: `8074`;
- moderate-unique mean: `6086`;
- low-signal/no-unique mean: `5379`;
- floor violations: `0`;
- retirada marginal positiva: `201 / 288`;
- casos negativos tras retirada: `0`;
- delta positivo acumulado: `209671`;
- máximo delta positivo: `3921`;
- medias por schedule: `8011` / `8032`.

`capped_units_blend`:

- media: `7800`;
- mínimo: `4363`;
- techo: `7`;
- `>= 7500`: `9533`;
- `>= 9000`: `352`;
- strong-role-redundant mean: `7872`;
- moderate-unique mean: `5683`;
- low-signal/no-unique mean: `5379`;
- floor violations: `0`;
- retirada marginal positiva: `243 / 288`;
- casos negativos tras retirada: `0`;
- delta positivo acumulado: `199201`;
- máximo delta positivo: `2750`;
- medias por schedule: `7793` / `7807`.

Ambos sobreviven esta ronda porque:

- conservan suelo de capacidad absoluta;
- no producen delta marginal negativo al retirar un compañero;
- reconocen nueva unicidad;
- no dan bonus contextual a low-signal/no-unique;
- mantienen la invariancia de 1 HP;
- un KO puede cambiar el contexto de supervivientes;
- limitan la saturación;
- muestran estabilidad entre los dos schedules.

`capped_units_blend` queda **mejor posicionado**, pero todavía no congelado: tiene solo `7` techos frente a `35`, responde en `243` retiradas frente a `201` y distingue cantidad marginal dentro de una familia hasta caps explícitos, sin breadth ilimitado.

#### Reproducibilidad y certificación técnica

El fix y C3c quedaron en el árbol humano exacto:

`7552445cfec68f4fb6ed6d639c17184ed0e44651`

Sobre ese SHA:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition primera ejecución: **338 PASS / 0 FAIL**;
- el mismo job se reruneó deliberadamente sobre el mismo SHA;
- segunda ejecución: **338 PASS / 0 FAIL**;
- los JSON C3b base, C3b disjunto y C3c fueron numéricamente idénticos entre ambas ejecuciones;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- producción C3a: sin modificaciones;
- `main`: no movido;
- PR #105: abierto y sin merge.

Por tanto, el incidente de reproducibilidad queda **CERRADO** y `7552445c...` es el baseline técnico canónico de C3c tras estabilizar el harness.

#### Siguiente microtranche autorizada

Antes de llevar una fórmula a producción, realizar una única ronda test-only de **sensibilidad local alrededor de `capped_units_blend`**.

Objetivo: comprobar que su ventaja no depende de un punto arbitrario demasiado fino de pesos.

La exploración debe ser pequeña y explicable, no una búsqueda masiva de hiperparámetros. Como mínimo debe variar de forma controlada:

- peso de contexto frente a capacidad absoluta alrededor del `30%` actual;
- caps/peso de las cuatro familias marginales sin cambiar su semántica;
- conservar el floor absoluto;
- comparar saturación, respuesta marginal, estabilidad entre schedules y sentinelas.

No se elegirá una variante solo porque maximice una métrica aislada. Debe existir una región estable de comportamiento razonable.

Sigue prohibido en la siguiente microtranche:

- modificar producción para devolver `structural_value_bp`;
- implementar `operational_readiness_bp` como sustituto;
- implementar `permadeath_loss_cost_bp` definitivo;
- inventar `replacement_policy` o `between_battle_recovery_policy`;
- integrar switching/search;
- iniciar FASE34;
- mergear PR #105.
