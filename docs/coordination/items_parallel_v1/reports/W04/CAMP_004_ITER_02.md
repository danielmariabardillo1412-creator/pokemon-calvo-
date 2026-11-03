# IA4/W04 — CAMPAÑA_004 — ITER_02

**Rama:** `codex/calvo-items-20261103-w04-camp004`. **Fecha:** 2026-11-03.

**Objetos exactos:** `love_sweet`, `ribbon_sweet`, `star_sweet`. No repetir `berry_sweet`, `clover_sweet`, `flower_sweet` como nuevos objetos: su regresión queda dentro del runner acumulativo.

## Contrato real y resultado pendiente

Fuentes originales `data/api/v2/item/1168/index.json`, `1173/index.json`, `1172/index.json`: categoría `evolution` y descripción inglesa de **Milcery con confite equipado y giro**. En `modules/creatures/progression/evolution_system.gd` el disparador `spin` está clasificado como `UNSUPPORTED`. No se inventa evolución directa por bolsa ni se afirma implementación de formas de Alcremie.

El runner Godot `tests/gameplay/parallel_items_w04_campaign_004.gd`, commit `b6e6e514182faaac035d58d448cfc524d9e75a9d`, suma `BLOQUE_02` a `BLOQUE_01`: descubre registros reales de evolución para cada confite, verifica clasificaciones, rechazos al usarlo en Eevee y Milcery, ausencia de consumo o mutación; si el servicio permite equiparlo, comprueba equipamiento, ausencia de evolución automática, recuperación y SaveV2. Solo si aparece una ruta `RUNTIME_SUPPORTED` por `use_item` se comprueban positivos, consumo unitario, identidad y guardado.

El fixture `tests/fixtures/parallel_items/w04_campaign_004.json`, commit `40d808eac07900172762b20860c15bf6c2f0c603`, añade el bloque 02 con 3 IDs y conserva el 01. El validador Python `tests/tools/test_parallel_items_w04_campaign_004.py`, commit `b4de4a2823fccf54cfae354ca63501db8bb66b8d`, coteja reserva, progreso, fuente PokeAPI, runner y regresiones conservadas. Progreso `reports/W04/CAMP_004_PROGRESO.csv`, commit `b74dbd8f73bb5f46b5df851aa580f15d4ab81e00`.

**Estado de entrega:** pruebas publicadas, `EN_CI_AUTOMATICA`. Es obligatorio revisar los recibos `CAMP004_W04_PY PASS blocks=2 checks=M` y `CAMP004_W04_GODOT PASS blocks=2 checks=M`, además de las regresiones CAMP003, en el run creado por el commit de progreso.

**Dependencias preservadas:** 3 confites del bloque 01 y 16 IDs de CAMPAÑA_003 permanecen pendientes de efecto funcional. No se ha cambiado producción, `main`, V28, otras ramas, catálogo, workflows ni reglas generales.

**Siguiente `p`:** únicamente bloque 03/10, `strawberry_sweet;whipped_dream;leaders_crest`, previa comprobación de CI02. No iniciar bloque 03 dentro del presente encargo.
