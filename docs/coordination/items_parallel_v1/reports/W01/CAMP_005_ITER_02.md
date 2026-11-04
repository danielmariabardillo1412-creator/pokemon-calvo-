# IA1/W01 — CAMPAÑA_005 — Bloque 02/10

**Rama única:** `codex/calvo-items-20261104-w01-camp005`.
**Autoridad:** `CAMPAIGN_005_W01_GATE.md`, `CAMPAIGN_005_W01_QUEUE_APPROVED.csv`, protocolo `AUTONOMOUS_REPAIR_V5.md`.
**IDs oficiales:** `miracle_seed;mystic_water;never_melt_ice`.

## Bloque anterior certificado
IA6 añadió el workflow propio `.github/workflows/parallel-camp005-w01-autoci.yml` en la misma rama. CI [#41767517526](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767517526), SHA `bd33aeb3f993804c3c85217b81892356af39aac5`, conclusión `completed/success`.

Recibos de nueva campaña: `CAMP005_W01_SCOPE PASS blocks=1`; `CAMP005_W01_PY PASS blocks=1 checks=88`; `CAMP005_W01_GODOT PASS blocks=1 checks=1109`. Regresión completa CAMPAÑA_004: `CAMP004_W01_PY PASS blocks=10 checks=1028` y `CAMP004_W01_GODOT PASS blocks=10 checks=16816`. Fila 01 del progreso pasa a `CI_PASS_VERIFICADO`; ese SHA corresponde al código funcional y al workflow, no a la actualización documental posterior.

## Bloque 02: pruebas de combate real

El motor Showdown `gen9calvounifiedv1` ya implementa los tres modificadores mediante `onBasePower`. El inventario canónico y la lista seleccionada coinciden; la referencia nativa histórica `tools/item_audit/held_effect_sweep_v2.cjs` contiene `booster`, `attack`, `type_boost` y `type_boost_nonmatching`. Se reutiliza la sesión Godot L2/L3, los tres carriles independientes y la proyección SaveV2 de CAMPAÑA_004; no se modifica producción.

| Objeto | Ataque positivo coincidente | Negativo tipo no coincidente | Negativo de estado |
| --- | --- | --- | --- |
| Semilla Milagro (`miracle_seed`) | `energy_ball` (Planta) | `tackle` (Normal) | `reflect` |
| Agua Mística (`mystic_water`) | `surf` (Agua) | `tackle` (Normal) | `reflect` |
| Hielo Perpetuo (`never_melt_ice`) | `ice_beam` (Hielo) | `tackle` (Normal) | `reflect` |

Cada prueba usa portador activo, objeto ausente y objeto en reserva, misma semilla y rival Mew a nivel 100. Se exige **daño positivo real y estrictamente mayor** solo al equipar el tipo apropiado, daño idéntico con tipo erróneo, ausencia de daño con Reflejo, no consumo, identidad de portador, inventario físico y SaveV2 restaurado exactamente. Dos semillas en ataque positivo y una en cada control.

**Bloque 02:** 9 casos / 12 pares caso-semilla / 36 variantes. **Acumulado CAMP005:** 6 equipables / 18 casos / 24 pares / 72 variantes. Se mantienen íntegros los casos, checks y recibos previos de bloque 01.

## Estado de entrega y CI

Al publicar la rama, la fila 02 queda `EN_CI_AUTOMATICA`. No se declara `PASS` funcional hasta ejecutar nueva CI con `CAMP005_W01_PY PASS blocks=2 checks=N` y `CAMP005_W01_GODOT PASS blocks=2 checks=N` en un mismo SHA, y concluir `completed/success`. En hito 02 el workflow no repite la regresión completa CAMP004 (ya pasó en el hito 01), salvo cambios de producción; será obligatoria de nuevo en 05/10 y 10/10.

**Límites:** pruebas headless no acreditan GPU/UI ni la integración en `main` o V28. Sigue pendiente para IA6 el problema SaveV2 de fase intermedia de carga de Rayo Solar en campaña anterior. No modificar main, V28, rama árbitra, política común ni otras ramas.

**Siguiente `p`, solo tras CI positiva de este bloque:** bloque 03 `poison_barb;sharp_beak;silk_scarf`, sin saltar filas.
