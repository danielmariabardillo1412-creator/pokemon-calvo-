# IA6 — RELEVO ACTUAL 2026-11-10 · 19:22 EUROPE/MADRID

**AUDITORÍA:** [AUTONOMY_V1/IA6_AUDIT_RELAY_20261110_1922.md](IA6_AUDIT_RELAY_20261110_1922.md). Certificadas TANDA02 W01 (5 gemas, 5 QA), W02 (9 hitos funcionales con mentas, 1 QA), TANDA03 W03 (Repeat Ball L3, QA07/08 parciales), W05 (229 MT ya existentes, 10 QA). **W04 NO se cierra:** TANDA03 con CI de último HEAD aún no certificada.

**Colas ACTUALIZADAS YA EN RAMAS PROPIAS:** W01=T03 `QUEUE_W01_TANDA_03.md`; W02=T03 `QUEUE_W02_TANDA_03.md`; W03=T04 `QUEUE_W03_TANDA_04.md`; W05=T04 `QUEUE_W05_TANDA_04.md`. W04 sigue T03 sin modificar, bajo supervisión. Todas utilizan `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` de su propia rama. Usuarios pueden dar `p` solo a W01/W02/W03/W05 para trabajo **nuevo**; W04 puede seguir en su cola actual. Hitos != objetos nuevos != integración conjunta IA6.

**Riesgo prioritario IA6:** integración `codex/calvo-ia6-integration-20261109` sigue en SHA `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e` (#42701239557 SUCCESS) y NO incorpora automáticamente las nuevas ramas posteriores. El relevo autónomo de trabajadoras NO es un merge. Cada incorporación debe reconstruirse por función y comprobarse con CI conjunta, sin tocar main/V28/PR118.

---

# ACTUALIZACIÓN IA6 — TANDA 02 ACTIVADA EN W03/W04/W05 · 2026-11-10

**Tandas cerradas y verificadas:** W03 #42729137809 SUCCESS (10 revisadas/0 nuevas), W04 #42729967922 SUCCESS (10 revisadas/0 formas o fusiones nuevas), W05 #42730140482 SUCCESS (49/49 MT panel headless). Auditoría [IA6_AUDIT_BATCH01_AND_HANDOFF_BATCH02_20261110.md](IA6_AUDIT_BATCH01_AND_HANDOFF_BATCH02_20261110.md).

**Notas permanentes TANDA02 escritas en cada rama:** W03 = [QUEUE_W03_TANDA_02.md](QUEUE_W03_TANDA_02.md), captura persistente/Repeat Ball; W04 = [QUEUE_W04_TANDA_02.md](QUEUE_W04_TANDA_02.md), identidad de forma persistente; W05 = [QUEUE_W05_TANDA_02.md](QUEUE_W05_TANDA_02.md), otras 180 MT restantes de un total de 229. Usuario solo pulsa `p`; cada trabajadora lee su propio `IA6_AUTORUN.md`. No duplicar auditoría anterior ni atribuir L3 a nuevos productores antes de CI.

**Conflicto controlado:** W03 y W04 pueden tocar funciones distintas de `SaveGameData` / `field_native_save.gd` en ramas propias; **IA6 integrará selectivamente** conservando naturaleza efectiva y todos los tests, nunca merge automático. No se ha llevado todavía el código de estas nuevas ramas a `codex/calvo-ia6-integration-20261109`, `main` ni V28.

---

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
