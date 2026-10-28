# Verificación de equipados y bayas V3 — 2026-10-28

Se cierra la clasificación de los **80 equipados y 32 bayas** que quedaron sin
escenario en V2. Esto no declara terminados todos los sistemas de objetos.

## Resultado comprobado

- **65 IDs adicionales**: 53 equipados y 12 bayas.
- **908 escenarios nativos**, con controles sin objeto y semillas reproducibles.
- **1092 transiciones** proyectadas a Godot y **23434 comprobaciones**, sin errores ni mensajes de protocolo pendientes.
- **65 escenarios por IPC real**, uno por objeto, con hash final idéntico y sin mutación prematura del equipo de entrada. Las otras variantes se ejecutan y proyectan, pero no se anuncian como ejecuciones IPC independientes.
- Acumulado: **189 IDs con escenarios de efecto verificados**, conservando el alcance de V1/V2.

El lote cubre potenciadores de especie y tipo, objetos de defensa, peso y orden,
habilidades protegidas, semillas y terrenos, duración del clima, trampas y cambio,
críticos, precisión, curación, PP, consumo y transferencia. Incluye secuencias de
varios turnos para Transformación, Metrónomo, Garra Garfio, Muda Concha y Baya Lagro.

Las expectativas están declaradas en el verificador. Los controles mantienen la
misma semilla, especie y acciones salvo el objeto; el control de Muda Concha se
detiene antes de intentar un cambio que estaría prohibido. Preparar no publica
el turno; restaurar cada snapshot conserva su hash. Las plantillas proceden de
CreatureFactory y aíslan los efectos con habilidades vacías, salvo donde la
habilidad es precisamente el contexto probado. No son equipos legales de campaña.

Los ocho grupos probabilísticos usan semillas fijas y comprueban ambas ramas;
**no certifican sus porcentajes exactos**. Los potenciadores se contrastan por
dirección del daño y controles negativos, sin afirmar una segunda implementación
independiente de todos los redondeos. Tampoco se certifica cada interacción en
dobles, crianza, botín o tiendas.

## Corrección de conexión encontrada

Escudo Habilidad funcionaba en el motor nativo, pero su mensaje `-block` detenía
la publicación del turno en Godot. El adaptador reconoce ahora exclusivamente
`item: Ability Shield`, conserva el destinatario y publica ITEM_TRIGGERED con
motivo `ability_protected`. Un mensaje de bloqueo desconocido sigue rechazándose.
Se verifica el aviso, la protección de la habilidad y la repetición por IPC.

Es el único archivo de ejecución modificado en este lote. No se regeneran datos
ni se cambian vetos o imágenes. Los hashes de datos, políticas y
manifiesto artístico siguen coincidiendo con V2.

## 47 dependencias explícitas, sin PASS ficticio

| Grupo | IDs | Motivo |
| --- | ---: | --- |
| Formas de especie | 26 | 17 memorias de Silvally, 4 discos de Genesect, 3 máscaras de Ogerpon y Espada/Escudo Oxidados necesitan una ruta de forma y proyección válida. |
| Entrenamiento fuera del combate | 6 | Bayas de reducción de EV/amistad: falta conectar el cambio persistente al dueño real. |
| Comida, concursos u otro uso del mundo | 14 | Su uso no se certifica mediante un efecto pasivo de combate; requiere decidir y conectar su sistema. |
| Lazo Destino | 1 | Falta un contrato explícito de género para enamoramiento y un sistema de crianza. |

El catálogo canónico actual contiene las especies base de esas 26 rutas, sin las
formas específicas requeridas. Las sondas de inicio del motor muestran también
por qué no basta con poner el objeto: los discos/memorias/máscaras no sustituyen
la ruta de forma; los objetos oxidados sí producen una forma coronada que falta
en el catálogo/proyección. Esto no equivale a que falten sus dibujos, ni autoriza
a descartarlos del contenido. Los IDs y motivos están en el registro pendiente.

Las otras familias conservan sus límites previos: medicinas fuera del combate,
bolas condicionales, máquinas antiguas, evoluciones condicionadas y sistemas de
mundo. Los **323 otros IDs reconocidos por el motor** que aún requieren un
contexto propio no son 323 equipados fallidos ni forman parte de estos 112.

## Regresiones y reproducción

Se repiten la proyección V2 (368 casos), el piloto anterior, medicina de combate,
inventario/captura, campo nativo, guardado, guardado adversarial, política de
selección y conexiones de mochila/MT/evolución. No se ha cambiado la interfaz;
este lote no añade una nueva certificación artística o de GPU.

```text
python tools/item_audit/run_verification_v3.py
```

El proceso es secuencial y no publica un informe nuevo ante un fallo. La matriz
CSV/JSON conserva los 2.222 IDs y separa uso, transferencia y efecto; el informe
guarda hashes de fuentes y evidencia. `ITEM_VERIFICATION_PENDING_V3.json` conserva
los 47 motivos y los demás sistemas pendientes. `ITEM_SYSTEM_CURRENT_STATUS.json`
apunta a este estado, manteniendo `all_item_effects_certified: false`.
