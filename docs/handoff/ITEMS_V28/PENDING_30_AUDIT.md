# Auditoría operativa de 30 equipables pendientes — ITEMS_V28 (2026-11-01)

## Resultado y límites

**Estado de entrada:** 61 candidatos de singles Gen9 factory sets + ampliación V28, **27** con cierre ampliado V28, **30** sin cierre ampliado y **4** bloqueados por formas. Esta auditoría **NO cierra objetos, NO modifica reglas y NO altera el contador 27/30/4**. PR #118 en borrador; `main` V27 permanece oficial. `wide_lens` excluido y `beast_ball` vetada por decisión del proyecto.

**Hallazgo:** los **30** tienen alguna cobertura histórica de efectos en la matriz V8; **22** aparecen en los generadores nativos de casos `held_effect_sweep_v2.cjs` / `held_effect_sweep_v3.cjs` y los **otros 8** tienen casos en `held_pilot.cjs` (V1). En V8 los treinta tienen `equipment_transfer=VERIFIED` y `battle_effect_status=HELD_EFFECT_SCENARIOS_VERIFIED_NOT_EXHAUSTIVE`. Esto **no significa** que todos los efectos, rutas de mochila, persistencia, consumo, propietarios, interacciones y renderizado estén probados en V28.

**Cautela:** el replay V28 demostrado usa SOLO cuatro IDs V2/V3 y 14 casos originales; pasa 20/20 workflows sobre `6383f558`, pero **0 objetos adicionales certificados**. El replay ejecuta originales con sus aserciones; no certifica efectos ausentes por comparación de snapshots sin oráculo. V1 tiene recibos históricos propios y **todavía no está incorporado** al reproductor `replay_v28.py`. Hay que verificar formato, aserciones y pruebas de equivalencia **antes** de extender la reproducción a V1. El código histórico es fuente de escenarios, no un PASS actual automático.

## Inventario exhaustivo, sin duplicados

Clasificación de planificación: **9 potenciadores de tipo, 3 bayas de resistencia, 2 bayas con prueba V2 específica, 8 casos V1 y 8 casos V2/V3 especiales = 30**. La columna final describe el **contrato aún por comprobar o ampliar en integración**, no un fallo demostrado.

| ID interno | Familia operativa | Fuente de escenario | Pendiente para cierre V28 |
| --- | --- | --- | --- |
| `black_glasses` | Tipos | V2 | Daño Siniestro coincide/no coincide; persistencia y control portador |
| `earth_plate` | Tipos | V2 | Bonus Tierra; la forma de Arceus NO se incluye en el cierre simple |
| `splash_plate` | Tipos | V2 | Bonus Agua; no inferir transformación de Arceus |
| `pixie_plate` | Tipos | V2 | Bonus Hada; no inferir transformación de Arceus |
| `insect_plate` | Tipos | V2 | Bonus Bicho; no inferir transformación de Arceus |
| `silk_scarf` | Tipos | V2 | Bonus Normal, control ataque de otro tipo |
| `soft_sand` | Tipos | V2 | Bonus Tierra y control negativo |
| `metal_coat` | Tipos | V2 | Bonus Acero; evolución es otro sistema, NO certificada aquí |
| `spell_tag` | Tipos | V2 | Bonus Fantasma y control negativo |
| `colbur_berry` | Resistencias | V2 | Golpe Siniestro supereficaz, consumo, control sin activar, guardado |
| `occa_berry` | Resistencias | V2 | Golpe Fuego supereficaz, consumo, control sin activar, guardado |
| `shuca_berry` | Resistencias | V2 | Golpe Tierra supereficaz, consumo, control sin activar, guardado |
| `chesto_berry` | Bayas | V2 | Curación automática de sueño, ausencia de activación, diferenciar uso de campo ya registrado |
| `kee_berry` | Bayas | V2 | Subida de Defensa por impacto físico; control especial y consumo |
| `assault_vest` | V1 | V1 | Bloqueo de movimientos de estado, bonus defensivo especial y guardado |
| `lum_berry` | V1 | V1 | Estados alterados y confusión, no activación, consumo; no duplicar uso de campo |
| `power_herb` | V1 | V1 | Turno de carga evitado, consumo, movimiento sin carga como control |
| `focus_sash` | V1 | V1 | Aguantar a 1 PS desde salud completa, disparador no aplicable y consumo |
| `sitrus_berry` | V1 | V1 | Umbral de curación automática, PS límite, consumo; no duplicar ruta de campo |
| `mental_herb` | V1 | V1 | Eliminar Mofa y verificar otras restricciones solo si hay escenarios |
| `red_card` | V1 | V1 | Cambio forzado real, rival sin reserva y guardado de estado |
| `throat_spray` | V1 | V1 | Movimiento sonoro y subida de Ataque Especial, control no sonoro y consumo |
| `loaded_dice` | Especial | V2 | Repetición de golpes, contraste y límites RNG; no basta un solo seed |
| `toxic_orb` | Especial | V2 | Veneno grave tras turno, inmunidades, varios turnos y persistencia |
| `flame_orb` | Especial | V2 | Quemadura tras turno, inmunidades, varios turnos y persistencia |
| `weakness_policy` | Especial | V2 | Golpe supereficaz, subida estadística, no activación y consumo |
| `booster_energy` | Especial | V3 | Habilidad Paradoja real, activación/consumo y control sin habilidad; integración habilidades pendiente |
| `eviolite` | Especial | V3 | Defensa de especie no evolucionada, evolución final como control, persistencia |
| `soul_dew` | Especial | V3 | Latios/Latias y tipo apropiado, portador incorrecto, persistencia |
| `sticky_barb` | Especial | V3 | Daño residual y transferencia por contacto; propiedad real rival tras guardado |

