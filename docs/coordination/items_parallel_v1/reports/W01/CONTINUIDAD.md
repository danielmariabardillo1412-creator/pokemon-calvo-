# W01 — CUADERNO DE CONTINUIDAD

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


---

## ACTUALIZACIÓN VIGENTE — CAMPAÑA_001 / ITER_01 (2026-11-01)

- **Orden superior actual:** `campaigns/CAMP_001_W01.md` en árbitra, blob `4faaae234c3021944d7f4724789c3b2c5d0652fd`. Puerta global `CAMPAIGN_GATE_001.md`, blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`, ACTIVADA. La campaña asigna **solo** `black_sludge`, `shell_bell`, `big_root` (microbloque 01), `eviolite`, `expert_belt`, `safety_goggles` (02) y consolidación (03).
- **Base:** rama W01 avanzó por fast-forward normal al HEAD árbitra `1b52fdd0b7b89e468811a17ad83a917ec7107735`; blobs originales de `LOTE_001.md` (`df56277c...`) y `LOTE_002.md` (`9a32f8e...`) comprobados idénticos. No editar la rama árbitra.
- **CI de referencia YA EJECUTADA**: Actions [#41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), commit `ac34fabbe1a27e69614f0239abee21c29d6fe65e`, PASS de **LOTE_002 W01** 1.332 checks / 16 pares / 48 variantes. **No prueba los casos nuevos de la campaña** y sustituye el estado antiguo PENDIENTE_CI de LOTE_002.
- **Microbloque 01 publicado, estado PREPARADO_PENDIENTE_CI**: `reports/W01/CAMP_001_ITER_01.md` y `CAMP_001_PROGRESO.csv`. Fixture `tests/fixtures/parallel_items/w01_campaign_001.json` (8 casos, 12 pares, 36 variantes); runner `tests/gameplay/parallel_items_w01_campaign_001.gd`; validador `tests/tools/test_parallel_items_w01_campaign_001.py`. Commits de tests `19db170d5aadf29d0b158dc5c3bbbd04c19b1b21`, `320e985db63d1afa86ffadbcccfe30441eb775f4`, `cb81acaabf6b7d5f1d347ecad9bc6f825ee69919`.
- **Flujo verificado estáticamente:** selección de inventario (`docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`) → `FieldItemService.equip` mediante helper `_fixture` V28 → `Native.begin_wild/submit`, nativo `@pkmn/sim@0.10.11`, hooks `blacksludge/onResidual`, `shellbell/onAfterMoveSecondarySelf`, `bigroot/onTryHeal` → `SaveGameData/SaveGameRepository` mediante `_restore_probe` → snapshots y prueba de propietario/reserva; **UI y cierre real de campaña fuera del test**.
- **Evidencia de pruebas nuevas:** validación estática propia de 12 invariantes de estructura/IDs/rutas/hashes **PASS**; ejecución de Python, Godot y GPU **SIN_EJECUTAR**. Los scripts no equivalen a certificar efectos hasta obtener reporte `.godot/parallel_items/w01_campaign_001/report.json` con los hashes correspondientes.
- **Riesgos:** posibles fallos de parser/fixtures en Godot aún no comprobados; sin regresión de cambios de portador, supresión y liquidación en mapa; comparación causal con semillas fijadas no equivale a exhaustividad. **Si aparece FAIL, parar e informar a IA6; no maquillar fixtures ni modificar producción.**
- **Archivos escritos solo en este bloque:** los tres `w01_campaign_001` (runner, validador, fixture), `reports/W01/CAMP_001_ITER_01.md`, `reports/W01/CAMP_001_PROGRESO.csv`, este cuaderno. Los informes LOTE_001/002 y los tests W01 originales **no fueron modificados**.
- **Siguiente microbloque, NO EJECUTADO:** 02, `eviolite` (evolución pendiente/final), `expert_belt` (ataque eficaz/control), `safety_goggles` (polvo/clima/control). Antes de una nueva `p`, releer órdenes árbitra, puerta y este cuaderno. Tras 03, emitir `CAMP_001_FINAL.md` y detenerse.

**Rutas fuera de permiso:** toda producción de `modules/`, `scenes/`, `data/`, `config/`, `.github/`, `main`, V28 original, rama árbitra, otras W y docs comunes. **No reclamar integración o PASS nuevo sin CI SHA.**

---

## ACTUALIZACIÓN MÁS RECIENTE — CAMPAÑA_001 / ITER_02 (2026-11-01)

**Autoridad:** IA1/W01, asignación `campaigns/CAMP_001_W01.md` blob `4faaae234c3021944d7f4724789c3b2c5d0652fd`, gate `3ef0b39f7eb74f3ebcb688f279c254daec981f8e` ACTIVADA. **Estado: PREPARADO_PENDIENTE_CI, 02/03 microbloques preparados.**

**Sincronización:** último HEAD árbitra leído `a710d8abe2e94f11974488c4563b9eb80ede5bbc`; merge de dos padres sin force `024c4bafe6ca18873030d89b270f3a04d3a1d5b4`. Se mantienen el contenido de LOTE_001/002 y el informe ITER_01. No sobreescribirlos.

**Nuevos IDs y mecanismos sin implementación duplicada:**
- `eviolite` → native `onModifyDef|onModifySpD`; Pidgeotto vs Pidgeot, daño físico/especial.
- `expert_belt` → native `onModifyDamage`; daño supereficaz Water Gun→Arcanine vs neutral→Mew.
- `safety_goggles` → native `onImmunity|onTryHit`; Espora→Mew, arena y turno neutro. Snapshot observa `status_state.persistent_id`, PS y tenencia.
- Los tres están en catálogo `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, clasificación `HELD_COMBAT_CANDIDATE`, `SELECCIONADO`; esto **no certifica** efectos.
- Reutilización técnica: `FieldItemService`/helper `_fixture` → `Native` → `_restore_probe` y SaveV2 → archivo JSON y SHA-256 → validador Python; sin tocar `modules/`, workflows ni producción.

