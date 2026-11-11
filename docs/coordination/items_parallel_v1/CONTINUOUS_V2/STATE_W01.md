# W01 CONTINUOUS_V2 · Estado activo — FASE B / Bloque 01

**Rama W01:** `codex/calvo-items-20261110-w01-gems-autobatch01`. **Protocolo:** `IA6_AUTORUN.md` y `CONTINUOUS_V2/PLAN_W01.md`. **NUNCA STOP por 10/10**.

## Fase A — cerrada
- **10/10 L3 certificados**, objetos de producción implementados nuevos: **0**.
- **SHA funcional certificado:** `83dacee5c924505f5234503a4fef126ea0bb0e01`; **CI final:** [#42939814729](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42939814729) `completed/success` **16/16 jobs**.
- Informe `reports/W01/AUTORUN_V4_FINAL.md`; CSV `reports/W01/AUTORUN_V4_PROGRESS.csv` (todas las filas CERTIFICADO).
- Integración en rama IA6 **NO**. El pase W01 no prueba UI visual completa ni integración multiworker.

## Fase B — bloque 01/03 activo
- **26 candidatos autorizados**, 10+10+6. **22 seleccionados con entrada nativa**, **4 DEPENDENCIA_FUERA_W01** debido a `DATA_ONLY` y ausencia en selección: `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`. No se implementan monedas, encuentros ni crianza.
- **CSV activo:** `reports/W01/CONTINUOUS_V2_PHASE_B_PROGRESS.csv`, 26 filas, **2/26 certificados B**, **6 pilotos L3 aprobados** (puerta global pendiente), **4/26 dependencias**, **16/26 pilotos por ejecutar**, **0 nuevos implementados B**.
- **next_id:** bloque B01 con 6 pilotos verdes (IDs 01,02,03,04,05,10) y 4 dependencias fuera W01 (06–09). La CI acumulativa intermedia #42946981841 terminó SUCCESS 18/18; nueva CI 22 jobs pendiente para cuatro pilotos adicionales. Al terminar, publicar gate final B01 con 22 jobs (los 18 + 4 pilotos verdes), sin cancelar la CI vigente. Después empezar B02 placas por tipo.
- **siguientes:** Fase B bloque 02 (10 placas) y bloque 03 (6 placas); no implementar formas de Arceus. Si mejora eficiencia, usar suite paramétrica de tipos con controles por placa y reporte individual por ID.
- **preflight:** `reports/W01/CONTINUOUS_V2_PHASE_B_PREFLIGHT.md`. `holdable_ids` no basta para declarar efecto disponible. `expert_belt` ya tenía piloto L2; `big_root` CAMP001: reusar evidencia y añadir únicamente cobertura faltante.

## Seguridad / reanudación
- **Rama exclusiva W01**; `main`, V28, PR118, W02–W05, SaveV2, FieldItemService, FieldItemBag, CreatureInstance, PlayerCollection y reglas Showdown globales protegidos.
- No atribuir compilación CI al commit documental posterior al SHA de pruebas; citar siempre `head_sha` de la ejecución.
- Próximo `p` empieza por releer este STATE+CSV y comprobar la CI publicada del primer piloto B si existe. Si no, construir el piloto L2/L3 del primer ID.
- No existe ejecución asíncrona garantizada. Integración IA6 sigue **PENDIENTE**.

## Fase B Bloque 01 — primeros dos pilotos aprobados (sin certificación acumulativa)
- `ability_shield`: [CI #42946138962](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42946138962) **completed/success**, código SHA `0d53565751c2550c37c595de99d5c02d044c6cfd`: Python 9, Node 4 modos, Godot 4 sesiones L3/81 checks. Prueba `gastro_acid` suprimida salvo portador protegido, evento `item_triggered` y SaveV2. Prueba nativa anterior identificada; **0 nueva implementación**.
- `absorb_bulb`: [CI #42946617984](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42946617984) **completed/success**, SHA `a496b6418656029b2a97754326887874807c0842`: Python 9, Node 4 modos, Godot 4 sesiones L3/82 checks. Impacto real Agua, +1 Ataque Especial, consumo, tipo equivocado/reserva/controles, SaveV2; **0 nueva implementación**.
- Este commit publica `.github/workflows/w01-continuous-b01-held.yml` con **18 jobs** (los 16 de Fase A sin alterar + los 2 pilotos), manteniendo intacto el workflow V4 congelado. No certificar B01/01–02 hasta `18/18 SUCCESS` de la nueva ejecución sobre SHA exacto.
- **Contabilidad:** A 10/10; B 0/26 certificados (2 pilotos verdes pendientes de gate, 4 `DEPENDENCIA_FUERA_W01`, 20 sin ejecutar); 0 objetos nuevos implementados, integración IA6 NO.

## Checkpoint B01 completo en pilotos individuales (no certificación global)
- [#42947269894](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42947269894) `adrenaline_orb` SUCCESS SHA `1ed2fb26e1e84d1d2446a327f9648352b8cae853`: 4 modos NativeEngine, L3 Godot 83 checks; Intimidación, +1 Velocidad, consumo, SaveV2.
- [#42947729756](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42947729756) `big_root` SUCCESS SHA `bb4997466d704c704d99f9b4aa13dffd51b865c6`: 4 modos, Godot 84 checks; más curación drenaje sin mayor daño, control no-drenante.
- [#42948015542](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42948015542) `expert_belt` SUCCESS SHA `1a23c683c89c5f7dcb060b35f68a27c3e5bb2fa5`: 5 modos, Godot 100 checks; solo daño supereficaz, piloto nativo histórico preexistente.
- [#42948306404](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42948306404) `draco_plate` SUCCESS SHA `b1c8810a551b1a4e29e9450c0e61f6c97f7fdbed`: 5 modos, Godot 100 checks, solo daño Dragón con Mew, sin cambio de forma ni manipulación W04.
- **Gate intermedia:** [#42946981841](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42946981841), SHA `d1ebc143df5c499a169ef299894bcb345c11e6b0`: 17/18 PASS al último chequeo (CAMP005 en ejecución). Incluye escudo y tubérculo; no certificar antes de 18/18 SUCCESS.
- **Siguiente:** al obtener 18/18, construir nueva CI B01 22 jobs reutilizando todo histórico y añadiendo los cuatro pilotos. Actualizar CSV con SHA/CI final solo tras ver SUCCESS en todos. Entonces B01 **6 CERTIFICADO y 4 DEPENDENCIA_FUERA_W01**; no 10 implementados.
- **Fase A permanece 10/10** por #42939814729 16/16 SUCCESS SHA `83dacee5c924505f5234503a4fef126ea0bb0e01`. No se tocó producción; IA6 integración NO.

## Nuevo checkpoint · Gate intermedia B01 completada
- [CI #42946981841](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42946981841) **completed/success 18/18** sobre SHA `d1ebc143df5c499a169ef299894bcb345c11e6b0`. Filas B01/01 `ability_shield` y B01/02 `absorb_bulb`: **CERTIFICADO**.
- Nueva CI de B01 con **22 jobs**: mantiene íntegros los 18 anteriores, añade pilotos ya verdes `adrenaline_orb` (#42947269894), `big_root` (#42947729756), `expert_belt` (#42948015542), `draco_plate` (#42948306404). **No certificar filas 03,04,05,10 hasta 22/22 SUCCESS sobre la SHA funcional de esta publicación**.
- Contabilidad actual: A 10/10; B **2/26 certificados**; B01 2 certificados, 4 piloto-verde-pendiente, 4 dependencias fuera W01; B02/03 dieciséis placas pendientes. **0 implementaciones nuevas de producción, IA6 integración NO**.
- **Próximo trabajo independiente mientras corre CI22:** B02 `dread_plate`, seguido de `earth_plate`, etc., preferiblemente suite paramétrica reusando test de `draco_plate`, con evidencia causal por tipo, controles y SaveV2. No tocar formas Arceus ni control W04.

## Checkpoint de ejecución autónoma · Fase B (11-11-2026)
- **CI B01 definitiva 22 jobs:** [#42954745915](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42954745915), SHA `1bfd86991cfbd01509b29a245f2e8ee7ada45e93`, **in_progress** al último chequeo. Incluye pilotos `ability_shield`, `absorb_bulb`, `adrenaline_orb`, `big_root`, `expert_belt`, `draco_plate`, más 16 regresiones completas. Los 6 jobs B01 de ítems ya están SUCCESS, pero **NO** certificar los últimos cuatro hasta 22/22 SUCCESS.
- **B02 fila 11 `dread_plate`:** piloto aislado [#42954858566](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42954858566), SHA funcional `41cf4d24f70f97a31e9b1c45159ab6e770261523`, **in_progress** en último chequeo. Cinco casos nativos Dark Pulse vs Tackle/no equipar/reserva, camino FieldItemService → campo → SaveV2. Prohibición de cambios Arceus/W04. No declarar PASS todavía.
- **Contabilidad verificable actual:** Fase A 10/10; Fase B **2/26** certificados (01–02), cuatro pilotos B01 verdes todavía sin gate completa, cuatro dependencias fuera W01; B02 fila 11 test publicado, no certificado. **0 objetos implementados nuevos**; **IA6 integración pendiente**.
- **Siguiente `p`:** comprobar #42954745915 y #42954858566. Si B01 22/22 SUCCESS, certificar filas 03/04/05/10 con SHA de CI y cerrar B01 6 certificados + 4 dependencias. Si Dread PASS, incorporar su test a CI acumulativa de B02, preferentemente en suite parametrizada de 16 placas, sin cancelar jobs pendientes. Si Dread falla, revisar Node/Godot y corregir solo test W01. Continuar al ID `earth_plate` sin orden adicional.

## Continuidad adicional — B02/11 y B02/12 (este turno)
- **Fila 11 `dread_plate`:** piloto nativo Dark Pulse/Siniestro y L3 Godot publicado en `41cf4d24f70f97a31e9b1c45159ab6e770261523`. CI #42954858566 FALLÓ únicamente en el preflight Python porque apuntaba a `continuous_b01_dread_plate` en vez de archivos `continuous_b02_dread_plate`; corregido en commit `b70b80c4731bbd8ab723b291f84b70a9c7a0e19d`. [CI reintento #42955088591](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955088591) **en ejecución** en última consulta. Hasta resultado real: NO PASADO/NO CERTIFICADO.
- **Fila 12 `earth_plate`:** piloto nativo `earth_power` y control `tackle`, reserva/no equipar y Godot L3/SaveV2 publicado SHA `6e01402af5811a74ad2f200d80ab7c1eb761ecbf`. [CI #42955023454](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955023454) **completed/success**, Python 9, Showdown 5 modos y Godot 5 rutas L3 / 100 comprobaciones; **todavía NO CERTIFICADO globalmente** hasta CI acumulativa B02.
- **Gate B01 22 jobs** [#42954745915](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42954745915) SHA `1bfd86991cfbd01509b29a245f2e8ee7ada45e93` en ejecución en último chequeo. No atribuir PASS global a las filas B01/03–05,10 hasta 22/22 success. Fase A 10/10; Fase B 2/26 certificados, 4 dependencias; nuevas implementaciones producción 0; IA6 integración NO.
- **Próximo `p`:** consultar CI22, Dread reintento y Earth piloto. Si CI22 SUCCESS, certificar en CSV B01 filas 03–05 y 10, cerrar B01 6/10 + 4 DEPENDENCIA_FUERA_W01. Si Dread/Earth PASS, integrar sus jobs a CI B02 acumulativa; si falla, reparar exclusivamente test W01 tras leer logs. Continuar B02 `fist_plate` etc. No tocar formas de Arceus ni W04.
