# IA1/W01 — TANDA 04 · CIERRE FUNCIONAL CERTIFICADO

**Fecha de cierre:** 2026-11-11. **Rama funcional exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`.

## CI final y límites de la certificación

- [CI #42939814729](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42939814729), **completed/success**, **16/16 jobs completados en SUCCESS**, **SHA funcional `83dacee5c924505f5234503a4fef126ea0bb0e01`**.
- Jobs acumulados sin reducción ni `continue-on-error`: `v2_new_gems`, `tanda01_regression`, `camp005_regression`, `camp004_regression`, `v3_l3_field_path`, `v3_field_boundaries`, los diez `v4_*` de TANDA04.
- La evidencia L3 para cada fila recorre `FieldItemService.equip → FieldNativeSession / Showdown → settle_finished_battle → SaveV2` en piloto y CI acumulativa. No se ha auditado UI visual completa ni integración cruzada IA6.
- **10 candidatos examinados y funcionalmente certificados (10/10)**; **0 implementaciones nuevas de producción**; **10 coberturas de recorrido L3 incorporadas/certificadas en esta tanda**; **0 bloqueos en A**; **integración IA6 pendiente**.
- Filas: `leftovers`, `life_orb`, `choice_band`, `choice_specs`, `choice_scarf`, `shell_bell`, `eviolite`, `safety_goggles`, `black_sludge`, `sitrus_berry`.
- Baya Zidra tratada SOLO como objeto equipado en combate, sin tocar las bayas de uso en campo propias de W02; los efectos de combate ya existían.
- El CSV `reports/W01/AUTORUN_V4_PROGRESS.csv` fija el estado con SHA/CI por fila. Las filas 08–10 se respaldan en la misma CI final SHA; no se reutilizan SHA de piloto para atribuir la regresión acumulativa.

## Siguiente trabajo sin STOP

Se activa `CONTINUOUS_V2` Fase B: **26 candidatos en tres bloques de 10+10+6**, con auditoría previa `CONTINUOUS_V2_PHASE_B_PREFLIGHT.md`.
Se detectaron 22 seleccionados con entrada nativa y 4 dependencias fuera de ámbito W01: `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`. Estos cuatro no se convierten en objetos de combate artificialmente; hay que mantenerlos como `DEPENDENCIA_FUERA_W01` si la política sigue sin habilitarlos.
Comenzar `ability_shield`, luego `absorb_bulb`, `adrenaline_orb`, `big_root`, `expert_belt` y `draco_plate`. Las placas tienen exclusivamente autorización de multiplicador por tipo, sin formas Arceus.
Al finalizar toda B, Fase C de auditoría real e informe `READY_FOR_IA6`. Prohibido fusionar o editar `main`, V28, PR118, otra rama W o módulos protegidos sin autorización específica.
