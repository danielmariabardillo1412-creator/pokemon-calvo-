# W02 / CAMP_001 — ITER_03 (regresión y matriz de seis bayas)

**Estado:** `PREPARADO_PENDIENTE_CI` (03/03, último microbloque). **No atribuir PASS Godot/Python nuevos.**
**Identidad:** IA2/W02; rama exclusiva `codex/calvo-items-20261101-w02`.
**Órdenes:** `campaigns/CAMP_001_W02.md` blob `f6f8f08b13f9e4f84d18970643ebd4aeab5a75b7`; puerta `CAMPAIGN_GATE_001.md` ACTIVADA, blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`.
**Base sincronizada:** árbitra HEAD `a710d8abe2e94f11974488c4563b9eb80ede5bbc` incorporado con merge no forzado `7cbbf780e6cd36251327018f20c127e53a25c415`, solo cambio STATUS documental.
**IDs cubiertos:** `oran_berry`, `pecha_berry`, `cheri_berry`, `persim_berry`, `chesto_berry`, `rawst_berry`.
**Regresión:** sin escenarios nuevos fabricados; 16 positivos/negativos existentes ahora agrupados por 6 descriptores independientes con nombres, perfil de campo y expectativas explícitas. 48 variantes nativas y 32 de campo previstas; cada prueba tiene verificación de stock, titular, descarte, SaveV2, SHA256 de recibo.
**Por ID:** Aranja 2 casos (PS/lleno); Meloc 3 (veneno/quemadura/sano); Zreza 3 (parálisis/veneno/sano); Persim 2 (confusión/sin confusión); Chesto 3 (Spore/quemadura/sano); Rawst 3 (quemadura/veneno/sano). Un éxito aislado no permite marcar seis PASS.
**Fixture:** `tests/fixtures/parallel_items/w02_campaign_001.json` blob `8840b37569270054757dc2728af66f882af44db6` (commit `b5a27e10a789b833e57219d135307944d87d3f95`), `coverage_matrix`, `microblocks_completed=[1,2,3]`.
**Godot:** `tests/gameplay/parallel_items_w02_campaign_001.gd` blob `0f66aeab576d099d7de215c27eb5a2746cdcfb0a`; desglosa `per_item` y bloquea PASS global si un ID falla. Último commit `bfb2091f3e433aad936fc26bdd7c7d9d960d4b33`.
**Python:** `tests/tools/test_parallel_items_w02_campaign_001.py` blob `aadad7a50e013d831f908c9b4c6585f0a412575b`, commit `599fa0b1a1af1fe82c3023aaf70816fdeefd44af`; valida descriptores exactos, recibos per-ID y 18 tests negativos/estructura, **sin ejecución de Python aún**.
**Validación:** 25/25 inspecciones **estáticas GitHub** PASS, 0 fallos estáticos observados; Python unittests, Godot 4.7 y GPU **SIN_EJECUTAR** para CAMPAÑA_001.
**Deuda registrada:** Persim tiene comportamiento de confusión al equiparse, pero no está registrada en perfil de cura desde mochila (`imported_recovery_v19.json`); tests esperan rechazo, sin inventar cambios en producción.
**CI anterior no aplica:** [run #41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320) PASS 503 W02 checks para Zidra/Ziuela/Dillo, no para estos seis IDs ni el árbol actual.
**Próxima acción de IA6:** integrar los tests de esta rama en checkpoint de revisión y ejecutar `python tests/tools/test_parallel_items_w02_campaign_001.py --unittest`; `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_001.gd`; `python tests/tools/test_parallel_items_w02_campaign_001.py --result .godot/parallel_items/w02_campaign_001/godot.json`.
**Restricciones:** solo tests exclusivos e informes de W02, cero modificaciones producción, RNG, workflows, selección, SaveV2, datos ni otras ramas; LOTE_001/002 e ITER_01/02 conservados byte a byte.
**Cierre:** ninguna continuación autorizada dentro de CAMPAÑA_001 después de ITER_03. Consultar `CAMP_001_FINAL.md` y detenerse hasta nueva orden de IA6.
