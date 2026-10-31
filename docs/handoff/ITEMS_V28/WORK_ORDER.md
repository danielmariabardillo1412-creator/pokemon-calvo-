# Orden de trabajo — ITEMS_V28

Autorización del usuario 31-10-2026: proseguir objetos sobre V27 *oficial*; trabajar incrementalmente, conservar los fallos, documentar cada cambio y pruebas; `main` queda estable y no se toca directamente.

Base inmutable de partida: `233b1a4f15ee4df7301e2c5acf8aed84a8f40626`, merge PR #116. Rama única `codex/items-v28-from-main` y PR en borrador hacia `main` (no merge automático).

## Bloque 0: recuperación comprobada de EV + matrices V3
Permitidos, copia exacta desde el checkpoint validado `c554ab7635fb847aa395d2dbb5bc523b560bc6de`:
- `modules/creatures/progression/battle_ev_rewards.gd`
- `modules/creatures/progression/progression_system.gd`
- `tests/gameplay/item_closure_v3_test_runner.gd`
- `tests/tools/test_item_closure_v3.py`
- `tools/item_audit/item_closure_v3.py`
- `tools/item_audit/stage_item_connections_ci_v3.py`
- `.github/workflows/item-closure-v3.yml`
- `docs/handoff/ITEMS_V28/{START_HERE.md,WORK_ORDER.md,STATE.json,PROGRESS.md,RESULTADOS.json}`.

Comprobar igualdades de blobs con V3, compatibilidad con V27 en `main`; ejecutar GitHub Actions Godot 4.7 Ubuntu + Windows portable y demás regresiones. Estado `NO_VERIFICADO_EN_V28` hasta resultados reales. No copiar los viejos cuadernos como si fueran pruebas nuevas.

## Bloques sucesivos
Elegir una familia pendiente usando `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json` y los cuadernos específicos. Anotar primero las rutas adicionales y contratos en este documento; separar entrada de catálogo, efecto del simulador, conexión juego/propietario/consumo, guardado y escenario ejercitado. Cerrar con pruebas y evidencias por SHA. No prometer todos los objetos mientras falten sistemas.

## Límites
No modificar main, node_modules, versión @pkmn/sim, motor de combate/RNG/protocolo, datasets, baselines, políticas de exclusión, recursos/hashes, guardas históricas, schema de partida o EvolutionSystem. Conserva los 14 objetos evolutivos originales y la exclusión de Linking Cord; no implementar aún sustitución de intercambios. Economía para Amulet Coin/Luck Incense, Exp. Share, mentas/IV, crianza/formas y mundo son dependencias, no ceros neutros. Sin shortcuts de calidad: los tests deben tener comprobaciones >0.


## Bloque 1: integración real ampliada de entrenamiento (sin cambios de motor)
Ampliar únicamente `tests/gameplay/item_closure_v3_test_runner.gd` ya permitido: por cada uno de `power_bracer/power_belt/power_lens/power_band/power_anklet/macho_brace`, probar con batalla nativa efectiva, restauración de checkpoint, recompensa al propietario, seis EV exactos, XP no bloqueada, persistencia, conservación del objeto e idempotencia del cierre. No sustituye la ruta física de mochila/mapa/guardado ya comprobada para `power_weight`; dejar el límite explícito. Fallos de objetos heredados se documentarán, no se ocultarán. Ejecutar CI Godot y portable antes de declarar éxito.

## Cierre verificado de bloques 0–1
Código probado en `69e15d74d04063dbe9613575b8618062e1efbed7`, 20/20 workflows PASS, run V28 #41220691787. Bloque 0 conserva siete blobs funcionales idénticos a V3 histórico; bloque 1 añade únicamente cobertura nativa EV para seis equipables (la ruta mapa/mochila sigue solo en `power_weight`). Incidencia de aserción en `c29db193` resuelta por comparación correcta del esquema serializado y comprobada en nuevo CI; no se ha cambiado el esquema. Los avisos de proceso hijo Ubuntu quedan como pendiente de diagnóstico, sin maquillar. Cualquier bloque 2 posterior debe declarar primero familia, consumidores y nuevas rutas, y dejar pruebas registradas por SHA.

