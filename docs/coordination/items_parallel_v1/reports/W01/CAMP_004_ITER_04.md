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
