# IA4/W04 — CAMPAÑA_005 / Microbloque 04: variantes regionales y estilos de Urshifu

**Rama exclusiva:** `codex/calvo-items-20261103-w04-camp005`.  
**Cuatro IDs de backlog, NO objetos nuevos:** `galarica_cuff;galarica_wreath;scroll_of_darkness;scroll_of_waters`.  
**Estado de publicación:** `EN_CI_AUTOMATICA`; todavía no afirmar PASS del bloque.

## Contratos originales diferenciados

| Ítem | Ruta original | Versión PokeAPI | Forma que debe aplicar |
| --- | --- | --- | --- |
| `galarica_cuff` | Slowpoke → Slowbro | Isla de la Armadura | `base_form=slowpoke-galar`; `evolved_form=slowbro-galar` |
| `galarica_wreath` | Slowpoke → Slowking | Isla de la Armadura | `base_form=slowpoke-galar`; `evolved_form=slowking-galar` |
| `scroll_of_darkness` | Kubfu → Urshifu | Escarlata/Púrpura | `evolved_form=urshifu-single-strike` |
| `scroll_of_waters` | Kubfu → Urshifu | Escarlata/Púrpura | `evolved_form=urshifu-rapid-strike` |

Fuentes crudas: `data/api/v2/evolution-chain/33/index.json` y `data/api/v2/evolution-chain/470/index.json`. Para Kubfu, los disparadores `tower-of-darkness` y `tower-of-waters` de Isla de la Armadura son **rutas históricas alternativas separadas**, no equivalentes a `use-item` con manuscrito en Escarlata/Púrpura. Las dos opciones con manuscrito tienen **la misma especie destino `urshifu` pero distinta forma**. Confundir la especie con la forma daría un falso positivo de implementación.

## Dependencia NUEVA para IA6 (productor → consumidor → persistencia)

```text
[PokeAPI chain 33/470; version_group + base_form + evolved_form]
            |
            v
[tools/pokeapi_adapter_v3.py::evolution_record]
            |  Preserva condiciones V3 en EvolutionRecord
            v
[EvolutionSystem.classify_record/evolution_candidates]
            |  evolved_form no es condición runtime; base_form regional
            |  no basta sin identidad de forma de la criatura
            v
[FieldItemService.evolution_options / evolve]
            |  Solo entrega species_id; no el destino con su forma
            v
[EvolutionSystem.apply_evolution + PlayerCollection]
            |  Crea CreatureInstance destino; sin selector/estado
            |  regional ni estilo persistente en CreatureInstance
            v
[SaveV2 / restauración / UI / batalla]
            |  Debe distinguir slowpoke-galar y ambos Urshifu
            v
[EVOLUCIÓN DE FORMA REAL — NO DISPONIBLE TODAVÍA]
```

**Contratos mínimos por decidir o coordinar con IA6:** (1) representación e identidad persistente de forma regional y estilo dentro del Pokémon, con persistencia/migración SaveV2; (2) resolvedor de evolución que conserve y valide `base_form`, `evolved_form` y versión, incluyendo dos Urshifu con `species_id` idéntico; (3) selección y activación de los manuscritos y torres según versión/escenario aprobado; (4) política de consumo y cancelación del objeto con restauración transaccional. El usuario no autorizó inventar formas, fusionarlas en especies nuevas ni migrar SaveV2 desde W04 unilateralmente.

## Evidencias nuevas publicadas

- Fixture acumulativo `tests/fixtures/parallel_items/w04_campaign_005.json`, commit `e3f5ade3a22415ad00fdeb392edf1a438aa2a04c`: cuatro rutas y diferencias de versión/forma; bloques 01–03 preservados.
- Runner `tests/gameplay/parallel_items_w04_campaign_005.gd`, commit `7f58ec93656a4806ed3c873400de6a876c237918`: valida registro individual por item, condiciones de forma, no degradación a evolución ordinaria, dos formas de Urshifu, dos torres alternativas `UNSUPPORTED`; prueba rechazo sin gasto, equipamiento permitido, identidad y SaveV2 en ambas especies origen.
- Validador Python `tests/tools/test_parallel_items_w04_campaign_005.py`, commit `3656edddbdb6417d233533299cadd9431ab9f0f3`: inspección de cadenas PokeAPI 33/470 y de la ausencia de contrato de forma en el dominio. Diferencia dos fuentes por versión y asegura que las cuatro rutas y objetos seleccionados sean los de la cola original.
- CSV `docs/coordination/items_parallel_v1/reports/W04/CAMP_005_PROGRESO.csv`, commit `59e5d086d53071e27db2a56ba20d8ff120b94f4c`: bloque 04 `EN_CI_AUTOMATICA`.

**Puerta CI**: `CAMP005_W04_MANIFEST_PASS reserved=10 completed=4 ids=46 kind=FUNCTIONAL_BACKLOG`, `CAMP005_W04_PY PASS blocks=4 checks=N` y `CAMP005_W04_GODOT PASS blocks=4 checks=N`; corregir errores reales propios antes de reconciliar el CSV. Regresiones CAMP004/CAMP003/CAMP001 están conservadas; workflow las ejecuta en hitos 05/10 o tras parche propio de producción.

**Límites:** no se ha modificado producción, datos, `main`, V28, rama IA6, PR118, ramas W01/W02/W03/W05 ni interfaces de SaveV2. Este trabajo pretende localizar y comprobar una **dependencia nueva de integración de formas**, no repetir auditorías anteriores ni inventar funcionalidad.

**Próximo `p` después de CI04 correcta:** ejecutar exclusivamente bloque 05/10, siete confites de Milcery: `berry_sweet;clover_sweet;flower_sweet;love_sweet;ribbon_sweet;star_sweet;strawberry_sweet`.


## Incidencia de arnés CI04 y reparación

La primera ejecución completa [#41723323786](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41723323786), SHA `59e5d086d53071e27db2a56ba20d8ff120b94f4c`, terminó `failure` en **validador Python**, antes de ejecutar Godot. El arnés antiguo del bloque 02 seguía buscando el marcador literal `bloques_01_a_03_secuenciales`; el runner acumulativo ahora publica `bloques_01_a_04_secuenciales`. No es un fallo funcional ni una ausencia de contrato regional.

Se corrigió exclusivamente ese marcador de test en `tests/tools/test_parallel_items_w04_campaign_005.py`, commit `e3862af4babb283c2257c919b7c792261fd18868`, **sin retirar ni relajar ninguna prueba de forma, consentimiento, inventario, persistencia o versión**. GitHub Actions reinició el bloque en [#41723793802](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41723793802), cuyo resultado es obligatorio comprobar antes de cerrar el bloque.
