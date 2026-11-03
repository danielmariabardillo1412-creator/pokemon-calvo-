# IA1/W01 — CAMPAÑA_003, microbloque 09/10

**Identidad:** IA1/W01. **Rama exclusiva:** `codex/calvo-items-20261103-w01-camp003`. **Estado al publicar:** `EN_CI_AUTOMATICA`, sin PASS funcional nuevo del bloque 09. **Fila exacta de cola IA6:** W01/09 = `mirror_herb;muscle_band;protective_pads`, objetivo `cambio_de_portador`. Se añade solo cobertura de tests, no implementación de mecánicas. AUTONOMOUS_REPAIR_V5 permite arreglar fallos propios si CI revela un defecto.

## Evidencia histórica previa a cambios

| Objeto | Fuente ya existente | Escenario positivo y controles nativos nuevos |
|---|---|---|
| **Hierba Copia** (`mirror_herb`) | `tools/item_audit/held_effect_sweep_v3.cjs` blob `fd5d9d0b1eecf8b84f14e606631df93b40728586`: `positive_copy` tras `swords_dance`; `negative_not_copied` tras `growl` | El rival utiliza Danza Espada: solo el portador gana +2 Ataque y gasta una unidad (semillas 19,23). El rival usa Gruñido: el jugador baja a −1 en los tres modos, sin consumo (19) |
| **Cinta Fuerte** (`muscle_band`) | `held_effect_sweep_v2.cjs` blob `c9ba4d7bcddad6ae69f085f4b69983461ad05219`: `category_boost` con `tackle` | Placaje físico causa más daño únicamente con la cinta equipada en el actor (19,23). Agua Pistola especial no aumenta su daño (19). No consumible |
| **Paracontacto** (`protective_pads`) | `held_effect_sweep_v2.cjs`: `contact_protection` contra un rival con `rocky_helmet` | Con Casco Dentado en rival, Placaje de contacto causa daño al atacante sin Paracontacto, pero no al portador (19,23). Agua Pistola contra el mismo Casco Dentado no causa daño por contacto (19). Placaje ante un rival **sin** Casco Dentado tampoco (19). No consumible |

**Implementación de pruebas:** el fixture añade el campo opcional `foe_item` solo a los casos de Casco Dentado; se equipa realmente en `prepared.foe.held_item_id` y se comprueba desde el estado de batalla nativo. El runner contrasta objetos activos, ausentes o en reserva y compara PS, boosts, consumo, stock y los estados después de restaurar SaveV2. Para Cinta Fuerte se permite diferencia de daño **únicamente en su escenario positivo**, con aserción explícita de incremento; controles anteriores siguen sin alteración.

**Bloque 09:** siete escenarios, diez pares caso-semilla y 30 variantes. **Acumulado W01 01..09:** 61 escenarios, 118 pares caso-semilla y 354 variantes. Los 54 casos anteriores y las pruebas para 24 IDs de 01..08 se conservan sin alteraciones.

## Publicación, validación y CI

- Fixture `tests/fixtures/parallel_items/w01_campaign_003.json`: commit `8b6b94e579b013833ae004fdec9871556ebf3acb`, blob `57e195bb7924bc2b19217ba9d538c13b02d05034`.
- Runner `tests/gameplay/parallel_items_w01_campaign_003.gd`: commits `e678f1a453ae3f3a994ea88b604d33fcfea9e443` y `facb84a47bbe3e1df1a8096bf78a2a8d5636107c`, blob final `4ba47ddd5df3c42976387f7326ed3be6612a8080`.
- Validador `tests/tools/test_parallel_items_w01_campaign_003.py`: commit `aba72c8dddf98160810a1cf55d46dc4977b7b194`, blob `ec300498f622a51939166a5966b30dbf460804e7`. `SCENARIOS_09` exige los siete casos, especies, comandos, `foe_item` y semillas exactas, historial V2/V3 y total 61/118.
- `CAMP_003_PROGRESO.csv`: commit `dc636ff178d5d46a381b24407dcbde0ae3795732`. Filas 04–08 convertidas a `CI_PASS_VERIFICADO` sobre evidencia **real** [#41569533376](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41569533376): `CAMP003_W01_PY PASS blocks=8 checks=649`, `CAMP003_W01_GODOT PASS blocks=8 checks=9780`, `completed/success`, 0 errores. Fila 09 `EN_CI_AUTOMATICA` a la espera de nueva ejecución.
- Auditoría estática de estructura, alcance, causalidad, preservación SaveV2 y contratos: **26/26 verificaciones correctas**. Esto **no es** todavía veredicto funcional de stage 09.
- **GitHub Actions W01/09** [#41571425044](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571425044), SHA disparador `dc636ff178d5d46a381b24407dcbde0ae3795732`, `in_progress` al registrar. Debe emitir `CAMP003_W01_PY PASS blocks=9 checks=M` y `CAMP003_W01_GODOT PASS blocks=9 checks=M` con M positivo y conclusión `success`; la CI volverá a ejecutar todas las familias anteriores. Los runs previos cancelados al subir tests no se califican como falla de mecánica.

**Riesgos y límites:** si CI falla en W01, analizar logs y reparar autónomamente según V5, manteniendo todas las aserciones y regresiones; solo intervención de IA6 ante conflicto real, arquitectura compartida o denegación de permisos. La CI headless no acredita GPU/UI, settlement ni integración completa al salir al mapa.

**Siguiente `p`:** comprobar primero CI de 09; si no hay fallo sin resolver, ejecutar únicamente **bloque W01/10 `quick_claw;red_card;rocky_helmet`**. Tras 10/10 y CI validada, detener y comunicar `CAMPAÑA_003_FINALIZADA`. Nunca crear 11.
