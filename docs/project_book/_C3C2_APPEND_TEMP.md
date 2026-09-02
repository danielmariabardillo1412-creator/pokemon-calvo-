
### 26.19 C3c2 — sensibilidad local y selección de `structural_value_bp`

C3c2 somete al candidato mejor posicionado de C3c, `capped_units_blend`, a una vecindad local pequeña antes de autorizar su paso a producción. La intención no es optimizar la distribución contra el dataset, sino comprobar que la decisión no depende de un punto frágil de parámetros.

#### Baseline de código certificado

La suite test-only de sensibilidad quedó certificada sobre el SHA humano tree-identical:

`621c5f6d6cf28bf460ae8b6c10b3d8f1b6e58ef0`

Resultado en ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: **355 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- producción: sin modificaciones en C3c2;
- `main`: sin mover;
- PR #105: abierto y sin merge.

#### Vecindad auditada

Se comparan nueve variantes, producto de:

- peso contextual: `25%`, `30%`, `35%`;
- caps `compact`, `baseline`, `broad`.

Caps por familia:

- `compact`: role `1`, offense `2`, exclusive resistance `2`, immunity `1`;
- `baseline`: role `2`, offense `3`, exclusive resistance `3`, immunity `2`;
- `broad`: role `2`, offense `4`, exclusive resistance `4`, immunity `2`.

Todas conservan el mismo suelo absoluto y la misma separación semántica de defensa demostrada por C3b.

Las nueve variantes cumplen:

- `0` violaciones del suelo absoluto;
- `0` deltas marginales negativos tras retirar un compañero;
- respuesta positiva a cambios legítimos de unicidad;
- ningún bonus contextual para miembros low-signal sin evidencia única;
- determinismo;
- serialización JSON;
- spreads mínimos entre los schedules `173` y `389`.

#### Resultado central

`baseline_w30` reproduce exactamente el `capped_units_blend` de C3c:

- media: `7800`;
- mínimo: `4363`;
- techo `10000`: `7 / 12252`;
- `>= 7500`: `9533`;
- `>= 9000`: `352`;
- strong-role-redundant mean: `7872`;
- moderate-unique mean: `5683`;
- low-signal/no-unique mean: `5379`;
- retirada marginal positiva: `243 / 288`;
- retirada marginal negativa: `0 / 288`;
- delta positivo acumulado: `199201`;
- máximo delta positivo: `2750`;
- medias por schedule: `7793 / 7807`;
- spread entre schedules: `14 bp`.

#### Por qué no mover los parámetros

La vecindad es estable, por lo que no existe señal técnica que justifique retocar el baseline solo para mejorar una cifra agregada.

Los perfiles `compact` reducen fuertemente el extremo alto y también la respuesta marginal: con `compact_w35`, por ejemplo, el máximo cae a `9300` y solo `176 / 288` retiradas producen mejora. Eso comprime contribuciones estructurales legítimas.

Los perfiles `broad` aumentan la amplitud contextual, pero duplican los techos del baseline (`15` frente a `7`) sin corregir ningún fallo semántico observado.

`w25` responde a más retiradas y eleva más población al tramo alto, pero concede mayor influencia relativa al contexto. `w35` reduce progresivamente la respuesta marginal. `w30` queda entre ambos extremos y mantiene el comportamiento ya auditado en C3c.

Por tanto no se selecciona `baseline_w30` porque su histograma “se vea mejor”, sino porque:

1. está en el centro de una región local estable;
2. conserva la capacidad absoluta como suelo real;
3. reconoce contribución marginal sin saturación masiva;
4. no genera deltas negativos por nueva unicidad;
5. mantiene spreads mínimos entre schedules independientes;
6. no requiere una segunda recalibración para resolver ningún sentinel roto.

#### Fórmula seleccionada y congelada para C3d

Se selecciona para el futuro `structural_value_bp` de producción:

**modelo:** `capped_units_blend / baseline_w30`.

Capacidad absoluta:

`absolute_capacity_bp = round((3 * role_max_bp + role_second_bp) / 4)`

Contexto estructural:

- contar únicamente unidades **únicas** del roster actual;
- familias separadas: rol fuerte, cobertura ofensiva, resistencia exclusiva no inmune, inmunidad;
- caps: role `2`, offense `3`, exclusive resistance `3`, immunity `2`;
- normalizar el contexto capado a basis points de forma determinista, exactamente como la candidata C3c/C3c2 certificada.

Blend final:

`structural_value_bp = max(round(0.80 * absolute_capacity_bp), round(0.70 * absolute_capacity_bp + 0.30 * context_bp))`

La implementación de producción deberá portar literalmente esta semántica y demostrar equivalencia contra la fórmula test-only; no se autoriza reinterpretar pesos durante el port.

#### Límites que siguen congelados

Esta selección **solo** congela `structural_value_bp`.

Todavía NO se autoriza:

- fingir un `operational_readiness_bp` definitivo;
- exponer `permadeath_loss_cost_bp` definitivo;
- inventar `replacement_policy`;
- inventar `between_battle_recovery_policy`;
- integrar el valor estructural en switching/search;
- modificar pesos FASE31 por campaña;
- iniciar FASE34;
- mergear PR #105.

#### Siguiente microtranche autorizada

**C3d — portar la fórmula seleccionada a `TrainerRosterStrategicValueEvaluator` y exponer `structural_value_bp` con breakdown auditable.**

C3d debe ser una tranche de producción aislada:

- reutilizar la evidencia C3a, no duplicar role inference ni semántica DATA V3;
- mantener HP actual fuera del scalar estructural salvo para excluir miembros ya KO del roster superviviente;
- mismo miembro a 1 HP y a HP completo → mismo `structural_value_bp`;
- retirar un compañero puede aumentar el valor de supervivientes por nueva unicidad, pero no reducirlo por ese motivo;
- perfil, rival, beliefs y RNG no entran;
- output determinista y JSON-serializable;
- incluir componentes suficientes para auditar `absolute_capacity_bp`, unidades únicas capadas, `context_bp`, suelo y blend;
- mantener ausentes `operational_readiness_bp` y `permadeath_loss_cost_bp` hasta que sus contratos de gameplay estén resueltos.

C3c2 queda por tanto **CERTIFICADO** y `capped_units_blend / baseline_w30` queda **SELECCIONADO** como fórmula estructural para C3d.
