# W01 Fase B Bloque01/03 — Adrenaline Orb (piloto)

El `onAfterBoost` real del motor se comprueba mediante Intimidación de Gyarados. La fuente histórica `held_effect_sweep_v3.cjs` ya contenía casos nativos: no contar como nueva implementación sin mostrar un cambio productivo necesario.

Pruebas: cuatro modos `active`, `none`, `reserve`, `neutral`. Efecto positivo: Ataque -1 y Velocidad +1, consumo único de `adrenaline_orb`; controles: Intimidación sin objeto/no en activo, y rival sin Intimidación. NativeEngine real con Prepare/Commit/Restore; Godot recorre mochila real, FieldItemService, FieldNativeSession, settlement y SaveV2, sin persistir boost temporal.

No certificado con piloto: exige incorporar job B01 a CI acumulativa de Fase B junto con los 16 de TANDA04. Sin modificar producción, motor global ni otros workers.
