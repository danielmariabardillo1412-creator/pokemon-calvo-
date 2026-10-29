# Correcciones tras la auditoría PokéAPI — 2026-10-29

El usuario autoriza corregir errores confirmados y conservar las diferencias que
sean reglas válidas de Pokémon. Esto autoriza las correcciones mínimas de datos
descritas aquí; no una regeneración o sustitución general del catálogo.
Base: `680b655`, posterior al cierre de la corrección XP ya probada.

## Cambios

- El adaptador V3 distingue valores numéricos cero de booleanos falsos. La
  conversión de evoluciones ya no elimina `relative_physical_stats: 0`.
- Se restaura exclusivamente esa condición en Tyrogue → Hitmontop en raw y
  normalized. Las otras 1.024 especies, los movimientos, textos, objetos,
  habilidades y condiciones permanecen iguales. No se ejecuta un regenerador.
- El módulo de evoluciones interpreta las relaciones -1/0/1 con el Ataque y la
  Defensa persistentes tras subir de nivel: Hitmonchan/Hitmontop/Hitmonlee,
  respectivamente, desde nivel 20. Sin estadísticas válidas no ofrece una ruta.
  Otras condiciones no implementadas siguen bloqueadas; no se ignoran.
- Progresión y la validación de evolución del dueño comparten ese contexto. No
  se usan las modificaciones temporales del combate ni se publica una evolución
  por confiar únicamente en el evento. No se añade UI ni se conecta aquí un
  sistema completo de caramelos.
- Se vincula de nuevo la procedencia de Lilligant de Hisui al registro 10237 del
  snapshot comprobado. Sus estadísticas, aprendizaje y rutas ya coincidían con
  él: no se cambian. El hash antiguo no pudo justificarse con las copias locales
  consultadas; permanece en Git y en el informe anterior, sin atribuirle una
  procedencia inventada. Se corrige la referencia a la fuente ahora verificada.
- Se actualiza el binding de la capa regional al nuevo hash del catálogo
  corregido. No se desactiva el guard de integridad ni se regeneran imágenes.

El verificador compara los JSON completos con la base: solo admite la condición
indicada en cada catálogo y los dos hashes de configuración. Los manifiestos de
verificación históricos no se resellan ni se cambian para certificar esta fase.

## Reglas contrastadas y diferencias conservadas

La evolución de Tyrogue se contrastó con Pokémon Essentials, commit
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`, `007_Evolution.rb` (AttackGreater,
AtkDefEqual y DefenseGreater), y la comparación de estadísticas en
`pret/pokeemerald` `731ad5bfd6e6f265508d0efcca0ba42f9dcf5881`, `src/pokemon.c`.
También se consultó su [tabla de evoluciones](https://github.com/pret/pokeemerald/blob/master/src/data/pokemon/evolution.h).
Créditos: Maruno17 y colaboradores; comunidad pret.

Los otros textos se contrastaron con las reglas y descripciones del paquete ya
instalado `@pkmn/sim@0.10.11`, archivos `data/moves`, `data/abilities` y `data/text`.
Referencia comunitaria: [Pokémon Showdown](https://github.com/smogon/pokemon-showdown/tree/master/data).
Se conservan los hashes de las fuentes y una extracción de consulta en la
evidencia de esta fase. No se instala ni cambia el motor.

| Ficha | Motivo para conservar el texto del proyecto |
| --- | --- |
| Reducción | Además de evasión existe el estado Minimized, con interacciones propias. |
| Dulce Aroma | En las generaciones modernas baja dos niveles de evasión; uno es la regla antigua. |
| Paliza | Participan miembros no debilitados y sin estado persistente; la API resumía solo parte del requisito. |
| Reserva | La regla moderna también modifica Defensa/Defensa Especial y registra sus cambios. |
| Tragar | Requiere Reserva; sus niveles determinan la curación y se consumen. |
| Aligerar | Reduce 100 kg; la descripción de la API que dice mitad del peso no corresponde a esta regla. |
| Fertilizante | La condición de estar en el suelo importa; se conserva la nota de disponibilidad histórica. |
| Defensa Floral | Afecta a los Pokémon de tipo Planta activos; se conserva la nota de generación. |
| Purificación | La curación del usuario depende de curar el estado del objetivo. |
| Novena Potencia | Aumenta cinco estadísticas, sin incluir precisión/evasión; disponibilidad y veto Z de estado son asuntos separados. |
| Limpieza General | Aumenta Ataque/Velocidad y elimina obstáculos/Sustitutos de ambos lados. |
| Garra Dura | La regla usa aproximadamente 1,3 (30 %), no 1,33; el motor aplica su multiplicador fijo. |

Son 13 campos de texto en 12 fichas. No se revierte ninguno ni se cambia el
perfil de disponibilidad para coincidir artificialmente con la API.

Baya Hibis se conserva como un objeto canónico. La fuente trae dos IDs con el
mismo identificador; el retenido, 723, incluye nombre español y descripción,
mientras que 2279 carece de ambos. No se crea un duplicado en el inventario.

## Verificación y límites

```text
python tools/verification/run_pokeapi_repairs.py
python tools/verification/audit_pokeapi_data.py
```

El manifiesto inicial de esta fase ya existe. `--prepare` fue una operación
única y rechaza sobrescribirlo. Logs de intentos anteriores se conservan.
La batería de regionales usa `--legacy-field` porque sus interacciones están
escritas contra esa presentación; el combate, guardado/restauración y objetos
nativos se comprueban con sus propias baterías. Se crea la carpeta de salida de
esa prueba antes de intentar guardar, sin tocar el serializador del juego.

Resultado definitivo, recuentos, comandos, hashes y revisión de cada diferencia:
[POKEAPI_DATA_REPAIRS_V1.json](POKEAPI_DATA_REPAIRS_V1.json).
La auditoría V1 original sigue siendo un informe histórico, sin reescribirlo.
El nuevo comparador sigue mostrando las 14 diferencias de texto/duplicado
aceptadas: no se ocultan ni se presentan como igualdad literal con la API.

El guardado nativo incluye el hash del catálogo y rechaza partidas de una versión
de contenido distinta. No se modifica ese control ni se migran partidas en esta
fase. No existe el guardado de campaña por defecto en la copia activa al hacer
la comprobación; las pruebas usan archivos propios. Importar una campaña antigua
requiere un tratamiento explícito, no cambiar su checksum silenciosamente.

Este trabajo cierra los hallazgos de esta auditoría concreta; no certifica todas
las mecánicas pendientes de objetos, evoluciones condicionadas, multijugador o
combinaciones posibles de combate. El original, la fuente API de F:, arte,
políticas, formato de guardado y código del motor nativo permanecen intactos.
