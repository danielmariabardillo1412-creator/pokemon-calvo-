

### 26.25 C3f-d — producción de componentes descompuestos de readiness actual

C3f-d se ejecuta después de que C3f-c demostrase que no existe base suficiente para congelar un único `operational_readiness_bp`. La decisión de arquitectura es por tanto deliberada: llevar a producción los componentes semánticamente certificados sin destruir información mediante un agregado prematuro.

#### Baseline certificado

Baseline documental humano de C3f-c:

`36cd0460db5e0192a4a6831986d2b254c5148947`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **443 PASS / 0 FAIL**;
- C3f-c había probado inversión de ranking con pesos razonables, colisiones semánticas del blend y del producto y una dispersión de **3448 bp** entre agregados sobre los mismos 128 estados real-data degradados;
- la recomendación certificada era `decomposed_components_first`;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Scope ejecutado

Se añadió una nueva clase de producción separada del evaluador estructural:

`modules/trainer_ai/trainer_roster_operational_readiness_evaluator.gd`

Clase:

`TrainerRosterOperationalReadinessEvaluator`

Modelo:

`trainer_roster_current_operational_components_v1`

API pública:

`evaluate_current_components(own_party: Array) -> Dictionary`

La separación respecto de `TrainerRosterStrategicValueEvaluator` es intencional. El valor estructural responde a la pregunta de qué representa permanentemente un activo dentro del roster; la superficie C3f-d responde a qué parte de su capacidad está operativa **ahora**. Mezclar ambas capas habría vuelto a permitir que HP/PP/status borrasen valor estructural permanente, una contradicción que C3 había prohibido desde el diseño.

C3f-d modifica exactamente tres archivos respecto del baseline 26.24:

1. nueva clase de producción `trainer_roster_operational_readiness_evaluator.gd`;
2. nueva suite `trainer_roster_operational_readiness_production_test_suite.gd`;
3. una sustitución de una línea en `trainer_team_composition_test_runner.gd` para ejecutar la nueva suite heredando las auditorías anteriores.

No se modifica `TrainerRosterStrategicValueEvaluator`, switching, search, controller, campaign value ni ninguna política de gameplay.

#### Resultado de roster y tratamiento fail-closed

La llamada devuelve:

- `model_id`;
- `member_count`;
- `skipped_invalid_member_indices`;
- `member_components`.

Se omiten de forma fail-closed:

- entradas que no sean `Dictionary`;
- entradas sin `instance_id`;
- entradas sin `species_id`;
- especies ausentes del `DefinitionCatalog`.

Con `DefinitionCatalog == null`, la superficie devuelve un resultado vacío con el mismo `model_id` y no inventa datos.

A diferencia de la capa estructural, los miembros KO **no se eliminan**. C3f-d es una fotografía del estado operativo de cada miembro conocido: un KO permanece representado con `hp_state_bp = 0`, `is_knocked_out = true` y sin aplicar attrition activa. Eliminarlo ocultaría precisamente el estado que esta superficie debe describir.

#### Los tres componentes inmediatos de producción

Cada miembro válido expone, de forma independiente:

1. `hp_state_bp`;
2. `route_retention_bp`;
3. `immediate_status_action_bp`.

No existe un cuarto campo que los agregue.

No se produce `operational_readiness_bp`, ni blend, ni producto, ni pesos ocultos.

##### `hp_state_bp`

Representa únicamente HP actual relativo:

`current_hp * 10000 / max_hp`

con clamp del HP actual a `[0, max_hp]` y `0` si no hay un `max_hp` válido.

La suite certifica monotonicidad directa: curar HP no puede empeorar el componente.

##### `route_retention_bp`

C3f-d migra a producción la semántica route-aware certificada en C3f-a/C3f-b.

Solo participan movimientos con:

`classification == RUNTIME_SUPPORTED`

Unknown y DATA_ONLY no aportan capacidad y fallan cerrados.

Para cada movimiento runtime-supported se conserva evidencia auditable:

- `move_id`;
- `current_pp`;
- `max_pp`;
- `pp_ratio_bp`;
- validez del estado PP;
- disponibilidad actual;
- damage class;
- power;
- type;
- afinidad por rol sensible a PP.

Los roles sensibles a PP son:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `support`.

La afinidad de cada ruta reutiliza `TrainerRosterRoleInference` sobre el moveset reducido a ese movimiento. Después se calculan máximos por rol para todas las rutas y para las rutas que conservan PP.

La retención queda:

