# IA6 — CERTIFICACIÓN V2 DEL ÁRBOL DE INTEGRACIÓN (2026-11-09)

**Rama exclusiva de integración**: `codex/calvo-ia6-integration-20261109`  
**SHA exactamente validado**: `251617a8bdff0b095f3f70273f3dc29fafcf74d0`  
**Run global**: [GitHub Actions #42700066031](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42700066031) `completed/success` · 1 job `verify` · 0 anotaciones `error`.

## Alcance positivo, corroborado mediante Godot 4.7 headless

| Productor | Integración seleccionada de trabajadores | Recibo en el mismo árbol y CI |
| --- | --- | --- |
| W01, bloque 06 | Reparación de `restore()` en `modules/battle/backends/showdown/native_engine.cjs`; solo ese bloque es diferente de la base, sin cambiar el resto del motor; test aislado heredado de W01 | `W01_B06_NATIVE_REPRO PASS cases=3 snapshots=3 switches=3`; `SHOWDOWN_TRANSACTIONS PASS 10` |
| W02, CAMP006 + piloto MINT-L3 01 | `CreatureInstance` con naturaleza efectiva, `FieldItemService` transaccional, helper extendido con `gentle_mint` y `lonely_mint/mild_mint/naive_mint` | `IA6_INTEGRATION PASS checks=65 features=mint_effective_nature,escape_rope_bag_savev2` |
| W03, Cuerda Huida | Piloto de mundo, transacción, ruta mochila y SaveV2 manual; no hay autoguardado | Mismo `IA6_INTEGRATION` 65 PASS, incluido retorno y una unidad consumida |
| W05, panel de libros | Panel W05 `field_machine_book_panel.gd` + montaje en `FieldItemBag`; **reutiliza el servicio de enseñanza, no hay segundo motor**; evento solo refresca interfaz y HUD | `W05_BOOK_UI_PILOT_20261109_GODOT PASS checks=88` y **`IA6_BOOK_BAG PASS checks=20 features=real_bag,w05_panel,one_teach,savev2`** |

## Regresiones en el árbol mixto

- `PROGRESSION_ITEMS_V18 PASS checks=8755 cases=4304 GPU=false`.
- `ITEM_CONNECTIONS PASS checks=4993 equip=624 evolutions=72 machines=229`.
- El generador de conexión produce una diferencia exclusiva en `holdable_source` (proveniencia), diagnosticada mediante `IA6_CONNECTION_PROVENANCE_DRIFT`; todos los campos funcionales se comparan y el original versionado se restaura byte por byte. No se modifica el catálogo.
- Las tres mentas nuevas también tenían CI positiva en la rama W02 [#42696681590](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42696681590): Python 35 y Godot 180.
- El panel W05 también contaba con [#42697722250](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42697722250) (Python 17/Godot 88, 49 MT y regresiones propias).

## Diferencia entre certificado y pendiente

1. **Certificado en la demo de prueba, no en `main`**: el recorrido desde mochila hasta enseñar un libro, gastar exactamente uno y persistir con SaveV2, limitado a los movimientos y criaturas de prueba. No se atribuye a los 229 libros la misma cobertura UI; `FieldItemService.teach` sí dispone de cobertura de enseñanza más amplia en W05.
2. **NO** se ha probado la apariencia/GPU con persona ni introducido arte final para los seis libros por tipo. No afirmar producción visual completa.
3. **W03 repelentes** permanecen en L2. No consumen desde bolsa ni filtran todos los encuentros reales con persistencia SaveV2 del estado activo. Bloque 04 diferido y 05 por productor pesca/surf/buceo.
4. **W04** resolver aislado con CI propia, pero sin productores autenticados de sexo, día y fase lunar, ni regla de intercambio por nivel: no declarar L3 de Piedra Oval/Alba/Bloque de Turba, ni 04/05 de CAMP006.
5. **`exp_share`** mantiene dependencia L1 de participación en combate, documentada en `IA6_EXP_SHARE_PARTICIPATION_CONTRACT_20261109.md`; no sumar XP doble.
6. **Regresiones específicas de campaña W01 y W02 completas:** comprobadas en sus ramas independientes, pero **no se han reproducido sus suites completas en el árbol mixto**. La batería anterior certifica solo sus contratos declarados. Se necesita gate consolidado antes de incorporación global.

## Regla de fusión y siguiente actuación

- `main`, V28, PR #118 y ramas W01–W05 **sin modificaciones por IA6**. Toda integración se ha hecho en la rama aislada.
- No lanzar `merge` de ramas enteras ni declarar aceptación global. Se precisan diff/gate de W01 CAMP005 completo sobre árbol combinado, regresión W02 y pruebas visuales antes del siguiente nivel de incorporación.
- El trabajo con mayor efecto multiplicador pendiente es un **productor real de encuentros/pasos/origen**, seguido por un **estado canónico de sexo/día/luna**; no repartir objetos dependientes como si fueran tareas independientes.
- IA6 sigue siendo la coordinadora activa. Cada trabajador conserva su rama y su contabilidad original. Las pruebas de integración **no añaden nuevos IDs** al catálogo.
