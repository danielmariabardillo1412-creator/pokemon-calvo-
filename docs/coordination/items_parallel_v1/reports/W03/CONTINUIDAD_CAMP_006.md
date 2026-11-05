## NUEVO — CAMPAÑA_006 W03, bloque 03/10: L2 POSITIVO, L3 PENDIENTE IA6

**Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`. El bloque 03 `repel;super_repel;max_repel` añade el helper `modules/overworld/field_repel_step_effect.gd`. Conecta al productor de pasos **reales** `OverworldPlayer.step_completed`; duraciones 100/200/250 pasos, filtra encuentros con nivel salvaje inferior al líder, caduca exactamente al paso final y permite serializar/restaurar su propio estado. El runner Godot mueve el personaje por `apply_motion` 550 pasos físicos, verifica no movimientos bloqueados, niveles 9/10/11, expiración y roundtrip propio. **No hay consumo de repelentes desde la mochila, ni filtro ligado a encuentros reales de la demo, ni SaveV2 integrado**: L2 probado ≠ L3 jugable. Ticket exacto en `reports/W03/CAMP_006_ITER_03.md`: IA6 debe decidir punto de integración antes de inicio de combate, preservar RNG/candidatos, activar ítem en bolsa y persistir `active_id/remaining_steps` en SaveV2; no cambiar mundo, sesión o SaveV2 unilateralmente.

**CI código #41965630903:** [GitHub Actions](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41965630903), SHA `7be81acec35ee8fce4edd5f1a5e1bb917d408f54`, **SUCCESS**, Python CAMP006 43, Godot CAMP006 77, regresión CAMP005 Python 169 y Godot 208. Progreso oficial: 03/10 marcado `CI_PASS_L2_VERIFICADO` y bloque 02 L3 se conserva sin modificaciones.

**Siguiente `p`: solo bloque 04**, `black_flute;white_flute;lure;super_lure;max_lure`, con diagnóstico de dependencia de duración/frecuencia y trabajo positivo nuevo solo si es independiente; no repetir la dependencia del productor de encuentros. En caso de repetir exactamente la anterior sin seam, elevar a IA6 y detener. No editar `main`, V28 ni ramas ajenas.

---

## Cierre CI bloque02 — mochila real y guardado manual

Código funcional y runner ampliado verificados en [GitHub Actions #41955141690](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41955141690), SHA `275af61fd2028737cfafc227207c994591ba0ec3`: **completed/success**. Recibos: `CAMP006_W03_PY PASS blocks=2 checks=29`, `CAMP006_W03_GODOT PASS blocks=2 checks=43`, `CAMP005_W03_PY PASS blocks=10 checks=169`, `CAMP005_W03_GODOT PASS blocks=10 checks=208`. Primera CI de integración [#41954695248](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41954695248) PASS 29/39; tras ampliar rechazos, [#41954953546](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41954953546) falló únicamente por expectativa incorrecta de posición del test; corregido y demostrado en la CI final.

**Efecto positivo:** pulsación real `FieldItemBag._use.pressed` dentro de la cueva → `EscapeRopeDemoPilot`/travesía → superficie segura → -1 Cuerda Huida. **SaveV2 solo manual**, sin autoguardado al usar el objeto; la recarga conserva posición y cantidad. Stale inventory, colisión en marcador, falta de ítem y doble activación rechazan sin consumo. `fluffy_tail` queda en batalla y la regresión anterior confirma su contrato. No se cambiaron APIs protegidas.

**Reserva de auditoría:** `FieldWorldItemTransaction._restore_position` solo puede restaurar posición si el controlador terminó su transición. Ante fallo catastrófico permanente del controlador o mutación simultánea ajena, la atomicidad general necesita una primitiva coordinada de cancelación/rollback (IA6); la evidencia actual avala el camino normal y los rechazos probados, **no garantía absoluta ante todos los fallos posibles**. La modificación del archivo compartido `field_item_bag.gd` requiere revisión de IA6 antes de fusionar.

---

## CAMP006 bloque02: PAUSA por contrato compartido IA6

La revisión del gate mantiene FieldItemBag, FieldItemService, sesión e infraestructura SaveV2 bajo responsabilidad de IA6. El piloto 01/10 sigue aprobado. El bloque02 requiere conectar inventario, traslado y persistencia en una transacción; no está autorizado hacerlo unilateralmente. Ticket: `reports/W03/CAMP_006_BLOCK_02_IA6_INTERFACE_BLOCKER.md` (commit `723525ec`). No aumentar el progreso ni repetir pruebas negativas. WORLD_RETURN detenida hasta asignación explícita de la interfaz por IA6.

---

## Última verificación tras actualizar el CSV

[GitHub Actions #41764265082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764265082), HEAD `eead52006beb011f9a4c994cc4a7e9ced0a1c43a`, **completed/success**. La CI volvió a comprobar el mismo código funcional y el estado final del progreso: `CAMP006_W03_PY PASS blocks=1 checks=17`, `CAMP006_W03_GODOT PASS blocks=1 checks=20`, regresión `CAMP005_W03_PY PASS blocks=10 checks=169` y `CAMP005_W03_GODOT PASS blocks=10 checks=208`. El bloque 01 se considera **piloto de navegación L2/L3 validado**, no una Cuerda Huida conectada al botón de mochila. El contrato transaccional de IA6 sigue pendiente.

---

# IA3/W03 — CAMP006 continuidad — 01/10

**Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`. **Bloque 01 `escape_rope`: PILOTO DEMO FUNCIONAL, NO AÚN ÍTEM USABLE DESDE BOLSA.**

