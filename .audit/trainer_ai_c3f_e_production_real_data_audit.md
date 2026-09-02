

### 26.26 C3f-e — auditoría real-data de la superficie operativa de producción

**Estado:** CERRADO / CERTIFICADO.

C3f-e se ejecutó como microtranche exclusivamente de **test/audit** para comprobar que la superficie de producción introducida en C3f-d no solo conserva la semántica en fixtures sintéticos, sino también al consumir el DATA V3 canónico a escala amplia.

#### Baseline y SHAs

- Baseline documental C3f-d / 26.25: `ff10b71cfec2e6481ac1d723a86cb032880f79d3`.
- SHA técnico C3f-e: `184ee9cc75afb14a96a710e31071dd01f8d40a43`.
- SHA humano tree-identical C3f-e: `eed5528e47776f06517a6a7f46e23132ea1ac36a`.
- Árbol técnico/humano común: `95cf27e95c400c23980adeccb333a570bf3e2ca7`.

El SHA humano fue construido sobre exactamente el mismo árbol que el SHA técnico y se certificó de nuevo por CI antes de considerar C3f-e cerrado.

#### Alcance neto

El diff de C3f-e frente a `ff10b71...` quedó limitado a **dos archivos de test**:

1. nuevo `tests/trainer_ai/trainer_roster_operational_readiness_production_real_data_audit_test_suite.gd` — **+398 líneas**;
2. `tests/trainer_ai/trainer_team_composition_test_runner.gd` — sustitución de una sola línea para ejecutar la nueva suite heredada.

No se modificó ningún archivo de producción.

En particular, C3f-e **no** cambió:

- `TrainerRosterOperationalReadinessEvaluator`;
- `TrainerRosterStrategicValueEvaluator`;
- switching estratégico;
- búsqueda/planning;
- controller/campaign integration;
- recovery/replacement;
- reglas de permadeath;
- FASE34.

#### Objetivo auditado

La suite invoca directamente la clase de producción:

`TrainerRosterOperationalReadinessEvaluator`

modelo:

`trainer_roster_current_operational_components_v1`

y compara sus salidas contra los helpers semánticos ya certificados durante C3f-a/C3f-b/C3f-c.

La condición de aceptación fue **paridad exacta, mismatch = 0**, no una distribución visualmente razonable.

#### Dataset y metodología

Se reutilizó el probe canónico real-data:

`runtime_levelup_l50_neutral_probe_v1`

sobre DATA V3 normalizado.

Cobertura principal:

- especies elegibles con moveset runtime: **1021**;
- miembros sanos auditados: **1021 / 1021**;
- entradas de movimientos runtime inspeccionadas: **4015**.

Cada uno de esos 1021 miembros fue evaluado en estado sano, HP completo, PP completo y sin status persistente. La producción debía devolver los tres componentes inmediatos en techo y conservar paridad exacta de rutas PP con la semántica certificada.

Además se construyó una muestra degradada determinista:

- stride: **8**;
- miembros: **128**;
- degradación de HP;
- degradación de PP;
- rotación de status persistente;
- active/bench;
- disponibilidad/consumo de held item.

La rotación de status cubrió:

- `burn`: 19 casos;
- `paralysis`: 18;
- `poison`: 18;
- `badly_poisoned`: 18;
- `sleep`: 18;
- `freeze`: 18;
- sin status: 19.

#### Paridad de producción

Resultado central: **todos los contadores de divergencia quedaron en cero**.

- `healthy_component_parity_mismatches = 0`;
- `healthy_route_evidence_mismatches = 0`;
- `healthy_non_ceiling_component_cases = 0`;
- `degraded_component_parity_mismatches = 0`;
- `degraded_route_evidence_mismatches = 0`;
- `attrition_bp_mismatches = 0`;
- `attrition_raw_damage_mismatches = 0`;
- `attrition_applied_damage_mismatches = 0`;
- `active_bench_application_mismatches = 0`;
- `held_item_component_mismatches = 0`;
- `blocked_output_cases = 0`.

Esto certifica que la migración de C3f-d no reinterpretó silenciosamente la semántica de las auditorías previas.

#### Diversidad observada

La muestra degradada no colapsó en unos pocos estados triviales:

- vectores inmediatos distintos: **96** sobre 128 miembros;
- `hp_state_bp`: media **6230**, mínimo **2427**, máximo **10000**;
- `route_retention_bp`: media **9512**, mínimo **6250**, máximo **10000**;
- `immediate_status_action_bp`: media **6148**, mínimo **0**, máximo **10000**.

