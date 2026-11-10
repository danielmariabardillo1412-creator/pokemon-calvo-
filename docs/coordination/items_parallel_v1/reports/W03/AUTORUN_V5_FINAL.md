# IA3/W03 — TANDA 05 FINALIZADA: Net Ball nativa L3, cuatro perfiles y regresión completa

Fecha: 2026-11-11 (cierre de la ejecución iniciada el 10 de noviembre, UTC). Rama exclusiva `codex/calvo-items-20261104-w03-camp006`.

## Contabilidad verificable

- **Hitos: 10/10 examinados y completados; 0 bloqueos pendientes de esta tanda.**
- **Objetos NUEVOS: 0.** Net Ball ya tenía reglas funcionales L2 en `modules/capture/capture_ball_effects.gd`, registradas en `capture_ruleset.gd` y cubiertas en `parallel_items_w03_net_campaign_001.gd`. No se reimplementó el multiplicador.
- **Un objeto preexistente revalidado en L3 nativo: `net_ball` (1).** Certificación mediante `WildEncounterSystem`/tabla real, `ShowdownAdventureSession.capture`, propietario de colección, inventario y SaveV2.
- **QA V5 nueva: 128 verificaciones PASS** repartidas en cuatro suites (79+19+15+15).
- **Integración en rama IA6: NO.** Ningún merge, cherry-pick ni cambio de main, V28, PR118 o ramas ajenas.
- **Código y workflow sometidos a CI:** `56155f824dd684989192407622c7c46d28836110`.
- **CI final:** [GitHub Actions #42922912695](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42922912695), `completed/success` para ese SHA exacto.

## Hitos de la cola maestra

| Hito | Resultado | Evidencia |
|---|---|---|
| 01. Preflight Net y tipos | **PASS, L2 previo identificado** | `capture_ball_effects.gd` aplica ×3,5 a Agua o Bicho, sin acumulación en doble tipo; ×1 a otros. Los tests históricos `net_campaign_001.gd` prueban lógica de dominio y SaveV2, sin certificar por sí mismos la integración nativa de mapa. |
| 02. Captura nativa Agua y Normal | **L3 PASS** | `parallel_items_w03_net_native_v5.gd`: tabla real de encuentros, Goldeen Agua ×3,5; Pidgey Normal ×1. Semillas reproducibles, probabilidad calculada desde catálogo y estado vivo; aceptación de éxito o fallo según RNG, sin forzarlo. |
| 03. Bicho y doble Agua/Bicho | **L3 PASS** | Caterpie Bicho ×3,5; Surskit doble Agua/Bicho ×3,5 **una sola vez**, no ×12,25. Especie y tipos originales del catálogo. |
| 04. Éxito, consumo y dueño | **L3 PASS** | Goldeen capturado mediante Net real, descuento de exactamente una unidad, colección propietaria y ledger canónico actualizados sólo después de confirmar el resultado. |
| 05. Fallo real por RNG | **L3 PASS** | `parallel_items_w03_net_native_v5_negatives.gd`: Squirtle Agua, semilla seleccionada sobre RNG clonada para que la tirada supere la probabilidad matemática. Resultado FAILED real, consume una Net en inventario staged y turno/RNG; antes de asentamiento no añade criatura/ledger ni altera colección persistente. Se guarda y restaura el checkpoint staged. |
| 06. Party completa y PC expandible | **L3 PASS** | Seis Pokémon en Party y 30 ocupando la primera caja del PC. La captura positiva crea automáticamente segunda caja y preserva identidad única; no se simula un «PC globalmente lleno» porque tal límite no existe. |
| 07. Cambio de miembro y Transformación | **L3 PASS** | `parallel_items_w03_net_native_v5_transform.gd`: cambio nativo al Mew de reserva, movimiento Transform ejecutado en Showdown y lanzamiento Net contra Goldeen Agua auténtico. El Mew original permanece Mew tras la captura y SaveV2. |
| 08. SaveV2 normal/corrupto | **L3 PASS** | Guardados reales con dueño, cajas, ledger y stock. Fixture con checksum válido pero historial duplicado rechazado antes de publicar; la colección viva conserva identidad/stock y el guardado anterior sigue cargando. |
| 09. Regresiones | **QA PASS** | `parallel_items_w03_net_v5_context_regression.gd`: 15 checks de Quick, Timer, Level, Repeat y Net; además CI conserva Repeat V2/V3/V4, repeles L3, Cuerda Huida CAMP006, CAMP005, SaveV2 normal/adversarial y `FIELD_NATIVE`. |
| 10. CI + informe | **PASS** | La ejecución #42922912695 aprobó todos los pasos; este informe, el CSV y la evidencia de SHA cierran la tanda. |

**Matiz de aceptación del hito 02:** el protocolo pedía una «prueba nativa roja». No se fabricó una prueba negativa para simular un fallo de integración: la ruta ya funcionaba. Se probaron los multiplicadores en la sesión real, con aserciones que fallarían si el resultado difiriese del contrato.

## Pruebas efectivamente registradas en los logs de #42922912695

| Suite | Resultado |
|---|---:|
| `W03_NET_NATIVE_V5` — campo real/tipos/cajas/SaveV2 | **PASS 79** |
| `W03_NET_NATIVE_V5_NEG` — RNG adversarial/SaveV2 | **PASS 19** |
| `W03_NET_NATIVE_V5_TRANSFORM` — switch/Transform | **PASS 15** |
| `W03_NET_V5_CONTEXT` — Quick/Timer/Level/Repeat/Net | **PASS 15** |
| **Total QA V5 nueva** | **128 PASS** |
| `FIELD_NATIVE` | PASS 118 |
| `W03_REPEAT_NATIVE_V3` | PASS 26 |
| `W03_REPEAT_NATIVE_V4`, V4 negativos y Transform | Todos PASS |
| `CAMP006_W03_REPEL_L3` | PASS 65 |
| `CAMP006_W03_PY` | PASS 54; `deferred=1` heredado |
| `CAMP006_W03_GODOT` | PASS 78 |
| `CAMP005_W03_PY` | PASS 169 |
| `CAMP005_W03_GODOT` | PASS 208 |
| SaveV2 normal, adversarial y pruebas de continuidad | PASS |

**Regla de CI:** el SHA `56155f82` es el último commit de código/test/workflow ejecutado. Los commits posteriores que sólo publican estos informes (`[skip ci]`) no se presentan como ejecutados por esa CI.

## Incidencia independiente detectada durante el test

La primera versión empleó Magikarp salvaje nivel 5. El mapa intentó iniciar el combate y la sesión nativa devolvió `move_policy`. Esto **no acredita un defecto de Net Ball**: el rechazo ocurre antes de lanzar ninguna bola. El movimiento específico del encuentro que infringe la política no está aislado todavía. La prueba de Agua pasó a Goldeen, especie admitida por la ruta nativa y con probabilidad real de éxito ×3,5.

**Recomendación a IA6:** abrir una investigación separada de `move_policy` para Magikarp nivel 5 en la generación de equipos/learnsets/permitidos. No ampliar los permisos de W03 para modificar `randomlock_content_policy` ni el backend general sin una causa probada. El primer workflow con YAML mal insertado y las primeras CI fallidas quedaron supersedidas por el SHA con SUCCESS.

## Archivos creados o modificados

- `tests/gameplay/parallel_items_w03_net_native_v5.gd`
- `tests/gameplay/parallel_items_w03_net_native_v5_negatives.gd`
- `tests/gameplay/parallel_items_w03_net_native_v5_transform.gd`
- `tests/gameplay/parallel_items_w03_net_v5_context_regression.gd`
- `.github/workflows/parallel-camp006-w03-autoci.yml`: incluye V5 sin retirar ningún gate previo.
- `docs/coordination/items_parallel_v1/reports/W03/AUTORUN_V5_PROGRESS.csv`
- `docs/coordination/items_parallel_v1/reports/W03/AUTORUN_V5_FINAL.md` (este documento).

No se modificaron `modules/capture/capture_ball_effects.gd`, `showdown_adventure_session.gd`, los serializadores compartidos, las estructuras de criaturas, el RNG global ni otras bolas.

## Relevo para IA6

1. Revisar CI #42922912695 y los cuatro runners V5.
2. Decidir integración selectiva de Net Ball y pruebas en la rama árbitra; **no se da por hecho ningún merge**.
3. Registrar la investigación independiente `move_policy` de Magikarp como posible limitación de contenido.
4. Publicar TANDA 06 en `IA6_AUTORUN.md` cuando proceda.

**TANDA 05 TERMINADA. Hitos 10/10; objetos nuevos 0; 1 Net Ball existente certificada L3 nativa; QA nueva 128 PASS; integración IA6 NO. STOP hasta nueva autorización.**
