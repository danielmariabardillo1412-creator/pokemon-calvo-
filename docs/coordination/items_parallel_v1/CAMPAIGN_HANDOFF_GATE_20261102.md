# IA6 — GATE DE RELEVO DE CONVERSACIONES 2026-11-02 (W04 / W05)
**Estado:** autorizado para relevo de chat, sin apertura de nueva campaña ni reescritura de trabajo. **Motivo:** el usuario indica que las conversaciones anteriores de IA4 e IA5 fallan y solicita dos chats de sustitución con órdenes diferentes. En consecuencia revoca **solo** la congelación anterior de W04 para finalizar su microbloque pendiente en CAMPAÑA_001; las demás restricciones siguen vigentes.

## Identidades, puntos de partida verificados en GitHub
- **IA4/W04:** CAMPAÑA_001, **02/03** entregados. Continuación exactamente en rama `codex/calvo-items-20261101-w04`, HEAD verificado `146dfd0c17334ef95295e1106b26b86375bddfe2`. NO crear rama CAMP002 W04, ni repetir bloques 01/02. Fuentes: `campaigns/CAMP_001_W04.md`, en propia rama `reports/W04/CAMP_001_PROGRESO.csv` y `CAMP_001_ITER_02.md`. La entrada antigua de `CONTINUIDAD.md` refiere LOTE_002 y debe contrastarse con el CSV de CAMP_001, no sustituirlo. Pruebas de los bloques 01/02 corrieron en staging de IA6 #41350981613: paso W04 PASS `313 checks / 12 casos`, pero run global FALLÓ por W02, después reparado en campaña; no inventar un PASS de su bloque 03.
- **IA5/W05:** CAMPAÑA_002, **01/03** entregado. Rama **nueva** `codex/calvo-items-20261102-w05-camp002`, HEAD verificado `16b4b6ec4f595cbb0306cec68dba7b0b6f18365a`. NO usar rama antigua `codex/calvo-items-20261101-w05`. Fuentes: `campaigns/CAMP_002_W05.md` y `reports/W05/CAMP_002_PROGRESO.csv`/ `CAMP_002_ITER_01.md`. La prueba Python y selección real de 12 MT distintas de `tm01/tm02/tm77` pasaron en IA6 [#41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741), sobre staging SHA `967002fcbf26a1159d3a14a020e8921b34cfab8f`. Solo verifica contrato/learnsets y elección de muestra, **no enseñanza Godot de estas 12**.
- **IA1/W01:** 02/03 CAMP002 en rama `codex/calvo-items-20261102-w01-camp002` HEAD `681c381833c8e0cc7b195ae2a7ad683695d9d464`; **runner Godot nuevo pendiente de CI**. Estado naranja `PREPARADO_PENDIENTE_CI` no es FAIL. IA6 centraliza ese gate, **no enviar tercera `p` a W01 hasta autorización basada en pruebas**.
- **IA2/W02 e IA3/W03:** 02/03 CAMP002 preparados en ramas nuevas propias; paquetes recientes pendientes de CI; tampoco añadir bloques automáticamente por esta puerta.

## Permisos acotados del relevo
**W04 reactivada exclusivamente para ITER_03 de CAMP_001**, al recibir el mensaje específico de relevo del usuario. Su tarea es prueba con SaveV2/carga de seis piedras, consumo único y conservación de ID, IV/EV, movimientos, experiencia y amistad, con rechazos de especie/propiedad y PC/equipo, sin cambiar producción. **Al publicar 03/03, cerrar `CAMPAÑA_001_FINALIZADA` y STOP**. Esa reactivación no autoriza ninguna tarea de CAMP_002 en W04.

**W05 reanudada exclusivamente en ITER_02 de CAMP_002**, en rama actual y con muestra de 12 MT ya elegidas por test real. Construir runner Godot parametrizado para **al menos seis parejas compatibles** mediante `FieldItemService.teach`, con PP, consumo, propiedad, rechazo, persistencia; no inventar especies ni tocar `FieldItemService`, datos, arte, selección o 19 antiguas. Tras 02, **STOP por CI/esperar puerta IA6** antes de ITER_03, para no acumular fallo funcional.

La nueva conversación puede recibir una sola orden de inicialización + **microbloque pendiente**. No repetir informes, no copiar todo el historial del chat, no merge/rebase automático desde árbitra, no sobrescribir archivos antiguos, no editar las ramas de las otras trabajadoras, `main`, V28, PR #118 o archivos de producción. Si hay dudas sobre propiedad de ruta, conflictos o herramientas ausentes: detenerse y devolver SHA y causa.

## Instrucciones de reentrada para nuevas conversaciones
Las dos órdenes completas y diferenciadas se publican junto a este gate:
- [RELEVO_IA4_W04.md](RELEVO_IA4_W04.md)
- [RELEVO_IA5_W05.md](RELEVO_IA5_W05.md)

Para el operador: **pegar solo el mensaje IA4 en la conversación nueva IA4 y solo IA5 en IA5**. La instrucción de ejecutar bloque ya viene incluida; no añadir `p` hasta que respondan. La CI de nuevos commits sigue siendo responsabilidad de IA6.

## Evidencia no alterada
Las pruebas históricas de IA6 en Godot 4.7 (véanse gates 005 y 002) cubren solo los SHA y escenarios indicados. El relevo no presume CI nueva ni verificación visual/GPU. Cambiar el texto de una puerta no invalida comprobaciones anteriores.
