# Orden de trabajo — ITEMS_V28

Autorización del usuario 31-10-2026: proseguir objetos sobre V27 *oficial*; trabajar incrementalmente, conservar los fallos, documentar cada cambio y pruebas; `main` queda estable y no se toca directamente.

Base inmutable de partida: `233b1a4f15ee4df7301e2c5acf8aed84a8f40626`, merge PR #116. Rama única `codex/items-v28-from-main` y PR en borrador hacia `main` (no merge automático).

## Bloque 0: recuperación comprobada de EV + matrices V3
Permitidos, copia exacta desde el checkpoint validado `c554ab7635fb847aa395d2dbb5bc523b560bc6de`:
- `modules/creatures/progression/battle_ev_rewards.gd`
- `modules/creatures/progression/progression_system.gd`
- `tests/gameplay/item_closure_v3_test_runner.gd`
- `tests/tools/test_item_closure_v3.py`
- `tools/item_audit/item_closure_v3.py`
- `tools/item_audit/stage_item_connections_ci_v3.py`
- `.github/workflows/item-closure-v3.yml`
- `docs/handoff/ITEMS_V28/{START_HERE.md,WORK_ORDER.md,STATE.json,PROGRESS.md,RESULTADOS.json}`.

Comprobar igualdades de blobs con V3, compatibilidad con V27 en `main`; ejecutar GitHub Actions Godot 4.7 Ubuntu + Windows portable y demás regresiones. Estado `NO_VERIFICADO_EN_V28` hasta resultados reales. No copiar los viejos cuadernos como si fueran pruebas nuevas.

## Bloques sucesivos
Elegir una familia pendiente usando `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json` y los cuadernos específicos. Anotar primero las rutas adicionales y contratos en este documento; separar entrada de catálogo, efecto del simulador, conexión juego/propietario/consumo, guardado y escenario ejercitado. Cerrar con pruebas y evidencias por SHA. No prometer todos los objetos mientras falten sistemas.

## Límites
No modificar main, node_modules, versión @pkmn/sim, motor de combate/RNG/protocolo, datasets, baselines, políticas de exclusión, recursos/hashes, guardas históricas, schema de partida o EvolutionSystem. Conserva los 14 objetos evolutivos originales y la exclusión de Linking Cord; no implementar aún sustitución de intercambios. Economía para Amulet Coin/Luck Incense, Exp. Share, mentas/IV, crianza/formas y mundo son dependencias, no ceros neutros. Sin shortcuts de calidad: los tests deben tener comprobaciones >0.


## Bloque 1: integración real ampliada de entrenamiento (sin cambios de motor)
Ampliar únicamente `tests/gameplay/item_closure_v3_test_runner.gd` ya permitido: por cada uno de `power_bracer/power_belt/power_lens/power_band/power_anklet/macho_brace`, probar con batalla nativa efectiva, restauración de checkpoint, recompensa al propietario, seis EV exactos, XP no bloqueada, persistencia, conservación del objeto e idempotencia del cierre. No sustituye la ruta física de mochila/mapa/guardado ya comprobada para `power_weight`; dejar el límite explícito. Fallos de objetos heredados se documentarán, no se ocultarán. Ejecutar CI Godot y portable antes de declarar éxito.

## Cierre verificado de bloques 0–1
Código probado en `69e15d74d04063dbe9613575b8618062e1efbed7`, 20/20 workflows PASS, run V28 #41220691787. Bloque 0 conserva siete blobs funcionales idénticos a V3 histórico; bloque 1 añade únicamente cobertura nativa EV para seis equipables (la ruta mapa/mochila sigue solo en `power_weight`). Incidencia de aserción en `c29db193` resuelta por comparación correcta del esquema serializado y comprobada en nuevo CI; no se ha cambiado el esquema. Los avisos de proceso hijo Ubuntu quedan como pendiente de diagnóstico, sin maquillar. Cualquier bloque 2 posterior debe declarar primero familia, consumidores y nuevas rutas, y dejar pruebas registradas por SHA.

