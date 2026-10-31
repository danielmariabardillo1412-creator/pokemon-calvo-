# O100 — reconciliación de inventario y contratos

**Estado: PASS dentro de `PARTIAL_READY_FOR_REVIEW`.** La familia no se declara
aceptada. Evidencia serializada: `results.json` (SHA-256
`06474ede97f5e4f422eb1223401a3104fb07095ce54fe2b59563471fbb8f1d4a`).

## Qué se ejecutó de verdad

| Comando | Resultado | Checks | Duración | Log |
|---|---|---|---|---|
| `python tests/tools/test_item_closure_audit_v2.py` | PASS | 10 | 2.53 s | `.godot/opencode_items_v2/closure/runs/<run>/audit_test.log` |
| `python tools/item_import/audit_item_closure_v2.py --check` | PASS | 1 | 0.44 s | `.godot/opencode_items_v2/closure/runs/<run>/audit_check.log` |

La prueba no usa constantes: carga el catálogo, las políticas, las conexiones y
los informes reales, reconstruye COVERAGE y compara JSON/CSV byte a byte. El
`--check` vuelve a compilar y compara los bytes almacenados.

## Cifras reconciliadas (2.222 IDs)

- Permiso: 625 permitidos, 43 excluidos, 1.554 no aplicables.
- Equipables permitidos con definición nativa: 619; faltan exactamente 6.
- Arte: 1.011 con arte, 1.055 sin arte preparada, 156 fuera del plan.
- Máquinas: 338 mapeadas, 229 enseñables verificadas, 109 pendientes de perfil.
- Evolución: 57 rutas soportadas, 15 de otro tipo; 26 IDs implicados.
- UNKNOWN: 0. Estados globales: 291 verificados, 250 parciales, 1.604 con
  dependencia concreta, 34 no aplicables, 43 excluidos.
- Los 6 huecos nativos son `amulet_coin`, `cleanse_tag`, `exp_share`,
  `linking_cord`, `luck_incense`, `pure_incense`; `smoke_ball` ya está presente.

## Límites

La presencia de arte o de metadato nativo no certifica la mecánica. Cada fila
separa permiso, arte, equipar, metadato nativo, uso de campo, uso en combate,
evolución, máquina y escenario. `DEPENDENCY_MISSING` describe un dato, sistema o
decisión ausente; no es un fallo de prueba ni autoriza a inventar un efecto
neutro. La auditoría no certifica todas las combinaciones jugables.

Los cambios de O100/O110/O120 comparten archivos autorizados y siguen sin
commit, por lo que no se pudo aislar un guard por familia. El guard global
`--full` sí se ejecutó y pasó.
