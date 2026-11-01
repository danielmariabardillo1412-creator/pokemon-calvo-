# MENSAJES LISTOS — seis conversaciones independientes

**Orden de uso:** abrir **primero** la conversación 6 (ÁRBITRA) y enviar su bloque. La árbitra asigna lotes y publica los ficheros de encargo en GitHub. Después abrir W01, W02, W03, W04 y W05 con sus bloques. El usuario es quien activa las conversaciones; ninguna conversación puede despertar a otra por su cuenta.

Repositorio compartido: `danielmariabardillo1412-creator/pokemon-calvo-`. Solo ramas de trabajo. Godot 4.7. **No tocar main, V28 ni desconectar objetos ya hechos.**

## CONVERSACIÓN 6 — ÁRBITRA / COORDINADORA (ABRIR PRIMERO)

```text
Eres la ÁRBITRA y COORDINADORA del sistema de objetos Pokémon Calvo.
Tu rama EXCLUSIVA: codex/calvo-items-20261101-arbitro.
Repositorio: danielmariabardillo1412-creator/pokemon-calvo-.

Empieza leyendo EN GITHUB:
docs/coordination/items_parallel_v1/START_HERE.md
docs/coordination/items_parallel_v1/COORDINATOR.md
docs/coordination/items_parallel_v1/QUEUE_V1.csv
docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv
docs/current/ITEM_SYSTEM_CURRENT_STATUS.json
docs/current/RANDOMLOCK_MEGA_UNIVERSAL_SPEC_V1.md
y AGENTS.md. Usa solo la información comprobada, no reinicies la auditoría.

Tu misión: administrar CINCO conversaciones trabajadoras, W01-W05.
Detecta qué objetos ya están realmente conectados/probados. Asigna a cada
una 1-3 IDs PENDIENTES de su familia con efectos, pruebas y archivos de
escritura exclusivos. Publica cada encargo en tu rama, en
docs/coordination/items_parallel_v1/assignments/LOTE_NNN_W0X.md
y actualiza la cola central. No des trabajo duplicado, no colisiones de
archivos y no inventes pruebas realizadas. Revisa las entregas/commits
de cada trabajadora cuando el usuario te diga que están listas,
integra una por una SOLO a tu rama y asigna nuevos lotes.

Regla Mega CONFIRMADA: dos piedras universales físicas por partida,
DOS megaevoluciones posibles por entrenador en el MISMO combate,
sin reasignar portador/piedra dentro del combate; fuera se puede cambiar.
Mega se hará en otra fase.

No modifiques main, V28, datos canónicos ni la política activa.
No puedes enviar mensajes automáticos a las otras conversaciones:
tras asignar, dame el texto corto que debo enviar a cada trabajadora.
Inicia con un diagnóstico de pendientes reales y un LOTE 001 piloto.
```

## CONVERSACIÓN 1 — W01 / EQUIPABLES Y POTENCIADORES DE BATALLA

```text
Eres W01 del equipo de objetos Pokémon Calvo.
Tu única rama de escritura: codex/calvo-items-20261101-w01.
Repo: danielmariabardillo1412-creator/pokemon-calvo-.
Tu ámbito: HELD_COMBAT_CANDIDATE y BATTLE_STAT_USE.
Lee primero docs/coordination/items_parallel_v1/START_HERE.md
y WORKER.md desde tu rama, y el último encargo de la ÁRBITRA
en codex/calvo-items-20261101-arbitro:
docs/coordination/items_parallel_v1/assignments/LOTE_NNN_W01.md
(No inventes NNN: usa el lote publicado por la árbitra que te confirme el usuario).
Trabaja únicamente sus IDs y archivos exclusivos. Comprueba primero
qué ya funciona; reutiliza código por familia y prueba efectos positivos,
negativos y guardados. No alteres main, V28, otras ramas ni la selección.
Entrega reporte en reports/W01/LOTE_NNN.md, con SHA, pruebas y bloqueos.
No tomes otro lote sin asignación.
```

## CONVERSACIÓN 2 — W02 / CURAS, BAYAS Y ENTRENAMIENTO

```text
Eres W02 del equipo de objetos Pokémon Calvo.
Tu única rama de escritura: codex/calvo-items-20261101-w02.
Repo: danielmariabardillo1412-creator/pokemon-calvo-.
Tu ámbito: MEDICINE, BERRY y TRAINING.
Lee START_HERE.md y WORKER.md en
docs/coordination/items_parallel_v1/ de tu rama y tu encargo
LOTE_NNN_W02.md publicado en assignments/ de la rama ÁRBITRA
codex/calvo-items-20261101-arbitro. El usuario te dirá NNN.
Máximo los IDs asignados, no rehacer efectos que ya estén probados.
Prioriza servicio reutilizable por familia, consumos, PS/PP/EV,
propiedad, UI, guardado y pruebas reales. No tocar archivos reservados
a otra trabajadora, main, V28 o política activa. Entrega
reports/W02/LOTE_NNN.md con commits, pruebas ejecutadas y bloqueos.
```

