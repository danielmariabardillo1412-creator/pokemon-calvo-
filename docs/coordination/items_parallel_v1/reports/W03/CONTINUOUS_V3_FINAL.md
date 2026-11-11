# IA3/W03 — CONTINUOUS V3 FINAL · Moon, Heavy y Beast con fuente de captura

**Fecha:** 2026-11-11.
**Rama de trabajo:** `codex/calvo-items-20261104-w03-camp006`.
**Orden de IA6:** `docs/coordination/items_parallel_v1/CONTINUOUS_V3/PLAN_W03.md` (rama árbitra), activada en `IA6_AUTORUN.md` de W03.
**Estado de entrega:** `READY_FOR_IA6` (terminadas las fases independientes; no hay integración central).

## Resultado y contabilidad causal

| Magnitud | Valor |
|---|---|
| Fases V3 A/B/C realizadas | **3/3** |
| Familias prioritarias auditadas | **Heavy Ball, Moon Ball, Beast Ball** |
| Funciones L3 nuevas de un ID existente | **1**: Moon Ball |
| Objetos/IDs de inventario recién creados | **0** |
| Funcionalidad Heavy | `L2_DATA_ONLY / BLOCKED_CONTEXT` |
| Funcionalidad Beast | `BLOCKED_CONTEXT` |
| Foto posterior de 25 bolas de V2 | **17** rutas L3 comprobadas, **2** parciales de zona, **6** sin productor |
| Integración de IA6 sobre su rama | **NO**; ninguna fusión ni cherry-pick de W03 |

### Puertas CI exactas

