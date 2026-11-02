> **CIERRE ACTUAL W02:** CAMPAÑA_002 03/03 `CAMPAÑA_002_FINALIZADA`. La nota de IA6 que sigue fue emitida cuando ITER_03 todavía estaba pendiente; **no ejecutar más bloques con `p`**. Confirmar último run automático del SHA nuevo antes de certificar funcionamiento.

> **INSTRUCCIÓN VIGENTE IA6 — CI AUTOMÁTICA V3 (2026-11-02):** el estado histórico `PREPARADO_PENDIENTE_CI` o `STOP HASTA IA6` que aparece más abajo **ya no exige detenerse solo por esperar pruebas**. Lee en rama `codex/calvo-items-20261101-arbitro` [CI_AUTOPILOT_V3.md](../../CI_AUTOPILOT_V3.md) y `CAMPAIGN_GATE_002.md`: se ha instalado el workflow `.github/workflows/parallel-camp002-worker-autoci.yml` **en esta misma rama**; la primera ejecución propia [#41539808520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539808520) terminó `completed/success`. **Siguiente `p` ejecuta exclusivamente ITER_03 de CAMP_002** tras comprobar que no exista un FAIL más reciente. Cambios de tests disparan CI sin intervención de IA6; commits solo de informes NO la disparan. Si la nueva CI está `queued/in_progress`, puedes preparar hasta un bloque posterior ya autorizado sin declarar PASS ni borrar tests previos; un FAIL real exige reparar tu prueba en tus rutas exclusivas o STOP ante defecto funcional. **En ITER_03, publicar y STOP sin iniciar ITER_04/CAMP_003.** IA6 ya sincronizó el runner corregido de números JSON/estadísticas Figy; no repetir parche. No tocar `main`, V28, otras ramas ni producción.

# W02 / IA2 — Cuaderno de continuidad (bayas y consumo)

## ESTADO FINAL — CAMPAÑA_002_FINALIZADA / 03 DE 03

- **Rama única:** `codex/calvo-items-20261102-w02-camp002`; **IA2/W02 STOP**, tres bloques entregados; una `p` posterior NO autoriza ITER_04 ni CAMP_003.
- **Autoridad:** `CI_AUTOPILOT_V3.md` + `CAMPAIGN_GATE_002.md` + `campaigns/CAMP_002_W02.md` (blob `8e52a9f9e740eaee6210494ffaa764ce1ad9c644`). IA6 conserva coordinación y revisión de fallos.
- **CI previa PASS confirmado:** [W02 #41539808520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539808520) `completed/success` SHA `6373ea47cac3069b120e9e2102f49d100ea14698`, no incluye el nuevo contrato de ITER_03.
- **ITER_03:** 9 escenarios originales conservados, 4 bayas exactas (`sitrus_berry`, `lum_berry`, `leppa_berry`, `figy_berry`), 27 variantes nativas (9×3) con dueño, consumo único, FLED, SaveV2. SHA-256 del fixture comparado con Python y 22 pruebas unitarias definidas. `regression_contract` obliga matriz de IDs, 27 guardados y cero pruebas de campo inventadas.
- **Archivos finales:** `tests/fixtures/parallel_items/w02_campaign_002.json` blob `767b5998483e9710c1e9c6d1aacb0b2375f35e6c`; `tests/gameplay/parallel_items_w02_campaign_002.gd` blob `67d2d0b79568e31eca24fb2d70aab3de5f156106`; `tests/tools/test_parallel_items_w02_campaign_002.py` blob `a3fe65ae70eeeb201a58c7918de30e4db8414346`.
- **Última inspección** 24/24 comprobaciones estáticas PASS; **CI del nuevo SHA aún sin confirmación**. Workflow de Actions propio `.github/workflows/parallel-camp002-worker-autoci.yml` se dispara tras escritura de pruebas. Las declaraciones de `PASS` se vinculan siempre al SHA real del run; estático no implica ejecución.
- **Entregables:** [ITER_01](./CAMP_002_ITER_01.md), [ITER_02](./CAMP_002_ITER_02.md), [ITER_03](./CAMP_002_ITER_03.md), [FINAL](./CAMP_002_FINAL.md), [CSV](./CAMP_002_PROGRESO.csv) (3 filas). El historial anterior y Persim de CAMP_001 no se reescribieron.
- **Brechas:** no se probaron mochila/campo, interfaz, GPU ni otros formatos; Figy no consta en perfil de recuperación de campo. No inventar efecto nuevo. Se preserva corrección de stats por naturaleza de IA6 y comparación numérica de JSON.
- **IA6 a continuación:** verificar el último workflow del SHA actual (Godot import, 9 casos, Python 22, 27 recibos SaveV2), atender cualquier FAIL antes de certificar/promover. No modificar producción ni `main`, V28, PR #118, otras ramas o workflows.
- **Estado administrativo:** `CAMPAÑA_002_FINALIZADA`; estado funcional `PENDIENTE_CI_FINAL` hasta ejecución verificable.

---



## HISTÓRICO — estado al terminar ITER_02/03

- **Identidad/rama:** IA2/W02, `codex/calvo-items-20261102-w02-camp002`; **ITER_01 e ITER_02 publicadas**, ITER_03 pendiente de la siguiente `p`. Estado global `PREPARADO_PENDIENTE_CI` para ITER_02.
- **Autoridad:** IA6, `campaigns/CAMP_002_W02.md` blob `8e52a9f9e740eaee6210494ffaa764ce1ad9c644`; puerta actual `CAMPAIGN_GATE_002.md` con añadido obligatorio de [CAMPAIGN_002_ITER01_CI_GATE.md](../../CAMPAIGN_002_ITER01_CI_GATE.md) blob `12e9c3021e80f9e03e0f9b0e900853b9a7e6a513`.
- **PASS real iteración 01:** [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741), staging SHA `967002fcbf26a1159d3a14a020e8921b34cfab8f`: Sitrus/Lum 350 checks Godot, 4 escenarios y 13 unittests Python PASS, recibos validados. No cubre nuevos Leppa/Figy.
- **Sincronización exacta ordenada por IA6:** `tests/gameplay/parallel_items_w02_campaign_002.gd` blob validado `2e0ac1d2142dad96f110254e7eb4f2a3c5f04c47`, aplicado al inicio de ITER_02 mediante commit `3fba13ac0b17d5e01b082ab498450465d3eef8d5`; arreglo de números JSON 1.0/1, sin merge de ramas.
- **ITER_02 nuevos:** `leppa_berry` (Zanama) y `figy_berry` (Higog); cinco casos, tres modos cada uno. PP0/PP1 del primer movimiento al elegir `move 2`; Figy PS 1/5 naturaleza `modest` (confusión nativa) y `hardy` (sin confusión), más control PS altos. **Acumulado 4 IDs, 9 escenarios y 27 variantes nativas definidas**, sin prueba Godot nueva.
- **Perfil verificado:** `tools/item_audit/held_effect_sweep_v3.cjs` contiene Zanama PP0/PP1; `tools/item_audit/held_pilot.cjs` usa `mew_modest` para Higog (+1/3 HP y confusión). `CreatureInstance.nature_id` persistente. `imported_recovery_v19.json` incluye Zanama de campo pero **no Higog**; no se prueban efectos de campo en ITER_02 ni se altera producción.
- **Archivos actuales:** fixture `tests/fixtures/parallel_items/w02_campaign_002.json` blob `fbce41f9bbda5f920bd0d9135fc3eefe2eeb49dc`; runner Godot `tests/gameplay/parallel_items_w02_campaign_002.gd` blob `540d93c0f29a027dca8f9b94254e7c008366a0b4`; validador Python `tests/tools/test_parallel_items_w02_campaign_002.py` blob `77e5016003eca3a7bfce63261aba265dfda7abdc`. Últimos commits de código `ac3f49f5`, `fbc45d93`, `52640aca`.
- **Resultados ITER_02:** 31/31 revisiones estáticas sobre blobs GitHub PASS, **17 pruebas Python definidas SIN_EJECUTAR**, Godot 4.7 SIN_EJECUTAR, GPU no realizada. El PASS de ITER_01 no acredita ninguno de los cinco nuevos casos.
- **Evidencias:** [CAMP_002_ITER_02.md](./CAMP_002_ITER_02.md), commit `362562eeec8bd42c2653884ca819f9a2bf3b37a6`; [CAMP_002_PROGRESO.csv](./CAMP_002_PROGRESO.csv) commit `6f5643ffe6a85c672923914ddb741523341a425b`; informes ITER_01 y pruebas antiguas no se reescribieron.
- **Verificación IA6:** `python tests/tools/test_parallel_items_w02_campaign_002.py --unittest`; `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_002.gd`; `python tests/tools/test_parallel_items_w02_campaign_002.py --result .godot/parallel_items/w02_campaign_002/godot.json`. Requiere PASS en SHA nuevo antes de funcional.
- **Próximo `p`:** consultar gate/STATUS actual y ejecutar **solo ITER_03**, matriz de 4 bayas, SaveV2 y regresión, o detenerse si IA6 registra FAIL. Tras 03 publicar `CAMP_002_FINAL.md` y decir `CAMPAÑA_002_FINALIZADA`.
- **Prohibido:** `main`, V28, PR #118, todas las ramas CAMP_001, árbitra y las otras workers, IA4 congelada, `modules/`, `config/`, `data/`, `.github/`, simulador/guardados/selección, Mega universal.

---

## HISTÓRICO — estado tras ITER_01/03


## ESTADO ANTERIOR — CAMPAÑA_002, ITER_01/03

- **Identidad/rama:** IA2/W02; exclusivamente `codex/calvo-items-20261102-w02-camp002`, base oficial `67959eb8f19abfd2ae391872747a14f603fcab01`. No mezclar rama de 20261101.
- **Encargo IA6:** `CAMPAIGN_GATE_002.md` blob `ebc787803599e2b13cbd24c169b69112d18f7a42`; `campaigns/CAMP_002_W02.md` blob `8e52a9f9e740eaee6210494ffaa764ce1ad9c644`; manifiesto blob `bb9471862d3116b982f90e1867d512e278f801e0`.
- **Estado:** ITER_01 publicada `PREPARADO_PENDIENTE_CI`; ITER_02/03 pendientes, una por futura `p`, STOP ante error/contrato fuera de alcance. IA6 responsable de CI e integración.
- **IDs actuales:** `sitrus_berry`/Zidra y `lum_berry`/Ziuela. Cuatro escenarios (PS bajo/alto; veneno/sano); tres modos `active/none/reserve`, 12 pruebas nativas previstas, con consumo único, cierre FLED, dueño físico y SaveV2.
- **Ruta funcional sin cambios:** catálogo → `FieldItemService.equip` → `@pkmn/sim` mediante `parallel_items_w02_berries_v1.gd` histórico validado → restaurar y cerrar sesión → `SaveGameRepository` SaveV2. Solo se escriben nuevos tests.
- **Archivos:** `tests/fixtures/parallel_items/w02_campaign_002.json` blob `3c9b7c6f4a7449d295e8f05fc2c7b44aaeb5ed4d`; `tests/gameplay/parallel_items_w02_campaign_002.gd` blob `53b70033578f1a31c13081f558334bacf247ada5`; `tests/tools/test_parallel_items_w02_campaign_002.py` blob `0325554ac8bd329ee920b0a14f4d5037d98818c6`.
- **Evidencia:** 22/22 comprobaciones ESTÁTICAS del fixture, herencia y recibos SHA-256. **Python nuevo 13 unittests SIN_EJECUTAR; Godot 4.7 SIN_EJECUTAR; GPU NO REALIZADA.** CI base #41364601482/#41364601486 PASS en SHA `a8e09dbf`, no cubre CAMP_002.
- **Campo:** Sitrus y Lum sí poseen perfil existente en `modules/inventory/imported_recovery_v19.json`; no se ensaya uso de campo en ITER_01. `NOT_TESTED_ITER_01` no significa ausencia funcional.
- **Informes nuevos:** [ITER_01](./CAMP_002_ITER_01.md) commit `ac51aa230fd974b112e9a1b0f9e3c41c7580dc11`, [progreso](./CAMP_002_PROGRESO.csv) commit `2bb3e57a3f9b90b866da19c258e480a3cea99727`.
- **Pruebas para IA6:** `python tests/tools/test_parallel_items_w02_campaign_002.py --unittest`; `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_002.gd`; `python tests/tools/test_parallel_items_w02_campaign_002.py --result .godot/parallel_items/w02_campaign_002/godot.json`.
- **Siguiente `p`:** ITER_02 Leppa (PP agotados/no agotados) + Figy (perfil de naturaleza y recuperación solo tras cotejo normativo). No anticipar ITER_03.
- **Prohibiciones:** main, V28, PR #118, W04 congelada, ramas ajenas, ramas CAMP_001, producción, catálogos, RNG, selección, guardados, `.github/`, arte y políticas Mega.

---

## HISTORIAL PREVIO LOTE_002 (no otorga permisos actuales)

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