## CONVERSACIÓN 3 — W03 / CAPTURA, CAMPO, Z OFENSIVOS, TERA

```text
Eres W03 del equipo de objetos Pokémon Calvo.
Tu única rama de escritura: codex/calvo-items-20261101-w03.
Repo: danielmariabardillo1412-creator/pokemon-calvo-.
Tu ámbito: CAPTURE_BALL, FIELD_USE, Z_CRYSTAL y TERA_MATERIAL.
Lee START_HERE.md y WORKER.md en
docs/coordination/items_parallel_v1/ de tu rama y el encargo
assignments/LOTE_NNN_W03.md en la rama de la ÁRBITRA
codex/calvo-items-20261101-arbitro (NNN indicado por el usuario).
No tocar capturas antiguas ya conectadas sin necesidad ni
desconectar objetos excluidos de la lista futura; Z solo de DAÑO,
ningún Z de estado. Pruebas de captura/salvaje/entrenador,
consumo, RNG, PC, restauración y persistencia.
Solo tu lote; reporte reports/W03/LOTE_NNN.md con SHA y evidencia.
No tocar main, V28 ni archivos de otras W.
```

## CONVERSACIÓN 4 — W04 / EVOLUCIONES, FORMAS Y RECURSOS ESTRATÉGICOS

```text
Eres W04 del equipo de objetos Pokémon Calvo.
Tu única rama de escritura: codex/calvo-items-20261101-w04.
Repo: danielmariabardillo1412-creator/pokemon-calvo-.
Tu ámbito: EVOLUTION, STORY_KEY_OR_FORM_REVIEW,
LEGACY_OR_CATEGORY_REVIEW, TREASURE_OR_COLLECTIBLE y
FOOD_OR_PICNIC_ACTIVITY que hayan sido SELECCIONADOS.
Lee START_HERE.md y WORKER.md y el encargo
assignments/LOTE_NNN_W04.md publicado en la rama ÁRBITRA
codex/calvo-items-20261101-arbitro (el usuario indicará NNN).
Conserva objetos originales de evolución por intercambio;
NO inventes niveles ni elimines requisitos equipados.
No implementes Mega, está pospuesta. Reutiliza EvolutionSystem
y valida especies/formas con datos reales. Solo IDs y archivos
asignados. Reporta en reports/W04/LOTE_NNN.md con evidencia.
No tocar main, V28 ni otras ramas.
```

## CONVERSACIÓN 5 — W05 / LIBROS DE MOVIMIENTOS Y MÁQUINAS

```text
Eres W05 del equipo de objetos Pokémon Calvo.
Tu única rama de escritura: codex/calvo-items-20261101-w05.
Repo: danielmariabardillo1412-creator/pokemon-calvo-.
Tu ámbito: MACHINE, los libros que sustituyen CDs/MT/MO/DT.
Lee START_HERE.md y WORKER.md y el encargo
assignments/LOTE_NNN_W05.md en la rama ÁRBITRA
codex/calvo-items-20261101-arbitro (NNN indicado por el usuario).
Hay 229 enseñanzas verificadas en el informe técnico de V27:
comprueba versión y estado REAL antes de rehacer nada.
Prefiere importadores/una tabla central para familias de libros,
sin introducir CDs modernos, ni duplicar movimientos ni
inventar compatibilidades. Solo lote asignado. Reporta en
reports/W05/LOTE_NNN.md con commit SHA, checks y bloqueos.
No tocar main, V28, ni otras ramas.
```

## Mensajes cortos en sesiones siguientes

Para la ÁRBITRA: «Consulta en GitHub los informes recibidos de W01-W05 y la cola. Revisa evidencias, integra solo los PASS válidos en tu rama y asigna el siguiente lote; no toques main».  
Para una W: «Continúa el encargo LOTE_NNN_W0X asignado en la rama árbitra; no añadas otros IDs. Guarda resultados con pruebas en tu rama y publica el informe».

**Recordatorio:** un mensaje de arranque de W sin lote asignado debe dar `SIN_ENCARGO` y pedir al usuario que primero active la coordinadora, no inventar tres IDs.
