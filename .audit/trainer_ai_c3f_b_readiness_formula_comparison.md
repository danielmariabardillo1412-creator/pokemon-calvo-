

### 26.23 C3f-b — comparación TEST/AUDIT-ONLY de fórmulas de readiness actual

C3f-b se ejecuta después de C3f-a con una restricción explícita: comparar composiciones posibles de la evidencia operativa ya certificada sin exponer todavía `operational_readiness_bp` en producción.

#### Baseline certificado

Baseline documental humano de C3f-a:

`0b1c858c9bb7b53f2079701ab1c8f650a9ad66e3`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- C3f-a mantenía la evidencia operativa exclusivamente en tests;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Scope ejecutado

Se añadió únicamente una suite test-only:

`tests/trainer_ai/trainer_roster_operational_readiness_formula_comparison_test_suite.gd`

y una sustitución de una línea en:

`tests/trainer_ai/trainer_team_composition_test_runner.gd`

No se modificó ninguna clase de producción.

La comparación usa seis familias deliberadamente distintas:

1. `hp_only`;
2. `naive_mean_pp_blend`;
3. `route_retention_blend`;
4. `route_action_status_blend`;
5. `route_action_status_product`;
6. `active_tick_assumption_product`.

Ninguna de ellas queda seleccionada como fórmula canónica. El reporte conserva explícitamente:

`selected_operational_readiness_formula: null`

#### Controles negativos útiles

`hp_only` confirma que HP por sí solo no puede representar agotamiento de PP ni status.

`naive_mean_pp_blend` confirma el defecto ya descubierto en C3f-a: un promedio bruto de PP no representa la capacidad operativa que realmente sigue disponible.

En DATA V3 real se detectaron **72 casos** en el muestreo donde el promedio naive penaliza al miembro aunque la representación route-aware comprueba que una ruta redundante equivalente conserva la capacidad.

La suma de diferencia `route_retention_blend - naive_mean_pp_blend` sobre esos escenarios de agotamiento fue:

`66,462 bp`

No se interpreta esa suma como métrica de calidad absoluta; demuestra únicamente que ambos modelos no son semánticamente equivalentes.

#### PP route-aware — propiedad confirmada

La familia route-aware compara, por rol sensible a PP, la evidencia de capacidad total con la evidencia que sigue teniendo al menos una ruta runtime-supported disponible.

Esto permite que:

- agotar una ruta irrelevante no destruya otra capacidad;
- agotar una de dos rutas redundantes no cree una pérdida ficticia;
- agotar la única ruta que sustenta una capacidad sí reduzca su retención;
- restaurar PP nunca reduzca readiness;
- DATA_ONLY/unknown continúen fail-closed.

C3f-b refuerza por tanto la conclusión de C3f-a: la unidad correcta para PP no es el slot medio, sino la capacidad operativa conservada.

#### Burn — impacto dependiente del rol confirmado

La comparación usa la semántica runtime certificada de burn y la afinidad física/especial ya disponible.

En el muestreo real determinista:

- casos physical-dominant: **63**;
- penalización media del candidato blend: **1000 bp**;
- casos special-dominant: **50**;
- penalización media: **407 bp**.

Esto confirma que una penalización fija por `burn=true` sería incorrecta. El efecto debe depender de cuánto descansa la capacidad útil del miembro en la ruta física.

#### Paralysis — acción + dependencia de Speed

La capa test-only separa:

- probabilidad de perder acción;
- pérdida de Speed;
- dependencia real del rol `fast_attacker`.

Durante la primera ejecución se descubrió un fallo del propio fixture, no de la fórmula: se construyó `StatBlock` como si el último parámetro fuera Speed.

El contrato real de `StatBlock.new` es:

`max_hp, attack, defense, speed, special_attack, special_defense`

Por tanto los fixtures iniciales rápido/lento tenían ambos `speed=70`; los valores `200/45` habían caído en `special_defense`.

Se corrigió el fixture para colocar `200/45` en Speed y se reforzó la regresión exigiendo primero que la afinidad `fast_attacker` del fixture rápido sea realmente superior antes de comparar la penalización de paralysis.

Con esa corrección, el miembro dependiente de Speed recibe una degradación mayor, como exige la semántica del status.

#### Sleep y freeze

Bajo el contrato de estado actual:

- sleep con `turns_remaining > 0` tiene disponibilidad inmediata de acción `0`;
- freeze usa la probabilidad runtime de thaw como disponibilidad de acción actual.

Esto no pretende valorar un horizonte de varios turnos; únicamente expresa la capacidad de actuar bajo el estado presente.

#### Poison/toxic — separación obligatoria de horizonte

C3f-b confirma una frontera especialmente importante.

Para el scalar de capacidad operativa inmediata:

- poison no reduce por sí mismo la disponibilidad de la acción presente;
- toxic tampoco debe convertirse automáticamente en una pérdida inmediata de acción.

En el muestreo real:

- `poison_immediate_penalty_cases = 0`;
- bajo el candidato explícitamente condicionado a “siguiente tick activo”, `poison_active_tick_penalty_cases = 128/128`.

Por tanto la presión de attrition es real, pero depende de un horizonte. El candidato se llama deliberadamente:

