# IA6 — CENTRO DE COLAS AUTÓNOMAS · 2026-11-10

**Protocolo obligatorio:** [README.md](README.md). **Una copia íntegra de cada orden** también está en `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` de la propia rama de cada W; es el archivo estable que deben abrir al recibir `p`/ `sigue`. No hace falta mensajería IA6 por microbloque.

| Trabajadora | Cola 10 filas | Rama de trabajo | Baseline comprobado al asignar |
|---|---|---|---|
| IA1/W01 | [QUEUE_W01.md](QUEUE_W01.md): 10 gemas de tipo, 1/ID | `codex/calvo-items-20261110-w01-gems-autobatch01` | CAMP005 10/10, run #42717306543 SUCCESS; nueva rama desde f7f28b1e |
| IA2/W02 | [QUEUE_W02.md](QUEUE_W02.md): 10 mentas pendientes + reparación de regresión histórica | `codex/calvo-items-20261109-w02-mints-integration` | Pilot02 positive Python 39/Godot 223; global #42715490604 FAILED por negativas antiguas |
| IA3/W03 | [QUEUE_W03.md](QUEUE_W03.md): CAMP006 04–10 + 3 QA de campo | `codex/calvo-items-20261104-w03-camp006` | Repel L3 #42716742131 SUCCESS; 04/05 siguen diferidos |
| IA4/W04 | [QUEUE_W04.md](QUEUE_W04.md): CAMP006 07–10 + 6 QA/contratos de evolución | `codex/calvo-items-20261104-w04-camp006` | completed=3, 04/05/06 pendientes; Milcery resolver pura #42715401401 SUCCESS |
| IA5/W05 | [QUEUE_W05.md](QUEUE_W05.md): UI de 49 libros MT, 10 grupos canónicos | `codex/calvo-items-20261109-w05-books-ui` | Libros UI02 #42714738745 SUCCESS; panel aislado pendiente de nueva integración IA6 |

## Flujo de control exacto

1. IA6 deja en GitHub una **orden completa**. Ninguna W solicita otra puerta dentro de sus diez filas mientras respete archivos permitidos. Si encuentra bloqueo compartido, ticket 1 vez, estado BLOQUEADO y salto a otra fila independiente.
2. Usuario a cada W: `sigue` o `p`. Si el primer intento no reconoce la nueva política, una única instrucción común basta: «Lee `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` en tu rama y ejecuta la tanda de diez filas con el protocolo IA6». No es necesario repetir ese mensaje en siguientes tandas.
3. La trabajadora continúa hasta cubrir 10 filas, publica `AUTORUN_V1_FINAL.md`, HEAD/CI/efectos probados y mensaje de cierre. Si el turno acaba antes, checkpoint + nueva `p`; **no hay ejecución en segundo plano garantizada**.
4. Usuario a IA6 únicamente: «IAx terminó». IA6 lee su final y la CI, integra selectivamente en rama aislada y actualiza tanto la cola árbitra como la nota **en esa misma rama** para la tanda siguiente.
5. Secciones cerradas con PASS no se vuelven a fabricar. La CI de SHA y casos positivos es obligatoria; 10 filas revisadas no equivale a 10 mecánicas nuevas.
6. La rama árbitra y la de integración son propiedad IA6; `main`, V28 y PR #118 siguen protegidas.

**Importante:** GitHub es la memoria y el tablero persistente, **no un sistema que mande órdenes automáticamente a ventanas de chat**. Los trabajadores deben abrir su nota al reanudar. Este límite del producto no se oculta ni se sustituye por promesas de trabajo en background.
