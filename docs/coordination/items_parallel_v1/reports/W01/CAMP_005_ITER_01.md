# IA1/W01 — CAMPAÑA_005 — Bloque 01/10

## Autoridad y alcance
- Gate IA6: `CAMPAIGN_005_W01_GATE.md`; cola: `CAMPAIGN_005_W01_QUEUE_APPROVED.csv`; protocolo `AUTONOMOUS_REPAIR_V5.md`.
- Rama única escribible: `codex/calvo-items-20261104-w01-camp005`.
- Bloque autorizado exclusivamente: `black_glasses;dragon_fang;hard_stone`.
- Baseline heredado: CAMPAÑA_004 finalizada 10/10, evidencia CI #41733777992 (Godot 16816; Python 1028; regresión CAMPAÑA_003 Godot 12392/Python 806); no recontar esas pruebas como nueva campaña.

## Mecánica contrastada y diseño de prueba
Los tres potenciadores están seleccionados en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`; su `native_entry=True` y `onBasePower` constan en `ITEM_INVENTORY.csv`. La prueba nativa preexistente `tools/item_audit/held_effect_sweep_v2.cjs` proporciona ataques coincidentes y no coincidentes para el modificador de tipo. No se añade lógica de daño, ya existente; se reutiliza el runner Godot de CAMP004 con sesión real de batalla, actualización del checkpoint y SaveV2.

| Objeto | Positivo de daño (dos semillas) | Negativo de tipo (una semilla) | Negativo de estado (una semilla) |
| --- | --- | --- | --- |
| Gafas de Sol (`black_glasses`) | `dark_pulse` (Siniestro) | `tackle` (Normal) | `reflect` |
| Colmillo Dragón (`dragon_fang`) | `dragon_pulse` (Dragón) | `tackle` (Normal) | `reflect` |
| Piedra Dura (`hard_stone`) | `smack_down` (Roca) | `tackle` (Normal) | `reflect` |

Cada escenario incluye **portador activo, sin objeto y objeto en reserva** a la misma semilla con motor `gen9calvounifiedv1`; se compara daño real positivo, ausencia de bonificación del tipo incorrecto, retención sin consumo, identidad de portador, cantidad de unidades y snapshot/proyección tras restauración SaveV2. Son **9 escenarios / 12 pares caso-semilla / 36 variantes**. No se realizan tests únicamente de existencia del descriptor.

## Estado CI y bloqueo encontrado
**ESTADO: DEPENDENCIA_DOCUMENTADA — NO HAY CI PARA CAMP005 W01.** La rama inicial de IA6 contiene solamente fixture bootstrap y CSV vacío para CAMPAÑA_005, sin runner ni workflow específicos. Se han creado fixture y runners W01, pero ninguna ejecución los ha comprobado aún. La rama heredó `.github/workflows/parallel-camp004-w01-autoci.yml`, cuyo filtro `on.push.branches` incluye únicamente `codex/calvo-items-20261103-w01-camp004`; su `workflow_dispatch` también ejecuta el contrato `campaign_004`, no CAMP005. Al inspeccionar la rama inicial, GitHub Actions no devolvió runs. El gate no aporta un workflow alternativo aplicable.

**No declarar `CAMP005_W01_PY PASS`, `CAMP005_W01_GODOT PASS`, efecto validado ni bloque 01 cerrado**. No puede certificarse por la CI anterior de CAMP004.

### Encargo concreto de integración a IA6
Configurar un workflow de CI para la nueva rama (sin reescribir la CI histórica) que:
1. Observe cambios en fixture/runner Python/runner Godot/progreso de CAMP005 y en módulos funcionales si se reparan. Exija manifiesto de 10 IDs/bloques de W01 y recibos nuevos `CAMP005_W01_PY PASS blocks=1 checks=N` y `CAMP005_W01_GODOT PASS blocks=1 checks=N`, ambos con N positivo en el mismo SHA.
2. Prepare Python 3.11, Node 22, Godot 4.7, recursos `restore_resources.py` y simulador Showdown anclado, como hacía la CI CAMP004; ejecute `python -B tests/tools/test_parallel_items_w01_campaign_005.py --ci` y `godot --headless --path . --script res://tests/gameplay/parallel_items_w01_campaign_005.gd`.
3. Ejecute la regresión íntegra de CAMPAÑA_004 Python y Godot en hito 01, 05, 10 y tras parche de producción. No sustituya pruebas de CAMPAÑA_005 por CI pasada de CAMPAÑA_004.
4. Publique logs para diagnóstico y concluya `completed/success` antes de cerrar el bloque.

Esto corresponde a la coordinación IA6 por la norma V5 de cambios de workflows. W01 no altera un workflow global, ni `main`, V28, PR #118 ni ramas ajenas. Tampoco modifica código de producción ni contratos viejos.

## Estado y continuidad
Bloque 01 **implementado en tests, pendiente de ejecución y validación**. Si se recibe `p` antes de restaurarse CI, comprobar primero la CI de bloque 01 y repararlo si falla; **no avanzar al 02 ni sumar objetos**. Tras CI real positiva, certificar el CSV con SHA/run y continuar con fila 02 `miracle_seed;mystic_water;never_melt_ice`.