## Prioridad y vía de automatización

1. **Grupo A: 9 potenciadores de tipo V2.** Reusar directamente los pares matching/nonmatching de V2 y el runner común existente. Crear comprobaciones compartidas de equipamiento/propietario, mapa, checkpoint, guardar/cargar y controles de ausencia de bonificación. Las cuatro placas pueden mejorar daño sin certificar cambio de forma de Arceus; `metal_coat` no certifica evolución. No reimplementar cálculo del daño.
2. **Grupo B: 3 bayas de resistencia V2.** Reutilizar escenarios positivo/negativo, conectar consumo exacto y persistencia de la mochila después del combate. No inventar uso de campo para bayas de resistencia.
3. **Grupo C: 2 bayas V2 (`chesto_berry`, `kee_berry`).** Comparten infraestructura de consumo, **no activador**: sueño frente a golpe físico. `chesto_berry` ya registra ruta de recuperación en campo en V8; no reconstruirla.
4. **Grupo D: 8 escenarios V1.** Antes de redactar contratos nuevos, evaluar un adaptador **genérico y acotado** para `.godot/item_audit_v1/held_cases.json` y sus oráculos originales `held_pilot.cjs`. En particular `sitrus_berry` y `lum_berry` ya tienen recuperación de campo documentada. Si el adaptador no conserva pruebas causales/recibos/propiedad, no declarar PASS y usar infraestructura compartida con tests específicos.
5. **Grupo E: 8 especiales V2/V3.** Reusar los casos nativos para el disparador, pero **ampliar controles por conducta**, especialmente RNG (`loaded_dice`), inmunidades y turnos (`toxic_orb`, `flame_orb`), habilidad Paradoja (`booster_energy`), especie/evolución (`eviolite`, `soul_dew`), consumo (`weakness_policy`) y transferencia real (`sticky_barb`). **`booster_energy` queda condicionado a demostrar integración real de habilidades**; no añadirlo a los cuatro bloqueados por formas ni certificarlo por un caso nativo aislado.

**Orden preferido:** primero prototipo de ampliación de replay con 2–3 potenciadores sencillos; comparar resultados nativos originales y postcondiciones físicas reales. Si demuestra ahorro con la misma cobertura, incorporar los otros del grupo A y luego B. Separar los especiales y no desarrollar todos en paralelo. No activar una familia nueva sin delimitar allowlist y contrato.

## Criterios de aprobación (por ID, no por lote)

- Origen y regla existente identificados en datos locales/simulador; nada importado solo por descripción.
- Disparador real y resultado observable; **control negativo** que detectaría un efecto ausente o aplicado al portador equivocado. Para consumibles, verificar la retirada exactamente una vez; para transferencias, propietario correcto.
- Misma semilla/contexto entre tratamiento y control; combate real con comandos legales y evidencia de estado. Usar checks de causalidad heredados y ampliar solo donde existan huecos.
- Servicio físico de mochila: poseedor, stock, equipar/quitar; guardar/restaurar durante y después; cierre idempotente, sin recompensas duplicadas. Distinguir encuentro de mapa de comprobación causal de efecto.
- Evidencia verificable por **SHA funcional + run + logs/artefactos** en Godot 4.7 Ubuntu y Windows; fallos preservados, regresiones no rebajadas. GPU/manual visual pendiente y errores PID Linux pendientes de diagnóstico.
- Estado admisible: `HISTORICAL_ONLY`, `PARTIAL`, `SCOPED_VERIFIED`, `FAILED`, `BLOCKED_DEPENDENCY`. El contador solo disminuye al obtener `SCOPED_VERIFIED` en un contrato explícito; no llamar a eso cobertura universal.

## Fuentes locales que se cruzaron

- `docs/handoff/ITEMS_V28/COMPETITIVE_COVERAGE_AUDIT.md` (los 47 y 15 extra; 27/30/4).
- `docs/current/ITEM_FIELD_V8.csv.txt` (filas exactas de los 30, equipamiento y efecto histórico parcial).
- `tools/item_audit/held_effect_sweep_v2.cjs` (generador y oráculos V2).
- `tools/item_audit/held_effect_sweep_v3.cjs` (generador y oráculos V3).
- `tools/item_audit/held_pilot.cjs` (ocho casos piloto V1 y oráculos).
- `docs/handoff/ITEMS_V28/REPLAY_FEASIBILITY.md`, `REPLAY_RESULTS.json` (14 replay/435 checks/0 cierres nuevos).
- `modules/inventory/field_recovery_profile.json` y V8 (no duplicar recuperación de campo).

**Sin cambios funcionales ni nuevos tests ejecutados por esta auditoría documental.** El siguiente commit con funcionalidad deberá ejecutar CI y actualizar evidencia antes de cambiar el contador. Mantener las cuatro dependencias `wellspring_mask`, `cornerstone_mask`, `griseous_core`, `rusted_sword` aparte.
