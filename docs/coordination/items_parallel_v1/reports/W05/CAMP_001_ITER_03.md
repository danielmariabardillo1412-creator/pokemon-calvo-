# W05 — CAMPAÑA_001, ITER_03

**Estado:** PREPARADO_PENDIENTE_CI. Tercer microbloque, no certificado en Godot todavía.

- Permiso: `CAMPAIGN_GATE_UPDATE_004.md`, blob `5a96d80793d0c438ee005d366655f42e9cd4074b`.
- Base sincronizada sin force, merge W05 `dcfce415e94e574a41c8d9da0ec1940a4e12ac9e`.
- ITER_02 tiene PASS Godot 959/0 y Python 14/14: Actions #41362733419 (no certifica ITER_03).
- Código nuevo de ITER_03: solo pruebas en `tests/gameplay/parallel_items_w05_machine_books_v1.gd`, commit `c48491a3e50f0386cec76d72402b1e5cdcd4d3e3`.
- Scope: 248 MACHINE seleccionadas; 229 SV activas, 19 heredadas rechazadas, ningún ID faltante o duplicado en comprobación estática.
- Muestras de enseñanza con `FieldItemService.teach`: tm01/take_down, tm02/charm y tm77/waterfall. Compatibilidad de especie desde learnset real.
- Contratos preparados: movimiento y PP, consumo 2→1, identidad/propiedad, rechazo sin stock, criatura ajena, bloqueo de campo, repetición sin doble gasto.
- Las 19 heredadas se prueban con inventario real: rechazo `machine_not_in_active_version`, sin modificación del propietario ni consumo.
- Guardado/carga aislados de tm01 y limpieza de ruta de test específica, no edición de partidas de usuario.
- Reutilización: `FieldItemService.teach` permanece sin cambios. El adaptador de libros carece de implementación duplicada de enseñar o gastar.
- Pruebas ITER_02 de 229 etiquetas y 19 rechazos conservadas, así como informe LOTE_001/002 y política de versiones.
- Verificación en GitHub de perfil y código: PASS ESTÁTICO. Godot de ITER_03, GPU, UI y arte: SIN_EJECUTAR.
- Comando CI: `godot --headless --path . --script res://tests/gameplay/parallel_items_w05_machine_books_v1.gd`.
- IA6 debe ejecutar nueva CI del SHA integrado, comprobar regresiones y clasificar fallos, sin falsificar fixtures.
- No tocar main, V28, árbitra, otras W, guardados, catálogo, FieldItemService, aprendibilidad ni 19 máquinas históricas.
- Tras reportar FINAL: `CAMPAÑA_001_FINALIZADA` como entrega 03/03, STOP hasta nueva orden.
