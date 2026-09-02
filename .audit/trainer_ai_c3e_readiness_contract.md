

### 26.21 C3e — auditoría del contrato de `operational_readiness_bp`

C3e se ejecuta como auditoría read-only de contrato después de certificar C3d. No modifica producción, no introduce un scalar nuevo y no integra campaign-value en switching/search.

#### Baseline certificado

Baseline documental humano:

`ab61ab644439e5a2527ea84ba064d0c6fa05bfa3`

Sobre ese SHA exacto:

- **18/18 workflows GitHub Actions: SUCCESS**;
- C3d estructural ya estaba certificado en producción;
- PR #105 seguía abierto y sin merge;
- `main` seguía inmóvil en `f8452a1625ccb8389c9e52ff4416a96a24e00efd`.

#### Señales operativas ya disponibles de forma segura

`TrainerObservationBuilder` construye `own_party` a partir de `CreatureInstance.to_dict()` y por tanto la IA propia dispone, sin leer `BattleState` ni referencias mutables, de:

- `current_hp`;
- `stats.max_hp`;
- `moveset[].move_id`;
- `moveset[].current_pp`;
- `moveset[].max_pp`;
- `status_state.persistent_id`;
- `status_state.turns_remaining`;
- `status_state.toxic_counter`;
- `status_state.volatile`;
- `stat_stages`;
- `held_item_id`;
- `held_item_consumed`;
- identidad, especie, nivel, stats y moves conocidos del propio roster.

La observación propia es completa; esta evidencia no requiere rival, beliefs, memory, profile ni RNG.

#### Qué persiste realmente al salir de Battle

`CreatureInstance.reconcile_post_battle()` establece una frontera importante:

Persiste/clampa:

- HP actual;
- PP actual;
- status persistente;
- `held_item_consumed` no se resetea en reconciliación.

Se elimina como estado puramente de batalla:

- todos los `stat_stages`;
- todos los status volátiles.

`TrainerBattleSession.settle_finished_battle()` llama a `reconcile_post_battle()` sobre ambos rosters y no aplica ninguna curación adicional de HP, PP o status.

Por tanto el runtime actual demuestra persistencia técnica de esos recursos, pero **NO define una política canónica de Random Cup entre rondas**.

#### `campaign_snapshot` no resuelve todavía recovery/replacement

`TrainerDecisionContext.campaign_snapshot` y `TrainerIntelligenceController.set_campaign_snapshot()` son hoy un seam seguro de transporte por copia profunda.

La regresión existente solo certifica que puede transportar datos como `schema_version`, `round_index` y `own_roster.alive_instance_ids` sin aliasing.

No existe todavía contrato canónico para:

- `between_battle_recovery_policy`;
- `replacement_policy`;
- restauración de PP;
- curación de HP;
- curación de status;
- reposición/reactivación de held items consumidos;
- número público de rondas restantes como entrada obligatoria.

Por tanto C3e no puede inferir esas reglas ni crear defaults.

#### HP — señal directamente utilizable

HP sí admite una medida objetiva de estado actual:

`hp_ratio_bp = current_hp / max_hp`

con clamp `0..10000`.

Para un miembro vivo, reducir HP debe poder reducir readiness actual sin modificar `structural_value_bp`.

Un cambio de HP por sí solo no cambia identidad, rol estructural, cobertura ni unicidad C3d.

#### PP — señal válida, agregación todavía no autorizada

PP actual/máximo por movimiento es estado operativo real y persistente en el runtime actual.

Pero un promedio bruto de PP del moveset sería semánticamente incorrecto:

- agotar un movimiento irrelevante no equivale a agotar la única ruta ofensiva útil;
- un support puede depender de una única ruta dedicada;
- dos moves con el mismo rol pueden aportar redundancia real;
- DATA_ONLY/unknown moves no deben crear readiness ficticio.

C3e autoriza tratar PP como evidencia por movimiento y capacidad, no como media lineal no ponderada.

La siguiente tranche deberá reutilizar clasificación runtime y evidencia de roles ya certificadas, sin duplicar semántica DATA V3.

#### Status persistente — efectos runtime objetivos, impacto dependiente del rol

Los status persistentes tienen semántica runtime concreta bajo `BattleRuleset calvo_v1`:

