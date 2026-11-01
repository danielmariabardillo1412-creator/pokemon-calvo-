# Mensaje común para IA1/IA2/IA3/IA4/IA5 — enviar SOLO después de activación oficial IA6

> No enviar mientras `CAMPAIGN_GATE_001.md` diga PREPARADA_SIN_ACTIVAR.

Continúa como tu IA/W asignada de Pokémon Calvo, sin cambiar de identidad.

La coordinadora IA6 ha publicado campañas limitadas en `codex/calvo-items-20261101-arbitro`. Lee `docs/coordination/items_parallel_v1/CAMPAIGN_GATE_001.md` y comprueba que diga **ACTIVADA**, con SHA y CI. Si no está activada, detente.

Después lee exclusivamente tu fichero `docs/coordination/items_parallel_v1/campaigns/CAMP_001_W0X.md` (reemplaza W0X por tu identidad), `AUTONOMOUS_FAMILY_PROTOCOL_V1.md`, `NOTEBOOK_PROTOCOL_V1.md` y tu `reports/W0X/CONTINUIDAD.md`.

Sincroniza tu propia rama con el checkpoint autorizado sin force, sin reescribir informes ni invadir ramas ajenas. Si no puedes, informa BLOQUEADO_BASE y detente.

A partir de ahora, cada vez que te envíe solo la letra **p**, equivale a **sigue**: ejecuta **un único microbloque pendiente** de tu campaña, publica commit, informe breve, progreso CSV y cuaderno de continuidad, y comunica estado y siguiente microbloque. No repitas un microbloque ya publicado. Puedes continuar al siguiente p sin intervención IA6 solo dentro de la campaña y permisos exactos.

Distingue pruebas realmente ejecutadas de escenarios diseñados y pruebas históricas. No declaras PASS sin ejecutar Godot/CI. Ante FAIL, cambio compartido fuera de permisos, problema de arquitectura o decisión de diseño pendiente, registra BLOQUEADO y detente. Al terminar los tres bloques, CAMPAÑA_001_FINALIZADA y espera una nueva asignación.

Nunca toques main, V28 original, árbitra, otras ramas o fuentes protegidas. No implementes nuevas mecánicas por duplicación ni elimines tests para fabricar PASS.
