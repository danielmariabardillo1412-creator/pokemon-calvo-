# IA6 — REVISIÓN DE CINCO TRABAJADORAS Y NUEVAS MISIONES · 2026-11-12

**Usuario ordena revisar trabajadoras cerradas y asignar trabajo real.** Se han consultado HEAD, notas AUTORUN y STATE/FINAL de cada rama; las ramas nuevas y los planes están publicados y reenlazados desde ramas anteriores. **NINGUNA misión nueva tiene código, CI ni cierre aún.** Los planes no ejecutan tareas en segundo plano.

| IA | Fuente comprobada | Estado real | Acción IA6 |
|---|---|---|---|
| W01 | `codex/calvo-ia6-staging-20261111-w01-held` SHA documental `cfc1e18de0c6651ccd92e918da572c2e02173f8a` | **ACTIVA V4**: gemas 18/18 con CI, 4 placas piloto CI #43095875174 pendiente de resolución en su último STATE; T01–04/CAMP003–005 equivalencia aún no cerrada | No tocar/renovar; siguiente `p` revisa run de placas y sigue staging |
| W02 | `codex/calvo-items-20261109-w02-mints-integration` HEAD `c5371d6a76a1848e93dcbd35a9c7b456c5aac0b2` | **V3 AÚN ASIGNADA, NO CERRADA** (participantes / EXP Share), checkpoint inicial sin código V3. V4 staging preasignada tras cierre V3 | No duplicar; seguir V3 con `p`, V4 solo al READY real |
| W03 | `codex/calvo-items-20261111-w03-repel-staging-v5`; captura/repeles integrados oficialmente en `codex/calvo-ia6-integration-20261109`, CI #43106031150 y #43106031155 SUCCESS | **V5 CERRADA; sin trabajo nuevo previo** | Nueva V6 `codex/calvo-items-20261112-w03-dusk-cave-v6`: Bola Ocaso con fuente real de cueva, test rojo + productor nativo + SaveV2 y regresiones; `CONTINUOUS_V6/PLAN_W03.md` |
| W04 | `codex/calvo-items-20261111-w04-regional-level-v5`, CI #43073026880 SUCCESS | **V5 CERRADA**, diez rutas regionales desde servicio OK, pero **falta aceptación/publicación en juego** | Nueva V6 `codex/calvo-items-20261112-w04-evolution-consumer-v6`: consumidor real XP poscombate→UI→owner/SaveV2, `CONTINUOUS_V6/PLAN_W04.md` |
| W05 | `codex/calvo-ia6-staging-20261111-w05-books`, CI #42965926888 SUCCESS, oficial W03/W05 gates cross verde | **V4 CERRADA**, 229/229 libros SV | Nueva V5 `codex/calvo-items-20261112-w05-legacy-books-v5`: 19 seleccionados fuera SV = 14 TM/TR candidatas + 5 HM con regla especial, versión histórica **opt-in** con fuente exacta; `CONTINUOUS_V5/PLAN_W05.md` |

## Criterios de auditoría
- 10/10 hitos != 10 objetos nuevos. Las misiones nuevas trabajan funcionalidades ausentes de IDs existentes; no añaden IDs al catálogo, no cuentan como implementado hasta SHA y CI nuevos.
- Veto `dynamax_candy` permanece vinculante. No tocar main, V28, PR118 ni sobreescribir la integración oficial `codex/calvo-ia6-integration-20261109`.
- W03 nueva parte de la rama oficial con Repel/Libro/Rope/captura integrados. W05 nueva también. W04 parte de su V5 para conservar fixes de forma, y **IA6 tendrá que reconciliarla con el árbol oficial más reciente**, nunca merger completo.
- Prohibido inventar contextos nativos: Dusk necesita cueva real; HMs no prometen acciones de campo; W04 no equipara emitir un evento con reemplazar la identidad; Exp Share es responsabilidad W02.
- Los planes autorizan arreglos de producción en ramas nuevas solo dentro de hunks concretos, pruebas positivas y negativas y CI propia. IA6 integrará **después** tras selectividad/regresiones. Si no hay productores reales, ticket y bloqueo, nunca SUCCESS ficticio.
- **Relevos directos escritos:** `IA6_AUTORUN.md` en W03 V5, W04 V5 y W05 V4 apuntan a nuevas ramas. Las nuevas ramas incluyen plan íntegro en `IA6_AUTORUN.md` + `STATE_W0X.md` inicial.
- **Estado de integración oficial anterior** verificado en W03: CI oficiales #43106031150/43106031155 SUCCESS sobre HEAD `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`; no convertir esas CI en prueba de nuevas ramas.
