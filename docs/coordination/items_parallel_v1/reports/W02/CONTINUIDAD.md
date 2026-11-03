# W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / 03 DE 10

**Estado:** bloque **03/10 ENTREGADO**, `EN_CI_AUTOMATICA` para SHA que incorpora tres filas de progreso. **Solo la siguiente `p` ejecutará bloque 04** si el último run no es FAILURE. Rama exclusiva `codex/calvo-items-20261103-w02-camp003`.

**Autoridad:** `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. IA6 mantiene íntegra W02 bajo ampliación de W04; no modifica la cola de 40.

**Bloques precedentes verificados:** 01/02 en [Actions #41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832), SHA `926ad81488c1e83d777177bfa5a2eff35b028eca`, **Python 122 checks PASS, Godot 1406 checks PASS, 2 bloques**. El filtro Apicot solo `p1a` sigue conservado (error anterior ya reparado; no volver a modificar por cuenta propia).

**BLOQUE 03 nuevos:** `colbur_berry` Siniestro contra Mew/ataque no coincidente; `custap_berry` orden de acción Snorlax lento vs Gengar rápido al 1/5 de PS/PS máximos; `enigma_berry` curación tras `thunder_shock` eléctrico supereficaz a Gyarados vs `tackle` no disparador; `ganlon_berry` subida de Defensa al cruzar 1/4 PS vs PS altos. Hay **ocho escenarios nuevos, 24 variantes**.

**Acumulado:** 3 bloques, 12 bayas diferentes, 25 escenarios, 75 variantes `active,none,reserve`; pruebas de consumo único, actor correcto en el log, no gasto de reserva, cierre FLED, SaveV2 y recibos SHA256. No pruebas de campo, GUI, GPU ni producción.

**Contratos de referencia:** `tools/item_audit/held_effect_sweep_v2.cjs`: Colbur/Ganlon; `held_effect_sweep_v3.cjs`: Custap/Enigma. Son pruebas de mecanismo existente; no se implementaron nuevas mecánicas.

**Archivos W02 escritos:** `tests/fixtures/parallel_items/w02_campaign_003.json` commit `cd837d26ca2283296a11dbd41af8672208694de0`; `tests/gameplay/parallel_items_w02_campaign_003.gd` commit `94d107df596ced40283845430e8cb36e9e7a686f`; `tests/tools/test_parallel_items_w02_campaign_003.py` commit `8e5b6b111c17259d0f73c08d8bb307a64155afa7`; `CAMP_003_PROGRESO.csv` tercera fila commit `44482761ab0217323335d9a1bc63f060cbcad513`; `CAMP_003_ITER_03.md` commit `88f5654fcaccff06ac8a3e297825e129864377f9`. Ningún otro archivo autorizado para escribir.

**CI automática:** comprobar run más reciente de la rama, en SHA de pruebas/progreso `44482761ab0217323335d9a1bc63f060cbcad513`. Se exige `CAMP003_W02_PY PASS blocks=3 checks=M` y `CAMP003_W02_GODOT PASS blocks=3 checks=M`. Si FAILED, inspeccionar log, reparar solo prueba propia sin rebajar aserciones; si defecto compartido, STOP y ticket IA6. Cancelled de runs previos por nuevo push no equivale a FAIL.

**Siguiente `p`:** bloque 04 de cola exacta `haban_berry;iapapa_berry;jaboca_berry;kasib_berry`; consultar progreso y último run. No iniciar bloque 05 ni 11, ni tocar `main`, V28, producción/catálogo/IA6/ramas ajenas ni W04.

---

## HISTÓRICO — 02/10 Y ANTERIORES

> **CI POSTERIOR VERIFICADA — 2026-11-03:** [Actions #41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832) `completed/success` sobre SHA de tests/progreso `926ad81488c1e83d777177bfa5a2eff35b028eca`. Recibos auténticos de logs: `CAMP003_W02_PY PASS blocks=2 checks=122` y `CAMP003_W02_GODOT PASS blocks=2 checks=1406`. El estado anterior `EN_CI_AUTOMATICA` de este documento/CSV describe la entrega inicial y está superado por esta ejecución. Para evitar otra CI redundante, el CSV de progreso no se reescribe: la evidencia de PASS queda aquí y en el cuaderno. **Próxima `p`: bloque 03/10 solamente.**

# IA2/W02 — ESTADO ACTUAL DE CAMPAÑA_003 (02/10)

**BLOQUES PUBLICADOS:** 01 y 02 de 10. La siguiente `p` autoriza SOLO bloque 03 si semáforo CI permite continuar. Rama `codex/calvo-items-20261103-w02-camp003`, exclusivamente pruebas/fixture/progreso/informes W02. No inventar bloque 11 ni modificar CI compartida.

**Reparación anterior verificada:** CI #41553745691 FALLÓ en Apicot por atribución a `p2a` de boost SpD de Amnesia del rival; filtrado en prueba `|-boost|p1a:` commit `2449baf285ef9eaffdb4fa030f78dfe3ee8c551c`; [CI #41554998986](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41554998986) `completed/success`. Ningún cambio en producción.

**Bloque 02:** `charti_berry`, `chilan_berry`, `chople_berry`, `coba_berry`; histórico `held_effect_sweep_v2.cjs` ya verifica resistencia ante Roca/Normal/Lucha/Volador. Positivos `smack_down/tackle/brick_break/aerial_ace`, controles negativos `tackle/surf/tackle/tackle`, portadores `charizard/mew/snorlax/venusaur`. Chilan protege de Normal sin supereficacia.

**Suite acumulativa:** 9 casos del bloque 01 (4 IDs) + 8 casos del bloque 02 (4 IDs) = **17 escenarios, 51 variantes nativas previstas** (`active/none/reserve`). Integridad SHA256 de recibos, recuperación y SaveV2; solo equipadas. Campo/UI/GPU no probados. Python obliga cumplimiento exacto de 8 casos y 6 controles adversariales nuevos; evita falsos PASS de bloque futuro.

**Pruebas publicadas:** fixture commit `919f36e444a572b973852b3ef4f114c83d6f6707`; runner `ed5c2f2dd1ca8620f6fcb0d066942dd721734fcd`; validador Python `feddccce4d23571d989784e89919305dceede825`; CSV `926ad81488c1e83d777177bfa5a2eff35b028eca`; informe `d5d76f0940653b60af1018f845d986f663576038`.

**CI del bloque 02:** [#41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832), inicialmente pending, SHA de pruebas publicado con bloque 02 en CSV `926ad81488c1e83d777177bfa5a2eff35b028eca`. Exige `CAMP003_W02_PY PASS blocks=2 checks=M` y `CAMP003_W02_GODOT PASS blocks=2 checks=M`, sin inventar PASS antes de resultado. Los runs previos del mismo bloque se cancelan por concurrencia.

**Siguiente `p`:** bloque **03** de cola IA6: `colbur_berry;custap_berry;enigma_berry;ganlon_berry`. Consultar run más reciente, detener si FAIL real, reparar test propio si demuestra bug del arnés. Nada de producción, `main`, V28, PR #118, otras ramas o IA4.

---

# ARCHIVO HISTÓRICO — ESTADO AL FINAL DEL BLOQUE 01

# IA2/W02 — CONTINUIDAD VIGENTE / CAMPAÑA_003

**ESTADO HISTÓRICO:** BLOQUE **01/10 ENTREGADO**, `EN_CI_AUTOMATICA`, pendiente verificación de GitHub Actions #41553745691 (primer SHA con CSV 1/10). Los PASS de bootstrap 00/10 no acreditan funcionamiento.

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp003`. Arranque de IA6 `41c1efeba0346349490f863131179ed7a8fc274c`. No fusionar CAMP001/CAMP002. La rama contiene el workflow/validador global de IA6 que **no puede editar W02**.

