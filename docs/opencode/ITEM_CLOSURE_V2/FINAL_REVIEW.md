# Revisión final conjunta — ITEM_CLOSURE_V2

**Estado: `PARTIAL_READY_FOR_REVIEW`. Aceptación: `NOT_ACCEPTED` (pendiente de
revisión independiente).** No se declara `COMPLETE` ni `ACCEPTED_BY_CODEX`.

Base de misión y `FAMILY_BASE`: `78c3b0f7d6ccfbe8f26f75070d9737ccdaa90035`.
HEAD sigue siendo el mismo; los cambios están en el árbol de trabajo, sin commit.
La primera entrega fue rechazada por R1–R7; este informe documenta la corrección
real, no una aceptación. El informe original de Codex se conserva intacto en
`evidence/O190/REVIEW.md` (SHA-256 `b208aa37...4fbf`).

Informe serializado: `FINAL_RESULTS.json`
(SHA-256 `de3ba4e891167a5b59b9c0b8f09b9d116ef7869941c8e88ee761903f2477409f`,
42.981 bytes).

## R1–R7

| ID | Hallazgo | Corrección | Verificación real |
|---|---|---|---|
| R1 | El mapa no cargaba por una API inexistente y la colección equivocada | `field_demo.gd` usa `_session.player.party` y el tipo real del líder | El mapa se instancia, abre la mochila, equipa Bola de Humo y se captura en GPU |
| R2 | O110 no aplicaba efectos nativos | `native_bag_effects.cjs` usa boost, Focus Energy, Mist y curaciones nativas; `applyMedicine` enruta 11 IDs | Node nativo + Godot + GPU; 13.274 checks de familia |
| R3 | Consumo/rechazo no verificados | Una unidad solo al aplicarse; rechazo sin RNG, sin mutación y sin gasto; flautas reutilizables | Aceptado/rechazado, topes, reutilización, enemigo/residual/KO, preparar/abortar/commit, guardar/cargar |
| R4 | O120 no estaba conectado | `held_escape_items.gd` se llama desde `flee()` con `held_item_active`; el helper de encuentro se llama desde el dueño del mapa | Bola de Humo lento/rápido/atrapado/suprimido; tasa validada; dos capturas |
| R5 | Verificadores constantes | Se sustituyeron por pruebas que llaman al código real y afirman efectos concretos | 14.880 checks de familia y 1.285 de cierre, todos > 0 |
| R6 | Auditoría incompleta / UNKNOWN | Auditor v2 por ID y contexto, con dependencia explicada | 2.222 filas, UNKNOWN=0, 10 pruebas y `--check` byte a byte |
| R7 | Evidencia final inválida | JSON serializado desde informes y logs reales; SHA-256 sobre archivos reales | Este informe, `evidence/` y la puerta final |

## Comandos y resultados reales

| Comando | Resultado | Conteo | Duración |
|---|---|---|---|
| `python tools/verification/run_opencode_closure_v2.py` | PASS | 6/6 grupos | 13 min 52 s |
| — auditoría: prueba + `--check` | PASS | 10 + 1 | 2.53 s + 0.44 s |
| — encuentro salvaje | PASS | 54 | 1.38 s |
| — guardado v2 | PASS | 40 | 0.66 s |
| — guardado adversarial | PASS | 8 | 0.47 s |
| — contrato de restauración | PASS | 1.172 | 5.36 s |
| `python tools/verification/run_opencode_support_v2.py` (O110) | PASS | 13.274 en 14 grupos | 379.09 s |
| `python tools/verification/run_opencode_world_held_v2.py` (O120) | PASS | 1.606 en 9 grupos | 288.45 s |
| `python tools/verification/opencode_items_v2_guard.py --full` | PASS (4 ejecuciones) | 23.079 protegidos, 15.647 ausentes | antes/después del cierre y antes/después de los informes finales |

La puerta de cierre ejecutó también dos guardas `--full` (antes y después) y una
tercera guarda independiente al final, todas PASS. La guarda es de alcance y
contenido protegido: no certifica mecánicas ni sustituye la revisión de Codex.

