# IA1/W01 — CAMPAÑA_005 — ITER_10 — CERTIFICACIÓN FINAL

**Estado oficial: CAMPAÑA_005_FINALIZADA — 10/10 bloques, 30 objetos.**

Rama de trabajo `codex/calvo-items-20261104-w01-camp005`. 
**SHA funcional inmutable:** `5303578448d909cf1b4e2c3c60c7d3e231203f98`. 
**GitHub Actions [#42717306543](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42717306543): `completed/success`, HEAD de la ejecución exactamente ese SHA.**

## Bloque 10: gemas con consumo real y SaveV2 intermedio

- `normal_gem`: Placaje (Normal) potenciado y gema consumida en el primer golpe; control negativo Agua Pistola y Danza Espada (Normal, movimiento de estado).
- `fire_gem`: Puño Fuego potenciado y consumido en el primer golpe; control Placaje y Día Soleado (Fuego, estado).
- `water_gem`: Surf potenciado y consumido en el primer golpe; control Placaje y Danza Lluvia (Agua, estado).

Se prueba **por separado** objeto equipado al activo, ausencia y equipamiento a reserva. Tras el primer impacto se restaura SaveV2 desde el estado consumido y se ejecuta un segundo ataque auténtico: ninguna gema reaparece o se consume de nuevo. Se comprueban unidades físicas, identidad, titularidad, daño real y snapshot idéntico antes/después de cada restauración. Los ataques de tipo incorrecto y los estados del propio tipo no consumen.

**B10:** 9 escenarios / 12 pares caso-semilla / 36 variantes. **Acumulado CAMPAÑA_005:** 90 escenarios / 272 pares caso-semilla / 816 variantes; ninguna regresión anterior retirada.

## Recibos de CI

- `CAMP005_W01_SCOPE PASS blocks=10`
- `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3`
- `SHOWDOWN_TRANSACTIONS PASS 10`
- `W01_B07_NATIVE_SPEED PASS cases=3`
- `W01_B09_NATIVE PASS water=1 order=1 misses=7 hits=57`
- `W01_B10_NATIVE PASS consumed=6 retained=6 double_actions=6 snapshots=33`
- `CAMP005_W01_PY PASS blocks=10 checks=668`
- `CAMP005_W01_GODOT PASS blocks=10 checks=24723`
- **Regresión completa hito final CAMPAÑA_004:** `CAMP004_W01_PY PASS blocks=10 checks=1028` y `CAMP004_W01_GODOT PASS blocks=10 checks=16816`.

**Alcance y límites:** test Godot headless y backend real Showdown; no prueba gráfica/GPU. No se ha alterado el código de producción, SaveV2 central, ni otros responsables. El aumento de timeout se circunscribe al workflow/runner de pruebas de W01. `main`, V28, PR #118, rama IA6 y las demás trabajadoras intactas. **No hay fusión ni integración general certificada:** IA6 conserva autoridad de revisión/integración de CAMPAÑA_005.

**Concluido el último bloque autorizado.** No iniciar una CAMPAÑA_006 ni editar módulos compartidos sin nueva orden explícita de IA6. El commit documental de cierre puede iniciar otra CI de metadatos; el recibo funcional anterior sigue anclado al SHA inmutable exacto.