La lectura es importante: la paridad cero no proviene de que todos los casos produzcan el mismo vector.

#### Attrition y active/bench

C3f-e verificó por separado la semántica de attrition:

- casos con attrition activo aplicado: **27**;
- casos bench que conservan fórmula de attrition pero no la aplican como tick activo actual: **28**;
- mismatches de presión en bp: **0**;
- mismatches de daño residual entero bruto: **0**;
- mismatches de daño aplicado limitado por HP actual: **0**;
- mismatches active/bench: **0**.

Por tanto, producción mantiene la distinción certificada entre:

1. que un status tenga una fórmula residual;
2. cuánto sería el próximo tick;
3. que ese tick se aplique **ahora** al miembro activo.

No se convirtió attrition en una predicción multi-turn ni en una política de campaña.

#### Held item

La disponibilidad de held item sigue siendo evidencia explícita, no un multiplicador oculto de readiness.

La auditoría alternó item disponible/consumido y obtuvo:

`held_item_component_mismatches = 0`

Los tres componentes inmediatos permanecen independientes de esa disponibilidad mientras no exista una semántica autorizada que convierta el item en valor operacional agregado.

#### Scalar deliberadamente no seleccionado

C3f-e **no** selecciona ni produce:

`operational_readiness_bp`

El reporte conserva explícitamente:

`selected_operational_readiness_formula = null`

La razón continúa siendo la demostrada por C3f-c: agregaciones razonables pueden invertir rankings y destruir información distinta con el mismo número final.

La interfaz certificada sigue siendo **component-first**:

- `hp_state_bp`;
- `route_retention_bp`;
- `immediate_status_action_bp`;
- attrition separado;
- item como evidencia separada.

#### Consumidores todavía no autorizados

El propio reporte C3f-e fija:

`consumer_integration_authorized = false`

Por tanto, cerrar C3f-e **no** autoriza todavía a introducir esta superficie directamente en:

- switching;
- search/planning;
- selección de sacrificios;
- decisiones de curación;
- lógica de campaña;
- valoración de pérdida permanente.

Antes de un consumidor real debe existir una microtranche separada que defina qué componentes puede leer, en qué horizonte y con qué invariantes, sin esconder una nueva fórmula scalar en el consumidor.

#### Límites que siguen bloqueados

Siguen fuera de alcance:

- scalar global `operational_readiness_bp`;
- `permadeath_loss_cost_bp` definitivo;
- `replacement_policy` inventada;
- `between_battle_recovery_policy` inventada;
- lectura de rival/beliefs/hidden bracket como valor objetivo del roster propio;
- integración switching/search de campaña;
- FASE34;
- merge de PR #105.

#### CI y certificación

SHA técnico `184ee9cc75afb14a96a710e31071dd01f8d40a43`:

- **18/18 workflows SUCCESS**;
- FASE33 Team Composition: **491 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

SHA humano tree-identical `eed5528e47776f06517a6a7f46e23132ea1ac36a`:

- **18/18 workflows SUCCESS**;
- FASE33 Team Composition: **491 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

El reporte real-data fue determinista y JSON-serializable en ambos SHAs.

#### Invariantes del repositorio

Durante la certificación humana se verificó de nuevo:

- PR #105: **OPEN**, `merged_at = null`;
- head de PR #105: `eed5528e47776f06517a6a7f46e23132ea1ac36a` antes del append documental;
- `main`: `f8452a1625ccb8389c9e52ff4416a96a24e00efd`, sin movimiento.

#### Conclusión de C3f-e

C3f-e cierra la duda principal posterior a C3f-d: la superficie descompuesta de readiness no solo pasa fixtures; **reproduce exactamente la semántica certificada sobre DATA V3 real**, tanto en estado sano como bajo degradaciones de HP/PP/status/attrition/item.

Esto permite considerar estable el **contrato productor** de componentes operativos actuales.

No permite aún considerar estable ningún **contrato consumidor** ni ningún scalar global.

#### Siguiente frontera prudente

La siguiente microtranche debe permanecer separada de la integración de comportamiento: diseñar y auditar un **contrato de consumo component-first** que combine la evidencia estructural y operacional sin seleccionar a escondidas un `operational_readiness_bp`, sin inventar recovery/replacement y sin conectar todavía switching/search.

Solo después de demostrar invariantes de ese contrato podrá evaluarse una integración concreta en una tranche posterior.
