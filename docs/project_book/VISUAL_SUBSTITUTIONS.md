# Registro único de sustituciones visuales de movimientos

Actualizado: 2026-10-25, por petición del usuario. Índice humano complementario
de `VISUAL_CATALOG.md`; no es una nueva fase ni una aprobación de mecánicas.

## Regla para continuar

Actualización 2026-10-26: el lote de Niebla/Reversión/Cambiaalmas/Cambiafuerza/
Cambiadefensa/Acupresión/Niebla Clara/Robasombra conecta lógica real con los
recursos existentes. **Ninguna imagen, animación fuente o fondo sustituido**;
no aumenta el recuento de sustituciones. Evidencia de cámara/playback y reglas:
`../current/STAT_STAGE_MOVES.json`.

**Toda sustitución futura de imagen, animación o fondo debe anotarse aquí**:
movimiento/especie afectado, recurso anterior, recurso elegido, motivo, vistas,
alcance (laboratorio/combate) y evidencia. Conservar el original o su procedencia
y separar la elección vigente de los candidatos descartados. No sustituir recursos
silenciosamente. Si afecta a sprites de una especie, añadir sección de Pokémon
con su ID y vínculo al manifiesto correspondiente, sin mezclarla con ataques.

Este inventario reconstruye las selecciones vigentes de MOVIMIENTOS; no pretende
inventariar retrospectivamente cada sprite de las 1.025 especies. Sus fuentes y
renders siguen en los manifiestos/cuaderno del catálogo de Pokémon.

## Recuento verificado y alcance

### Registro general enlazado al juego ordinario — 2026-10-26

Sin sustituciones nuevas de arte. Se registran los 1.822 clips / 900 IDs del
catálogo congelado para carga bajo demanda en combate normal, sobre efectos
resueltos. El inventario de sustituciones conserva 41 IDs / 49 familias / 98 clips.

Adaptaciones de integración: coreografías originales de cuerpos/partículas desde
los shards; coordinación de visibilidad para no dibujar dos cuerpos; en movimientos
propios no desaparece el rival. Los bindings de impacto fino anteriores mantienen
prioridad. Los nuevos bindings generales aplican PS al finalizar el clip, sin
inventar daño ni cambiar eventos/RNG. La ruta del sustituto sigue independiente.

Los cinco Torque sin par nativo por defecto (`blazing_torque`, `combat_torque`,
`magical_torque`, `noxious_torque`, `wicked_torque`) conservan fallback genérico por
tipo. No se declara que registrar clips certifique cada especie/ataque o su lógica.

Constructor `tools/visual/build_live_battle_catalog.py`, manifiesto
`.godot/live_battle_catalog/manifest.json`, informe `LIVE_MOVE_INTEGRATION.json`.
Muestras ordinarias en `.godot/live_integration_checks/contact_sheet.png`.
Los dibujos, renderer y fuentes congeladas no se modifican. Procedencia/créditos
y revisión de distribución del catálogo original siguen vigentes.

### F12: Cambio de Banda, posiciones y cuatro cuerpos — 2026-10-26

| Movimiento | Antes | Recurso utilizado | Adaptación y motivo | Alcance/evidencia |
|---|---|---|---|---|
| `ally_switch` | Dos pistas de cuerpo en laboratorio; sin dos aliados reales ni objetivos por puesto | Dos clips fuente `ALLYSWITCH`, 15 frames/20 fps, y sprites originales de los cuatro participantes | Curva de opacidad original reflejada alrededor de un intercambio de posiciones confirmado; cámara y desplazamiento adaptados a cuatro cuerpos. No se usa al rival como falso aliado | F12; `ALLY_SWITCH_PILOT.json`; 16 capturas, hojas `positions_contact_sheet.png` / `motion_contact_sheet.png` |

Sin sustitución de dibujos/PNGs: el inventario conserva 41 IDs / 49 familias /
98 clips. Se añade una adaptación de composición y cámara. El clip original no
contiene partículas; no se anuncia un VFX nativo completo. Los cuatro ataques
de diagnóstico emplean recetas genéricas por tipo sobre daño auténtico, sin
cambiar el catálogo ni el renderer congelado.

Constructor `tools/visual/build_ally_switch_pilot.py`; manifiesto
`.godot/battle_ally_switch/manifest.json`, con clips fuente, SHA del shard/índice y
curvas de ambas vistas. La clasificación `DATA_ONLY` se conserva. Procedencia y
créditos originales del catálogo siguen vigentes. Reglas de referencia:
<https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts>.

### F11: Transformación, imagen copiada y reversión — 2026-10-26

| Movimiento | Antes | Recurso utilizado | Adaptación y motivo | Alcance/evidencia |
|---|---|---|---|---|
| `transform` | Cambio de apariencia ilustrativo en laboratorio; sin copia real en combate | Dos líneas de tiempo originales `TRANSFORM`, 15 frames/20 fps, y sprites existentes de la especie copiada en el lado correcto | Handoff del frame 8; breve compresión/desvanecimiento para el cambio confirmado. El clip fuente SOLO contiene cuerpos: no se inventan partículas ni se etiqueta como VFX nativo completo. Se restaura la imagen original al salir/terminar | F11; `TRANSFORM_PILOT.json`; 12 capturas `.godot/transform_checks/contact_sheet.png` |

No se sustituye ningún dibujo ni aumenta el inventario de sustituciones
(41 IDs / 49 familias / 98 clips). Se añade una adaptación de apariencia con
fuentes existentes. Ditto conserva nombre/PS/nivel; la mecánica copia también
los datos representados y actualiza el menú real. Snapshot y replay son separados.

Constructor `tools/visual/build_transform_pilot.py`, manifiesto
`.godot/battle_transform/manifest.json`: dos clips fuente, SHA de shard/índice,
clasificación congelada `UNSUPPORTED` y handoff. No hay nuevos PNGs, cambios del
renderer congelado ni reexportación de fuentes. Mantener los créditos y condiciones
de distribución del catálogo; reglas de referencia Pokémon Showdown:
<https://github.com/smogon/pokemon-showdown/blob/master/sim/pokemon.ts>.

