# W02 / IA2 — Cuaderno de continuidad (bayas y consumo)

## ESTADO VIGENTE — CAMPAÑA_001, ITER_01 / 3

- **Identidad:** IA2/W02, rama propia `codex/calvo-items-20261101-w02`. **Estado:** `PREPARADO_PENDIENTE_CI`, ITER_01 entregada, ITER_02/03 pendientes. La campaña **ACTIVADA** no permite adelantar iteraciones: cada `p` = un microbloque.
- **Autoridad:** [CAMP_001_W02](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/campaigns/CAMP_001_W02.md), blob `f6f8f08b13f9e4f84d18970643ebd4aeab5a75b7`, puerta `CAMPAIGN_GATE_001.md` blob `3ef0b39f7eb74f3ebcb688f279c254daec981f8e`. El protocolo anterior decía «propuesta»; la **puerta actual activa** prevalece.
- **Base:** fast-forward seguro de W02 a árbitra HEAD `1b52fdd0b7b89e468811a17ad83a917ec7107735`, después nuevos commits solo en W02. Informe LOTE_001 intacto blob `8b49a29d9cbf98dac85ad3947e6b872bba8a6735`; LOTE_002 intacto blob `201a10e1396334277036c92faa9a7bdd914ce21c`.
- **CI base REAL ya pasada:** [Actions #41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), commit `ac34fabbe1a27e69614f0239abee21c29d6fe65e`: Godot 4.7; **W02 anterior 503 checks, 7 casos/21 variantes PASS** (Zidra/Ziuela/Dillo). No cubre los nuevos casos de CAMPAÑA_001.
- **ITER_01 — Oran/Pecha/Cheri:** `oran_berry`, `pecha_berry`, `cheri_berry`. **8 casos**, **24 variantes nativas** (`active/none/reserve`), **16 variantes campo** (`PARTY/STORAGE`). Positivo, negativo, stock inicial 2 y gasto único, uso de mochila, restauración y publicación tras batalla, SaveV2.
- **Nuevos archivos de test exclusivos:** `tests/fixtures/parallel_items/w02_campaign_001.json` blob `6a72c1cb043b82cfa79c0a415f3ecfc6668e80e7`; `tests/gameplay/parallel_items_w02_campaign_001.gd` blob `40a9266e2b633ca9cddd9b49766c739acc0c9d69`; `tests/tools/test_parallel_items_w02_campaign_001.py` blob `30babaf9b3a5d7e042f69a2523868b7b52992f02`. **Commits de código:** `3bde944a`, `545f3a61`, `e6873734`.
- **Registro operativo:** [CAMP_001_ITER_01.md](./CAMP_001_ITER_01.md), commit `3fee53a8b6f03126cf48aa8acd5d15c5b230c2f8`; [CAMP_001_PROGRESO.csv](./CAMP_001_PROGRESO.csv), commit `253c4cbd7548365c276094f86804d0595cb3a562`. El SHA definitivo del cuaderno se consulta en HEAD, no se autorreferencia.
- **Resultados del microbloque 01:** **15/15 PASS ESTÁTICO REAL** revisando blobs + contratos vía conector GitHub; **12 tests Python definidos, SIN_EJECUTAR**; integración Godot nueva **SIN_EJECUTAR / PENDIENTE_CI**; GPU/manual **NO_REALIZADA**. No confundir preparación con función certificada.
- **Cómo verificar al integrar:** `python tests/tools/test_parallel_items_w02_campaign_001.py --fixture-only`, `python tests/tools/test_parallel_items_w02_campaign_001.py --unittest`, `godot --headless --path . --script res://tests/gameplay/parallel_items_w02_campaign_001.gd`, `python tests/tools/test_parallel_items_w02_campaign_001.py --result .godot/parallel_items/w02_campaign_001/godot.json`. Requiere checkout funcional Godot 4.7 + runtime `@pkmn/sim@0.10.11`; no ejecutar CI repetida por documentación.
- **Siguiente `p`:** comprobar puerta/STATUS y que no hay FAIL o cambio de contrato; ejecutar SOLO **ITER_02** para `persim_berry`, `chesto_berry`, `rawst_berry` sobre los mismos archivos de test/fixtures, registrar iteración y progreso; no iniciar ITER_03 hasta posterior `p`.
- **Prohibido:** producción, archivos compartidos de simulador, RNG, esquema, políticas, `main`, V28 original, árbitra y otras ramas. Mantener los viejos 7 casos W02 sin alterar expectativas. Si falla test funcional tras CI, detener campaña, diagnosticar y pedir IA6. Tras ITER_03 publicar `CAMP_001_FINAL.md` y emitir `CAMPAÑA_001_FINALIZADA`.

---

## ARCHIVO HISTÓRICO — LOTE_001 y LOTE_002 (información de base anterior a la campaña)

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
