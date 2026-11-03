# IA4/W04 — Cierre técnico de CAMPAÑA_003

**Identidad:** IA4/W04, objetos evolutivos.  
**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp003`.  
**Alcance:** 10 microbloques, 30 IDs de `CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv`, todos entregados.  
**CI final ejecutada:** [#41573737061](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573737061), SHA `5622c3d3e8927b7da4cba8c587c81ab4997c5bab`, `completed/success`.

## Recibos verificados en logs
- `CAMP003_W04_PY PASS blocks=10 checks=120`
- `CAMP003_W04_GODOT PASS blocks=10 checks=270`
- Regresión histórica independiente CAMPAÑA_001: `PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=3 checks=559 cases=12`

El workflow también pasó alcance y recuento de diez filas, importación de Godot 4.7 y validación de recibos. La CI acredita los contratos implementados y los rechazos de rutas incompatibles, **no** que toda evolución documentada esté jugable.

## Resultado por comportamiento real (30 IDs)
**14 con evolución positiva observada en Godot:**
`dusk_stone`, `shiny_stone`, `sun_stone`, `black_augurite`,
`auspicious_armor`, `malicious_armor`, `metal_alloy`,
`chipped_pot`, `cracked_pot`, `masterpiece_teacup`,
`unremarkable_teacup`, `sweet_apple`, `tart_apple`, `syrupy_apple`.

**10 sin regla asociada en catálogo normalizado:** `oval_stone`,
`dragon_scale`, `dubious_disc`, `electirizer`, `magmarizer`,
`protector`, `reaper_cloth`, `prism_scale`, `sachet`, `up_grade`.

**6 con registro evolutivo clasificado `DATA_ONLY`:**
`dawn_stone`, `galarica_cuff`, `galarica_wreath`, `peat_block`,
`scroll_of_darkness`, `scroll_of_waters`.

Los dos pergaminos registran `kubfu -> urshifu` con condiciones
`evolved_form=urshifu_single_strike` y `evolved_form=urshifu_rapid_strike`;
el motor actual no las admite como evolución ejecutable. No alterar la modalidad.

**Limitación adicional de formas:** los positivos con teteras, manzanas y otras rutas muestran condiciones `{}` para sus registros de origen. La prueba confirma evolución básica, inventario, identidad y SaveV2, pero NO demuestra selección correcta entre todas las formas cuando faltan condiciones. No afirmar ese alcance.

## Cambios y fronteras
Se modificaron solo las pruebas `tests/gameplay/parallel_items_w04_campaign_003.gd`, `tests/tools/test_parallel_items_w04_campaign_003.py`, `tests/fixtures/parallel_items/w04_campaign_003.json` y reportes propios W04. **No** se modificaron producción, `main`, etiqueta V28, otra rama, catálogo canónico ni workflow. La campaña está completa como **auditoría y pruebas de 30 IDs**, no como implementación funcional de los 30.

**Para IA6:** mantener 16 dependencias en backlog y no integrarlas como funcionales. Revisar políticas de formas, intercambio y nivel/objeto equipado antes de cualquier implementación compartida. Verificar integraciones globales/visuales por separado. Esta trabajadora **STOP** tras el cierre 10/10; no crear CAMPAÑA_004 por iniciativa propia.
