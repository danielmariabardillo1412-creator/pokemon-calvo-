# IA6 — AUDITORÍA DE LAS CINCO IAs Y NUEVAS TANDAS, 2026-11-10

## Evidencia actual consultada en GitHub Actions (completado / SUCCESS)
| IA | SHA funcional | Run | Resultado técnico |
|---|---|---|---|
| W01 | 9d1a9dae8b9d9abed09a12b082f7a719aa047981 | [42730773059](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42730773059) | TANDA01 10 gemas con 20 activaciones nativas/20 negativas/120 snapshots + Godot 4002 checks; CAMP005 Godot 24723 y CAMP004 16816. **Falta cierre documental**: CSV sigue EN_CI_AUTOMATICA y no existe AUTORUN_V1_FINAL.md. |
| W02 | f8168c2b5cdb2dc74bc2820d94cc59e7bc7be19c | [42730263746](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42730263746) | TANDA01 10 mentas L3 desde servicio, Godot 822, Python95, histórico CAMP005 congelado 288 y actual con whitelist; final publicado. |
| W03 | 4d6ee28064706e336ec8cf8ac89862356e886017 | [42736177949](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42736177949) | TANDA02 10 hitos con ledger real y Repeat Ball L2 en WildAdventureSession (37 checks), **native_capture_l3=false**. FIELD_NATIVE 118 checks PASS es regresión, NO certifica Repeat nativo. |
| W04 | 8c216c9c15dd028241cb664c99f06d79a81c5536 | [42735277975](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42735277975) | TANDA02 10 hitos; **un productor de identidad de forma real** Slowpoke Galar elegido por WildEncounterSystem, Factory, opcional form_id y SaveV2, Godot 37 + Python 29. **No** cambios de forma por ítem, fusiones, ni aparición demostrada en mapa jugable. |
| W05 | 07513aa912a01219d21155b9ee5eb7c75a5d4a37 | [42734399078](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42734399078) | TANDA02 180/180 MT SV panel aislado headless Godot 10467, más 49 anteriores = 229 activas con positivo; sin revisión GPU o integración final del panel nuevo en FieldItemBag. |

Los runs anteriores han sido consultados en API, los jobs reales están SUCCESS. La rapidez de W04/W03 **no significa implementación completa de las familias**: se miden hitos, y sus propios informes distinguen L2/L3. W01 hizo pruebas reales, pero dejó CSV desactualizado. W02 SÍ había terminado, no estaba pendiente de arrancar.

## Relevo permanente ejecutado
Se actualizaron los cinco archivos en sus ramas exactas: `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`. Colas centrales con diez filas por W:
- [W01 TANDA02](QUEUE_W01_TANDA_02.md): cinco gemas restantes (+ QA), cierre documental TANDA01 primero.
- [W02 TANDA02](QUEUE_W02_TANDA_02.md): corregir FieldGrowth/FieldMochi con naturaleza efectiva y secuencias reales de objetos.
- [W03 TANDA03](QUEUE_W03_TANDA_03.md): autorización mínima ShowdownAdventureSession.capture / _finish para Repeat Ball nativo L3.
- [W04 TANDA03](QUEUE_W04_TANDA_03.md): 56 variantes regionales que constan en config/pokemon_variants_v1.json, diez grupos; piloto Slowpoke Galar ya certificado excluido.
- [W05 TANDA03](QUEUE_W05_TANDA_03.md): resiliencia y UX del panel de 229 MT, no añadir más MT ficticias.

**Regla para todas:** ante `p` abrir su propia nota y reanudar tarea pendiente; nada de repetir los lotes cerrados; si termina turno deja checkpoint. Diez filas examinadas no equivalen a diez nuevas funcionalidades. Publicar CI HEAD y reporte final. Sin nuevos mensajes IA6 por cada microbloque.

## Puerta de integración IA6 pendiente (riesgo alto)
La rama aislada `codex/calvo-ia6-integration-20261109` tenía CI V3 [#42701239557](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42701239557) SUCCESS, pero NO contiene automáticamente los desarrollos posteriores de W01/W02/W03/W04/W05. W02 y W04 tocan consumidores/CreatureInstance y W03 SaveV2+captura, W05 UI; integrarlos exigirá cherry-pick por función con CI conjunta y sin borrar naturaleza efectiva ni panel de libros/repelentes. No modificar main, V28 ni PR118. Las nuevas notas son autorización, no CI de las siguientes tandas.

**Documentos de continuidad:** [INDEX.md](INDEX.md), [README.md](README.md), [STATUS.md](../STATUS.md).