### F10: Sustituto y Shed Tail, creación y persistencia — 2026-10-26

| Movimiento | Antes | Recurso utilizado | Adaptación y motivo | Alcance/evidencia |
|---|---|---|---|---|
| `substitute` | Clip solo en laboratorio; sin muñeco funcional en combate | Dos clips `SUBSTITUTE` y muñeco original frontal/trasero, SHA `e4cb8b5708589c81ce97fb5c9be30dbf60477f5437c0c17554abbded3a8ed093` | Alinear la creación con los pies del muñeco; ocultar el muñeco persistente mientras el clip nativo dibuja el suyo, para evitar duplicados | F10; `SUBSTITUTE_PILOT.json`; capturas `substitute_back_native`, `substitute_front_native`, `substitute_persistent`, `substitute_broken` |
| `shed_tail` | Clip de laboratorio; sin transferencia a una reserva | Dos clips `SHEDTAIL`, mismo muñeco original | Proyectar cola/muñeco sobre el apoyo real y conservar el muñeco tras elegir reserva; no transferir otras estadísticas/volátiles | F10; mismo informe; `shed_tail_back_native`, `shed_tail_front_native`, `shed_tail_persistent`, `shed_entry_doll`, `shed_tail_broken` |

No sustituciones nuevas de dibujos: los 41 IDs / 49 familias / 98 clips del
inventario de sustituciones conservan su recuento. Son cuatro bindings de creación
adicionales y una adaptación de cámara/persistencia. Todos los golpes absorbidos
se etiquetan `SUBSTITUTE_DAMAGED` y usan por ahora el impacto genérico por tipo;
no se falsifica daño corporal para forzar una animación nativa. No se certifica
el resto de las animaciones originales contra objetivos de tamaño de muñeco.

Constructor `tools/visual/build_substitute_pilot.py`: fuente, SHA y clips en
`.godot/battle_substitute/manifest.json`. PNGs originales, clips fuente, renderer e
índice sin cambios. Se conserva la procedencia/créditos del catálogo y su revisión
de distribución; la referencia de reglas añadida es Pokémon Showdown
<https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts>.

### F9: activaciones y clima persistente desde las fuentes existentes — 2026-10-26

Sin sustitución de imágenes. Se enlazan los diez clips ya revisados a eventos
reales de lluvia, granizo, arena, nieve y Fría Acogida. Antes estaban disponibles
como fuentes/LAB; ahora F9 añade las activaciones y la persistencia del clima.
Las partículas usan los cuerpos reales del combate; no copian los del export.

| ID | Fuentes back / front | Frames por lado |
| --- | --- | --- |
| rain_dance | Move:RAINDANCE / Move:RAINDANCE, front mapeado | 26 |
| hail | Move:HAIL / Move:HAIL, front mapeado | 13 |
| sandstorm | Move:SANDSTORM / Move:SANDSTORM, front mapeado | 24 |
| snowscape | Move:SNOWSCAPE / Move:SNOWSCAPE, front mapeado | 13 |
| chilly_reception | Move:CHILLYRECEPTION / OppMove:CHILLYRECEPTION | 30 |

Persistencia: Common:Rain/Hail/Snow a 30 frames y Common:Sandstorm a 20, todos
a 20 fps. Nieve/granizo conservan el mismo arte original. Sandstorm conserva
su capa PRAS- Sandstorm.png y su cadencia; no se alarga a 30 frames. El overlay
omite el campo/cuerpos nativos y conserva las partículas/capas de clima.
No se tocan las correcciones de cámara históricas de Fría Acogida front.

Pack reproducible `tools/visual/build_weather_pilot.py`, 442.397 bytes PNG
copiados. casts.json SHA `c14aa0a4adae54e980a82ab2dad18b0c7c3dbb684fc847b73cbd5f18875d0704`;
common.json SHA `044675099b36945a28c7838a8d1a5a59257167aa0ce26d5d94fec3970e2ad42d`.
Sandstorm fuente fijada por SHA
`25db6fbf3ab3b290bc57cd05d7b022ad9a6b7e20aa9d952d7ee5a5ceae162b03`.
Evidencia `../current/WEATHER_PILOT.json`: 1.523 PASS, 120 casos, 11 capturas.
Lámina de activaciones back y persistencia observada; sin atribuir una nueva
revisión GPU front. No hay autores/recursos artísticos nuevos; mismos créditos
del pack original. Inventario sigue en 41 IDs/49 familias/98 clips.

### F8: cinco movimientos de estado conectados, sin sustituir dibujos — 2026-10-26

Antes: fuentes nativas revisadas en laboratorio, sin efecto real de estos cinco.
Ahora: mismas partículas enlazadas a un efecto confirmado, en el piloto F8 de
combate salvaje individual. Los cuerpos/fondos del export se omiten; las
retiradas/entradas siguen eventos reales. No se genera ni reemplaza ningún PNG.
La equivalencia GUST de Whirlwind ya estaba seleccionada; aquí solo se conecta.

| ID | Fuente back / front | Frames back / front | Primer frame visible usado como aviso |
| --- | --- | --- | --- |
| roar | Move:ROAR / OppMove:ROAR | 21 / 21 | 5 |
| whirlwind | Move:GUST / Move:GUST, front mapeado | 26 / 26 | 1 |
| teleport | Move:TELEPORT / Move:TELEPORT, front mapeado | 21 / 21 | 6 |
| baton_pass | Move:BATONPASS / OppMove:BATONPASS | 31 / 35 | 0 |
| parting_shot | Move:PARTINGSHOT / OppMove:PARTINGSHOT | 26 / 26 | 2 |

