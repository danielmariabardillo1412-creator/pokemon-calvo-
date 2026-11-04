## Última verificación tras actualizar el CSV

[GitHub Actions #41764265082](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764265082), HEAD `eead52006beb011f9a4c994cc4a7e9ced0a1c43a`, **completed/success**. La CI volvió a comprobar el mismo código funcional y el estado final del progreso: `CAMP006_W03_PY PASS blocks=1 checks=17`, `CAMP006_W03_GODOT PASS blocks=1 checks=20`, regresión `CAMP005_W03_PY PASS blocks=10 checks=169` y `CAMP005_W03_GODOT PASS blocks=10 checks=208`. El bloque 01 se considera **piloto de navegación L2/L3 validado**, no una Cuerda Huida conectada al botón de mochila. El contrato transaccional de IA6 sigue pendiente.

---

# IA3/W03 — CAMP006 continuidad — 01/10

**Rama exclusiva:** `codex/calvo-items-20261104-w03-camp006`. **Bloque 01 `escape_rope`: PILOTO DEMO FUNCIONAL, NO AÚN ÍTEM USABLE DESDE BOLSA.**

La nueva lógica propia `modules/overworld/escape_rope_demo_pilot.gd` valida un ancla de retorno canónica `CaveExit → SurfaceCaveReturn` y alternativamente salida del edificio, usando `OverworldTraversalController.traverse_portal` sin modificar APIs de mundo, sesión, inventario o SaveV2. Test Godot `tests/gameplay/parallel_items_w03_campaign_006.gd` instancia `field_demo.tscn`, entra en cueva por portal real, retorna a superficie, guarda la sesión nativa con `field_native_bridge.save_game` y recupera posición/cantidad con `load_game`; verifica superficie sin ancla, movimiento bloqueado y no-consumo de ítem durante el piloto.

**CI de código comprobada:** [#41764044349](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41764044349), commit `425885a7182db2a7c9962f0a396fd22bf70b858e`, SUCCESS: `CAMP006_W03_PY PASS blocks=1 checks=17`, `CAMP006_W03_GODOT PASS blocks=1 checks=20`; CAMP005 regresión Python 169, Godot 208 PASS. Errores iniciales de tipado runner y preflight de movimiento resueltos y detallados en `CAMP_006_ITER_01.md`.

**TICKET DE PRODUCTOR COMPARTIDO A IA6, necesario para el siguiente bloque:** autorizar la interfaz transaccional `WorldItemCommand.use_world_item(escape_rope, expected_world_revision, expected_inventory_stamp)` y el propietario de `FieldItemBag/FieldItemService`, que hagan: validar bolsa y mundo → preparar consumo unitario → solicitar traslado seguro con adaptador → publicar inventario y posición juntos → guardar/cargar SaveV2 o rollback total. Probar fallo de disco, destino ocupado, combate activo, mochila corrupta, doble uso, revisión desactualizada. **NO IMPLEMENTAR** consumo/UI saltándose la autorización. Esto puede bloquear el bloque 02 entero; aplicar regla de detener la familia si el productor compartido no está asignado.

**Siguiente `p`: bloque 02 de la cola aprobada**, `escape_rope;fluffy_tail`, con evaluación del ticket anterior y no meras pruebas negativas. No iniciar otros bloques anticipadamente. Prohibido tocar `main`, V28, PR118, la rama de IA6, otras ramas o APIs compartidas.

