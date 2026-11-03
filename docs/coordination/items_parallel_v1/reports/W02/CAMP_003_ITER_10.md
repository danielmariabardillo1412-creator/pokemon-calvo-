# IA2/W02 — CAMPAÑA_003 / BLOQUE 10 DE 10

**Estado de entrega:** 10/10 publicados en `codex/calvo-items-20261103-w02-camp003`; la CI del último SHA de pruebas/progreso sigue pendiente, por tanto **NO declarar CAMPAÑA_003_FINALIZADA** hasta leer y resolver sus recibos. IDs exactos de fila 10 oficial: `yache_berry;grepa_berry;hondew_berry;pomeg_berry`.

## Alcance de este bloque y precedentes reutilizados

| Baya | Ruta nativa | Positivo/rechazo | Persistencia |
|---|---|---|---|
| `yache_berry` | Equipamiento de combate `@pkmn/sim` | Dragonite recibe `ice_shard` Hielo supereficaz, resiste y consume; `tackle` normal no reduce/consume | 3 modos de propiedad `active/none/reserve`, SaveV2, checkpoint/restore, FLED |
| `grepa_berry` | Bolsa `FieldItemService.use_item` | EV Defensa Especial 20→10 y amistad 100→105; EV=0 amistad=200→202; EV=0 amistad=255 rechazo sin consumir | Equipo, ausencia de objeto y almacenamiento, SaveV2 con EV/amistad intactos |
| `hondew_berry` | Bolsa `FieldItemService.use_item` | EV Ataque Especial 20→10 y amistad 100→105; solo amistad 200→202; límite 255 sin EV rechaza | Misma matriz de propiedad y SaveV2 |
| `pomeg_berry` | Bolsa `FieldItemService.use_item` | EV PS 252→242, amistad 100→105 y Pokémon de 1 PS **no puede debilitarse** al bajar PS máximos; EV=0 amistad=200→202; no-op a amistad 255 | Misma matriz y preservación del déficit PS tras SaveV2 |

**Decisión de diseño respaldada por código existente:** Grepa, Hondew y Pomeg son bayas de entrenamiento de aplicación en campo mediante bolsa; **no tienen un disparador de batalla equipada equivalente a Yache**. Ruta canónica en `modules/inventory/field_item_effects.gd`:`_ev_berry`. La prueba histórica `tests/gameplay/item_field_effects_v4.gd` ya cubría 6 bayas × 28 situaciones de EV/amistad más bordes; no se duplica esta matriz. Se integra el recorrido real de propiedad/consumo SaveV2 específico de los tres IDs reservados en CAMP003.

**Casos añadidos:** Yache 2 batallas con controles activo/ausente/reserva; Grepa, Hondew y Pomeg 3 escenarios cada una, distinguiendo uso aceptado por EV, uso aceptado solo por amistad y rechazo atómico. Cada escenario de entrenamiento ejecuta **equipo con objeto / equipo sin objeto / almacenamiento con objeto**, preservando ID del dueño, EV no seleccionado, IV, naturaleza, PS, amistad, stock, copia original y `SaveGameRepository.decode_snapshot`, con recibo SHA256. Son **11 nuevos escenarios y 33 variantes previstas**, para **87 escenarios de 40 IDs y 261 variantes** de toda la campaña.

**Reparación previa V5 de Starf (bloque 09):** CI [#41566220523](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41566220523) `completed/failure`, Python `CAMP003_W02_PY PASS blocks=9 checks=599`; Godot `FAIL blocks=8 checks=6586`, fallo solo de autenticidad del vector Starf en JSON (comparación directa de `Dictionary`). Se publicó cambio de comparador con **mismo conjunto de claves y valores enteros por estadística**, manteniendo aserciones de único +2 aleatorio/SaveV2/recibos SHA256; commit `13dc40ee663cd73379e4d21337e8f89ea667a067`. Su CI exclusiva se canceló por pushes de pruebas independientes; el gate de bloque 10 **debe regresar también el 09**.

## Entregables y puerta CI

- `tests/fixtures/parallel_items/w02_campaign_003.json` +11 escenarios, commit `773a3ed100637761e2f10b71a2febda01c370ab7`.
- `tests/gameplay/parallel_items_w02_campaign_003.gd` incluye tres contextos reales de `field_ev_training`, commit `3ccac60d4324f8f3916f556aee1a06c352b4e819`.
- `tests/tools/test_parallel_items_w02_campaign_003.py` exige exactamente 2 Yache + 9 entrenamiento, fuente real y **16 mutaciones adversariales** adicionales; commit `cd70cb65eeb30e962ddac5bb5f1964d8bb437aec`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv` fila 10, commit `680713149f39e742d92a9c64503e4caeb78d8aee`.

**CI acumulativa a consultar:** [Actions #41570674107](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570674107), SHA de tests/progreso `680713149f39e742d92a9c64503e4caeb78d8aee`, inicialmente `pending`. Debe emitir `CAMP003_W02_PY PASS blocks=10 checks=N` y `CAMP003_W02_GODOT PASS blocks=10 checks=M`, con ambos N y M positivos, sin errores, para considerar terminada la campaña. Un `cancelled` no certifica nada. La CI del bloque 08 [#41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549) era `success` (Python 535, Godot 5795) sobre 8 bloques, **no certifica los bloques 09 o 10**.

**Autonomía:** `AUTONOMOUS_REPAIR_V5.md` de IA6 permite corregir tanto el arnés como las funciones de nuestras bayas de forma mínima en la rama propia. Cualquier error de última CI se investiga y repara allí sin rebajar el contrato ni alterar reglas ajenas. No tocar `main`, V28, PR #118, otras ramas, workflows coordinados ni módulos compartidos fuera del comportamiento reservado. Existe un commit de IA6 externo en el historial de workflow `43876a6d833958d2d7ad86ce15014b011778007a`, no atribuible a W02.

**Limitaciones:** verificación de entrenamientos conforme a contrato base, no incluye bonificadores por origen de amistad aún pendientes en auditoría histórica, ni interfaz/GPU o efectos globales de campo. Nunca reclamar cobertura exhaustiva de todos los items del catálogo.

**Próximo paso:** esperar el resultado real de la CI en esta conversación mediante comprobación, corregir si falla y publicar `CAMP_003_FINAL.md` y estado `CAMPAÑA_003_FINALIZADA` solo tras PASS real del último SHA. **STOP definitivo en 10/10; no hay fila 11.**