Todos a 20 fps. No se cambian sus frames/duración para igualar vistas. El aviso
no representa un impacto de daño: estos pasos no restan PS. Pack reproducible
con `tools/visual/build_status_switch_pilot.py`, SHA
`6e6255dee81de130110edb89c3fa8ca5b161ce72a05524d9d2b4e54bf41ffb81`,
12.277 bytes PNG copiados. Registro `../current/STATUS_SWITCH_MOVES.json`:
1.326 PASS/120 casos, diez vistas y 18 capturas GPU. Observadas las láminas
native_contact_sheet y live_contact_sheet; textos finales de estadísticas
expresados en español, sin nombres internos de eventos.

Alcance: cinco mecánicas base nuevas; junto a F7 diez. Entrenador/IA, todos los
volátiles futuros de Relevo y otras interacciones competitivas pendientes.
La cola global de 19 no se cierra por el piloto. Inventario artístico sigue en
41 IDs/49 familias/98 clips. Se mantienen procedencias/créditos del pack original.

### F7: mismos diez clips, ahora con cinco mecánicas base — 2026-10-25

Sin sustitución de PNG, atlas, exports ni marcadores. Antes: esos cinco solo
reproducían daño. Ahora, **en el piloto F7**, los mismos clips de partículas se
acompañan de peticiones/elecciones/retiradas/entradas y fin por expulsión que
resuelve el motor. El reproductor no decide la reserva. La retirada/entrada usa
los efectos existentes del combate y los sprites del Pokémon realmente elegido.
En F6 se mantiene el contraste SOLO DAÑO con su aviso; F7 omite ese aviso.

IDs: circle_throw y dragon_tail (expulsión); flip_turn, u_turn y volt_switch
(elección de reserva). Dos vistas nativas por ID, mismas fuentes/frames/tiempos
de la tabla siguiente. Evidencia `../current/SWITCH_MOVE_PILOT.json`, 1.844 PASS,
120 casos y 11 capturas GPU; lámina y entrada de Blastoise observadas.
Activación de interfaz F7 solo en encuentros salvajes individuales; interfaz/IA
de entrenador e interacciones competitivas completas pendientes. La cola global
de 19 no se cierra por este piloto. Inventario de alternativas sigue en
41 IDs/49 familias/98 clips, sin nuevos autores ni recursos a acreditar.

### Enlaces parciales de daño al combate — 2026-10-25

No se sustituyen dibujos ni exports. Se añaden diez enlaces usando sus mismas
capas/frames/PNG nativos ya revisados. Antes: receta genérica del combate.
Ahora: partículas nativas sobre los cuerpos reales, omitiendo los cuerpos y
BG/FG del recurso. El resultado especial de relevo/expulsión no está implementado
y se avisa en la demo. Las 38 fuentes de los 19 siguen intactas en laboratorio.
Sin nuevos autores ni recursos externos; conservan los créditos del pack original.

| ID | Fuente back / front | Frames | Impacto / fin PS, a 20 fps |
| --- | --- | --- | --- |
| circle_throw | Move:CIRCLETHROW / Move:CIRCLETHROW | 19 | 2 / 10 |
| dragon_tail | Move:DRAGONTAIL / OppMove:DRAGONTAIL | 20 | 7 / 15 |
| flip_turn | Move:FLIPTURN / OppMove:FLIPTURN | 30 | 12 / 20 |
| u_turn | Move:UTURN / Move:UTURN, front mapeado | 28 | 14 / 22 |
| volt_switch | Move:VOLTSWITCH / OppMove:VOLTSWITCH | 26 | 18 / 24 |

U-turn y Volt Switch tenían en el prototipo marcadores 12/20 y 14/22 demasiado
tempranos respecto al viaje del efecto. Se ajustan solo los marcadores del
reproductor de combate tras inspección GPU; no los tiempos/frames de la fuente.
Prototipo anterior conservado en `.godot/battle_external_integration/timing_before/`.

Selección reproducible: `tools/visual/build_external_damage_pilot.py`, pack
`.godot/battle_external_damage/manifest.json`, SHA
`175ceb67c22c67ec90aca69eb79697b5a4c95f2568226d04c8e82c03079e6105`.
179.921 bytes de PNG copiados. Evidencia final:
`.godot/battle_external_integration/gpu_result.json`, 475 PASS, 38 casos del
servidor, 11 impactos reales/12 capturas; lámina de diez vistas observada.
Informe versionable `../current/BATTLE_EXTERNAL_INTEGRATION.json` status PARTIAL.
F6 permite probar el alcance SOLO DAÑO sin guardar learnsets.

Inventario artístico permanece en 41 IDs/49 familias/98 clips. Los diez enlaces
no se cuentan como nuevas sustituciones ni cierran sus mecánicas: siguen abiertos
los 19 efectos especiales/38 vistas. Total enlaces de combate diez IDs/20 clips,
cinco de esos IDs únicamente para daño confirmado.

**Contrastes generales — 2026-10-25:** cuatro vistas con ajuste de presentación,
sin sustituir imágenes, atlas, exportaciones ni clasificaciones:

| ID / vistas | Antes | Ajuste vigente | Alcance |
| --- | --- | --- | --- |
| `clanging_scales` back/front | El track fijo del receptor usa foco local del usuario; se desplaza y front queda cortado por arriba | Solo el cuerpo receptor/slot1 usa su propio origen; partículas y gesto del usuario se conservan | LAB; back también se corrige aunque no fuera un clip pendiente |
| `court_change` back/front | La metáfora nativa del cruce deja los cuerpos en plazas opuestas | Cruce inicial intacto hasta f13; retorno suave a la plaza propia en f14..21 | LAB; no intercambia condiciones del campo ni posiciones reales |

Fuentes fijadas por nombre, lados, atlas y SHA completo de frames/capas.
`aeroblast`, `destiny_bond` y `doom_desire` se verifican sin cambios: diferencia
de fondos nativos, sombra ovalada del atlas original y trazos presentes en el
atlas original, respectivamente. DOOMDUMMY es un candidato separado; verificar
su asignación a carga/impacto y no dar por resuelto el encadenamiento por el nombre.

