# IA1/W01 — CAMPAÑA_005 — ITER_08 (CI pendiente)

**Rama:** `codex/calvo-items-20261104-w01-camp005`  
**Bloque:** 08 / 10  
**Objetos:** `odd_incense` (Psíquico), `rock_incense` (Roca), `rose_incense` (Planta).  
**Estado:** EN_CI_AUTOMATICA; el bloque **NO** se certifica hasta completar CI funcional sobre este SHA.

## Contrato L2/L3 ejecutable
- Tres inciensos canónicos de combate `onBasePower`. Mew con cada incienso ataca al Mew rival usando `confusion`, `smack_down` o `energy_ball` respectivamente.
- Casos positivos: daño real con incienso equipado superior a controles ausente y reserva; controles idénticos con semillas 19 y 23, nunca efecto desde la reserva.
- Negativos: `tackle` (tipo distinto) inflige daño sin bonificación; `reflect` (estado) no inflige daño, no consume objeto.
- Reutiliza motor nativo Showdown, tres carriles concurrentes aislados, SaveV2 y comprobaciones de titularidad, dos unidades físicas, no consumo, snapshots y propiedad.
- Añade **9 escenarios, 12 pares, 36 modalidades**; total acumulado **72 escenarios, 234 pares, 702 modalidades**. Preservadas las pruebas probabilísticas B05/B07 y Transformación B06, sin modificar producción.

## Evidencia histórica
`docs/current/ITEM_INVENTORY.csv` confirma entrada nativa y hook `onBasePower` de los tres inciensos. `tools/item_audit/held_effect_sweep_v3.cjs` prueba previamente potencia por tipo y control de tipo incorrecto; el nuevo bloque lleva esa evidencia al flujo Godot/SaveV2. No hay contrato de crianza dentro del alcance de equipables de combate.

## Certificación pendiente
La CI documental previa del B07 [#42692174058](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42692174058) es `completed/success`, cabeza previa `54db2518c08b12dce5ca4756dbfffb3367e9a818`. No reutilizar ese run como certificación B08.

**Punto de parada:** no ejecutar B09 antes de CI B08 verde y registrar el run real. Sin cambios a `main`, V28, PR #118, rama árbitra, otras trabajadoras, SaveV2 o motor global. Se ha ampliado sólo el temporizador del runner de pruebas de 800 a 1040 s para sostener la matriz acumulativa dentro del timeout 1100 s del workflow.
