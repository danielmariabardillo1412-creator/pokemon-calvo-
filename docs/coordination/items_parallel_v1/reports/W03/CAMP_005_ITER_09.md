## Verificación final de CI del bloque 09

[GitHub Actions #41738147298](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41738147298), SHA `0c66c18a1e97533ed6422c7aded283593648f5aa`, terminó **completed/success**. Recibos: `CAMP005_W03_PY PASS blocks=9 checks=153`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=9 checks=179`, `CAMP005_GATE_GODOT_PASS`. La validación confirma la huida salvaje de Cola Esponjosa existente y el rechazo seguro de campo, pero no implementa el retorno al mapa de Cuerda Huida.

---

# IA3/W03 — CAMPAÑA_005 / BLOQUE 09 — Cuerda Huida y Cola Esponjosa

**Reserva IA6:** `escape_rope;fluffy_tail`. Ambos pertenecen al backlog anterior: no se contabilizan como nuevos.

## Evidencia y estado funcional

**Cola Esponjosa:** `battle_escape_profile.json` declara `fluffy_tail` como consumible de una unidad, huida garantizada en combate salvaje y sin gasto de RNG. `ShowdownAdventureSession.use_item` lo envía a `_use_escape_item`, que exige batalla salvaje activa, revisión válida, objetivo propio activo y objeto en bolsa; prepara una copia del inventario, realiza `bag.remove` y llama a `_finish("FLED", bag)`. Solo después del resultado confirmado registra el gasto. Hay una integración de **huida salvaje existente**, distinta de la funcionalidad de campo.

**Cuerda Huida:** no figura en el perfil de huida de combate y `FieldItemService.use_item` no dispone de una ruta de teletransporte al mapa. `PlayerCollection.location_of()` responde PARTY/STORAGE, **no localización del jugador ni entrada de mazmorra**. Falta un productor de posición segura, identificador de mapa, última salida válida y guardado/restauración de destino. No deben inventarse coordenadas ni utilizarse la ubicación de la criatura como destino.

## Fronteras pendientes para IA6

- `escape_rope`: el propietario del mundo/mapa debe proporcionar un checkpoint de salida válido y validar si se permite la cuerda en la zona. El consumidor deberá publicar traslado e inventario atómicamente y confirmar el guardado; no consumir al rechazar, con mapa inaccesible o fallo de transición.
- `fluffy_tail`: conservar contrato de combate salvaje ya implementado. El uso en campo sigue rechazado sin gasto y no debe confundirse con un objeto para volver a la entrada del mapa.

## Nuevas pruebas

Godot `_block_09` comprueba definición canónica `fluffy_tail` garantizada/salvaje/no-RNG, política de selección de ambos objetos y rechazo de `FieldItemService.use_item` con instantánea completa de criatura, mochila y relojes sin mutación. Python valida la ruta `_use_escape_item → _finish("FLED", bag)` y registra el hueco de Cuerda Huida; no repite sin contexto las matrices negativas de CAMPAÑA_004.

**Clasificación:** `escape_rope=DEPENDENCIA_MUNDO_RETORNO`; `fluffy_tail=BATTLE_ESCAPE_EXISTING_FIELD_REJECTED`. Una CI aprobada no implica teletransporte del mapa ni nueva funcionalidad de combate; valida las rutas existentes y los límites de integración.

No se modifican producción, `main`, V28, PR #118 ni ramas ajenas. **CI:** verificar Python/Godot `blocks=9` y gates sobre el commit final del CSV antes de declarar bloque validado.