No se alteran las 38 vistas de los 19 contextos; el laboratorio añade sus
requisitos concretos para distinguir la fuente de la integración pendiente.
Sin nuevos autores/recursos/créditos; se mantienen los del pack y Essentials.
Original en `.godot/move_general_checks/reference/preview_before.gd`, SHA
`16892e3fcdd2…`; fuentes/atlas y cotejo upstream en `reference/sources.json` y
`reference/phase_sources.json`. Evidencia
`.godot/move_general_checks/418254331eca04dc/gpu/`, result/boards/review y nueve
láminas observadas (cinco antes/después y cuatro de fuentes de contexto en lote).
Review SHA `208ad6d39b44df9741027494f35c502158b96252f0a2aa5bef0575927f1addc5`.

Gate 593.828 PASS: captura 2.532 estados, 960 pares; contrato 12.660 estados,
cinco parejas/dos arenas, 540 anclas y 40 retornos finales correctos. Fuente
inmutable preservada, cuatro exports manipulados rechazados. Regresiones:
catálogo 5.366.237, Z 317.062, contexto 6.442, rutas 407 y perfil 1.898 PASS.
Renderer `16892e3fcdd2…` → `7674d3a61e11…`; contexto `e1221ddaae3b2375`.
Cinco IDs/nueve clips de cola cerrados: **74 IDs/118 clips** acumulados;
**19 IDs/38 clips** externos siguen pendientes de integración, aunque sus
fuentes ya estén revisadas. **Inventario de alternativas: 41 IDs/49 familias/98
clips**, sin aumento por estos ajustes de cámara ni por simples verificaciones.

**Lote Z de siete casos — 2026-10-25:** autorización posterior del usuario para
retomar la revisión visual. Diez clips de cinco IDs reciben opciones artísticas
parciales; dos clips corrigen cámara y dos se verifican sin cambios visuales.
No decide la inclusión final de los Z ni añade rutas de combate/mecánicas.

| ID / vistas | Antes | Elección vigente | Límite |
| --- | --- | --- | --- |
| `extreme_evoboost` back/front | Eeveeluciones fijas, patrones0..7 | Orbes9..12 del mismo atlas, conservando trayectorias y tiempos | Opción parcial genérica de energía; no animación nativa exacta de Novena Potencia |
| `genesis_supernova` back/front | Mew fijo, patrones35..46 | Energía psíquica31..33 del mismo atlas | Conserva ADN, BG/FG, impacto y duración; no reemplaza al atacante por un modelo de Mew |
| `lets_snuggle_forever` back/front | Disfraz/silueta de Mimikyu en3/4/5/21..26 | Nube de impacto12 del mismo atlas | Conserva fases, desplazamientos, estrellas y corazones; equivalente parcial, no coreografía exacta del disfraz |
| `savage_spin_out_physical` y `_special`, back/front | Joltik, Volcarona, Scizor, Ribombee y Beedrill fijos en6/7/8/9/23/24/25/26 | Omitir solo esos cameos; conservar capullo/red, arcos e impactos | No sustituirlos por más capullos: ese candidato fue rechazado por duplicación visual |
| `soul_stealing_7_star_strike` back/front | Atacante cortado en el salto al aparecer más allá del rival | Encajar solo esa emergencia con margen8px usando las dimensiones visibles del cuerpo | Conserva tamaño, alpha, tiempos, partículas, receptor y resto del recorrido; sin cambio de imagen |
| `guardian_of_alola` back/front | Transparencias señaladas para contraste | Fuente verificada sin alterar alpha | El receptor termina en225/255; no fingir que el último frame original es opaco |

Las cinco elecciones parciales también aíslan el filtrado de cada región del
atlas para evitar líneas de celdas vecinas, incluidas las placas negras de las
cinemáticas. UI: EQUIVALENTE ARTÍSTICO EXPLÍCITO y PARCIAL. Fuentes fijadas por
nombre, export nativo/sintetizado, atlas y SHA completos de frames/capas. Todos
los PNG y exports originales permanecen intactos. Sin autores ni créditos nuevos;
se conservan los del pack/PRAS y Essentials ya anotados.

Original `.godot/move_z_checks/reference/preview_before.gd`, SHA `a9e655948ae2…`;
fuentes y atlas inspeccionados en `reference/sources.json` y `*_source.png`.
Evidencia final `.godot/move_z_checks/c2a52b27e855bafa/gpu/`, siete láminas
`*_before_after.png`, result/boards/review y snapshot del runner. Review SHA
`1be9f5844bbe15fd7eb487d01c8a07d36eed7f8ab0ebfa911518112347793913`.
317.622 checks PASS; 2.724 estados de captura +16.320 de contrato, cinco parejas
y dos arenas, incluidas Wailord/Pikachu en ambos lados. 80 poses de emergencia
del salto caben; 14 exports manipulados rechazados. Las 280 muestras finales
coinciden con el candidato seleccionado `99afa865d23c88ca`, observado antes.
Esa evidencia es contraste por fases/inputs; no afirmar visionado en tiempo real.

Regresiones: catálogo 5.366.237/118.766 estados/1.822 clips, motivos anteriores
92.247, contexto 6.442, cinco rutas 407 y perfil/laboratorio 1.898, todas PASS.
Renderer `a9e655948ae2…` → `16892e3fcdd2…`; contexto `3bcab4075e9a7662`.
Siete IDs/14 clips cerrados: acumulado **69 IDs/109 clips**, pendientes
**24 IDs/47 clips**. **Inventario vigente: 41 IDs/49 familias/98 clips con alguna
alternativa**, los 36 IDs anteriores más cinco opciones parciales; el ajuste
de cámara y la verificación sin cambios no se suman como sustituciones artísticas.

**Selecciones parciales de motivos — 2026-10-25:** cuatro vistas modificadas,
`behemoth_bash/back`, `/front`, `catastropika/back`, `/front`. Son decisiones
artísticas para usuarios aleatorios, no fallos técnicos de sus fuentes.

