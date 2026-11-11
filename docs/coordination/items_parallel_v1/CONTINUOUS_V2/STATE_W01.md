# W01 / IA1 — CONTINUOUS_V2 · Estado operativo tras preparar cierre Fase A

**Branch exclusivo:** `codex/calvo-items-20261110-w01-gems-autobatch01` · **Orden:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` (CONTINUOUS_V2/PLAN_W01) · **Último HEAD funcional comprobado antes de esta publicación:** `ea13f499e1ad41227f9c30b7389bc9c16526daad`.

## Control de campaña
- **Fase A:** TANDA04, **7/10 certificados** con CI acumulativa real; 3 pilotos (filas 08–10) verdes pendientes de una **única nueva CI 16 jobs**. No proclamar 10/10 hasta que los 16 estén `completed/success` en HEAD correcto.
- **Fase B:** 26 candidatos, bloques 10+10+6, lista preautorizada. Auditoría previa en `reports/W01/CONTINUOUS_V2_PHASE_B_PREFLIGHT.md`: **22 seleccionados con `native_entry=True`; 4 sin fila efectiva de selección y `DATA_ONLY`** (`amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`). No implementar oro, encuentros o cría en W01. Tras cierre de A, empezar B sin exigir nuevo `p` por bloque (sujeto a duración de turno).
- **Fase C:** auditoría integral de L3 e integración; ningún pase cruzado IA6 atribuido a W01.
- **Objetos nuevos implementados en producción:** 0. **L3 certificados sobre efectos preexistentes:** 7. **Bloqueos de arquitectura:** 0. **Integración IA6:** NO.
- **Protegidos:** `main`, V28, PR #118, ramas W02–W05, `FieldItemService`, `FieldItemBag`, `CreatureInstance`, `SaveV2`, motor compartido no modificados.

## Evidencia cerrada por filas
- Fila 01 `leftovers`: CI #42923382323 SUCCESS SHA `197b908d949825631856d246d36144c88154ea0c`.
- Fila 02 `life_orb`: CI #42926374158 SUCCESS 8/8 SHA `46e4204a77743656de68d2026f6533f712c618cd`.
- Fila 03 `choice_band`: CI #42929306389 SUCCESS 9/9 SHA `0d11b41549b713c68433fa6b1d11d18b7d7e670c`.
- **Filas 04–07:** `choice_specs`, `choice_scarf`, `shell_bell`, `eviolite` certificadas por [CI #42936836840](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42936836840), SHA `8ddbef7d1fcd235b921173a4cb005b175be10b08`, **13/13 jobs completed/success**, incluyendo regresiones CAMP004/005, gemas T01–T03.
- **Fila 08 `safety_goggles`:** [CI piloto #42937741017](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42937741017) SUCCESS SHA `0839dee1dd6ad46ca3963569d0d2ca9c7f284f32`, Python 10, Node 8 modos, Godot 8 rutas L3/157 checks (Spore/tormenta/control). Inicial piloto rojo por apertura de Breloom nivel20; corregido el setup a lvl100 en test, sin producción.
- **Fila 09 `black_sludge`:** [CI piloto #42937805501](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42937805501) SUCCESS SHA `5fe9eea00a078b90734ec4e0f327012784471c98`, Python 9, Node 7 modos, Godot 7 rutas L3/127 checks. Primera ejecución roja por marcador de Python que no coincidía con la fórmula nativa; corregido solo el test.
- **Fila 10 `sitrus_berry`:** [CI piloto #42939382830](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42939382830) SUCCESS SHA `ea13f499e1ad41227f9c30b7389bc9c16526daad`, Python 10, Node 6 modos y Godot 6 rutas L3/148 checks. **Consumida ya al comienzo de batalla si entra a ≤50 % HP**, no al primer ataque; el test exige no doble curación, stock y SaveV2 coherente. Se audita **solo objeto equipado**, no uso de bayas como medicina W02; sin cambios de código W02.
- **CSV oficial:** `reports/W01/AUTORUN_V4_PROGRESS.csv`, filas 01–07 CERTIFICADO, filas 08–10 EN_CI_AUTOMATICA; todos 0 nuevas implementaciones de producción.

## Próximo paso automático
1. Comprobar nueva CI V4 **16 jobs** disparada por la modificación del workflow en este commit (su run ID debe verificarse, no inventarse). Si 16/16 SUCCESS sobre el SHA correcto, marcar filas 08–10 `CERTIFICADO` en CSV, publicar `AUTORUN_V4_FINAL.md`, cerrar Fase A 10/10 sin atribuir implementaciones inexistentes.
2. Entrar inmediatamente Fase B / bloque 01: `ability_shield`, `absorb_bulb`, `adrenaline_orb`, `big_root`, `expert_belt`, y registrar 4 `DEPENDENCIA_FUERA_W01` si permanecen sin selección. No hacer STOP por diez. En B no tocar formas/Arceus de W04.
3. Si CI 16-jobs falla, reparar solo prueba W01 que demuestre error concreto; nunca borrar regresiones ni hacer `continue-on-error`. Conservar historial rojo.
4. Si el turno/contexto concluye, una nueva `p` recupera este STATE, CSV y HEAD; **no** hay ejecución en segundo plano garantizada.
