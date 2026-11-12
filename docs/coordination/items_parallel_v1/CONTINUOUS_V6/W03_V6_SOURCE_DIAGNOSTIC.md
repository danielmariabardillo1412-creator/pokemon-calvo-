# IA3/W03 V6 — Procedencia auténtica de zona y diferencias exactas (12-11-2026)

## Fuente oficial de referencia
- Base fija de IA6: `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`; rama nueva exclusiva `codex/calvo-items-20261112-w03-dusk-cave-v6`.
- El `OverworldEncounterZone` físico heredado de `technical_overworld.gd` detecta posiciones mediante `zone_at_position`, no mediante strings de la interfaz. Nodos reales `CaveEncounterZone` y `EncounterZone`, respectivamente `technical_cave_floor` y `technical_grass`. Registro validado en `OverworldEncounterDirector._tables`.
- Cadena nativa **real**: `field_note_native_step(position)` → `field_prepare_native_encounter(zone)` → `FieldNativeBridge.on_step` → `FieldNativeBridge._open` → `FieldNativeSession` (hereda `ShowdownAdventureSession`) → `capture` → `CaptureBattleContext` → `CaptureRuleset.ContextBallEffects` → `CaptureSystem.resolve`.
- Perfil de generación VII–IX: **Bola Ocaso ×3** en cueva/noche y **×1** fuera; para esta campaña solo cueva física, porque no existe productor de hora nocturna autenticado. Fuente externa de referencia: https://bulbapedia.bulbagarden.net/wiki/Dusk_Ball . La fórmula de probabilidad sigue la aproximación interna `calvo_capture_v1`, no la fórmula oficial Gen IX completa.
- La fuente de datos PokéAPI no aporta el multiplicador estructurado, tal como se explica en `docs/architecture/CAPTURE_RULESET_CALVO_V1.md`.

## Evidencia A — hueco RED anterior
El guard `test_ia6_w03_v6_dusk_source_guard.py` compara contra el Git SHA fijo anterior y certifica dos hechos: `dusk_ball` **no figuraba** en IDs contextuales y `FieldNativeBridge` **no enlazaba** ningún productor auténtico de zona. Esto acredita la condición RED de fuente (una Bola Ocaso anterior no era conocida por `CaptureRuleset`). **No se ejecutó la nueva prueba Godot contra una copia de la base sin parchear; no atribuir un runtime RED ni run ID inexistente**. El primer runtime de V6 `#43124880797` resultó FAIL con 22/23 checks por una referencia obsoleta en el test tras `load_game`, y no constituye una regresión real de producción; quedó reparado exclusivamente en el test antes de la CI verde.

## HUNK B — cambios permitidos exclusivamente
1. `scenes/visual/field_demo.gd`: nuevo `field_native_capture_zone(position, expected_zone)`. Devuelve ID solo cuando el `OverworldEncounterDirector` realmente conoce la zona, el jugador sigue en esa posición física, el `OverworldEncounterZone` real la contiene y la región (`cave`/`surface`) coincide. Por defecto `&""`. No altera el resolvedor de encuentros, pasos, tablas, RNG ni repelentes.
2. `scenes/visual/field_native_bridge.gd`: `on_step` transporta `zone` y `position` auténticos a `_open`. Esta instala un **Callable verificador vivo** en la sesión solamente después de abrir combate salvaje nativo. Al recuperar una partida, usa la `position` validada y el ID del rival original del snapshot para reconstruir el verificador: **no acepta campo de bonificación de SaveV2**.
3. `modules/gameplay/showdown_adventure_session.gd`: variables efímeras `_native_zone_source` y `_native_zone_target_id`, adaptador `bind_native_field_source` que rechaza origen no válido o rival de identidad distinta. `capture` revalida física e identidad antes de aplicar contexto: zona cambiada, región incorrecta, tabla inexistente o rival distinto **no concede ×3**. Las rutinas de ahorro de RNG y stock, Repeat, Moon, propiedad y settlement nativo permanecen como estaban.
4. `modules/capture/capture_battle_context.gd`: campo aditivo `native_field_zone_id` con valor por defecto `&""`, nunca serializado en el mundo/SaveV2.
5. `modules/capture/capture_context_ball_effects.gd`: registra solo `dusk_ball` contextual y aplica ×3 para `technical_cave_floor` verificado; si no, ×1. `CaptureRuleset` ya incorpora automáticamente IDs contextuales, así que no se editó.

**Sin editar:** `scenes/visual/field_item_bag.gd`, `CreatureInstance`, `FieldItemService`, `SaveGameData`, `FieldNativeSave`, `WildAdventureSession`, Showdown JS, políticas, RNG global ni otro subsistema. Los ocho blobs se cotejan por Git hash con el baseline IA6.

## B — matriz de productores pendientes (no declarar L3)

| Bola | Contexto auténtico requerido | Estado V6 |
|---|---|---|
| dusk_ball | Zona física de cueva; la noche queda pendiente de productor horario real | **L3 staging cueva**; hierba ×1 |
| dive_ball | Acción/área submarina verdadera (no tipo Agua de especie) | BLOCKED_CONTEXT |
| lure_ball | Acción de pesca real y su origen | BLOCKED_CONTEXT |
| love_ball | Relación de sexo/género de participantes validada por reglas y sesión | BLOCKED_CONTEXT |
| heavy_ball | Peso auténtico y handler/reglas de generación | BLOCKED_CONTEXT |
| beast_ball | Clasificación Ultraente verificada y reglas de perfil | BLOCKED_CONTEXT |

No habilitar falsas banderas de cueva, hora, pesca, género, peso ni Ultraente. No tocar `dynamax_candy`, expresamente excluido.

## C — límites de la certificación
- [CI #43125138000](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43125138000): **SUCCESS**, 21 steps SUCCESS / 0 FAIL, SHA de código+tests `a5733eb3683222d302ec6ed084bb1ac69575b9ce`.
- Positivo nativo `W03_DUSK_V6 PASS checks=23`: dos encuentros creados por sus respectivas zonas físicas, ×3/×1 calculados por captura real y comparados contra probabilidades nativas, stock, propietario, SaveV2 antes/después de captura.
- Adversarial `W03_DUSK_V6_NEG PASS checks=20`: productor de registro ausente → ×1, movimiento del jugador invalida fuente, ID de objetivo indebido rechazado al intentar vincular, intento nativo fallido con semilla real, inventario escalonado, dueño intacto, guardado/carga nativa y veto genérico de captura en entrenador.
- Cobertura diferenciada: **no se simuló intercambio real del rival dentro de una batalla nativa salvaje**, y el rechazo de entrenador se comprobó en `CaptureSystem.validate_attempt`, no recorriendo un combate completo contra un entrenador. No atribuir cobertura adicional.
- Regresiones: Repeat legacy=37, Repeat native=26 y negativos=18; Net=79 + negativos=19; Moon=41; Repel=66; SaveV2=40 y adversariales=8; menta nativa=18; mentas/Cuerda=65; panel libros base=20; panel W05 real=366; fuente anterior=1082. No son CAMP003–006 completas ni cobertura de todas las rutas W04/W02.
- La rama oficial IA6 avanzó a `5ece417fe0e15c9507c870601bf87ce97e184996` durante esta ejecución y debe evaluar **diff selectivo** sobre su propio HEAD, nunca fusionar un árbol completo basado en `ddc8a1af`.

**Estado:** `READY_FOR_IA6_MERGE_DUSK_CAVE_CANDIDATE` (código W03 V6 certificado). **Integración oficial de V6: NO**.