| ID | Antes | Elección vigente | Límite |
| --- | --- | --- | --- |
| Embate Supremo `behemoth_bash` | Rostro/escudo de Zamazenta, patrón8 | Patrón9 del mismo atlas, impacto metálico neutro | Motivo de menor huella; no escudo nuevo ni animación nativa exacta |
| Pikavoltio Letal `catastropika` | Insignia de Pikachu, patrones10/11/12 | Omitir solo la insignia; conservar fase eléctrica y BG/FG | Conserva preparación y 50 frames; equivalente genérico para Z secundario, no decide pool final |

Originales conservados, sin editar PNG, frames, capas, mecánicas o clasificación.
Elección PARCIAL y EQUIVALENTE ARTÍSTICO EXPLÍCITO visibles en laboratorio;
ninguna ruta de combate nueva. Fuentes por nombre/lado/SHA completo/atlas;
créditos existentes de autores del pack/PRAS y Essentials, sin autores nuevos.

Evidencia `.godot/move_art_motif_checks/21fa00b2ed6f3953/gpu/`,
`*_before_after.png`, `{result,boards,review}.json`, 88 pares/176 PNG; 64 muestras
coinciden con candidatos observados en `8a1434b41c22a68d`. Original renderer en
`move_art_motif_checks/reference/preview_before.gd`. Gate 92.447/2.136 estados y
regresiones PASS, incluidos Tajo Supremo (atlas compartido) y Rayo sin cambios.
Renderer `d934d0ccf43b…` → `a9e655948ae2…`. Total de cola: 62 IDs/95 clips cerrados,
pendientes 31 IDs/61 clips. **Inventario vigente: 36 IDs/44 familias/88 clips**,
incluyendo dos selecciones parciales nuevas y las 34 anteriores.

**Trayectorias de carga y fundido de reentrada — 2026-10-25:** cuatro vistas
modificadas: `rock_climb/back`, `rock_climb/front`, `take_down/back`,
`take_down/front`. Antes el recorrido local dejaba partes del usuario visibles
cuando la fuente lo cambiaba al borde opuesto. Después el recorrido se proyecta
entre actores; conserva tamaño, giros, colores, prioridades, duración y atlas.
Derribo front también lleva sus estrellas nativas al ancla local del receptor.

Con cuerpos grandes aún quedaban restos, por lo que se modifica expresamente
la **opacidad de presentación** del usuario durante el cambio de borde: Treparrocas
0 f20..24 y 0,5 f19/f25; Derribo 0 f9..13 y 0,5 f8/f14. Resto 1. Fuentes opacas
originales conservadas, sin editar PNG ni exportaciones. Es un ajuste del adaptador,
no un recurso artístico nuevo ni reproducción exacta del original. No aplicarlo
a otras animaciones. Llave Corsé back/front comprobada sin cambios de recurso:
la salida y retorno forman parte de su lanzamiento continuo.

Alcance laboratorio; ninguna mecánica o ruta de combate añadida. Fuentes fijadas
por nombre/export/SHA completo/atlas; créditos de autores del pack/PRAS y Essentials
ya anotados, sin autores nuevos. Original en
`.godot/move_motion_path_checks/reference/preview_before.gd`; diagnóstico
`adc95fa7a8cd1694`, final `4a0319aad2f9b423/gpu/`, dentro de `move_motion_path_checks`.
Tres láminas `*_before_after.png`, `{result,boards,review}.json`, 88 pares completos,
80 capturas de extremos transparentes en GPU, cinco parejas/dos arenas. Gate y
regresiones PASS. Renderer `b7da766584d9…` → `d934d0ccf43b…`. Dos IDs corregidos
y uno verificado: total 60 IDs/91 clips cerrados; pendientes 33 IDs/65 clips.
Inventario de 34 equivalencias completas intacto; ajustes registrados aquí.

**Ajustes locales de presentación — 2026-10-25:** cinco vistas modificadas,
sin sustituir ni editar PNG/animaciones exportadas:

- `acupressure/back` y `/front`: antes la marca señalaba al usuario y destellaba
  el otro cuerpo; después se transfiere el tinte al usuario marcado. Es referencia
  de uso sobre uno mismo en el laboratorio, no implementación de aliado/stats.
- `entrainment/front`: antes el receptor se recortaba abajo durante el descenso;
  después se reduce únicamente la excursión positiva Y hasta caber con margen de
  8 px. Mismos tiempos, X, tamaño, poses ascendentes y fuentes; back intacto.
- `flatter/back` y `/front`: antes el filtro del atlas dibujaba líneas de texels
  vecinos; después cada región se aísla al filtrar. Confeti/paleta/geometría
  conservados, comparados con recortes independientes de las celdas originales.

Niebla Aromática back/front comprobada sin cambio; la ausencia no se reproduce.
Fuentes fijadas por SHA de frames/capas/atlas, sin créditos o recursos nuevos;
se mantienen autores del pack/PRAS y Essentials ya anotados. Alcance laboratorio,
cinco rutas de combate intactas. Ninguna mecánica nueva ni clasificación alterada.

Original `.godot/move_local_effect_checks/reference/preview_before.gd`; evidencia
`.godot/move_local_effect_checks/58e91f150a8fc69c/gpu/`,
`local_effects_before_after.png`, `{result,boards,review}.json`, 84 pares completos
y 96 pares de oráculo de partículas. Sondeos inicial/final `e761bf78c0468ccf` y
`a62342ccd21cad1f`. Gate y regresiones PASS, recortes 30 → 0, error del oráculo
máximo 1/255. Renderer `c712c423db4a…` → `b7da766584d9…`. Tres IDs corregidos y
uno comprobado: total 57 IDs/85 clips cerrados; pendientes 36 IDs/71 clips.
Inventario de 34 equivalencias completas sin cambios; estos ajustes quedan aquí.

**Limpieza parcial de entrada de agua — 2026-10-25:** afecta exactamente a
`hydro_vortex_physical/front`, `hydro_vortex_special/front` y `max_geyser/front`.
Antes: segunda masa separada de `PRAS- Surf FG Opp.png` aparecía como rectángulo
gris/franja inferior f3/f7 por repetición. Después: descartar solo filas 524..1150
de esa textura durante f0..11; desde f12 se conserva el relleno completo original.
Se conserva la cresta superior, posiciones, colores, opacidad, cuerpos, partículas
y tiempos. No descargar ni redibujar PNG, ni sustituir toda la animación. Política
por ID, export nativo, nombre y SHA completos de frames/capas/PNG.

