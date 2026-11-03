## Validación de CI — 2026-11-03

GitHub Actions [#41715717542](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715717542), SHA `a1bf8989427464f32762b49550bc08b06629a4b4`, terminó **success**. Recibos: `CAMP005_W03_PY PASS blocks=1 checks=28`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=1 checks=18`, `CAMP005_GATE_GODOT_PASS`. El primer intento [#41715500393](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715500393) falló por un falso positivo del auditor al encontrar `unknown_ball` en un comentario; criterio reparado en el SHA validado. El PASS certifica únicamente los contratos fuente disponibles y las dependencias descritas, **no** efectos funcionales nuevos para las tres bolas.

---

# IA3/W03 — CAMPAÑA_005 / BLOQUE 01 — Contrato de integración de captura

**Reservados, no nuevos:** `dive_ball`, `dusk_ball`, `repeat_ball`. Rama exclusiva: `codex/calvo-items-20261103-w03-camp005`.

## Diagnóstico verificable de producción

La ruta de consumo real es:

```text
ShowdownAdventureSession.capture()
  → reconstruye CaptureBattleContext desde batalla
      → CaptureInventoryService.resolve(CaptureAttempt)
          → CaptureSystem.validate_attempt()
          → CaptureSystem.resolve() y cálculo de modificadores
```

Actualmente `modules/gameplay/showdown_adventure_session.gd` produce `is_wild`, `target_side_id`, `completed_turns=battle_state().turn` y `catcher_level=battle_state().active_for_side("side_a").level`. `modules/capture/capture_battle_context.gd` no contiene datos de origen del encuentro, reloj/iluminación ni historial de especies capturadas. La presencia de `Dive/Dusk/Repeat Ball` en el catálogo no demuestra esas fuentes ni justifica registrar sus bonificaciones. Tampoco se debe derivar noche de número de turno, cueva de tipo de Pokémon ni registro de Pokédex de la composición del equipo.

## Fronteras pendientes por ID

| ID | Productor propietario necesario | Consumidor | Contrato propuesto / decisión concreta |
|---|---|---|---|
| `dive_ball` | Origen autoritativo del encuentro en exploración/mundo | `ShowdownAdventureSession.capture` → contexto → `CaptureSystem` | Proveer origen certificado: agua/surf/buceo/pesca según regla versionada. IA6 debe decidir qué condiciones exactas aplican a este juego; no basta inferirlo del tipo del objetivo |
| `dusk_ball` | Reloj del mundo y metadatos fiables de oscuridad/cueva del mapa | Misma cadena | Proveer reloj válido, condición de noche y condición de cueva/oscuridad. IA6 debe fijar umbrales de noche y fuentes de mapa; no utilizar reloj de sistema arbitrariamente ni reinterpretar turnos |
| `repeat_ball` | Registro persistente de Pokédex del jugador, con identidad canónica de especie base y versión | Misma cadena | Entregar conjunto de especies ya capturadas **antes** del intento, reconstruible de SaveV2, evitando obtenerlo únicamente de Pokémon presentes; IA6 debe definir autoridad, semántica de formas y persistencia |

Los nombres de campos del fixture son **propuesta de interfaz**, no campos que existan ni pruebas de que el productor esté implementado. Una nueva fuente debe garantizar autoridad en multijugador, ser inmune a manipulación de cliente y reconstruirse tras guardar/cargar. La validación de captura debe distinguir contexto ausente de un contexto válido cuyo efecto no se active, preservando inventario/RNG al rechazar. No hay autorización para editar sesión, mapa, Pokédex, inventario compartido ni SaveV2.

## Evidencia nueva de la remediación

- `tests/tools/test_parallel_items_w03_campaign_005.py`: inspecciona específicamente la función productora `capture()`, exige su puente de turno/nivel, comprueba ausencia de los seis campos de contrato y documenta productor/consumidor/decisión por ID. **No repite el test de `unknown_ball` de CAMPAÑA_004.**
- `tests/gameplay/parallel_items_w03_campaign_005.gd`: introspección dinámica de `CaptureBattleContext` para detectar campos realmente presentes y pruebas positivas de reglas ya conectadas Quick Ball (turno 0, ×5), Timer Ball (turno 0, ×1) y Level Ball (nivel 50 vs 25, ×4); esos ejemplos demuestran cómo se consume un contexto fiable, **no** una integración nueva de Dive/Dusk/Repeat.
- `tests/fixtures/parallel_items/w03_campaign_005.json`: captura de contratos concretos por objeto sin sumar objetos nuevos.

**Estado de los tres:** `DEPENDENCIA_CONCRETA`. **Producción funcional nueva:** ninguna; no existe productor confiable para las condiciones pedidas. El bloque aporta delimitación verificable y controles que obligarán a reauditar cuando cambien las fuentes. La CI debe validar Python/Godot en el SHA final del CSV; ninguna prueba verde convierte las tres bolas en funcionales.

## Siguiente intervención solicitada a IA6

Asignar propiedad del productor de origen de encuentros, reloj/metadatos de mapa y registro Pokédex/SaveV2; acordar DTO mínimo y reglas de tres bolas. Una vez se publique el contrato fiable, W03 podrá integrar multiplicadores/validación solo en `modules/capture/`, con pruebas positivas de captura, no-consumo de inválidos, RNG y regresiones. Mientras tanto, no inventar señales.

**Sin cambios** en `main`, V28, PR #118, ramas ajenas, módulos de producción ni reglas globales.
