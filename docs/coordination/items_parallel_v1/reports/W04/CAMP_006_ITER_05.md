# IA4/W04 — CAMPAÑA_006 / bloque 05 (salto excepcional 04 aplazado)

**Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`. **Fecha:** 2026-11-09. **Nuevos objetos:** 0.
**Decisión vinculante:** `docs/coordination/items_parallel_v1/CAMPAIGN_006_W04_BLOCK04_DEFER_CONDITIONS_GATE_20261109.md` de árbitra IA6 (blob `66a0d88d5ddbf38e13d96ff7de07dae3090dc6ca`).

## Recuento verificable

`last_executed_id=05`, `deferred=["04"]`, `completed=3`, `completed_ids=["01","02","03"]`, `evaluated_ids=["01","02","03","05"]`.

- **Bloque04**: `DEFERRED_POR_POLITICA`; fuera de la lista de pruebas funcionales; 0 cambios; no se le acredita un PASS.
- **Bloque05**: `BLOCKED_MISSING_SHARED_PRODUCERS`. Se investigaron 3 objetos / 4 rutas, pero **0 evoluciones nuevas funcionales L2/L3**; no se le acredita un bloque completado.
- **Bloques01-03**: se ejecutan íntegramente las pruebas L3 anteriores, con sus limitaciones previas. Los PASS del runner significan que las pruebas pasan, **no** que 05 se integra.
- La regresión CAMP005 original se ejecuta expresamente en esta ocasión por ser hito `last_executed_id=05`. No modificar su cobertura.

## Las cuatro condiciones fuente contrastadas con PokeAPI

| Ítem | Origen → destino | Archivo PokeAPI | Disparador y condición original |
|---|---|---|---|
| `oval_stone` | Happiny → Chansey | `data/api/v2/evolution-chain/51/index.json` | `level-up` con `held_item=oval-stone` y `time_of_day=day` |
| `dawn_stone` | Kirlia → Gallade | `data/api/v2/evolution-chain/140/index.json` | `use-item`, Piedra Alba y `gender=2` (macho) |
| `dawn_stone` | Snorunt → Froslass | `data/api/v2/evolution-chain/186/index.json` | `use-item`, Piedra Alba y `gender=1` (hembra) |
| `peat_block` | Ursaring → Ursaluna | `data/api/v2/evolution-chain/110/index.json` | `use-item`, Bloque de Turba y `time_of_day=full-moon` |

Las condiciones importadas en `CreatureSpecies.evolutions` están presentes pero `EvolutionSystem.classify_record` las conserva como `DATA_ONLY`; los productores reales no están conectados. Para Happiny, `min_level=null` de la API **no autoriza** elegir un nivel nuevo. La condición es un *level-up* con objeto equipado y de día, no usar Piedra Oval desde mochila. Para Ursaring, `full-moon` no equivale a asumir noche o utilizar el reloj del sistema operativo.

## Ticket único a IA6: interfaz requerida para evolución real

**Productor 1 — sexo individual.** Captura/creación debe asignar sexo canónico por individuo, con apoyo en metadatos de especies solo como restricciones probabilísticas, no como sexo determinado. `CreatureInstance.to_dict/from_dict` y SaveV2 deben serializar la identidad, ofrecer migración definida para partidas antiguas y preservar el sexo tras la evolución. **Propiedad compartida IA6**, sin modificar desde W04.

**Productor 2 — día.** El reloj del mundo jugable debe proporcionar una hora/fase del día autoritativa y reproducible, guardada/cargada en SaveV2, y hacerla accesible en el evento de subida de nivel de Happiny. No confundir los `native_sleep_clocks` (relojes de sueño del combate) con día del mundo. `EvolutionSystem.level_up_context` necesita el objeto equipado y la condición de día suministrada por el productor apropiado.

**Productor 3 — luna.** Un calendario/fase lunar jugable y persistente debe determinar la condición de luna llena para Ursaring. Sin fuente ni política aprobada, no se puede habilitar `peat_block` sin convertir arbitrariamente cualquier día o noche en luna llena.

**Consumidores:** `EvolutionSystem.classify_record/evolution_candidates` deberá comprobar los valores contra fuentes concretas, sin aceptar contexto omitido o inventado. `FieldItemService.evolution_options/evolve` deberá validar `gender` y `full-moon` cuando el contrato exista, gastar únicamente el ítem correcto en operación exitosa, y no gastar en fallo; `ProgressionSystem.gain_experience` debe pasar contexto de día/held para Piedra Oval. Eventual evolución confirmada, reemplazo de criatura, compatibilidad con SaveV2 y rollback pertenecen a integración coordinada IA6.

**Pruebas necesarias antes de certificar funcionalidad:**
- Kirlia macho con Piedra Alba → Gallade; Kirlia hembra rechazada sin gasto; Snorunt hembra → Froslass y macho rechazado; persistencia de sexo desde creación hasta guardar/cargar, estabilidad de identidad.
- Happiny portando Piedra Oval evoluciona **al subir de nivel de día**; sin objeto o de noche no; mismo `instance_id`, inventario/held y SaveV2 coherentes.
- Ursaring evoluciona con Bloque de Turba **durante luna llena real del mundo**; en otra fase no, sin gastar; fase persistida al guardar/cargar.
- No usar un evento de tiempo simulado por el test como prueba de integración de mundo; solo contexto emitido por la fuente autorizada. Sin productor positivo, no se contabiliza L2/L3.

## Entrega técnica y límites

`tests/fixtures/parallel_items/w04_campaign_006.json`: añade `execution_state`, `deferred_blocks` solo 04 y entrada diagnóstica 05 sin crédito.
`tests/tools/test_parallel_items_w04_campaign_006.py`: preserva contratos anteriores; verifica cuatro cadenas fuente y ausencia real de productores; emite `PASS completed=3 last_executed=05 deferred=04` (PASS de pruebas, no de mecánica05).
`tests/gameplay/parallel_items_w04_campaign_006.gd`: sigue ejecutando todas las pruebas anteriores y verifica clasificación `DATA_ONLY` y carencia de fuentes; **no** intenta forzar evolución.
`.github/workflows/parallel-camp006-w04-autoci.yml`: puerta oficial para filas `01,02,03,05`, `completed=3`, `deferred=04`; rehace regresión CAMP005 al llegar a `last_executed_id=05`.
`reports/W04/CAMP_006_PROGRESO.csv`: filas `01,02,03,05`, 04 fuera, fila05 clasificada como bloqueo de productor.

**Sin cambios** en producción, `CreatureInstance`, SaveV2, escena, servicios compartidos, datos canónicos, `main`, V28, PR #118 ni otras ramas. CI del bloque05 debe leerse en GitHub antes de añadir los recibos definitivos.

**Siguiente acción:** IA6 debe publicar autorización de productor/semántica o reasignar trabajo independiente. No dar por concluido 05 ni disparar 06 en esta ventana por una `p` sin resolver antes este gate.
