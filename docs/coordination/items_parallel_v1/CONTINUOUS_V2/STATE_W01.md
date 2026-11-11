# W01 CONTINUOUS_V2 · Estado activo — FASE B / Bloque 01

**Rama W01:** `codex/calvo-items-20261110-w01-gems-autobatch01`. **Protocolo:** `IA6_AUTORUN.md` y `CONTINUOUS_V2/PLAN_W01.md`. **NUNCA STOP por 10/10**.

## Fase A — cerrada
- **10/10 L3 certificados**, objetos de producción implementados nuevos: **0**.
- **SHA funcional certificado:** `83dacee5c924505f5234503a4fef126ea0bb0e01`; **CI final:** [#42939814729](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42939814729) `completed/success` **16/16 jobs**.
- Informe `reports/W01/AUTORUN_V4_FINAL.md`; CSV `reports/W01/AUTORUN_V4_PROGRESS.csv` (todas las filas CERTIFICADO).
- Integración en rama IA6 **NO**. El pase W01 no prueba UI visual completa ni integración multiworker.

## Fase B — bloque 01/03 activo
- **26 candidatos autorizados**, 10+10+6. **22 seleccionados con entrada nativa**, **4 DEPENDENCIA_FUERA_W01** debido a `DATA_ONLY` y ausencia en selección: `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`. No se implementan monedas, encuentros ni crianza.
- **CSV activo:** `reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv`, 26 filas, **0/26 certificados B**, **4/26 dependencias**, **22/26 pruebas por ejecutar**, **0 nuevos implementados B**.
- **next_id:** `ability_shield` (orden 01, onSetAbility, proteger habilidad frente a cambio/supresión). Comprobar escenario nativo real y negativos con/sin objeto, reserva, guardado antes de considerarlo L3. Si requiere seam protegido registrar evidencia roja y continuar `absorb_bulb`.
- **siguientes:** `absorb_bulb`, `adrenaline_orb`, `big_root`, `expert_belt`, `draco_plate` y bloques de placas aprobados.
- **preflight:** `reports/W01/CONTINUOUS_V2_PHASE_B_PREFLIGHT.md`. `holdable_ids` no basta para declarar efecto disponible. `expert_belt` ya tenía piloto L2; `big_root` CAMP001: reusar evidencia y añadir únicamente cobertura faltante.

## Seguridad / reanudación
- **Rama exclusiva W01**; `main`, V28, PR118, W02–W05, SaveV2, FieldItemService, FieldItemBag, CreatureInstance, PlayerCollection y reglas Showdown globales protegidos.
- No atribuir compilación CI al commit documental posterior al SHA de pruebas; citar siempre `head_sha` de la ejecución.
- Próximo `p` empieza por releer este STATE+CSV y comprobar la CI publicada del primer piloto B si existe. Si no, construir el piloto L2/L3 del primer ID.
- No existe ejecución asíncrona garantizada. Integración IA6 sigue **PENDIENTE**.
