

### 26.22 C3f-a — evidencia operativa actual TEST/AUDIT-ONLY

C3f-a ejecuta la autorización de 26.21 sin adelantar el scalar. Su objetivo es demostrar qué degradación operativa presente puede medirse de forma auditable antes de comparar fórmulas de `operational_readiness_bp`.

#### Baseline y certificación

Baseline humano C3e:

`604ff9dfdc564f14a33553b68fe5286ab014db32`

C3f-a técnico:

`78e2d7cf535c45b9bb92c24e0247195fd19d1faf`

C3f-a humano tree-identical certificado:

`8023b1ccc670eeeecb597516b6e5310eebe9de57`

Sobre el SHA humano exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- FASE33 / Team Composition: **396 PASS / 0 FAIL**;
- Godot 4.7 general: SUCCESS;
- DATA V3: SUCCESS.

El net diff funcional de C3f-a contra C3e es exclusivamente de tests:

- `tests/trainer_ai/trainer_roster_operational_evidence_audit_test_suite.gd` — suite nueva;
- `tests/trainer_ai/trainer_team_composition_test_runner.gd` — una sustitución de runner para heredar C3d y añadir C3f-a.

**No hay cambios de producción.**

#### Modelo de auditoría

La suite introduce únicamente en tests:

`trainer_roster_current_operational_evidence_audit_v1`

No existe todavía un `operational_readiness_bp` de producción ni test-only congelado.

Para cada vista propia, la evidencia conserva:

- `instance_id`;
- `species_id`;
- estado KO actual;
- HP actual, máximo y `hp_ratio_bp`;
- PP por movimiento runtime-supported;
- disponibilidad de cada ruta por `current_pp > 0`;
- movimientos agotados;
- movimientos DATA_ONLY/excluidos;
- movimientos desconocidos;
- afinidad de cada ruta PP con roles sensibles;
- status persistente y parámetros runtime públicos;
- held item presente/consumido/disponible;
- lista explícita de campos transitorios excluidos.

La salida es determinista y JSON-serializable.

#### HP queda como señal directa

C3f-a prueba el ratio presente:

`hp_ratio_bp = current_hp / max_hp`

con clamp seguro.

También prueba KO como estado operativo sin convertirlo en un scalar C3 nuevo.

Esto preserva la separación ya certificada:

- HP puede degradar readiness presente;
- HP no reescribe `structural_value_bp`.

#### PP se conserva por ruta, no como media del moveset

Para cada movimiento runtime-supported se registra:

- `move_id`;
- `current_pp`;
- `max_pp`;
- `pp_ratio_bp`;
- `pp_state_valid`;
- `available`;
- `damage_class`;
- `power`;
- `type_id`.

Un estado PP inválido falla cerrado:

- no se considera disponible;
- `pp_ratio_bp = 0`;
- no crea capacidad ficticia.

Los movimientos desconocidos o no runtime-supported quedan separados y tampoco crean readiness ficticio.

#### Afinidad de rol por ruta PP

C3f-a no inventa una clasificación PP nueva. Para cada movimiento runtime-supported construye una vista de un solo movimiento y reutiliza `TrainerRosterRoleInference` ya certificado.

Se conservan máximos de afinidad para roles donde PP puede cortar capacidad ejecutable:

- `physical_attacker`;
- `special_attacker`;
- `fast_attacker`;
- `support`.

Se calculan dos familias de evidencia:

1. máximo de afinidad disponible en todas las rutas runtime del moveset;
2. máximo de afinidad que todavía conserva al menos una ruta con PP.

La segunda nunca puede superar a la primera: la suite certifica esta monotonicidad.

#### Hallazgo clave — la media de PP colisiona semánticamente

C3f-a construye dos estados del mismo miembro:

A. ruta física agotada + support lleno;

B. ruta física llena + support agotado.

En ambos casos una media bruta del PP de los dos slots da exactamente:

`5000 bp`.

Sin embargo las capacidades disponibles no son equivalentes.

La evidencia route-aware demuestra simultáneamente que:

- A conserva menos afinidad disponible de `physical_attacker` que B;
- A conserva más afinidad disponible de `support` que B.

Por tanto queda demostrado con regresión ejecutable que:

**`mean(current_pp/max_pp)` del moveset NO es una medida válida de readiness operativo.**

No se debe volver a introducir esa simplificación en C3f-b o producción.

#### Status persistente se conserva con semántica runtime, no con penalización genérica