- `10000` si no existe capacidad PP-sensitive que dividir;
- en otro caso, suma de capacidad disponible / suma de capacidad total, en basis points.

Esto conserva la propiedad clave descubierta en C3f-a/b: agotar una de dos rutas redundantes no destruye ficticiamente la capacidad mientras otra ruta equivalente siga disponible.

El `breakdown.route_retention` conserva además:

- `all_pp_sensitive_role_max_bp`;
- `available_pp_sensitive_role_max_bp`;
- `runtime_move_pp`;
- movimientos disponibles;
- movimientos agotados;
- movimientos excluidos;
- movimientos desconocidos.

##### `immediate_status_action_bp`

Representa degradación de la capacidad de actuar **ahora**, no attrition futura ni recuperación posterior.

La lógica es la misma certificada en C3f-b:

- sin status: `10000`;
- burn: penalización dependiente de cuánto descansa la capacidad real en la ruta física frente a especial y del multiplicador runtime de burn;
- paralysis: combina probabilidad runtime de perder acción con degradación de Speed ponderada por dependencia real del rol `fast_attacker`;
- sleep: `0` mientras `turns_remaining > 0`;
- freeze: disponibilidad actual igual a la probabilidad runtime de thaw;
- poison/toxic: `10000` en este componente, porque no implican por sí solos pérdida de la acción presente;
- status persistente no reconocido: no se inventa modificador y queda marcado como no reconocido.

El breakdown conserva `rule_id`, efectos runtime y dependencias intermedias para que el cálculo sea auditable.

#### Attrition permanece separada del estado inmediato

C3f-d añade un bloque `attrition` estructurado, pero **no lo incorpora a ningún scalar**.

El bloque distingue explícitamente entre:

- que exista una fórmula de daño residual para el status;
- que el miembro sea el activo y esté vivo, por lo que el siguiente tick aplicaría bajo el supuesto explícito de final de turno activo;
- cuánto representa el tick respecto a `max_hp`;
- cuál sería el daño entero según el mismo redondeo del runtime;
- cuánto daño puede aplicarse realmente limitado por `current_hp`.

Campos principales:

- `active_member_required`;
- `requires_active_end_turn_assumption`;
- `next_active_tick_formula_defined`;
- `next_active_tick_applies_now`;
- `next_active_tick_loss_max_hp_bp`;
- `next_active_tick_raw_damage_hp`;
- `next_active_tick_applied_damage_hp`;
- divisor residual;
- contador toxic antes y para el próximo tick;
- `projected_readiness_included = false`.

#### Paridad exacta con el runtime residual

Antes de producir daño entero se verificó el contrato real de `StatusSystem`.

La producción C3f-d replica exactamente:

- poison: `max(1, max_hp / poison_divisor)`;
- burn: `max(1, max_hp / burn_divisor)`;
- toxic: incrementa primero el contador y luego calcula `max(1, max_hp * counter / toxic_divisor)`;
- el daño aplicado no supera HP actual.

También respeta la frontera runtime de aplicación: el residual de final de turno procesa al miembro activo vivo. Por eso un Pokémon poisoned en bench puede tener una fórmula definida, pero `next_active_tick_applies_now = false`. Lo mismo ocurre con un miembro KO.

Esto evita confundir “este status tiene presión de attrition” con “este daño se va a aplicar necesariamente en este instante”.

#### Held item: evidencia, no valoración genérica

La superficie conserva:

- `held_item_id`;
- `held_item_consumed`;
- `present`;
- `available`.

Consumir el item no cambia por sí solo `hp_state_bp`, `route_retention_bp` ni `immediate_status_action_bp`.

Sigue sin existir una penalización universal porque C3f-b/c no la demostraron y los items no tienen valor homogéneo.

#### Transitorios excluidos

C3f-d conserva la frontera ya auditada:

- `stat_stages` no entra en la capa persistente de readiness;
- `status_state.volatile` tampoco.

El output marca explícitamente:

`excluded_transient_fields = ["stat_stages", "status_state.volatile"]`

La suite comprueba que añadir stages o volatile state no cambia la salida persistente.

Esto evita mezclar una fotografía de recursos/estado persistente con condiciones tácticas efímeras de una batalla concreta.

#### Independencia de información oculta y políticas

La suite inyecta ruido externo y comprueba que el resultado no cambia ante:

- opponent;
- rival memory;
- beliefs;
- TrainerProfile;
- RNG;
- campaign snapshot.

