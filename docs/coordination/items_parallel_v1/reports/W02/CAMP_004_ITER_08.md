# IA2/W02 — CAMPAÑA_004 | MICROBLOQUE 08/10

**Autoridad:** `CAMPAIGN_004_W02_GATE.md`, fila `08` de `CAMPAIGN_004_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W02.md` y autonomía `AUTONOMOUS_REPAIR_V5.md`. **Rama exclusiva W02:** `codex/calvo-items-20261103-w02-camp004`. Se ejecutó sólo fila 08. Sin modificar producción, políticas globales, workflows, rama IA6 ni otras trabajadoras, `main`, V28 o PR #118.

## Alcance nuevo: 4 IDs / 20 escenarios × 3 modos = 60 variantes de prueba preparadas

| ID | Escenarios | Contrato real y rechazos |
| --- | ---: | --- |
| `max_elixir` | 5 | Rellena al máximo los PP de **todos** los movimientos (`pp:"full", scope:"all"`); dos vacíos, uno completo/otro vacío, 5/2 PP, dos completos = rechazo y ranura explícita = rechazo atómico |
| `max_ether` | 6 | Rellena al máximo los PP del **único movimiento seleccionado** (`scope:"one"`), sin tocar el otro; primero/segundo vacío, primero parcial, movimiento seleccionado completo aunque otro vacío = rechazo, ausencia de ranura o ranura 99 = rechazo |
| `max_potion` | 5 | Recupera PS al máximo (`heal:"full"`), sin curar veneno ni confusión; recuperación desde mitad o a 7 del máximo, PS completos = rechazo |
| `moomoo_milk` | 4 | Recupera **100 PS**, limitado a máximo; estado de veneno permanece, PS completos = rechazo |

**Fuente canónica `modules/inventory/imported_recovery_v19.json`:** `max_elixir: {pp:"full",scope:"all"}`, `max_ether: {pp:"full",scope:"one"}`, `max_potion: {heal:"full"}`, `moomoo_milk: {heal:100}`; `consume:true` en los cuatro. En `modules/inventory/field_item_effects.gd`, la ruta de PP suma `slot.max_pp` con tope `max_pp` si `pp` es un string y mantiene la discriminación `one`/`all`; los efectos de curación llaman `creature.recover_hp(amount)`. Precedentes de prueba histórica en `tests/gameplay/item_field_effects_v4.gd` incluyen `max_potion`, sin atribuir regresiones no comprobadas a Leche Mu-mu.

**Harness Godot actualizado:** `tests/gameplay/parallel_items_w02_campaign_004.gd` distingue `pp_full:true` de `pp_gain:10` de bloques previos, y `scope:one` de `scope:all`, con 2 movimientos y ranura seleccionada. Las aserciones de antes/después comprueban ambos PP exactos, límites, efecto en el seleccionado, rechazo atómico sin consumo, ubicación PARTY/STORAGE, estado/status/confusión sin cambios, amistad y EV intactos, `SaveV2` con reconstrucción exacta y recibos SHA256.

**Tres modalidades:** `active` (PARTY con 2 unidades), `none` (PARTY sin ítem), `reserve` (STORAGE con 2 unidades). Los casos son objetivos de prueba, no resultados ejecutados aún. Todas las pruebas de los bloques 01–07 se conservan y la CI de la rama incluye regresión CAMP003.

## Archivos y commits publicados

- `tests/fixtures/parallel_items/w02_campaign_004.json`: añade bloque 08 con 20 casos, `b00892f57e6e9807cf3f8139019b4d27e4296998`.
- `tests/gameplay/parallel_items_w02_campaign_004.gd`: verificación en Godot de recarga PP total/un movimiento y casos límite, `7eb2bd7f97f3e6a80413ab77a988708736c7cb85`.
- `tests/tools/test_parallel_items_w02_campaign_004.py`: matriz independiente de 20 contratos exactos, perfiles + 16 mutaciones adversariales, `55426d2b867f10674cc37eb7ed08ccf47095992f`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`: fila 08 pendiente de CI, `684657a846ef1478948f5e540bda2aa65eea6951`.
- Informe `CAMP_004_ITER_08.md`, `CONTINUIDAD.md` actualizado aparte.

## Validación y dependencias

**Total publicado CAMP004:** 8/10 bloques, 32 IDs, 143 escenarios y 429 variantes previstas. **Esto NO equivale a 32 objetos certificados.** El único run de CAMP004 consultado y corroborado sigue siendo [#41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223) para **bloque 01**: `CAMP004_W02_PY PASS blocks=1 checks=83`, `CAMP004_W02_GODOT PASS blocks=1 checks=1022`, regresión CAMP003 (Python 680, Godot 7306). **Bloques 02–08: aún sin CI verificable**, debido a que la consulta de runs por commit del conector sólo devuelve PR y los casos de W02 se disparan por push. No asumir que los runners han ejecutado o aprobado los commits. Falta revisión UI/GPU PC.

**Dependencias abiertas no ocultadas:** `razz_berry` fila 02 (sin efecto conectado en bolsa/held) y `hopo_berry` fila 06 (categoría PP recovery, pero sin efecto/cantidad de PP importada) tienen controles negativos, no funcionalidad positiva certificada; requiere decisión IA6.

## Próxima `p`

Revisar antes una CI del HEAD bloque08 con logs y SHA. Deben quedar `CAMP004_W02_PY PASS blocks=8 checks>0`, `CAMP004_W02_GODOT PASS blocks=8 checks>0`, regresiones `CAMP003_W02_PY/GODOT PASS blocks=10`. Si detecta errores de arnés/perfil propio, repararlos en W02 con V5; no rebajar pruebas ni tocar API compartida sin IA6. Avanzar exactamente a fila **09**: `old_gateau;paralyze_heal;pewter_crunchies;potion`. No ejecutar fila 10 sin otra tecla.
