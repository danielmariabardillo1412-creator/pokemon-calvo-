# Reglas de selección del Randomlock

Decisión de objetos vigente (2026-10-28): el usuario delega y pide respetar los
nombres indicados por su amigo. Se excluyen Lupa y Polvo Brillo; no se amplía
automáticamente a Incienso Suave. El veto a todo revivificador incluye Maxipanal,
además de Revivir, Máximo Revivir, Hierba Revivir y Ceniza Sagrada. Se excluyen
las 36 cartas. Total 43 IDs en `config/item_selection_v1.json`. Es un filtro de
selección con soporte explícito adicional, no borrado de definiciones/partidas.
Poké Muñeco tiene función de escape: no se confunde con decoración sin función.
Botín/tiendas nuevos aún no existen. Detalle en `../current/ITEM_FOUNDATION.md`.

Vigente 2026-10-28: el perfil propio Gen9 + Dinamax se documenta en
`../current/BATTLE_PROFILE.md`. No cambia la política de contenido: 900 IDs
permitidos y 19 excluidos, Z solo de daño. No se aplica la propuesta de uso
compartido Mega/Z/Max ni nuevas prohibiciones de competitivo. Sigue pendiente
integrar las reglas personalizadas de randomización, vidas y muerte definitiva.
Los apartados siguientes conservan antecedentes de perfiles separados.

Dobles F12 (2026-10-27): los 11 movimientos de contexto doble están conectados
en un ensayo nativo con clones y checkpoint separado. Conserva las exclusiones
actuales. No activa automáticamente perfiles especiales, recompensas de dobles,
presupuesto común Mega/Z/Max, ni reglas nuevas de randomlock. Gen9 default y
Gen8/Max siguen separados hasta acordar el perfil final conjunto.

Aplicación al mapa actual: `field_demo.tscn` usa la conexión nativa de forma
predeterminada. Las exclusiones se comprueban también al abrir/restaurar combate
y cargar la colección. El guardado del mapa no activa por sí mismo learnsets
aleatorios, muerte definitiva/cuatro vidas ni un presupuesto común Mega/Z/Max.
La IA rival permanece básica. Detalle: `../current/FIELD_NATIVE_INTEGRATION.json`.

## Decisión Z vigente y solicitudes futuras — 2026-10-27

Respuesta expresa del usuario/amigo: **Z de daño sí; TODOS los Z de estado no**.
Se aplica `z_moves.decision=damage_only`: 52 IDs de daño y uno de estado,
`extreme_evoboost`, excluido. También se bloquean Z-Conversión, Z-Truco,
Z-Deseo Cura, Z-Aromaterapia, Z-Campana Cura y cualquier Z de estado generado;
no se inventan IDs de datos. Los movimientos normales de estado se conservan.
Z y Max son acciones generadas en combate, no movimientos aprendidos ordinarios.

Actualización expresa del usuario: **excluir** Cerco Dimensión (`hyperspace_fury`),
Fotodestrucción Apocalíptica (`light_that_burns_the_sky`) y Gigarrayo Fulminante
(`10_000_000_volt_thunderbolt`). Sus usuarios/formas no forman parte del juego;
no añadir las formas, inventar usuarios ni rediseñar gorras para recuperarlos.
Hoopa Desatado es una forma de Hoopa, no otra especie. Hoopa normal, su movimiento
Paso Dimensional (`hyperspace_hole`) y Pikachu normal permanecen permitidos.
La ambientación romana/vikinga refuerza la exclusión de gorras modernas; no es
una petición de crear versiones de esas gorras. Estos ataques NO quedan pendientes.

50 Z de daño permitidos/conectados; tres IDs Z excluidos (uno de estado y dos
por forma/usuario). Total de movimientos: 889 acciones de individuales ensayadas,
11 de contexto doble y 19 excluidos = 919. Los apartados
posteriores de 53 Z pendientes son antecedentes superados por esta decisión.
Informe vigente: `../current/Z_MOVE_INTEGRATION.json/CSV`.

Compartir un único uso entre Mega/Z/Gigamax sigue **propuesta no confirmada**.
Los vetos de KO directo/evasión/daño fijo temprano investigados después quedan
aplazados por el usuario; no se añaden al perfil ni se borra su implementación.

