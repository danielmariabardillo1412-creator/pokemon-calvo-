# IA6 → W03/IA3 · AUTORUN TANDA 02: HISTORIAL AUTÉNTICO DE CAPTURAS / REPEAT BALL
**Rama:** `codex/calvo-items-20261104-w03-camp006` · **Fecha:** 2026-11-10.

**Auditoría de TANDA01:** 10/10 filas inspeccionadas; **0 nuevos objetos funcionales**, CI [#42729137809](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729137809) SUCCESS en SHA funcional `0114c3331d3d641569a0e967c111bb9836a6a572`; HEAD posterior `d009f948e8f4390f2e00a69fa5d3cb48a21dec45` solo documental. Los bloqueos reales están en `reports/W03/AUTORUN_V1_PRODUCER_BLOCKERS.md`. **No repetir la auditoría B04–B10.**

**Protocolo vinculante:** `AUTONOMY_V1/README.md`. Una sola `p` autoriza iniciar y avanzar las diez filas de esta tanda dentro de los turnos que sean necesarios, con checkpoints; no pedir permiso nuevo por cada fila. CI y reporte de cierre por diez filas. No trabajo en segundo plano garantizado. Únicamente rama propia. Prohibido editar `main`, V28, PR118, otras ramas. Un bloqueo se documenta y se pasa a la siguiente prueba independiente; no acreditar L3 falso.

## Decisión IA6 — productor prioritario
De los bloqueos, **Repeat Ball** tiene una ruta implementable: registrar **solo capturas realmente exitosas**, conservar una lista versionada de **especies base** ya capturadas y utilizarla en el siguiente intento. No inferir historial exclusivamente de la Party actual (la especie podría haberse liberado), no contar avistamientos/fallos/regalos como capturas, no inventar flags de pesca o reloj. El historial debe pertenecer al jugador y persistir en SaveV2, sin cambiar `schema_version=2`, checksums ni RNG general. El bonus exacto de Repeat Ball debe proceder de las reglas canónicas/referencia fijadas en el repo, no de una suposición.

## 10 filas de desarrollo preautorizadas (un solo productor, no diez objetos)
| Fila | Entrega exigida |
|---|---|
| 01 | Verificar fuentes `WildAdventureSession.capture_current`, `CaptureOwnershipRouter.route`, `PlayerCollection`, `SaveGameData.build`, `SaveGameRepository.save_collection/decode_snapshot` y ruta field-native; definir contrato `caught_base_species_ids` sin identificaciones artificiales |
| 02 | Añadir helper local `modules/capture/caught_species_history_w03.gd` con canonicalización exacta de `source_metadata.base_species_id`, deduplicación, validación estricta y lista estable |
| 03 | Añadir propiedad opcional al agregado `PlayerCollection` para historial, sin reconstruirlo de Party/storage; legacy inactivo/vacío |
| 04 | Registrar ID únicamente **después** de captura SUCCESS y enrutamiento aceptado, con rollback en fallo; asegurar que batalla perdida, captura fallida, storage full/rollback no modifica historial |
| 05 | Persistir/restaurar historial en colección SaveV2 con campo opcional compatible (no cambiar versión, hashes ni serializador) y rechazar payload corrupto antes de publicar estado |
| 06 | Preservar historial a través de carga nativa de campo y carga normal de aventura, sin reconstruir otra `PlayerCollection` que lo pierda; sin autosave |
| 07 | Producir bandera `previously_caught_base_species` **desde el ledger real y antes de usar la Ball**, dentro de `CaptureBattleContext` de sesión propia; nunca parámetro del usuario/UI |
| 08 | Implementar regla `repeat_ball` en adaptador de captura y `CaptureContextBallEffects` bajo perfil canónico, sin alterar otras 16 Balls, distribución de RNG ni consumo en rechazo |
| 09 | Prueba L3: primera captura real → ledger nuevo → SaveV2 → recarga → segunda captura misma especie con bonificación; negativos de especie distinta, corrupción/legacy, captura fallida, no doble captura ni gasto |
| 10 | CI acumulativa HEAD, pruebas nuevas Python/Godot + todas CAMP006 01–03 repelentes/Cuerda, CAMP005, native save. Informe `reports/W03/AUTORUN_V2_FINAL.md` con estados L1/L2/L3 y SHA/run |

## Autorización excepcional de IA6 en archivos protegidos — **solo estas funciones, solo en rama W03**
- `modules/creatures/storage/player_collection.gd`: propiedad de historial y helper propio, **no** alterar deposit/withdraw/identidad.
- `modules/save/save_game_data.gd`: campo opcional `caught_base_species_ids` y `build`/`to_dict`/`from_dict`/`validate` **solo para ledger**, sin alterar formato y sin suprimir validaciones.
- `modules/save/save_game_repository.gd`: rutas `save_collection` y `decode_snapshot`/reconstrucción **solo ledger**; `modules/save/load_result.gd`: campo de resultado opcional si hace falta.
- `modules/save/field_native_save.gd::decode`: copiar ledger del resultado al `PlayerCollection` real **exclusivamente**; no alterar `_valid_creature` (IA6 ya tiene parche de naturaleza efectiva ahí).
- `modules/gameplay/wild_adventure_session.gd::capture_current`, `save_game`, `load_game` y reconstrucción de `player`: únicamente historial de capturas.
- `modules/capture/capture_battle_context.gd` y `modules/capture/capture_context_ball_effects.gd`: bandera/validación y efecto de Repeat Ball; `capture_system.gd` solo un dispatch **muy localizado** si la API existente no puede invocar el nuevo efecto.
- Nuevos helpers/tests/fixtures y workflows W03, sin rebajar ninguna regresión previa.

**No autorizados:** nuevos formatos globales, cambios a `SaveGameSerializer`, `SaveGameMigration` (si fuera imprescindible, ticket de IA6 y continuar otros tests), motores Showdown, `FieldItemBag`, mapas, `CreatureInstance`, reglas generales de captura/combate ni código W04/W05. **Hay trabajo IA6 paralelo en `field_native_save.gd`; no copiarlo desde otras ramas ni pisarlo.** IA6 hará integración selectiva por función, nunca merge ciego. Cuando un seam resulte imposible sin tocar algo no listado: prueba roja, ticket y `BLOQUEADO`, no pedir permiso para repetir las mismas filas.

**Semántica positiva:** Repeat Ball se marca funcional L3 únicamente con ruta de captura real + historial persistente antes del intento + bonificación verificable + guardado/carga y CI íntegra. No acreditar otros objetos bloqueados de TANDA01. Un `p` basta para iniciar esta tanda de diez hitos; al terminar, STOP y aviso IA6.
