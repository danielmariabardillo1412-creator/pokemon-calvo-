# IA4/W04 — CAMPAÑA_006 / bloque 01 — manzanas L3 demo

**Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`. **IDs:** `sweet_apple;tart_apple;syrupy_apple`. **0 objetos nuevos.** Estado `ENTREGADO_PENDIENTE_CI`.

## Puerta de arranque / bloqueo externo confirmado

Se contrastaron `CAMPAIGN_006_W04_GATE.md`, `CAMPAIGN_006_W04_QUEUE_APPROVED.csv`, `campaigns/CAMP_006_W04.md` y `AUTONOMOUS_REPAIR_V5.md` en la rama árbitra. Rama W04 creada desde `f401651d25fc5780c757170a2d5c5d260f5d2d22`, cierre CAMPAÑA_005 y GitHub Actions [#41752332374](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41752332374) SUCCESS.

**Problema:** los tres documentos de CAMPAÑA_006 se encuentran en árbitra, no en la rama nueva, y no hay `.github/workflows/parallel-camp006-w04-autoci.yml` en W04 ni ejecuciones de `branch=codex/calvo-items-20261104-w04-camp006`. El workflow heredado `parallel-camp005-w04-autoci.yml` limita `on.push.branches` y comprueba `GITHUB_REF_NAME` de la rama antigua, por lo que **no valida CAMPAÑA_006**. La definición y activación CI pertenecen a IA6 según el Gate; no se editan workflows desde W04, no se inventan recibos.

## Integración ya encontrada (NO duplicarla)

Recorrido existente en producción de la demo:
`scenes/visual/field_demo.tscn` → `field_demo.gd::toggle_item_bag` → `field_item_bag.gd::_apply("use")` → `FieldItemService.use_item` → `evolution_options/evolve` → `PlayerCollection.replace_owned_same_identity` → `field_native_bridge.save_game/load_game` → SaveV2 y `field_publish_native_loaded_world`.

Este puente ya existe: no implementar otro motor ni contar las tres manzanas como nuevas. CAMPAÑA_005 ya había verificado tres evoluciones positivas de especie con guardado mediante `SaveGameRepository`; CAMPAÑA_006 exige **cobertura L3 desde escena y botones reales**, no repetir el test de servicio.

## Nueva prueba L3 publicada sin certificar

- Fixture `tests/fixtures/parallel_items/w04_campaign_006.json`: tres pares `Applin → Appletun/Flapple/Dipplin`, tres rutas de guardado aisladas y contrato explícito.
- Godot `tests/gameplay/parallel_items_w04_campaign_006.gd`: instancia la **escena visual real** y selecciona manzana y Pokémon en la mochila. Comprueba con `bag._apply("use")` rechazo por especie equivocada sin gasto, efecto positivo de evolución, texto de confirmación, exactamente un objeto consumido, mismo `instance_id`, conservación IV/EV/XP/nivel/amistad/movimientos, veto a repetir evolución. Cierra mochila, guarda con el puente nativo de la demo, modifica la mochila en memoria y recarga la partida con su puente para comprobar que la mutación posterior desapareció y que especie/inventario/identidad se restauran.
- Python `tests/tools/test_parallel_items_w04_campaign_006.py`: contrato estático de encadenamiento real, aislamiento de la nueva campaña y conservación de V27. **Aunque un test Python dé PASS, no acredita por sí solo la escena L3.**
- Progreso `reports/W04/CAMP_006_PROGRESO.csv`: únicamente fila 01 `ENTREGADO_PENDIENTE_CI`.

**No hay resultados de ejecución de estas pruebas:** sin CI CAMP006 y sin Godot disponible en el entorno actual, no puede afirmarse que el test Godot pase o que el recorrido sea funcional desde la escena. Debe ejecutarse en Actions del SHA que contenga fixture, tests y progreso. Si falla, W04 corrige tests y solo funciones de evolución que le correspondan.

## Próximo paso de IA6

Crear y activar en **esta rama** el workflow CAMPAÑA_006 que:
1. ejecute Godot 4.7, restauración de recursos e import y los tests `test_parallel_items_w04_campaign_006.py --ci` y `parallel_items_w04_campaign_006.gd`;
2. verifique `CAMP006_W04_PY PASS blocks=1 checks=N` y `CAMP006_W04_GODOT PASS blocks=1 checks=N` sobre el mismo SHA, con N>0;
3. ejecute regresión acumulativa CAMPAÑA_005 en el bloque 01;
4. deje recibo de éxito/fallo y marque el estado solo si se ha verificado la CI.

Si IA6 dispone de una infraestructura compartida que pueda ejecutar estos mismos comandos **sin editar el workflow desde W04**, es igualmente válida solo con logs reales asociados al SHA.

**No iniciada la fila 02.** Sin cambios en `main`, V28, PR118, ramas de IA6/otras trabajadoras, módulos comunes o política V27.

## Resolución IA6: CI desbloqueada y verificada

IA6 incorporó el workflow de CAMPAÑA_006 a esta rama. [Run #41767573680](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767573680), SHA `73db15112ac09b641e25a050bb59f344030edf28`, terminó **completed/success**. Los recibos examinados en el log son:
- `CAMP006_W04_PY PASS blocks=1 checks=52`
- `CAMP006_W04_GODOT PASS blocks=1 checks=91`
- `CAMP005_W04_PY PASS blocks=10 checks=673`
- `CAMP005_W04_GODOT PASS blocks=10 checks=1423`

Tres líneas `CAMP006_W04_APPLE` identifican `sweet_apple→appletun`, `tart_apple→flapple` y `syrupy_apple→dipplin`, todas `status=L3_SCENE_BAG_AND_NATIVE_SAVEV2`.

La incidencia del workflow que constaba al preparar el bloque quedó **resuelta por IA6**. Se actualizó `CAMP_006_PROGRESO.csv` a `CI_PASS_VERIFICADO`, y el validador Python admite ese estado sin alterar el contrato del bloque.

**Cierre funcional bloque 01/10: APROBADO.** No declarar todavía ejecución de bloque 02; requiere la siguiente tecla `p`. Si los commits puramente documentales generan una CI adicional, comprobarla independientemente.
