# W03 / CAMPAÑA_002 — ITER_02: referencia fijada y negativos de captura

**Fecha:** 2026-11-02. **Estado:** `PREPARADO_PENDIENTE_CI`. IDs exclusivos: `dusk_ball`, `repeat_ball`, `dive_ball`.
**Permiso:** puerta `CAMPAIGN_GATE_002.md` blob `2fceaa04646db8a9538f3d3693c85b6e67422fd6`, CI ITER_01 gate blob `12e9c3021e80f9e03e0f9b0e900853b9a7e6a513`, encargo `CAMP_002_W03.md` blob `96ec7241e2fad9f3c9f411a555649979c77b3953`.
**CI previa real:** [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741), SHA `967002fcbf26a1159d3a14a020e8921b34cfab8f`, `success` para 9 contratos Python del bloque 01 **solo estático**, no efectos de bolas.

## Referencia externa exacta, inmutable
**Pokémon Essentials (Maruno17)** commit `8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`, archivo [010_Battle_PokeBallEffects.rb](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/011_Battle/007_Other%20battle%20code/010_Battle_PokeBallEffects.rb), blob `3deb95a4d4a38e51bf6950a4702f73e06a806c6f`. Ya fijado por `docs/current/ITEM_CAPTURE_V11.md` / V12 / V15, **no se trae ni ejecuta Ruby**.
| ID | Línea Ruby | Condición exacta de referencia | Gen ≥7 | Gen anterior | Fuera condición |
| --- | ---: | --- | ---: | ---: | ---: |
| `dusk_ball` | 85–89 | `battle.time == 2`: noche o cueva | ×3 | ×3,5 | ×1 |
| `repeat_ball` | 73–77 | `battle.pbPlayer.owned?(battler.species)`: especie previamente registrada como propia | ×3,5 | ×3 | ×1 |
| `dive_ball` | 61–64 | `battle.environment == :Underwater` | ×3,5 | ×3,5 | ×1 |
El switch genacional deriva de [002_BattleSettings.rb](https://github.com/Maruno17/pokemon-essentials/blob/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b/Data/Scripts/002_BattleSettings.rb), blob `550a358751fba061adf3978460382de3dc3ab556`: `NEW_POKE_BALL_CATCH_RATES = (MECHANICS_GENERATION >= 7)`. **No significa que `calvo_capture_v1` implemente estos bonos o la fórmula oficial.**

## Evidencia creada solo en rama `codex/calvo-items-20261102-w03-camp002`
- Fixture existente ampliado `tests/fixtures/parallel_items/w03_campaign_002.json`: referencia SHA/lineas, multiplicadores normativos, `current_expected_status=unknown_ball` y política `NEGATIVE_CHARACTERIZATION_ONLY`; commit `d70d3b8aa2bd48a4524d7012d976a0179cea1a0f`, blob `09d387e36acc7e4bbddd07f3a2f2f7fde4956a21`.
- GDScript nuevo `tests/gameplay/parallel_items_w03_campaign_002.gd`: commit `89d7ec1193c964f03db3c7efe0de3e897ba949a7`, blob `ccb45a1c31be3385b7bf7520c31a536b457eaaa6`. Exige que las 3 sigan sin registrar, `unknown_ball` tanto con contexto por defecto como turno/nivel real, ausencia de consumo/avance RNG/mutaciones, y prioridad de rechazos entrenador/combate finalizado/KO. Protege registro de `net_ball` y `poke_ball`. **No simula cuevas, reloj o Pokédex**.
- Python ampliado `tests/tools/test_parallel_items_w03_campaign_002.py`: 11 contratos en total, incluye comprobación de referencia fijada y alcance de GDScript; commit `fe0772cd27459b0cf19c2a659570acfcccd3786f`, blob `f91e4b8d30fbbe80b92a8bbaf919e607856c2d50`.
- **Verificación ejecutada aquí:** revisión manual del Ruby exacto en GitHub más `STATIC_REVIEW_PASS` al inspeccionar los blobs GitHub, sin discrepancias; **Python actualizado: SIN_EJECUTAR, Godot nuevo: SIN_EJECUTAR, CI iteración 02: SIN_EJECUTAR, GPU: SIN_EJECUTAR**. Ningún `FUNCIONAL_PASS` nuevo.
- **Reproducción para IA6:** `python tests/tools/test_parallel_items_w03_campaign_002.py`, y `godot --headless --path . --script tests/gameplay/parallel_items_w03_campaign_002.gd` tras importar Godot 4.7; registrar SHA, salida `CAMP_002_W03_NEGATIVE` y código final. El éxito de este GDScript certifica únicamente **rechazo correcto de bolas aún no conectadas**.
- **Dependencias:** Ocaso requiere reloj/zona confiables; Acopio requiere registro histórico persistente de especie (no equipo/PC actual); Buceo necesita entorno subacuático real. No hay positivos ejecutables sin cambiar contratos compartidos, lo que **no está autorizado**.
- **Siguiente `p`: ITER_03**, emitir decisión por bola `DEPENDENCIA_DE_CONTEXTO`, defensa contra duplicación de Net/V11/V15, matriz final y solicitud concreta a IA6. No activar efectos por la siguiente tecla.
- **Prohibiciones respetadas:** cero producción, contexto, RNG, datos, save, selector, `.github`, main, V28, otras W; IA4 congelada.
