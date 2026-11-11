# W05 — CONTINUOUS_V2 · READY_FOR_IA6 · Cierre B01+B02+B03
Fecha: 2026-11-11 (Europe/Madrid). Rama exclusiva: codex/calvo-items-20261109-w05-books-ui.

**Estado de CAMPAÑA W05: B01/B02/B03 completadas en su alcance autorizado (3/3).**
**Objetos nuevos: 0.** Anteriormente certificados en panel independiente: **229/229 libros SV**.
**Integración L3 dentro de la mochila real: NO.** L3 verificado: panel UI Godot headless + FieldItemService real + SaveV2.
**Bloqueados internos W05: 0.** Dependencia de módulo central IA6: montaje en FieldItemBag y coexistencia integrada con W03.

## CI real y trazabilidad
- SHA de CÓDIGO que probó la CI: 426021c41b75d42cd2ee112ed4446f11e166ec54.
- Run: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42929830881
- Estado: completed/success, jobs verify y W05 TANDA05 - Windows PCK/runtime isolation ambos SUCCESS.
- Los commits posteriores del ticket y el checkpoint son sólo documentación. Ninguna modificación a módulos de producción, perfiles ni presets, ni a main, V28, PR118 o ramas ajenas.

## B01 — Interfaz y servicio auténticos
El job verify mantiene TANDA01/TANDA02/TANDA03/TANDA04 y regresiones CAMPAÑA003–006 y pilotos W05. Referencia histórica, **sin recertificar 229 objetos nuevos**.
Nuevo runner Godot: tests/gameplay/parallel_items_w05_continuous_v2.gd.
Recibo: W05_V2_CONSUMER_GODOT PASS live_service=1 real_panel=1 accepted=1 duplicate_spend=0 storage_rejection=1 locked_rollback=1 savev2=1 actual_bag=NOT_MOUNTED w03_coexistence=IA6_PENDING checks=58.
La prueba cubre bind del mismo servicio, select_book, select_creature, select_replacement_slot, teaching_finished único, PP canónicos, consumo unitario, sin doble gasto, propietario Storage, bloqueo de sesión y roundtrip SaveV2. El consumidor sigue siendo **un harness de panel aislado**.

## B02 — Windows PCK, textos, tamaño y límites
Godot 4.7 generó desde CI ambos artefactos temporales (no entregables finales):
- EXE Windows cabecera MZ y 635.389.864 bytes.
- PCK 526.370.204 bytes.
- Cambio EXE anterior (635.385.472 B): **+4.392 B**. Guarda de regresión máximo +10%: 698.924.019 B; **PASS**.
- Proyecto Godot vacío montó PCK y leyó 229 etiquetas con helper real cargado desde el paquete, muestras tm01, tm75, tm202, tm229: W05_V5_PCK_PROBE PASS records=229 runtime_samples=4 helper=1 source=pck_only.
- Fallback JSON inexistente y JSON inválido: ambas pruebas Godot PASS.
- Conteo de workspace versionado: 19.888 archivos. Directorio data: 15.683 archivos, 502.084.984 bytes en workspace. **Esto NO es un manifiesto exacto de miembros PCK.**
- W05_V2_PACKAGE PASS exe_bytes=635389864 pck_bytes=526370204 growth_guard_bytes=698924019 tracked_workspace_files=19888 windows_runtime_manual=UNVERIFIED android=UNVERIFIED.
No se ejecutó EXE en sistema operativo Windows, no se probaron FPS/GPU, no se creó instalador, no existe certificación Android. El umbral 10% es un límite contra regresiones, **NO un objetivo de peso comercial**, que exige auditoría IA6 antes de publicar.

## B03 — Contrato ejecutable para IA6
- Ticket exacto y matriz de aceptación: docs/coordination/items_parallel_v1/CONTINUOUS_V2/W05_IA6_ACCEPTANCE.md.
- Puerta actual de W05: W05_V2_CONTRACT PASS books=229 source_es=229 teach_entrypoints=1 historical_regressions=preserved real_mount=pending_ia6.
- El comando python -B tests/tools/test_parallel_items_w05_continuous_v2.py --require-integrated debe fallar en W05 por ausencia real de montaje; se entrega a IA6 como prueba estática roja y futura verde, **sin simular aceptación dinámica**.
- IA6 deberá montar el panel en su propia FieldItemBag, bindear mismo servicio, transmitir IDs y slot, conectar teaching_finished una vez, actualizar UI/HUD sin segunda llamada a teach/use_item y conservar las rutas de Cuerda Huida y repelentes W03.
- IA6 ejecutará aceptación Godot integrada de mochila real (click y gasto x1, duplicidad, cambios Party/Storage, rollback, SaveV2 manual y coexistencia W03) y prueba manual Windows.

## Riesgos que no se ocultan
1. No hay montaje real en FieldItemBag, que sólo puede cambiar IA6.
2. No hay prueba conjunta de Cuerda Huida/repelentes W03 desde la mochila integrada.
3. 635 MB es un tamaño de EXE elevado; el control de crecimiento NO reduce el paquete ni evalúa distribución comercial.
4. Diferencia textual preexistente: light_screen se llama Pantalla Luz en CORE global frente a Pantalla de Luz en fuente PokeAPI libro. W05 no debe editar SpanishGameText.
5. Android sigue sin preset/exportación certificados.

## Regla de cierre
**READY_FOR_IA6.** La campaña W05 CONTINUOUS_V2 queda agotada: B01/B02/B03 terminados con pruebas y CI completa. Ninguna fase independiente autorizada restante. Detenerse, no crear tandas 06/07, no repetir 229 checks como trabajo nuevo ni tocar módulos compartidos. Si IA6 modifica la orden permanente en el futuro, aplicar la nueva orden desde HEAD con la próxima p.