Para objetos, **anotado sin implementar**: excluir decoración sin función y todo
objeto que reviva (Revivir, Máximo Revivir, Hierba Revivir, Ceniza Sagrada).
Revisar Lupa/Polvo Brillo: Lupa aumenta precisión; no equivale a Incienso Suave.
Lista de objetos y adaptación narrativa de futuristas aún no cerradas. El veto
a objetos revivificadores no resuelve automáticamente Plegaria Vital; se conserva
su prueba normal previa y la muerte permanente pertenece a la fase posterior.

### Los 11 movimientos de contexto doble se conservan

| Movimiento | Uso que requiere varios Pokémon activos |
| --- | --- |
| Cede Paso / Último Lugar | Alterar cuándo actúa otro participante |
| Cambio de Banda | Intercambiar la posición con el compañero |
| Niebla Aromática / Motivación / Bramido Dragón | Beneficiar estadísticas o críticos de compañeros |
| Refuerzo | Aumentar el daño del compañero |
| Señuelo / Polvo Ira / Foco | Redirigir hacia quién van los ataques |
| Manos Juntas | Acción cosmética con un compañero; sin ventaja competitiva |

No todos están técnicamente prohibidos o fallan siempre en individuales; varios
carecen allí de utilidad. Se mantienen elegibles por decisión del usuario y con
sus pruebas nativas de dobles, sin inventar un aliado ni efectos de individuales.
La conexión/comandos/presentación Godot con varios activos sigue pendiente.
La aleatorización futura deberá respetar contexto y requisitos; esta fase no
implementa ese generador ni un modo doble nuevo.

## Aclaración de alcance visual — 2026-10-26

**Actualización tras implementación:** las 57 regionales ordinarias ya están
integradas con sus datos propios en el juego local. Se incorporan los shiny
existentes: 1.011 parejas base + 57 regionales; no se crean los 14 ausentes.
Probabilidad provisional configurable 1/4.096, con RNG cosmético aislado.
Las seis especies base descartadas siguen fuera del selector ordinario; no se
elimina su arte histórico. Referencia: `../current/POKEMON_VARIANTS_INTEGRATION.json`.
El recuento siguiente describe el inventario y el estado **anterior** a integrarlo.

El usuario confirma incluir los shiny que ya tengan recursos disponibles y cuya
integración sea sencilla. No rehacer ni generar las variantes shiny de los 14
Pokémon cuyos recursos normales se prepararon como candidatos propios. La
exclusión anterior de todos los shiny queda sustituida por este alcance parcial.
Esto fija el criterio; no activa todavía encuentros shiny ni su presentación.

Las formas regionales ordinarias deben incluirse, como Vulpix de Alola. Recuento
de la auditoría local `cierre_visual_v1/forms_coverage.json`, consultada el
2026-10-26: 57 variantes regionales ordinarias (18 Alola, 19 Galar, 16 Hisui,
4 Paldea, contando las tres razas de Tauros). Todas tienen pareja frontal/espalda
normal y shiny en el inventario previamente decodificado; los archivos referidos
siguen existiendo. Ninguna tiene entrada propia en el manifiesto visual activo,
que contiene solo las 1.025 especies base. No confundir recursos disponibles con
formas integradas y jugables. Este recuento no incluye gorras de Pikachu, Totem
ni el estado Zen de Darmanitan; no decide la inclusión de esas otras variantes.

La auditoría anterior recoge 1.011 parejas shiny de especies base y 450 registros
de formas alternativas con parejas normales/shiny. Son coberturas de fuentes,
no un pool final permitido ni certificación de integración o aspecto.

## Aplicación al perfil de combate local — 2026-10-26

`live_move_profile.gd` aplica estas exclusiones y la decisión Z pendiente al
servidor, menú e IA de individuales, además de exigir soporte de mecánica.
No se han modificado las listas confirmadas: Max conserva su arte/prioridad y
Z no pasa automáticamente a incluido. Los movimientos con lógica parcial se
retienen en catálogo pero no se admiten como completos. Ally Switch es solo dobles.
La asignación aleatoria de movimientos a niveles no se implementa en esta fase.

Actualización tras el lote de etapas: **585 admitidos / 334 no disponibles**,
con 265 mecánicas pendientes; las exclusiones/decisión Z se conservan. Desglose y nombres en
`../current/LIVE_MOVE_UNAVAILABLE.csv`, alcance en `LIVE_MOVE_INTEGRATION.json`.


