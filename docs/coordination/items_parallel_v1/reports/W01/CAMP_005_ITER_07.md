# IA1/W01 — CAMPAÑA_005 — ITER_07 — CI_PASS_VERIFICADO

**Fecha:** 9 de noviembre de 2026. **Estado funcional:** 7/10 bloques certificados; **siguiente:** 08, solamente con nueva `p`.

**Rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`  
**SHA funcional certificado:** `1e713a1925fe3fa582f21b5353e2c7f265ba928d`  
**CI funcional:** [#42689328705](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42689328705), `completed/success` para ese SHA.

## Bloque 07 — objetivos y evidencia real

IDs: `quick_powder`, `razor_claw`, `razor_fang`. Nueve casos nuevos, 88 pares caso-semilla, 264 modalidades (activo/sin objeto/reserva) añadidas; matriz acumulativa: **63 escenarios, 222 pares, 666 modalidades**.

- **Polvo Veloz:** Ditto sin transformar duplica su velocidad nativa (se comprueba el valor exacto del modificador) y actúa antes que Gyarados, a diferencia de los controles. Mew equipado no obtiene bono; Ditto tras Transformación tampoco, pese a conservar el objeto. Restauración nativa y SaveV2 en turno transformado y tras cambio real.
- **Garra Afilada:** Foco Energía + Placaje en Mew produce crítico real nativo, con al menos una semilla que demuestra crítico exclusivo frente a controles sin objeto y con objeto en reserva. Foco Energía y 16 semillas no manipulan RNG; Gengar inmune y Reflejo no provocan crítico ni daño.
- **Colmillo Agudo:** Placaje contra Snorlax con 64 semillas naturales demuestra ambos ramales RNG: retroceso activado y no activado. Los dos controles nunca retroceden; no hay bonificación artificial al daño. Con Reflejo o ante Gengar inmune tampoco activa retroceso.

Los tres conservan identidad, propietario, consumo **nulo**, dos unidades físicas y el snapshot/restauración SaveV2 en los tres modos. El test de Polvo Veloz inspecciona el `getStat('spe')` del mismo backend nativo utilizado en combate, no valores simulados.

## Recibos exactos GitHub Actions

- `CAMP005_W01_SCOPE PASS blocks=7`
- `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3`
- `SHOWDOWN_TRANSACTIONS PASS 10`
- `W01_B07_NATIVE_SPEED PASS cases=3`
- `CAMP005_W01_PY PASS blocks=7 checks=480`
- `CAMP005_W01_GODOT PASS blocks=7 checks=20049`

La regresión Python/Godot CAMP004 **no se reejecutó** en la CI B07 porque el workflow conserva la puerta de hitos 01/05/10 o cambios de producción y B07 solo modificó pruebas/documentos. La regresión CAMP004 completa anterior sigue certificada en #42679854792 (Python 1028 y Godot 16816). Conservar el runner B06 y las transacciones nativas evita perder esa reparación funcional.

## Fronteras y siguientes pasos

No se ha modificado `main`, V28, PR #118, rama árbitra, ramas de otras IA, `native_engine.cjs`, SaveV2 central ni producción. Sin nueva dependencia compartida detectada en B07. La CI valida pruebas headless; **no** certifica integración global ni GPU/UI.

Fila 07 del CSV certificada con SHA de código y run inmutables. El commit documental de este cierre puede disparar otra CI por cambiar el progreso, pero **no altera la evidencia funcional del SHA anterior**. Próxima `p`: bloque 08 exclusivamente `odd_incense;rock_incense;rose_incense`; no comenzarlo antes.