`active_tick_assumption_product`

y reporta:

`attrition_candidate_requires_active_end_turn_assumption: true`

No puede promoverse silenciosamente a readiness canónico mientras no se defina qué horizonte está valorando.

#### Held item continúa fuera del scalar

`held_item_id` y `held_item_consumed` siguen siendo evidencia operativa válida, pero C3f-b no ha demostrado un valor genérico común a todos los items.

Los candidatos producen el mismo score con item disponible o consumido cuando el resto del estado es idéntico.

Esto es intencional. No se autoriza una penalización fija por item consumido.

#### Primer SHA y fallo de auditoría

Primer SHA técnico:

`d4142e896e0cb7695a9fbcd0577eae2535887f95`

Resultado:

- **17/18 workflows SUCCESS**;
- único fallo: Trainer Team Composition;
- FASE33: **421 PASS / 2 FAIL**;
- Godot general: SUCCESS;
- DATA V3: SUCCESS.

Los dos fallos eran de la suite:

1. fixture de paralysis con los argumentos de `StatBlock` en posición incorrecta;
2. la aserción `comparison_remains_test_only` exigía ausencia de la clave `selected_operational_readiness_formula`, aunque el reporte la contenía correctamente con valor `null`.

No se modificó ninguna fórmula candidata para resolver esos fallos.

La corrección fue exclusivamente test-only: **9 adiciones / 5 eliminaciones** en la suite C3f-b.

#### SHA técnico corregido

SHA técnico corregido:

`ad2b8721a7b65d244f43602f68b1a786e67b2f0e`

Sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **423 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS.

Reporte real-data determinista:

- `sample_members = 128`;
- `sample_stride = 8`;
- `naive_penalizes_but_route_preserves_cases = 72`;
- `route_minus_naive_depletion_score_delta_sum = 66462`;
- `burn_physical_dominant_count = 63`;
- `burn_physical_dominant_mean_penalty_bp = 1000`;
- `burn_special_dominant_count = 50`;
- `burn_special_dominant_mean_penalty_bp = 407`;
- `poison_immediate_penalty_cases = 0`;
- `poison_active_tick_penalty_cases = 128`;
- `held_item_in_scalar = false`;
- `selected_operational_readiness_formula = null`.

#### Certificación humana tree-identical

SHA humano final C3f-b:

`0d51894121ccfcdb9ec8bf9d1634492a099a4a4a`

Su árbol es idéntico al SHA técnico corregido.

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: SUCCESS;
- Godot 4.7: SUCCESS;
- DATA Foundation V3: SUCCESS;
- PR #105: OPEN / unmerged;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

C3f-b queda **CERTIFICADO**.

#### Qué queda demostrado y qué NO

Queda demostrado que una futura capa de readiness debe poder disponer, como mínimo, de tres componentes semánticamente distintos:

1. `hp_state_bp` / HP actual relativo;
2. `route_retention_bp` / capacidad sensible a PP que sigue operativa;
3. `immediate_status_action_bp` / degradación de la capacidad de actuar ahora, dependiente del status y del rol.

También queda demostrado que:

- HP solo es incompleto;
- PP medio naive es semánticamente defectuoso;
- PP route-aware maneja correctamente redundancia;
- burn y paralysis necesitan dependencia de rol;
- poison/toxic introducen attrition dependiente del horizonte;
- held item todavía no tiene una penalización genérica demostrada.

NO queda demostrado todavía:

- que los pesos `55/25/20` del blend sean canónicos;
- que la multiplicación pura sea preferible al blend;
- que sleep deba convertir el scalar agregado en cero;
- que un scalar único sea mejor interfaz que exponer primero subcomponentes;
- cómo incorporar attrition sin una definición explícita de horizonte;
- cómo valorar held items de forma general;
- ninguna política de recovery/replacement;
- `permadeath_loss_cost_bp`.

#### Siguiente microtranche autorizada — C3f-c

**C3f-c — sensibilidad/decomposición TEST/AUDIT-ONLY del readiness actual.**

Debe comparar la estabilidad semántica de las familias que sobrevivieron C3f-b, con especial atención a:

- blend frente a producto;
- sensibilidad a pesos razonables del blend;
- comportamiento cuando un solo subcomponente cae a cero;
- diferencia entre “capacidad inmediata” y “attrition pressure”;
- si conviene que la futura API de producción exponga primero `hp_state_bp`, `route_retention_bp` e `immediate_status_action_bp` y deje el scalar agregado sin seleccionar;
- monotonicidad al curar HP;
- monotonicidad al restaurar PP;
- monotonicidad al retirar/curar un status;
- ausencia de penalización por held item mientras no exista valoración certificada;
- determinismo y JSON serialization.

C3f-c seguirá siendo exclusivamente test/audit. No debe modificar `TrainerRosterStrategicValueEvaluator` ni ninguna otra clase de producción.

Sigue prohibido durante C3f-c:

- exponer `operational_readiness_bp` de producción;
- inventar `between_battle_recovery_policy`;
- inventar `replacement_policy`;
- implementar `permadeath_loss_cost_bp`;
- integrar campaign-value en switching/search;
- iniciar FASE34;
- mergear PR #105.
