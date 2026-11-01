# ESTADO ACTUAL — LOTE_002 INTEGRADO PROVISIONALMENTE / CI EN EJECUCIÓN
**Fecha:** 2026-11-01. **No se autoriza LOTE_003 ni producción todavía.**

## Resultado y pruebas

- **W01-W05** entregaron LOTE_002 y cinco cuadernos propios; sus diffs permitidos se auditaron contra el checkpoint `38188cc208e67b19002437ac75160898ce332ec2`.
- Reunión provisional en rama árbitra: **`30efddb618f0b3f397a3090568a070818c5cc36a`**, un merge con las cinco ramas como padres. 29 rutas propias transferidas (informes, cuadernos, fixtures y tests), **0 cambios a producción**.
- Puerta CI añadida en commit **`96037b8e383eb944050b0246957658e6fdb67f39`**: [GitHub Actions #41339009393](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41339009393), un job Ubuntu con Godot 4.7, Node fijado, contratos Python y cuatro pruebas de familias. **ESTADO AL PUBLICAR ESTA NOTA: en ejecución**; leer estado real del run, no atribuir PASS anticipado.
- Python y contratos estáticos iniciales pasan en el job; falta confirmar sus pruebas Godot e integración final. El W05 verifica el mapa 248/229/19, **no** 248 enseñanzas en combate.
- **W03** es caracterización: un PASS de los controles actuales NO significa que `net_ball` funcione; la falta de registro debe informarse como `BLOQUEADO_NET_BALL_NO_REGISTRADA`. `luxury_ball` y `dusk_ball` dependen de cambios de esquema/contexto no autorizados.
- V28 continúa como PR borrador #118, no tocar. `main` V27 intacta por esta coordinación.

## Para reducir contexto

Consultar [AUTONOMOUS_FAMILY_PROTOCOL_V1.md](./AUTONOMOUS_FAMILY_PROTOCOL_V1.md): cuaderno técnico por W, delegación **acotada** de varios microbloques, tests automáticos y revisión de IA6 **por excepción**. **PROTOCOLO AÚN NO ACTIVADO** hasta verificar y reparar la puerta de CI y publicar campañas individuales con rutas exclusivas y límites de IDs.

## Próxima decisión

1. Leer resultado y fallos reales de Actions #41339009393.
2. Si falla: identificar **una** familia/archivo y delegar corrección de test o reporte; sin producción/fixtures falseadas.
3. Si pasa: registrar SHA exacto y límites y preparar `CAMP_NNN_W01` a `CAMP_NNN_W05` con propiedad de archivos, entradas permitidas y microbloques; entonces el usuario podrá enviar a cada trabajadora un único mensaje de activación y después `sigue` dentro de su campaña.
4. Mantener conflictos `beast_ball`, 19 máquinas históricas, tipo/hora/amistad, arte libros y migraciones como **no decididos**.

**Regla permanente:** nunca declarar implementado, funcional, probado o integrado lo que solo está seleccionado o auditado.
