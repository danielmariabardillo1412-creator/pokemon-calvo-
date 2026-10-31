# Objetos V11 — cinco Poké Balls adicionales

Base: `ce5f9b89`. Se trabaja en la copia organizada, con un escritor y sin
OpenCode. No se altera el original, los datos, las políticas, el arte, el motor
de combate ni el esquema de guardado.

## Perfil y alcance

Se amplía **calvo_capture_v1**, el perfil de captura que ya utiliza el proyecto.
Su probabilidad es una aproximación propia; **no es la fórmula completa oficial
de novena generación**. Se conservan su fórmula, bonus de estado (sueño/hielo 2),
RNG y cuatro bolas anteriores. No se certifican capturas críticas, cuatro tiradas
de sacudidas, penalización de Ultraentes ni todas las interacciones oficiales.
La futura revisión de fidelidad del perfil permanece separada y explícita.

Reglas de objetos tomadas como referencia de Pokémon Essentials, commit
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`:

| Objeto | Regla añadida al perfil existente |
| --- | --- |
| Nido Ball (`nest_ball`) | Multiplicador máximo entre `(41 − nivel) / 10` y 1. Nivel 1: 4; nivel 30: 1,1; desde 31: 1. |
| Rapid Ball (`fast_ball`) | ×4 si velocidad **base de la especie original** ≥100; tasa modificada limitada a 255 antes del bonus de estado/PS. En otro caso ×1. No usa la estadística del individuo. |
| Ensueño Ball (`dream_ball`) | ×4 si el objetivo está dormido; Bostezo sin sueño no activa el bonus. |
| Sana Ball (`heal_ball`) | ×1; tras captura exitosa restaura PS, PP hasta sus máximos existentes y estado persistente del capturado. No cura al equipo. |
| Honor Ball (`premier_ball`) | ×1, sin bonus ni efecto posterior. |

Son cinco IDs nuevos de captura; no se suman a los 69 efectos de uso fuera del
combate. Las cuatro bolas previas y las cinco nuevas forman nueve IDs admitidos.
Rapid Ball y Veloz Ball (`quick_ball`) son objetos diferentes; Veloz sigue pendiente.
Las bolas dependientes de turno, historial, ambiente, género, pesca o cambios de
tipo no se habilitan con contexto inventado.

## Arquitectura y conexión

- `capture_ball_effects.gd`: multiplicadores, validación de estados nuevos y cura
  posterior; módulo puro, sin UI, IO, inventario ni fuente aleatoria propia.
- `CaptureRuleset`: catálogo/orden común de bolas; misma versión de esquema.
  `CaptureSystem` utiliza el módulo al calcular y tras el éxito. La frontera
  `CaptureInventoryService` existente conserva propiedad y consumo transaccional.
- `capture_ball_picker.gd`: vista del inventario de combate, nombres y unidades.
  El laboratorio y la demo principal lanzan el ID seleccionado; Master conserva
  su botón. Sin unidades, combate de entrenador o ejecución en curso no se ofrece
  un lanzamiento válido. La presentación técnica anterior comparte el catálogo.
- La Sana publica una criatura curada después del checkpoint nativo. Por eso
  `field_native_session.gd` conserva un reloj solo si la criatura final sigue
  dormida. No cambia la lógica de sueño del worker.

No se añaden campos a criaturas/partidas ni se recuerda la bola de origen. Por
eso siguen pendientes Lujo Ball y bonos de amistad según origen. Un intento
fallido gasta una bola y un turno en el inventario preparado del combate; rechazo
no gasta bola/RNG. La publicación de campaña sigue ocurriendo al terminar.

## Verificación

10.760 casos de catálogo: 1.076 especies/formas permitidas, cinco bolas y dos
estados de sueño. Tabla esperada independiente, probabilidad, resultado, una
tirada RNG, una unidad, identidad y comparación del estado completo. Se prueban
límites de nivel y velocidad base, PP aumentados/gastados, fallos sin cura,
captura destinada al PC y rechazo sin mutar ante contextos/objetivos inválidos.

En nativo se produce sueño con Espora, se guarda/restaura el checkpoint y se
captura con cada bola. La prueba comprueba curación exclusiva de Sana y relojes
finales. Nido y Sana cubren también fallo real, inventario preparado, una sola
reacción rival, RNG exacto, restauración y liquidación final con Master.

La escena real del mapa selecciona Sana, guarda/carga y lanza el ID elegido.
La ejecución GPU captura los controles y comprueba sus límites en pantalla.
Resultados reales y hashes: [ITEM_CAPTURE_V11.json](ITEM_CAPTURE_V11.json).

```text
python tools/verification/run_capture_v11.py
```

El runner incluye núcleo, habilidades V10, inventario/captura anteriores,
presentación técnica de captura, campo nativo y restauración. Un intento
interrumpido, con error o sin asserts no se cuenta como PASS.

## Integridad, intentos y fuentes

El manifiesto inicial `.godot/item_capture_v11/scope_base.json` se conserva sin
reescribir. Tras el primer pase completo de la pieza se detectó la necesidad
de dos conexiones adicionales: reloj posterior de la Sana y colocación del
selector en el campo. Antes de editarlas se contrastaron sus bytes con el
checkpoint y se preparó el manifiesto propio de `integration_scope/`, con
enmienda documentada, hash del manifiesto inicial e integridad anterior. El
verificador final usa ese alcance; no resella los guards de fases antiguas.

Dos primeros intentos fallaron al importar un objetivo dormido sin reloj nativo
observado: error de preparación de esta prueba, no PASS. Se conservan sus logs
en los dos primeros directorios `runs/` del alcance inicial. Se corrigió el
escenario provocando sueño dentro del motor, sin debilitar su contrato ni
fabricar un reloj. Los intentos posteriores conservan su propia evidencia.

Créditos: Maruno17 y colaboradores, Pokémon Essentials. Archivos de referencia
locales `Data/Scripts/011_Battle/007_Other battle code/010_Battle_PokeBallEffects.rb`
y `Data/Scripts/014_Pokemon/001_Pokemon.rb` (`heal`). Solo lectura; no se ejecuta
Ruby ni se importa su motor. Versiones, SHA-256 y resultados en el informe JSON.

Cierre: nueve grupos PASS, 32.405 comprobaciones headless y 32.407 GPU. Matriz
final: 4.536 capturas y 6.224 fallos deterministas, todos con estado/consumo/RNG
contrastados. Nueve bolas admitidas; los 69 efectos de campo permanecen iguales.
No se modifica la generación de botín ni se conceden bolas nuevas a partidas.
