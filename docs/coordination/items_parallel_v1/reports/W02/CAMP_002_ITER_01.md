# W02 / CAMPAÑA_002 — ITER_01: Zidra (Sitrus) y Ziuela (Lum)

**Estado:** `PREPARADO_PENDIENTE_CI`. **Solo bloque 01/03 ejecutado; no se afirma PASS Godot/Python de CAMP_002.**
**Rama exclusiva nueva:** `codex/calvo-items-20261102-w02-camp002`, HEAD inicial `67959eb8f19abfd2ae391872747a14f603fcab01` confirmado contra manifiesto. Sin mezcla con rama vieja.
**Autoridad:** `CAMPAIGN_GATE_002.md` blob `ebc787803599e2b13cbd24c169b69112d18f7a42`; `CAMP_002_W02.md` blob `8e52a9f9e740eaee6210494ffaa764ce1ad9c644`.
**IDs exactos:** `sitrus_berry` y `lum_berry`. `leppa_berry` y `figy_berry` quedan exclusivamente para ITER_02.
**Cuatro escenarios declarados:** Sitrus por debajo del umbral y por encima (consumo sí/no); Lum envenenado y sin estado (consumo sí/no). Por caso se prueban portador activo, sin baya y baya en reserva: **12 ejecuciones nativas previstas**.
**Prueba real prevista:** arnés reutiliza por herencia `parallel_items_w02_berries_v1.gd` (W02 LOTE_002 histórico ya verificado), sin duplicar reglas; comprueba HP 1/4, estado curado, stock inicial 2 y final 1/2, propietario de reserva, cierre FLED, restauración de sesión y SaveV2.
**Integridad:** cada variante deja JSON real con SHA-256, captura de frontera nativa antes del turno y dueño después; Python comprueba los recibos y bloquea resultados agregados falsos.
**Campo:** `sitrus_berry` y `lum_berry` **sí están registrados** en `modules/inventory/imported_recovery_v19.json` (Sitrus cura cuarto; Lum cura estado/confusión). **No se ejecutó uso de campo en ITER_01**: `field_scope=NOT_TESTED_ITER_01`; no presentarlo como fallo o ausencia funcional.
**Fixture nuevo:** `tests/fixtures/parallel_items/w02_campaign_002.json`, blob `3c9b7c6f4a7449d295e8f05fc2c7b44aaeb5ed4d`, commit `7b1b4485a113d83fe4b2fc308daa0c3385c2a9df`.
**Runner nuevo:** `tests/gameplay/parallel_items_w02_campaign_002.gd`, blob `53b70033578f1a31c13081f558334bacf247ada5`, commit de corrección de errores de fixture `8d75f68cbdf791d4f8641da442be823cf03fda74`.
**Validador nuevo:** `tests/tools/test_parallel_items_w02_campaign_002.py`, blob `0325554ac8bd329ee920b0a14f4d5037d98818c6`, commit `843c0def127a8fd9922890370d4dff82755090f1`; **13 unittests definidos**, aun sin ejecución.
**Verificación realizada:** 22/22 inspecciones ESTÁTICAS de GitHub: IDs, contratos, controles, matriz, parent Godot, fuente real, recibos, integridad, límites y conservación de `CAMP_001` integrado.
**SIN_EJECUTAR:** comandos Python `--fixture-only` / `--unittest`, Godot 4.7, postvalidador `--result`; ninguna prueba visual/GPU. Los CI base PASS #41364601482 / #41364601486 (SHA `a8e09dbf`) NO prueban estos archivos.
**Comandos para IA6:** `python tests/tools/test_parallel_items_w02_campaign_002.py --unittest`; `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_002.gd`; `python tests/tools/test_parallel_items_w02_campaign_002.py --result .godot/parallel_items/w02_campaign_002/godot.json`.
**Permisos respetados:** solo rutas nuevas de pruebas W02 y docs W02; cero cambios en `main`, V28, rama antigua, otras W, política, producción, saves, motor, `config`, `data`, `.github`.
**Próximo `p`:** ITER_02, Leppa y Figy; verificar contrato nativo PP y naturaleza ANTES de generar expectativas para Figy. En caso de perfil ausente, `BLOQUEO_DE_PERFIL`, no adivinar.