La nueva lógica propia `modules/overworld/escape_rope_demo_pilot.gd` valida un ancla de retorno canónica `CaveExit → SurfaceCaveReturn` y alternativamente salida del edificio, usando `OverworldTraversalController.traverse_portal` sin modificar APIs de mundo, sesión, inventario o SaveV2. Test Godot `tests/gameplay/parallel_items_w03_campaign_006.gd` instancia `field_demo.tscn`, entra en cueva por portal real, retorna a superficie, guarda la sesión nativa con `field_native_bridge.save_game` y recupera posición/cantidad con `load_game`; verifica superficie sin ancla, movimiento bloqueado y no-consumo de ítem durante el piloto.

**CI de código comprobada:** [#41764044349](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764044349), commit `425885a7182db2a7c9962f0a396fd22bf70b858e`, SUCCESS: `CAMP006_W03_PY PASS blocks=1 checks=17`, `CAMP006_W03_GODOT PASS blocks=1 checks=20`; CAMP005 regresión Python 169, Godot 208 PASS. Errores iniciales de tipado runner y preflight de movimiento resueltos y detallados en `CAMP_006_ITER_01.md`.

**TICKET DE PRODUCTOR COMPARTIDO A IA6, necesario para el siguiente bloque:** autorizar la interfaz transaccional `WorldItemCommand.use_world_item(escape_rope, expected_world_revision, expected_inventory_stamp)` y el propietario de `FieldItemBag/FieldItemService`, que hagan: validar bolsa y mundo → preparar consumo unitario → solicitar traslado seguro con adaptador → publicar inventario y posición juntos → guardar/cargar SaveV2 o rollback total. Probar fallo de disco, destino ocupado, combate activo, mochila corrupta, doble uso, revisión desactualizada. **NO IMPLEMENTAR** consumo/UI saltándose la autorización. Esto puede bloquear el bloque 02 entero; aplicar regla de detener la familia si el productor compartido no está asignado.

**Siguiente `p`: bloque 02 de la cola aprobada**, `escape_rope;fluffy_tail`, con evaluación del ticket anterior y no meras pruebas negativas. No iniciar otros bloques anticipadamente. Prohibido tocar `main`, V28, PR118, la rama de IA6, otras ramas o APIs compartidas.

