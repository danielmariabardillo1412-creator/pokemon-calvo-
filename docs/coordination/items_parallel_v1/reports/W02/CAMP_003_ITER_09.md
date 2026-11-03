# IA2/W02 — CAMPAÑA_003 / BLOQUE 09 DE 10

**Entrega:** bloque 09 publicado exclusivamente en `codex/calvo-items-20261103-w02-camp003`, `EN_CI_AUTOMATICA` mientras no aparezca recibo Godot del SHA `93bd706149928f63c2cf5cd318ce4a32fa013bc8`. No iniciar bloque 10 con esta `p`.

**Autoridad:** `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, fila `09,W02`; `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. `AUTONOMOUS_REPAIR_V5.md` blob `ebe71ace6949cc9311eb9831068799081bca8ba7` permite resolver defectos propios, no autoriza cambios en `main`/V28 ni reglas ajenas.

## Nueve escenarios nuevos de cuatro bayas exactas

| Baya | Escenarios y controles funcionales | Evidencia histórica |
|---|---|---|
| `starf_berry` | Mew a 20 % PS consume y suma **exactamente +2 en una única estadística aleatoria** entre `atk,def,spa,spd,spe`, con las otras cuatro a 0; Mew casi lleno conserva baya y los cinco modificadores a 0 | `held_effect_sweep_v3.cjs`, `one_random_stat` y `full_hp` |
| `tanga_berry` | Mew ante `bug_buzz` Bicho supereficaz reduce daño y consume; `tackle` Normal sin cambio/consumo | `held_effect_sweep_v2.cjs` tabla `resist.bug` |
| `wacan_berry` | Gyarados ante `thunder_shock` Eléctrico 4× supereficaz reduce daño y consume; `tackle` Normal sin cambio/consumo | `held_effect_sweep_v2.cjs` tabla `resist.electric`; Thunder Shock de potencia moderada ya presente en test histórico de Enigma, evita KO de testigo |
| `wiki_berry` | Mew de naturaleza `adamant` recibe Esfuerzo de Snorlax con 1 PS, cura `floor(maxHP/3)` y se confunde; naturaleza `hardy` cura sin confusión; con HP altos y `adamant` no consume | `held_effect_sweep_v3.cjs` perfil de `wiki_berry,adamant` y testigos de sabor |

**Prueba fuerte de Starf:** el runner no acepta una simple línea `consumed`. Inspecciona `session._checkpoint.roster[].pokemon[].boosts` del combatiente `own` después del turno, captura cinco valores nativos, comprueba **uno y solo uno con +2** y suma total +2, y exige que no haya boosts en controles `none/reserve`. Comprueba persistencia de ese vector al restaurar checkpoint y asocia el recibo JSON/SHA256 al vector. No fija de antemano el atributo aleatorio ni depende de una llamada RNG simulada.

**Propiedad, SaveV2 e integración:** para cada escenario se ejecutan los tres modos `active/none/reserve` con semilla fijada, una transacción nativa por modo sobre `@pkmn/sim` Godot 4.7, prueba de revisión obsoleta, comparación contra testigos, equipo/inventario (dos unidades), restore de checkpoint real, FLED con Poké Muñeco, ausencia de doble cierre, `SaveGameRepository.decode_snapshot` y evidencia autenticada SHA256. Se conservan los 67 escenarios de bloques 01–08. No se prueban efectos de campo ni GPU.

**Cobertura:** 9 + 8 + 8 + 9 + 8 + 9 + 8 + 8 + 9 = **76 escenarios** para **36 bayas**, **228 variantes nativas previstas**. Cuatro IDs nuevos, 9 escenas nuevas y 27 variantes. Contrato `EXPECTED_09` con schema exacto, fuentes V2/V3 verificadas y **15 mutaciones adversariales adicionales** (azar +1 en lugar de +2, usuario con Danza Espada, umbral, resistencias, naturaleza, HP rival, consumo y objetos no autorizados).

## Commits y CI

- Fixture `tests/fixtures/parallel_items/w02_campaign_003.json`: `62aa15f89b2ab49e1c097f4f888ff1ff33263e1d`.
- Godot `tests/gameplay/parallel_items_w02_campaign_003.gd`: `9af9ddf3df656ba416acf217df0a86b1ede749a1`.
- Python `tests/tools/test_parallel_items_w02_campaign_003.py`: `df292337f4f2ccb69bb35e8e04e807051f7daee6`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv`: novena fila commit `93bd706149928f63c2cf5cd318ce4a32fa013bc8`.

**Última CI funcional VERIFICADA:** [Actions #41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549), `completed/success`, SHA `992b31cde4984d1c6ca3e1f87a192b96247f71f4`, `CAMP003_W02_PY PASS blocks=8 checks=535`, `CAMP003_W02_GODOT PASS blocks=8 checks=5795`. Certifica 01–08 y las reparaciones del bloque 06, **no este bloque 09**.

**CI nueva:** [Actions #41566220523](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41566220523), sobre el SHA de tests/progreso `93bd706149928f63c2cf5cd318ce4a32fa013bc8`, inicialmente `pending`. Se requieren recibos `CAMP003_W02_PY PASS blocks=9 checks=M` y `CAMP003_W02_GODOT PASS blocks=9 checks=M`, mismo SHA. Los runs anteriores intermedios cancelados por `concurrency.cancel-in-progress` **no cuentan como éxito ni fallo nativo**.

**Autoría, independencia:** la rama también contiene un cambio de workflow introducido por IA6 en el commit `43876a6d833958d2d7ad86ce15014b011778007a`, no modificado por W02. Todos los commits del bloque 09 se limitan a fixture, prueba, validador, progreso y documentos W02. No fusionar ramas ni alterar `main`, V28, PR #118, funciones de otras trabajadoras, arquitectura compartida o reglas globales.

**Acción próxima:** la siguiente orden `p` autoriza **solo bloque 10/10**: `yache_berry;grepa_berry;hondew_berry;pomeg_berry`. Primero consultar CI y reparar cualquier fallo propio sin relajar aserciones, según V5. Al completar bloque 10 emitir el informe de cierre y STOP.
