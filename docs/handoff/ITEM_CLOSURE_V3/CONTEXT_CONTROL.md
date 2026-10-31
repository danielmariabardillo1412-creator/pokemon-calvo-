# CONTEXT_CONTROL — Reanudar Pokémon Calvo sin releer el proyecto entero

Este es el **punto de entrada corto** para otras conversaciones/agentes que continúen la misión ITEM_CLOSURE_V3. No es una nueva autorización para tocar código ni un reemplazo de los contratos. La memoria entre chats se conserva en Git y en los enlaces CI, no en el contexto del modelo.

## Estado comprobado y alcance

- Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`.
- Base: `codex/organized-update-v27` (`e10b79a5eb8c3e83975a9f4f5b48d6615a85e1b7`).
- Trabajo: `codex/item-closure-v3`, [PR #117](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/117), borrador, sin fusionar. Verificar **su HEAD remoto**, no asumir que permanece igual.
- Código funcional validado: `c554ab7635fb847aa395d2dbb5bc523b560bc6de`. [CI #41217120667](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41217120667): 20/20 workflows PASS, incluidos Godot 4.7 Ubuntu y portable Windows. Resultado portable: `PUBLICATION_V27 PASS` (conexiones: 4.993 comprobaciones).
- Último commit documental antes de este protocolo: `78fb63cc03a123900b31eb34752e1c55d0b4491e`; solo modificaba los tres informes de la misión. Sus CI no constituyen una nueva validación funcional del código.
- Resultado V3: 2.222 IDs inventariados, no todos funcionales; 908 escenarios nativos en 65 IDs, 23.434 comprobaciones de proyección Godot, 94 de EV, 8.755 regresiones V18 y evidencia **acotada** de 72 IDs. Los siete entrenadores EV se cubren en dominio; solo `power_weight` tiene el recorrido V3 específico de combate real/mochila/guardado.
- Estado: `READY_FOR_REVIEW` **de esta misión**, no `ALL_ITEMS_DONE`. Inspección manual/GPU/visual local pendiente; economía, Exp. Share, mentas/IV persistentes, sistemas ausentes y futura evolución sin intercambio fuera de la misión. Main no debe tocarse.

## Entrada mínima de una conversación nueva

1. Leer **este archivo** y `STATE.json`. Consultar `PROGRESS.md` **por su última sección** para saber el siguiente paso; `WORK_ORDER.md` solo si se va a editar. `RESULTADOS.json` únicamente al necesitar detalles de evidencia, y solo las claves relevantes.
2. Consultar metadatos de PR #117: HEAD, base, draft y estado. Si HEAD no cambió desde el último checkpoint conocido, **no** repetir inventarios, descargas de datos, logs, auditorías ni lecturas de módulos ya revisados. Si cambió, usar comparación de commits y **lista de archivos modificados** antes de leer su contenido.
3. Respetar `AGENTS.md` y las decisiones humanas vigentes. De `docs/current/START_HERE.md`, `PROJECT_STATE.md`, `WORK_PROTOCOL.md`, otros cuadernos o el código, recuperar **solo la sección/contrato que se necesite** para resolver un cambio; comprobar que corresponde al commit. No leer los 164 documentos actuales en bloque.
4. No reabrir por un simple «sigue» familias cerradas ni las evoluciones aplazadas. Si la V3 está lista para revisión, el siguiente trabajo autorizado es revisar el alcance y la GPU/visual en el PC del propietario, o una nueva misión expresa.

## Presupuesto de consultas y evidencia

- Usar intermediarios que filtren los resultados **antes de presentarlos al modelo**: seleccionar propiedades, resumir arrays, limitar las líneas a lo pertinente. Objetivo rutinario ~1.500 tokens por respuesta de herramienta; **no es un límite para leer código necesario**.
- `fetch_file` con rangos `start_line/end_line`; buscar primero el símbolo o la ruta exacta. Expandir únicamente si una dependencia exige contexto cercano.
- En GitHub Actions: primero listado resumido de runs (`id/status/conclusion/head_sha`), luego jobs y steps. Descargar logs solo al encontrar fallo o discrepancia; procesarlos en una llamada intermediaria y mostrar el error + ~20–50 líneas próximas, nunca volcar miles de líneas al contexto.
- No declarar PASS por haber escrito pruebas, importado Godot o recibido exit 0 con cero asserts. Conservar run ID, commit, métricas, pasos y limitaciones. Las pruebas de UI en modo headless no sustituyen aprobación gráfica/GPU.
- Código o datos modificados → pruebas de la familia y sus regresiones; al cerrar el bloque, CI aplicable sin rebajar controles. Código **sin** cambios y evidencia válida del mismo SHA → no repetir solo para generar otro informe. Evitar commits y ejecuciones redundantes; nunca suspender guardas para ahorrar contexto.

## Persistencia obligatoria al cerrar un bloque

- `STATE.json`: estado por bloque, HEAD de código validado, pendiente y alcance; nunca marcar como hecho lo que no se ejecutó.
- `PROGRESS.md`: 5–12 líneas nuevas con qué cambió, qué se verificó, qué falló, decisiones y **siguiente acción exacta**.
- `RESULTADOS.json`: comandos/IDs de runs, SHA, resultados observables, enlaces CI y limitaciones; no duplicar logs íntegros.
- `WORK_ORDER.md`: lista autorizada de rutas antes de ampliarla; un único escritor, checkout de la rama V3, sin merge, force-push, resets destructivos ni reescritura de baselines.
- Documentar una vez por bloque, no por objeto. Ante interrupción, siguiente chat retoma el checkpoint. Si cambian ramas/contratos, verificar primero y actualizar este punto de entrada solo cuando sea material.

**Principio:** el cuaderno funciona como índice y traspaso; el código y las pruebas fijados por SHA son las pruebas de verdad. Ahorra lecturas, **no** rigor.
