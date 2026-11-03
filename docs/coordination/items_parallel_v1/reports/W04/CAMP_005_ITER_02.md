# IA4/W04 — CAMPAÑA_005 / Microbloque 02 — intercambio con objeto y rutas de versión

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`  
**IDs ya auditados en CAMP003, no nuevos:** `protector;reaper_cloth;prism_scale;sachet;up_grade`.  
**Estado inicial:** `EN_CI_AUTOMATICA`; no declarar ninguna conversión evolutiva positiva sin contrato real.

## Contrato vigente y cinco rutas originales

`docs/current/ITEM_TRADE_RESTORATION_V27.json` revoca la exclusión V26, exige conservar el objeto **equipado** tras sustituir solo el intercambio por nivel y tiene `future_evolution_implementation=DEFERRED`, `level_values_selected=null`. También `ITEM_SCOPE_V25.json` registra niveles pendientes. Ningún nivel de otra etapa se reutiliza.

| Objeto | Origen | Destino | Cadena PokeAPI | Requisito original |
| --- | --- | --- | --- | --- |
| `protector` | `rhydon` | `rhyperior` | `data/api/v2/evolution-chain/50/index.json` | intercambio, Protector equipado, nivel `null` |
| `reaper_cloth` | `dusclops` | `dusknoir` | `data/api/v2/evolution-chain/182/index.json` | intercambio, Tela Terrible equipada, nivel `null` |
| `prism_scale` | `feebas` | `milotic` | `data/api/v2/evolution-chain/178/index.json` | intercambio, Escama Bella equipada, nivel `null` |
| `sachet` | `spritzee` | `aromatisse` | `data/api/v2/evolution-chain/350/index.json` | intercambio, Saquito Fragante equipado, nivel `null` |
| `up_grade` | `porygon` | `porygon2` | `data/api/v2/evolution-chain/68/index.json` | intercambio, Mejora equipada, nivel `null` |

**Precisión crucial:** el nivel **42** de Rhyhorn→Rhydon y el **37** de Duskull→Dusclops son niveles de etapas previas, no niveles aprobados para Rhydon→Rhyperior o Dusclops→Dusknoir.

### Condiciones especiales preservadas

**Feebas:** la cadena PokeAPI 178 contiene rutas de nivel con **belleza 170** en diferentes versiones y una ruta de intercambio con `prism-scale`. No son equivalentes. La evolución de belleza carece de implementación de su condición en `EvolutionSystem`; una conversión del intercambio que omita dicha condición podría crear una evolución automática incorrecta.

**Porygon:** la cadena 68 tiene dos etapas con objetos distintos: `porygon` + `up_grade` → `porygon2`, luego `porygon2` + `dubious_disc` → `porygon_z`. No autorizar `up_grade` para saltar a Porygon-Z, ni tratar el ítem del bloque 01 como intercambiable con este.

## Frontera concreta con IA6

```text
[Política V27: nivel aprobado todavía NULL]
            |
            v
[ProgressionSystem.gain_experience]
            |  Evento de nivel: especie, nivel, estadísticas
            v
[EvolutionSystem.level_up_context]
            |  No expone requisito de objeto equipado
            v
[EvolutionSystem._conditions_are_runtime_compatible]
            |  "held_item" -> DATA_ONLY en level_up/trade
            v
[EVOLUTION_AVAILABLE y aplicación]
            |  Sin contrato de consumo del objeto al aceptar/cancelar
            v
