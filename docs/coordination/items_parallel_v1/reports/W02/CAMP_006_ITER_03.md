# IA2/W02 — CAMPAÑA_006 · BLOQUE 03/10

**Rama única:** `codex/calvo-items-20261104-w02-camp006`. Autorización IA6: fila03 `lonely_mint; mild_mint; naive_mint`. Ninguna escritura en main, V28, otras ramas o producción.

| Menta | Naturaleza | Aumenta | Reduce | Estado |
| --- | --- | --- | --- | --- |
| `lonely_mint` | Lonely | Ataque | Defensa | Dependencia |
| `mild_mint` | Mild | Ataque Especial | Defensa | Dependencia |
| `naive_mint` | Naive | Velocidad | Defensa Especial | Dependencia |

**Conclusión funcional: no L2.** Las reglas nativas de naturaleza existen, pero no hay handler de menta en `FieldItemService`/`FieldItemEffects` ni campo de naturaleza efectiva independiente en `CreatureInstance`; `StatCalculator` usa `nature_id` original, persistido por SaveV2. La implementación positiva requiere decisión de IA6 sobre estado, API de estadísticas y combate, consumo transaccional, rollback y SaveV2.

**Una única dependencia compartida:** `MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02` del bloque02. El bloque03 añade **cero rechazos nativos redundantes** y reutiliza la prueba `gentle_mint_missing_effect_route` de bloque02 (PARTY con/sin stock y STORAGE con stock). El verificador Python exige mapeos y fuentes reales, política de inclusión, ausencia de ejecutor y cinco controles adversariales. Godot comprueba catálogo y tres modificadores nativos sin simular uso positivo. Marcador CI: `CAMP006_W02_DEPENDENCY BLOCKED block=03 ids=3`, nunca `PASS blocks=3`.

La recuperación [41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080) y CI del bloque02 [41778869360](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778869360) terminaron SUCCESS para sus propios SHA, incluidas regresiones CAMP004/003. **No se atribuyen esos recibos a la nueva fila03.** CAMPAÑA_005 mantiene 288 escenarios, 10 bloques.

**Siguiente `p`:** solo fila04 `naughty_mint; rash_mint; sassy_mint; serious_mint`, tras revisar el productor compartido. No ejecutar en este turno.