Además recorre el output de forma recursiva y prohíbe claves que congelarían prematuramente capas bloqueadas, entre ellas:

- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`;
- `between_battle_recovery_policy`;
- `replacement_policy`;
- blend weights;
- product score;
- post-recovery readiness.

#### Suite de producción C3f-d

Nueva suite:

`tests/trainer_ai/trainer_roster_operational_readiness_production_test_suite.gd`

Hereda `TrainerRosterOperationalReadinessDecompositionSensitivityTestSuite`, por lo que ejecuta primero los **443 checks** anteriores.

Añade **29 checks** específicos de producción que cubren:

- model id y shape;
- no mutación;
- paridad directa C3f-a de rutas PP;
- paridad directa C3f-b de los tres componentes;
- monotonicidad de HP;
- redundancia de rutas;
- burn y paralysis dependientes de rol;
- sleep/freeze;
- poison/toxic;
- daño residual entero igual al runtime;
- cap de daño por HP actual;
- held items evidence-only;
- transitorios excluidos;
- KO retenido;
- diferencia active/bench;
- independencia de contexto oculto/políticas;
- fail-closed;
- determinismo;
- serialización JSON;
- ausencia de scalar/políticas prohibidas.

#### SHA técnico C3f-d

SHA técnico:

`653f1cae9a98b5d6441900fbf02690f1a4a367c6`

Sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **472 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS.

La primera implementación pasó completa; no fue necesario ningún ciclo de corrección.

#### Certificación humana tree-identical

Árbol del SHA técnico:

`43a55fa32439f67092d5bd1adda0c877d503e258`

SHA humano C3f-d:

`5fff90738b46d96a5ec6a9c1888e10d19a9e807d`

Es tree-identical al técnico.

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33: **472 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS;
- PR #105: OPEN / unmerged;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

C3f-d queda **CERTIFICADO** técnicamente.

#### Qué queda autorizado en producción y qué NO

Queda autorizada como superficie de producción independiente la lectura actual de:

1. HP relativo;
2. capacidad PP-sensitive que sigue conservando rutas runtime-supported;
3. disponibilidad inmediata de acción bajo status persistente;
4. evidencia separada de attrition del próximo tick activo cuando la fórmula está definida;
5. identidad/disponibilidad del held item sin valoración genérica.

No se autoriza todavía ningún consumidor estratégico de esa superficie.

En particular siguen bloqueados:

- un agregado `operational_readiness_bp`;
- cualquier blend/producto/pesos canónicos;
- `between_battle_recovery_policy`;
- `replacement_policy`;
- `permadeath_loss_cost_bp`;
- una estimación post-recovery;
- integración de campaign-value en switching/search;
- FASE34;
- merge de PR #105.

#### Siguiente microtranche autorizada — C3f-e

**C3f-e — auditoría real-data directa de la superficie de producción.**

C3f-a/b/c probaron la semántica con helpers audit-only y C3f-d probó paridad sintética directa al migrarla. Antes de permitir un consumidor, la siguiente barrera debe ejecutar la **clase de producción real** sobre DATA V3 real.

C3f-e será exclusivamente TEST/AUDIT-ONLY y no modificará producción.

Debe, como mínimo:

- instanciar `TrainerRosterOperationalReadinessEvaluator` sobre miembros reales DATA V3 mediante una selección determinista auditable;
- reutilizar, para comparabilidad, el muestreo de 128 miembros / stride 8 de C3f-b/c y, si el coste permite hacerlo sin degradar CI, ampliar la sonda a los 1021 elegibles;
- producir las mismas degradaciones deterministas de HP, PP, status e item;
- comparar exactamente producción frente a la semántica certificada de los helpers para `hp_state_bp`, `route_retention_bp`, `immediate_status_action_bp` y `next_active_tick_loss_max_hp_bp`;
- auditar active frente a bench para residual;
- auditar `runtime_move_pp` y afinidades de rol sobre datos reales;
- medir rangos/distribuciones sin convertirlos en criterio de selección de scalar;
- exigir determinismo y JSON serialization;
- comprobar otra vez ausencia de `operational_readiness_bp` y de políticas bloqueadas.

C3f-e no podrá introducir consumidores de producción, recovery/replacement, permadeath-loss ni FASE34.

Solo después de C3f-e deberá decidirse en un checkpoint documental si los componentes pueden exponerse a una futura capa de campaign value **sin agregarlos**, o si el avance debe detenerse hasta que las reglas de recovery/replacement estén definidas.
