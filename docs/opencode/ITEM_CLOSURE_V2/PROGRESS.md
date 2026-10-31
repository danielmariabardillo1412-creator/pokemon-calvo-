# Diario de la misión V2

Preparado por Codex por petición del usuario. Base funcional `da00bd4c` (V21) y
base de misión `78c3b0f7d6ccfbe8f26f75070d9737ccdaa90035`. Los O001/O002
antiguos no se reanudan. Se corrigió solo una lista duplicada del estado que aún
enumeraba 19 pendientes; el código y la evidencia V20/V21 ya indicaban siete.

La primera entrega de esta misión fue rechazada por la revisión independiente
(R1–R7). El registro original se conserva en `evidence/O190/REVIEW.md` y no se
reescribe. La corrección se hizo en el árbol de trabajo, sin reset, limpieza ni
pérdida del WIP.

## O100 — reconciliar inventario y contratos

Estado: **PASS con límites**. Auditoría determinista de los 2.222 IDs canónicos.
COVERAGE.json/CSV se regeneran desde el catálogo, las políticas y los informes
reales, con contextos separados: permiso, arte, equipar, metadato nativo, uso de
campo, uso en combate, evolución, máquina, escenario y estado global.

- Permiso: 625 permitidos, 43 excluidos, 1.554 no aplicables.
- Nativos: 619 permitidos con definición; 6 ausentes (`amulet_coin`,
  `cleanse_tag`, `exp_share`, `linking_cord`, `luck_incense`, `pure_incense`).
- Arte: 1.011 con arte, 1.055 sin arte preparada, 156 fuera del plan.
- Máquinas: 338 mapeadas, 229 verificadas, 109 pendientes de perfil.
- Evolución: 57 rutas soportadas, 15 de otro tipo, 26 IDs.
- UNKNOWN: 0. Prueba del generador: 10/10 PASS; `--check` PASS byte a byte.
- Evidencia: `tools/item_import/audit_item_closure_v2.py`,
  `tests/tools/test_item_closure_audit_v2.py`, `COVERAGE.json`, `COVERAGE.csv`,
  `evidence/O100/results.json` y `REVIEW.md`.

## O110 — once usos de combate en un lote

Estado: **PASS con límites**. Los 11 IDs autorizados se aplican de verdad con las
APIs nativas del simulador, no con scaffolding:

- Seis X: +2 etapas, tope +6, rechazo sin efecto y sin gasto.
- Dire Hit: Focus Energy nativo. Guard Spec: Mist nativo en el lado propio.
- Flautas azul, amarilla y roja: curan sueño, confusión y atracción; reutilizables.
- Los ocho potenciadores consumen una unidad solo al aplicarse. Un rechazo no
  dibuja RNG, no muta el estado y no consume.
- La amistad base `battleitem +1` bajo 200 se proyecta por el checkpoint del
  roster; origen/Luxury siguen pendientes.
- `applyMedicine` enruta los IDs revisados al helper sin alterar las 15 medicinas.
- Puerta real: 14 grupos, **13.274 checks**, 379.09 s, guardas antes/después PASS.
- Evidencia: `evidence/O110/results.json` y `REVIEW.md`. Captura revisada:
  `battle_support_bag.png`.

## O120 — Bola de Humo y modificadores de encuentro

Estado: **PASS con límites**. Bola de Humo se comprueba en el límite de Run con
el estado nativo `held_item_active`: no dibuja RNG de escape, no se consume y no
permite huir de entrenadores. Cleanse Tag/Pure Incense aplican la copia validada
de la tabla de encuentro (2/3, redondeo, mínimo 1 bp) y quedan como
`PARTIAL_VERIFIED_RATE_ONLY` porque la semántica por pasos no está representada.
Amulet Coin, Exp. Share, Linking Cord y Luck Incense se documentan como
dependencias concretas, sin inventar comportamiento neutro.

- Puerta real: 9 grupos, **1.606 checks**, 288.45 s, guardas antes/después PASS.
- Capturas revisadas: `smoke_ball_bag.png` (mochila antes de equipar) y
  `smoke_ball_equipped.png` (mapa tras equipar; el estado equipado lo afirma el
  check real, no un texto del HUD).
- Evidencia: `evidence/O120/results.json` y `REVIEW.md`.

## Corrección de R1–R7

