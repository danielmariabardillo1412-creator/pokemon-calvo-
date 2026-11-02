# IA6 — RECUPERACIÓN W04 FINAL / W05 ITER_02, control real (2026-11-02)

**Prioridad:** la CI debe verificarse por ejecución y SHA. Esta acta no permite escribir nuevas mecánicas de producción, guardar una partida real, tocar main/V28 ni reabrir el cuarto bloque de W04.

## Estado de entrega
- **W04/IA4:** CAMPAÑA_001 **03/03 entregada** tras relevo, rama propia `codex/calvo-items-20261101-w04`, HEAD `3c6aa9c3b9754a197a4d34c9bd0c0a7606af1d1f`. El nuevo runner prueba 6 piedras × equipo/PC = 12 casos SaveV2, identidad, especie y atributos, rechazos y consumo único. **STOP por campaña terminada.**
- **W05/IA5:** CAMPAÑA_002 **02/03 entregada**, rama propia `codex/calvo-items-20261102-w05-camp002`, HEAD `1913c2b3b219ebcc431abc904fb7a13374fda9e4`. Selector de 12 MT válidas de ITER_01, runner Godot que enseña 6 MT reales por `FieldItemService.teach`, PP, propietario, consumo, rechazo, persistencia y limpieza `user://`. ITER_03 **todavía no existe**.

## CI en staging aislado
- Primera prueba [#41537680311](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41537680311), SHA `e4f4642f54632d4aefd1ba276f485ff3073a56d4` **FAIL**, separada por familia: W04 falló 12 comparaciones de IV/EV/movimientos/XP/amistad **después** de SaveV2 (12 casos llegaron al save/load con instantánea íntegra); W05 PASS `W05_CAMP002_ITER02 PASS checks=177 cases=6`; Python W05 11 tests PASS; muestra 12 válida.
- Diagnóstico W04: el serializador `CreatureInstance.to_dict()` convierte claves de IV/EV a `String`; un `Dictionary` de claves originales `StringName` no debe cotejarse con otro serializado con igualdad cruda de claves. En cambio se comparan **todos los valores canónicos** `to_dict()["ivs"]`, `["evs"]`, `["move_ids"]`, `["moveset"]`, `["experience"]`, `["friendship"]`, más la instantánea completa, especie, ID, inventario, lugar y rechazos ya existentes. No se eliminó ninguna comprobación funcional, ni se cambió `SaveGameRepository`, evolución, motor o datos.
- Segundo staging [#41538151097](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41538151097), SHA `850a81b62d608370ece05bcfb610a1e931246301`: **`completed/success` confirmado**; W04 GDScript/Python y W05 GDScript/Python con veredicto independiente `success`. Registro exacto: **W04 559 comprobaciones, 12 casos de SaveV2, 0 errores**, validador Python 73 checks estáticos y `PARALLEL_ITEMS_W04_CAMP_001_GODOT PASS iteration=3 checks=559 cases=12`; **W05 177 comprobaciones, 6 enseñanzas de MT, 0 errores**, 11 pruebas Python y selector de 12 MT `W05_SAMPLE_PASS 12`.

## Integración de archivos exactos
- W04 prueba GDScript con comparación serializada, blob `7af3c80e4708034cd23c6365e421e10b3da90199`. W04 Python validador blob `d09cbdda8912bd75e6b0c518af32774835bad485`.
- W05 runner GDScript `237dedaf4ff1dbc9d8b67cba69aac803f8751e22`, Python `7393a05d614bc6198d00099d5b3dbf74c70311a2`, fixture `e50a0a1c9d3687b970c6c1291fd1c050a250c733`.
- Los cinco blobs se promueven sin modificaciones desde staging al árbol árbitra. Las ramas W04 y W05 **NO se sobrescriben**. W04 conserva su test original anterior en su propia rama; la corrección válida queda integrada solo en árbitra. No se le dará más `p`.
- El pase en staging de **exactos blobs** acredita esos casos, no todos los efectos ni arte/UI/GPU. Después de promoción se debe mirar CI genérica en nuevo SHA si se dispara.

## Próximas acciones
- W01/W02/W03 CAMP002 02/03, tests 687/800/37 PASS [#41493879869](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493879869), pero W01/W02 deben sincronizar el runner corregido según `CAMPAIGN_002_ITER02_CI_GATE.md` antes de `p` para ITER_03. W03 únicamente auditoría de contexto final, sin implementación de Dusk/Repeat/Dive.
- W05 podrá continuar a ITER_03 **solo tras verificar conclusión final de CI** y recibir un `p` de usuario; la nueva entrega exigirá otro CI. W04: STOP.
- No iniciar CAMP003 ni avanzar a más objetos en paralelo sin nuevo gate.
