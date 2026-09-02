
### 26.20 C3d — `structural_value_bp` en producción

C3d porta a producción la fórmula estructural seleccionada y certificada en C3c/C3c2 sin ampliar el contrato a readiness, loss-cost ni integración táctica.

#### Certificación de código

SHA humano tree-identical certificado:

`6e80a1813904a1efb29ecc6f34ffc0cf1d9d8131`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- Trainer Team Composition: **370 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS;
- PR #105: abierto y `merged=false`;
- `main`: permanece en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

El árbol C3d añade únicamente:

- producción en `modules/trainer_ai/trainer_roster_strategic_value_evaluator.gd`;
- nueva suite `tests/trainer_ai/trainer_roster_structural_value_production_test_suite.gd`;
- runner FASE33 actualizado para ejecutar la suite nueva, que hereda y conserva todas las regresiones C3a.

No queda ningún workflow temporal ni staging auxiliar en el net diff C3d.

#### API de producción

`TrainerRosterStrategicValueEvaluator` conserva `extract_structural_evidence(own_party)` como contrato C3a y añade una capa separada:

`evaluate_structural_value(own_party: Array) -> Dictionary`

La separación es deliberada: el extractor de evidencia no adquiere semántica de campaña ni se convierte en un scalar implícito.

Modelo:

`trainer_roster_structural_value_capped_units_blend_v1`

Fórmula:

`capped_units_blend_baseline_w30_v1`

El resultado top-level expone:

- `model_id`;
- `formula_id`;
- `evidence_model_id`;
- `role_presence_threshold_bp`;
- `member_count`;
- miembros KO omitidos;
- índices inválidos omitidos;
- `member_values`.

Cada miembro superviviente expone:

- `instance_id`;
- `species_id`;
- `structural_value_bp`;
- breakdown determinista y JSON-serializable.

#### Fórmula portada literalmente

Capacidad absoluta:

`absolute_capacity_bp = round((3 * role_max_bp + role_second_bp) / 4)`

Contexto estructural usa exclusivamente contribuciones únicas del roster superviviente y mantiene cuatro familias separadas:

1. rol fuerte único;
2. cobertura ofensiva única;
3. resistencia exclusiva no inmune única;
4. inmunidad única.

Caps de producción:

- role: `2`;
- offense: `3`;
- exclusive resistance: `3`;
- immunity: `2`.

Valor por unidad:

- role: `2500 bp`;
- offense: `1000 bp`;
- exclusive resistance: `1000 bp`;
- immunity: `1500 bp`.

`context_bp` queda limitado a `10000`.

Suelo absoluto:

`absolute_floor_bp = round(0.80 * absolute_capacity_bp)`

Blend:

`blended_score_bp = round(0.70 * absolute_capacity_bp + 0.30 * context_bp)`

Resultado:

`structural_value_bp = max(absolute_floor_bp, blended_score_bp)`

con clamp final `0..10000`.

#### Defensa disjunta ya no es solo auditoría

C3d porta a producción la corrección semántica demostrada por C3b:

- primero se calcula el conjunto de inmunidades;
- `exclusive resistance = resisted - immune`;
- resistencia exclusiva e inmunidad se cuentan y particionan por separado;
- una inmunidad no puede volver a aportar simultáneamente como resistencia.

La regresión `roster_structural_value_defense_is_disjoint` demuestra explícitamente esta frontera.

#### Paridad contra la fórmula certificada

La nueva suite no se limita a comprobar rangos.

Para el fixture de producción calcula de forma independiente:

- evidencia C3a;
- normalización defensiva disjunta C3b;
- métricas C3c;
- `capped_units_blend` test-only certificado.

Después exige igualdad exacta con el `structural_value_bp` de producción.

Regresión:

`roster_structural_value_matches_selected_c3c_formula`

Resultado: **PASS**.

Por tanto el port no reinterpretó pesos, caps ni redondeos durante el paso a producción.

#### Invariantes C3d certificados

FASE33 demuestra además:

- model/formula/evidence IDs correctos;
- solo se cuentan supervivientes;
- no se muta `own_party`;
- breakdown auditable;
- mismo miembro a `1 HP` y HP completo → mismo `structural_value_bp`;
- un KO sale del roster estructural y puede cambiar el contexto de los supervivientes;
- retirar un compañero puede elevar la importancia estructural de otro por nueva unicidad;
- defensa disjunta;
- determinismo;
- JSON serialization;
- null catalog fail-closed.

La suite comprueba expresamente que C3d **no** expone:

- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`.

#### Estado de C3 después de C3d

La parte estructural de C3 queda **IMPLEMENTADA Y CERTIFICADA EN PRODUCCIÓN**.

Ya existe una respuesta estable a:

> ¿qué valor estructural objetivo aporta este superviviente al roster actual, independientemente de su HP operativo presente?

Pero todavía no existe una respuesta completa y canónica a:

> ¿cuánto cuesta perderlo permanentemente en esta campaña concreta?

Ese segundo concepto sigue bloqueado por gameplay, principalmente:

- `replacement_policy`;
- `between_battle_recovery_policy`;
- opcionalmente rondas restantes si la regla pública del modo decide exponerlas.

#### Frontera inmediata — no integrar switching/search todavía

Aunque `structural_value_bp` ya es producción real, **no se integra todavía** en `TrainerStrategicSwitchEvaluatorV2`, `TrainerSearchStateEvaluator` ni otros brains.

Motivo: usar ahora el scalar estructural como sustituto de `permadeath_loss_cost_bp` mezclaría dos conceptos que el diseño separó expresamente. Un activo estructuralmente valioso puede tener distinta urgencia de preservación según reposición, recuperación y estado operativo de campaña.

Por tanto siguen congelados:

- switching/search campaign-value integration;
- `productive_sacrifice_window` con loss-cost persistente;
- valoración desigual de KOs en search por campaña;
- FASE34;
- merge de PR #105.

#### Siguiente bloque autorizado

**C3e — auditoría read-only del contrato de `operational_readiness_bp` y de la frontera con `between_battle_recovery_policy`.**

Objetivo:

1. inventariar exactamente qué señales operativas seguras ya existen en `own_party` (`current_hp`, `max_hp`, status, PP, held item consumido u otras);
2. separar qué puede medirse como readiness **del estado actual** sin conocer reglas entre combates;
3. identificar qué semántica depende necesariamente de `between_battle_recovery_policy`;
4. decidir si puede implementarse un readiness actual separado y honesto o si debe seguir bloqueado;
5. no crear defaults de recuperación ni reposición;
6. no implementar `permadeath_loss_cost_bp` durante esta auditoría;
7. no integrar todavía switching/search.

C3d queda así **CERTIFICADO** y la siguiente acción segura vuelve a ser una auditoría de contrato, no una expansión automática de comportamiento.
