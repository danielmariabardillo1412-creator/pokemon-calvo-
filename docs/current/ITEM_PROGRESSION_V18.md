# V18 — Huevo Suerte y Piedra Eterna en la progresión

Base: `28c550a4`. Se continúa en la copia organizada, con un escritor. Este lote
conecta efectos de progresión reales además de permitir los dos objetos equipados
en el motor nativo; no cambia datos, arte, vetos, paquetes, algoritmos de combate,
RNG ni esquema de guardado.

## Comportamiento conectado

**Huevo Suerte (`lucky_egg`).** Multiplica por 3/2, con división entera, la
recompensa de experiencia de combate del portador. Se aplica después de obtener
la parte individual del perfil vigente `calvo_progression_v1`. No cambia la parte
de los compañeros ni otorga experiencia a los debilitados. No multiplica EXP
obtenida mediante caramelos ni cambia las seis curvas de nivel.

La referencia Essentials consulta primero el objeto actual y después el objeto
inicial. Por ello, un Huevo Suerte activo al iniciar sigue dando bonificación si
se pierde mediante Desarme, se lanza o se entrega con Truco durante ese combate.
También cuenta uno obtenido durante el combate. Uno ya marcado como consumido
al iniciar no cuenta. No se apilan dos multiplicadores por cumplir ambas rutas.

El combate nativo reconstruye ese contexto desde su `origin.p1` existente al
aplicar el resultado, incluido después de guardar/cargar. Las sesiones legado
salvaje y entrenador conservan un diccionario transitorio de IDs iniciales por
instance_id y lo limpian al terminar; no se añaden campos de partida. Su guardado
legado ya rechaza combates activos, por lo que no se inventa una restauración de
ese estado que su formato no admite.

La recompensa se limita al espacio real que queda hasta el máximo de experiencia.
Los eventos anuncian solo lo realmente concedido; un Pokémon al máximo no recibe
un evento de experiencia ficticio. Antes, la reconciliación podía anunciar el
importe solicitado aunque la experiencia persistente ya estuviera limitada.

**Piedra Eterna (`everstone`).** Bloquea las evoluciones por nivel soportadas
mientras esté equipada y activa. Se centraliza la condición en el contexto de
EvolutionSystem: la progresión de combate y los caramelos usan la misma regla.
Quitarla o perderla vuelve a permitir esas candidatas; una intención de evolución
obsoleta se rechaza en la API que comprueba la criatura poseída. No consume la
piedra ni impide subir de nivel o aprender movimientos. No se amplían en este lote
los disparadores de intercambio, formas o condiciones todavía no soportadas.

## Organización

`progression_held_items.gd` contiene únicamente las reglas puras y la extracción
de objetos iniciales. ProgressionSystem lo aplica a recompensas, EvolutionSystem
lo usa en su contexto de nivel y FieldGrowth conserva la misma puerta. Las tres
sesiones solo proporcionan el contexto de su dueño; no calculan otra fórmula.

Los descriptores nativos de ambos objetos contienen nombre, generación 2 y potencia
30 de Lanzamiento. No tienen callbacks de combate. Sus efectos de experiencia y
evolución se ejecutan en los sistemas de progresión, fuera del simulador.

## Fuentes y créditos

Maruno17 y colaboradores, Pokémon Essentials, commit
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`:

- `009_Battle_ItemEffects.rb`: manejador ExpGainModifier de Lucky Egg, exp * 3 / 2.
- `003_Battle_ExpAndMoveLearning.rb`: selección de objeto actual y fallback inicial.
- `001_Pokemon.rb`: comprobación de Everstone en las comprobaciones de evolución.

Metadatos: RHH y colaboradores, pokeemerald-expansion, commit
`8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`, `src/data/items.h`. Ambos tienen
potencia 30 y efectos de mundo declarados, no se clasifican como neutros globales.
Generación contrastada con la fuente pret/pokecrystal ya fijada en V16.
Se reutilizan copias locales, con SHA-256 y prueba de lectura en el JSON; no se
descarga otro dataset ni se ejecutan Ruby/C de estas referencias.

## Verificación

Ejecutar `python tools/verification/run_progression_items_v18.py`.
Resultados, hashes y evidencia: [ITEM_PROGRESSION_V18.json](ITEM_PROGRESSION_V18.json).

- 4.304 casos sobre las 1.076 especies/formas permitidas: sin Huevo, activo,
  perdido con contexto inicial y ya consumido al comenzar. Se comparan XP, evento
  exacto y ausencia de cambios en otros datos del individuo.
- Redondeo entero, máximo de experiencia, evento final parcial, varios receptores,
  compañeros debilitados y caramelos sin multiplicador.
- Piedra activa/consumida, otro objeto y sin objeto: misma decisión al subir por
  combate o caramelo, más rechazo de una intención de evolución obsoleta.
- Victorias reales de las sesiones legado salvaje y entrenador; fixture explícito
  de objeto perdido después del inicio para comprobar su contexto y publicación.
- Seis rutas nativas reales: conservar, Lanzamiento, Truco, Desarme, obtener el
  Huevo con Truco y entrar con uno ya consumido. Restauración antes del KO,
  revisión obsoleta rechazada, recompensa solo al liquidar y sin duplicar XP.
- Dos rutas del mapa con equipar desde mochila, guardar/cargar combate, victoria,
  parte ordinaria de compañeros, caramelo EXP con Huevo y retirada de Piedra para
  recuperar candidatas. El resultado y las unidades físicas persisten al cargar.
- Regresiones del núcleo, caramelos, curvas, aventura nativa, entrenadores,
  campo/restauración y prueba gráfica. Guard propio con hash completo al cerrar.

Se conservan los intentos fallidos. El primer test tenía una variable heredada
repetida y dos tipos sin declarar. Otro asumía una curva de Mew incorrecta para
dos expectativas; se sustituyeron por la tabla de referencia verificada, sin
alterar datos. Una regresión antigua necesitaba crear su carpeta de salida: el
runner prepara esa carpeta sin cambiar las aserciones ni contar el error como PASS.

## Límites y pendientes

El reparto/base de experiencia sigue siendo el perfil existente, con suma y
redondeo propios; no se certifica la fórmula completa de una generación oficial,
sus bonus de entrenador/intercambio/afecto ni un Repartir Exp nuevo. El alcance de
Piedra es la evolución por nivel disponible, no todas las excepciones históricas.

El registro nativo pasa a 606/625 equipables permitidos; quedan 19 sin definición
revisada. Los 76 usos de campo y 16 bolas se cuentan aparte de estos dos efectos
de progresión. Los ocho potenciadores desde mochila de combate, mentas/IV y los
otros sistemas del mundo continúan pendientes.