## Cobertura O100

- 2.222 filas canónicas, 0 UNKNOWN.
- Permiso: 625 permitidos / 43 excluidos / 1.554 no aplicables.
- Nativos: 619 con definición / 6 ausentes (`amulet_coin`, `cleanse_tag`,
  `exp_share`, `linking_cord`, `luck_incense`, `pure_incense`).
- Arte: 1.011 con arte / 1.055 sin preparar / 156 fuera del plan.
- Máquinas: 338 mapeadas / 229 verificadas / 109 pendientes.
- Evolución: 57 rutas soportadas + 15 de otro tipo; 26 IDs.
- Estados: 291 verificados / 250 parciales / 1.604 con dependencia / 34 no
  aplicables / 43 excluidos.

## O110 y O120

- O110: seis X (+2 etapas, tope +6, rechazo sin gasto), Dire Hit (Focus Energy),
  Guard Spec (Mist), flautas azul/amarilla/roja reutilizables. Ocho potenciadores
  consumen una unidad solo al aplicarse. Amistad base verificada; origen/Luxury
  pendientes.
- O120: Bola de Humo verificada en el límite de Run, sin RNG de escape y sin
  consumo. Cleanse Tag/Pure Incense: `PARTIAL_VERIFIED_RATE_ONLY` (copia validada
  de la tabla; semántica por pasos pendiente). Amulet Coin, Exp. Share, Linking
  Cord y Luck Incense: `DEPENDENCY_MISSING` con motivo concreto.

## Capturas revisadas

1. `battle_support_bag.png` (1280×720, SHA-256 `ad5c7d60...4bf2`): «Ataque X · 3»,
   aviso de consumo y objetivo Bulbasaur.
2. `smoke_ball_bag.png` (1280×720, SHA-256 `bb097832...2ad4`): «Bola de Humo · 1»,
   Bulbasaur «sin objeto» y botón Equipar; la captura es previa al equipamiento.
3. `smoke_ball_equipped.png` (1280×720, SHA-256 `1ec43d8c...06d3`): mapa tras
   equipar. El estado equipado lo afirma el check real; el HUD no imprime una
   etiqueta de objeto equipado.

## Límites que impiden declarar COMPLETE

- Los guardas por familia no pudieron aislarse: los cambios O100/O110/O120
  comparten archivos autorizados y siguen sin commit. No se inventaron
  checkpoints ni bases familiares posteriores; solo se ejecutó el guard global.
- Quedan dependencias concretas: Amulet Coin, Exp. Share, Linking Cord, Luck
  Incense; semántica por pasos de Cleanse Tag/Pure Incense; multiplicadores EV de
  Macho Brace y los seis Power items; Max Mushrooms/Dynamax.
- Fidelidad de captura/XP, IV, naturalezas y rutas de formas/evolución siguen
  fuera de este cierre.
- La auditoría separa presencia de efecto, pero no certifica todas las
  combinaciones jugables.

## Reproducción

```
python tools/verification/run_opencode_closure_v2.py
python tools/verification/opencode_items_v2_guard.py --full
```

Evidencia de la última ejecución:
`.godot/opencode_items_v2/closure/runs/1793413901862561200/results.json`
(SHA-256 `708aa77b96af5ed39bc8148ab3330d866e9fd3a2610b120cc629c3771ddeec2f`).
Log de la guarda final previa a los informes:
`.godot/opencode_items_v2/final_guard/final_guard.log`
(SHA-256 `c42c1c771b86bbf2550d0a6983b71d0602c6a5e752eb91816f7087ca807c28fc`).
Log de la guarda posterior a los informes:
`.godot/opencode_items_v2/final_guard/final_guard_after_reports.log`
(SHA-256 `ab6e77695794184c58c8112a6cdbdba98044c655730eaedbc8922fbe70005504`).

**Estado final: `PARTIAL_READY_FOR_REVIEW`, `writer_active=false`.**