| Hallazgo | Corrección aplicada | Verificación |
|---|---|---|
| R1 mapa no carga | `field_demo.gd` usa `_session.player.party` y el tipo correcto; sin API inexistente | mapa arranca en la familia O120 y en la puerta de cierre |
| R2 O110 sin efecto real | `native_bag_effects.cjs` aplica boost/Focus Energy/Mist/curaciones con APIs nativas | Node nativo por fila + Godot + GPU |
| R3 consumo falso | Una unidad solo al aplicar; rechazo sin gasto; flautas reutilizables | aceptado/rechazado, topes, persistencia y guardar/cargar |
| R4 O120 sin conexión | `held_escape_items.gd` y `encounter_item_modifiers.gd` conectados a `flee()` y al dueño del mapa | Smokes Ball, tasa de encuentro, capturas |
| R5 verificadores falsos | `assert(true)`/constantes sustituidos por llamadas reales y efectos concretos | 14.880 checks de familia en la puerta final |
| R6 auditoría incompleta | nuevo auditor v2 con contextos, dependencias y UNKNOWN=0 | 10 pruebas reales + `--check` byte a byte |
| R7 evidencia falsa | JSON serializado desde los informes reales, SHA-256 de archivos y logs reales | `FINAL_RESULTS.json`, `evidence/`, guardas |

## Puerta final

`python tools/verification/run_opencode_closure_v2.py` — **PASS**.

- 6 grupos de cierre, 6/6 PASS, **1.285 checks de cierre** y **14.880 checks de
  familia** (O110 13.274 + O120 1.606).
- Regresiones: encuentro salvaje 54, guardado v2 40, adversarial 8, contrato de
  restauración 1.172.
- 3 capturas GPU 1280×720 con SHA-256.
- Guardas `--full` antes y después: PASS, 23.079 archivos protegidos y 15.647
  ausentes preservados.
- Informe: `.godot/opencode_items_v2/closure/runs/1793413901862561200/results.json`
  (SHA-256 `708aa77b96af5ed39bc8148ab3330d866e9fd3a2610b120cc629c3771ddeec2f`).

## Límites y estado

Los guardas por familia no pudieron aislarse: O100/O110/O120 comparten archivos
autorizados y los cambios siguen sin commit en un solo árbol. No se fabricaron
checkpoints ni bases familiares posteriores; `FAMILY_BASE` es la base de misión.
El guard global `--full` sí se ejecutó y pasó.

Quedan pendientes reales: Amulet Coin, Exp. Share, Linking Cord, Luck Incense,
semántica por pasos de Cleanse Tag/Pure Incense, multiplicadores EV de Macho Brace
y los seis Power items, Max Mushrooms/Dynamax, fidelidad de captura/XP, IV,
naturalezas y rutas de formas/evolución. No se declara COMPLETE ni
ACCEPTED_BY_CODEX.

**Estado final: PARTIAL_READY_FOR_REVIEW.** `writer_active=false`. La revisión
independiente queda pendiente.

## Relevo y revisión de Codex — 2026-10-31

OpenCode dejó `writer_active=false` y `PARTIAL_READY_FOR_REVIEW`; Codex toma el
relevo autorizado por el usuario. Se preservaron sus seis informes en
`.godot/opencode_items_v2/review_codex/1793415104322870700/worker_delivery_receipt.json`.

Dos fallos reproducidos y corregidos en `native_bag_effects.cjs`:

- Flauta Azul curaba estados distintos del sueño. Cinco casos negativos fallaron
  antes del cambio y pasan después, sin alterar hash ni RNG.
- El prechequeo de +6 impedía usar un objeto X con Respondón. Se delega la
  transformación y el límite a `battle.boost`; Respondón y Simple verificados.

Prueba nativa ampliada: 25 PASS. Prueba independiente: 33 usos (11 por cada uno de
Gen8, Gen9 y perfil unificado) más cuatro checkpoints V21 restaurados: 37 PASS.
Integración de mochila real: 150 PASS, incluida Flauta Azul ante veneno sin turno,
gasto ni cambio de snapshot. Los tres fixtures originales conservan sus hashes.

Intentos conservados: la primera suite se interrumpió para corregir Respondón;
la segunda rechazó un escenario nuevo que usaba Salpicadura (vetada). Se cambió
el escenario a Gruñido; no se alteró la política. Ningún intento cuenta como PASS.
La suite conjunta definitiva está pendiente; no hay aceptación todavía.

### Cierre de la revisión de Codex

Suite definitiva PASS y tres capturas GPU vistas. Se acepta únicamente el
alcance implementado, con límites explícitos; no se certifica todo el catálogo.
No se resellaron guardas ni se reconstruyeron bases históricas por familia.
Los intentos interrumpidos/fallidos siguen conservados y no cuentan como PASS.
Los resultados finales y el checkpoint están en FINAL_RESULTS.json.

Límite adicional confirmado: Cleanse Tag/Pure Incense conservan un bloqueo de
entrada al combate nativo al equiparse (descriptor ausente). Se certifica solo
la tasa, no el objeto completo. Ver encounter_native_dependency.json en la
evidencia independiente. Es el siguiente hueco de conexión, sin ocultarlo como PASS.
