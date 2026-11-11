# ACTUALIZACIÓN POSTERIOR IA3/W03 — 2026-11-11 · PREVALECE SOBRE EL REGISTRO HISTÓRICO

**Hecho nuevo verificado en GitHub:** IA6 ha integrado funcionalidad Repel y la ha certificado en su rama oficial `codex/calvo-ia6-integration-20261109`, SHA `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`.
- [CI oficial Repel + libros + Rope #43106031150](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43106031150): **SUCCESS**, log `CAMP006_W03_REPEL_L3 PASS checks=66`; `IA6_BOOK_BAG PASS checks=20`, `IA6_INTEGRATION PASS checks=65`, 229 nombres españoles y exclusión Dinamax.
- [CI oficial W03 capture + cross-worker #43106031155](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43106031155): **SUCCESS**, Repeat original 37, Repeat native 26 + 18, Net 79 + 19, Moon 41, SaveV2 40 + 8, menta 18, libros 20, repel histórico 66.
- **Diferencia importante:** el test histórico oficial tiene blob `f542f6aef303caa12812714415846bcf16bb2bcf` y selecciona zona real desde `zone_at_position`. El test W03 exclusivo ha recibido autorización IA6 para **otra corrección mínima equivalente de una línea** desde `registered_zone_ids()[0]` hacia `scene.TECHNICAL_ZONE_ID`, blob `91ec4cca45b0a398597dd352f10d4bcfec4b3353`. No son archivos idénticos y la CI oficial no certifica automáticamente esa nueva versión W03.
- Corrección W03 commit funcional `e7b4235788b200a946030a248b33cc4a20535359`; guard protege reconstrucción exacta del blob original y los 7 hashes de producción.
- CI W03 histórica estricta [#43095883086](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43095883086) y CI W03 scoped [#43095882953](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43095882953): a esta revisión ambas **QUEUED, sin jobs iniciados**. No afirmar PASS, FAIL ni fallo de código. Última CI W03 scoped verde antes del cambio #43084807955 sobre `1fc5d7fdba3a9b84a4c04fc88a24ea3c8d1bb579`.
- **No queda trabajo de integración pendiente de W03 sobre la rama oficial** sin orden nueva; tampoco abrir V6. El único remate de W03 V5 es auditar sus dos CI exactas cuando GitHub las ejecute. Integración de rutas W04 y CAMP003–006 completas no certificada por estas pruebas.

---

## Registro anterior (válido para el momento previo a la integración oficial y a la corrección del fixture)

# IA3/W03 — CONTINUOUS_V5 FINAL · READY_FOR_IA6_MERGE_REPEL_CANDIDATE
**Fecha:** 2026-11-11. **Ejecutor:** W03. **Integración oficial IA6:** NO.

## Resultado verificable
- **Fases A/B/C: 3/3 cerradas en la rama exclusiva W03** `codex/calvo-items-20261111-w03-repel-staging-v5`, derivada de V4 `5a82da2a9dd1a868c3f8af9d73551fe16571adea`.
- **`repel`: L3 staging**; 100 pasos de desplazamiento real.
- **`super_repel`: L3 staging**; 200 pasos reales.
- **`max_repel`: L3 staging**; 250 pasos reales.
- **Objetos añadidos al catálogo: 0.** Son 3 ítems preexistentes cuya funcionalidad de mochila y mundo se ha conectado. No equivalen a nueva disponibilidad en rama central.
- Un uso consume exactamente 1 unidad de mochila; uso activo duplicado, stock caducado o guard de campo lo impiden. Un commit de inventario forzado a fallar revierte al estado de efecto anterior. No hay autoguardado.
- Supresión de salvaje con nivel **inferior** al líder, nunca igual/superior. Solo confirma RNG comprometido tras encuentro repelido; no crea batalla ni reserva una semilla nativa. Efecto registrado mediante `OverworldPlayer.step_completed` una sola vez.
- SaveV2 de mundo lleva estado de Repel en guardado manual, admite legacy sin sección `repel`, rechaza datos corruptos sin mutar el mundo activo.

## Recepción real y CI de SHA exacto

**CI V5 final:** [GitHub Actions #43084807955](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43084807955), **completed / success**, sobre **`1fc5d7fdba3a9b84a4c04fc88a24ea3c8d1bb579`**; 18 pasos de job SUCCESS, 0 FAIL. No atribuir CI de commit documental posterior a ese SHA.

Recibos de logs de la propia ejecución:
- `W03_V5_SOURCE PASS checks=41 protected=7 old_test_unchanged=true actual_grass_fixture=true dynamax_veto=true`: siete blobs protegidos, prueba histórica idéntica y exclusión expresa de `dynamax_candy`.
- `W03_V3_SOURCE PASS checked=1082 moon=6 runtime_weight=0 ultra_fields=0`: fuentes previas; Heavy/Beast permanecen bloqueadas, sin inferir productores de mundo.
- `W03_V5_REPEL_GRASS PASS checks=65`: tres repeles, zona hierba genuina, mochila real, umbral de nivel, pasos, RNG, snapshot y carga manual.
- `W03_V5_REPEL_NEG PASS checks=33`: mochila real, ausencia de stock tras refresco, `PlayerInventory.remove` denegado con inyección solo de test, rollback intacto, idempotencia y ninguna batalla.
- `W03_REPEAT_V2_GODOT PASS checks=37 native_capture_l3=false`: **legacy sin waiver**.
- `W03_REPEAT_NATIVE_V4 PASS checks=26`; `W03_REPEAT_NATIVE_V4_NEG PASS checks=18`.
- `W03_NET_NATIVE_V5 PASS checks=79`; `W03_NET_NATIVE_V5_NEG PASS checks=19`.
- `W03_V3_MOON PASS native=2 checks=41`.
- `SAVEGAME V2 TEST RESULT: 40 PASS / 0 FAIL`; `SAVEGAME V2 ADVERSARIAL RESULT: 8 PASS / 0 FAIL`.
- `IA6_MINT_FIELD_SAVE PASS checks=18`; `IA6_INTEGRATION PASS checks=65` (menta efectiva y Cuerda Huida); `IA6_BOOK_BAG PASS checks=20` (panel W05 de **esta base V4**, no la staging W05 posterior).

## A — RED histórica y diff

- Se importó **sin modificar** `tests/gameplay/parallel_items_w03_repel_l3.gd` (blob `318ee45f60d9ee046bcb048019337524acfb4844`).
- Previo al trasplante, `_repel_effect` ausente: run #43072852369 cancelada después, con evidencia de error por ausencia del efecto.
- Después del trasplante, la prueba histórica dio un **FAIL REAL** en run [#43073388744](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43073388744), `CAMP006_W03_REPEL_L3 FAIL checks=49`: `registered_zone_ids()[0]` selecciona `technical_cave_floor` (orden lexical) pero la posición que consulta es `EncounterZone` de `technical_grass`. Los errores subsiguientes se encadenan porque entra una batalla en la zona no esperada. **No se ha ocultado ni renombrado este FAIL como PASS**.
- La nueva prueba **independiente** usa `scene.TECHNICAL_ZONE_ID`, conserva los escenarios funcionales y es GREEN. Se requiere decisión de IA6 sobre cómo reparar o deprecar el fixture histórico; véase `CONTINUOUS_V5/W03_REPEL_HISTORICAL_TEST_ZONE_TICKET.md`.

## B — Trasplante aislado y protegido

- `modules/overworld/field_repel_step_effect.gd`: mismo blob `7dbd62dd8238191e2101f25687d3e12d5d61a693` de la fuente histórica; no cambia.
- `scenes/visual/field_item_bag.gd`: solo `_refresh_choices`, `_apply`, nueva `_apply_repel` para los 3 IDs, sin exigir Pokémon objetivo. Se mantienen la transacción de Cuerda Huida, botones y enseñanza del libro.
- `scenes/visual/field_demo.gd`: conexión de pasos, bloqueo de encuentros en productor real, serialización, validación y restauración de `repel` en mundo.
- `scenes/visual/field_native_bridge.gd::on_step`: intercepción de `blocked_by_repel`, commit RNG sin iniciar combate.
- Ficheros de producción protegidos fuera de alcance, motor JS, catálogos y políticas intactos. **Diff con blobs y funciones exactos**: `CONTINUOUS_V5/W03_FUNCTION_DIFF_AND_W05_SEAMS.md`.

## C — Dependencias que IA6 debe resolver

1. La rama W05 posterior `codex/calvo-ia6-staging-20261111-w05-books` tiene mochila blob `12907d0dfdc040686dc3385c27bcef8ffda1e1d9`; W03 V5 tiene `a72be67c03b6548b348748d78d4b8efafd954fbc`. Se solapan `_ready`, `open_bag`, `_refresh_choices`, `_apply`; W05 trae nuevos cambios en `_open_machine_books` y callback, W03 trae `_apply_repel`. **No copiar ningún archivo completo**; merge selectivo de funciones y CI cruzada oficial.
2. El CI `ia6-w03-v5-repel-staging.yml` que ejecuta el fixture **histórico inalterado** sigue rojo por la selección errónea de zona; véase ticket. La CI scoped **verde** no lo silencia.
3. Las 7 rutas W04, las suites completas CAMP003–006 y la última staging W05 **no se certifican en esta entrega**: no se ejecutaron con esos árboles en la CI `43084807955`. Reservarlas a IA6 tras integrar.
4. `Heavy Ball`, `Beast Ball` y efectos condicionados a pesca, zona o sexo permanecen sin productores verificados; no se crean flags improvisados ni se amplía el alcance.
5. Quedan fuera `main`, V28, PR #118 y la rama integradora oficial.

**Siguiente acción autorizada:** IA6 compara ambos conjuntos de hunks, integra manualmente, decide el ticket del fixture, ejecuta CI central y después publica nuevas órdenes si las hubiera. **W03 queda READY_FOR_IA6_MERGE_REPEL_CANDIDATE y no abre V6 unilateralmente.**
