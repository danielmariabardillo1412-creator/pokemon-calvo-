# IA6 — ORDEN PERMANENTE AUTORUN V1 — W03
**Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`
**Estado desde el que se reanuda:** CAMP006 bloque03 repelentes L3 certificado #42716742131 SUCCESS; 01–03 cerrados, 04 aplazado, 05 bloqueado por productor.
**Activador:** `p`, `sigue` o `continúa` inicia o reanuda los **diez bloques de esta tanda**, sin pedir nuevo permiso por cada fila. Se trabaja hasta donde permita el turno/herramientas; si se interrumpe, checkpoint y siguiente `p` retoma la siguiente fila no cerrada.
**Reglas vinculantes:** leer `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`. Se autoriza la reparación autónoma en archivos propios, la migración versionada de pruebas históricas y seguir con filas independientes pese a bloqueos. **Nunca saltar pruebas ni inventar L3.**
**Resumen al usuario:** barra de filas revisadas `[████░░░░░░] 4/10` y **funcionales N/10** diferenciadas; solo al final enviar cierre a IA6.
**Informe final único:** `docs/coordination/items_parallel_v1/reports/W03/AUTORUN_V1_FINAL.md`; estado por fila en `AUTORUN_V1_PROGRESS.csv`. No tocar main, V28, PR118 ni otras ramas.

## Tanda 01 — diez filas: completar cola de captura, sin repetir repelentes
| Fila | Origen | Objetos o tarea |
|---|---|---|
| 01 | CAMP006 B04 | `black_flute;white_flute;lure;super_lure;max_lure` |
| 02 | CAMP006 B05 | `dive_ball;lure_ball` |
| 03 | CAMP006 B06 | `dusk_ball` |
| 04 | CAMP006 B07 | `repeat_ball` |
| 05 | CAMP006 B08 | `safari_ball;sport_ball` |
| 06 | CAMP006 B09 | `love_ball;moon_ball;heavy_ball;beast_ball` |
| 07 | CAMP006 B10 | `friend_ball;heal_ball;quick_ball;timer_ball` |
| 08 | QA dedicado | Revalidar repelentes L3 (100/200/250 pasos, RNG consumido sin semilla de combate, legacy SaveV2) en nueva CI de la tanda, **sin recertificar como nuevo bloque** |
| 09 | QA dedicado | Revalidar `escape_rope` y `fluffy_tail` junto al flujo de captura nativo, sin doble consumo/guardado automático |
| 10 | QA de cobertura | Informe reproducible del contrato de `CaptureBattleContext` y tabla de procedencia REAL de noche/cueva, agua/pesca, Pokédex y zona; tests de fuente y no flags ficticios |

**Autoridad heredada:** `CAMPAIGN_006_W03_BLOCK03_REPEL_L3_WORLD_SEAM_AUTH_20261109.md` sigue válida SOLO para repelentes; IA6 integrará sus cambios en versión compartida de mochila/escena. No se reabre B03. Para B04–B10 se autorizan pruebas, adaptadores propios de captura y consumo solo dentro de APIs ya existentes y propiedad W03; si requieren nuevo `FieldItemBag`, `field_demo.gd`, `field_native_bridge.gd`, SaveV2 central o alterar RNG general, documentar contrato y marcar esa fila **BLOQUEADA**, pero seguir inmediatamente las otras filas independientes. No inventar pescas, día/noche, Pokédex o zonas si el productor aún no existe. Tampoco retrogradar resultados L3 previos.

**Criterios positivos:** wild encounter real, contexto real de origen, CaptureBattleContext, bonus/tasa de captura según reglas existentes, RNG/seed/no-conjunto, consumo y SaveV2/propiedad; conservar CI CAMP006 01–03 y CAMP005. Si B04/B05 siguen bloqueados, no repetir 10 negativas; una sola prueba/ticket por productor. Informar cierre por las diez filas examinadas, con funcionales reales separados del total.
