# IA1/W01 — CAMPAÑA_001 · Microbloque 02 (defensa y daño condicional)

**Estado: PREPARADO_PENDIENTE_CI.** No hay PASS nativo nuevo para estos casos; no modificar producción.
**Asignación:** `campaigns/CAMP_001_W01.md`, blob `4faaae234c3021944d7f4724789c3b2c5d0652fd`; puerta ACTIVADA.
**Base sincronizada:** árbitra HEAD `a710d8abe2e94f11974488c4563b9eb80ede5bbc`, merge W01 `024c4bafe6ca18873030d89b270f3a04d3a1d5b4`. LOTE_001 y LOTE_002 preservados.

## Alcance exacto
- `eviolite` / Mineral Evolutivo: `onModifyDef|onModifySpD`. `pidgeotto` con daño físico (Tackle) y especial (Psychic), comparado con objeto/no objeto/reserva; `pidgeot` como evolución final sin mejora esperada. 4 escenarios, 6 semillas.
- `expert_belt` / Cinta Experto: `onModifyDamage`. Mew usando Water Gun ante Arcanine (supereficaz) o Mew (neutral): incremento solo en supereficaz, sin saturar PS. 2 escenarios, 3 semillas.
- `safety_goggles` / Gafas Protectoras: `onImmunity|onTryHit`. Mew ante Espora de Breloom, tormenta de arena y control sin polvo/clima; estado persistente y PS contrastados. 3 escenarios, 3 semillas.

## Cambios publicados, únicamente rutas propias
- `tests/fixtures/parallel_items/w01_campaign_001.json`: añade 9 casos de etapa `02`, conserva 8 de `01`; total 17 casos, 24 caso-semilla y 72 variantes de propiedad.
- `tests/gameplay/parallel_items_w01_campaign_001.gd`: reutiliza `Native`, `FieldItemService`, `_fixture` y `_restore_probe`; observa daño recibido/infligido y estado sueño, sin efectos inventados.
- `tests/tools/test_parallel_items_w01_campaign_001.py`: actualiza contrato inmutable de IDs, especies, semillas y operaciones; compara causalmente los tres modos y exige hashes del snapshot. Añade dos negativas del fixture (etapa y movimiento alterados).
- **Commits de código de test:** `79a26778f58a397e098526a2d96967f36d490b41` (fixture), `60673b1030aafb41c2702e63973e02ea4b96f197` (runner), `c16f7e93222274034b61dde686eddb16a92f737e` (validador).

## Evidencias y límites
- **PASS estático en este microbloque:** 13 verificaciones de coherencia (6 IDs permitidos, 17 casos únicos, 24 semillas combinadas, 72 variantes, ramas de aserciones, excepciones, campos de evidencia y stage). Fuente: lectura GitHub de los tres blobs actuales.
- **Python nuevo: SIN_EJECUTAR. Godot 4.7 nuevo: SIN_EJECUTAR. GPU/visual: SIN_EJECUTAR.** El PASS de [CI #41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320) corresponde al LOTE_002 antiguo, no a `CAMP_001`.
- Validación reproducible tras restaurar recursos y Node fijado: `python -B tests/tools/test_parallel_items_w01_campaign_001.py --contracts`; `python -B tests/tools/test_parallel_items_w01_campaign_001.py --self-test`; `godot --headless --path . --script res://tests/gameplay/parallel_items_w01_campaign_001.gd`; `python -B tests/tools/test_parallel_items_w01_campaign_001.py`.
- No valida asentamiento de victoria, cambios de objeto en turno, todos los climas, todos los tipos ni interacciones de habilidades. Si el Godot futuro falla por fixture/efecto, detener y elevar evidencia a IA6; no forzar PASS ni alterar `@pkmn/sim`.

**Siguiente autorización posible con otra `p`: microbloque 03, consolidación y revisión de hashes/semillas; no implementado ni certificado todavía.**