La suite certifica evidencia estructurada para:

- burn: multiplicador físico 5000 bp + divisor residual 16;
- paralysis: Speed 5000 bp + skip 2500 bp;
- poison: divisor residual 8;
- badly poisoned: divisor 16 + `toxic_counter` actual;
- sleep: `turns_remaining`;
- freeze: thaw 2000 bp.

Esto permite a la futura comparación de fórmulas utilizar consecuencias runtime reales.

C3f-a **no** asigna una penalización uniforme por status.

#### Held item queda deliberadamente como evidencia cruda

Se registra:

- `item_id`;
- presencia;
- `consumed`;
- `available`.

Se prueba explícitamente que un item consumido deja de estar disponible.

No se genera `generic_penalty_bp` ni otra equivalencia universal porque C3f-a no ha demostrado que todos los held items tengan un valor comparable.

#### Estados transitorios excluidos

C3f-a excluye expresamente:

- `stat_stages`;
- `status_state.volatile`.

Además prueba que añadir o retirar esos datos transitorios **no cambia la salida de evidencia persistente**.

La razón sigue siendo la frontera de 26.21: `reconcile_post_battle()` los elimina y ya pertenecen al horizonte táctico de Battle.

#### Seguridad semántica

La evidencia C3f-a no contiene ni consume:

- `operational_readiness_bp`;
- `permadeath_loss_cost_bp`;
- `campaign_snapshot` como fuente de política;
- `between_battle_recovery_policy`;
- `replacement_policy`;
- oponente;
- beliefs;
- TrainerProfile;
- RNG.

Por tanto no adelanta reglas de campaña inexistentes.

#### Conclusión C3f-a

C3f-a demuestra que el estado operativo presente tiene cuatro familias conceptualmente distintas:

1. **supervivencia presente** — HP;
2. **capacidad ejecutable restante** — rutas PP todavía disponibles y su afinidad funcional;
3. **degradación persistente con efectos runtime** — status;
4. **recurso equipado persistente** — held item disponible/consumido, todavía sin valor escalar certificado.

No existe evidencia para colapsar las cuatro con una media simple.

Especialmente PP necesita una representación sensible a la ruta/capacidad, no al número de slots.

C3f-a queda **CERTIFICADO** y no modifica la fórmula estructural C3d.

#### Siguiente microtranche autorizada — C3f-b

**C3f-b — comparación TEST/AUDIT-ONLY de fórmulas candidatas para readiness operativo ACTUAL.**

Debe reutilizar la evidencia C3f-a y comparar varias familias pequeñas y explicables antes de seleccionar ninguna.

Como mínimo debe incluir controles que permitan detectar fórmulas defectuosas:

- un control `hp_only`;
- una familia que combine HP con retención route-aware de capacidad PP;
- una o más familias que incorporen status con efectos dependientes del rol/semántica;
- una variante deliberadamente ingenua basada en media PP, solo como foil, para demostrar sus colisiones.

C3f-b debe probar invariantes relacionales, no elegir por una distribución bonita:

- bajar HP no puede aumentar readiness;
- agotar una ruta runtime no puede aumentar readiness;
- restaurar PP no puede reducir readiness;
- una ruta agotada irrelevante debe afectar menos que una ruta que sostiene una capacidad fuerte, cuando la evidencia permita distinguirlo;
- burn debe penalizar más a una configuración física que a una especial comparable;
- paralysis debe reflejar degradación de velocidad/disponibilidad de acción;
- poison/toxic deben afectar supervivencia/attrition sin fingir pérdida estructural;
- sleep/freeze deben modelarse de manera explícita y conservadora, no como una constante universal sin horizonte;
- stat stages y volátiles deben seguir fuera;
- no debe cambiar `structural_value_bp`;
- no debe usar rival, beliefs, profile, RNG ni políticas de recuperación/reemplazo.

Held item seguirá **evidence-only** durante C3f-b salvo que una auditoría separada demuestre una semántica de valor suficiente para incorporarlo.

C3f-b sigue siendo TEST/AUDIT-ONLY: todavía no autoriza exponer `operational_readiness_bp` en producción.

Siguen prohibidos:

- readiness post-recuperación sin política canónica;
- `permadeath_loss_cost_bp` definitivo;
- inventar `between_battle_recovery_policy` o `replacement_policy`;
- integrar campaign-value en switching/search;
- FASE34;
- mergear PR #105.
