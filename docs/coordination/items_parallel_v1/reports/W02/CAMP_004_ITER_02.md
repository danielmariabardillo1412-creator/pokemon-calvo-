# IA2/W02 — CAMPAÑA_004 / MICROBLOQUE 02 DE 10

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp004`. **Autorización:** fila 02 de `CAMPAIGN_004_W02_QUEUE_APPROVED.csv` y `campaigns/CAMP_004_W02.md`. Se conserva íntegramente el bloque 01, sin iniciar 03.

**Estado:** `EN_CI_AUTOMATICA`. **No se atribuye PASS a bloque 02 hasta verificar Godot+Python del mismo SHA.** CAMP004 bloque 01 sí tiene CI `completed/success` en [run 41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223), incluidos ambos contratos CAMP004 y regresión CAMP003.

## Fila autorizada: 4 IDs; 12 escenarios × 3 variantes = 36

| Objeto | Escenarios | Qué comprueba el contrato |
| --- | ---: | --- |
| `qualot_berry` | 3 | Baja EV Defensa 20→10, mejora amistad 100→105; EV 0 y amistad 200→202; con EV 0 y amistad 255, rechazo atómico. `FieldItemService.use_item` con propietario en PARTY/STORAGE, guardado SaveV2 |
| `razz_berry` | 2 | **Control negativo.** Uso directo en campo sin efecto conectado: rechazo sin gasto ni mutación. Equipada en batalla contra un movimiento inocuo: no consume ni activa efectos, identidad y stock intactos. **Dependencia de producto/política: no está acreditada funcionalidad positiva** |
| `sitrus_berry` | 4 | Equipada: `Endeavor` reduce PS hasta umbral y restaura exactamente `floor(maxHP/4)`, con control paralelo sin baya/reserva; no activa con PS altos. Bolsa: cura un cuarto desde media vida; PS máximos rechazan sin consumo; SaveV2 |
| `tamato_berry` | 3 | Baja EV Velocidad 20→10, amistad 100→105; EV 0 amistad 200→202; EV 0 amistad 255 rechazo atómico, con SaveV2 y stock |

La fixture fija 12 escenarios y el validador Python compara cada campo contra una matriz independiente del propio JSON, además de controles adversariales (IDs externos, Razz falsa activación, Sitrus de un tercio y estadística incorrecta). El runner Godot usa las rutas reales existentes de combate y bolsa, no respuestas simuladas.

## Dependencia concreta Razz

El catálogo permite sostener `razz_berry`, pero `field_item_effects.gd` no registra Razz como baya EV ni `imported_recovery_v19.json` le atribuye recuperación. `FieldItemService.use_item` no tiene contrato directo para ella; sus usos históricos de otras mecánicas (por ejemplo captura de Let's Go/recetas) no autorizan inventar efecto competitivo. **El test negativo puede pasar y continuar marcado como DEPENDENCIA funcional.** IA6 debe decidir si se excluye de objetos útiles o si existe un uso canónico que deba conectarse por diseño; no se modifica arquitectura ni políticas globales aquí.

## Evidencias, rutas y límites

- `tests/fixtures/parallel_items/w02_campaign_004.json`: bloque 02 añadido, anteriores intactos.
- `tests/gameplay/parallel_items_w02_campaign_004.gd`: comprobación nativa Sitrus/propiedad, ampliación controlada de pruebas de campo y rechazo Razz.
- `tests/tools/test_parallel_items_w02_campaign_004.py`: contrato 02, fuentes y controles negativos.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`: dos filas, primera con CI 41573481223, segunda pendiente.
- CI requerida de la última revisión: `CAMP004_W02_PY PASS blocks=2`, `CAMP004_W02_GODOT PASS blocks=2` y regresiones `CAMP003_W02_PY/GODOT PASS blocks=10`. Un error de pruebas o arnés se repara aquí según V5, sin rebajar aserciones.
- **NO VERIFICADO:** interfaz visual/GPU, amistad especial por origen, integración global en `main`, semántica de Razz no decidida.

**Producción:** sin cambios. **Ramas ajenas, `main`, V28 y workflow:** intactos por W02. **Próxima `p`:** revisar CI del bloque 02 y, si procede, ejecutar exactamente fila 03 `antidote;awakening;berry_juice;big_malasada`.
