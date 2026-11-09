# W04 — CAMPAÑA_006: resolver puro de condiciones de evolución (IA6, 2026-11-09)

**Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`. **Autoridad:** `docs/coordination/items_parallel_v1/IA6_REACTIVATION_W02_W05_W03_W04_20261109.md`.

**Estado de campaña sin cambios:** `completed=3`, `completed_ids=["01","02","03"]`, `deferred=["04"]`, `last_executed_id="05"`, fila 05 `BLOCKED_PRODUCER_VERIFIED`. **No se implementó una evolución jugable L3** ni se completó 04/05. No se inicia 06.

## Entrega funcional aislada

Archivo: `modules/creatures/progression/evolution_condition_resolver_w04.gd`. Componente `RefCounted` independiente sin registrar en `EvolutionSystem` ni `FieldItemService`. Firma:

```gdscript
const Resolver = preload("res://modules/creatures/progression/evolution_condition_resolver_w04.gd")
var outcome: Dictionary = Resolver.evaluate(canonical_record, event, facts)
# {"eligible": bool, "reason": String, "scope": "RESOLVER_ONLY", "mutates": false}
```

- `canonical_record: EvolutionRecord` procede de la lista real `catalog.species(source).evolutions` **seleccionada por especie y destino por el consumidor**. El resolver no selecciona ni autentica por sí solo la especie o la versión canónica; no invocar con registros sintetizados en gameplay.
- `event: Dictionary` exige `{"trigger":"use_item","item_id":"dawn_stone"}` / `{"trigger":"use_item","item_id":"peat_block"}`, o `{"trigger":"level_up","previous_level":int,"new_level":int}` **solo desde un evento real de subida**. Una selección de mochila no equivale a `level_up`, aunque lleve Piedra Oval. No se inventan umbrales; `record.min_level` se respeta si alguna ruta dispone de un mínimo real.
- `facts: Dictionary` requiere `{"gender": 1|2}` para Piedra Alba; `{"held_item_id":"oval_stone","held_item_consumed":false,"daypart":"day"|"night"}` para Piedra Oval; `{"moon_phase":"full"|"not_full"}` para Bloque de Turba. Los enteros canónicos PokeAPI son `1=hembra`, `2=macho`.
- El `EvolutionRecord.conditions.time_of_day="full_moon"` original del Bloque de Turba se **interpreta como fase lunar**, nunca como sinónimo de `daypart="night"`.
- Deniega por defecto hechos ausentes/tipos equivocados, objeto equivocado, género incorrecto, luna no llena, día equivocado, objeto equipado ya consumido, ausencia de evento real de nivel, trigger `trade`, condiciones adicionales desconocidas y rutas sin condiciones. No altera registros, eventos, hechos, inventario, propiedad ni estado de criatura.
- **El resolver no verifica la procedencia de `facts`**. En las pruebas unitarias se inyectan valores inventados *solo para verificar el predicado*. No se deben tomar por estados reales del juego; `scope=RESOLVER_ONLY` lo advierte. No usar `eligible=true` para mutar una criatura hasta que IA6 integre los productores y el servicio transaccional.

## Cuatro rutas reales y fuente

| Fuente canónica local | Transición | Predicado puro |
| --- | --- | --- |
| `data/api/v2/evolution-chain/140/index.json` | Kirlia → Gallade | `use_item=dawn_stone`, `gender=2` |
| `data/api/v2/evolution-chain/186/index.json` | Snorunt → Froslass | `use_item=dawn_stone`, `gender=1` |
| `data/api/v2/evolution-chain/51/index.json` | Happiny → Chansey | `level_up` real, `held_item=oval_stone` sin consumir, `daypart=day` |
| `data/api/v2/evolution-chain/110/index.json` | Ursaring → Ursaluna | `use_item=peat_block`, `moon_phase=full` |

La batería `tests/gameplay/parallel_items_w04_condition_resolver.gd` usa los registros importados de `data/normalized/pokemon_api.json` y realiza comprobaciones positivas y negativas del predicado y pureza. Sus ejemplos de transición `39 → 40` son solo datos de prueba, **no un nivel mínimo normativo**. También comprueba que `EvolutionSystem.classify_record` sigue en `DATA_ONLY` y que `EvolutionSystem.evolution_candidates` no reconoce todavía las rutas como funcionales, aunque el resolver puro devuelva `eligible=true` con hechos inyectados.

El workflow `.github/workflows/parallel-camp006-w04-autoci.yml` incorpora un paso **separado** del runner Godot existente para el nuevo módulo, mantiene los recibos `completed=3 last_executed=05 deferred=04`, y conserva las regresiones acumulativas CAMP006/CAMP005. El validador Python `tests/tools/test_parallel_items_w04_campaign_006.py` verifica el alcance y el aislamiento.

## Contrato mínimo a entregar a IA6

**Productores y responsabilidades (faltan en gameplay):**

1. **Factory / captura → CreatureInstance / SaveV2:** añadir `individual_gender` autoritativo y persistente por ejemplar; codificación `1=female`, `2=male`; para especies sin sexo o partidas antiguas sin dato, valor explícito `unknown` que el consumidor rechace, no derivarlo del ratio de especie a posteriori. Determinar generación, migración SaveV2, conservación tras evolución y ownership central. **No se ha tocado este código.**
2. **Reloj del mundo jugable / SaveV2:** publicar `daypart` `day|night` de un reloj de mundo con reglas y persistencia verificables; no emplear hora del SO, reloj de sueño de combate o un campo sintético creado en un test. Entregar la observación en el evento real de evolución por nivel de Happiny. **No se ha tocado reloj global.**
3. **Calendario lunar del mundo / SaveV2:** publicar `moon_phase` `full|not_full` desde una regla de calendario aprobada, determinista y persistente; no suponer que noche es luna llena. **No se ha creado calendario ficticio.**
4. **ProgressionSystem / FieldItemService / owner:** seleccionar `EvolutionRecord` de especie real y entregar un evento `previous_level/new_level` auténtico, el held `held_item_id/held_item_consumed` desde CreatureInstance y el día del mundo, o `item_id` y el sexo/fase desde productor persistente. Llamar al predicado **antes de gastar objetos**; revalidar ownership y estado en commit; efectuar sustitución de criatura, gasto y rollback en servicio de IA6. Pruebas positivas/negativas de UI, SaveV2, cambio de fase y migración antes de aceptar L3. No modificar políticas V27 sobre evoluciones por intercambio.

**Invariante:** el consumidor jamás debe habilitar una evolución al faltar un dato: `eligible=false`. El resultado exitoso del resolver **no** garantiza procedencia de los datos y debe permanecer fuera de la ruta jugable hasta que se conecten estos productores.

## Evidencia CI

**Pendiente de adjuntar:** ejecutar GitHub Actions sobre SHA que incluya módulo, test, workflow y guardas; exigir un recibo `CAMP006_W04_CONDITION_RESOLVER cases=4 positives=4 status=PURE_L2_NOT_GAMEPLAY_L3 completed=3 last_executed=05 deferred=04` y `CAMP006_W04_RESOLVER_L2 PASS completed=3 last_executed=05 deferred=04 checks=N`. Además, los cuatro pasos existentes (CAMP006 Python/Godot y CAMP005 Python/Godot) deben mantener éxito. Cualquier `FAIL` requiere reparación antes de certificar el piloto.

**Archivos compartidos no modificados:** `CreatureInstance`, `CreatureFactory`, `ProgressionSystem`, `EvolutionSystem`, `FieldItemService`, SaveV2, `field_demo.gd`, `main`, V28, PR #118, rama árbitra y demás ramas.
