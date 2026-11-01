"""W03 / LOTE_002: auditoría estática del contrato de captura, SIN simular Godot.

Ejecución desde la raíz: python tests/tools/test_parallel_items_w03_capture_v1.py
Opcional: --root RUTA. PASS = contrato estático; no demuestra capturas funcionales.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path
import unittest


class ContratoCapturaW03(unittest.TestCase):
    raiz: Path

    @classmethod
    def fuente(cls, ruta: str) -> str:
        return (cls.raiz / ruta).read_text(encoding="utf-8-sig")

    def test_tipos_reales_expuestos_por_catalogo(self) -> None:
        contenido = self.fuente("modules/creatures/domain/creature_species.gd")
        self.assertIn("func has_type(", contenido)
        self.assertIn("func type_ids_resolved(", contenido)
        self.assertIn("primary_type_id", contenido)
        self.assertIn("secondary_type_id", contenido)

    def test_captura_lee_especie_y_aplica_adaptadores(self) -> None:
        codigo = self.fuente("modules/capture/capture_system.gd")
        self.assertIn("get_by_id(target.base_species_id())", codigo)
        self.assertIn("BallEffects.multiplier(", codigo)
        self.assertIn("ContextBallEffects.multiplier(", codigo)
        self.assertIn("BallEffects.on_catch(", codigo)
        self.assertIn("func validate_attempt(", codigo)

    def test_contrato_inventario_no_duplicado(self) -> None:
        codigo = self.fuente("modules/inventory/capture_inventory_service.gd")
        self.assertIn("CaptureSystem.validate_attempt(", codigo)
        self.assertIn("inventory.has(attempt.ball_id, 1)", codigo)
        self.assertIn("inventory.remove(attempt.ball_id, 1)", codigo)
        self.assertIn("CaptureSystem.resolve(", codigo)
        self.assertIn("inventory.add(attempt.ball_id, 1)", codigo)

    def test_catalogo_elige_net_sin_certificar_efecto(self) -> None:
        ruta = self.raiz / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
        with ruta.open(newline="", encoding="utf-8-sig") as archivo:
            filas = {row["id"]: row for row in csv.DictReader(archivo)}
        self.assertIn("net_ball", filas)
        self.assertEqual(filas["net_ball"]["familia"], "CAPTURE_BALL")
        self.assertEqual(filas["net_ball"]["estado_contenido"], "SELECCIONADO")

    def test_escenarios_godot_y_control_rojo_sin_falsear_exito(self) -> None:
        prueba = self.fuente("tests/gameplay/parallel_items_w03_capture_net_v1.gd")
        for frase in (
            'magikarp', 'caterpie', 'pidgey', 'has_type(',
            'WildAdventureSession.new(', 'CaptureInventoryService.resolve(',
            'SaveGameRepository.new()', 'CaptureOwnershipRouter.new()',
            'CaptureResult.FAILED', 'CaptureResult.INVALID',
            'CaptureResult.SUCCESS', 'inventory.quantity(&"net_ball")',
            '--require-net', 'funcional_certificado": false',
        ):
            with self.subTest(escenario=frase):
                self.assertIn(frase, prueba)

    def test_estado_de_contexto_no_se_inventa(self) -> None:
        contexto = self.fuente("modules/capture/capture_battle_context.gd")
        self.assertIn("var is_wild:", contexto)
        self.assertIn("var completed_turns:", contexto)
        self.assertIn("var catcher_level:", contexto)
        # Diagnóstico, NO declaración de que sea imposible usar tipos:
        # la especie se consulta en CaptureSystem; el contexto no los expone.
        tipos_en_contexto = "var target_types:" in contexto
        self.assertFalse(tipos_en_contexto,
                         "El contexto cambió: actualizar la auditoría W03 antes de seguir")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path,
                        default=Path(__file__).resolve().parents[2],
                        help="raíz del checkout del proyecto")
    opciones = parser.parse_args()
    ContratoCapturaW03.raiz = opciones.root.resolve()
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ContratoCapturaW03)
    resultado = unittest.TextTestRunner(verbosity=2).run(suite)
    if resultado.wasSuccessful():
        ruleset = ContratoCapturaW03.fuente("modules/capture/capture_ruleset.gd")
        efectos = ContratoCapturaW03.fuente("modules/capture/capture_ball_effects.gd")
        conectado = '&"net_ball"' in ruleset or '&"net_ball"' in efectos
        estado = "REQUIERE_REVISAR_GODOT" if conectado else "NET_SIN_REGISTRO"
        print(f"STATIC_CONTRACT_PASS tests={resultado.testsRun} "
              f"net={estado}; NO_ES_PASS_FUNCIONAL")
    return 0 if resultado.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