Alcance: renderer del laboratorio; ninguna ruta nueva de combate. Maxichorro
sigue utilizando el equivalente HYDROVORTEX ya registrado. Surf y Onda Tóxica
verificados sin cambio: la orientación de su ola está en la fuente rival; no
aplicarles esta máscara. Tampoco cambiar las cinco vistas back. Créditos PRAS,
autores del pack y Essentials ya registrados; sin recursos ni autores nuevos.

Original preservado `.godot/move_water_checks/reference/preview_before.gd`.
Antes/después `.godot/move_water_checks/085180c565bcc21c/gpu/`:
`water_before_after.png`, `{result,boards,review}.json`, 90 pares/180 PNG.
Sondeos `0e74983d44234990` y `fa75bd02eb57c456`, cinco IDs/tres cámaras.
Renderer `d1861790b529…` → `c712c423db4a…`. Gate GPU y regresiones PASS.
Tres correcciones parciales y dos comprobados cierran cinco casos: acumulado
53 IDs/78 clips, pendientes 40 IDs/78 clips. Inventario de 34 equivalencias
completas intacto; esta máscara parcial queda registrada expresamente aquí.

**Recalibración de Láser Doble — 2026-10-25:** `twin_beam/front` conserva export,
imágenes, forma/tamaño, colores y eje Y. Antes el recorrido proyectado terminaba
a la derecha del cuerpo; después su núcleo final x176 de fuente se lleva al
ancla del objetivo. Política por SHA completo del export, solo coordenada X de
partículas foco3; no regeneración ni sustitución de atlas. Back permanece igual.
Evidencia `.godot/move_beam_endpoint_checks/9a306b629ccf3cfa/gpu/`,
`{result,review}.json` y dos láminas en `sheets/`, 20 vistas/60 tiempos/120 PNG.
Sondeos de cámara antes/después en `move_pending_beam_checks/`
`c60749ecda70ec7e/` y `748c927261000e64/`; SHA y límites en VISUAL_CATALOG.

Pulso Dragón y Lanza Glacial se mantienen sin cambio: contacto tardío/fragmentos
confirmados. Este tramo cierra tres dudas, una reparada y dos verificadas; total
48 IDs/73 clips cerrados y 45 casos pendientes. Renderer `81cb49e7e0b2…` →
`d1861790b529…`. Ningún recurso artístico o crédito nuevo; inventario de 34 IDs
de equivalencias intacto. No habilita nuevas mecánicas ni rutas de combate.

**Ajuste técnico de campos y recorrido — 2026-10-25:** light_screen/front,
mat_block/front, quick_guard/front y reflect/front dejan el cuerpo trasero no
implicado en su plaza; shadow_sneak/front separa la referencia del óvalo viajero
y la de los destellos sobre el objetivo. Antes: actor desplazado del suelo/sombra
o sombra/destello laterales. Después: plazas conservadas y recorrido entre actores
con impacto local. Políticas por SHA completo de frames; ninguna hoja, imagen,
animación exportada, color o tamaño sustituido. **Cinco casos cerrados**, total
45 IDs/69 clips de la cola; quedan 48 casos del baseline. Láser Doble sigue abierto.

Evidencia `.godot/move_projection_checks/c7fb45d23f10eccb/gpu/`: `result.json`,
`review.json`, tres láminas en `sheets/`; 30 vistas/96 tiempos/192 PNG. Sombra Vil
ampliada f5/f10/f16/f20. Renderer `b2610a303d30…` → `81cb49e7e0b2…`; gates y SHA
completos en VISUAL_CATALOG. Fuentes y versiones previas intactas. Sin mecánicas,
rutas, recursos o créditos nuevos; inventario artístico de 34 IDs intacto.

**Ajuste técnico de anclas nativas — 2026-10-25:** trece exportaciones frontales
usaban foco del delantero pese a estar escritas respecto al origen trasero.
Selección por ID/nombre/export/SHA completo de frames: crush_grip, drill_run,
dual_wingbeat, force_palm, poison_sting, poison_tail, pollen_puff, power_whip,
scary_face, sludge, thunderclap, wing_attack, worry_seed. Antes: manos, arcos,
burbujas o humo separados. Después: referencia local del objetivo correcta,
con forma, tamaño, color, partículas de trayectoria, cuerpos y capas conservados.
No se reemplazan imágenes, hojas, fondos o exports. **13 casos/clips frontales
cerrados**, más los 27 IDs/51 clips del grupo inferior; quedan 53 casos del baseline.

Evidencia antes/después `.godot/move_anchor_checks/4cba2c2b751a2842/gpu/`:
`{result,review}.json`, cinco láminas en `sheets/`; 46 vistas/138 tiempos/276 PNG
con controles. Renderer `4fb1e38b88cd…` → `b2610a303d30…`; SHA completo en
VISUAL_CATALOG y reportes. Latigazo f0 ahora toca; separación f6 pertenece al
retroceso nativo, ampliaciones guardadas. Sombra Vil/Láser Doble no se sustituyen
ni se cierran: conservan revisión de trayectoria. Sin nuevas rutas de combate,
mecánicas o créditos por arte; inventario artístico de 34 IDs intacto.

**Ajuste técnico de presentación — 2026-10-25:** reparado el doble cuerpo base en
movimientos propios mediante una selección compartida de pista. Conserva gesto,
tinte y fundido; OppMove invierte roles y Danza Lunar/Venganza necesitan conservar
la pista animada alternativa. Celdas extra de copias intencionales se mantienen.
No se reemplaza imagen, hoja, fondo ni export; el recuento artístico de abajo
permanece en 34 IDs/42 familias/84 clips. Antes: dos bases superpuestas o clon
frontal en otra plaza. Después: una base animada, conservando partículas y ecos.

