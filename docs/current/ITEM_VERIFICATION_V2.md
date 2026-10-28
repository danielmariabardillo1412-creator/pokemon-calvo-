# Verificación de objetos disponibles y pendientes V2 — 2026-10-28

Petición: ejecutar el comprobador sobre lo verificable y registrar lo que depende
de mecanismos/contextos todavía pendientes. Este lote añade pruebas, no efectos
nuevos al juego. No cambia datos brutos, políticas, imágenes ni mecánicas.

## Grupos verificados

Se vuelve a ejecutar el barrido de conexiones V1: transferencia de 625 objetos,
57 rutas evolutivas de uso de objeto y 229 MT del perfil activo, guardado/carga,
entrada al combate nativo, bloqueos y regresiones. Se mantienen aparte las 15
rutas condicionadas y los 109 IDs de máquinas sin perfil activado.

También se repiten los 21 equipados del piloto original (42 escenarios, dos
semillas), su proyección, repetición por IPC y prueba de publicación/consumo.
Se comprueban de nuevo las 15 medicinas en combate y las suites existentes de
inventario/captura, que incluyen las cuatro bolas básicas y casos de identidad,
cantidades, restricciones, determinismo y falta de espacio.

El lote nuevo incorpora **103 IDs**, con **368 escenarios nativos** entre casos
de activación y de no activación, usando dos semillas:

- Potenciadores de tipo y tablas: aumenta daño del tipo pertinente y no el de otro.
- Gemas: activación/consumo al usar el tipo correcto y ausencia de consumo en otro.
- Bayas reductoras: reducción de daño y consumo en el contexto correspondiente;
  no se consumen por otro tipo de ataque.
- Bayas de estadísticas y curación: condiciones cumplidas e incumplidas.
- Objetos de daño, velocidad, reacción al golpe, protección frente a contacto,
  efectos secundarios, polvo y bajadas; recuperación, orbes y límites multigolpe.

Se usa el motor fijado `@pkmn/sim@0.10.11` y el perfil de combate del juego.
Las expectativas de los escenarios están declaradas en el verificador. Los
controles sin objeto mantienen equipo, movimientos y semilla. Se comprueba que
preparar un turno no publique el estado y que restaurar su snapshot conserve el hash.
Las plantillas se crean con las estadísticas reales del catálogo; sus habilidades
se dejan vacías deliberadamente para aislar el objeto, sin afirmar que sean
equipos legales de generación de campaña.

Las 368 transiciones se proyectan a Godot, cotejando PS, estado, consumo y siete
estadísticas. Para limitar arranques de procesos, se repite además un escenario
positivo de cada uno de los 103 IDs mediante el worker real: **103 casos IPC**,
no 368. Se exige el mismo hash final y ausencia de cambios prematuros en la
colección de entrada. Las variantes de semilla/control restantes sí se ejecutan
en el motor nativo y se proyectan, pero no se anuncian como 368 ejecuciones IPC.

Total de IDs con escenarios de efecto comprobados, sumando el piloto repetido:
**124**. No equivale a certificar todas las interacciones de esos 124 objetos.
Por ejemplo, comprobar que un potenciador incrementa el daño correcto no sustituye
una implementación independiente de cada redondeo de la fórmula canónica.

## Pendientes explícitos

`ITEM_VERIFICATION_PENDING_V2.json` separa:

1. **Mecánica o conexión pendiente:** Cuerda Huida, medicinas fuera del combate,
   entrenamiento, máquinas antiguas, condiciones/formas de evolución, bolas
   especiales y los sistemas de mundo que finalmente se conserven.
2. **Escenario de prueba pendiente:** un objeto reconocido por el motor puede
   necesitar clima, terreno, una especie, probabilidad, varios turnos o una acción
   especial. Eso no demuestra que falte su efecto ni autoriza marcarlo PASS.
3. **Protocolo Godot pendiente:** si el motor ejecuta un caso pero la traducción
   rechaza un evento, se registra con el mensaje concreto y no se cuenta como
   integrado. En este lote no hay casos pendientes de este tipo.

El caso de Chesto se provoca con Espora dentro del combate, no inventando un
reloj de sueño importado. Un ensayo inicial sin reloj fue un contexto de prueba
inválido; no se debilitó la validación del motor para hacerlo pasar.

No se aprueban objetos para botín/tiendas por pasar una prueba diagnóstica, ni
se modifica su disponibilidad histórica o los vetos del proyecto.

## Resultado y reproducción

- Conexiones: 4.994 comprobaciones sin ventana y 4.996 con GPU, PASS.
- Lote de efectos nuevo: 368 escenarios nativos y 6.668 comprobaciones Godot, PASS.
- Piloto original repetido: 42 escenarios nativos y 461 comprobaciones Godot, PASS.
- Medicinas de combate: 120 comprobaciones, PASS.
- Inventario y captura: 133 comprobaciones, PASS.
- Regresiones de campo, guardado, guardado adversarial y política: PASS.

```text
python tools/item_audit/run_verification_v2.py
```

El proceso ejecuta las fases secuencialmente y detiene la publicación ante
errores de script, aserciones o fallo de un caso. El backend de proyección se
reutiliza para no releer el dataset en cada variante; el juego no cambia.

- `ITEM_VERIFICATION_V2.json`: resultado, límites, fuentes y hashes de evidencia.
- `ITEM_VERIFICATION_V2.csv`: estado por operación para los 2.222 objetos.
- `ITEM_VERIFICATION_PENDING_V2.json`: pendientes con motivos concretos.
- `.godot/item_verification_v2/`: escenarios, snapshots, proyección y registros.
- `ITEM_SYSTEM_CURRENT_STATUS.json`: punto de continuación actualizado.

La opción `--summarize` solo consolida evidencias ya existentes; para reproducir
todas las pruebas se usa el comando anterior sin esa opción.
