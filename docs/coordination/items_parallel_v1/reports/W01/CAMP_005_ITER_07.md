# IA1/W01 — CAMP_005 — ITER_07 (ejecución técnica, pendiente de CI)

**Rama exclusiva:** \`codex/calvo-items-20261104-w01-camp005\`  
**Bloque:** 07 / 10  
**IDs:** \`quick_powder\`, \`razor_claw\`, \`razor_fang\`  
**Situación de entrega:** EN_CI_AUTOMATICA; **NO** declarar \`CI_PASS_VERIFICADO\` hasta observar la CI sobre el SHA publicado.

## Evidencia previa preservada
Bloques 01–06: 54 escenarios y 134 pares; reparaciones nativas y SaveV2 del B06 intactos. CI anterior de metadatos \`42683458326\` completed/success, código nativo B06 \`2900431b3b50d3d47dbf7fabbb554915cd9c8319\`, CI funcional \`42679854792\` SUCCESS.

## Contrato funcional B07
- **Polvo Veloz:** Ditto sin transformar duplica Velocidad real y adelanta a Gyarados; control Mew no recibe bonus. Después de Transformación, la Velocidad nativa calculada ya no recibe el bonus. Prueba nativa JS B07 junto al runner Godot con SaveV2 transformado antes del cambio y posteriormente en reserva.
- **Garra Afilada:** Foco Energía + Placaje incrementa la etapa crítica hasta crítico observado; 16 semillas deterministas; control sin objeto y reserva y casos inmunidad de Gengar / Reflejo; requiere al menos un crítico exclusivo.
- **Colmillo Agudo:** Placaje contra Snorlax con 64 semillas nativas, sin manipular RNG; exige retroceso presente y ausente; Gengar inmune y Reflejo no lo activan; no potencia daño de Placaje.

Para los tres objetos: portador, propiedad, identidad, conservación sin consumo, batalla nativa y restauración SaveV2 en modos activo/ausente/reserva. 9 escenarios B07, 88 pares nuevos, 264 modalidades; acumulado previsto 63 escenarios, 222 pares, 666 modalidades. Los resultados no se consideran PASS hasta CI.

## Fronteras y dependencias
Sin ediciones a producción, \`native_engine.cjs\`, SaveV2 central, workflows o módulos compartidos. Regresión CAMP004 no se reduce: el workflow la conserva para hitos o cambios de producción (último PASS funcional del B06 con la regresión íntegra). Estado pendiente de certificado CI B07.

**Próximo paso:** observar \`run_id\`, \`head_sha\`, recibos Python/Godot y nativo. Si falla, reparar B07; si pasa, actualizar CSV + continuidad con SHA/run y certificar metadatos antes de autorizar 08.