## Bloque 2 — cierre de ruta mapa/mochila para toda la familia EV
Cambiar únicamente `tests/gameplay/item_closure_v3_test_runner.gd`, preservando los asertos anteriores: iterar los seis objetos `power_*` y `macho_brace` por un recorrido **aislado por cada ID** en `field_demo.tscn`, seleccionar y equipar el objeto desde la mochila, guardar/cargar, enfrentar un Caterpie en combate nativo, aplicar EV por las seis estadísticas, confirmar XP, titularidad, stock y guardado en disco. No duplicar mecánicas en el motor ni en UI. No afirmar cierre universal ni segundo combate por familia si no se ejecuta. Si falla, conservar SHA/ejecución y corregir el comportamiento real o el test, según evidencia. CI Ubuntu+Windows y regresiones completas antes de certificar.

## Cierre del bloque 2
Código `ae51793641b6981b4827524208b50f7a7c8e54a0`, 20/20 workflows GitHub PASS (run #41222946680). Siete recorridos físicos aislados mapa/mochila/combate/guardado, no solo equipados en dominio. Runner único ampliado; motor, adaptador, escenas, datos y política intactos. El fracaso previo de `f052b09c` (#41222565742) fue la aserción compuesta de recarga; la versión aprobada desglosa EV/XP/equipamiento/stats/stock por cada objeto, sin cambiar el contrato. Siguen pendientes pruebas GPU/manuales, mensajes de proceso auxiliares y familias dependientes. Cualquier nuevo bloque requerirá declaración de rutas/consumidores y CI por SHA; no reabrir estos siete sin motivo.


## Bloque 3 — captura de ultraentes con Ente Ball / beast_ball (autorizado)
**Rutas permitidas añadidas antes de editar:** `modules/capture/capture_ball_effects.gd` (módulo de reglas de dominio ya existente), `tests/gameplay/item_capture_beast_v28.gd` (nuevo verificador), `.github/workflows/item-closure-v3.yml` (añadir un único paso Ubuntu Godot 4.7); y cuadernos `docs/handoff/ITEMS_V28/{WORK_ORDER.md,STATE.json,PROGRESS.md,RESULTADOS.json,START_HERE.md}`. No tocar la UI/escenas, catálogo, esquema de guardado, motor/RNG nativo, tests/baselines históricos ni umbrales existentes.

**Contrato:** `beast_ball` usa multiplicador x5 contra los 11 ultraentes canónicos (Nihilego, Buzzwole, Pheromosa, Xurkitree, Celesteela, Kartana, Guzzlord, Poipole, Naganadel, Stakataka, Blacephalon); contra otros x410/4096. Generación VII+ como referencia de multiplicador, conservando explícitamente `calvo_capture_v1` (no afirmar equivalencia con la fórmula completa Gen IX). Referencia [Bulbapedia Beast Ball](https://bulbapedia.bulbagarden.net/wiki/Beast_Ball) y [lista de ultraentes](https://bulbapedia.bulbagarden.net/wiki/Template:Ultra_Beasts); no confundir Cosmog, Solgaleo, Lunala o Necrozma con esos 11 para esta mecánica. No añadir un registro nuevo al esquema ni asignar inventario/regalos a partidas.

**Pruebas exigidas:** multiplicador por especie (11 positivas + no-UB), matriz de captura e inventario con éxitos/fallos y control RNG, rechazos sin gasto, integración con partida nativa y selector de combate/mapa ya existente, guardado y restauración, no gasto duplicado. Asegurar >0 aserciones y casos; CI Ubuntu de misión y gate Windows existentes, 20 workflows completos; el último commit comprobado será la autoridad. La V15 histórica debe permanecer intacta (su lista de negativos no incluye `beast_ball`). Fuera de alcance: formas por Transform/Impostor, cambios de tipo de Net Ball, economía o entrega de Ente Balls, rutas de mundo o precisión completa de captura.
