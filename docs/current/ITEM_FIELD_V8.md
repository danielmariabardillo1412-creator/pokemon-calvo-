# Más PP / PP Máximos V8 — verificado

Base: 941dd297 (limpieza cerrada). Alcance autorizado: conectar pp_up y pp_max
desde la mochila existente, manteniendo el servicio como única autoridad del
inventario y de la publicación. No es un motor nuevo ni cambia el guardado.

## Contrato

- Elegir un movimiento aprendido permitido por la política existente.
- Máximo base + floor(base × mejoras / 5), con 0–3 mejoras. Más PP añade una;
  PP Máximos lleva a tres. Movimientos con menos de 5 PP base no admiten mejora.
- Los PP actuales crecen lo mismo que el máximo, conservando los gastados.
  Al límite no se consume el objeto ni se gana amistad.
- Amistad base 5/3/2 con franjas 100/200 y Campana Alivio activa ×1,5 truncada,
  como el perfil ya usado. Origen de captura/mapa sigue pendiente: no se inventa.
- Se infiere el número de mejoras de max_pp; no se añade otro contador o campo
  de guardado. Rechazar datos inconsistentes sin corregirlos silenciosamente.
- Mantener el objetivo vivo, propiedad equipo/PC, bloqueo durante combate y
  guards de identidad de la arquitectura aceptada. Sin revivir, nuevos vetos,
  datos, imágenes, cambios de Node/Showdown ni funciones del dueño/puente.

Módulos: field_pp_boost_effects aplica solo a una criatura preparada;
field_friendship_effects comparte las ganancias positivas de bayas/vitaminas/PP;
FieldItemEffects despacha; FieldItemService valida política/propiedad, prepara,
publica y consume una unidad. La mochila solo selecciona y presenta el resultado.

## Fuentes fijadas

pret/pokeemerald, commit 731ad5bfd6e6f265508d0efcca0ba42f9dcf5881:
[PP y amistad](https://github.com/pret/pokeemerald/blob/731ad5bfd6e6f265508d0efcca0ba42f9dcf5881/src/pokemon.c),
[efectos de los objetos](https://github.com/pret/pokeemerald/blob/731ad5bfd6e6f265508d0efcca0ba42f9dcf5881/src/data/pokemon/item_effects.h).
Se usa como referencia del comportamiento de PP, no para importar sus límites
antiguos de EV u otras reglas generacionales. Créditos: equipo pret y colaboradores.

Essentials 8c5911e conserva la misma fórmula/límite de mejoras, pero su setter
solo limita PP y sus handlers no aplican la amistad. No se copia esa diferencia:
se sigue el comportamiento de PP contrastado en la referencia principal y el
perfil de amistad ya conectado. No se ejecuta C/Ruby ni se incorpora otro motor.
Hashes, tabla independiente y límites: tests/fixtures/item_field_v8/reference_contract.json.

## Verificación ejecutada

Barrido del catálogo aprendible, estados 0–3, ambos objetos y PP vacío/parcial/lleno;
matriz de propiedad, selección, amistad y Campana Alivio; límites/corrupción/no-op;
mochila real, guardado/carga, consumo de PP en combate, checkpoint y retorno.
Regresiones de familias anteriores y API/guardado, con captura GPU.

El runner V8 usa un manifiesto nuevo contra 941dd297 y una allowlist explícita.
Conserva los archivos ausentes con skip-worktree y comprueba los presentes fuera
del alcance. No resella ni ejecuta el guard histórico de T006B como puerta actual.
Fase completa PASS: 43.588 comprobaciones headless y 43.590 con GPU;
19.872 casos de PP cubren los 828 movimientos aprendibles con PP base >=5,
con estados 0–3 y PP vacío/parcial/lleno. La matriz del servicio tiene 336
contextos positivos de ambos objetos, equipo/PC, cuatro slots, siete valores
de amistad y tres estados de Campana Alivio. Se comprueban no-op al límite,
datos/selecciones inválidos, objetivo ajeno, estado temporal, movimientos no
aprendibles, inventario corrupto y bloqueo durante el combate.

La mochila real verifica la elección del destino y el resultado, incluido el
rechazo sin consumo al límite. Persistencia real de 21/56 PP tras mejorar un
movimiento agotado; el combate gasta uno, guarda/carga su checkpoint y conserva
20/56 tras capturar y volver al mapa. Éter Máximo reconoce después el límite 56.
La captura GPU de la mochila se revisó visualmente y cabe en la ventana.

También pasan las regresiones V4/V5/V6/V7, conexiones de objetos, API real,
restauración, medicinas en combate y política: doce grupos incluida importación
y GPU. Hash completo PASS de 22.933 archivos presentes fuera de la allowlist
(3.696 versionados y 19.237 recursos locales), manteniendo ausentes los 15.647
archivos con skip-worktree. Se conservan intactos los manifiestos anteriores.
El primer piloto falló al inferir un tipo del runner (clocks); corregido y repetido,
con el fallo preservado en runs/, sin contarlo como PASS.

El total conectado de campo pasa de 59 a 61: 41 recuperación y 20 entrenamiento
(18 EV/amistad y 2 mejoras de PP). No certifica los 2.222 objetos. Origen de captura,
XP, IV, naturalezas, habilidades y dependencias de formas/mundo siguen separados.

## Reproducción y evidencia

En esta copia, conservando los manifiestos V8 ya preparados:

```text
python tools/item_audit/run_field_pp_v8.py
```

Un encargo nuevo prepara su propio alcance antes de editar. --prepare y
--prepare-local rechazan manifiestos existentes; no volver a sellarlos para
hacer pasar cambios posteriores. Los contratos T006B/V5–V7 siguen siendo históricos.

Informe: ITEM_FIELD_V8.json; matriz acumulada: ITEM_FIELD_V8.csv.txt;
pendientes: ITEM_PENDING_V8.json. Evidencia local: .godot/item_field_v8/results.json,
godot.json, gpu.json, pp_boost_bag.png y runs/ con comandos, logs y hashes.