[SaveV2 / propietario / inventario]
```

**Decisiones pendientes:** umbrales oficiales para las cinco rutas; transmisión y verificación del objeto realmente equipado; persistencia y consumo/retención en aceptación y cancelación; preservación de la alternativa de belleza y de las dos etapas de Porygon.

No hay autorización para asignar niveles numéricos, modificar los datos canónicos o construir una nueva API compartida. La reparación queda `BLOQUEADO_POR_CONTRATO` para las cinco conversiones de nivel.

## Nuevo trabajo de pruebas

- Fixture acumulativo `tests/fixtures/parallel_items/w04_campaign_005.json`, commit `f95bcf42d739ea2c91786204aa307275dcec57e3`, preserva bloque 01 y añade cinco parejas y dos excepciones.
- Godot `tests/gameplay/parallel_items_w04_campaign_005.gd`, commit `4424648bb42f450a2ab5a66f4b8f4a7c6e9238f8`: mantiene las cuatro parejas anteriores y amplía a nueve. Además compara registros de belleza y protege etapas Porygon. Verifica equipamiento real, rechazo de uso de mochila, identidad, cantidad y SaveV2 sin transformación incorrecta.
- Python `tests/tools/test_parallel_items_w04_campaign_005.py`, commit `c7e05e76e450433b40f761aa1f6ffaa4c1a6633c`, inspecciona cadenas PokeAPI y política V27, comprueba versiones y etapas adicionales y la interfaz productor–consumidor.
- CSV `reports/W04/CAMP_005_PROGRESO.csv`, commit `1a6ceb323b77efecfcdc480665ad1a8707f79e14`, fila 02 `EN_CI_AUTOMATICA`.

**Puerta CI:** [#41718927428](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718927428), exigir `CAMP005_W04_MANIFEST_PASS reserved=10 completed=2 ids=46`, `CAMP005_W04_PY PASS blocks=2 checks=N` y `CAMP005_W04_GODOT PASS blocks=2 checks=N`. Regresiones CAMP004/CAMP003 en hitos 05/10 o parches de producción; CAMP001 en hitos 05/10. Los runs intermedios cancelados por nuevo push no son fallos de prueba.

**Aislamiento:** solo archivos W04 de test/fixture/progreso/informe. Sin cambios en módulos de producción, datasets, workflow, `main`, V28, rama árbitra, PR118 ni ramas W01/W02/W03/W05.

**Próximo `p` cuando la CI02 pase:** bloque 03/10 `oval_stone;dawn_stone;peat_block`. No ejecutarlo en este turno.


## CI real de bloque 02

[GitHub Actions #41718927428](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718927428), SHA `1a6ceb323b77efecfcdc480665ad1a8707f79e14`, terminó **completed/success**. Recibos:
- `CAMP005_W04_MANIFEST_PASS reserved=10 completed=2 ids=46 kind=FUNCTIONAL_BACKLOG`.
- `CAMP005_W04_PY PASS blocks=2 checks=159`.
- `CAMP005_W04_GODOT PASS blocks=2 checks=194`.

Godot emitió `status=BLOQUEADO_POR_CONTRATO` para **los nueve IDs de los bloques 01–02**. Prueba especial `CAMP005_W04_ALT id=prism_scale source=feebas target=milotic min_beauty=170 routes=2 status=DATA_ONLY`: dos registros de versión diferentes preservados e inejecutables con el motor actual. Prueba especial `CAMP005_W04_STAGE item=up_grade ... wrong_stage_rejected=true`: Mejora queda separada de Disco Extraño; nunca provoca Porygon2→Porygon-Z.

El CSV se actualizó a `DEPENDENCIA_DOCUMENTADA` con run `41718927428`, commit `585dda8cfaa65210220d2f1589e7cd6a2174ced3`. La modificación activa una **nueva CI de consolidación**, cuyo resultado se comprueba por separado.

**Los tests nuevos son cobertura de contrato/integración y equipamiento real, NO reparación positiva de la evolución por nivel.** Sin nuevos niveles adoptados, API compartida ni producción modificada. Las regresiones históricas se preservan y su ejecución completa corresponde a los hitos 05/10 o a cambios de producción según el workflow.


## Segunda CI02 sobre progreso consolidado

La ejecución [#41719349096](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719349096), SHA `585dda8cfaa65210220d2f1589e7cd6a2174ced3`, terminó **completed/success** sobre el CSV ya `DEPENDENCIA_DOCUMENTADA`. Repitió los recibos `CAMP005_W04_MANIFEST_PASS reserved=10 completed=2 ids=46 kind=FUNCTIONAL_BACKLOG`, Python **159 PASS**, Godot **194 PASS**. Feebas registró 2 rutas `min_beauty=170` `DATA_ONLY` y `up_grade` rechazo en Porygon2; los 9 ID de los bloques 01–02 siguen `BLOQUEADO_POR_CONTRATO`, no implementados por nivel.

**Bloque 02/10 cerrado en W04:** auditoría de contrato nueva aprobada y persistencia probada; niveles y política de consumo continúan pendientes de IA6.
