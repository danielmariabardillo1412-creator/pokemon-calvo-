# ESTADO DE COORDINACIÓN — ronda 001 preparada, NO iniciada por trabajadoras

**Fecha:** 2026-11-01. **Último paso confirmado:** auditoría de partida V27/V28 documentada; encargos `LOTE_001` creados en la rama árbitra. Los chats no han sido activados todavía por el usuario. No hay código nuevo de objetos en esta rama.

## Contabilidad

- **2.222 canónicos:** 743 PERMITIR + 1.375 DESCARTAR + 104 APARCADO_MEGA; 0 condicionales.
- **744 tipos de diseño:** 743 permitidos canónicos + 1 tipo universal Mega; 2 unidades máximas, 2 megaevoluciones por entrenador y combate; sin traspasos durante el combate. Mega NO se programa ahora.
- **743 IDs ordinarios por triar**, no 743 objetos necesariamente sin función.
- V27: 229 máquinas activas, 77 efectos de campo y 16 capturas; V28: 27 cierres ampliados de 61 equipables en su objetivo específico. Los contadores no se suman.

## Control de ramas

- Línea base común anterior: `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af`. Ramas W01–W05 sobre ella, SIN producción autorizada.
- Catálogo y V28 **divergentes**. V28 PR #118 sigue en borrador; main V27 no se toca.
- Ver `BASELINE_GATE_2026-11-01.md` antes de desarrollar cualquier componente.
- **Ente Ball**: contradicción catálogo/V28 abierta, sin nueva decisión de runtime.

## Encargos

| IA | Rama exclusiva | Lote | Alcance inicial | Estado |
|---|---|---|---|---|
| W01 | `codex/calvo-items-20261101-w01` | `LOTE_001_W01` | 3 equipables: assault_vest, loaded_dice, focus_sash | ASIGNADO / SIN ACTIVAR |
| W02 | `codex/calvo-items-20261101-w02` | `LOTE_001_W02` | 3 bayas: sitrus, lum, colbur | ASIGNADO / SIN ACTIVAR |
| W03 | `codex/calvo-items-20261101-w03` | `LOTE_001_W03` | 3 bolas: luxury, net, dusk | ASIGNADO / SIN ACTIVAR |
| W04 | `codex/calvo-items-20261101-w04` | `LOTE_001_W04` | 3 evolutivos: auspicious_armor, malicious_armor, black_augurite | ASIGNADO / SIN ACTIVAR |
| W05 | `codex/calvo-items-20261101-w05` | `LOTE_001_W05` | Auditoría íntegra 248 MACHINE | ASIGNADO / SIN ACTIVAR |

**Reservados para auditoría:** 260 IDs (3+3+3+3+248); libres 483 canónicos, más 1 Mega aparcada. No declarar 260 funciones verificadas o implementadas. La cola `QUEUE_V1.csv` contiene el lote por ID.

## Próximo paso ejecutable

Usuario: identificar W01 a W05 en cinco chats y pegar mensaje común de ejecución de `LOTE_001`. Trabajadoras: sólo informes. Árbitra: recibir las cinco entregas, decidir base integrada y verificarla antes de codear. No disparar 20 CI de forma innecesaria por cambios de cuadernos.
