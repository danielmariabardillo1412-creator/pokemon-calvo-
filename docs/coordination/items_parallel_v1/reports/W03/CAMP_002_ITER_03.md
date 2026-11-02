# W03 / CAMPAÑA_002 — ITER_03 / decisión por bola y regresión de Net

**Identidad:** IA3/W03. **Rama exclusiva:** `codex/calvo-items-20261102-w03-camp002`.
**Estado de entrega:** `03/03 PUBLICADO — PREPARADO_EN_CI_AUTOMATICA` (el cierre no significa que Ocaso/Acopio/Buceo funcionen).

## Autoridad y resultados anteriores realmente comprobados
- `campaigns/CAMP_002_W03.md` blob `96ec7241e2fad9f3c9f411a555649979c77b3953`, gate ITER_02 `CAMPAIGN_002_ITER02_CI_GATE.md` blob `ee1feb63c70f9146d7200b3460c37f19e1cecb06`, protocolo `CI_AUTOPILOT_V3.md` blob `7b1ec84bc1ca0477498cafa6fdf52f603307041e`. **Autoriza solo tests/contratos/reports, sin edición de producción.**
- ITER_01: W03 9 tests estáticos PASS en [CI #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) staging `967002fcbf26a1159d3a14a020e8921b34cfab8f`.
- ITER_02: 11 tests Python y 37 negativos Godot PASS, 0 errores, en [CI #41493879869](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493879869) staging `6a5562dd97225d86fd9b2fb994b247aadc33f98e`. CI autónoma de W03 [#41539840311](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539840311) `completed/success` sobre `b0897ea0de533579c199e41c4a4e8ef8bc7fd7fd`; los commits posteriores previos a ITER_03 fueron documentales.
- **ITER_03 tests/fixture nuevos:** commit `44ab67c16eb30e5a3f7044b1b13ff9da1d0dace5`, corrección puntual de un test `754b1ece5039a01da79144e9db60ea774cca6b13`. Blobs: fixture `d55fa7b87864ff4d4058dd737505b42bbd560b10`; Godot `f469b38be329b239306806a4c01c08acef2980d9`; Python `34371e7c0284813ccc863ffaed7badbb6d5fa305`. **Nueva CI #41547276442 en cola al verificar; #41547253548 anterior en curso y podrá cancelarse por `cancel-in-progress`. No hay PASS confirmado de ITER_03 a esta fecha.**

## DECISIÓN TÉCNICA: tres dependencias, ninguna implementación autorizada

| ID / bola | Referencia fijada en Essentials | Señal indispensable y productora confiable | Decisión |
| --- | --- | --- | --- |
| `dusk_ball` / Ocaso | Noche o cueva, ×3 con perfil moderno (×3,5 anterior), ×1 en otro caso. `battle.time == 2`. | Mundo/reloj de juego y entorno verificado de encuentro → sesión Wild/Showdown → contexto de captura. `field_demo.gd` conoce cueva pero no la transmite; no usar reloj del runner ni turnos. | **DEPENDENCIA_DE_CONTEXTO** |
| `repeat_ball` / Acopio | Especie previamente registrada `battle.pbPlayer.owned?(battler.species)`, ×3,5 moderno (×3 anterior), ×1 si no. | Historial autoritativo de *especies capturadas anteriormente* (no simple vista, equipo o PC actual), transacción de captura y persistencia. Definir criterio especie/formas y migración de SaveV2 antes de tocar esquema. | **DEPENDENCIA_DE_CONTEXTO** |
| `dive_ball` / Buceo | Entorno `:Underwater`, ×3,5 o ×1. | Bioma/encuentro realmente subacuático → sesión de captura. Tipo Agua, pesca o zona de cueva no son indicadores suficientes. | **DEPENDENCIA_DE_CONTEXTO** |

Referencia exacta e inalterada: Pokémon Essentials commit `8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`, `Data/Scripts/011_Battle/007_Other battle code/010_Battle_PokeBallEffects.rb`, blob `3deb95a4d4a38e51bf6950a4702f73e06a806c6f`; perfil gen ≥7 desde `002_BattleSettings.rb` blob `550a358751fba061adf3978460382de3dc3ab556`. **El multiplicador es un contrato de referencia, no una característica conectada**.

## Regresión sin duplicación de código
- `tests/gameplay/parallel_items_w03_campaign_002.gd`: mantiene todas las pruebas negativas de ITER_02; añade `_test_regresiones_net_v11_v15()` con **4 especies reales**: Magikarp ×3,5 (Agua), Caterpie ×3,5 (Bicho), Pidgey ×1 (Normal), Surskit ×3,5 (Agua+Bicho, solo una vez). Compara adaptador real, probabilidad del `CaptureRuleset`, consumo único, RNG e identidad si éxito. **No reimplementa fórmula ni reejecuta matrices históricas enormes**.
- Relee `item_capture_v11.gd` y `item_capture_v15.gd` sin modificarlos: ambas listas de `unsupported` deben **excluir Net**; V15 conserva **Acopio como no habilitada**. Exige preservación de la regresión V11 de entrenador y de probabilidad/propiedad V15.
- `tests/tools/test_parallel_items_w03_campaign_002.py` amplía de 11 a **14 tests estáticos**: expectativas Net/V11/V15, tres contratos de contexto por separado, y presencia de regresión Godot. Se corrigió en test_12 el ID normalizado devuelto por `ids_adaptador()` (`"net_ball"`, sin sintaxis GDScript `&`).
- `tests/fixtures/parallel_items/w03_campaign_002.json` añade `phase_03` y `decision_03` para cada bola, productor de señal, procedencia, persistencia, casos positivos futuros y prohibiciones. Los positivos de Dusk/Repeat/Dive **no** se ejecutan ni se simulan con campos falsos.

## Solicitud de gate a IA6: SOLICITUD_IA6 / DEPENDENCIA_DE_CONTEXTO
1. **Ocaso:** decidir reloj nocturno de juego y criterio de cueva; definir datos validados por mundo + reconstrucción al entrar/restaurar encuentro, para **ambas sesiones**. Pruebas futuras: día exterior ×1, noche exterior ×3, día cueva ×3 y sin fuente → rechazo sin coste.
2. **Acopio:** definir Pokédex persistente con bit de especie **capturada**, no poseída actualmente; transacción de actualización únicamente en captura exitosa; resolución de forma/especie, migración/compatibilidad de guardados V2 y captura/soltado. Pruebas: nunca capturada ×1, liberada tras captura ×3,5, vista no capturada ×1 y reinicio/carga.
3. **Buceo:** definir señal fiable de encuentro subacuático desde mapa/bioma, no tipo del objetivo; para ambas sesiones y recuperación de checkpoint. Pruebas: subacuático ×3,5; aguas superficiales/pesca/Agua en tierra ×1; fuente ausente → rechazo sin coste.
4. Solo con **nuevo gate** puede una IA editar `CaptureBattleContext`, sesiones, persistencia/SaveV2 o adaptadores. Reutilizar `CaptureInventoryService`, `CaptureSystem`, `CaptureRuleset`, RNG y selector existentes; evitar duplicados. IA6 debería fijar versión de perfil moderno antes de autorizar código.

## Evidencia y límites
- Inspección de blobs/estructura por GitHub: **revisada**; CI de ITER_03 **SIN VEREDICTO REAL AL REDACTAR**. Ejecutar por workflow automático `parallel-camp002-worker-autoci.yml`: Python 14 tests y Godot `CAMP_002_W03_NEGATIVE` con `new_balls_functional=false` y status PASS, bajo SHA real del último commit de tests.
- El workflow comprueba negativos + regresiones Net acotadas, **no** constituye una certificación de las tres bolas nuevas; no verifica GPU/visuales ni migraciones futuras.
- **STOP formal 03/03:** no ejecutar ITER_04, CAMPAÑA_003 ni cambiar producción por futuras `p`. `main`, V28, PR #118, ramas anteriores y otras W intocables.
