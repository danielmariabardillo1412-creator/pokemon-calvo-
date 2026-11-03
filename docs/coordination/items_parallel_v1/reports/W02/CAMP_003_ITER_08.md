# IA2/W02 — CAMPAÑA_003 / BLOQUE 08 DE 10

**Estado:** `EN_CI_AUTOMATICA` — publicado en rama exclusiva `codex/calvo-items-20261103-w02-camp003`; no afirmar PASS nativo del bloque 08 ni de 06–07 sin un run `completed/success` con sus recibos.

**Autoridad:** `CAMPAIGN_GATE_003.md` (autopiloto `p`), `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. Únicamente fila `08,W02`.

## 4 bayas exactas, 8 escenarios nuevos

| ID | Activación nativa que se exige | Testigo negativo | Precedente |
|---|---|---|---|
| `roseli_berry` | Garchomp recibe `dazzling_gleam` de Hada supereficaz, daño inferior a testigos y consumo | `tackle` Normal, no reduce ni consume | `held_effect_sweep_v2.cjs` `resist.fairy` |
| `rowap_berry` | Mew recibe `confusion` especial; el rival pierde exactamente `floor(maxHP_rival/8)`; Rowap consume | `tackle` físico: mismo PS del atacante, no consume | `held_effect_sweep_v3.cjs` `category_retaliation` |
| `salac_berry` | Mew a 1/5 de PS gana +1 Velocidad con registro nativo `|-boost|p1a:|spe|` y consume | PS casi máximos, sin boost ni consumo | `held_effect_sweep_v2.cjs` `pinch_stat_berry` |
| `shuca_berry` | Pikachu recibe `bulldoze` de Tierra supereficaz, menor daño con consumo | `tackle`, sin reducción ni consumo | `held_effect_sweep_v2.cjs` `resist.ground` (el sweep usa `earth_power`; aquí se usa Bulldoze para evitar KO del testigo sin baya) |

**Ampliación Godot:** se reutiliza comparador de resistencias y `SaveGameRepository`; Rowap se integra en el mismo verificador real de HP rival y restauración que Jaboca, pero con familia `retaliate_special` y disparo de categoría especial, sin cambiar motor. Salac añade `boost_spe` y filtrado `|-boost|p1a:` con `|spe|`, evitando atribuir movimientos del rival. Los recibos SHA256 incluyen el incremento de Velocidad. Todos los casos se ejecutan en `active`, `none`, `reserve` y deben confirmar conservación de unidades, consumo único y SaveV2/FLED.

**Cobertura acumulada:** bloques 01–08 = 9+8+8+9+8+9+8+8 = **67 escenarios**, **201 variantes de combate previstas**, **32 bayas distintas**. Son expectativas de suite, no pruebas de éxito mientras la CI del último SHA esté pendiente. Python valida esquema `EXPECTED_08` estricto y 12 mutaciones de ataques, daños, categoría, tipo, umbral, boosts y IDs que deben ser rechazadas.

## Incidencia previa que NO debe ocultarse

**Último PASS funcional confirmado:** [Actions #41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763), bloques 01–05, `CAMP003_W02_PY PASS blocks=5 checks=327`, `CAMP003_W02_GODOT PASS blocks=5 checks=3612`.

**CI anterior 07 con FAIL REAL:** [Actions #41560981081](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560981081), Python `PASS blocks=7 checks=463`; Godot `FAIL blocks=6 checks=5073`. Se detectaron casos del bloque 06: Mago-Brave no coincidía con curva de curación tras auto-confusión, Maranga se atribuía a Amnesia propia, Occa-Flamethrower vencía al testigo Scizor y no permitía FLED. Múltiples mensajes de PID de `pipe_client.gd` en Linux son secundarios; los fallos de contrato se tratan por separado. **Ningún efecto se ha declarado funcionalmente erróneo sin aislar su testigo.**

**Corrección exclusiva de test W02:** fixture `dd0c3e9eaca1724fb525b24f1b56cd8238133feb` (Mago: Snorlax con 1 PS y Esfuerzo al final del turno, Maranga: Reflejo, Occa: Ascuas), Godot `9773e00baf10b23185a43657a473b5fff5852284` (inyectar HP de rival y diagnósticos sin reducir expectativa), Python `5faad6d8f95d8976e521c391611ca5affc1ca251` (contratos actualizados y negativos adicionales). Las reejecuciones de corrección se cancelaron al publicar el bloque 08 por `concurrency.cancel-in-progress`, no emitieron PASS final. Deben probarse **junto con el bloque 08**; cualquier FAIL nuevo exige diagnóstico o STOP según gate.

## Publicaciones de bloque 08

- `tests/fixtures/parallel_items/w02_campaign_003.json` — commit `6623c6a8b8a2e8f7db2c7e989736807a3a117f78`.
- `tests/gameplay/parallel_items_w02_campaign_003.gd` — commit `19e266594e233e375e5b1e21f6259d6f146d5aac`.
- `tests/tools/test_parallel_items_w02_campaign_003.py` — commit `6049e1cdd2a14ad43088535c476c0ccaad7ef34d`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv` — octava fila, commit `992b31cde4984d1c6ca3e1f87a192b96247f71f4`.

**CI actual:** [Actions #41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549), SHA de pruebas/progreso `992b31cde4984d1c6ca3e1f87a192b96247f71f4`. Se requieren exactamente `CAMP003_W02_PY PASS blocks=8 checks=M` y `CAMP003_W02_GODOT PASS blocks=8 checks=M` para certificar **06, 07 y 08** más regresiones 01–05. Inicialmente pendiente. No confundir `cancelled` con `success`.

**Seguridad:** 0 cambios de producción, `main`, V28, PR #118, catálogo, motor, workflows o ramas ajenas; solo tres archivos W02 de tests, su progreso y reportes. Sin prueba de campo ni GPU. Fallo de arnés: reparar sin debilitar; fallo funcional de motor/SaveV2: detener, comunicar IA6.

**Próxima `p`:** bloque 09 solamente `starf_berry;tanga_berry;wacan_berry;wiki_berry`, previa revisión del resultado CI de la fila 08 y de la cola oficial. No publicar bloque 10 hasta la siguiente orden.
