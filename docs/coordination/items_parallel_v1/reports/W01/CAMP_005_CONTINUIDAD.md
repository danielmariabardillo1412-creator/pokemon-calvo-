# IA1/W01 — CAMPAÑA_005 — Continuidad y bloqueo CI

**Repositorio:** `danielmariabardillo1412-creator/pokemon-calvo-`
**Rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`
**Coordinación/solo lectura:** `codex/calvo-items-20261101-arbitro`

## Estado real tras primer encargo
- CAMPAÑA_004 previa: 10/10 CI aprobada #41733777992, evidencias heredadas, NO se recontarán como nuevos.
- CAMP005 bloque 01 autorizado `black_glasses;dragon_fang;hard_stone`. Fixture, validador Python y runner Godot funcional diseñados para 9 escenarios, 12 pares semilla, 36 controles de equipamiento con SaveV2; además progreso e informe `CAMP_005_ITER_01.md`.
- **No existe workflow aplicable a `codex/calvo-items-20261104-w01-camp005`**. El heredado `parallel-camp004-w01-autoci.yml` solo escucha la rama antigua y ejecuta contrato CAMP004. CI inicial de CAMP005: ningún run.
- El bloque 01 queda `DEPENDENCIA_DOCUMENTADA`, no `CI_PASS_VERIFICADO`; **no se ha observado ningún resultado funcional nuevo**. Ejecutar/crear CI corresponde a IA6 por V5. Los errores concretos de Godot, si los hubiera, solo podrán diagnosticarse tras el primer run.
- Invariantes: una `p` autoriza solo un bloque; sin CI 01 no avanzar a 02. No tocar `main`, V28, la rama árbitra, otras ramas, políticas comunes, ni producción ajena.
- Próximo paso de IA6: workflow con Godot 4.7, Python 3.11, Node22, recibos `CAMP005_W01_PY/GODOT PASS blocks=1` con checks positivos y **regresión CAMP004 completa en el mismo run** (hito 01), además de 05/10.
- Una vez CI tenga resultado, W01 diagnostica/recupera bloqueo, certifica 01 con SHA/run y queda preparada para bloque 02 `miracle_seed;mystic_water;never_melt_ice`.

Consultar para detalles mecánicos y requisitos de CI `CAMP_005_ITER_01.md`. Sin permiso nuevo de IA6 no modificar workflows.

## Recuperación CI y bloque 02 — trabajo autorizado

- IA6 instaló workflow propio `.github/workflows/parallel-camp005-w01-autoci.yml` en W01; la antigua dependencia de CI **queda resuelta**. Run [#41767517526](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767517526), SHA `bd33aeb3f993804c3c85217b81892356af39aac5`, **SUCCESS**: bloque 01 Python 88 PASS / Godot 1109 PASS, regresión CAMP004 íntegra Python 1028 PASS / Godot 16816 PASS. Registrar fila 01 `CI_PASS_VERIFICADO`.
- Con esta `p` se autoriza exactamente el bloque 02 `miracle_seed;mystic_water;never_melt_ice`. Positivos: `energy_ball`, `surf` e `ice_beam`; negativos `tackle` y `reflect` por objeto. Cada caso en modos activo/ausente/reserva con misma semilla; SaveV2, identidad y consumo. Nueve escenarios, doce pares, 36 variantes. Acumulado: seis objetos, 18 casos, 24 pares, 72 variantes. Código de producción inalterado.
- Esperar recibos `CAMP005_W01_PY PASS blocks=2 checks=N` y `CAMP005_W01_GODOT PASS blocks=2 checks=N` con N positivo y run `completed/success` sobre SHA del bloque 02. Si falla, diagnosticar y reparar rama propia según V5, no reducir aserciones.
- Regresión completa CAMP004 aprobada hito 01; nueva ejecución obligatoria en hitos 05 y 10 o tras cambios de producción. No inventar integración global, UI o GPU. Incidencia anterior SaveV2 en carga intermedia de Rayo Solar continúa pendiente para IA6.
- **Próxima `p` solo después de CI positiva:** bloquear cierre documental de 02 con SHA/run y ejecutar bloque 03 `poison_barb;sharp_beak;silk_scarf`. Nunca tocar `main`, V28, árbitra ni ramas ajenas.

## Bloque 02 — certificación real CI

La ejecución [GitHub Actions #41778911208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778911208) ha terminado `completed/success` sobre el **SHA de pruebas** `69438bfb81921456a87eb7da18b3442f50c79873`. Recibos extraídos del job:
- `CAMP005_W01_SCOPE PASS blocks=2`
- `CAMP005_W01_PY PASS blocks=2 checks=148`
- `CAMP005_W01_GODOT PASS blocks=2 checks=2207`

**Estado funcional: bloque 02 aprobado, 2/10 verificados**, 6 objetos, 18 escenarios, 24 pares caso-semilla y 72 variantes, con comparaciones nativas y SaveV2. Workflow y motores previos sin cambios en este commit. El workflow omitió legítimamente la regresión completa CAMPAÑA_004 en hito 02, ya verificada en el run del hito 01 #41767517526; volverá en hitos 05 y 10 o por parche de producción.

La fila 02 del CSV queda temporalmente `EN_CI_AUTOMATICA` para no disparar CI por el cierre documental. En la **siguiente `p`**, certificarla con `CI_PASS_VERIFICADO`, SHA `69438bfb81921456a87eb7da18b3442f50c79873` y run `41778911208` antes de insertar la fila 03. El siguiente microbloque, y solo ese, es `poison_barb;sharp_beak;silk_scarf`.

La incidencia SaveV2 del turno de carga de Rayo Solar de CAMPAÑA_004 sigue pendiente para IA6; no hay prueba visual/GPU ni integración en main/V28. **STOP en 02/10 hasta nueva `p`**.

## Bloque 03/10 — entrega y matriz acumulativa

- **B02 certificado:** CI [#41778911208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778911208), SHA `69438bfb81921456a87eb7da18b3442f50c79873`, `CAMP005_W01_PY PASS blocks=2 checks=148`, `CAMP005_W01_GODOT PASS blocks=2 checks=2207`. Fila 02 en `CI_PASS_VERIFICADO`.
- **B03 autorizado** `poison_barb;sharp_beak;silk_scarf`: golpe positivo `sludge_bomb`, `aerial_ace`, `tackle`, respectivamente; negativo `tackle`, `tackle`, `water_gun`; control no dañino `reflect`. Es esencial que Pañuelo de Seda potencie Placaje y que **Pistola Agua**, no Placaje, sea su control de tipo diferente.
- Nueve casos nuevos, doce pares y 36 variantes. Acumulado 3 bloques, 9 objetos, 27 casos, 36 pares, 108 variantes; tres modalidades equipamiento activo/ausente/reserva con owner y SaveV2, sin recortar escenarios anteriores.
- `CAMP005_W01_PY PASS blocks=3` y `CAMP005_W01_GODOT PASS blocks=3`, run `completed/success`, son la condición de cierre de B03. No atribuir aprobación por construcción de blobs ni basarse en el PASS de B02; revisar los logs y reparar con V5 si falla.
- No se modifican motor, workflow, main, V28, rama árbitra, PR #118 ni ramas W02-W05. La regresión integral CAMP004 corresponde al hito 05/10, 10/10 o parches de producción; el run previo del hito 01 está aprobado.
- Próxima `p` (solo si B03 PASS): bloque 04 `silver_powder;soft_sand;spell_tag`. Incidencia SaveV2 de Rayo Solar a media carga heredada de CAMP004 continúa para IA6, sin proclamar corrección ni integración global.
