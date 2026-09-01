# Battle ruleset `calvo_v1`

Ruleset inicial coherente, inspirado en reglas modernas pero no ligado a una
generación concreta.

## Ordering and stages

- Switch priority: +6.
- Move priority: `MoveDefinition.priority`.
- Después: Speed efectiva; empate mediante RNG.
- Attack, Defense, Special Attack, Special Defense y Speed: multiplicador
  `(2+n)/2` para stages positivos y `2/(2-n)` para negativos.
- Accuracy/Evasion: `(3+n)/3` y `3/(3-n)`. Rango siempre -6..+6.

## Accuracy and critical

- Accuracy negativa significa “sin chequeo”; no es una decisión de UI.
- Accuracy restante se combina con accuracy-evasion stage y un roll 0..9999.
- Critical base: 1/24; multiplicador 1.5x.
- Crítico V2 no ignora stages. Una variante futura puede cambiarlo en otro ruleset.
- Damage roll: 85.00%..100.00%, RNG `lcg32_v1`.

## Damage and types

- Physical usa Attack/Defense; special usa Special Attack/Special Defense.
- STAB 1.5x.
- Efectividad multiplica los 1-2 tipos defensores desde `TypeDefinition`.
- Burn reduce daño physical a 50%.
- Abilities pinch (`blaze`, `torrent`, `overgrow`) multiplican 1.5x por debajo o
  igual a un tercio de HP. Levitate anula Ground.

## Persistent status

Solo puede existir uno: burn, poison, badly_poisoned, paralysis, sleep o freeze.

- Poison: 1/8 max HP al final del turno.
- Badly poisoned: `counter/16` max HP; contador empieza en 1 y crece cada tick.
- Burn: 1/16 max HP y penalización physical.
- Paralysis: 50% Speed y 25% de impedir acción.
- Sleep: duración aleatoria 1..3 acciones impedidas.
- Freeze: 20% de thaw antes de actuar; modelo soportado parcialmente, sin move V2.
- Fire es inmune a burn; Poison/Steel a poison/toxic; Electric a paralysis.

Volátiles separados: `flinch`, `confusion`. Flinch se consume al impedir la acción.
Confusion está modelado como slot volátil, pero su auto-daño aún no está soportado.

## Switching and faint

Switch voluntario está validado por ownership, bench, HP y active actual. Limpia
stages y volátiles del saliente. Status/PP persisten. Ante KO, `calvo_v1` promueve
el primer bench vivo; una fase de protocolo podrá sustituirlo por elección del
jugador sin cambiar el snapshot.

## Held items

- Leftovers: cura 1/16 max HP al final de turno si falta HP.
- Sitrus Berry: al quedar en 1/2 HP o menos tras daño, cura 1/4 y se consume.

## Known deliberate gaps

No hay doubles, clima, terrenos, hazards, Protect, multi-hit, confusion completa,
contact metadata exacta, struggle por PP agotado ni selección interactiva tras KO.
