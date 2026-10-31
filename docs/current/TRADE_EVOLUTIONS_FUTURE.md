# Evoluciones por intercambio — trabajo aplazado

Regla aclarada por el usuario el 2026-10-31: **se elimina únicamente la necesidad
de intercambiar. Se conserva el objeto equipado cuando esa evolución lo exige.**
La adaptación a niveles se hará después de terminar objetos; ahora no se implementa.

## Requisito que deberá conservarse

- Intercambio con objeto: nivel que se defina + objeto correspondiente equipado,
  sin necesidad de intercambio. No basta con alcanzar un nivel sin ese objeto.
- Ejemplo: Onix deberá poder evolucionar a Steelix al cumplir el nivel establecido
  y llevar Revestimiento Metálico. Sin equipárselo, el jugador puede conservar Onix.
- También se conservan los demás requisitos de objeto: Electrizador, Magmatizador,
  Protector, Escama Dragón, etc. Su valor evolutivo es suficiente para mantenerlos,
  aunque no proporcionen una bonificación adicional durante el combate.
- Intercambio sin objeto: habrá que definir su adaptación por nivel sin inventarle
  un objeto nuevo. Cordón Unión permanece excluido; es un sustituto del intercambio,
  no uno de los objetos equipados originales que el usuario quiere conservar.
- Revisar destinos múltiples como Clamperl y Slowpoke manteniendo el control del
  jugador mediante sus objetos. Respetar variantes y las decisiones de evolución.

No se ha elegido un nivel común ni se adopta nivel 37. Se contrastarán otros
juegos/randomizadores y cualquier tabla del amigo cuando se retome esta fase.
Los niveles de etapas previas no equivalen a un mínimo oficial para el intercambio.

## Referencias para más adelante

[Universal Pokémon Randomizer ZX, Gen4RomHandler](https://github.com/Ajarmar/universal-pokemon-randomizer-zx/blob/master/src/com/dabomstew/pkrandom/romhandlers/Gen4RomHandler.java)
usa criterios distintos: nivel 37 para intercambios simples, objetos conservados
en otras rutas y una excepción de Slowpoke con piedra. Es una referencia para
comparar, no una norma adoptada. No copiar una excepción que quite el requisito
de objeto definido por el usuario sin revisar previamente el caso.

Habrá que resolver niveles, disparador de subida, ramas, formas y consumo del
objeto según la referencia adoptada. No se modifican ahora EvolutionSystem,
registros canónicos, guardados ni comportamiento de evolución.

## Corrección de la revisión anterior

Codex interpretó incorrectamente la regla y excluyó diez objetos en V26. La
restauración V27 revoca esa exclusión. Los resultados V26 solo prueban aquel
checkpoint histórico; no significan que esa decisión siga vigente.
Los diez están permitidos otra vez, junto con Revestimiento Metálico, Roca del
Rey, Diente Marino y Escama Marina. Los otros vetos previos siguen sin cambios.