Decisiones del usuario y su amigo, fijadas el 2026-10-25. Este cuaderno conserva
las reglas de contenido para futuras fases. No cambia el cálculo de daño, la
tabla de tipos, los datos canónicos ni las reglas de Battle Core.

La política ejecutable es `config/randomlock_content_v1.json`; su lector es
`modules/gameplay/randomlock_content_policy.gd`. El informe reproducible está
en `docs/current/CONTENT_POOL_AUDIT.json`. Estos archivos definen selección,
no una promesa de que todas las mecánicas ya sean ejecutables.

## Movimientos descartados

Excluir Salpicadura (`splash`) y los movimientos exclusivos de spin-offs/títulos
indicados. La exclusividad importa: un movimiento introducido en Leyendas Arceus
que después pasó a juegos principales se conserva.

Actualmente se descartan **15 IDs presentes**:

- Salpicadura: `splash`.
- Exclusivos de compañeros de Let's Go: `zippy_zap`, `splishy_splash`,
  `floaty_fall`, `pika_papow`, `bouncy_bubble`, `buzzy_buzz`, `sizzly_slide`,
  `glitzy_glow`, `baddy_bad`, `sappy_seed`, `freezy_frost`, `sparkly_swirl`,
  `veevee_volley`.
- Cambiapoder, exclusivo de Leyendas Arceus: `power_shift`.

Los 18 movimientos oscuros exclusivos de Colosseum/XD no están entre los 919
movimientos locales; sus IDs exactos quedan bloqueados para una futura importación
en la política. No aplicar un filtro por prefijo `shadow_`: Bola Sombra, Garra
Umbría y los otros movimientos ordinarios con ese prefijo se mantienen.

No excluir por ser antiguo, por generación completa o solo por estar marcado
como Past/Unobtainable. No quitar Headlong Rush, Mystical Power, Lunar Blessing,
Take Heart, Roar of Time o Spacial Rend por haber aparecido en Leyendas Arceus.
Nuevas importaciones requieren revisar procedencia/exclusividad antes de ampliar
el perfil: el dataset actual no trae metadatos suficientes para deducirlo solo.

## Decisión Z pendiente y Dinamax conservado

Se preguntó al usuario si quiere excluir todos los Z. **Todavía no hay respuesta**.
Los 53 IDs Z se marcan `pending`, separados de los descartes confirmados y fuera
de la vista del pool de juego; siguen en el archivo de investigación. El usuario
ha autorizado después retomar su revisión visual: los siete casos pendientes
ya están cerrados en `.godot/move_z_checks/c2a52b27e855bafa/gpu/review.json`.
Esa autorización no decide la inclusión final de todos los Z. No presentarlos
como descartados definitivamente ni seguir manteniendo esos siete en la cola artística.

Se mantienen los **19 Max/Dinamax** por la prioridad explícita anterior. Teraexplosión
y Garrote Liana también se conservan. Conservar una referencia visual Max no
implementa Dinamax ni permite aprender un Max como movimiento ordinario.

Los cinco Torque del Starmóvil siguen como huecos diferidos; no se ha ordenado
descartarlos. La política Z pendiente tampoco autoriza retirarlos.

## Habilidades excluidas

Hay **16 IDs únicos**; Truant y Forecast estaban repetidos en el mensaje:

`truant`, `defeatist`, `run_away`, `normalize`, `schooling`, `klutz`,
`gulp_missile`, `honey_gather`, `anticipation`, `forewarn`, `shields_down`,
`forecast`, `no_guard`, `frisk`, `soundproof`, `wonder_guard`.

No asignar una habilidad sustituta ni descartar automáticamente todas las
especies que originalmente la tengan. La futura asignación aleatoria debe usar
el pool permitido y respetar las reglas de asignación que se concreten entonces.

## Especies y formas excluidas

| Exclusión confirmada | Alcance |
| --- | --- |
| Wishiwashi | Todas sus formas |
| Minior | Todas sus formas |
| Castform | Sus cuatro formas: normal, sol, lluvia y nieve |
| Nincada, Ninjask y Shedinja | Los tres, confirmado expresamente por el usuario |
| Pikachu con gorra | Original, Hoenn, Sinnoh, Unova, Kalos, Alola, Partner y World Cap |

Pikachu normal, Raichu y las formas regionales ordinarias se conservan. No ampliar
la exclusión de gorras a los disfraces de Pikachu sin una decisión del usuario.
El filtro de formas recibe la especie base canónica; el futuro catálogo deberá
validar además que cada forma pertenezca a esa especie.

