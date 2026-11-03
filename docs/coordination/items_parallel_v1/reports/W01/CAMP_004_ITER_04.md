# IA1/W01 — CAMPAÑA_004 — Microbloque 04/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp004`. **IDs:** `psychic_seed;punching_glove;ring_target`. **Estado de publicación:** EN_CI_AUTOMATICA.

## Alcance y evidencia
Los tres objetos figuran SELECCIONADO en el catálogo. El motor ya contiene las mecánicas. Se han reutilizado el `held_effect_sweep_v3.cjs` (Semilla Psique, Blanco) y `held_effect_sweep_v2.cjs` (Guante de Boxeo). Se prueba su funcionamiento por el motor nativo y no un duplicado.

- **Semilla Psique:** Campo Psíquico eleva Def. Especial +1 y consume una unidad; Campo Eléctrico no activa ni consume. Controles sin objeto y reserva sin efecto.
- **Guante de Boxeo:** Puño Trueno potencia daño y evita Casco Dentado rival; Placaje no gana potencia y sí recibe daño de Casco; Agua Pistola no gana potencia ni recibe Casco. Objeto no consumible.
- **Blanco:** inmunidades por tipo suprimidas en Gengar/Placaje y Charizard/Terremoto solo equipados. Mew con Levitación conserva inmunidad a Terremoto en los tres modos; objeto retenido.

**Nuevos:** 8 escenarios, 13 pares y 39 variantes. **Acumulados:** 28 escenarios, 75 pares, 225 variantes. Todas comparan portador activo, no equipado y objeto en reserva, integridad del inventario, identidad, consumo, estado nativo y restauración SaveV2. No modificar CAMP003, production, workflows, main, V28, rama árbitra ni otras trabajadoras.

Bloque 03 cerrado documentalmente con run [#41590511208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41590511208), SHA `b9aa52cd282938221e1b2554132a31ce0189d886`. La limitación histórica de vista durante carga transitoria sin Hierba Única sigue pendiente para IA6 y no se declara reparada.

**CI bloque 04 pendiente:** verificar recibos `CAMP004_W01_PY PASS blocks=4 checks=M` y `CAMP004_W01_GODOT PASS blocks=4 checks=M`, y `completed/success` sobre SHA de pruebas. Si falla, diagnóstico y parche mínimo V5 solo en W01. Próxima `p` autorizada tras cerrar: bloque 05, no antes.

## Certificación final de CI — 04/10

**Run oficial:** [#41592180823](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41592180823), `completed/success` en el SHA funcional `ec13e1c6b30a58c8ac8c7c6bab3052d2ddec8699`. No hubo errores de validación ni pasos fallidos. Los recibos literales de Godot y Python son:

- `CAMP004_W01_MANIFEST_PASS reserved=10 completed=4 ids=30`
- `CAMP004_W01_PY PASS blocks=4 checks=388`
- `CAMP004_GATE_PY_PASS worker=W01 blocks=4 checks=388`
- `CAMP004_W01_GODOT PASS blocks=4 checks=6593`
- `CAMP004_GATE_GODOT_PASS worker=W01 blocks=4 checks=6593`

**Resultado:** 4/10 bloques certificados localmente, **12 equipables**, 28 escenarios, 75 pares caso-semilla y 225 variantes de equipamiento, con SaveV2 y negativos de mecánica. El bloque 04 añade 3 nuevos objetos, 8 escenarios, 13 pares, 39 variantes. No se modificaron módulos de producción ni la suite CAMP003.

**Limitaciones explícitas:** headless no es UI ni GPU; CI de rama no implica integración en `main`; el defecto de proyección transitoria SaveV2 mid-charge sin Hierba Única detectado en bloque 03 continúa pendiente de IA6 y no se declara solucionado. No se ejecuta aquí toda la regresión CAMP003: puerta oficial requiere esa regresión en los hitos 05/10 y 10/10, o tras parche de producción.

**Estado administrativo:** fila 04 del CSV conserva provisionalmente `EN_CI_AUTOMATICA` para evitar disparar una CI costosa solo por metadatos; prevalece la evidencia real de run+SHA anterior. En la próxima `p` cambiar esa fila a `CI_PASS_VERIFICADO` simultáneamente a la fila 05. **Próximo bloque autorizado:** 05/10 `room_service;scope_lens;shed_shell`, solo por nueva `p`.
