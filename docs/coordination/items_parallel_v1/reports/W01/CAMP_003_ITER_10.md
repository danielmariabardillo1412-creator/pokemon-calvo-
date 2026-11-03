# IA1/W01 — CAMPAÑA_003 · Bloque 10/10, último autorizado

**Estado de entrega:** microbloque 10 publicado con `EN_CI_AUTOMATICA`. **Todavía no se declara `CAMPAÑA_003_FINALIZADA`**, pendiente de CI Godot del bloque 10. Rama exclusiva `codex/calvo-items-20261103-w01-camp003`. Fila oficial IA6 W01/10 = `quick_claw;red_card;rocky_helmet`, objetivo `regresion_savev2`. Protocolo autónomo V5 para reparaciones locales de W01; sin modificar producción, `main`, V28, workflows o ramas ajenas.

## Mecánicas y controles realmente ensayados

| Equipable | Fuente nativa preexistente (solo lectura) | Escenarios nuevos y afirmación comprobable |
|---|---|---|
| **Garra Rápida** — `quick_claw` | `tools/item_audit/held_effect_sweep_v3.cjs`, `order_rng` (64 semillas históricas, log de `item: Quick Claw`, `onFractionalPriority`) | `quick_claw_order_rng`: Mew contra Gengar, Placaje de misma prioridad, semillas **1..12**; comprobar que el rival es primero sin objeto o con objeto en reserva, y que el portador solo mueve primero si el **log nativo registra activación**. El runner **exige al menos una activación y una no-activación** observadas, sin inventar probabilidades. `quick_claw_priority_control`: Ataque Rápido (+1 prioridad) actúa antes en los tres modos (semilla 19). Nunca consumible |
| **Tarjeta Roja** — `red_card` | `tools/item_audit/held_pilot.cjs`, `red_card` provoca `roster[1].active_id = foe_reserve`, `onAfterMoveSecondary`, inventario `HELD_PILOT_VERIFIED` | `red_card_forced_foe_switch`: combate nativo **de entrenador** con dos Pokémon rivales `foe` y `foe_reserve`, tras recibir Placaje el portador consume una unidad y obliga al oponente a entrar con `foe_reserve` (semillas 19 y 23); los controles de ausencia/reserva no fuerzan cambio. `red_card_no_damaging_hit`: Amnesia rival no cambia ni consume (19) |
| **Casco Dentado** — `rocky_helmet` | `held_pilot.cjs`, contacto de `tackle` resta `floor(max_hp_rival/6)`, `onDamagingHit`, inventario `HELD_PILOT_VERIFIED` | `rocky_helmet_incoming_contact`: Placaje rival origina retroceso de **1/6 de sus PS máximos** y log de `[from] item: Rocky Helmet` solo con portador, conservando el casco (19/23); `rocky_helmet_noncontact`: Agua Pistola no origina retroceso ni consumo (19) |

**Integración:** cada caso usa `FieldItemService` para equipar activo/ninguno/reserva, `Native` para combate verdadero, el log del motor, propietario y stock, más `_restore_probe` para reabrir la **misma instantánea SaveV2** sin alterar resultados. Para Tarjeta Roja se cambia únicamente la configuración de pruebas al `begin_trainer` nativo con reserva rival real; no se modifica el motor ni la lógica funcional.

**Cobertura nueva:** 6 escenarios, 19 pares caso-semilla, 57 variantes. **Total acumulado CAMPAÑA_003 W01:** **67 escenarios, 137 pares y 411 variantes de equipamiento**, 30 IDs de los 10 bloques. Se preservaron los 61 casos y 118 pares de 01..09.

## Evidencia y publicación

- Fixture `tests/fixtures/parallel_items/w01_campaign_003.json`: commit `5353296f19a9e1e1bcfbd263b61e08f7e74e4e82`, blob `c2978b20c96fec22ba66cb5e44968176d14f9fcb`.
- Godot `tests/gameplay/parallel_items_w01_campaign_003.gd`: commit `2d1f2cac4ccede409d02386ea26b4045aaf62e06`, blob `9850857bc57b292d31cd5ea40823f0df65e9a850`. Se mantienen los arreglos V5 de Botas Gruesas, Bola Férrea y Cola Plúmbea.
- Python `tests/tools/test_parallel_items_w01_campaign_003.py`: commit `8c6b28a44d3a6909ae721ea0e12974ba79d6ba09`, blob `2852951e3cd0e3edfdb90aaf95e73c7e4b6ee797`. Contrato exacto 67/137, pruebas nativas históricas y semillas declaradas (12 únicamente para rama RNG `quick_claw_order_rng`).
- CSV `reports/W01/CAMP_003_PROGRESO.csv`: diez filas, commit disparador de CI `5f93a652b353dd54f3f85da4672f04514cc5fca3`: 01–09 `CI_PASS_VERIFICADO`, 10 `EN_CI_AUTOMATICA`.
- Última CI confirmada **09/10**: [#41571425044](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571425044), `completed/success`, recibos `CAMP003_W01_PY PASS blocks=9 checks=723` y `CAMP003_W01_GODOT PASS blocks=9 checks=10689`. Todas las regresiones 01–09 aprobadas.
- Nueva CI final **10/10**: [#41574042928](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574042928), SHA `5f93a652b353dd54f3f85da4672f04514cc5fca3`, `pending` al redactar. Se exige `CAMP003_W01_PY PASS blocks=10 checks=M` y `CAMP003_W01_GODOT PASS blocks=10 checks=M` y conclusión `success`; no confundir auditoría estructural (28/28) con PASS funcional.

## Cierre y límites

**Próxima acción:** comprobar la nueva CI del último bloque. Si fallan test, RNG, montaje de entrenador o límite de tiempo, resolver autónomamente **solo en rutas W01**, conservando causalidad y regresiones; elevar a IA6 únicamente conflictos de otras trabajadoras, permisos reales o cambios compartidos. Una vez CI `success`, actualizar CSV con run de 10 y crear `CAMP_003_FINAL.md` con toda la evidencia; entonces anunciar **`CAMPAÑA_003_FINALIZADA`** y STOP. No existe bloque 11. Esta ejecución no sustituye comprobación manual de UI/GPU ni resultado de partida hasta regreso al mapa.