Casos de la cola cerrados para este defecto: barrier, bulk_up, celebrate, copycat,
detect, dragon_dance, endure, fillet_away, laser_focus, lunar_dance, magic_coat,
magnet_rise, meditate, minimize, moonlight, no_retreat, power_trick, quiver_dance,
rage_powder, rock_polish, sharpen, slack_off, snatch, splash, tidy_up, victory_dance,
work_up. **27 IDs / 51 clips señalados**, ambos lados comparados con controles.
Prueba automática de 97 IDs propios/194 clips, sin afirmar revisión artística
manual de todos ellos. Evidencia antes/después:
`.godot/move_self_body_checks/e6bb10786f264b35/gpu/{result,review}.json`, ocho láminas
en `sheets/`; 76 vistas/152 PNG. El renderer cambia de `9636af2c5cba…` a
`4fb1e38b88cd…`; fuentes y registro original conservados. Relevo, Sustituto y
Teletransporte mantienen sus contextos pendientes. No nuevas rutas de combate.
Detalles y gates en VISUAL_CATALOG. Sin sustitución artística nueva ni commit/push.

**36 IDs de movimientos con equivalencias/referencias alternativas**, repartidos
en **44 familias visuales / 88 clips** al contar contextos y ambos lados. Incluye
los 34 IDs anteriores, sustituciones completas/de fondo/de fase y dos selecciones
parciales de motivos del renderer; no son 36 imágenes repintadas.
Todos son recursos de referencia del laboratorio; una fila NO habilita el movimiento.
Teraexplosión tiene además su enlace normal ya existente dentro de las cinco rutas
reales, no creado por este registro. No se alteran datos, clasificación ni pool.

Fuente de verdad: índice `bb327ada0e33347980260a7e4a8af65e8622171002c64d3ecf56759aa92dbee1`,
`generation_66381a70b65ea385`, más las dos políticas `MOTIF_ART_EXPORTS` del
renderer, fijadas por fuente y registradas arriba. No se altera el índice para
fingir nuevos exports. Cada selección conserva exports por lado, hojas y SHA;
fuentes/pruebas en `VISUAL_CATALOG.md` y `move_art_motif_checks/reference/`.

## 1. Huecos y decisiones artísticas recientes — once IDs

Ambos lados, salvo que el límite indique un cambio solo de fondo/fase.

| Movimiento / ID | Antes o motivo | Selección vigente y límite |
| --- | --- | --- |
| Cañón Armadura `armor_cannon` | ARMORCANNON / firepoison.png: motivo rectangular/moteado no deseado | FLAMEBURST (Pirotecnia), exports propios de ambos lados; equivalente artístico, no reparación |
| Pájaro Osado `brave_bird` | Atlas nativo incompleto | SKYATTACK (Ataque Aéreo) |
| Picado Supersónico físico `supersonic_skystrike_physical` | Atlas incompleto; Z secundario | SKYATTACK; no secuencia Z exacta |
| Picado Supersónico especial `supersonic_skystrike_special` | Mismo hueco de atlas; Z secundario | SKYATTACK; no secuencia Z exacta |
| Infortunio `hex` | Patrón ausente en Grudge | SPITE (Rencor), dirigido al objetivo |
| Láser Prisma `prismatic_laser` | Atlas incompleto; luego PHOTONGEYSER rechazado por pico exagerado | PSYBEAM (Psicorrayo), ambos exports; anillos psíquicos, NO láser nativo |
| Descanso `rest` | Patrón ausente en Slack Off | SLEEPTALK (Sonámbulo), símbolo Z; no curación/sueño ejecutados |
| Ciclón `twister` | Atlas incompleto | HURRICANE (Vendaval) |
| Remolino `whirlwind` | Atlas incompleto | GUST (Tornado); no retirada/cambio de Pokémon |
| Premonición `future_sight` | Fondo ausente en preparación | FUTUREDUMMY del pack, SOLO impacto; preparación/espera externas pendientes |
| Truco Floral `flower_trick` | Fondo `uwu.png` ausente | FLOWERTRICK; solo fondo → `PRAS- Petal BG.png`; conserva celdas y tiempos originales |

Los diez huecos nativos siguen anotados y sin reparar; Cañón Armadura es una
decisión artística sobre una fuente reproducible, no un undécimo hueco nativo.

## 2. Los diecinueve Maxi/Dinamax — equivalentes, no animaciones Max originales

Ambos lados. La fuente vigente es la del catálogo por lotes, no necesariamente
la del piloto histórico de 70 clips.

| Movimiento / ID | Referencia visual vigente |
| --- | --- |
| Maxiciclón `max_airstream` | HURRICANE |
| Maxisombra `max_darkness` | MALICIOUSMOONSAULT |
| Maxignición `max_flare` | INFERNOOVERDRIVE |
| Maxibicho / Maxinsecto `max_flutterby` | SILVERWIND (Viento Plata); reemplaza SAVAGESPINOUT con otros Pokémon incrustados |
| Maxichorro `max_geyser` | HYDROVORTEX |
| Maxibarrera `max_guard` | BANEFULBUNKER |
| Maxihelada `max_hailstorm` | SUBZEROSLAMMER |
| Maxipuño `max_knuckle` | ALLOUTPUMMELING |
| Maxitormenta `max_lightning` | GIGAVOLTHAVOC |
| Maxionda `max_mindstorm` | SHATTEREDPSYCHE |
| Maxiácido `max_ooze` | ACIDDOWNPOUR |
| Maxiflora `max_overgrowth` | BLOOMDOOM |
| Maxiespectro `max_phantasm` | SHADOWBALL |
| Maxitemblor `max_quake` | TECTONICRAGE |
| Maxilito `max_rockfall` | CONTINENTALCRUSH |
| Maxiestela `max_starfall` | TWINKLETACKLE |
| Maximetal `max_steelspike` | CORKSCREWCRASH |
| Maxiataque `max_strike` | BREAKNECKBLITZ |
| Maxidraco `max_wyrmwind` | DEVASTATINGDRAKE |

