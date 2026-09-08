# PROTOCOLO DE TRABAJO

Estas reglas existen para poder continuar el repositorio durante sesiones largas sin perder el estado real ni certificar accidentalmente un SHA distinto del que se pretende conservar.

## 1. No acumular fallos

Para cada tramo:

1. investigar primero;
2. acotar el cambio;
3. añadir o usar una prueba que represente la verdad buscada;
4. ejecutar el gate focal;
5. si falla, detener el avance y encontrar causa raíz;
6. corregir la causa y repetir focal + regresiones;
7. continuar solo cuando esté verde.

Nunca construir trabajo nuevo encima de un fallo no explicado.

## 2. Orden de autoridad

Cuando haya contradicción:

1. commit/PR/CI/artefactos del SHA exacto;
2. fuente canónica o inmutable del dominio;
3. `docs/current/`;
4. arquitectura y ADR;
5. cuadernos temáticos;
6. historial/worklogs;
7. memoria del chat.

No editar fuentes inmutables para hacer pasar tests.

## 3. `main` vuelve a ser el baseline canónico

La política histórica de encadenar snapshots cerrados sin merge terminó con la consolidación certificada de 2026-09-08.

Baseline canónico de entrada a Game Foundation V1:

`main = d2ad6796a93e6db56ef24c98431a3909e3874cdf`

Ese SHA pasó la matriz completa vigente entonces (**18/18 SUCCESS**) y absorbió por fast-forward el linaje moderno certificado.

A partir de aquí:

- cada workstream nuevo parte del `main` certificado exacto;
- se trabaja en una rama dedicada;
- el PR se abre contra `main`;
- el HEAD final de la rama debe pasar el gate focal y la matriz normal completa;
- cuando se promueva, preferir fast-forward de `main` al **mismo SHA ya certificado** cuando la topología lo permita;
- si una estrategia de merge crea un SHA nuevo distinto, ese nuevo SHA no se considera certificado hasta ejecutar sus gates aplicables;
- no volver a una cadena de snapshots cerrados sin merge salvo decisión explícita nueva del usuario.

## 4. Regla de SHA exacto

Un resultado de CI solo certifica el SHA sobre el que se ejecutó.

Si se cambia código, tests, workflows o documentación después de quedar verde, el HEAD nuevo necesita su propia validación cuando vaya a conservarse.

No repetir ciclos por ritual. Se repiten cuando existe un HEAD distinto o cuando un fallo de infraestructura deja el gate formalmente rojo. Un fallo de infraestructura puede reintentarse, pero debe quedar investigado y documentado si afecta a una certificación.

## 5. Matriz de regresión

Desde Game Foundation V1 la matriz normal contiene **19 workflows**:

- Data Foundation V3
- Godot 4.7 global
- Spanish Types Foundation
- Trainer Battle Session
- Trainer Intelligence Foundation
- Trainer Tactical Intelligence
- Trainer Belief Inference
- Trainer Search Foundation
- Trainer Search Depth Budget
- Trainer Self Play Evaluation
- Trainer Evaluation Corpus
- Trainer Search Limit Benchmark
- Trainer Adaptive Branching
- Trainer Public Coverage Beliefs
- Trainer Item Actions
- Trainer Strategic Switching V2
- Trainer Loadouts
- Trainer Team Composition
- **Game Foundation Tests**.

`Game Foundation Tests` es obligatorio para cualquier HEAD de GF1 y para las regresiones futuras que puedan afectar campaña/mapas/eventos/save de mundo.

Si la matriz aumenta o cambia, `PROJECT_STATE.md` debe describir el nuevo contrato; no conservar el número 19 por inercia.

## 6. DATA V3

No confundir:

- dato presente en PokéAPI;
- dato preservado por V3;
- mecánica ejecutable fielmente por Battle Core.

Los límites `RUNTIME_SUPPORTED`, `PARTIAL_RUNTIME`, `DATA_ONLY` y `UNSUPPORTED` son contratos, no objetivos estéticos de cobertura.

`data/api/v2` y `data/schema/v2` son fuentes inmutables. No modificar JSON canónico manualmente.

## 7. Fronteras de Game Foundation

Game Foundation convierte los subsistemas ya certificados en un videojuego, pero no absorbe su autoridad:

- `PlayerCollection` sigue siendo dueño de Party + Storage + Inventory;
- `CreatureInstance` sigue siendo la identidad persistente de cada criatura;
- Battle Core sigue siendo autoridad de combate;
- Trainer AI sigue siendo consumidor no autoritativo de información sanitizada;
- `GameCampaignState` es dueño solo del estado de campaña/mundo que le corresponda;
- Save V2 permanece congelado hasta GF1-D; GF1-A..C no deben colar persistencia de mundo dentro del schema V2.

## 8. Memoria documental

Cada descubrimiento material, excepción, corrección, decisión arquitectónica, certificación o diferimiento debe quedar fuera del chat:

- cambio del estado real → `docs/current/`;
- conocimiento acumulado de un dominio → cuaderno en `docs/project_book/`;
- decisión arquitectónica duradera → ADR;
- diario cerrado / evidencia histórica → `docs/history/worklogs/`.

No crear un archivo nuevo por cada microtramo. Game Foundation V1 usa un único cuaderno `GAME_FOUNDATION.md` durante GF1-A..GF1-F.

## 9. Recuperación de contexto

Una sesión nueva debe:

1. leer `docs/current/START_HERE.md`;
2. leer `PROJECT_STATE.md` y `NEXT_STEPS.md`;
3. leer solo el cuaderno temático necesario;
4. comprobar en GitHub el `main` y branch/HEAD/PR mencionados;
5. verificar CI antes de modificar;
6. continuar desde el último HEAD certificado del workstream o, al abrir uno nuevo, desde el `main` certificado.

## 10. Regla de honestidad técnica

No subir contadores, aparentar soporte o ampliar la IA solo para que el proyecto parezca más avanzado.

Una limitación demostrada y documentada es preferible a una aproximación silenciosa que cambia las reglas del juego.
