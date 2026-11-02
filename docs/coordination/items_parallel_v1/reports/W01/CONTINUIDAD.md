> **INSTRUCCIÓN VIGENTE IA6 — CI AUTOMÁTICA V3 (2026-11-02):** el estado histórico `PREPARADO_PENDIENTE_CI` o `STOP HASTA IA6` que aparece más abajo **ya no exige detenerse solo por esperar pruebas**. Lee en rama `codex/calvo-items-20261101-arbitro` [CI_AUTOPILOT_V3.md](../../CI_AUTOPILOT_V3.md) y `CAMPAIGN_GATE_002.md`: se ha instalado el workflow `.github/workflows/parallel-camp002-worker-autoci.yml` **en esta misma rama**; la primera ejecución propia [#41539775567](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539775567) terminó `completed/success`. **Siguiente `p` ejecuta exclusivamente ITER_03 de CAMP_002** tras comprobar que no exista un FAIL más reciente. Cambios de tests disparan CI sin intervención de IA6; commits solo de informes NO la disparan. Si la nueva CI está `queued/in_progress`, puedes preparar hasta un bloque posterior ya autorizado sin declarar PASS ni borrar tests previos; un FAIL real exige reparar tu prueba en tus rutas exclusivas o STOP ante defecto funcional. **En ITER_03, publicar y STOP sin iniciar ITER_04/CAMP_003.** IA6 ya sincronizó el runner corregido del conflicto OUT; no repetir parche. No tocar `main`, V28, otras ramas ni producción.

# W01 — CUADERNO DE CONTINUIDAD


## ACTUALIZACIÓN VIGENTE — CAMPAÑA_002 ITER_02 (2026-11-02)

**IA1/W01; rama exclusiva `codex/calvo-items-20261102-w01-camp002`**. Autoridad de IA6: `CAMPAIGN_GATE_002.md` (ACTIVADA), `CAMPAIGN_002_ITER01_CI_GATE.md` blob `12e9c3021e80f9e03e0f9b0e900853b9a7e6a513`, y `campaigns/CAMP_002_W01.md` blob `6ef97f3c0569c96138cb8c322069384e124e5c79`. Solo IDs `ability_shield`, `absorb_bulb`, `adrenaline_orb`. **02/03 microbloques entregados. No ejecutar tercero sin nuevo `p`.**

- **ITER_01 comprobada:** IA6 ejecutó validador de contratos Python (7 escenarios, 10 pares/30 variantes, seis negativos rechazados) sobre staging SHA `967002fcbf26a1159d3a14a020e8921b34cfab8f`; CI [#41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) `completed/success`. Ese resultado **NO incluía** runner Godot W01.
- **ITER_02 publicada:** runner `tests/gameplay/parallel_items_w01_campaign_002.gd` commit `b34e954a7e9a601432d23c470b50607920afec5e`, blob `68b73dd62b0250b5bdbdebdf44c97cd4649a2487`; validador `tests/tools/test_parallel_items_w01_campaign_002.py` extendido con `--native`, commit `b22ff7136b368171c003ef6d0571de964b8e529c`, blob `a6492e1f9f8fa6928af5601a0633f6e830b0238e`. Fixture de ITER_01 sin modificar blob `74c91b2cfb69d7525ee4d42cc1e57f442c4a808d`.
- **Cobertura de efectos prevista:** Escudo Habilidad `gastro_acid` frente a `synchronize` (protección en slot activo, control sin escudo o en reserva); Tubérculo `water_gun` (+1 `spa` y consumo) frente a golpe Normal/sin golpe; Nerviosfera `intimidate` de Gyarados (+1 `spe` y consumo al entrar) frente a ausencia de Intimidate. Por cada escenario, tres modos `active/none/reserve`; dos semillas 19 y 23 en cada disparador positivo.
- **Camino técnico, solo tests:** catálogo seleccionado → `FieldItemService.equip` mediante `_fixture` V28 → `Native.begin_wild/submit` sobre `@pkmn/sim@0.10.11` → snapshots y `_checkpoint.roster` nativo (volátiles, stats, consumo) → recibos JSON con SHA-256 → validador Python `--native` obligatorio para declarar PASS. **No se han programado hooks** y no se ha modificado simulador, guardado ni UI.
- **Evidencia y límites:** comprobación estructural desde GitHub de **20/20 invariantes PASS** (scripts/fixture, callbacks observados, escenario positivo/negativo, seed, hashes); **nueva ejecución de Python y Godot SIN_EJECUTAR**, **GPU/visual SIN_EJECUTAR**, validación SaveV2 tras turno **PENDIENTE ITER_03**. Estado de ITER_02 `PREPARADO_PENDIENTE_CI`, no `FUNCIONAL_PASS`. IA6 gestiona una CI integrada por paquete.
- **Informes actualizados:** `reports/W01/CAMP_002_ITER_01.md` histórico, `CAMP_002_ITER_02.md` nuevo y `CAMP_002_PROGRESO.csv` con 02/03. Los reportes de CAMPAÑA_001 permanecen en ramas antiguas y **NO se copiaron ni modificaron**.
- **Siguiente operación autorizable:** tras próximo `p`, leer gate/encargo/CSV y **si no existe FAIL**, ITER_03 exclusivamente: revisar persistencia/restauración SaveV2, matriz causal por ID, recibos SHA, informe final y STOP. Si la CI detecta error de parseo, proyección o efecto, parar y pasar solicitud a IA6; no suprimir aserciones ni tocar producción.
- **PROHIBIDO:** rama `codex/calvo-items-20261101-w01`, W04 congelada, cualquier otra W, `main`, V28, `modules/`, `data/`, `.github/`, guardados, reglas Mega y política del juego.

---


## ESTADO VIGENTE — IA1/W01 — CAMPAÑA_002 (2026-11-02)

**ÚLTIMA ORDEN OFICIAL:** IA6 `CAMPAIGN_GATE_002.md`, blob `ebc787803599e2b13cbd24c169b69112d18f7a42`; `CAMPAIGN_002_BRANCH_MANIFEST.md`, blob `bb9471862d3116b982f90e1867d512e278f801e0`; encargo `campaigns/CAMP_002_W01.md`, blob `6ef97f3c0569c96138cb8c322069384e124e5c79`. **Identidad W01**, familia equipables, exclusivamente IDs `ability_shield`, `absorb_bulb`, `adrenaline_orb`.

**NUEVA rama exclusiva:** `codex/calvo-items-20261102-w01-camp002`; nacida exactamente desde `67959eb8f19abfd2ae391872747a14f603fcab01`. **PROHIBIDO** fusionar o reescribir ramas de CAMPAÑA_001; el material antiguo debajo es historia previa, no autoridad vigente. IA4/W04 congelada.

**Progreso de campaña nueva:** ITER_01 de 03 **PREPARADO_PENDIENTE_CI**, ITER_02/ITER_03 **NO INICIADAS**. Informe `CAMP_002_ITER_01.md`; CSV `CAMP_002_PROGRESO.csv`. Dos archivos de pruebas nuevos y solo documentación propia; no GDScript aún.
- **Referencias existentes:** `tools/item_audit/held_effect_sweep_v3.cjs` (Escudo Habilidad: `gastro_acid`/Synchronize y Nerviosfera: Intimidate/no Intimidate); `held_effect_sweep_v2.cjs` (Tubérculo: Agua y +1 SpA). Los hooks de Dex indexados en `docs/current/ITEM_INVENTORY.csv` son `onSetAbility`, `onDamagingHit` y `onAfterBoost`. Los tres IDs `SELECCIONADO`, no implica efecto probado nuevamente.
- **Archivos creados en ITER_01:** `tests/fixtures/parallel_items/w01_campaign_002.json` (7 escenarios, 10 semillas combinadas, 30 modalidades de objeto, positivas/negativas, efecto/consumo esperado y reserva) y `tests/tools/test_parallel_items_w01_campaign_002.py` (fija y verifica fuentes Git, hooks, selección, escenarios y seis mutaciones negativas).
- **Commits de pruebas publicados:** `16cd0d253c17d454e578cced864948e30b69e023` y `c2451f93a839c9e6e9b6058e3765da0a68f400b3`. Informe `9075f82a5167e0793930cf60040fc62245e7f0ea`. CSV `788dfc92304854393972ffd5162d647d6a7764bf`.
- **Auditoría de contenido REALIZADA:** 16/16 comprobaciones estáticas mediante comparación de blobs GitHub y estructura/causas de la matriz **PASS**. **Python nuevo SIN_EJECUTAR**, **Godot nuevo SIN_EJECUTAR**, **GPU/UI SIN_EJECUTAR**. Referencia CI base #41364601482/#41364601486 preexiste a la campaña; no certificar con ella.
- **Cómo funciona el flujo futuro (no implementado en ITER_01):** selección canónica → `FieldItemService` equipa portador (existente) → `Native` entrega a simulador `@pkmn/sim@0.10.11` → se observa propiedad activa, sin ítem y reserva → `SaveV2` restaura estado; runner de ITER_02 hará la prueba real. No tocar la lógica nativa ni replicar hooks.
- **Siguiente acto bajo una nueva `p`:** consultar gate/manifest/encargo y CSV; ITER_02 exclusivamente, crear `tests/gameplay/parallel_items_w01_campaign_002.gd` y ampliar pruebas con observación causal sobre tres modos y segunda semilla, publicar commits/cuaderno. Si hay FAIL, `BLOQUEADO` y consulta IA6, no forzar PASS. ITER_03 futuro: SaveV2/matriz/final/STOP.
- **Rutas fuera de permiso:** `main`, V28, PR #118, scripts `modules/`, `data/`, `.github/`, ramas antiguas/W04/otras W, arte, UI, partidas, selección, política dos Mega. No comenzar ITER_04.

---


## Identidad y autoridad

- **IA1/W01**, rama exclusiva `codex/calvo-items-20261101-w01`.
- Familia: `HELD_COMBAT_CANDIDATE`, objetos `assault_vest`, `loaded_dice`, `focus_sash`.
- Última orden oficial: `docs/coordination/items_parallel_v1/assignments/LOTE_002_W01.md` en rama árbitra, **blob de asignación `660203ce96aeff2f6bb42b88962b7b46f5e2eca4`**.
- Estado **LISTA_PARA_REVISION (tests escritos, Godot PENDIENTE_CI)**; IA6 aceptó únicamente LOTE_001 como auditoría documental. No autodeclarar LOTE_002 integrado.
- Base integrada IA6: `38188cc208e67b19002437ac75160898ce332ec2`; merge seguro propio `e40b82303aa5c12b2ec1faaa8bcea2554e9319a6` con los dos padres. Antiguo W01 preservado: `aa224efeb261a05a63e5d3cae928748ec195aeb1`; informe LOTE_001 blob `df56277c045c05e28499cfea71e99ddaaf18ce48`.
- Commit de tests nuevos: `5f306faa1a375bf4094d493c40e20341a006460c` (tres archivos autorizados). El commit documental del cierre será posterior; consultar HEAD actual.

## Mapa técnico — qué existe y cómo funciona

`docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (selección de contenido) → 
`modules/inventory/field_item_service.gd` (`holdable/equip/unequip`, propietario equipo/PC, consumo físico) → 
`modules/gameplay/showdown_adventure_session.gd` / backend `modules/battle/backends/showdown/showdown_backend.gd` (sesión) → 
`native_engine.cjs` / **@pkmn/sim 0.10.11** (hooks de efecto nativos) → 
`CreatureInstance` / `SaveGameRepository` (snapshot/propietario) → UI/escena mapa (fuera del lote).

**No duplicar** lógica del motor en GDScript. `field_held_items.cjs` registra metadatos de otros ítems, no contiene los tres efectos; los hooks nativos conocidos son:
- Chaleco: `assaultvest`, `onDisableMove|onModifySpD`.
- Dado: `loadeddice`, `onModifyMove`.
- Banda: `focussash`, `onDamage`.

Los inventarios `ITEM_INVENTORY.csv` y matriz `ITEM_FIELD_V8.csv.txt` certifican presencia/transferencia y ciertos escenarios antiguos, no funcionamiento exhaustivo. V28 añade harness común, pero su lista de cierre ampliado deja fuera estos tres IDs. V28 y el catálogo convivieron inicialmente en ramas divergentes, ahora comparten checkpoint Git; CI conjunta **sin verificar**.

### Adaptadores y pruebas reutilizables

- V27: `tools/item_audit/held_pilot.cjs`, `held_effect_sweep_v2.cjs`, `tests/gameplay/item_held_pilot_test_runner.gd`, `item_effect_projection_v2.gd`; PASS históricos acotados, **no repetirlos sin motivo**.
- V28: `tests/gameplay/item_automation_v28.gd`, `_fixture`, `_restore_probe`, `_write_evidence`, `FieldItemService`, `SaveGameRepository`, `Native`; `tools/item_audit/automation_v28.py` conserva contratos cerrados ajenos y no se ha editado.
- W01 nuevos: `tests/fixtures/parallel_items/w01_held_v1.json` (9 casos / 16 semillas combinadas / 3 variantes por ejecución), `tests/gameplay/parallel_items_w01_held_v1.gd` (runner que hereda los helpers), `tests/tools/test_parallel_items_w01_held_v1.py` (contratos/evidencia SHA). **No** nuevos handlers de objeto.

## Estado por ID

| ID | Ya existía (histórico) | Test W01 añadido (no ejecutado en Godot) | Pendiente |
|---|---|---|---|
| `assault_vest` | Bloqueo de estado/turno rechazado (V1); callback nativo de Defensa Especial | bloqueo/ataque permitido, reducción de daño especial comparativa, daño físico control, reserva, restore | CI + asentamiento en campaña, supresión/Truco y efectos complejos |
| `loaded_dice` | 4–5 golpes Semilladora (V2) | seis semillas, control sin objeto/reserva, dos golpes fijos, golpe simple, restore y retención | CI + distribución estadística, otros ataques/habilidades |
| `focus_sash` | 1 PS y gasto al evitar KO (V1) | PS máximos/reducidos, golpe no letal, guardado de consumo y unidades activas/reserva | CI + cierre real del combate y gasto único persistido en campaña |

## Historial y evidencia

| Lote | Entrega | Evidencia actual | Autoridad IA6 |
|---|---|---|---|
| 001 | Informe `reports/W01/LOTE_001.md`, commit `aa224efe...`; solo lectura del código | PASS antiguos identificados, sin runtime nuevo | ACEPTADO **documental**, no funcional |
| 002 | Pruebas y fixture nuevos en `5f306faa...`; `reports/W01/LOTE_002.md` y este cuaderno | `python -m py_compile` PASS; `python tests/tools/test_parallel_items_w01_held_v1.py --contracts` PASS 9/16; 4 manipulaciones negativas rechazadas; comando sin reporte termina con error por ausencia de evidencia; **Godot SIN_EJECUTAR** | PENDIENTE_REVISION |

**Comandos futuros reproducibles** desde checkout combinado:

```bash
python -B tests/tools/test_parallel_items_w01_held_v1.py --contracts
godot --headless --path . --import
godot --headless --path . --script res://tests/gameplay/parallel_items_w01_held_v1.gd
python -B tests/tools/test_parallel_items_w01_held_v1.py
```

Se necesita Godot 4.7, `@pkmn/sim@0.10.11` fijado y `POKEMON_CALVO_NODE` correctamente configurado. Reutilizar staging/restauración del workflow V28, sin descargar/alterar datasets originales. La salida de Godot debe producir `.godot/parallel_items/w01_held_v1/report.json` y evidencias; Python sin `--contracts` debe revalidar los hashes. Ningún RUN de Godot nuevo disponible; prueba visual/GPU **NO REALIZADA**.

## Riesgos, dependencias y siguiente paso

1. IA6 debe validar la base fusionada mediante **una CI consolidada** y registrar commit, run, log y posibles fallos de parser/GDScript (no ejecutado aquí).
2. Si un test falla por fixture o regla del motor, conservar su salida y diagnosticar: **no** alterar callback, RNG, selección, ni cambiar el criterio para forzar PASS. Solicitar propietario de motor a IA6 si fuera necesario.
3. El harness W01 hereda de V28. Si se modifica V28/una API compartida, revisar compatibilidad antes de integrar.
4. Falta confirmar liquidación de combate y guardado de campaña después de consumo de Banda. El test actual verifica snapshots/restauración y ausencia de publicación prematura, no el ciclo completo de mapa.
5. La prueba de seis semillas de Dado no certifica porcentaje exacto de distribución; faltan casos de habilidades, movimientos especiales y dobles.
6. El próximo trabajo es **revisar informe 002 + diff y ejecutar CI**; solo después IA6 puede autorizar LOTE_003.

**NO HACER EN OTRO CHAT:** no tocar `main`, V28, árbitra, otras W, `modules/`, `scenes/`, `data/`, `assets/`, `config/`, docs actuales, políticas ni guardados sin nuevo encargo. No reprogramar efectos nativos que ya existen; no asumir LOTE_003 por un simple «sigue».

**Último siguiente paso reproducible:** IA6 revisa `LOTE_002.md`, el fixture y el validador del commit `5f306faa...`, y ejecuta una única CI para obtener el primer PASS/FAIL funcional nuevo. Hasta entonces, estado **LISTA_PARA_REVISION / PENDIENTE_CI**.
