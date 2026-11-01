# W02 / LOTE_002 — pruebas reutilizables de consumo de bayas

**ESTADO: LISTA_PARA_REVISION / PENDIENTE_CI** (sin PASS funcional nuevo).
**Identidad exclusiva:** IA2/W02, rama `codex/calvo-items-20261101-w02`.
**Asignación oficial:** [LOTE_002_W02](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_002_W02.md), blob `6615339c816bb9159467c3c3e99477efb95e4792`.
**Recepción LOTE_001 aceptada por IA6:** `dd9d1616e405f5ac2d455185abbc7f5a39449233`; blob de informe preservado `8b49a29d9cbf98dac85ad3947e6b872bba8a6735`.
**Sincronización comprobada:** checkpoint oficial `38188cc208e67b19002437ac75160898ce332ec2`, merge no destructivo local `98a45388df091697c660a28cd30e958240bf6dad` con padres `dd9d1616...` y `38188cc...`. Comparación posterior: 0 commits detrás del checkpoint; informe LOTE_001 idéntico, sin conflictos. La base integrada heredada aún carece de CI combinada.
**Commit(s) de entrega:** consultar historial/HEAD de la rama W02 tras este archivo y `CONTINUIDAD.md`; el SHA del commit que contiene este informe no se incrusta autorreferencialmente.

## 1. Resultado real (no confundir preparar pruebas con ejecutarlas)