Viento Plata usa una vista rival sintetizada/declarada porque no hay OppMove
propio en esta fuente. Las diferencias entre exports y lados de toda la tabla
se conservan en los manifests; no asumir que todos tienen export rival nativo.
Estas equivalencias no implementan Dinamax, cambios de estadísticas ni climas.

## 3. Teraexplosión, Prensa Metálica y referencias manuales — cuatro IDs

| Destino / contexto | Referencia vigente | Límite |
| --- | --- | --- |
| Teraexplosión `tera_blast` | TECHNOBLAST | Referencia normal única, no diecinueve animaciones de tipo |
| Prensa Metálica `hard_press` | HEAVYSLAM | Equivalente de impacto, no cambio de fórmula de daño |
| Adaptación `nature_power/neutral` | TRIATTACK | Referencia manual, no detección automática del entorno |
| Adaptación `nature_power/electric` | THUNDERBOLT | Ídem |
| Adaptación `nature_power/grassy` | ENERGYBALL | Ídem |
| Adaptación `nature_power/misty` | MOONBLAST | Ídem |
| Adaptación `nature_power/psychic` | PSYCHIC | Ídem |
| Daño Secreto `secret_power/neutral` | BODYSLAM | Referencia manual, no ejecución del efecto ambiental |
| Daño Secreto `secret_power/electric` | THUNDERSHOCK | Ídem |
| Daño Secreto `secret_power/grassy` | VINEWHIP | Ídem |
| Daño Secreto `secret_power/misty` | FAIRYWIND | Ídem |
| Daño Secreto `secret_power/psychic` | CONFUSION | Ídem |

## 4. Historial que no debe confundirse con la selección actual

| Destino | Referencia anterior descartada | Vigente |
| --- | --- | --- |
| Maxiciclón | SUPERSONICSKYSTRIKE, patrón ausente | HURRICANE |
| Maxiespectro | NEVERENDINGNIGHTMARE, cinematográfica de franjas | SHADOWBALL |
| Láser Prisma | PHOTONGEYSER, pico enorme del atlas; no era el Pokémon deformado | PSYBEAM |
| Maxibicho | SAVAGESPINOUT, Pokémon dibujados dentro | SILVERWIND |
| Cañón Armadura | ARMORCANNON/firepoison.png, motivo rectangular de veneno | FLAMEBURST |

El Maxibicho del piloto histórico se conserva con advertencia HISTÓRICA en UI.
Los dibujos originales no se han sobrescrito para hacerlos pasar por otra cosa.

## 5. Ajustes de presentación / recursos añadidos que NO son una sustitución de ataque

- **Martillo Colosal**: no sustituido; impacto metálico nativo de 23 frames,
  sin martillo literal. Garrote Liana y sus tres variantes son exports de
  Toxillian, no un reemplazo genérico ni implementación de máscaras.
- **Cámara/anclas**: `hyper_drill`, `rolling_kick`, `upper_hand`,
  `chilly_reception`, `malignant_chain`; posición/foco corregidos, no dibujos.
- **Geometría del haz**: `moongeist_beam`, `oblivion_wing`; base geométrica
  corregida, mismos dibujos/colores/celdas/tiempos.
- **Orden de capas**: `clangorous_soulblaze`; prioridad adaptada, mismo arte.
- **Lengüetazo**: se omite una dependencia ausente cuya opacidad es siempre cero;
  no se sustituye una partícula visible.
- **Gigaimpacto / Resplandor**: recursos de fondo externos fijados por SHA para
  recuperar dependencias ausentes. El de Gigaimpacto requiere escala ×2 nearest;
  detalle de autoría/procedencia/licencias en el cuaderno.
- **Climas, retirada, Sustituto y Transformación**: demo opcional separada,
  con Common:Rain/Hail/Snow, muñeco original y apariencia del rival tomada del
  catálogo. No son nuevos sprites de especies ni integración real. Snow/Hail
  comparten arte en esta fuente y eso se declara.
- **Tono nativo de hojas**: treinta IDs procesados automáticamente según el hue
  original, sin redibujar ni alterar alfa/geometría. No son treinta sustituciones
  artísticas: `aerial_ace`, `attract`, `blizzard`, `blue_flare`, `corrosive_gas`,
  `defense_curl`, `diamond_storm`, `dragon_rage`, `ember`, `expanding_force`,
  `fire_pledge`, `grass_whistle`, `iron_defense`, `lash_out`, `light_that_burns_the_sky`,
  `magic_powder`, `meteor_assault`, `oblivion_wing`, `octolock`, `overdrive`,
  `poltergeist`, `psyshield_bash`, `roar_of_time`, `shell_side_arm`, `sing`,
  `sleep_powder`, `stun_spore`, `twineedle`, `wicked_blow`, `zen_headbutt`.

## Qué queda — corte del 2026-10-24

- **Cero dudas artísticas señaladas abiertas de la primera pasada por muestras**.
  No equivale a certificar toda la fluidez/arte de cada fotograma.
- **Seis presentaciones externas sin integración real**: Danza Lluvia, Granizo,
  Paisaje Nevado, Fría Acogida, Sustituto y Transformación; sí tienen demo opcional.
- **Diecinueve movimientos secundarios/exclusivos sin referencia reproducible**,
  apartados por la prioridad acordada, no borrados del dataset.
- **Conexión al combate todavía pendiente para el grueso del catálogo**: 900 IDs
  reproducibles en laboratorio no significan 900 conectados. Siguen cinco rutas
  reales: Garrote Liana, Teraexplosión normal, Lanzallamas, Rayo y Rayo Hielo.
  No dar una cifra única sumando estos grupos: se solapan y tienen soportes distintos.

Los diez huecos originales siguen cubiertos por equivalentes, no restaurados.
Las fuentes completas, hashes, diagnósticos y pruebas están en `VISUAL_CATALOG.md`,
`move_art_choices.py`, `move_visual_equivalents.py` y los manifiestos vigentes.
