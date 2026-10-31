# ITEM_CLOSURE_V3 — orden activa (2026-10-31)

Base exacta: `e10b79a5eb8c3e83975a9f4f5b48d6615a85e1b7` de `codex/organized-update-v27`. Única rama de escritura: `codex/item-closure-v3`; destino de PR: `codex/organized-update-v27`. Misión remota nueva autorizada, sin reactivar paquetes históricos.

## Bloques y criterios
A. Inventario reproducible por ID/familia/contexto: definición != efecto != conexión != escenario ejercitado; estados de dependencia y exclusión independientes. Fuente de verdad: catálogo, política, código actual y resultados identificados por checkpoint; los informes anteriores son antecedentes, no PASS automático.
B. EV tras derrotas del resultado de combate y objetos Macho Brace + seis Power. Generación de referencia: reglas de EV de Gen VII–IX (Power +8, 252 por característica, 510 total, nivel 100 elegible); Macho Brace x2 heredado. **XP y su reparto siguen `calvo_progression_v1`**, sin Exp. Share ni Pokérus. El equipamiento no se infiere en momentos que no registra el combate: documentar conservadurismo de recompensas.
C. Escenarios masivos de equipados y bayas que realmente active el simulador fijado, con efectos verificables y límites donde no se pueda reproducir contexto; nunca sustituir el motor.
D. Regresiones, CI y revisión consolidada, sin reclamar cierre total del catálogo.

## Archivos permitidos (lista cerrada inicial)
- `docs/handoff/ITEM_CLOSURE_V3/WORK_ORDER.md`, `STATE.json`, `PROGRESS.md`, `RESULTADOS.json` y referencias nuevas únicamente dentro de este paquete.
- `tools/item_audit/item_closure_v3.py` (nuevo, solo lectura del código/datos; salida bajo `.godot/item_closure_v3/`).
- `modules/creatures/progression/progression_system.gd`, `progression_held_items.gd`, y nuevo `battle_ev_rewards.gd`.
- `tests/gameplay/item_closure_v3_test_runner.gd` (nuevo) y `tests/tools/test_item_closure_v3.py` (nuevo).
- `.github/workflows/item-closure-v3.yml` (nuevo CI específico).
- `tools/item_audit/stage_item_connections_ci_v3.py` (nuevo, solo fixtures efímeras para CI Windows, lectura de fuentes primarias y perfil fijado; no modifica módulos ni datasets).

Ampliar esta lista **en este documento antes** de editar otros módulos. No tocar field_demo, mochila, adaptador nativo, node_modules, motor de combate, RNG, protocolo, datos, arte, políticas, guardados, EvolutionSystem, verificadores/baselines históricos o hashes.

## Condiciones de aceptación
- Separar los destinatarios de XP existentes (supervivientes del equipo de victoria), las fuentes de EV por especie derrotada y bonificaciones por propietario efectivo.
- Límites 252/510, sumas sucesivas, nivel 100, recálculo de stats y PS, preservación de partida y doble cierre.
- Referencias: Bulbapedia Effort values y Power item, revisión de 2026-10-31, URLs en PROGRESS; versión de generación explícita y sin alterar repartos de XP.
- Ejecutar test de familia y regresiones; documentar estado ejecutado/no ejecutado, conteo positivo y enlaces propios de CI. GPU/manual puede quedar pendiente sin declararlo superado.
- Antes de concluir comparar los archivos de commits con esta allowlist y contrastar CI. Una importación sola o cero aserciones no constituyen aprobación.
