# Objetos V10 — Cápsula Habilidad y Parche Habilidad

Base: `ce4a4243`. El usuario devuelve el trabajo a Codex porque OpenCode no está
disponible. El encargo externo O001 no llegó a ejecutarse. Se conserva su plano
y guard histórico; esta implementación utiliza `run_field_ability_v10.py` y su
manifiesto propio. No se atribuye una revisión independiente a otro agente.

## Mecánica y representación

Perfil de objetos: Escarlata/Púrpura. Cápsula alterna las dos normales distintas;
no obtiene ni elimina una oculta. Parche pasa de normal a oculta y de oculta a
la primera normal. No se recuerdan slots anteriores ni se elige una habilidad
al azar. Si dos normales comparten ID, la Cápsula no tiene efecto, pero Parche
puede obtener una oculta distinta sin inventar cuál normal genética tenía.

Se usan `ability_slots` de la especie/forma actual, con posiciones PokéAPI
1/2/3 y flags ocultos validados. Una habilidad ajena, metadatos insuficientes o
un ID que representa a la vez normal y oculta se rechazan explícitamente.
La API de los objetos no cambia formas ni intenta normalizar un Rockruff
especial. No se añaden campos al Pokémon o al formato de guardado.

La política filtra el destino real. Por ejemplo, Cápsula de Guts hacia No Guard
en Machop está bloqueada; no se redirige hacia Steadfast ni se elimina el veto.
Un Pokémon ya poseído con una habilidad vetada sí puede cambiar hacia un destino
permitido; esto no habilita nuevos encuentros ni habilidades prohibidas.

Parche hacia Modo Daruma queda como `DEPENDENCY_MISSING` sin consumo, tanto en
Darmanitan como en Darmanitan de Galar. Es el único destino con varias habilidades
del catálogo que requiere una ruta automática de forma pendiente. El worker
sí realiza la transición, pero el espejo local la rechaza explícitamente como
`temporary_form_not_supported`. Una prueba nativa reproduce ese límite sin mutar
la colección. Revertir desde una Modo Daruma ya existente hacia la primera
normal sí funciona; no se convierte esta dependencia en un veto de contenido.

Solo puede variar `ability_id` y una unidad de inventario. No hay amistad extra,
recalculo de estadísticas, cura, PP, nueva naturaleza o modificación de IV/EV.
Se preservan identidad, forma, shiny, estado, equipo y relojes. Se mantiene la
frontera de KO/transformación temporal y guard de actividad/propiedad existente.

## Arquitectura y mochila

`field_ability_effects.gd` adapta slots y trabaja sobre una candidata, sin IO,
inventario, UI o RNG. El dispatcher lo incorpora sin duplicar reglas de combate.
El servicio filtra la política, prepara el inventario y publica al final, además
de verificar que el serializador no ha cambiado otros campos del Pokémon.

La mochila muestra habilidad actual y destino antes de pulsar Usar. El token
de estado compartido con los caramelos comprueba si cambió el Pokémon, inventario,
propiedad o binding; una vista obsoleta refresca y exige otra acción explícita.
Esto también cubre una vista que no tenía destino válido y pasa a tenerlo tras
un cambio externo: el primer clic refresca; solo una acción posterior aplica.
La extracción del nombre es presentación de la definición existente, sin cambiar
el idioma de los datasets. El resultado informa de la habilidad nueva.

No se duplican los efectos de habilidades: el worker Showdown ya los calcula.
La publicación conserva el agregado y la ubicación equipo/PC. La UI de PC no se
amplía; sus rutas se verifican usando el servicio de propiedad existente.

## Referencias y créditos

- Pokémon Essentials, Maruno17 y colaboradores, commit
  `8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`,
  `Data/Scripts/013_Items/002_Item_Effects.rb`: Cápsula y comportamiento normal
  hacia oculta. Su handler de Parche antiguo no se copia como si fuera Gen IX.
- rh-hideout y colaboradores, pokeemerald-expansion, commit
  `8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`,
  [src/party_menu.c](https://github.com/rh-hideout/pokeemerald-expansion/blob/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c/src/party_menu.c):
  `ItemUseCB_AbilityPatch`, líneas 5116–5128, confirma destino 0 desde oculta
  (índice 2 de esa implementación); el modelo local lo traduce a slot 1.
  El mismo archivo contiene el cambio normal 0/1 y el consumo tras confirmación.

Son referencias comunitarias primarias, no código fuente oficial de Nintendo.
La segunda se consultó como un archivo fijado y no se ejecutó. URL/hash y copia
de consulta en `.godot/opencode_items_o001/references/`; hashes usados se incluyen
en el informe V10. No se descarga ni instala un juego/motor/dependencia.

## Verificación

Matriz del catálogo permitido: 1.076 especies/formas, 2.546 configuraciones de
habilidad actual, dos objetos, 5.092 casos. Se prueban cambios, falta de efecto y
destinos vetados. Fixtures aislados cubren metadatos ausentes, duplicados y
ambiguos; no se modifican los catálogos compartidos para crear esos escenarios.
Las dos rutas hacia Modo Daruma se cuentan como dependencia, no como aplicadas.

Se compara el estado completo, incluyendo equipo/PC, PP aumentados/gastados,
PS dañados, amistad, Campana Alivio, estado sueño, shiny y relojes. Casos negativos
de KO, transformación, guard cerrado, entrada inválida/null, inventario corrupto,
habilidad ajena y destinatario no poseído. Vista obsoleta y binding con relojes
sustituidos por otro diccionario de igual contenido se rechazan sin consumo.

Tres escenarios nativos: Intimidación de control recibe 11 PS de Ascuas;
Absorbe Fuego obtenido por Cápsula recibe 0; Justiciero obtenido por Parche recibe
11. Se comprueba habilidad enviada/reflejada y el contraste funcional, sin
implementar inmunidad en código local del objeto ni fijar el daño en producción.

La mochila real aplica Cápsula y Parche en ambos sentidos, guarda/carga, invalida
el servicio anterior y entra al combate nativo. También guarda/restaura el
checkpoint y termina capturando, conservando la habilidad. La variante GPU
captura la previsualización y verifica que el panel cabe en pantalla.

```text
python tools/verification/run_field_ability_v10.py
```

Preparación ya hecha: no repetir `--prepare`, borrar manifiestos ni resellar
otros guards. El runner incluye regresiones de caramelos, PP, vitaminas/plumas,
núcleo, campo nativo y restauración. Las evidencias reales, recuentos e integridad:
[ITEM_FIELD_V10.json](ITEM_FIELD_V10.json).

## Límites

Herencia de slots al evolucionar entre especies con nombres de habilidad distintos
sigue fuera de este bloque. El modelo conserva solo el ID, no un índice genético;
no se afirma que se haya resuelto crianza o herencia al implementar estos objetos.
También siguen pendientes mentas/IV, objetos de formas, mundo y captura especial.
No se modifica esquema, evolución, backend, políticas, datos ni imágenes.

La matriz completa V8 es histórica: los overrides de V9/V10 en el estado actual
describen los ocho cambios posteriores, sin duplicar 2.222 fichas por entrega.
Cierre: nueve grupos PASS; 15.376 checks headless y 15.378 GPU del nuevo bloque.
Quedan 69 efectos de campo conectados (41 recuperación y 28 entrenamiento,
incluidos dos de habilidades), con las dependencias anteriores explícitas.
