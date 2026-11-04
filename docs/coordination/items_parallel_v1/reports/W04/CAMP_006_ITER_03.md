# IA4/W04 · CAMPAÑA_006 · Bloque 03/10 · Objeto equipado y evolución diferida

**Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`  
**Cola oficial:** `dragon_scale;electirizer` (`TRADE_LEVEL_GATE`, `held_item_contexto_piloto_sin_inventar_niveles`).  
**Objetos nuevos:** 0. **Estado inicial:** `EN_CI_AUTOMATICA` hasta recibos de CI del bloque 03.

## Resultado funcional buscado: L3 positivo de equipamiento real

No se duplica la auditoría del antiguo bloque CAMPAÑA_005: el nuevo test `_case_trade_03` usa la **escena visual y la mochila real**, no un `FieldItemService` artificial con guard siempre `true`.

Para **Seadra + Escama Dragón** y **Electabuzz + Electrizador**:
1. Instanciar `field_demo.tscn` y Pokémon con identidad propia y dos unidades del objeto.
2. Seleccionar Pokémon y objeto en `field_item_bag`, comprobar que `_apply("use")` no hace evolucionar ni consume nada.
3. Pulsar **Equipar** mediante `_apply("equip")`: debe aplicarse de verdad el objeto al Pokémon conservando especie, `instance_id`, atributos, y dejando una unidad en mochila y una equipada; el objeto **no se considera consumido por evolución**.
4. Repetir Equipar y solicitar una evolución prematura: ambos deben ser rechazados, sin duplicar objetos ni transformar la especie.
5. Pulsar **Quitar equipado**: recuperar el objeto y volver al snapshot inicial; reequipar desde la UI.
6. Guardar con `field_native_bridge.save_game()`, mutar a propósito equipamiento y mochila en memoria y cargar con `field_native_bridge.load_game()`. Exigir misma especie e identidad, objeto equipado restaurado, stock y atributos intactos en SaveV2. Volver a quitar equipado desde la mochila tras el load.

Cada pareja debe generar un recibo `CAMP006_W04_TRADE_HELD ... status=L3_EQUIP_UNEQUIP_SAVEV2__TRADE_LEVEL_DEFERRED` **solo si el runner Godot pasa de verdad**.

El nuevo positivo es **equipamiento desde escena y persistencia nativa**, NO evolución por nivel ni conversión completa de intercambio.

## Regla canónica y única dependencia de evolución

`docs/current/ITEM_TRADE_RESTORATION_V27.json`: `level_values_selected=null`, `future_evolution_implementation=DEFERRED`. Se **sustituirá únicamente** el requisito de intercambio por nivel aprobado, pero **se mantendrá el objeto original equipado** si la evolución lo requiere. La regla de consumo o permanencia tras la evolución aún no está definida; no se inventa.

| Objeto | Origen → destino | Fuente PokeAPI original | Trigger canónico |
| --- | --- | --- | --- |
| `dragon_scale` | Seadra → Kingdra | `evolution-chain/54`, Gold/Silver | `trade` + `dragon-scale` equipado; sin mínimo de nivel |
| `electirizer` | Electabuzz → Electivire | `evolution-chain/60`, Diamond/Pearl | `trade` + `electirizer` equipado; sin mínimo de nivel |

**Productor:** `ProgressionSystem.gain_experience` utiliza `EvolutionSystem.level_up_context(creature)`, que ahora no transporta `held_item_id`.

**Consumidor:** `EvolutionSystem.classify_record` deja `held_item` como `DATA_ONLY`; el servicio tampoco interpreta el trade como `use_item`.

**Propietaria de decisión/integración compartida: IA6.** Debe fijar umbral(es) de las dos especies, semántica exacta del objeto equipado tras confirmar/cancelar la evolución y coordinar los productores de subida de nivel, evento y SaveV2. Una vez resuelto, W04 puede añadir exclusivamente la condición de evolución en su componente autorizado, con positivos/negativos de umbral, held y rollback.

**Prueba futura bloqueada:** evolucionar Seadra y Electabuzz al nivel aprobado llevando su objeto, impedirlo sin objeto y un nivel antes, y comprobar conservación de identidad y persistencia tras confirmar/cancelar. Un PASS del piloto de equipamiento no acredita ninguna de estas condiciones.

## Entrega y regresión acumulativa

- `tests/fixtures/parallel_items/w04_campaign_006.json`: filas 01, 02 y 03, parejas exactas, umbrales y consumo `null`, contrato de dependencia.
- `tests/gameplay/parallel_items_w04_campaign_006.gd`: añade `_case_trade_03` para equipar/quitar/guardar/cargar en demo, y **conserva y ejecuta los 3 casos L3 de manzanas y los 4 de teteras/cuencos** de bloques 01-02.
- `tests/tools/test_parallel_items_w04_campaign_006.py`: comprobaciones Python acumulativas de alcance y recibos, cadenas originales `trade+held`, política V27, ausencia de umbral, verificaciones del camino positivo Godot y dependencias.
- `reports/W04/CAMP_006_PROGRESO.csv`: fila03 en `EN_CI_AUTOMATICA`, filas anteriores intactas.
- CI rama: exigir `CAMP006_W04_SCOPE PASS blocks=3`, `CAMP006_W04_PY PASS blocks=3 checks=N`, `CAMP006_W04_GODOT PASS blocks=3 checks=N` y dos recibos nuevos `CAMP006_W04_TRADE_HELD`. Según el workflow, CAMP005 histórica no se ejecuta en bloque03 sin cambios de producción.
- **No se modificaron** `main`, V28, PR #118, políticas, productores ni las ramas ajenas.

**Finalizar 03/10 con `DEPENDENCIA_DOCUMENTADA`** si pasan las nuevas pruebas L3, sin confundirlo con la conversión trade→level. No ejecutar bloque04 sin la siguiente `p`; la familia siguiente dependerá de la misma aprobación de umbrales de IA6 y no debe rellenarse con negativos repetidos.

## CI03 ejecutada — evidencia L3 positiva y dependencia IA6

[Run GitHub Actions #41785445720](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785445720), SHA `4654ae0c70c600a26a8d0cd391739fed7ad09f5a`, **completed/success**. Logs:

- `CAMP006_W04_SCOPE PASS blocks=3`.
- `CAMP006_W04_PY PASS blocks=3 checks=127`.
- `CAMP006_W04_GODOT PASS blocks=3 checks=281`.
- Dos recibos `CAMP006_W04_TRADE_HELD id=dragon_scale/electirizer status=L3_EQUIP_UNEQUIP_SAVEV2__TRADE_LEVEL_DEFERRED requires=IA6_approved_level_and_consumption`.
- Tres recibos `CAMP006_W04_APPLE` y cuatro `CAMP006_W04_POT`: los **siete casos anteriores continúan pasando**. El control de autenticidad del bloque02 sigue pendiente de productor compartido.
- Regresión completa CAMPAÑA_005 histórica: `skipped` en bloque 03, conforme a los hitos 01/05/10 y ausencia de parche de producción.

**Conclusión:** alcanzado **L3 de equipamiento, retirada y SaveV2 en la demo** para dos objetos. **NO** implementada ninguna evolución `trade → level`; las reglas V27 permanecen diferidas. El CSV03 queda `DEPENDENCIA_DOCUMENTADA` hasta que IA6 apruebe umbrales y política de objeto, y coordine productores y consumidores.

**Aviso a IA6 antes de la fila04:** el bloque04 exige extender exactamente la misma conversión pendiente a otros siete objetos, **solo con política aprobada**. No permitir que la próxima `p` rellene ese bloque con pruebas negativas equivalentes o nuevos niveles arbitrarios. Si IA6 no aprueba V27, informar `BLOQUEADO_POLITICA_IA6` y no contabilizar integraciones de nivel como positivas.

La actualización del CSV dispara otra CI; verificarla separadamente. Se conserva rama W04, sin cambios a producción, política, `main` ni V28.

## CI sobre CSV03 consolidado — segundo recibo

La CI de [#41785614844](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785614844), SHA `ecc1a1c85af522826821e72dcb5924ebbb70e1d9`, terminó **completed/success** después de actualizar el progreso a `DEPENDENCIA_DOCUMENTADA`.

Se comprobaron nuevamente:
- `CAMP006_W04_SCOPE PASS blocks=3`
- `CAMP006_W04_PY PASS blocks=3 checks=127`
- `CAMP006_W04_GODOT PASS blocks=3 checks=281`
- `CAMP006_W04_TRADE_HELD id=dragon_scale` y `id=electirizer`, ambos `L3_EQUIP_UNEQUIP_SAVEV2__TRADE_LEVEL_DEFERRED`.
- El paso de regresión histórica CAMP005 se marcó `skipped`, como corresponde al hito03 sin modificaciones de producción.

**Cierre W04 bloque03:** completada validación funcional real L3 de equipamiento, retirada y persistencia; **no** implementada la evolución por nivel por falta de niveles/consumo aprobados por IA6. Antes de ejecutar el bloque04 de la misma familia, es necesario resolver la política; no repetir el mismo informe negativo para otros siete ítems sin integrar funcionalidad nueva.

**Detenido tras 03/10.** La siguiente `p` no concede modificar política V27 ni sistemas compartidos.
