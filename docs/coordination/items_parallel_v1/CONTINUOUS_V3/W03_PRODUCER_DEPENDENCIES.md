# IA3/W03 · V3 · Ticket de productores y dependencias para IA6

Rama propietaria: `codex/calvo-items-20261104-w03-camp006`.
Misión: `CONTINUOUS_V3/PLAN_W03.md`, aprobada en la nota propia `IA6_AUTORUN.md`.

## Fase A — evidencia fuente y fronteras

La auditoría ejecutada en checkout real (CI [#42956984681](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42956984681)) examinó **1.025 especies canónicas y 57 regionales**. Las seis con `EvolutionRecord.item_id == moon_stone`, trigger `use_item`, target canónico y `version_group` auténtico son: `nidorina`, `nidorino`, `clefairy`, `jigglypuff`, `skitty`, `munna`. El dato histórico de `version_group` es procedencia de la evolución (p. ej. `red_blue`), no significa que dejaran de evolucionar en generaciones posteriores. Ninguna de esas seis figura en las exclusiones de especies de `config/randomlock_content_v1.json`.

En `data/api/v2/pokemon/35/index.json` el origen PokeAPI de Clefairy conserva `weight: 75` **hectogramos**, pero el adaptador `tools/pokeapi_adapter_v3.py` no vuelca peso a `CreatureSpecies.source_metadata`, `CreatureSpecies` no tiene propiedad `weight`, y `DefinitionCatalog` no expone tal valor por especie/forma en batalla. Inventar 75 para toda la línea o calcular un multiplicador sobre datos sin unidad y forma sería incorrecto. Heavy requiere además política de **suma/resta de tasa** (no mero multiplicador) y versión de mecánica.

La fuente normalizada y los 57 regionales no contienen un campo explícito `is_ultra_beast` ni equivalente. No deducirlo de `generation_vii`, `egg_groups`, `is_legendary` o tipos: Nihilego, Stakataka, Celesteela no tienen marcado Ultraente, Mewtwo sí tiene `is_legendary`, que no significa Ultraente. **Sin fuente canónica no hay motor Beast Ball válido.**

## Dependencias fuera de permisos W03 (un único ticket de origen de mundo)

| Identificadores | Productor real ausente | Consumidor previsto | Estado |
|---|---|---|---|
| `heavy_ball` | Enlace por forma activa desde `pokemon/<id>/index.json.weight` en hectogramos hacia catálogo de combate, con versión, política de tasa y test de formas | `ShowdownAdventureSession.capture` → `CaptureSystem` | `BLOCKED_CONTEXT`, solo datos L2 de origen |
| `beast_ball` | Taxonomía canónica Ultraente de fuente de datos verificable/versionada (no lista supuesta) | `ShowdownAdventureSession.capture` → `CaptureSystem` | `BLOCKED_CONTEXT` |
| `dive_ball` | Evento de pesca/surf/buceo real y edición de regla regional | Contexto de captura inmutable del encuentro | `BLOCKED_CONTEXT` |
| `dusk_ball` | Oscuridad/noche/cueva auténtica de mapa/reloj, fuente y persistencia estable | Contexto de captura de mundo | `BLOCKED_CONTEXT` |
| `lure_ball` | Inicio de encuentro por pesca (no especie tipo Agua ni flags inventadas) | Contexto de captura de mundo | `BLOCKED_CONTEXT` |
| `love_ball` | Sexo individual real de capturador y objetivo en especie/forma, no gender_rate probabilístico | Contexto de captura de combate | `BLOCKED_CONTEXT` |
| `safari_ball` | Política definida de zona Safari, o decisión IA6 que valide explícitamente factor incondicional actual ×1,5 | Efecto existente `CaptureBallEffects` | `PARCIAL_ZONE` |
| `sport_ball` | Productor real del Concurso de Captura de Bichos, o política IA6 que valide ×1,5 incondicional | Efecto existente `CaptureBallEffects` | `PARCIAL_ZONE` |

**Pruebas mínimas exigidas a IA6 al desbloquear:** negativo si falta fuente, entrada con versión/forma erróneas, contexto creado por el productor real de campo, consumo/RNG/propiedad/SaveV2 y regresiones Repeat, Net, Moon y tienda/selección. El dueño de cada seam compartida debe autorizar la edición; W03 no tocará `CreatureInstance`, `PlayerCollection`, SaveV2, RNG, `FieldItemBag`, generadores, reloj, pesca ni sexo.

## Incidencia técnica independiente: Magikarp nivel 5

Ya reproducida sin confundir con una bola: el encuentro falla en `move_policy` **antes** del lanzamiento y sin pérdida de inventario/partido; control positivo Goldeen nivel 5 en el mismo propietario y tabla de encuentro funciona. Script `tests/gameplay/parallel_items_w03_continuous_v2_magikarp_probe.gd` (44 checks en CI V2). Investigar selector de learnset y política con propietario de módulo; **NO editar motor general** desde W03.

## Moon Ball ya desbloqueada; no solicitar más permiso para ella

`modules/capture/capture_source_w03_v3.gd` deriva `moon_context` desde `CreatureSpecies.evolutions` y `DefinitionCatalog`; el módulo exige evolución `use_item` con `moon_stone`, target existente, `version_group` explícito y contrato de evolución sin condiciones ocultas. `CaptureBattleContext` recibe solo campos aditivos seguros; el nativo pasa el ID base de objetivo y deja otros contextos sin cambio. `CaptureContextBallEffects` aplica ×4 a las seis especies, ×1 en el resto, con validación obligatoria de fuente. Perfil explícito: `moon_ball_gen7_plus_v1`.

La CI [#42957635224](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42957635224) demuestra 41 comprobaciones nativas PASS: Clefairy x4 con fallo RNG y captura posterior, Goldeen x1, ownership, stock y SaveV2. **No hay que volver a crear un objeto Moon Ball nuevo; estaba en el inventario/catálogo, pero no registrado como bola funcional.**

## Decisión pendiente IA6

Autorizar productores compartidos **por separado**, con fuente real, modelo de confianza y CI propia. No promover Heavy/Beast/Dive/Dusk/Lure/Love, ni declarar completas Safari/Sport, por simple presencia de IDs. La integración central en IA6 sigue **pendiente**, aunque W03 termine su propia CI.
