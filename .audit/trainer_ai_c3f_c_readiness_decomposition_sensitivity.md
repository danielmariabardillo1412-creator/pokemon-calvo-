

### 26.24 C3f-c — sensibilidad y descomposición del readiness actual

C3f-c se ejecuta después de certificar C3f-b con una pregunta más estricta que “qué fórmula distribuye mejor”: comprobar si existe base semántica suficiente para comprimir HP, retención de rutas PP y disponibilidad inmediata por status en un único `operational_readiness_bp`.

#### Baseline certificado

Baseline documental humano:

`cb04ffb945566623a872a746fb8cbdfbe02f5fce`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- C3f-b estaba certificado con FASE33 **423 PASS / 0 FAIL**;
- `selected_operational_readiness_formula` seguía `null`;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Scope ejecutado

C3f-c sigue siendo exclusivamente TEST/AUDIT-ONLY.

Se añadió:

`tests/trainer_ai/trainer_roster_operational_readiness_decomposition_sensitivity_test_suite.gd`

y se sustituyó una única línea del runner para ejecutar esta suite como heredera de C3f-b.

No se modificó producción.

La suite preserva todos los checks C3f-a/C3f-b y añade una representación explícita de cuatro señales:

1. `hp_state_bp`;
2. `route_retention_bp`;
3. `immediate_status_action_bp`;
4. `attrition_pressure_bp`.

El cuarto componente se mantiene deliberadamente fuera de la tupla de capacidad inmediata porque necesita horizonte.

#### Cinco blends razonables auditados

Se compararon cinco vecindades de pesos test-only, todas normalizadas a 10000 bp:

- `hp_heavy_60_20_20`;
- `baseline_55_25_20`;
- `route_heavy_45_35_20`;
- `status_heavy_45_25_30`;
- `capability_heavy_40_30_30`.

También se mantuvo el producto puro de los tres componentes inmediatos como contraste.

Ningún conjunto de pesos queda seleccionado como canónico.

#### Reversión de ranking por pesos — demostración exacta

Se construyeron dos estados sintéticos:

A:

- HP = 4000;
- route retention = 10000;
- status action = 10000.

B:

- HP = 8000;
- route retention = 6000;
- status action = 6000.

Con blend `60/20/20`:

- A = 6400;
- B = 7200;
- B > A.

Con blend `40/30/30`:

- A = 7600;
- B = 6800;
- A > B.

Por tanto dos elecciones de pesos razonables pueden **invertir el orden estratégico de los miembros** sin que cambie ninguna evidencia subyacente.

Esto impide justificar ahora una selección de pesos como si fuera una consecuencia objetiva del runtime.

#### Colisión semántica del blend

Bajo `55/25/20` se demostraron dos estados distintos que producen exactamente 8000 bp:

A:

- HP 10000;
- route 10000;
- status action 0.

B:

- HP 10000;
- route 2000;
- status action 10000.

El primero conserva HP y rutas pero no puede actuar ahora; el segundo puede actuar pero ha perdido la mayor parte de sus rutas sensibles a PP.

El scalar lineal los colapsa al mismo valor aunque semánticamente no sean intercambiables.

#### Colisión semántica del producto

El producto también pierde información.

A:

- HP 5000;
- route 10000;
- status 10000.

B:

- HP 10000;
- route 5000;
- status 10000.

Ambos producen 5000 bp bajo producto pese a representar degradaciones distintas.

Por tanto el problema no se resuelve sustituyendo blend por multiplicación.

#### Desacuerdo extremo cuando un componente llega a cero

Con los otros dos componentes en 10000:

- status action = 0 -> blend baseline = 8000, producto = 0;
- route retention = 0 -> blend baseline = 7500, producto = 0;
- HP = 0 -> blend baseline = 4500, producto = 0.

Esto expone una diferencia conceptual grande:

- un blend puede mantener un score alto aunque el miembro no pueda actuar ahora;
- el producto puede colapsar a cero un activo estructuralmente intacto que solo está temporalmente dormido.

C3f-c no encuentra base canónica para decidir cuál de esas interpretaciones debe representar un único scalar.

#### Monotonicidad

Todos los blends auditados y el producto sí cumplen las invariantes locales básicas:

- subir HP no reduce score;
- restaurar PP no reduce score;
- curar un status no reduce score.

La ausencia de problemas de monotonicidad no basta, sin embargo, para seleccionar una fórmula: las colisiones y las inversiones de ranking siguen presentes.

#### Sleep demuestra por qué debe conservarse la descomposición

En el fixture de sleep:

- `hp_state_bp = 10000`;
- `route_retention_bp = 10000`;
- `immediate_status_action_bp = 0`.

El blend baseline devuelve 8000; el producto devuelve 0.

La tupla descompuesta conserva toda la información relevante sin obligar a elegir prematuramente entre esas dos interpretaciones.

#### Attrition permanece separado

Un miembro sano y el mismo miembro poisoned pueden tener idéntica tupla inmediata:

- mismo HP actual;
- misma retención de rutas;
- misma disponibilidad de acción inmediata.

Pero poison tiene `attrition_pressure_bp > 0`.

