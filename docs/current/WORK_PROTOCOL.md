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

## 3. Cadena de snapshots certificados

Hasta que el usuario cambie expresamente esta política:

- el siguiente tramo parte del último HEAD certificado exacto;
- no se parte de `main` por costumbre;
- el PR se abre contra el snapshot inmediatamente anterior cuando sea práctico;
- se exige la matriz normal de workflows en verde sobre el SHA exacto final;
- el PR certificado se cierra **sin merge**;
- ese HEAD pasa a ser el parent del siguiente tramo.

`main` sigue siendo histórica hasta que se sustituya deliberadamente en una operación separada.

## 4. Regla de SHA exacto

Un resultado de CI solo certifica el SHA sobre el que se ejecutó.

Si se cambia código, tests, workflows o documentación después de quedar verde, el HEAD nuevo necesita su propia validación cuando vaya a formar parte de la cadena certificada.

No repetir dos ciclos por ritual: se repiten cuando existe un HEAD previo distinto que fue validado y después se modifica. Una rama exclusivamente documental puede cerrarse con un único ciclo completo si ese ciclo se ejecuta sobre su HEAD final exacto.

## 5. Matriz de regresión

El baseline de partida de esta reorganización tiene 18 workflows normales:

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
- Trainer Team Composition.

Si la matriz aumenta o cambia, `PROJECT_STATE.md` debe describir el nuevo contrato; no conservar el número 18 por inercia.

## 6. DATA V3

No confundir:

- dato presente en PokéAPI;
- dato preservado por V3;
- mecánica ejecutable fielmente por Battle Core.

Los límites `RUNTIME_SUPPORTED`, `PARTIAL_RUNTIME`, `DATA_ONLY` y `UNSUPPORTED` son contratos, no objetivos estéticos de cobertura.

`data/api/v2` y `data/schema/v2` son fuentes inmutables. No modificar JSON canónico manualmente.

## 7. Memoria documental

Cada descubrimiento material, excepción, corrección, decisión arquitectónica, certificación o diferimiento debe quedar fuera del chat:

- cambio del estado real → `docs/current/`;
- conocimiento acumulado de un dominio → cuaderno en `docs/project_book/`;
- decisión arquitectónica duradera → ADR;
- diario cerrado / evidencia histórica → `docs/history/worklogs/`.

No crear un archivo nuevo por cada microtramo. Actualizar el cuaderno temático existente y archivar worklogs cuando una fase cierre.

## 8. Recuperación de contexto

Una sesión nueva debe:

1. leer `docs/current/START_HERE.md`;
2. leer `PROJECT_STATE.md` y `NEXT_STEPS.md`;
3. leer solo el cuaderno temático necesario;
4. comprobar en GitHub el branch/HEAD/PR mencionado;
5. verificar CI antes de modificar;
6. continuar desde el último HEAD certificado, no desde `main` por su nombre.

## 9. Regla de honestidad técnica

No subir contadores, aparentar soporte o ampliar la IA solo para que el proyecto parezca más avanzado.

Una limitación demostrada y documentada es preferible a una aproximación silenciosa que cambia las reglas del juego.
