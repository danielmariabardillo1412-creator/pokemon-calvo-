# ADR-031 — Strategic Switching V2

## Estado

ACEPTADA / IMPLEMENTADA / VALIDADA.

## Contexto

FASE 30 convirtió ITEM en una acción autoritativa y finita. La siguiente carencia es que un entrenador humano competente no valora SWITCH como un simple coste fijo: cambia al encontrarse con una inmunidad o un counter claro, conserva piezas importantes para amenazas futuras, evita el ping-pong y puede aceptar que una pieza casi agotada caiga si cambiar inmediatamente regalaría daño sobre un counter crítico.

El evaluador táctico histórico ya comparaba presión ofensiva, seguridad y HP, pero no distinguía suficientemente esos patrones estratégicos.

## Decisión

FASE 31 añade una capa separada y explicable:

- `TrainerStrategicSwitchEvaluatorV2`;
- `TrainerStrategicSwitchTacticalEvaluator`;
- `StrategicSwitchingTrainerBrain`.

No se modifica el brain FASE 30 ni el search validado. El candidato nuevo conserva `TrainerItemAwareSearch` y añade estrategia de switching al score táctico de raíz.

### Daño esperado público

La urgencia defensiva no usa stats ocultos del rival. Se calcula con:

- especie y nivel públicos;
- movimientos revelados a confianza 10000 bp;
- hipótesis de movimiento de `TrainerBeliefState` ponderadas por su confianza;
- fallback de STAB público de especie a confianza reducida cuando no hay otra evidencia;
- stages/status públicamente observables;
- stats propios exactos, que son información legítima.

Una cobertura `machine/tutor/egg` de baja confianza puede contribuir al riesgo, pero no pesa igual que un movimiento revelado. Esto evita tanto la ceguera como el switch spam por coberturas raras.

### Patrones estratégicos

La capa V2 modela explícitamente:

- `escape_no_effective_route`: cambiar cuando el activo no dispone de daño efectivo ni utilidad estructurada y existe un counter;
- `clear_offensive_matchup_gain`: cambio por mejora ofensiva material;
- `escape_hard_counter`: escapar cuando la amenaza pública esperada cae de forma fuerte al cambiar;
- `avoid_switch_with_immediate_ko`: no regalar un KO inmediato por cambiar innecesariamente;
- `avoid_pointless_switch`: penalización cuando no mejora ni daño ni seguridad;
- `avoid_recent_switch_ping_pong`: penalización extra al regresar inmediatamente al Pokémon del que se acaba de salir sin mejora material;
- `preserve_key_bench_from_bad_entry`: no exponer una pieza futura valiosa a daño inmediato cuando el activo actual ya está casi agotado;
- `productive_sacrifice_window`: permitir quedarse con una pieza casi agotada cuando absorber su KO evita regalar daño de entrada sobre un counter futuro más valioso.

Los valores siguen siendo coeficientes heurísticos V1/V2 y quedan sujetos al laboratorio matemático posterior. Ninguna regla es una prohibición absoluta: se suma a búsqueda, táctica, equipo y perfil.

### Interacción con ITEM

Una curación del activo recibe presión negativa si el Pokémon no tiene ninguna ruta efectiva y existe un switch funcional. Curar un miembro de banca no se penaliza por esa regla.

El objetivo es evitar `heal spam` en matchups perdidos sin impedir usos estratégicos de objetos.

### Anti-cheat

La capa solo recibe `TrainerDecisionContext`:

- own party completa;
- observación rival sanitizada;
- creencias públicas/inferidas;
- memoria semántica sanitizada;
- acciones legales.

No recibe BattleState vivo, RNG rival, moveset oculto, naturaleza rival, IV/EV rivales, objeto no revelado ni banca no vista.

## Validación

Validación de código sobre `c7843f25e0c82a8f72d4fa1d35c5c643d22a1d68`:

- gate FASE 31: **169 PASS / 0 FAIL**;
- counter-switch ante inmunidad: PASS;
- reacción tras switch rival a counter: PASS;
- escape de amenaza revelada: PASS;
- permanencia con KO inmediato: PASS;
- utilidad estructurada evita falso `sin ruta`: PASS;
- anti-ping-pong por switch reciente: PASS;
- sacrificio productivo y preservación de banca clave: PASS;
- switch preferido frente a Hiperpoción en matchup bloqueado: PASS;
- corpus FASE 26 con candidato FASE 31: **36 PASS / 0 FAIL**;
- registro del candidato en corpus: **60 victorias / 0 derrotas**, sin regresiones emparejadas;
- FASE 30 y gates históricos: SUCCESS;
- regresión global Godot 4.7: SUCCESS;
- workflows del SHA de código: **14/14 SUCCESS**.

Antes del cierre de PR se requiere que este commit documental final vuelva a obtener los mismos 14 workflows en verde, para que el HEAD canónico de FASE 31 sea exactamente el SHA validado final.

## Fuera de alcance

FASE 31 no implementa todavía:

- hazards y coste de entrada completo;
- movimientos de pivot dedicados;
- Choice-lock completo;
- selección de held items;
- naturalezas/EV/IV de loadout;
- team building;
- expertise de Líder/Alto Mando/Campeón;
- calibración automática;
- MCTS.
