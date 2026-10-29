# Objetos de campo V9 — caramelos y decisiones de progresión

Base: `ce0dc71e`. Continúa los objetos después de cerrar la revisión de datos.
Se reutilizan ProgressionRuleset, ProgressionSystem, LearnsetSystem y
EvolutionSystem; no se construye otro motor de experiencia/evolución.

## Perfil conectado

| Objeto | Efecto de una unidad |
| --- | --- |
| Caramelo Raro | Alcanza el umbral del siguiente nivel. |
| Caramelo Exp. XS | 100 EXP |
| Caramelo Exp. S | 800 EXP |
| Caramelo Exp. M | 3.000 EXP |
| Caramelo Exp. L | 10.000 EXP |
| Caramelo Exp. XL | 30.000 EXP |

La experiencia queda limitada al máximo de su curva y el nivel a 100. Antes de
usar se comprueba coherencia entre nivel, experiencia, estadísticas, IV/EV y PP:
un estado inconsistente se rechaza sin repararlo silenciosamente. Se conservan
los PS perdidos cuando crece el máximo, la identidad, shiny, IV/EV, naturaleza,
objetos equipados, PP de movimientos conservados, estados y relojes de sueño.

El incremento base de amistad es el de vitamina, una vez por objeto, con Campana
Alivio activa y topes. No se inventan bonificaciones por lugar/bola de captura:
sus metadatos siguen pendientes, igual que en los objetos V7/V8.

Caramelo Raro puede iniciar una evolución por nivel a nivel 100 si su ruta está
implementada y permitida. Si se declina y no hay otro efecto, no se consume ni
concede amistad. Los caramelos EXP no hacen nada a nivel 100. Piedra Eterna activa
bloquea la evolución; por debajo del tope no impide ganar nivel. Evoluciones que
necesitan otros sistemas no se simplifican: se señalan como pendientes.

Se conserva la frontera existente de este proyecto: un Pokémon debilitado no
puede usar estos objetos para revivir. Es una restricción del perfil actual,
no una afirmación de que Caramelo Raro carezca de usos de reanimación en los
juegos oficiales.

## Decisiones y arquitectura

- `field_growth_effects.gd`: construye una candidata separada, sin IO, inventario,
  UI ni RNG. Aplica la progresión por niveles para resolver el aprendizaje en
  orden. Comprueba la evolución una vez al nivel final, como la referencia de
  objetos; tras evolucionar consulta movimientos de nivel cero/actual.
- Se respetan las opciones de la política vigente. Los movimientos nuevos con
  hueco libre se aprenden como en la progresión existente y se anuncian en el
  resultado; con cuatro movimientos se pide reemplazar uno o no aprender.
  Evolucionar o rechazar la evolución siempre requiere una elección explícita.
- `field_item_service.gd`: valida propiedad/actividad y prepara el inventario.
  Solo publica la candidata y consume una unidad al terminar todos los pasos.
- `field_growth_transaction.gd`: conserva intenciones primitivas y un token de
  estado, reproduciendo el plan desde el original. Rechaza cambios de referencia,
  inventario, ubicación, Pokémon, binding o relojes mientras una elección espera.
- `field_growth_choices.gd`: vista de opciones. La mochila muestra el resultado;
  no calcula reglas ni almacena un Pokémon parcialmente modificado.

Cancelar el uso, cerrar la mochila, cambiar objeto/destinatario o refrescarla
descarta las decisiones pendientes. Rechazar aprender/evolucionar y completar un
uso que sí aporta EXP permite ese efecto y consume una unidad. No se añaden
decisiones pendientes al formato de guardado, ni se consumen objetos por adelantado.

## Referencias y comprobación

Fuente ya descargada: Pokémon Essentials, Maruno17 y colaboradores, commit
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`:

- `Data/Scripts/013_Items/002_Item_Effects.rb`: los seis handlers de caramelos.
- `Data/Scripts/013_Items/001_Item_Utilities.rb`: pbChangeLevel, pbChangeExp y
  pbGainExpFromExpCandy; orden de aprendizaje/evolución y amistad.
- `Data/Scripts/016_UI/001_Non-interactive UI/004_UI_Evolution.rb`: aprendizaje
  de la especie evolucionada en nivel cero/actual.

Las tablas independientes ya contrastadas de seis curvas, niveles 1–100, están
en `tests/fixtures/progression_growth_curves/reference_contract.json`. Las
pruebas de caramelos comparan EXP/nivel con esos valores, no con otra copia de
las fórmulas del módulo bajo prueba. No se ejecuta Ruby ni un generador de datos.

La matriz contiene 6.456 combinaciones: las 1.076 especies/formas elegibles del
perfil actual por seis objetos. Se añaden topes para cada curva, decisiones
multinivel, movimientos tras evolucionar, cancelación, protección de intención
obsoleta, no reanimación y 252 contextos de propiedad/amistad/Campana Alivio.
No certifica todas las combinaciones de mecánicas de Pokémon.

La prueba real abre la mochila, cambia un movimiento con una elección, guarda y
carga el campo, usa un caramelo EXP y lleva el estado al worker nativo. También
comprueba guardado/restauración de combate y captura. La variante GPU incluye
una captura del panel de elección y comprueba que cabe en la pantalla.

```text
python tools/verification/run_field_growth_v9.py
```

La preparación de integridad ya se realizó una sola vez; no repetir `--prepare`
ni resellar manifiestos históricos. Cada ejecución conserva sus logs. Una prueba
de importación sin asserts no sustituye a las baterías de comportamiento.

Informe definitivo y hashes: [ITEM_FIELD_V9.json](ITEM_FIELD_V9.json).
El CSV de V8 conserva la matriz base de 2.222 fichas; el informe V9 y el estado
actual aportan exclusivamente los seis estados de uso actualizados, sin copiar
otra matriz completa ni presentar datos históricos como un barrido nuevo.

## Alcance restante

Los efectos conectados de campo pasan de 61 a 67; no significa que todos los
objetos estén terminados. Siguen pendientes IV, mentas/naturalezas, habilidades,
formas/evoluciones condicionadas no implementadas, metadatos de captura/amistad,
objetos de mundo y otros contextos ya inventariados. Se mantienen el catálogo,
las políticas, imágenes, backend nativo, RNG y esquema de guardado. No se ha
implementado el randomizador de movimientos, una UI de PC para estos usos ni
una campaña completa mediante esta fase.