**Autoridad:** `CAMPAIGN_GATE_003.md` blob `390f7ce6897462e1ae8e3cc7e3cd5f799b6c2213`; `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`; cola `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`. Diez bloques fijos: `p` ejecuta SOLO el siguiente. W04 no participa.

**BLOQUE 01 IDs:** `aguav_berry`, `apicot_berry`, `aspear_berry`, `babiri_berry`. Nuevos nueve escenarios, 27 variantes previstas de portador activo/sin objeto/reserva, consumo, curación/confusión, boost SpD, cura freeze, resistencia Steel, SaveV2/recibos SHA256. **No pruebas de campo ni cambios de producción**.

**Fuente técnica:** `tools/item_audit/held_effect_sweep_v3.cjs` (Aguav Naughty/Hardy); `held_effect_sweep_v2.cjs` (Apicot SpD, Aspear freeze, Babiri acero sobre Clefable). Reutiliza `tests/gameplay/item_automation_v28.gd` y `item_automation_opponent_v28.gd`; motor `@pkmn/sim` sigue fijado. Fuentes existentes no equivalen al PASS de nuevas variantes.

**Archivos de escritura permitidos:** `tests/gameplay/parallel_items_w02_campaign_003.gd`, `tests/tools/test_parallel_items_w02_campaign_003.py`, `tests/fixtures/parallel_items/w02_campaign_003.json`, `reports/W02/CAMP_003_PROGRESO.csv`, informes `reports/W02/CAMP_003_ITER_XX.md`, `CONTINUIDAD.md`. No escribir workflow, manifiesto global, otro worker ni producción.

