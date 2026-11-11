# IA3/W03 — CAMPAÑA CONTINUA V2 FINALIZADA · 25 IDs de captura y campo

Fecha de cierre: **2026-11-11**. Rama exclusiva: `codex/calvo-items-20261104-w03-camp006`.

## Contrato y resultados reales

| Magnitud | Resultado |
|---|---|
| IDs de la cola V2 revisados | **25/25** |
| Rutas con captura nativa completa L3 y SaveV2 | **16** |
| Captura nativa demostrada pero semántica de zona parcial | **2**: `safari_ball`, `sport_ball` |
| Contexto de mundo ausente o ID no registrado | **7**: Dive, Dusk, Lure, Love, Moon, Heavy, Beast |
| Objetos nuevos creados en esta campaña | **0**; ya existían 18 registros de captura |
| Lanzamientos nativos positivos en los dos runners de la campaña | **18/18**; 2 requieren todavía política/productor de zona |
| Nuevas comprobaciones V2 certificadas | **418 PASS** |
| Integración real en la rama árbitra IA6 | **NO**; no se ha realizado merge/cherry-pick |
| Último SHA de código/CI | `2c4b0a63f04572be1dd86d565e7b71e78d897c65` |
| CI final acumulativa | [#42931723587](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42931723587): **completed/success**, misma SHA |

**La certificación L3 aquí implica capturas realmente ejecutadas desde la tabla de encuentros del mapa, simulación nativa, captura con objeto del inventario y publicación de propietario y SaveV2.** No significa diez mecánicas recién programadas: todas las bolas del bloque 01 eran IDs ya registrados en la implementación.

### B01 · 10/10, rutas nativas completas

`poke_ball`, `great_ball`, `ultra_ball`, `master_ball`, `nest_ball`, `fast_ball`, `dream_ball`, `heal_ball`, `premier_ball`, `friend_ball`.

`parallel_items_w03_continuous_v2_b01.gd` certifica 10/10 capturas, con semilla determinista escogida según la probabilidad real, stock, rechazo de un ID sin inventario, propietario, ledger de especie base y guardado/carga SaveV2. Mantiene la semántica de Master Ball sin RNG; Spore real para Dream y Heal; Heal cura estado y restaura PP, Friend establece amistad 200. `W03_CONT_V2_B01 PASS ids=10 captured=10 checks=156`.

Adicionalmente, `parallel_items_w03_continuous_v2_context_edges.gd` prueba tres ramas no cubiertas por el objetivo genérico Goldeen:
- **Fast ×4** con Mewtwo salvaje real, velocidad base suficiente y tasa de captura 3; probabilidad `0.0156862745098`, semilla reproducible `71007`.
- **Quick ×1 tras el primer turno**, que avanza mediante Reflect en sesión nativa, contra Goldeen: probabilidad `0.29411764705882`, semilla `71000`.
- **Level ×8 sin cap de tasa**, Mew del jugador nivel 50 frente a Mewtwo nivel 5: probabilidad `0.03137254901961`, semilla `71007`.
- Resultado `W03_V2_CONTEXT_EDGES PASS branches=3 checks=35`.

### B02 · 10/10 examinadas: 6 L3, 2 parciales, 2 bloqueadas

| ID | Clasificación | Prueba |
|---|---|---|
| `safari_ball` | **PARCIAL_ZONE** | Captura nativa ×1,5 y SaveV2 positivos, pero no existe productor de zona Safari |
| `sport_ball` | **PARCIAL_ZONE** | Captura nativa ×1,5 y SaveV2 positivos, pero no hay evento real de Concurso Bicho |
| `cherish_ball` | **L3 existente** | Captura nativa ×1, stock/dueño y SaveV2 |
| `quick_ball` | **L3 existente** | ×5 primer turno, ×1 tras Reflect; semilla y SaveV2 |
| `timer_ball` | **L3 existente** | ×1,3 después de un turno real de Reflect |
| `level_ball` | **L3 existente** | Cap de tasa en Goldeen y ×8 sin cap en Mewtwo |
| `net_ball` | **L3 previamente certificada** | Revalidación nativa; caso Agua/Bicho y SaveV2 ya certificados en TANDA05 |
| `repeat_ball` | **L3 previamente certificada** | Revalidación nativa; historial positivo y adversarial ya certificados en TANDA03/04 |
| `dive_ball` | **BLOCKED_CONTEXT** | No hay origen auténtico pesca/surf/buceo ni regla regional conectada |
| `dusk_ball` | **BLOCKED_CONTEXT** | No existe productor de noche/cueva/oscuridad autenticado para captura |

`W03_CONT_V2_B02 PASS ids=8 captured=8 checks=125`. Los ocho casos nativos nuevos pasan. Safari/Sport NO quedan contabilizadas entre las 16 L3 completas porque sus regiones o eventos aún no están conectados. Net/Repeat no cuentan como objetos nuevos por repetirse en esta CI.

### B03 · 5/5 revisadas, todas bloqueadas por productor compartido

`lure_ball`: procedencia de pesca; `love_ball`: sexo individual real por especie y forma; `moon_ball`: líneas canónicas de evolución con Piedra Lunar; `heavy_ball`: peso de la forma y fórmula exacta; `beast_ball`: identidad de Ultraente y política de tasa.

Estas cinco, junto con Dive y Dusk, **no se registran artificialmente ni se prueban con flags inventados**. La auditoría comprueba 25 IDs, el registro de 18 ya operativas, la procedencia realmente construida por `showdown_adventure_session.gd::capture` y las ausencias de `CaptureBattleContext`: `W03_CONT_V2_SOURCE PASS checked=25 blocked_context=7 partial_zone=2 checks=58`.

Ticket único para IA6: [`W03_CONTEXT_PRODUCERS_TICKET.md`](W03_CONTEXT_PRODUCERS_TICKET.md).

### Incidencia separada: Magikarp nivel 5

`parallel_items_w03_continuous_v2_magikarp_probe.gd` reproduce el rechazo nativo `move_policy` de Magikarp a nivel 5 con seis integrantes de equipo y la primera caja llena. Comprueba que el rechazo ocurre **antes del lanzamiento** y no gasta bolas ni pierde criaturas. Cambiando únicamente la tabla real al objetivo Goldeen nivel 5, el mismo propietario sí entra en combate. `W03_V2_MAGIKARP_PROBE PASS checks=44 status=KNOWN_MOVE_POLICY_NO_BALL_LOSS`.

**Alcance limitado del diagnóstico:** confirma una frontera específica de preparación de encuentro, no la causa concreta en el learnset/selector de movimientos. La reparación de la política y el generador compartido **requiere IA6**. No se alteró código de producción para hacer pasar este test.

## QA nueva y regresiones del SHA certificado

| Runner V2 | Resultado |
|---|---:|
| `W03_CONT_V2_B01` | 156 PASS |
| `W03_CONT_V2_B02` | 125 PASS |
| `W03_CONT_V2_SOURCE` | 58 PASS |
| `W03_V2_MAGIKARP_PROBE` | 44 PASS |
| `W03_V2_CONTEXT_EDGES` | 35 PASS |
| **Total de comprobaciones V2 nuevas** | **418 PASS** |

También superaron la misma CI `FIELD_NATIVE` (118), Repeat V3 (26), Repeat V4 (26+18+20), Net V5 (sus cuatro runners), SaveV2 normal/adversarial, repelentes L3 (65), CAMP005 W03 Python (169) y Godot (208), CAMP006 W03 Python (54 con `deferred=1` **heredado y explícito**) y Godot (78). No se deshabilitaron ni rebajaron puertas históricas.

## Archivos propios nuevos y alterados

- `tests/gameplay/parallel_items_w03_continuous_v2_b01.gd`
- `tests/gameplay/parallel_items_w03_continuous_v2_b02.gd`
- `tests/gameplay/parallel_items_w03_continuous_v2_magikarp_probe.gd`
- `tests/gameplay/parallel_items_w03_continuous_v2_context_edges.gd`
- `tests/tools/test_parallel_items_w03_continuous_v2_sources.py`
- `.github/workflows/parallel-camp006-w03-autoci.yml`
- `docs/coordination/items_parallel_v1/CONTINUOUS_V2/STATE_W03.md`
- `docs/coordination/items_parallel_v1/CONTINUOUS_V2/W03_MANIFEST.csv`
- `docs/coordination/items_parallel_v1/CONTINUOUS_V2/W03_CONTEXT_PRODUCERS_TICKET.md`
- Este informe documental, publicado después de la CI y marcado `[skip ci]`.

**Sin cambios de producción** en `CaptureRuleset`, `CaptureBattleContext`, `showdown_adventure_session.gd`, `SaveV2`, `FieldItemBag`, `PlayerCollection`, generadores del mundo ni el RNG; tampoco `main`, V28, PR118, otras trabajadoras ni la rama árbitra. Los commits documentales posteriores al SHA `2c4b0a63` **no tienen CI propia** y no deben atribuirse a ella.

## Entrega IA6 / parada válida V2

La lista de 25 IDs **se ha agotado**. Quedan 7 IDs que requieren nuevas interfaces/proveedores de contexto y 2 que requieren una política explícita de zona; no hay otro trabajo independiente autorizado dentro del plan. IA6 debe examinar el ticket, decidir productores y permisos, y efectuar integración selectiva con CI cruzada si lo aprueba.

**Estado final: `READY_FOR_IA6`. 25/25 examinadas · L3 completas 16 · parciales 2 · bloqueadas 7 · objetos nuevos 0 · QA V2 418 PASS · integración IA6 NO.**
