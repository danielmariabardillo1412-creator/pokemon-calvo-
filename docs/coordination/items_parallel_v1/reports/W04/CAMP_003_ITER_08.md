# IA4/W04 — CAMPAÑA_003 / Microbloque 08

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp003`  
**Fecha:** 2026-11-03  
**Estado:** 08/10 PUBLICADO; `EN_CI_AUTOMATICA`, no declarar PASS funcional sin ejecutar y revisar GitHub Actions para el nuevo SHA.

## Objetos de la cola
- `chipped_pot`
- `cracked_pot`
- `masterpiece_teacup`

## Puerta previa
[GitHub Actions #41570669025](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570669025) sobre SHA `5f71282d1d77e89610a586618c95bd666991478a` terminó `completed/success`: **Python 79 checks, Godot 129 checks**. Los registros indican que los tres objetos del bloque 07 tienen rutas `DATA_ONLY` con condiciones y no son evoluciones jugables certificadas.

## Tests acumulativos del bloque 08
- `tests/gameplay/parallel_items_w04_campaign_003.gd` — commit `874d5f9646a2e5ce9265d64ee2ad50ad89e67ada`. Ejecuta bloques 01–08; descubre reglas reales de catálogo por objeto y publica `CAMP003_W04_FORMA` con origen, destino y condiciones, sin inventar variantes. Para registros `base_form` que no coincidan con la especie de origen, exige clasificación **distinta de `RUNTIME_SUPPORTED`**. Ejecuta control negativo de especie incompatible (Eevee): opciones vacías, uso rechazado, cantidad intacta 2 y snapshot serializado sin cambios. Para ruta condicionada sin soporte, conserva las pruebas de rechazo/sin consumo; para `TRIGGER_USE_ITEM` + `RUNTIME_SUPPORTED`, conserva positivo, identidad, inventario y SaveV2.
- `tests/fixtures/parallel_items/w04_campaign_003.json` — commit `4ec3947aac9300de05b812f01390e729fee40057`. Añade bloque 08, preservando las siete filas anteriores.
- `tests/tools/test_parallel_items_w04_campaign_003.py` — commit `9f17d58f5724a3a82901c41b5b1bc1310a706257`. Comprueba progreso/fixture/IDs bloque 08, cobertura del runner y aserciones de forma e incompatibilidad.
- `reports/W04/CAMP_003_PROGRESO.csv` — commit `f0c33388cb7e6ef428c3b80142a6170b1be69b5f`, actualiza 07 a `CI_PASS_VERIFICADO` con run y registra el 08 como `EN_CI_AUTOMATICA`.

## Alcance y límites
Sin ediciones en `main`, V28, producción, catálogo canónico, políticas, workflows u otras trabajadoras. La existencia de una entrada de evolución por forma no equivale a disponer de motor de formas completo: las condiciones ausentes o clasificadas `DATA_ONLY` son **DEPENDENCIA_DOCUMENTADA**, no PASS de funcionalidad de especie. No se equipara el uso de una tetera a la evolución de cualquier forma.

**Pendiente:** confirmar CI del bloque 08 con recibos reales `CAMP003_W04_PY PASS blocks=8 checks=M` y `CAMP003_W04_GODOT PASS blocks=8 checks=M`. Ante fallo, corregir dentro de la especialidad conforme a `AUTONOMOUS_REPAIR_V5.md` y conservar regresiones.

**Siguiente `p`:** bloque 09 (`unremarkable_teacup`, `sweet_apple`, `tart_apple`), previa consulta de la CI 08.
