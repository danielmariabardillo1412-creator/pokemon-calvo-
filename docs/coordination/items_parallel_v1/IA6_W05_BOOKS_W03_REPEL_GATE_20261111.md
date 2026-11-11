# IA6 — Puerta de integración W05 libros + W03 repelentes (2026-11-11)

## Certificación que sí existe
- Rama candidata W05: `codex/calvo-ia6-candidate-w05-books-20261111`.
- CI `43069884972`: completed/success, SHA `05213cdcb996a80c252a95738fe002112df031b9`.
- Alcance de la CI: import Godot 4.7, 229 nombres ES PokeAPI, veto dynamax_candy, panel único de libros, enseñanza/consumo/SaveV2 en mochila real, humo IA6 de Cuerda Huida y mentas.
- La CI NO certifica repelentes ni integración oficial ni Windows visual/Android.

## Inspección de ramas
- Fuente histórica W03 `codex/calvo-items-20261104-w03-camp006`:
  - `scenes/visual/field_item_bag.gd`: blob `b09970f8e9802a51538a40050ff3cebc3e6fab6e`, contiene `_apply_repel`.
  - `scenes/visual/field_demo.gd`: blob `517bd48d1bcdd9376a5032f8c4261e29042f7bde`, contiene `_repel_effect` y `blocked_by_repel`.
  - `scenes/visual/field_native_bridge.gd`: blob `238d0fd0e7f090d8ee975f2e5c3c744c1ef63011`, contiene `blocked_by_repel`.
- Candidata W05:
  - mochila: blob `12907d0dfdc040686dc3385c27bcef8ffda1e1d9`, contiene `_open_machine_books` y `_on_book_teaching_finished`; todavía NO `_apply_repel`.
  - demo: blob `e71bd44b8d9819058e7cbe9eee0483e87e469c65`, carece `_repel_effect`.
  - bridge: blob `14571ab0dedf0f789064c2137baa49c279cbe44a`, carece `blocked_by_repel`.
- W03 V4 actual: `codex/calvo-ia6-staging-20261111-w03-capture`, informe `CONTINUOUS_V4/STATE_W03.md`, CI `43068968046` SUCCESS para captura nativa/legacy; repelentes señalados como dependencia aparte.

## Puerta siguiente, sin engañar cobertura
1. Partir del HEAD de esta candidata, no sustituir los tres archivos enteros por versiones históricas W03.
2. Trasplantar exclusivamente las funciones/hunks de repelentes desde el origen W03, preservando libros, Cuerda Huida, naturaleza efectiva y los cambios de IA6.
3. Validar `repel`, `super_repel`, `max_repel`: gasto exactamente 1, 100/200/250 pasos, bloqueo sólo con líder aplicable, RNG, cancelación/rollback, SaveV2 manual y encuentros después de agotarse los pasos.
4. Ejecutar en la misma CI prueba cruzada nativa de libros/repeles/Cuerda Huida; además de regresión W03 y W05 adecuada al SHA del candidato.
5. Solamente después de SUCCESS del SHA exacto evaluar un trasplante selectivo a la rama oficial de IA6. No tocar main/V28/PR118.

**Estado:** LIBROS CANDIDATO CI VERDE; REPEL SHARED SEAM PENDIENTE; INTEGRACIÓN OFICIAL NO. Este documento es diagnóstico, no certificación nueva de código.