**Commits:** fixture `da00c3ab3565d46d42000e1a9f21c399bbc9270d`; Godot `a580fb13d27e074f5d847ce491bac04bd0128d76`; Python `3c8f2808a2011803b0450fd3d3a10726a4be0374`; CSV `a278495a20345e86458d13e536198140d78ae5f9`; informe `3e092736549f219778504b5ccaa9d7052400b7e2`. El HEAD final se consulta GitHub, no se incrusta recursivamente.

**CI:** [run #41553745691](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553745691). Exige recibos `CAMP003_W02_PY PASS blocks=1 checks=M` y `CAMP003_W02_GODOT PASS blocks=1 checks=M`. Si FAIL por pruebas reparables, corregir SOLO pruebas W02 sin relajar contrato; defecto nativo/SaveV2 compartido, STOP y pedir IA6.

**Siguiente `p`:** bloque 02 por cola oficial: `charti_berry;chilan_berry;chople_berry;coba_berry`. Leer CSV/último SHA de CI antes de escribir, ampliar arnés acumulativo y documentar. No saltar a bloque 03 ni iniciar fuera de 10/10.

**Prohibiciones:** `main`, V28, ramas ajenas, `modules`, `data`, `config`, guardados reales, catálogo, Mega, CI compartida, IA4. Fines visuales/GPU fuera del alcance headless.

---

## ARCHIVO HISTÓRICO ANTERIOR (LOTE_002, no concede autoridad CAMP003)

# W02 / IA2 — Cuaderno de continuidad (bayas y consumo)

> Memoria operativa exclusiva de `codex/calvo-items-20261101-w02`. La **autoridad de encargos** sigue siendo IA6 en `codex/calvo-items-20261101-arbitro`; este cuaderno no concede permisos nuevos.

## 1. Identidad, base y estado

- **Rol:** IA2/W02. **Familia:** BERRY; objeto de estos dos lotes: `sitrus_berry`, `lum_berry`, `colbur_berry`.
- **Lote vigente al cierre:** `LOTE_002_W02`, [encargo oficial](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_002_W02.md), blob `6615339c816bb9159467c3c3e99477efb95e4792`.
- **Estado:** `LISTA_PARA_REVISION` con `PENDIENTE_CI`. IA6 aceptó LOTE_001 **como auditoría documental**; no hay todavía aceptación del LOTE_002.
- **Base oficial combinada:** `38188cc208e67b19002437ac75160898ce332ec2`; merge exclusivamente en W02 `98a45388df091697c660a28cd30e958240bf6dad`, sin force/rebase.
- **Conservación:** el informe LOTE_001 mantiene blob `8b49a29d9cbf98dac85ad3947e6b872bba8a6735` y commit de entrega histórico `dd9d1616e405f5ac2d455185abbc7f5a39449233`.
- **Último commit conocido antes de escribir este cuaderno:** informe LOTE_002, `b1ac9003b2d47a756d0412344e2f16ef0067b0a7`. El SHA definitivo del cuaderno es el HEAD posterior en GitHub; no incrustar un SHA autorreferencial.
- **Último commit funcional efectivamente ejecutado por W02:** **NINGUNO**. No se alteró producción ni se obtuvo PASS nuevo con Godot.
- **Escritura permitida por LOTE_002:** sólo `tests/gameplay/parallel_items_w02_berries_v1.gd`, `tests/tools/test_parallel_items_w02_berries_v1.py`, `tests/fixtures/parallel_items/w02_berries_v1.json`, `reports/W02/LOTE_002.md` y este cuaderno. Un lote futuro requiere asignación diferente.

## 2. Mapa técnico — localizar antes de programar

```text
RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv (selección de contenido; no implica mecánica terminada)
  → config/item_selection_v1.json (política runtime existente; NO editar)
  → FieldItemService (equipar, usar campo, dueño, mochila, PC, consumo transaccional)
      → FieldItemEffects + imported_recovery_v19.json: Zidra/Ziuela voluntarias de campo
      → showdown_adventure_session + native_engine.cjs + @pkmn/sim@0.10.11:
          Zidra/Ziuela/Dillo EQUIPADAS: hooks y RNG nativos, sin duplicar callbacks
  → snapshot y SaveGameRepository / SaveV2 → publicación tras combate → mochila/UI
```

**Código de referencia de la línea V27:**
- `modules/inventory/field_item_service.gd` blob `b682c3af93b7af170c8aea66a130176c908b0745`: `configure`, `holdable`, `equip`, `unequip`, `use_item`, `_apply_field_effect`.
- `modules/inventory/field_item_effects.gd` blob `0c0eec6e7718144f2edd62b99f44984c39cdda33` usa `modules/inventory/imported_recovery_v19.json` blob `328c82722c068925415cc64bcec9a0c5790f84cd`; Dillo NO pertenece al perfil de curación voluntaria.
- `modules/battle/backends/showdown/native_engine.cjs` blob `1eacd1654d005b53324b4914c1af8db531d00068`, simulador fijado `@pkmn/sim@0.10.11`.
- `modules/inventory/item_connections_v1.json` blob `0525b37021edfc2e74c4fc2cb96e62f6f5b3e261`, los tres son equipables. La política activa no se modificó.
- Infraestructura heredada de V28: `tests/gameplay/item_automation_v28.gd`, `tests/gameplay/item_case_replay_v28.gd`, `tests/gameplay/item_automation_opponent_v28.gd`, `tools/item_audit/replay_v28.py`. **Son zonas compartidas de SOLO LECTURA**.

## 3. Estado verificado por ID

| ID | Qué existe | Evidencia exacta | Límite / acción futura |
| --- | --- | --- | --- |
| `sitrus_berry` | Hook nativo, recuperación cuarto de PS por objeto equipado, perfil de campo, traspaso y consumo. | `held_pilot.cjs:31`, histórico V1; `item_field_recovery_v5.gd:40–168` V5 (equipo/PC, tope, UI/guardar). Nueva prueba W02 `sitrus_low_hp/high_hp` **SIN_EJECUTAR**. | Probar CI y luego umbral atravesado por golpe/turno, no duplicar campo ya cubierto. |
| `lum_berry` | Hook nativo para limpiar estado, curación voluntaria completa de campo, stock. | `held_pilot.cjs:33` V1 (veneno y gasto); V5 para múltiples estados en campo. Nueva prueba W02 `lum_poison/healthy` **SIN_EJECUTAR**. | Falta prueba nueva de confusión/status alternos EQUIPADA, no dar por cubierto con V5. |
| `colbur_berry` | Hook nativo reducción Siniestro supereficaz, no consumo por tipo no coincidente; no uso de recuperación en campo. | `held_effect_sweep_v2.cjs:12,32–35`, V2; V28 replay 4 casos, [Actions #41255004688](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41255004688) PASS **histórico limitado**. Nuevos `super_dark/neutral_dark/other_type` **SIN_EJECUTAR**. | Comprobar neutralidad Siniestro, portador reserva y stock tras FLED; ampliar otros contextos sólo con nueva orden. |

**Clasificación:** hay `FUNCION_Y_PRUEBA` **histórica y acotada** en los tres, y `CONEXION_PARCIAL` para cierre global. Ni LOTE_001 ni la redacción de tests nuevos los hacen `FUNCIONALES_CERTIFICADOS`.

## 4. Historial y material reutilizable

| Lote | Cambios verdaderos | Evidencia/commit | Pruebas y revisión |
| --- | --- | --- | --- |
| 001 | Solo `reports/W02/LOTE_001.md`. Auditó código, estado y regresiones existentes. | `dd9d1616e405f5ac2d455185abbc7f5a39449233` | 22/22 verificaciones **estáticas**; 0 Godot nuevo. **ACEPTADA POR IA6 como auditoría**. |
| 002 | Merge conservador + fixture de 7 escenarios + runner Godot con 3 variantes + validador Python con 13 tests + informe + este cuaderno; 0 producción. | Merge `98a45388...`, [informe LOTE_002](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w02/docs/coordination/items_parallel_v1/reports/W02/LOTE_002.md) | 12/12 inspecciones **estáticas GitHub**. **Python, Godot y GPU SIN_EJECUTAR**; revisión IA6 pendiente. |

**Rutas nuevas:**
- `tests/fixtures/parallel_items/w02_berries_v1.json` blob `0d8d52767b768967437e1719b8cab001fac6a512`: 7 casos por activo/sin objeto/reserva.
- `tests/gameplay/parallel_items_w02_berries_v1.gd` blob `12cab8469836d8b57b42ef467b0e3a4eaded191d`: sesión real, comparaciones nativas, cierre FLED y SaveV2.
- `tests/tools/test_parallel_items_w02_berries_v1.py` blob `a6d346a74909902971b4db600c25a5cddd00a011`: verificación estricta de evidencias e integridad del contrato, pruebas sintéticas negativas. No transforma un JSON en una mecánica Pokémon.

## 5. Comandos y estado de pruebas

Desde raíz de checkout aprobado por IA6 (requiere runtime `@pkmn/sim@0.10.11` y Godot 4.7):

```bash
python tests/tools/test_parallel_items_w02_berries_v1.py --fixture-only
python tests/tools/test_parallel_items_w02_berries_v1.py --unittest
godot --headless --path . --script res://tests/gameplay/parallel_items_w02_berries_v1.gd
python tests/tools/test_parallel_items_w02_berries_v1.py --result .godot/parallel_items/w02_berries_v1/godot.json
```

**Estado:** los cuatro comandos `SIN_EJECUTAR` sobre el checkout completo; no hay reporte `godot.json` auténtico ni SHA de ejecución W02. No repetir CI por cada commit documental: **una sola ejecución consolidada** una vez revisada por IA6, con logs y raw.

## 6. Deuda, colisiones y siguiente relevo

- Checkpoint integrado `38188cc...` **no certificado por CI**. No asumir que V28 y catálogo funcionan combinados por el mero hecho de un merge sin conflictos.
- El runner actual compara siete contextos, no todos los de Pokémon (dobles, estado alternativo, sustituto, inmunidades, victoria/derrota, reentrada, ataque que cruza umbral de Zidra y UI/GPU siguen abiertos).
- Las tres bayas comparten infraestructura de simulador y guardado; **no añadir callbacks por objeto en GDScript ni cambiar `native_engine` o `FieldItemService` sin orden**.
- Prohibido tocar `main`, V28, árbitra, otras ramas, `QUEUE_V1.csv`, catálogos originales, config, arte, schema, guardados, workflow o tests antiguos.
- **Retomar:** 1) consultar encargo más reciente de IA6 en su rama y verificar blob; 2) leer este cuaderno y último informe; 3) comprobar HEAD y compare del checkpoint; 4) IA6 debería revisar diff y ejecutar/supervisar Python + Godot en CI consolidada; 5) registrar run SHA, PASS/FAIL y defectos concretos, sin promover falsamente los tres IDs a certificado; 6) empezar LOTE_003 **solo** si IA6 publica nuevo permiso.

**Próximo paso reproducible:** revisión de IA6 y prueba consolidada del código W02. Si falla un escenario, localizar primero fixture, inicialización de estado, contrato nativo o persistencia; solicitar autorización si corregirlo necesita producción.

**Verificación visual/GPU:** pendiente; no se ha hecho en LOTE_002.
