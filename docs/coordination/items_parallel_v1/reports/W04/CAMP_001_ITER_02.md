# W04 CAMPAÑA_001 — ITER_02

Estado: PREPARADO_PENDIENTE_CI.
IDs: leaf_stone, ice_stone, moon_stone.

Pruebas añadidas a los dos scripts propios. Cinco rutas positivas en equipo y PC; Vulpix de Alola condicionado como control negativo del Vulpix común.

Verificación independiente de archivos: 44/44 comprobaciones estructurales correctas. Godot y Python del checkout: SIN_EJECUTAR. CI base histórica #41341842320 PASS, no corresponde a estos cambios.

Runner Godot blob c78d1642c0e1f67c4510e2f3f1b338b5c70daae1; validador Python blob ffd348c51bab97095eb30c3e3c4f8e25674c684e.

Próximo microbloque autorizado: 03 persistencia SaveV2. No se cambia producción ni otros repositorios/ramas.

### Matriz de rutas nuevas

| Piedra | Origen | Destino de referencia | Ubicaciones |
|---|---|---|---|
| Hoja | eevee | leafeon | equipo y PC |
| Hoja | gloom | vileplume | equipo y PC |
| Hielo | eevee | glaceon | equipo y PC |
| Lunar | clefairy | clefable | equipo y PC |
| Lunar | jigglypuff | wigglytuff | equipo y PC |

Los destinos se deducen del catálogo al ejecutar; las cinco referencias anteriores proceden de cadenas PokeAPI 67, 18, 14 y 16. Cadena 15: `ice_stone` de Vulpix de Alola requiere forma; Vulpix corriente debe rechazar sin consumir. Este control se informa como ruta condicionada rechazada o no presente en catálogo, nunca como éxito regional inferido.

Aserciones: mismo destino en equipo/PC, stock 0, stock 2→1 tras éxito, propietario falso, destino falso, especie inválida, segundo intento sin gasto e identidad/IV/EV/movimientos/experiencia/amistad. **Solo verificaciones estructurales 44/44 reales en GitHub; Python y Godot del nuevo corredor SIN_EJECUTAR.**

Comandos para un único gate consolidado de IA6: `python -B tests/tools/test_parallel_items_w04_campaign_001.py` y `python -B tests/tools/test_parallel_items_w04_campaign_001.py --godot godot` después de importación Godot 4.7. Hasta entonces NO calificar FUNCIONAL_PASS_COMMIT. Microbloque 03 pendiente.