- **IDs:** `sitrus_berry` (Zidra), `lum_berry` (Ziuela), `colbur_berry` (Dillo).
- **Código de producción nuevo/cambiado por W02:** **0**. Solo tres archivos nuevos de tests/fixture y dos documentos propios (informe y cuaderno).
- **Matriz nueva de ejecución preparada:** 7 escenarios funcionales por 3 variantes `active/none/reserve` = **21 ejecuciones Godot propuestas**, NO ejecutadas.
- **Validador Python nuevo:** contratos estrictos (IDs, tipo/efecto, semilla y casos), evidencia raw con SHA-256, propietario, SaveV2, consumo, controles y 13 tests adversariales/sintéticos; **SIN_EJECUTAR** en este contexto. El test sintético valida **el validador**, no el videojuego.
- **Comprobación estática real de GitHub:** **12/12 PASS ESTÁTICOS** mediante lectura directa de blobs, comparando matriz, rutas exactas, uso de infraestructura V28, preservación del informe previo y diff de checkpoint; NO prueba GDScript ni ejecuta la lógica nativa.
- **Godot 4.7 / nativo @pkmn/sim:** **SIN_EJECUTAR** en esta conversación, porque el entorno local de herramientas carece del binario Godot y de un checkout ejecutable con `.godot/battle_reference/runtime/node_modules`; no se inició CI. `git ls-remote` desde contenedor no pudo resolver github.com. No se declaran PASS operativos ni de GPU.
- **V28:** las ejecuciones [Actions #41255004688](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41255004688) y los cuatro casos previos de Dillo son **PASS HISTÓRICO limitado al SHA `6383f558...`**, no ejecución de este nuevo test, ni certificación de las tres bayas.

## 2. Código y contrato de ensayo

| Archivo autorizado | Nuevo contenido | Blob SHA tras entrega de fuentes |
| --- | --- | --- |
| `tests/fixtures/parallel_items/w02_berries_v1.json` | Semilla fija `[23,19,29,43]`, formato `gen9calvounifiedv1`, 7 escenarios, 3 modos/propietarios, expectativa de consumo exacta. | `0d8d52767b768967437e1719b8cab001fac6a512` |
| `tests/gameplay/parallel_items_w02_berries_v1.gd` | Extiende SOLO infraestructura de test V28; `RivalControlado`, `Service.equip`, `Native.begin_wild/submit`, `_restore_probe`, salida real FLED, SaveV2, comparación de PS/estado/daño/consumo y stock después del cierre. | `12cab8469836d8b57b42ef467b0e3a4eaded191d` |
| `tests/tools/test_parallel_items_w02_berries_v1.py` | Valida matriz y recibos; exige casos completos, modo activo/sin objeto/reserva, cambio por tipo/umbral, retención/consumo, raw SHA-256, dueño, PS, inventario y ausencia de falsa certificación. Contiene 13 tests unitarios sintéticos. | `a6d346a74909902971b4db600c25a5cddd00a011` |

**Flujo de ejecución previsto:** selección activa (sin modificar) → `PlayerCollection` con dos Pokémon → `FieldItemService.equip` (dos unidades físicas al inicio) → `showdown_adventure_session` mediante rival controlado → `@pkmn/sim` fijado (la autoridad del disparador) → versión obsoleta rechazada/turno real → guardado de estado de combate con `_restore_probe` → salida real con `poke_doll` (FLED) y publicación → segundo cierre rechazado → recarga `SaveGameRepository` → inventario físico 1 o 2. Se preservan la campaña sin publicación prematura y el Pokémon de reserva. El runner no crea callbacks `onEat`, no cambia RNG ni define fórmulas de producción.

## 3. Casuística por ID, positivos y negativos

| ID | Escenarios nuevos / controles `active, none, reserve` | Aserción mínima; límite |
| --- | --- | --- |
| `sitrus_berry` | `sitrus_low_hp`, `sitrus_high_hp` | Al iniciar con 25% PS, objeto activo cura un cuarto de PS máximos y se consume; al estar a PS máximos - 1, no se activa. `none`/`reserve` no curan al activo. Tope al máximo en uso de campo ya está probado históricamente en V5 y **no se duplica**; falta probar durante combate un golpe que cruce el umbral. |
| `lum_berry` | `lum_poison`, `lum_healthy` | Ante veneno, sólo el titular activo lo cura y consume; sano conserva la baya. Controles sin objeto o en reserva mantienen el veneno del activo. La confusión y otros estados se probaron en campo V5, **no** se anuncian aquí como nuevos casos equipados. |
| `colbur_berry` | `colbur_super_dark`, `colbur_neutral_dark`, `colbur_wrong_type` | Mew Psíquico recibe Siniestro supereficaz y sólo el titular activo mitiga daño/consume; Snorlax recibe Siniestro **no** supereficaz, no reduce ni consume; ataque no Siniestro tampoco. `none`/`reserve` deben igualar daño con misma semilla. Es extensión de V2/V28, no recreación de la regla. |

**Cobertura transversal propuesta:** controles positivos/negativos, dueño activo/reserva/sin objeto, reversión de revisión obsoleta, ausencia de publicación prematura, restauración de snapshot, cierre terminal repetido, contabilización física de dos unidades, estado y PS en SaveV2. El runner produce evidencia sólo cuando Godot se ejecuta realmente; preparar el JSON no genera recibos.

## 4. Ejecución reproducible y estado actual

Desde la raíz del checkout **ya sincronizado**, con Python y Godot **4.7** y el runtime nativo del proyecto:

```bash
python tests/tools/test_parallel_items_w02_berries_v1.py --fixture-only
python tests/tools/test_parallel_items_w02_berries_v1.py --unittest
godot --headless --path . --script res://tests/gameplay/parallel_items_w02_berries_v1.gd
python tests/tools/test_parallel_items_w02_berries_v1.py --result .godot/parallel_items/w02_berries_v1/godot.json
```

Si la instalación usa `godot4` o `GODOT_BIN`, sustituir el ejecutable sin cambiar versión. El runner genera `.godot/parallel_items/w02_berries_v1/godot.json` y archivos raw por caso y modo; **no** deben commitearse como evidencia de PASS sin ejecutarse ni validarse. No ejecutar el último comando si no existe un `godot.json` real. Ninguno de los cuatro comandos fue ejecutado en esta sesión sobre el checkout completo.

| Comprobación | Resultado | Fuente |
| --- | --- | --- |
| GitHub merge/no divergencia tras checkpoint | **PASS REAL de estructura Git** | comparación `38188cc... → W02`, blob LOTE_001 inalterado |
| Validación estática de fixture/diff/nombres de rutas | **PASS ESTÁTICO 12/12** | lectura de los tres blobs indicados y comparación de ramas |
| Tests del validador Python (`--unittest`) | **SIN_EJECUTAR** | ningún resultado se atribuye al propio Python del proyecto |
| GDScript de 21 ejecuciones de combate | **SIN_EJECUTAR / PENDIENTE_CI** | no hay log de Godot, SHA ejecutado ni artefacto raw |
| Cierre visual/GPU y mecánicas exhaustivas | **NO REALIZADA** | requiere entorno Godot apropiado y revisión aparte |

**Verificadores antiguos reutilizables (no reejecutados):**
- `tools/item_audit/held_pilot.cjs:31,33`, blob `c8a59a18f546d772ff34e4f8640a4246a00a822b`: Zidra/Ziuela, dos semillas, cura y consumo inicial.
- `tools/item_audit/held_effect_sweep_v2.cjs:12,32–35`, blob `c9ba4d7bcddad6ae69f085f4b69983461ad05219`: Dillo contra golpe Siniestro y tipo distinto, control sin objeto.
- `tests/gameplay/item_field_recovery_v5.gd:40–168`, blob `94c9c78f00f95af3a4ff8d515a52012febe4d0c1`: campo en equipo/PC, umbral/tope, estado, mochila real, save/load y negativo. Historial V5: 1.049 headless / 1.051 GPU para 23 IDs, **NO** el test W02 de hoy.
- `tests/gameplay/item_case_replay_v28.gd`, blob `a4744e78c45cf80afcfc56b6023306768b2539d6`, más `tools/item_audit/replay_v28.py`: Dillo 4 casos limitados, replay de consola y FLED en V28 SHA previo; no toda la familia ni victoria/derrota.

## 5. Dependencias y recomendaciones para IA6

1. **SOLICITUD_IA6 — test/CI único:** integrar revisión de esta rama sólo en rama árbitra, tras constatar diff y permisos; ejecutar allí la prueba del validador Python, Godot 4.7 y el postvalidador sobre los raw originales, preferiblemente en un único workflow consolidado con las otras W. Citar SHA/Actions/artefactos/errores; NO reetiquetar este documento como PASS por publicar el script.
2. **Alcance que NO se cierra:** ataque que atraviesa el umbral de Zidra, confusión como trigger equipada de Ziuela, defensa Dillo ante sustituto/inmunidad y multigolpes; victoria/derrota y reentrada, dobles, UI/GPU/manual. Cualquier caso fallido requiere diagnóstico, **no** parche de producción por W02.
3. **Propiedad compartida:** `modules/battle/backends/showdown/native_engine.cjs`, `modules/inventory/field_item_service.gd`, `modules/gameplay/showdown_adventure_session.gd`, `tests/gameplay/item_automation_v28.gd` y `tools/item_audit/replay_v28.py` son **solo lectura**. El nuevo runner hereda el arnés existente, sin modificarlo. Si aparece un defecto de producción, pedir dueño/contrato explícitos para LOTE_003.
4. **Base fusionada sin ejecución:** `38188cc...` combina ramas documentales y V28, pero no está certificada. Un PASS del validador Python aislado no arregla la falta de Godot. La revisión de IA6 debe contrastar los tres modos por ID antes de marcar integración.

## 6. Autocontrol y entrega

- **Archivos tocados por W02 en LOTE_002:** exactamente `tests/gameplay/parallel_items_w02_berries_v1.gd`, `tests/tools/test_parallel_items_w02_berries_v1.py`, `tests/fixtures/parallel_items/w02_berries_v1.json`, este `reports/W02/LOTE_002.md` y `reports/W02/CONTINUIDAD.md`. El LOTE_001 sólo se heredó sin modificar.
- **Fuentes de producción, datos canónicos, arte, config, política, CI, tests V27/V28 preexistentes:** no modificados por W02.
- **Ramas `main`, `codex/items-v28-from-main`, árbitra y W01/W03/W04/W05:** no escritas.
- **Resultado final:** `LISTA_PARA_REVISION`, con test preparado y `PENDIENTE_CI`. No empezar LOTE_003 sin encargo publicado por IA6.
