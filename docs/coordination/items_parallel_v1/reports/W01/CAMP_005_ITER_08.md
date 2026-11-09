# IA1/W01 — CAMPAÑA_005 — ITER_08 — CI_PASS_VERIFICADO

**Bloque:** 08/10, con fecha 2026-11-09; **rama exclusiva** `codex/calvo-items-20261104-w01-camp005`.

**Commit funcional verificado:** `271cb9af74fdd03928fc42c53cced746ebe6b801`. **GitHub Actions [#42705717830](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42705717830): `completed/success`, mismo SHA**.

## IDs y comportamiento nativo
- `odd_incense` (Incienso Raro): efecto positivo real `onBasePower` Psíquico sobre `confusion`; no potencia `tackle` de Normal ni `reflect` de estado.
- `rock_incense` (Incienso Roca): potencia ataques Roca, probado con `smack_down`; negativos Normal y estado.
- `rose_incense` (Incienso Floral): potencia ataques Planta, probado con `energy_ball`; negativos Normal y estado.

Para cada uno: mismos adversarios reales Mew/Mew y mismas semillas 19/23 en controles; comparación `a.damage > n.damage > 0` con `n.damage == r.damage`, sin asignación de daño simulada. Portador activo, ausencia y reserva independientes; cada modalidad conserva propietario, dos unidades sin consumo, equipamiento, snapshot real y restauración SaveV2. No se han creado nuevas reglas de producción.

**Bloque 08:** 9 escenarios / 12 pares / 36 modalidades. **CAMPAÑA_005 acumulada:** 72 escenarios, 234 pares, 702 modalidades; preservados los 63 casos anteriores y el reproductor del arreglo Transformación.

## Recibos de CI sobre commit funcional
- `CAMP005_W01_SCOPE PASS blocks=8`
- `CAMP005_W01_PY PASS blocks=8 checks=544`
- `CAMP005_W01_GODOT PASS blocks=8 checks=21147`
- `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3`
- `W01_B07_NATIVE_SPEED PASS cases=3`
- `SHOWDOWN_TRANSACTIONS PASS 10`

**CAMP004** no se reejecutó: el workflow solo exige regresión completa en hitos 01/05/10 o ante cambios en `modules/`. Su última CI funcional íntegra #42679854792 conserva Python 1028 y Godot 16816 PASS. No se ha reducido esa puerta ni se ha modificado código de producción.

**Sin dependencias nuevas.** El test de inciensos como potenciadores de tipo no certifica funciones de crianza fuera de W01. Tampoco valida GUI/GPU ni integración en `main` o V28.

**Estado:** fila 08 `CI_PASS_VERIFICADO` en CSV, anclada al SHA y run inmutables. El commit documental posterior puede disparar una segunda CI de verificación del HEAD. **Siguiente `p`**, tras confirmar esa CI: bloque 09, únicamente `sea_incense;full_incense;lax_incense`. No se inicia ahora.