- **CI V3**: [#42958341652](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958341652), `completed/success` en SHA `b79f322d89619144f0111205d770e1b4db057b0f`: auditoría Python, Godot 4.7, fuente real, dos capturas Moon nativas, control negativo de Magikarp nivel 5.
- **CI acumulativa final**: [#42958535816](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42958535816), `completed/success` en SHA `ef63e824069aa27ce957e99997df8e7a50c78524`: 36 pasos exitosos y 0 fallidos. Incluye CAMP005 Python **169 PASS**, Godot **208 PASS**, AUTORUN V1 Python **51 PASS**, V2 B01 **156 PASS**, V2 B02 **125 PASS**, V2 source **61 PASS**, Moon V3 nativa **41 PASS**, SaveV2 normal **40 PASS**, adversarial **8 PASS**, Field Native **118 PASS** y demás regresiones T01–05 / Repeat / Net / repelentes / CAMP006.
- Los commits de informe/checkpoint posteriores son **documentales `[skip ci]`**. No atribuirles la ejecución anterior.

## FASE A — Productores auténticos

### Moon Ball: fuente demostrada

`tests/tools/test_parallel_items_w03_continuous_v3_sources.py` lee **1.025 especies normalizadas y 57 regionales** reales. Sólo estas seis especies tienen `EvolutionRecord` de `moon_stone` con `use_item` y versión de procedencia real:

- `nidorina` → `nidoqueen`
- `nidorino` → `nidoking`
- `clefairy` → `clefable`
- `jigglypuff` → `wigglytuff`
- `skitty` → `delcatty`
- `munna` → `musharna`

`version_group` de cada `EvolutionRecord` se conserva **como procedencia histórica de la evolución** (p. ej. `red_blue`, `black_white`), no como filtro erróneo que desactive mecánicas en versiones posteriores. La política `config/randomlock_content_v1.json` **no excluye ninguna de las seis**. La fuente de reglas es `moon_ball_gen7_plus_v1`, donde el modificador de captura para especies que evolucionan directamente con Piedra Lunar es **×4** y en especies ajenas **×1**. Contraste de reglas externas: [Moon Ball, Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Moon_Ball).

### Heavy Ball: PokeAPI contiene peso, pero falta conexión al runtime

El endpoint del repositorio `data/api/v2/pokemon/35/index.json` contiene `name=clefairy`, `weight=75` **hectogramos**. No obstante, ni los 1.025 registros `CreatureSpecies.source_metadata` ni los 57 regionales retienen el peso de forma, y `DefinitionCatalog` no lo expone al combate. `tools/pokeapi_adapter_v3.py` tampoco lo incorpora al metadata. Es ilegal promover Heavy a L3 usando una variable inventada, peso de otra forma o transformando arbitrariamente un **offset de tasa** en multiplicador. Estado: `L2_DATA_ONLY / BLOCKED_CONTEXT`.

### Beast Ball: falta clasificación Ultraente auténtica

La fuente normalizada y los regionales no tienen campo `is_ultra_beast` ni otro marcador canónico equivalente. `is_legendary`, `generation_vii`, tipos o `egg_groups` no demuestran esa clasificación. No fabricar whitelist con IDs recordados. Estado: `BLOCKED_CONTEXT`.

## FASE B — Implementación Moon y prueba nativa

### Archivos de producción modificados estrictamente en ámbito W03

- **Nuevo helper** `modules/capture/capture_source_w03_v3.gd`: deriva si un **ID base canónico del objetivo nativo** evoluciona por Piedra Lunar, desde `CreatureSpecies.evolutions` y `DefinitionCatalog`. Comprueba trigger, objeto del catálogo, target, versión y condiciones; rechaza procedencia ausente/incorrecta.
- `modules/capture/capture_battle_context.gd`: dos campos aditivos `moon_stone_context_known` y `target_evolves_with_moon_stone`. Contexto ausente **no** equivale a bonificación neutral concedida.
- `modules/capture/capture_context_ball_effects.gd`: registra **solo** `moon_ball` como extensión de `ContextBallEffects.IDS` (consumido por `CaptureRuleset`); validación del productor y ×4/×1, sin tocar otras bolas.
- `modules/gameplay/showdown_adventure_session.gd::capture`: sólo para `moon_ball`, consulta el productor sobre la **especie base del objetivo nativo**, previa a resolver la captura. Nada en RNG, ledger, inventario, cierre o almacenamiento global se modifica.

**Prueba** `tests/gameplay/parallel_items_w03_continuous_v3.gd`:
1. Mapa real → encuentro → Showdown nativo con `clefairy`, ×4 y probabilidad esperada `0.7843137254902`.
2. Fallo RNG auténtico de Clefairy: una bola gastada en inventario staged, sin captura falsa; segunda tirada válida y publicación exacta de **dos bolas consumidas** en la colección propietaria.
3. Control negativo salvaje `goldeen`, ×1 y probabilidad `0.29411764705882`, consumo único, propietario correcto.
4. Guardado/carga manual de SaveV2 para ambas capturas; verificación de stock, identidad, ledger.
5. Seis especies fuente positivas y negativas `clefable`, `wigglytuff`, `mewtwo`, `goldeen`; especies inexistentes y ausencia de catálogo rechazadas; contexto Moon sin autenticar rechazado antes del RNG.

Resultado: `W03_V3_MOON PASS native=2 checks=41`. **Una ruta L3 funcional existente promovida**, no un nuevo objeto de inventario.

**Límite reconocido:** no se certificó el tratamiento especial de Moon Ball contra Ultraentes. La regla moderna contiene una penalización específica en ese contexto; sin fuente Ultraente autenticada, no se debe afirmar plena equivalencia con todas las excepciones de todos los juegos. La rama Moon ×4 para especies Piedra Lunar y ×1 para controles ordinarios sí está certificada. El productor Beast pendiente debe cubrir este cruce de reglas.

## FASE C — Bloqueos compartidos y defecto previo

Ticket único `docs/coordination/items_parallel_v1/CONTINUOUS_V3/W03_PRODUCER_DEPENDENCIES.md`:

- **Dive/Dusk/Lure/Love** requieren respectivamente procedencia auténtica pesca/surf/buceo, oscuridad/cueva/noche, origen de pesca, sexo **individual** del salvaje y del capturador. Ninguna bandera de prueba reemplaza productores del mundo.
- **Safari/Sport** ya capturan con factor ×1,5 incondicional, pero falta productor real de zona/Concurso o decisión explícita IA6 que avale tal regla. Conservar `PARCIAL_ZONE`.
- **Magikarp nivel 5**: CI V3 reproduce el `move_policy` antes de lanzamiento, sin perder stock ni criaturas; control positivo Goldeen. Runner histórico `parallel_items_w03_continuous_v2_magikarp_probe.gd` **44 checks PASS**, sin editar motor o selector de encuentros.

### Regresiones y límites de autoría

Para conservar todas las pruebas históricas, se actualizaron exclusivamente **aserciones antiguas** que suponían que Moon todavía debía ser desconocida: `test_parallel_items_w03_campaign_005.py`, `parallel_items_w03_campaign_005.gd`, `test_parallel_items_w03_autorun_v1.py` y `test_parallel_items_w03_continuous_v2_sources.py`. Ahora comprueban que **sólo** Moon se promovió con productor auténtico y que Love/Heavy/Beast y demás ausencias siguen bloqueadas. Los fixtures y recuentos antiguos no fueron falseados.

No se tocaron `CaptureSystem`, `CreatureInstance`, `PlayerCollection`, SaveV2 central, `FieldItemBag`, `native_engine`, lógica RNG, generadores de campo, reloj, pesca o sexo; tampoco `main`, V28, PR118 ni ramas ajenas.

## Entrega a IA6 y condición de parada

La misión V3 autorizada está agotada. IA6 debe integrar **selectivamente por función**, no copiar archivos compartidos a ciegas, y ejecutar su propia CI sobre SHA de integración. Hay una mejora Moon que puede recogerse y dos funciones prioritarias que dependen de productores no disponibles en el contexto de W03 (Heavy y Beast), además de cuatro bolas de contexto de mundo y dos parciales de zona.

**Resultado final: `READY_FOR_IA6`; A/B/C 3/3 · 1 función L3 promovida · 0 IDs nuevos de inventario · 2 prioritarias bloqueadas · foto de 25 = 17 L3 + 2 parciales + 6 bloqueadas · CI acumulativa #42958535816 SUCCESS sobre `ef63e824` · integración IA6 NO.**