Esto demuestra que la presión de desgaste es una cuarta señal independiente del readiness inmediato y no debe introducirse silenciosamente en el scalar sin una definición de horizonte.

#### Held item sigue fuera de los componentes numéricos

Cambiar únicamente `held_item_consumed` no altera:

- `hp_state_bp`;
- `route_retention_bp`;
- `immediate_status_action_bp`;
- `attrition_pressure_bp`.

El estado del item sigue siendo evidencia estructurada, no una penalización genérica certificada.

#### Muestreo real DATA V3

C3f-c ejecutó además un muestreo determinista de **128 miembros** de DATA V3 (`stride=8`).

La degradación del probe alternó de forma determinista:

- cuatro niveles de HP: 25%, 50%, 75%, 100%;
- agotamiento del primer move en muestras alternas;
- burn, paralysis o sin status en ciclo de tres.

El objetivo no es simular una distribución real de torneo, sino verificar sensibilidad de los agregados sobre estados diversos construidos desde miembros canónicos reales.

Se obtuvieron **97 tuplas inmediatas distintas**.

Medias por agregador:

- `hp_heavy_60_20_20`: **7053 bp**;
- `baseline_55_25_20`: **7227 bp**;
- `route_heavy_45_35_20`: **7576 bp**;
- `status_heavy_45_25_30`: **7291 bp**;
- `capability_heavy_40_30_30`: **7465 bp**;
- producto: **4128 bp**.

Spread entre medias:

**3448 bp**.

Mínimos observados:

- hp-heavy: 3862;
- baseline: 4088;
- route-heavy: 4539;
- status-heavy: 4343;
- capability-heavy: 4569;
- producto: 853.

Todos alcanzaron 10000 en algún estado.

La magnitud de la divergencia sobre los mismos miembros vuelve a confirmar que la elección del agregador tendría consecuencias conductuales sustanciales.

#### SHA técnico C3f-c

SHA técnico:

`ba9b87d79f51f0384856ccdc4e177bed5f2dfa61`

Diff desde 26.23:

- nueva suite C3f-c: **354 líneas**;
- runner: **1 línea cambiada**;
- producción: **0 cambios**.

Sobre ese SHA exacto:

- **18/18 workflows SUCCESS**;
- FASE33: **443 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA Foundation V3: SUCCESS.

#### Certificación humana tree-identical

SHA humano C3f-c:

`df5f21c410df0ae8b560ee87e05f23f662f99722`

Su árbol es idéntico al SHA técnico C3f-c.

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: SUCCESS;
- Godot 4.7: SUCCESS;
- DATA Foundation V3: SUCCESS.

C3f-c queda **CERTIFICADO**.

#### Decisión de arquitectura

C3f-c NO autoriza todavía `operational_readiness_bp`.

La evidencia acumulada C3e -> C3f-c favorece una interfaz de producción descompuesta antes que un scalar agregado:

- `hp_state_bp` es objetivo y directo;
- `route_retention_bp` está certificado como alternativa semánticamente superior al PP medio;
- `immediate_status_action_bp` captura la degradación de acción actual con dependencia de rol;
- attrition debe conservarse como evidencia/horizonte separado;
- held item debe conservarse como evidencia hasta tener valoración específica.

La descomposición conserva información que todos los scalars auditados pierden.

#### Siguiente microtranche autorizada — C3f-d

**C3f-d — producción de componentes de readiness actual, SIN scalar agregado.**

Debe crear una superficie de producción separada y auditable para extraer, por miembro propio:

- `hp_state_bp`;
- `route_retention_bp`;
- `immediate_status_action_bp`;
- evidencia estructurada de attrition, incluyendo como mínimo la pérdida del siguiente tick cuando sea definible, pero sin convertirla en readiness proyectado;
- `held_item_id` + `held_item_consumed` como evidencia sin penalización genérica;
- breakdown suficiente para auditar qué rutas PP sustentan cada rol y qué status runtime produjo el factor de acción.

La preferencia arquitectónica es una clase separada de `TrainerRosterStrategicValueEvaluator`, para no mezclar valor estructural y degradación operativa.

La API NO debe exponer:

- `operational_readiness_bp` agregado;
- pesos de blend;
- producto agregado;
- readiness post-recovery;
- replacement expectation;
- `permadeath_loss_cost_bp`.

Regresiones mínimas obligatorias:

- paridad con la evidencia/semántica C3f-a/b/c;
- HP monotónico;
- PP route-aware y redundancia;
- burn físico/especial;
- paralysis dependiente de Speed;
- sleep/freeze;
- poison/toxic como attrition separado;
- held item evidence-only;
- exclusión de stat stages y volátiles;
- no mutación;
- determinismo;
- JSON serialization;
- null catalog fail-closed;
- ausencia de rival/belief/profile/RNG/campaign policy.

Sigue prohibido durante C3f-d:

- seleccionar o exponer `operational_readiness_bp` agregado;
- inventar `between_battle_recovery_policy`;
- inventar `replacement_policy`;
- implementar `permadeath_loss_cost_bp`;
- integrar campaign-value en switching/search;
- iniciar FASE34;
- mergear PR #105.