- burn: multiplicador físico `5000 bp` y daño residual `max_hp / 16`;
- paralysis: Speed `5000 bp` y probabilidad de impedir acción `2500 bp`;
- poison: daño residual `max_hp / 8`;
- badly poisoned: daño creciente mediante `toxic_counter / 16` del max HP;
- sleep: duración persistida en `turns_remaining`, rango base `1..3` al aplicarse;
- freeze: thaw `2000 bp` por intento de acción.

Esto demuestra que status es evidencia operativa real.

Pero una única penalización uniforme por “tener status” sería falsa:

- burn afecta mucho más a una ruta física que a una especial;
- paralysis afecta especialmente a valor basado en velocidad y además a disponibilidad de acción;
- poison/toxic erosionan supervivencia, no directamente la potencia intrínseca del moveset;
- sleep/freeze afectan disponibilidad temporal y su impacto depende del horizonte.

C3e no congela todavía un `status_penalty_bp` agregado.

#### Held item consumido — estado real, valor genérico no demostrado

`held_item_consumed` es observable para el propio roster y el Battle Core deja de disparar triggers del item cuando está consumido.

Además la reconciliación post-battle no lo restaura.

Por tanto “item disponible vs consumido” es evidencia operativa válida del estado actual.

Sin embargo no todos los held items aportan el mismo valor y algunos pueden no ser relevantes para el rol estructural del miembro. C3e no autoriza restar una penalización fija simplemente por `held_item_consumed=true`.

#### Estado transitorio que debe quedar fuera del readiness de campaña

Aunque `own_party` contiene `stat_stages` y status volátiles durante una batalla, C3e los excluye de la futura capa de readiness persistente porque:

- se borran explícitamente en `reconcile_post_battle()`;
- ya pertenecen a evaluación táctica del estado de combate;
- incorporarlos a valor operativo de campaña mezclaría horizonte táctico y persistencia entre combates.

No se prohíbe que los brains tácticos los usen; se prohíbe reutilizarlos como si fueran degradación persistente C3.

#### Conclusión de contrato

**Sí es implementable un `operational_readiness_bp` del estado operativo PRESENTE**, separado y honesto, sin conocer `between_battle_recovery_policy`.

No es todavía implementable de forma honesta:

- readiness proyectado después de la recuperación entre rondas;
- coste permanente de perder el miembro;
- expectativa de reposición;
- valoración de rondas futuras basada en reglas aún inexistentes.

La semántica obligatoria debe distinguir:

1. `structural_value_bp`: valor estructural del superviviente en el roster, ya C3d;
2. current operational readiness: degradación/utilidad del estado persistente actual;
3. post-recovery readiness: transformación futura que solo puede existir cuando haya política de recuperación;
4. `permadeath_loss_cost_bp`: capa posterior que necesita además replacement/campaign rules.

No se permite usar el punto 2 como sustituto de 3 o 4.

#### Siguiente microtranche autorizada — C3f-a

**C3f-a — extracción TEST/AUDIT-ONLY de evidencia operativa actual, todavía sin scalar.**

Debe construir fixtures y/o helper test-only que exponga como mínimo:

- `hp_ratio_bp`;
- por move runtime-supported: `move_id`, `current_pp`, `max_pp`, `pp_ratio_bp`, disponibilidad `current_pp > 0`;
- rutas desconocidas/DATA_ONLY separadas y fail-closed;
- status persistente estructurado con sus parámetros runtime públicos relevantes;
- `held_item_id` + `held_item_consumed` como evidencia, sin penalización genérica;
- exclusión explícita de stat stages y volátiles del contrato persistente;
- determinismo;
- JSON serialization;
- ausencia de rival/belief/profile/RNG/campaign-policy.

Debe además explorar cómo relacionar PP agotado con capacidad real sin usar un promedio bruto de cuatro slots. Es válido comparar representaciones, pero todavía no congelar `operational_readiness_bp`.

Sigue prohibido durante C3f-a:

- modificar C3d `structural_value_bp`;
- exponer un scalar readiness de producción;
- inventar `between_battle_recovery_policy` o `replacement_policy`;
- implementar `permadeath_loss_cost_bp`;
- integrar switching/search campaign-value;
- iniciar FASE34;
- mergear PR #105.