**Archivos cambiados en microbloque 02:** `tests/fixtures/parallel_items/w01_campaign_001.json`, `tests/gameplay/parallel_items_w01_campaign_001.gd`, `tests/tools/test_parallel_items_w01_campaign_001.py`, `reports/W01/CAMP_001_ITER_02.md`, `reports/W01/CAMP_001_PROGRESO.csv`, y este `CONTINUIDAD.md`. Commits test `79a26778`, `60673b10`, `c16f7e93`. 9 escenarios nuevos, 12 ejecuciones adicionales, 36 variantes; total acumulado **17/24/72**. El fixture conserva etapa 01, pero su SHA cambió y **necesita volver a comprobarse en el mismo reporte integral**.

**Pruebas:** validación estructural (13 condiciones a partir de los blobs de GitHub) **PASS estático**. Python ejecutado nuevo **SIN_EJECUTAR**; Godot 4.7 de CAMPAÑA_001 **SIN_EJECUTAR**; visual/GPU **NO REALIZADA**. El PASS de [CI #41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320) cubre solamente LOTE_002 histórico. No declarar nuevos objetos funcionales hasta CI del commit integrado de esta campaña.

**Riesgos y dependencias:** parser GDScript, disponibilidad de `spore/sandstorm/psychic` bajo perfil personalizado, cuantía exacta del daño en semillas fijadas, efecto nativo incompleto y liquidación de campaña aún no contrastados. En caso de FAIL probado, detener y notificar a IA6 con el log; no modificar la mecánica de combate ni relajar las pruebas para obtener PASS.

**Próximo paso reproducible solo mediante nueva `p`:** releer gate/STATUS/campaña, verificar HEAD y diff, ejecutar **microbloque 03 exclusivamente**: auditar cobertura para los seis IDs, integridad de los pares caso-semilla y hashes, documentación de límites y emitir `CAMP_001_FINAL.md`. Después **CAMPAÑA_001_FINALIZADA** y detener hasta nueva asignación. Ningún otro bloque ha sido empezado.

**NO TOCAR:** `main`, PR #118, V28 original, rama árbitra y otras trabajadoras; `modules/`, `scenes/`, `data/`, `config/`, `.github/`, guardados ni políticas. Sin permiso para cambios de producción.
