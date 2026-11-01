"""Puerta estática por fases para la campaña W03 / net_ball (NO prueba Godot).

Desde la raíz del repo:
 python tests/tools/test_parallel_items_w03_net_campaign_001.py --phase baseline
 Tras implementar y sustituir negativos antiguos:
 python tests/tools/test_parallel_items_w03_net_campaign_001.py --phase implemented
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys


def requerir(estado: bool, mensaje: str, errores: list[str]) -> None:
    if not estado:
        errores.append(mensaje)


def examinar(raiz: Path, fase: str) -> list[str]:
    leer = lambda ruta: (raiz / ruta).read_text(encoding="utf-8-sig")
    especies = leer("modules/creatures/domain/creature_species.gd")
    sistema = leer("modules/capture/capture_system.gd")
    reglas = leer("modules/capture/capture_ruleset.gd")
    efectos = leer("modules/capture/capture_ball_effects.gd")
    inventario = leer("modules/inventory/capture_inventory_service.gd")
    save = leer("modules/save/save_game_repository.gd")
    prueba = leer("tests/gameplay/parallel_items_w03_capture_net_v1.gd")
    v11 = leer("tests/gameplay/item_capture_v11.gd")
    v15 = leer("tests/gameplay/item_capture_v15.gd")
    errores: list[str] = []
    exigir = lambda condicion, texto: requerir(condicion, texto, errores)

    exigir("func has_type(" in especies and "func type_ids_resolved(" in especies,
           "CreatureSpecies no expone tipos reales")
    exigir("get_by_id(target.base_species_id())" in sistema
           and "BallEffects.multiplier(" in sistema,
           "CaptureSystem no recupera especie y adaptador")
    exigir("for id: StringName in BallEffects.IDS" in reglas
           and "ids.append_array(BallEffects.IDS)" in reglas,
           "CaptureRuleset no registra adaptador de IDs")
    exigir(all(s in inventario for s in (
           "CaptureSystem.validate_attempt(", "inventory.remove(attempt.ball_id, 1)",
           "inventory.add(attempt.ball_id, 1)")),
           "Captura sin validación, consumo o rollback compartido")
    exigir("func save_collection(" in save and "func load(" in save,
           "Guardado/carga compartidos no disponibles")
    for caso in (
        '{"species": &"magikarp", "type": &"water", "factor": 3.5}',
        '{"species": &"caterpie", "type": &"bug", "factor": 3.5}',
        '{"species": &"pidgey", "type": &"normal", "factor": 1.0}',
        "CaptureResult.FAILED", "CaptureResult.INVALID",
        "CaptureResult.SUCCESS", "SaveGameRepository.new()",
        "CaptureOwnershipRouter.new()",
    ):
        exigir(caso in prueba, "Falta escenario de caracterización: " + caso)

    # Comprobar exactamente los bucles de negativos históricos, no cualquier
    # aparición textual del nombre net_ball (puede estar en asserts positivos).
    linea_v11 = next((x for x in v11.splitlines() if "for unsupported:" in x), "")
    linea_v15 = next((x for x in v15.splitlines() if "for unsupported:" in x), "")
    exigir(bool(linea_v11 and linea_v15), "Bucles de regresión históricos desaparecidos")
    net_en_ids = '&"net_ball"' in efectos.split("static func multiplier", 1)[0]
    if fase == "baseline":
        exigir(not net_en_ids, "Net ya aparece en IDS; usar --phase implemented")
        exigir('&"net_ball"' in linea_v11 and '&"net_ball"' in linea_v15,
               "Cambió expectativa histórica antes de activar Net")
    else:
        exigir(net_en_ids, "Net no se registró en BallEffects.IDS")
        exigir('has_type(&"water")' in efectos and 'has_type(&"bug")' in efectos
               and "3.5" in efectos,
               "Falta el factor 3.5 consultando los tipos reales de especie")
        exigir('&"net_ball"' not in linea_v11 and '&"net_ball"' not in linea_v15,
               "Negativo obsoleto en V11 o V15: sustituirlo antes del PASS")

    return errores


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", choices=("baseline", "implemented"), required=True)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    try:
        errores = examinar(args.root.resolve(), args.phase)
    except (OSError, UnicodeError) as error:
        print(f"STATIC_GATE_ERROR: {error}", file=sys.stderr)
        return 2
    if errores:
        for fallo in errores:
            print("STATIC_GATE_FAIL: " + fallo, file=sys.stderr)
        return 1
    print(f"STATIC_GATE_PASS phase={args.phase}; NO_ES_PASS_FUNCIONAL")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