## Bloque 2 — cierre de ruta mapa/mochila para toda la familia EV
Cambiar únicamente `tests/gameplay/item_closure_v3_test_runner.gd`, preservando los asertos anteriores: iterar los seis objetos `power_*` y `macho_brace` por un recorrido **aislado por cada ID** en `field_demo.tscn`, seleccionar y equipar el objeto desde la mochila, guardar/cargar, enfrentar un Caterpie en combate nativo, aplicar EV por las seis estadísticas, confirmar XP, titularidad, stock y guardado en disco. No duplicar mecánicas en el motor ni en UI. No afirmar cierre universal ni segundo combate por familia si no se ejecuta. Si falla, conservar SHA/ejecución y corregir el comportamiento real o el test, según evidencia. CI Ubuntu+Windows y regresiones completas antes de certificar.

## Cierre del bloque 2
Código `ae51793641b6981b4827524208b50f7a7c8e54a0`, 20/20 workflows GitHub PASS (run #41222946680). Siete recorridos físicos aislados mapa/mochila/combate/guardado, no solo equipados en dominio. Runner único ampliado; motor, adaptador, escenas, datos y política intactos. El fracaso previo de `f052b09c` (#41222565742) fue la aserción compuesta de recarga; la versión aprobada desglosa EV/XP/equipamiento/stats/stock por cada objeto, sin cambiar el contrato. Siguen pendientes pruebas GPU/manuales, mensajes de proceso auxiliares y familias dependientes. Cualquier nuevo bloque requerirá declaración de rutas/consumidores y CI por SHA; no reabrir estos siete sin motivo.


## Bloque 3 CANCELADO — Ente Ball no pertenece al randomlocke competitivo

**Cancelado expresamente por el usuario, 31-10-2026.** Ultraentes se capturan con Poké Balls normales ya soportadas. `beast_ball` no se registra ni se utiliza; no se aplican multiplicadores propios de ultraentes, ni regalos ni cambios de política de inventario. La edición `224a080d` fue experimental y quedó anulada en un commit posterior sin merge; **no cuenta como entrega ni éxito**. Se restauran los blobs exactos anteriores del dominio y del workflow, y se elimina `tests/gameplay/item_capture_beast_v28.gd`. No reabrir por iniciativa propia. La descripción detallada del intento permanece en el historial Git y en PROGRESS como auditoría histórica, no como orden vigente.

## Filtro obligatorio antes del siguiente bloque

El objetivo revisado es **Pokémon Calvo como randomlocke competitivo**. Trabajar solo objetos que sirvan efectivamente al combate competitivo, entrenamiento permitido, equipo, mochila de combate, captura ordinaria u otras mecánicas del reglamento que el usuario confirme. No conectar sistemas no pertinentes por completar el inventario: concurso, cocina, crianza, evolución por intercambio ya aplazada, cosméticos, botín/historia, formas sin soporte, economía y `beast_ball` no son automáticamente tareas. Mantener íntegro el catálogo fuente y las exclusiones vigentes: *no utilizar* no implica borrar IDs del dataset ni vetarlos sin una política del juego. Para cada próxima familia: confirmar relevancia competitiva, consumo/propietario/recorrido real y reglas existentes; definir allowlist y tests antes de editar. Bloques 0–2 siguen validados en el SHA `ae517936`, CI #41222946680 20/20 PASS. No repetirlos ni alterar `main`.

## Bloque 4 — equipables de protección competitiva (cobertura real, no motor nuevo)
**Motivo competitivo:** conservar la utilidad de Gafas Protectoras `safety_goggles`, Capa Furtiva `covert_cloak` y Amuleto Puro `clear_amulet` en combate. Estos tres efectos **ya están implementados y verificados en el motor nativo V2** (tres casos positivos con control sin objeto). No confundir con funcionalidad nueva de fórmulas; el hueco es demostrar su conexión física con el juego y guardado.

**Rutas permitidas declaradas antes de editar:** nuevo `tests/gameplay/competitive_protection_items_v28.gd`, un único paso nuevo en `.github/workflows/item-closure-v3.yml`, y los cinco cuadernos en `docs/handoff/ITEMS_V28/`. Mantener intactos simulador fijado, motor, servicios, UI, escena, schema, datos, exclusiones, archivos históricos y gate portable.

**Contratos y escenarios:** para cada equipable, combate real nativo restaurado y control con el mismo Pokémon/movimientos/semilla SIN objeto; comprobar respectivamente impedir sueño por Espora, parálisis por efecto secundario de Moflete Estático (`nuzzle`) y bajada de Ataque por Encanto (`charm`). No basta con aceptar el comando: leer estado observable tras el turno; comprobar propietario correcto, revisión obsoleta rechazada, no consumir ni mutar la colección antes de publicar, y persistencia del objeto. Cada uno además atraviesa la mochila de `field_demo.tscn`, guardado antes de entrar, checkpoint, encuentro sencillo/cierre, guardado/carga posterior; confirmar stock y equipo. Los tres IDs son de uso competitivo, no se introduce ni un solo objeto de concurso/crianza o Ente Ball.

**Pruebas:** añadir paso Godot 4.7 CI con contador de aserciones >0 y marcador específico. Conservar los 20 workflows, test V3 existente, V18 y Windows portable sin umbrales rebajados. Si falla, preservar SHA y logs ajustados; evitar repetir CI sobre código sin cambios. **No afirmar que estos objetos eran antes inexistentes** ni que 2.222 efectos están completos.

## Cierre comprobado del bloque 4
Runner nuevo `tests/gameplay/competitive_protection_items_v28.gd` + un paso adicional al workflow `.github/workflows/item-closure-v3.yml`; sin cambios de dominio, motor o UI. Contraste de protección por Espora, Moflete Estático y Encanto con y sin objeto, más conexión real a mochila/mapa, batalla y persistencia. **Código `3a6a12a32e80352cfcc4ba3870957a583b26f323`: 20/20 CI PASS** ([run #41226013201](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41226013201)); `COMPETITIVE_PROTECTION_V28 PASS checks=122 cases=3 errors=0`, Windows portable PASS. Dos errores de parse históricos se conservaron y corrigieron sin relajar aserciones. El efecto no se activa en el combate de mapa con Caterpie, se demuestra en el combate nativo separado. Advertencias de procesos Node/Unix y GPU manual pendientes. **Bloque de protección cerrado en alcance; proyecto de objetos competitivo aún abierto.**

## Regla nueva 31-10-2026: habilidad, objeto beta y fuentes oficiales
Por petición expresa: **no adelantar objetos cuya activación exige una habilidad o su interacción todavía no integrada o verificada**. No deducir por existencia de un ID de habilidad que el camino del juego ha sido ensayado. Hechos: `modules/inventory/field_ability_effects.gd` soporta Ability Capsule/Patch en la mochila con validaciones; combate nativo Showdown gestiona habilidades; `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json` solo informa de **2 rutas de habilidad de campo probadas**, no de todas las interacciones. `klutz` figura en la lista vigente de habilidades excluidas en `config/randomlock_content_v1.json` (no reactivarla). `gorilla_tactics` figura como `DATA_ONLY` en el informe histórico de habilidades; no declarar su equivalencia con objetos Elección en el juego. Dejar sin puente nuevo los objetos `ability_shield` (supresión), `booster_energy` (Protosynthesis/Quark Drive), `adrenaline_orb` (Intimidate), y combinaciones de `choice_*`/Gorilla Tactics hasta ensayos de contexto; los efectos nativos ya existentes no se borran. No modificar la política de habilidades.

**Regla antibeta:** todo ID nuevo que se conecte debe estar (a) en el catálogo normalizado local, (b) en `data/api/v2/item/index.json`, (c) con ficha original `data/api/v2/item/<id>/index.json` que acredite objeto de juegos principales y efecto jugable, (d) permitido por `config/item_selection_v1.json`. Constar en el catálogo no basta si faltan las otras condiciones. Sin descarga ni importación de objetos beta.

## Bloque 5 — potenciadores de daño sin dependencia de habilidad
**Tres IDs oficiales contrastados en el repositorio:** `muscle_band` → PokéAPI #243 (x1.1 ataques físicos); `wise_glasses` → #244 (x1.1 especiales); `expert_belt` → #245 (x1.2 solo ataques supereficaces). Los tres figuran como `held-items`, atributos `holdable` y `holdable-active`, con índice Gen IV-VII en PokeAPI y están ya en catálogo. No cambiar el cálculo del daño. El barrido nativo V2 cubre Cinta Fuerte/Gafas Especiales y piloto cubre Cinta Experto; el hueco es conectar/asegurar ruta real mochila y el contraste de daño con y sin objeto.

**Allowlist antes de editar:** nuevo `tests/gameplay/competitive_damage_items_v28.gd`, un paso en `.github/workflows/item-closure-v3.yml`, y `docs/handoff/ITEMS_V28/{WORK_ORDER.md,STATE.json,PROGRESS.md,RESULTADOS.json,START_HERE.md}`. NO cambiar motor, habilidad, RNG, catálogo, políticas, UI, escenas, guardado, tests/baselines viejos ni main.

**Contratos:** 3 × dos tipos de movimiento (compatible/no compatible) × dos configuraciones equipadas y sin objeto, misma semilla/especies/estadísticas, habilidad vacía para aislar interacción. El daño medido del objeto debe superar al control solo en la condición correcta e igualarlo en la errónea. Verificar en el backend real checkpoint/versión, propietario, objeto no consumido y ausencia de cambios persistidos antes de cerrar. 3 rutas reales: equipar desde mochila en mapa, guardar/cargar, entrar y cerrar combate nativo, verificar existencias y equipo tras persistir. Diferenciar que la ruta de mapa no mide daño con el efecto activado si el enemigo es Caterpie; eso ocurre en el ensayo nativo separado.

**Gates:** Godot 4.7 Ubuntu + portable Windows, 20 workflows, fallo escrito por SHA. No declarar verificación hasta CI. Sin GPU manual ni las interacciones con habilidades especiales.

## Bloque 5 cerrado con CI real
Código `b9638283deb44d92c686f3d22f6fadbb27c2a1a4`, run #41227381283, **20/20 PASS**. Runner nuevo y paso Godot verificados, **164/0**; todos los casos usan `ability_id` vacío para aislar el efecto del objeto. Validación física de 3 IDs desde mochila, mapa, checkpoint, postcombate y guardado; no se prueba que todas las interacciones con habilidades funcionen. Los metadatos PokeAPI locales (243/244/245) acreditan su origen oficial. Regresión Windows `PUBLICATION_V27 PASS` con 4.993 conexiones y 40 guardados; sin relajar umbrales ni modificar producción. Pendiente GPU/manual y 30 avisos PID Linux; seguimiento técnico separado.

**Siguiente filtro:** familia adicional solo si es competitiva, oficial, permitida, no ya cubierta físicamente, y sin dependencia especial de habilidad no verificada. No reabrir tests anteriores sin evidencia.

## Bloque 6 — tres potenciadores elementales oficiales (escala acotada)
**Objetivo:** ampliar el comprobador existente, sin añadir ni modificar efectos productivos. Tres objetos oficiales del catálogo local: `charcoal` (#226, Fuego +20 %), `mystic_water` (#220, Agua +20 %) y `magnet` (#219, Eléctrico +20 %), cada uno con registros originales en `data/api/v2/item/index.json` y `data/api/v2/item/<id>/index.json`: categoría `type-enhancement`, `holdable` / `holdable-active`, game_indices de Gen II-VII y efecto escrito. Ya figuran en `tools/item_audit/held_effect_sweep_v2.cjs` bajo el diccionario de potenciadores de tipo. No son objetos beta. No modificar políticas ni importar nuevos datos.

**Allowlist exacta fijada ANTES de editar:** `tests/gameplay/competitive_damage_items_v28.gd` (modificar únicamente la tabla de tres ítems → seis, control de procedencia, cantidad y límites; sin tocar ayudas heredadas), `.github/workflows/item-closure-v3.yml` (ajustar el marcador a `ids=6`), y los cinco cuadernos `docs/handoff/ITEMS_V28/`. No editar producción, motor, backend, RNG, datos, esquemas, escenas, UI, baselines, versión Godot ni main.

**Casos:** `charcoal` con `ember` vs `tackle`, `mystic_water` con `water_gun` vs `tackle`, `magnet` con `thunder_shock` vs `tackle`, objetivo `snorlax` al nivel 100 con PS suficientes. Misma semilla y criaturas con habilidades vacías. 3 pares nuevos de efectos positivos/negativos → seis comparaciones con/sin objeto y 12 nuevas sesiones nativas, además de 3 escenas físicas independientes (mochila, combate de mapa, guardado/reinicio). Conservar íntegros los 3 casos anteriores y sus 164 aserciones. La validación del daño es positiva/negativa; **no** demuestra sinergias con habilidades o movimientos de varios golpes, switch, supresión. Control de fuentes oficiales automáticas con PokeAPI local en el nuevo runner. Guardar resultado real por SHA tras 20 workflows y un gate Windows sin cambios.

**Relevancia y límite:** sirven a estrategias de equipamiento del randomlocke competitivo sin habilidades dependientes; seis tipos (tres previos y tres elementales) no significan catálogo ni todos los potenciadores completos. `beast_ball` continúa vetada para implementación, sin revertir la captura normal de ultraentes.
