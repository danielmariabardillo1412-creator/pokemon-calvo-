# CERTIFICACIÓN FUNCIONAL DEFINITIVA — CAMP006 IA5/W05 · BLOQUE 01/10 · CI PASS

**Estado oficial: BLOQUE 01 CERTIFICADO (2026-11-04).** [GitHub Actions #41764725393](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764725393), SHA de pruebas `cfb95bd64db841bdc8500129ffa781be34bdc99a`, job `126360311722`, **`completed/success`**. Logs inspeccionados directamente:

| Suite real en este SHA | Recibo |
| --- | --- |
| Manifiesto CAMP006 | `CAMP006_W05_MANIFEST_PASS reserved=10 completed=1 ids=49 kind=NEW_IDS` |
| CAMP006 Python | `CAMP006_W05_PY PASS blocks=1 checks=49` |
| CAMP006 gate Python | `CAMP006_GATE_PY_PASS worker=W05 blocks=1 checks=49` |
| CAMP006 Godot 4.7 | `CAMP006_W05_GODOT PASS blocks=1 checks=196` |
| CAMP006 gate Godot | `CAMP006_GATE_GODOT_PASS worker=W05 blocks=1 checks=196` |
| Regresión CAMP005 Python / Godot | `CAMP005_W05_PY PASS blocks=10 checks=580` / `CAMP005_W05_GODOT PASS blocks=10 checks=2166` |
| Regresión CAMP004 Python / Godot | `CAMP004_W05_PY PASS blocks=10 checks=580` / `CAMP004_W05_GODOT PASS blocks=10 checks=2166` |
| Regresión CAMP003 Python / Godot | `CAMP003_W05_PY PASS blocks=10 checks=580` / `CAMP003_W05_GODOT PASS blocks=10 checks=2166` |

**5/5 MT `tm202`–`tm206` con pruebas funcionales de enseñanza en Godot headless** y los tres paquetes anteriores regresionados en el mismo run; no es una prueba visual/GPU ni una incorporación a `main`.

## Incidencias reparadas dentro del ámbito W05

1. `#41763714954`: YAML inválido en el primer workflow por sustitución de cadenas que duplicó líneas y truncó patrones `grep`. Corregido con reconstrucción desde el workflow aprobado CAMP005 y sustitución segura (commit `76196545511d694052d2eea9a56bdc7d70f2d2f0`). Bootstrap estructural `#41763897134` PASS, cero bloques, sin atribuir enseñanza.
2. `#41764007067`: runner Python había conservado ruta de cola CAMP005 de 6 IDs y rechazaba la cuota de 5. Corregidos ambos runners Python/Godot para leer CAMP006 (commits `d464cdafc0bbb97379f48887c6ef4cbd3170509d` y `22032718dc7984373df505c664ff5ddd79aa9043`).
3. `#41764226900`: lista de colas históricas incluía por error la propia cola CAMP006 y trataba `tm202` como usado. Se comprobó que CAMP003, CAMP004 y CAMP005 no incluyen `tm202`–`tm206`; restaurado el detector usando correctamente CAMP003/004/005, sin eliminar el control antirrepetición (commit `7343c5367947de810f8c1f62b0a83733b0771ab9`).
4. `#41764547262`: Python 49 PASS, pero Godot tenía un identificador `all_blocks` fuera del alcance donde se contaban los casos. Se corrigió el cálculo de cantidad esperada a partir del progreso autorizado (commit `cfb95bd64db841bdc8500129ffa781be34bdc99a`). La ejecución posterior `#41764725393` completó **todas** las suites y regresiones con éxito.

**Regla de continuidad:** próxima `p` = exactamente bloque 02 `tm207;tm208;tm209;tm210;tm211`; conservar los cinco casos previos y los contratos de compatibilidad, PP, propietario, consumo, rechazo y SaveV2. Regresiones CAMP005/004/003 obligatorias en hitos 05/10 y parches propios, con primer hito 01 ya aprobado. No tocar `main`, V28, PR118, árbitra, otras ramas, catálogo/learnsets, políticas o las 19 MT históricas inactivas. No hacer merge.

---

# IA5/W05 — CAMPAÑA_006 · ITER 01/10

**Estado de publicación:** BLOQUE_01_EN_CI_AUTOMATICA. No afirmar funcionalidad hasta recibir CI Python/Godot con 5 MT positivas.

## Autorización y alcance
- Rama exclusiva `codex/calvo-items-20261104-w05-camp006`, creada previamente desde CAMP005 final (HEAD inicial `f74b8d33c6d4e7853dcc4fdadfe3a62bf2050d0b`).
- Gate IA6 `CAMPAIGN_006_W05_GATE.md` y cola `CAMPAIGN_006_W05_QUEUE_APPROVED.csv` en la rama árbitra; protocolo `AUTONOMOUS_REPAIR_V5.md`. Cola copiada exactamente a esta rama (blob SHA `0f3f1af220dab2e2197b0f181a6f113a544828a6`).
- 49 MT activas, 10 bloques: 9 de 5 y el 10 de 4. La cola incluye 28 MT202–229 y 21 anteriores no cubiertas. Las 19 históricas sin versión SV quedan fuera. No alterar catálogos o learnsets.

## Bloque 01 autorizado — mapeo `scarlet-violet`

| MT | Movimiento |
| --- | --- |
| `tm202` | `pain_split` |
| `tm203` | `psych_up` |
| `tm204` | `double_edge` |
| `tm205` | `endeavor` |
| `tm206` | `petal_blizzard` |

## Preparación técnica y commits

- **CI bootstrap estructural:** el workflow propio `.github/workflows/parallel-camp006-w05-autoci.yml` se configuró y reparó en la rama W05. El primer run [#41763714954](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763714954) falló antes de ejecutar jobs por YAML inválido; se aisló una sustitución de cadenas en los `grep` de regresión que duplicaba bloques. Corrección mínima commit `76196545511d694052d2eea9a56bdc7d70f2d2f0`.
- **Bootstrap CI aprobado:** [#41763897134](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763897134), SHA de workflow reparado `76196545511d694052d2eea9a56bdc7d70f2d2f0`, `completed/success`, recibo `CAMP006_W05_MANIFEST_PASS reserved=10 completed=0 ids=49 kind=NEW_IDS` y `BOOTSTRAP_NO_FUNCIONAL`. No cuenta como prueba de enseñanza.
- Nuevo manifiesto `tests/tools/test_parallel_items_w05_campaign_006_manifest.py` (commit `d9e870e1687e0ed3e2e0c0c09e500d3032138aed`): verifica las 49 MT seleccionadas y mapeadas SV, sin repetir IDs de CAMP003/004/005, cuotas 5×9 + 4 y rechaza recibos sin checks positivos.
- Nuevos ejecutores: Python `tests/tools/test_parallel_items_w05_campaign_006.py` (commit `3e614424481dd6d1546a84dfb78736fdf782a480`), Godot `tests/gameplay/parallel_items_w05_campaign_006.gd` (commit `91c8a3d0d3c65e30e2169b669ea7f11694d99a6e`). Ambos conservan los contratos positivos y negativos heredados de CAMP005; Godot comprueba `FieldItemService.teach` real, learnset compatible/incompatible, propietario, PP, stock, consumo, identidad, rechazo sin mutación y SaveV2. No se ha creado un servicio paralelo.
- Fixture `tests/fixtures/parallel_items/w05_campaign_006.json` con bloque 01 y cinco mapeos, commit `450b10b189585977a3f30f044c95d38d1ab9062b`. Progreso `reports/W05/CAMP_006_PROGRESO.csv`, fila 01 `EN_CI_AUTOMATICA` commit `6eee6ccf80d41bae36063d1653babf085293426e`, que activa CI funcional.
- Cotejo estático tras publicación: un bloque, una fila, cinco IDs únicos y parejas exactas de cola oficial IA6/perfil SV: PASS. **Esto no prueba aún efectos de motor.**

## CI funcional y regresiones

- [CI funcional #41764007067](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764007067) sobre SHA `6eee6ccf80d41bae36063d1653babf085293426e` observada inicialmente en ejecución.
- Para cerrar bloque 01 exigir `completed/success`, `CAMP006_W05_PY PASS blocks=1 checks=N`, `CAMP006_GATE_PY_PASS worker=W05 blocks=1 checks=N`, `CAMP006_W05_GODOT PASS blocks=1 checks=N`, `CAMP006_GATE_GODOT_PASS worker=W05 blocks=1 checks=N`, con N positivo.
- Hito 01 de regresión según gate: el workflow ejecuta CAMP005, CAMP004 y CAMP003 (10 bloques por campaña) con pruebas Python y Godot. **No afirmar regresión aprobada sin comprobar los seis recibos de este run.**

## Continuidad y límites

La siguiente `p` debe verificar primero la CI 01. Con PASS, ejecutar solo bloque 02 `tm207;tm208;tm209;tm210;tm211`; cinco casos exactos. Si alguna enseñanza positiva no está disponible, identificar dependencia concreta (origen, contrato, consumidor, prueba pendiente y propietario IA6), no sustituirla por pruebas exclusivamente negativas. Reparación autónoma V5 solo en W05 sin modificar catálogo, learnsets, política o componente ajeno.

Prohibido tocar `main`, V28, PR118, árbitra, otras ramas, máquinas históricas inactivas o hacer merge. Las pruebas Godot headless no validan interfaz/GPU. Al 10/10 declarar `CAMPAÑA_006_FINALIZADA` y STOP.
