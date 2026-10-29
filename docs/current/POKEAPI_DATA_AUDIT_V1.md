# Auditoría de datos PokéAPI — 2026-10-29

Petición: localizar la descarga original y comparar los datos del juego con ella,
sin reescribirlos. Trabajo en la copia organizada; lectura de la fuente original
en F:. No se ejecuta ni modifica el juego original, ningún adaptador/importador,
las bibliotecas gráficas o los datasets.

## Resultado

**FINDINGS_REVIEW_REQUIRED**. El comparador terminó: 254.610 comprobaciones y
16 diferencias de campo/identidad que requieren distinguirse; no son 16 Pokémon
con valores incorrectos. Sus 11 pruebas de control positivo/negativo pasan.

| Grupo | Resultado |
| --- | --- |
| Fuente original | 8.874 archivos JSON de 10 endpoints cotejados con blobs Git; sin cambios de contenido |
| Especies base | 1.025; estadísticas, tipos, habilidades/slots, captura, curva XP y metadatos cotejados |
| Aprendizaje base | 61.102 entradas, conservando método, nivel, orden y una versión seleccionada por Pokémon |
| Evoluciones base | 554 rutas; una condición numérica perdida, detallada abajo |
| Regionales | 57; valores, 3.857 entradas de aprendizaje y rutas cotejados; una referencia hash inconsistente |
| Movimientos | 919; valores básicos, nombres y resúmenes cotejados |
| Habilidades / objetos | 373 / 2.222 fichas; valores representados por el esquema cotejados |
| Otros | 18 tablas de efectividad, 25 pares de naturaleza, 600 umbrales XP y 2.102 asociaciones máquina/versión cotejados |
| Importación interna | Sin diferencias de valores entre raw y normalized, teniendo en cuenta los defaults explícitos del serializador |
| Integridad | Fuentes y entradas del proyecto sin cambios durante el barrido |

No se detectaron diferencias en estadísticas base, tipos, habilidades asignadas,
tasas de captura o niveles de aprendizaje dentro de este alcance. No equivale a
certificar todas las mecánicas, todos los campos disponibles en PokéAPI ni todas
las combinaciones del motor de combate.

## Hallazgos y acciones separadas

1. **Pérdida de dato: Tyrogue → Hitmontop.** La fuente requiere nivel 20 y
   `relative_physical_stats: 0`: Ataque igual a Defensa. Raw y normalized han
   perdido esa condición. `evolution_record` del adaptador V3 descarta valores
   con `normalized in (None, "", False, 0, [], {})`; en Python el cero también
   compara igual a `False`. La corrección requiere una fase acotada, fixtures y
   comprobación de evolución. Esta auditoría no toca el adaptador ni los datos.
2. **Procedencia: Lilligant de Hisui.** `source_metadata.source_sha256` no
   coincide con el archivo original 10237, ni con sus variantes LF/CRLF. Sus
   estadísticas y aprendizaje sí coinciden. Investigar la procedencia antes de
   actualizar ese hash; no sustituir los valores del Pokémon.
3. **Textos: 13 campos en 12 fichas.** Once resúmenes de movimientos y dos campos
   de Garra Dura difieren de la API. Algunos amplían condiciones o describen
   reglas posteriores: no son automáticamente errores. La lista exacta con
   ambos textos está en el JSON. No revertirlos en bloque a descripciones
   históricas o incompletas del snapshot.
4. **Duplicado en la propia fuente: Baya Hibis.** Los IDs API 723 y 2279 tienen
   el mismo nombre `roseli-berry`. El catálogo conserva 723, que contiene nombre
   español y efecto; 2279 carece de ambos. El recuento 2.223 → 2.222 objetos
   procede de esta colisión. No demuestra que falte un objeto distinto.

Haunter conserva la evolución a Gengar por `trade`, sin nivel mínimo 10.
No se ha reproducido en esta versión el ejemplo histórico recordado por el usuario.

## Fuente y perfil

Fuente física encontrada:
`F:/pokemon roma el calvo/pokeapi-api-data/data/api/v2`.
También se localizaron copias en `datos pokemon/api/v2` y en el paquete de
imágenes; no se recorrieron bibliotecas gráficas ni los gigabytes ajenos a datos.

Árbol de referencia: `8349ea1ce75716897fe96e02a15950d19edba6c3`, idéntico en el
repositorio fuente encontrado y en el snapshot registrado por el proyecto.
Cada archivo de los endpoints auditados reproduce su blob Git tras convertir
exclusivamente CRLF a LF. Los bytes físicos se hashean de nuevo al finalizar:
no se normaliza ni escribe ninguno de esos archivos.

Perfil documentado: datos actuales del snapshot, un grupo convencional de
aprendizaje por Pokémon según la prioridad V3. No se mezclan generaciones ni se
etiquetan los fallbacks como actualización de contenido. Las exclusiones de
contenido del randomlocke no se aplican destruyendo registros del catálogo.
Se apartan los tipos no estándar y sus 18 movimientos, conservando su inventario.

PokéAPI es una fuente comunitaria. Coincidir con este snapshot demuestra fidelidad
al snapshot, no ausencia de errores en la fuente ni actualidad respecto de otra
versión del juego. Este barrido no descarga datos de la API viva.

## Idioma y mecánicas

Se verifica el nombre español cuando existe, con fallback es-419/en/identificador.
La fuente carece de español para 62 habilidades y 49 objetos; también faltan
muchas descripciones o solo existen en inglés. El informe las cuenta como deuda
de localización, sin atribuirlas a corrupción numérica. Las etiquetas regionales
son textos del proyecto, no traducciones API verificadas aquí.

Los efectos generados, clasificaciones, contacto y críticos se verifican por
preservación al importar, sin certificar su semántica contra PokéAPI. El motor
nativo Showdown tiene sus propias reglas y requiere sus pruebas de combate.
Los pares de naturaleza se leen como constantes inertes; las fórmulas XP no se
ejecutan en Python. Su ejecución tiene una prueba Godot separada ya registrada en
[PROGRESSION_GROWTH_CURVES_FIX.md](PROGRESSION_GROWTH_CURVES_FIX.md).

## Reproducción y evidencia

```text
python -m unittest discover -s tools/verification -p test_audit_pokeapi_data.py -v
python tools/verification/audit_pokeapi_data.py
```

Solo se escriben carpetas nuevas en `.godot/pokeapi_data_audit/`; nunca se
sobrescribe una ejecución. Código 0: comparación sin hallazgos, con límites;
1: diferencias a revisar; 2: problema de integridad de fuente/entradas.
Un resultado con diferencias no se presenta como PASS global.

Informe resumido persistente, diferencias completas y hashes:
[POKEAPI_DATA_AUDIT_V1.json](POKEAPI_DATA_AUDIT_V1.json).
Ejecución final: `.godot/pokeapi_data_audit/20261029T172253_137812Z/`.
Contiene `report.json`, `source_inventory.json`, `comparator_tests.json` y el log
real de las 11 pruebas. Los controles detectan cambios de estadísticas, nivel,
trigger, condición cero, faltas/duplicados, valores de efectos, idioma y archivos
API alterados/ausentes/no registrados. Solo se mutan fixtures temporales propios.

Los ensayos previos quedan en caché. El primer prototipo contó como diferencias
los CRLF del checkout y los defaults del serializador; se corrigió el comparador
y se repitió, sin tocar los datos para obtener un resultado mejor.

La corrección XP previa sigue siendo trabajo local anterior a esta auditoría.
Los hashes de entrada fijan los bytes realmente comparados, sin presentar HEAD
como si incluyera esa corrección pendiente de commit.
