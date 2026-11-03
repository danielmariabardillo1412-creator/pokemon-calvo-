# W04 — CAMPAÑA_003 / ITER_05

**Estado:** EN_CI_AUTOMATICA. **No declarar PASS funcional hasta ejecutar CI sobre el nuevo SHA.**

## Objetos de la cola W04
- `prism_scale`
- `sachet`
- `up_grade`

## Entrega
- Fixture acumulativo actualizado previamente: `1c32247b4c04c4fd5b43ccd9caa2379106afbcab`.
- Runner Godot actualizado: `45115ab12a43080a0de266b4af116726b9b64b36`.
- Validador Python actualizado: `2fc195db544a26571ab562f603ec1dd2aeb8d55f`.
- Progreso 05/10 registrado: `057d4a6a9f86852d0597eb96859b13fa8c620107`.

El runner conserva bloques 01–04 y añade 05. Para cada ID inspecciona reglas reales del catálogo activo, trigger y `EvolutionSystem.classify_record`. Los positivos de `FieldItemService.evolve` solo se ejecutan si existe `TRIGGER_USE_ITEM` y clasificación `RUNTIME_SUPPORTED`; verifican rechazo, no gasto, consumo unitario, identidad y SaveV2. En rutas condicionadas de intercambio u objeto equipado el test exige rechazo de uso directo y snapshot e inventario intactos. La prueba Python comprueba la reserva, fixture, cobertura y contratos del motor; su recibo esperado tras una ejecución válida es `CAMP003_W04_PY PASS blocks=5 checks=M`.

## Reparación del bloqueo de escritura anterior
Una operación anterior de actualización completa del runner fue denegada por control de seguridad. Se recuperó el SHA actual y se reintentó con el endpoint oficial de actualización, limitado a cuatro reemplazos de texto en la rama W04. La operación fue aceptada sin cambiar permisos ni eludir controles. No se alteró código de producción, reglas de juego ni otras ramas.

**Validación efectiva del bloque 05:** sin ejecución Python/Godot confirmada en esta conversación; GitHub Actions debe cotejar los recibos con el último SHA que contiene runner, validador, fixture y progreso. No se puede extrapolar CI PASS anterior a esta entrega.

**Dependencias existentes:** Piedra Oval e intercambios condicionados permanecen documentados, sin afirmar jugabilidad ni reimplementar modalidades.

**Siguiente bloque por `p`:** 06/10 `auspicious_armor;malicious_armor;metal_alloy`, si no hay fallo real que requiera reparar.
