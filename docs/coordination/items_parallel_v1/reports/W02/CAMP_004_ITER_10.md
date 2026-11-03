# IA2/W02 — CAMP004, bloque 10/10 — entrega cerrada

Rama exclusiva: `codex/calvo-items-20261103-w02-camp004`. Autoridad: gate IA6 y fila 10 de `CAMPAIGN_004_W02_QUEUE_APPROVED.csv`. No se modificaron main, V28, otras ramas, producción ni workflows.

## Cuatro objetos nuevos

| ID | Escenarios | Contrato real |
| --- | ---: | --- |
| shalour_sable | 7 | Cura estados persistentes y confusión; seis positivos de estados y confusión, un sano rechazado |
| soda_pop | 5 | Restaura 50 PS; límites, sano rechazado, veneno/confusión preservados |
| super_potion | 5 | Restaura 60 PS; límites, sano rechazado, veneno/confusión preservados |
| sweet_heart | 5 | Restaura 20 PS; límites, sano rechazado, veneno/confusión preservados |

Fuente canónica: `modules/inventory/imported_recovery_v19.json` y `field_item_effects.gd`. Los casos usan el runner Godot preexistente para `field_medicine`: PARTY con y sin objeto y STORAGE con objeto; consumo atómico, estados, HP/PP, amistad, EV, SaveV2 y recibos SHA256. Son pruebas diseñadas, no resultados de CI.

## Publicaciones y estado

Fixture: `caf1249f5381506c380084721b5484855c93f7b4`; validador Python (golden de 22 casos, fuente y 6 negativos): `b544289bd2f6e855963ad6a2a39ed69423502aaa`, `c732cfe8d84f92ea3a59a84370ab13b457c48461`, `9eaca581d3388704fb92401a1f9408bcd17f6e9e`, `78b2943be16ecb169067bc2d040ac1845499103e`. Progreso décima fila `ENTREGADO_PENDIENTE_CI`: `3c633256bb75b19e569242072ba2c5b31003b879`.

**Campaña entregada 10/10:** 40 IDs, 187 escenarios, 561 variantes de prueba previstas. No equivale a 40 objetos funcionalmente certificados. CI PASS comprobada solamente para bloque 01 en [Actions #41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223), con regresión CAMP003; bloques 02–10 SIN CI verificada por limitación de consulta de runs de push. No afirmar PASS/FAIL sin logs con SHA.

Dependencias sin funcionalidad positiva: `razz_berry` (02) y `hopo_berry` (06). Requieren decisión IA6; los casos actuales verifican rechazo, no efecto útil.

**Traspaso:** IA6 debe comprobar Python/Godot CAMP004 `PASS blocks=10` y regresión CAMP003 `PASS blocks=10` con logs y SHA. Sin GPU/UI, integración global ni merge. Parar aquí: no campaña 005 ni nuevas filas sin nueva autorización.
