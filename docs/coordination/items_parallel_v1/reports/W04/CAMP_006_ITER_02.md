# IA4/W04 — CAMPAÑA_006 — bloque 02/10 | Tetera rota/agrietada y cuencos

**Rama:** `codex/calvo-items-20261104-w04-camp006`. **Familia:** `FORM_SOURCE`. **IDs:** `chipped_pot;cracked_pot;masterpiece_teacup;unremarkable_teacup`. **Nuevos IDs:** 0. **Estado de entrega:** `EN_CI_AUTOMATICA`; no declarar PASS sin leer el run GitHub Actions del SHA completo.

## Hallazgo: formas canónicas presentes; productor persistente ausente

PokeAPI proporciona **formularios canónicos de criatura independientes de la especie** en `data/api/v2/pokemon-form/`:

| Objeto | Especie antes → después | Forma de origen (API) | Forma de destino (API) |
| --- | --- | --- | --- |
| `chipped_pot` | Sinistea → Polteageist | antique (10344) | antique (10345) |
| `cracked_pot` | Sinistea → Polteageist | phony (854) | phony (855) |
| `masterpiece_teacup` | Poltchageist → Sinistcha | artisan (10447) | masterpiece (10448) |
| `unremarkable_teacup` | Poltchageist → Sinistcha | counterfeit (1012) | unremarkable (1013) |

Los cuatro formularios fuente son permanentes (`is_battle_only=false`). Los datos PokeAPI existen; **no faltan los metadatos**. Sin embargo, `modules/creatures/domain/creature_instance.gd` no serializa `form_id` ni `source_form_id`: `species_id` solamente discrimina Sinistea frente a Poltchageist, **no** sus variedades. En `modules/inventory/field_item_service.gd::evolution_options`, las condiciones actuales evalúan especie/nivel/ítem; un mismo ejemplar sin etiqueta de forma ofrece los dos objetos alternativos.

### Bloqueo de implementación correcta: UNA dependencia compartida

- **Productor faltante:** captura y `CreatureFactory` deben asignar una **forma autorizada**, no decidirla al consumir la tetera/cuenco ni derivarla de `instance_id`, naturaleza, sexo, shiny o semilla del test.
- **Contrato persistente faltante:** `CreatureInstance` y SaveV2 requieren conservar forma fuente y forma resultante tras evolución, con migración para guardados previos. La forma de batalla temporal `battle_transform_original` **no** sirve de reemplazo.
- **Consumidor faltante:** `FieldItemService.evolution_options/evolve` debe comprobar coincidencia exacta entre objeto y forma fuente; evolución atómica debe conservar identidad y asignar la forma de destino, y rechazar otra tetera/cuenco sin consumo.
- **Prueba futura:** por especie, probar las dos formas, éxito con objeto correcto, rechazo con el contrario, preservación del estado y SaveV2 antes/después. **Propietaria:** IA6 para productor, formato de estado/SaveV2 y API compartida. W04 podría añadir el adaptador específico tras recibir ese contrato; no se ha modificado producción compartida ahora.

### Positivo independiente, nivel L3 de especie

El motor **ya** conoce las cuatro evoluciones por `use_item`. Se ha ampliado el runner CAMP006 para ejercitar **cuatro veces la escena visual real**: apertura de mochila, elegir tetera/cuenco y criatura, pulsar `_apply("use")`, comprobar nueva especie, `instance_id`, consumo exactamente de una unidad, estadísticas, movimientos y atributos, rechazo de segundo uso, guardar en el puente nativo y recuperar desde SaveV2.

**Este PASS —si CI lo da— prueba especie/consumo/SaveV2 en demo; NO acredita autenticidad ni forma final.** El recibo `CAMP006_W04_POT` lo especifica: `status=L3_SPECIES_EVOLUTION__FORM_AUTHENTICITY_MISSING`.

Los **tres casos L3 de manzanas del bloque01** siguen ejecutándose en el mismo runner antes de los cuatro casos nuevos. No se vuelven a contar evoluciones como nuevas ni se repite una auditoría de todas las especies.

## Evidencia y entorno

- Fixture acumulativo `tests/fixtures/parallel_items/w04_campaign_006.json`: bloques 01 y 02, cuatro pares fuente/forma destino más frontera de propiedad.
- Godot `tests/gameplay/parallel_items_w04_campaign_006.gd`: `_case` intacto para manzanas; `_case_form_02` prueba las cuatro rutas en escena + SaveV2; `_form_snapshot_02` comprueba fuentes canónicas.
- Python `tests/tools/test_parallel_items_w04_campaign_006.py`: ahora exige 2/10 bloques, fila02 exacta, comprueba formularios PokeAPI, persistencia ausente sin inventos y que runner contiene ejecución de escena.
- Progreso `reports/W04/CAMP_006_PROGRESO.csv`: fila01 `CI_PASS_VERIFICADO`, fila02 `EN_CI_AUTOMATICA`.
- Sin modificaciones en `modules/`, `scenes/visual/`, `main`, V28, rama árbitra ni otras trabajadoras. Política trade→level V27 sin tocar.

**Criterio para cerrar 02:** workflow CAMPAÑA_006 `completed/success`, recibos `CAMP006_W04_PY PASS blocks=2 checks=N` y `CAMP006_W04_GODOT PASS blocks=2 checks=N`, con cuatro líneas `CAMP006_W04_POT` diferenciadas. Clasificación final `DEPENDENCIA_DOCUMENTADA` salvo que IA6 entregue el productor de forma real y una CI lo demuestre.

## CI02 real — prueba funcional de especie aprobada, forma NO certificada

[Run GitHub Actions #41783726455](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41783726455) sobre SHA `45f1081011435db9ce07026d5e9dc3fc53c5eafa` terminó **completed/success**.

Recibos verificados en los logs:
- `CAMP006_W04_SCOPE PASS blocks=2`.
- `CAMP006_W04_PY PASS blocks=2 checks=91`.
- `CAMP006_W04_GODOT PASS blocks=2 checks=204`.
- Tres `CAMP006_W04_APPLE ... status=L3_SCENE_BAG_AND_NATIVE_SAVEV2`: bloque01 preservado íntegro.
- Cuatro `CAMP006_W04_POT ... status=L3_SPECIES_EVOLUTION__FORM_AUTHENTICITY_MISSING`: ejecución L3 positiva **por especie** y diagnóstico de falta de autenticidad, **no** forma correcta demostrada.

El paso de regresión histórica CAMP005 aparece `skipped` en bloque02 según el workflow; **no** indicar que se ejecutó. No se ha tocado producción. La clasificación `DEPENDENCIA_DOCUMENTADA` en el CSV reconoce tanto el avance L3 como la frontera funcional pendiente de IA6. Se disparó una segunda CI por la actualización de progreso, que deberá verificarse por separado.

**Próximo bloque autorizado cuando llegue `p`:** 03/10 `dragon_scale;electirizer`; política V27 `level_values_selected=null` sin umbrales ni consumo inventados. No iniciar ese bloque por el cierre de 02.
