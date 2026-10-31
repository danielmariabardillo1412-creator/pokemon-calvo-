# Alcance de objetos V25 — decisión del usuario

**Cordón Unión excluido. Evoluciones por nivel: aplazadas, sin implementar.**

Base de retirada: `4ac657f55fad2466a30ac25b631b55db01717126`. El código de Cordón
de V24 se retira del juego y sus herramientas específicas se retiran del árbol
activo; se conserva su historia y evidencia en Git. Se mantiene el aviso corregido
de los objetos pasivos. Los datos canónicos y el arte no se borran ni regeneran.

El objeto no puede generarse mediante la política, equiparse, usarse o provocar
evolución. La política conserva los inventarios antiguos, no los purga. Las
evoluciones normales por nivel y piedra siguen funcionando.

## Trabajo de evoluciones aplazado

Ver [TRADE_EVOLUTIONS_FUTURE.md](TRADE_EVOLUTIONS_FUTURE.md). Más adelante se
contrastarán otros juegos/randomizadores y la tabla que aporte el amigo. No se
ha fijado nivel 37, no se convierte ningún intercambio ni se cambia el dataset.

## Diez candidatos a revisar con esas reglas

No se excluyen ahora: podrían sobrar cuando dejen de ser requisitos evolutivos.
- Escama Dragón (`dragon_scale`): seadra → kingdra.
- Disco Extraño (`dubious_disc`): porygon2 → porygon_z.
- Electrizador (`electirizer`): electabuzz → electivire.
- Magmatizador (`magmarizer`): magmar → magmortar.
- Escama Bella (`prism_scale`): feebas → milotic.
- Protector (`protector`): rhydon → rhyperior.
- Tela Terrible (`reaper_cloth`): dusclops → dusknoir.
- Saquito Fragante (`sachet`): spritzee → aromatisse.
- Mejora (`up_grade`): porygon → porygon2.
- Dulce de Nata (`whipped_dream`): swirlix → slurpuff.

## Cuatro que no se descartan por su papel evolutivo

- Revestimiento Metálico: potencia los ataques de tipo Acero.
- Roca del Rey: añade probabilidad de retroceso a ataques compatibles.
- Diente Marino: mejora el Ataque Especial de Clamperl.
- Escama Marina: mejora la Defensa Especial de Clamperl.

Los cinco pañuelos de concurso quedan como otros candidatos de alcance; no se
añade una prohibición para ellos. Los objetos de economía o mecánicas aún no
implementadas se distinguen de objetos descartados. Poké Muñeco conserva su
función de huida y no se confunde con una decoración.

## Verificación

- 5 grupos PASS / 6.849 comprobaciones. incluidas regresiones.
- Retirada y política: uso/equipamiento/evolución bloqueados sin mutación;
  generación rechazada incluso si el llamador lo ofrece como utilizable.
- Se comprueba que Haunter no obtiene una evolución por nivel provisional y
  que siguen existiendo su registro canónico de intercambio, la evolución de
  Charmander y el uso ordinario de Piedra Fuego.
- Avisos de Amuleto/Incienso Puro conservados; adaptador y herramientas de
  Cordón sin consumidores de ejecución. Las pruebas de selección ahora esperan
  44 exclusiones, actualizadas por la nueva decisión humana, no para ocultar fallos.
- Guarda nueva completa PASS: 23.126 archivos protegidos, 15.647 ausentes
  preservados. No se resellan las fases anteriores.
- 621/624 equipables permitidos tienen descriptor nativo. El cambio de 625 a
  624 es la exclusión de Cordón, no un objeto adicional implementado. Quedan
  Amulet Coin, Exp. Share y Luck Incense como dependencias.

Informe de candidatos: [ITEM_SCOPE_V25.json](ITEM_SCOPE_V25.json). Resultados
de ejecución y hashes: `.godot/item_scope_v25/results.json`. Las cifras de
pruebas se solapan con regresiones y no representan objetos distintos.
