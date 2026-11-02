# CAMPAÑA_002 — MANIFIESTO REAL DE RAMAS / ARRANQUE
**Fecha:** 2026-11-02. **Autorización del usuario:** sí, activación explícita. **Gate activo:** [CAMPAIGN_GATE_002.md](CAMPAIGN_GATE_002.md).
**Commit base común comprobado con GET /branches de GitHub:** `67959eb8f19abfd2ae391872747a14f603fcab01`.

| IA | Branch nueva confirmada | SHA inicial | Encargo |
|---|---|---|---|
| IA1/W01 | `codex/calvo-items-20261102-w01-camp002` | `67959eb8f19abfd2ae391872747a14f603fcab01` | `campaigns/CAMP_002_W01.md` |
| IA2/W02 | `codex/calvo-items-20261102-w02-camp002` | `67959eb8f19abfd2ae391872747a14f603fcab01` | `campaigns/CAMP_002_W02.md` |
| IA3/W03 | `codex/calvo-items-20261102-w03-camp002` | `67959eb8f19abfd2ae391872747a14f603fcab01` | `campaigns/CAMP_002_W03.md` |
| IA5/W05 | `codex/calvo-items-20261102-w05-camp002` | `67959eb8f19abfd2ae391872747a14f603fcab01` | `campaigns/CAMP_002_W05.md` |

**W04 no tiene rama nueva, se mantiene `codex/calvo-items-20261101-w04` congelada**, antiguo SHA `146dfd0c17334ef95295e1106b26b86375bddfe2`.

## Forma correcta de activación manual
Las conversaciones de CAMP_001 estaban detenidas; una `p` sola **antes de leer la nueva puerta** puede ser interpretada como cuarto bloque prohibido. Por eso se entrega un mensaje universal al usuario, para **enviar UNA SOLA VEZ a cada uno de los cuatro chats antiguos** (sin enviarlo a W04). Ese mensaje reasigna la rama y pide arrancar directamente ITER_01. Después, `p` ejecuta ITER_02 y luego ITER_03. Prohibidas iteraciones 04 y campañas siguientes automáticas.

El mensaje universal listo para copiar está en [CAMPAIGN_002_ACTIVATION_MESSAGE.md](CAMPAIGN_002_ACTIVATION_MESSAGE.md).
Los reportes CAMP_001 están en las ramas antiguas, **no se fusionan** con las ramas nuevas.

## Gates de CI
CI base (NO de nueva campaña): [#41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) y [#41364601486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601486), PASS sobre árbol `a8e09dbf`; solo cambios documentales hasta `67959eb8`. Las suites nuevas no se han generado ni ejecutado todavía. IA6 debe leer HEAD y diff antes de reunirlas en staging y certificar cada familia. No dejar que un PASS estático se presente como funcional.
