# ESTADO ACTUAL DEL PROYECTO

## Línea moderna certificada

El último freeze funcional/documental moderno antes de consolidar `main` es:

`8552f52158ffc21c27b4e8f1dbc7caa63ac1a467`

Resultado verificado sobre ese SHA:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus: **628 PASS / 0 FAIL**;
- Trainer AI runtime 26.67 — CLOSED / COMPLETED;
- Game-Ready 27.1 — CLOSED / VALIDATED;
- Expertise V1 — CLOSED / CERTIFIED / FROZEN;
- Campaign Persistence V1 — CLOSED / CERTIFIED / FROZEN.

No existe P1-E ni queda una tranche Trainer AI obligatoria activa.

## Consolidación de `main`

La antigua `main` estaba en:

`641d4b1fb0bcf964205d616e96f198f05d702197`

Ese commit divergía del linaje moderno únicamente por añadir un archivo vacío `this_should_not_be_called`; no contiene una feature del juego que deba conservarse en el árbol final.

La operación autorizada de consolidación vive en:

`chore/main-baseline-consolidation-v1`

Merge histórico inicial:

`2f63312e8dc3e61c8fadbd02e97972fff6d0eacc`

Propiedades del merge inicial:

- parent 1: antigua `main` `641d4b1f...`;
- parent 2: freeze moderno `8552f521...`;
- tree exacto: `89835a6797989a8ef027b6b17baea206b1f97f74`, el mismo tree del freeze moderno;
- no arrastra `this_should_not_be_called`;
- no introduce cambios de producción respecto de `8552f521...`.

La promoción de `main` solo queda autorizada cuando el HEAD final de esta rama, incluida la actualización documental, pase la matriz normal completa. GitHub/CI sobre ese SHA exacto es la autoridad.

## DATA V3

Estado: **CERRADO / CERTIFICADO**.

Contrato canónico preservado:

- 1.025 especies;
- 326 formas;
- 18 tipos runtime;
- 919 movimientos;
- 373 habilidades;
- 2.222 objetos;
- 61.102 entradas de learnset;
- 554 evoluciones.

Frontera ejecutable relevante:

- Moves: 590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED;
- Abilities: 21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY;
- Evolutions: 391 RUNTIME_SUPPORTED / 149 DATA_ONLY / 14 UNSUPPORTED;
- held items runtime: `leftovers`, `sitrus_berry`;
- trainer bag runtime: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.

No reabrir DATA V3 por subir contadores. Ampliar mecánicas solo cuando una necesidad concreta del juego lo exija.

## Trainer AI — cerrado

El entrenador de combate dispone de memoria bilateral sanitizada, beliefs sin información oculta, búsqueda acotada, MOVE/SWITCH/ITEM donde corresponda, switching estratégico, loadouts/composición, proposal sobre todas las raíces legales, sustitución autónoma side_b, tie resolution game-ready, integración real Overworld/Battle Core, victoria/derrota/reset, full-battle adversarial, estilos/expertise y persistencia de roster entre combates.

Checkpoint técnico final P1-D:

`b314b8bb81db439e3063433644c691181ed39ef4`

Evidencia final:

- P1-D: **46/46 PASS**;
- Evaluation: **628 PASS / 0 FAIL**;
- full technical CI: **18/18 SUCCESS**.

No reabrir C3f, Game-Ready 27.x, Expertise V1 ni Campaign Persistence V1 salvo regresión reproducible o feature nueva explícita.

## Estado del videojuego visible

El ejecutable actual sigue arrancando en:

`res://scenes/overworld/technical_overworld.tscn`

Ese mundo es una vertical slice técnica asset-free. Ya demuestra movimiento, colisión, encuentros salvajes, captura, switching, combate de entrenador, IA, settlement y revancha/recovery explícitos, pero **no es todavía una campaña completa**.

Los sistemas base ya existentes incluyen:

- Battle Core;
- criaturas/progresión/evolución dentro de la frontera runtime;
- captura;
- party/storage;
- inventario;
- Save V2 de criaturas + party + storage + inventory;
- encuentros/overworld técnico;
- localización base;
- Trainer AI cerrada.

## Siguiente workstream de producto

Tras consolidar `main`, el siguiente trabajo obligatorio deja de ser Trainer AI y pasa a ser **Game Foundation V1**.

Objetivo: convertir los cimientos certificados en una primera mini-campaña reproducible sin depender todavía de arte final.

Orden previsto:

1. game state global y contrato de campaña;
2. infraestructura de mapas/transiciones/spawn points;
3. NPC + diálogo + flags/eventos data-driven;
4. Save V3 para mundo/campaña;
5. servicios básicos (curación, tienda, PC/party UI mínima);
6. vertical slice jugable: inicio + inicial + pueblo + ruta + encuentro salvaje + entrenador + servicio + guardar/cargar;
7. después, rival autónomo de overworld y producción de contenido.

## Invariantes externos durante la consolidación

- PR #105 permanece OPEN / unmerged;
- PR #106 CLOSED / not merged;
- PR #107 CLOSED / not merged;
- no mezclar la consolidación de `main` con nuevas features de Game Foundation hasta certificar la promoción.