## Aprendizaje y alcance de integración

La norma comunicada: conservar los niveles donde la especie aprende movimientos
y sustituir el movimiento de cada posición por otro aleatorio permitido. No
repartir todos los movimientos desde nivel 1 ni cambiar esos niveles. El
randomizador final de learnsets todavía no se implementa en esta fase.

Futuros generadores de encuentros/equipos, elección de formas, habilidades y
movimientos iniciales o por nivel deberán consumir esta política. Elegibilidad
del perfil y soporte runtime son filtros distintos y ambos son necesarios.
No podar los learnsets canónicos ni inventar habilidades de reemplazo para
forzar esta integración sobre los tests o las demos técnicas históricas.

Integración actual: `JUGAR_PRUEBA_ATAQUES.cmd` abre el catálogo por lotes con
`--game-pool`. El laboratorio filtra movimientos descartados y pendientes;
si la política es inválida bloquea esa vista. Desactivar «Solo pool de juego»
abre el archivo íntegro para investigación. Las demos técnicas de combate y
los catálogos históricos conservan sus definiciones; esto no es todavía un
Randomlock completo con los vetos aplicados a todos sus productores.

## Resultado del cruce con el trabajo visual

919 movimientos de datos: 15 descartados confirmados, 53 Z pendientes y 851
candidatos elegibles. 373 habilidades → 357 candidatas. 1.025 especies → 1.019
candidatas. Las formas son una regla aparte, no otras ocho especies.

El archivo visual conserva **900 IDs/1.822 clips**. La vista del pool ofrece
**846 IDs/1.714 clips**; oculta cuatro clips de Splash/Power Shift y 104 clips Z
pendientes. Ninguna imagen, fuente, atlas ni sustitución artística cambia aquí.

De los 19 huecos de recursos, **13 son los exclusivos descartados de Let's Go**:
dejar de buscarlos. Quedan cinco Torque activos y 10,000,000 Volt Thunderbolt
en espera de la decisión Z. No confundir estos huecos con los 19 casos de contexto.

La cola anterior tenía 31 casos, incluidos siete Z en espera. Al retomarlos por
instrucción del usuario se cierran sus 14 clips con evidencia visual propia;
después se revisan los 24 restantes y se cierran los cinco contrastes (nueve
clips de cola). Acumulado: **74 IDs/118 clips cerrados**. Restan **19 IDs/38 clips
de integración externa**, con sus fuentes nativas ya revisadas y requisitos
identificados. Las reviews anteriores permanecen intactas; ningún descarte ni
dependencia externa sin resolver cuenta como PASS artístico.

## Repetir la comprobación

Desde la raíz, con Godot 4.7:

```powershell
& 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://tools/visual/audit_randomlock_content.gd
& 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://tests/gameplay/randomlock_content_test_runner.gd
```

La auditoría verifica los SHA del baseline inmutable y que la review corresponda
al renderer actual. No regenera datos ni altera la review original. Tras cerrar
otro lote, pasar `-- --review=res://ruta/a/review.json` para cruzar esa nueva cola.
Después de una decisión Z explícita actualizar `z_moves.decision`, las expectativas
del contrato de pruebas, este cuaderno y el informe; ejecutar ambos comandos.

Evidencia local de este tramo: 1.898 comprobaciones del contrato, 6.442 de contexto
y 407 de las cinco rutas de combate, todas PASS. No certifica un nuevo commit/CI.

## Procedencias

- [Pokémon Showdown: movimientos](https://github.com/smogon/pokemon-showdown/blob/master/data/moves.ts),
  blob `a3b7cd8943a95a45e8775370a02130e66d788614`: isZ, isMax y LGPE.
  Los aliases locales Z físicos/especiales conservan sus IDs separados.
- [Exclusivos de compañeros Let's Go](https://bulbapedia.bulbagarden.net/wiki/Partner_Pok%C3%A9mon_(Let%27s_Go,_Pikachu!_and_Let%27s_Go,_Eevee!)).
- [Movimientos oscuros](https://bulbapedia.bulbagarden.net/wiki/Shadow_Moves).
- [Power Shift](https://bulbapedia.bulbagarden.net/wiki/Power_Shift_(move)).

Estas consultas clasifican IDs; no incorporan recursos artísticos ni créditos
nuevos. Las atribuciones de los recursos existentes siguen en VISUAL_CATALOG.
