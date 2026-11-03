# IA2/W02 — CAMPAÑA_004 | MICROBLOQUE 03/10

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp004`. **Autoridad:** IA6 `CAMPAIGN_004_W02_GATE.md`, fila 03 de `CAMPAIGN_004_W02_QUEUE_APPROVED.csv` y `campaigns/CAMP_004_W02.md`. Se ejecuta **solo fila 03**; ningún cambio de producción ni de ramas compartidas.

**Estado de verificación:** `PRUEBAS_PUBLICADAS_PENDIENTE_CI`. Las rutas de test y contratos están en GitHub, pero no se ha obtenido todavía recibo del CI de los bloques 02–03 en el último SHA. No atribuir PASS Godot/Python ni integración global sin leer logs y jobs de ese run. El bloque 01 tiene PASS verificable en [#41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223) (CAMP004 Python 83, Godot 1022, regresión CAMP003 Python 680 / Godot 7306), **no certifica 02–03**.

## Cuatro medicinas, 15 escenarios × tres propietarios = 45 variantes

| ID | Escenarios | Contrato en el servicio nativo de campo |
| --- | ---: | --- |
| `antidote` | 4 | Cura `poison` y `badly_poisoned`; no cura `burn` ni consume si está sano. Comprueba contadores, estado e inventario |
| `awakening` | 3 | Cura `sleep`, limpia estado de sueño y reloj nativo; rechaza `poison` y objetivo sano sin consumir |
| `berry_juice` | 3 | Restablece exactamente 20 PS desde media vida o hasta el máximo si faltan 7; rechaza PS completos sin consumo |
| `big_malasada` | 5 | Cura veneno, congelación y confusión, tanto sola como combinada con estado persistente; no consume en objetivo sano |

**Método:** prueba mediante `FieldItemService.use_item` y `FieldItemEffects.apply`, no un simulador alternativo. En los tres modos `active` (equipo con dos ítems), `none` (equipo sin ítem), `reserve` (Pokémon almacenado con dos ítems), comprobar propiedad, aceptación/rechazo, ausencia de mutación en la fuente, consumo exacto de una unidad cuando hay efecto, PP/EV/amistad no alterados, contadores de estado, reloj de sueño, SaveV2 y recibo JSON/SHA256. Contratos de datos contrastados con `modules/inventory/imported_recovery_v19.json` y regresión `tests/gameplay/item_field_effects_v4.gd`; si Godot identifica una diferencia, no ajustar la expectativa sin diagnosticarla.

**Acumulado publicado:** 01=15, 02=12, 03=15 escenarios; 42 escenarios × 3 modos = 126 variantes previstas sobre 12 IDs únicos. Los escenarios nuevos no implican PASS real.

## Cambios de esta iteración

- `tests/fixtures/parallel_items/w02_campaign_004.json`: bloque 03 añadido, contrato detallado de 15 casos; commit `5aa0a0e2c44fe33f5ac51d23f70fd3dae59ba56d`.
- `tests/tools/test_parallel_items_w02_campaign_004.py`: 15 casos esperados independientes, semántica del perfil para 4 IDs y mutaciones adversariales adicionales; commit `8a6a9f73aac2037b7d8f7fc71422dc93b47c15cd`.
- `tests/gameplay/parallel_items_w02_campaign_004.gd`: se amplía el arnés propio para `field_medicine`, PS iniciales y límites, curación de status/confusión, relojes del servicio, conservación de PP/EV y SaveV2; commits `e9f081890d4b880638342b8a2400c7e476e85d25`, `7040591c3ff8729649c33ccb8a417a5a090cf4d5`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`: fila 03 insertada, pruebas pendientes de CI; commit `042e0f60b1137c326306e3459385a0e575214b07`.

## Próximos controles necesarios

1. Confirmar GitHub Actions de **último SHA**: `CAMP004_W02_PY PASS blocks=3 checks=N` y `CAMP004_W02_GODOT PASS blocks=3 checks=M`, ambos números de checks mayores que cero; regresión `CAMP003_W02_PY/GODOT PASS blocks=10`. No aceptar el run anterior del 01.
2. Si hay fallos 02/03, reproducir y reparar localmente según `AUTONOMOUS_REPAIR_V5.md`; no rebajar condiciones ni alterar mecanismos ajenos. Si el servicio compartido necesita un cambio de API, pedir coordinación a IA6.
3. Mantener la **dependencia de Razz** del bloque 02: las pruebas de rechazo/inercia no constituyen una implementación útil. Decisión de contenido pendiente a IA6.
4. Con la siguiente `p` ejecutar **solo** fila 04: `burn_heal;casteliacone;elixir;energy_powder`, después de revisar la CI previa.

**Restricciones observadas por esta trabajadora:** `main`, V28, rama árbitra, W01/W03/W04/W05, producción, catálogos, workflows y PR #118 sin editar. **UI/GPU:** no comprobado.
