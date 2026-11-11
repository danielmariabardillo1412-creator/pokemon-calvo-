# IA3/W03 — Ticket único IA6: contexto auténtico para las bolas regionales

**Misión:** `CONTINUOUS_V2/PLAN_W03.md`, B02 filas 09–10 y B03 filas 01–05; además Safari/Sport parciales.

## Diagnóstico verificable
El productor nativo en `modules/gameplay/showdown_adventure_session.gd::capture` sólo construye contexto desde la sesión: `is_wild`, `target_side_id`, `completed_turns`, nivel del capturador y el historial `previously_caught_base_species` autenticado por el propietario. El `CaptureBattleContext` no tiene campos de procedencia de pesca/buceo/surf, fase de luz/cueva, sexo individual, peso de forma, línea evolutiva lunar, categoría de ultraente o eventos de zona Safari/Concurso.

Las reglas de `CaptureRuleset` registran 18 bolas ya existentes. Las siete indicadas a continuación **no están registradas** en el dispatch; su mera presencia en catálogo de objetos no autoriza habilitarlas. El validador `tests/tools/test_parallel_items_w03_continuous_v2_sources.py` controla esta frontera y se ejecutará como QA de la campaña.

| ID | Dependencia auténtica necesaria | Estado autorizado |
|---|---|---|
| `dive_ball` | Origen real de encuentro: pesca, surf y/o submarinismo según reglas definitivas | `BLOCKED_CONTEXT` |
| `dusk_ball` | Hora/cueva/oscuridad de la zona, producida por mundo, compatible con SaveV2 | `BLOCKED_CONTEXT` |
| `lure_ball` | Encuentro originado verdaderamente por pesca y modalidad de pesca | `BLOCKED_CONTEXT` |
| `love_ball` | Sexo real del salvaje y del capturador según especie, formas sin ambigüedad | `BLOCKED_CONTEXT` |
| `moon_ball` | Catálogo canónico de línea que evoluciona mediante Piedra Lunar, forma/versionado | `BLOCKED_CONTEXT` |
| `heavy_ball` | Peso canónico en la forma activa y reglas de signo/tasa, sin inventarlo en prueba | `BLOCKED_CONTEXT` |
| `beast_ball` | Clasificación canónica Ultraente y política de multiplicador/tasa | `BLOCKED_CONTEXT` |
| `safari_ball` | Bandera real de zona Safari o política que autorice aplicación incondicional ×1,5 | `PARCIAL_ZONE` |
| `sport_ball` | Evento de concurso de captura de bichos o política de uso incondicional ×1,5 | `PARCIAL_ZONE` |

## Petición a IA6
No habilitar ninguna de las siete bolas sin productor de datos autenticado, fuente canónica, orden de precedencia y tests positivos/negativos por mapa y guardado. Confirmar si Safari/Sport deben permanecer deliberadamente incondicionales o si se restringen a eventos reales. Autorizar una seam mínima, con owner y consumidor claros, **en una campaña distinta** cuando estén disponibles las dependencias.

## Restricciones
No tocar `CaptureBattleContext`, `PlayerCollection`, `SaveV2`, generadores compartidos, `FieldItemBag`, `main`, V28, PR118 ni otras ramas por este ticket. No atribuir a las bolas bloqueadas objetos L3, ni simular estados del mundo con flags fabricadas en tests.
