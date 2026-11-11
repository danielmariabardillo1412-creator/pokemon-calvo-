# IA1/W01 — CONTINUOUS_V2 / Auditoría anticipada de alcance Fase B

**Naturaleza del documento:** lectura/preflight, **NO funcionalidad implementada, QA ejecutada ni CI certificada**. Se prepara mientras la Fase A (TANDA04) cierra su puerta acumulativa. Los 26 IDs proceden de `CONTINUOUS_V2/PLAN_W01.md` copiado en `IA6_AUTORUN.md`; este preflight no crea autorizaciones ni cambia de fase.

**Rama exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`. Datos consultados en HEAD `5f9b7a05bdafbdac531366ee266c2357ed56e4dd`. Contraste: `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, `ITEM_INVENTORY.csv`, `item_connections_v1.json::holdable_ids`, `tools/item_audit/held_pilot.cjs`, `test_parallel_items_w01_campaign_001.py`.

- 26 candidatos de la orden V2 y los 26 dentro de `holdable_ids`; **solo 22** muestran simultáneamente `SELECCIONADO` y `native_entry=True`. Esto indica posibilidad de probarlos, **NO certificación de efecto**.
- **4 candidatos sin entrada seleccionada en el CSV efectivo y con `native_entry=False`:** `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`. En inventario figuran `DATA_ONLY`. No implementar mecánicas de dinero, encuentros o crianza en W01 ni contarlos como `CERTIFICADO` por `holdable`; registrar `DEPENDENCIA_FUERA_W01` al procesarlos si siguen así.
- La evidencia nativa previa de `expert_belt` y escenario de `big_root` no equivale automáticamente a certificación end-to-end. Revisar SHA/CI real y añadir únicamente cobertura L3 ausente.
- **Placas:** únicamente boosts de tipo de batalla. Sin `Arceus` / transformación / formas, ámbito de W04. Sin multiplicadores hardcoded; comprobar motor nativo y contextos negativos.

| Bloque | ID | Selección efectiva | Entrada nativa | Historial detectado | Acción al iniciar Fase B |
|---|---|---|---|---|---|
| 01 | `ability_shield` | SELECCIONADO | Sí | No verificada L2/L3 | Ejecutar prueba positiva/negativa L2 y L3 |
| 01 | `absorb_bulb` | SELECCIONADO | Sí | No verificada L2/L3 | Ejecutar prueba positiva/negativa L2 y L3 |
| 01 | `adrenaline_orb` | SELECCIONADO | Sí | No verificada L2/L3 | Ejecutar prueba positiva/negativa L2 y L3 |
| 01 | `big_root` | SELECCIONADO | Sí | Escenario CAMP001 previo | Conservar CAMP001 y verificar drenaje L3 |
| 01 | `expert_belt` | SELECCIONADO | Sí | Piloto nativo previo | Contrastar cobertura nativa previa antes de L3 |
| 01 | `amulet_coin` | SIN_FILA_EN_POLICY | No | No verificada L2/L3 | DEPENDENCIA_FUERA_W01: selección/productor no acreditados |
| 01 | `pure_incense` | SIN_FILA_EN_POLICY | No | No verificada L2/L3 | DEPENDENCIA_FUERA_W01: selección/productor no acreditados |
| 01 | `luck_incense` | SIN_FILA_EN_POLICY | No | No verificada L2/L3 | DEPENDENCIA_FUERA_W01: selección/productor no acreditados |
| 01 | `cleanse_tag` | SIN_FILA_EN_POLICY | No | No verificada L2/L3 | DEPENDENCIA_FUERA_W01: selección/productor no acreditados |
| 01 | `draco_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `dread_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `earth_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `fist_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `flame_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `icicle_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `insect_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `iron_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `meadow_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `mind_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 02 | `pixie_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 03 | `sky_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 03 | `splash_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 03 | `spooky_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 03 | `stone_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 03 | `toxic_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |
| 03 | `zap_plate` | SELECCIONADO | Sí | No verificada L2/L3 | Probar daño por tipo; no formas Arceus |

## Guardarraíles
1. **No entrar en Fase B hasta cerrar Fase A** con 10 filas contablemente resueltas y CI acumulativa de su código correcto, o documentar blockers independientes según orden IA6.
2. Antes de cada ID, verificar política actual, productor y tests históricos del HEAD real; un `NATIVE_ENTRY_REQUIRES_EFFECT_CASE` no acredita daño o activación.
3. No modificar `main`, V28, PR118, W02-W05, código compartido, IA6 integración ni catálogo de formas. Los cuatro no seleccionados no se convierten en nuevas tareas por decisión local.
4. El cierre de Fase A debe distinguir objetos ya funcionales, efectos L3 nuevos **en cobertura**, nuevas implementaciones de producción (hasta la última certificación: 0) e integración IA6 (**NO**).

**Siguiente acción:** cerrar pilotos 08–10, CI de regresión total; después comenzar bloque 01 de Fase B sin esperar una nueva tanda IA6.
