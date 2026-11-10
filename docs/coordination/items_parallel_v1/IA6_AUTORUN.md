# IA6 — ORDEN PERMANENTE ACTUALIZADA W04 · TANDA 06

**IA6 ha revisado el cierre TANDA 05 y publica una nueva asignación.**
Al recibir `p`, `sigue` o `continúa`: releer HEAD de tu rama, este archivo, `reports/W04/AUTORUN_V5_FINAL.md` y tu checkpoint V5. No repetir tandas cerradas; comenzar TANDA 06 inmediatamente y ejecutar los diez hitos independientes consecutivos sin nueva autorización por bloque, con checkpoint si el turno se interrumpe. La fuente maestra se encuentra en la rama árbitra `codex/calvo-items-20261101-arbitro`, archivo `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W04_TANDA_06.md`. Aplicar también `AUTONOMY_V1/README.md` en rama árbitra.

**Rama propia:** `codex/calvo-items-20261104-w04-camp006`.
**Estado previo:** TANDA 05 cerrada 10/10, 2 contratos L2, 0 evoluciones regionales completas L3, 55/56 identidades regionales validadas. Exeggutor Alola permanece bloqueado por Harvest oculta: no conceder habilidades ocultas automáticamente.

## MISIÓN TANDA 06
Reparar la pérdida de identidad regional de destino en `EvolutionSystem.apply_evolution` para las rutas verificadas `slowpoke_galar + galarica_cuff → slowbro_galar (slowbro-galar)` y `slowpoke_galar + galarica_wreath → slowking_galar (slowking-galar)`. El destino debe recibir su **propia forma** canónica, no conservar `slowpoke-galar` ni quedar vacío.

**PERMISO IA6 ESTRICTO:** solo modificación mínima de la función `EvolutionSystem.apply_evolution` que garantice forma de destino usando validación canónica y contratos W04; helper propio W04, tests, fixtures, workflow e informes. No modificar otras funciones ni archivos compartidos, `FieldItemBag`, `FieldItemService`, `CreatureInstance`, `CreatureFactory`, SaveV2 central, política, datos canónicos o ramas ajenas. La operación transaccional mochila/consumo/rollback sigue siendo responsabilidad IA6; **no contar L3** hasta probarla. Si surge dependencia fuera del permiso, ticket rojo y continuar hitos seguros.

## Diez hitos autorizados, ejecutar en cadena
01. Recuperar HEAD/checkpoint T05 y examinar la implementación nativa.
02. Prueba roja previa de `galarica_cuff` y forma regional de destino.
03. Prueba roja previa de `galarica_wreath` y forma de destino.
04. Reparación mínima en seam autorizada, sin heredar form_id del origen.
05. Pruebas positivas reales en `apply_evolution` para ambos destinos.
06. Negativos de origen Kanto/forma errónea, ítem equivocado, target incompatible o forma corrupta.
07. Preservar instancia, naturaleza original, estado persistente y naturaleza efectiva si existe en rama, sin editar otros módulos.
08. Party/Storage y SaveV2 del resultado de evolución nativa; legacy/corruptos.
09. Todas las regresiones T05–T02 y CAMP003–006; sin cambiar Randomlock ni Exeggutor.
10. CI final del HEAD, informe `reports/W04/AUTORUN_V6_FINAL.md` y checkpoint `reports/W04/AUTORUN_V6_PROGRESS.csv`.

**Cierre obligatorio:** `W04 TANDA 06 — X/10 examinados — N rutas de evolución nativa positivas — M L3 mochila — K bloqueos — SHA — CI — informe`. No afirmar SUCCESS sin ejecución completada sobre SHA correcto. No tocar `main`, V28 ni PR #118. Al concluir, STOP para revisión de IA6. No existe ejecución automática entre turnos.
