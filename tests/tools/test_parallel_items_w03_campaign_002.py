"""W03 / CAMPAÑA_002: puerta estática de procedencia, NO prueba de captura.

Uso: python tests/tools/test_parallel_items_w03_campaign_002.py
Opcional: --root /ruta/al/checkout
La ejecución debe FALLAR si aparece una fuente nueva o un contrato diferente:
eso exige reauditoría de IA6, no licencia automática para implementar bolas.
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
import re
import unittest


IDS = {"dusk_ball", "repeat_ball", "dive_ball"}
CAMP_FIXTURE = Path("tests/fixtures/parallel_items/w03_campaign_002.json")


def campos_gd(fuente: str) -> set[str]:
    """Variables declaradas del contexto real; ignorar comentarios y supuestos."""
    return set(re.findall(r"(?m)^\s*var\s+([A-Za-z_]\w*)\s*:", fuente))


def metodo_gd(fuente: str, nombre: str) -> str:
    patron = re.compile(r"(?m)^func\s+" + re.escape(nombre) + r"\(")
    match = patron.search(fuente)
    if match is None:
        return ""
    proximo = re.search(r"(?m)^func\s+", fuente[match.end():])
    return fuente[match.start():match.end() + proximo.start()] if proximo else fuente[match.start():]


def asignaciones_contexto(fuente: str) -> set[str]:
    return set(re.findall(r"\bcontext\.([A-Za-z_]\w*)\s*=", fuente))


def ids_adaptador(fuente: str) -> set[str]:
    bloque = fuente.split("static func", 1)[0]
    return set(re.findall(r'&"([a-z_]+)"', bloque))


class ContratoContextoW03(unittest.TestCase):
    raiz: Path
    matriz: dict

    @classmethod
    def setUpClass(cls) -> None:
        cls.matriz = json.loads((cls.raiz / CAMP_FIXTURE).read_text(encoding="utf-8"))

    @classmethod
    def leer(cls, ruta: str) -> str:
        return (cls.raiz / ruta).read_text(encoding="utf-8-sig")

    def test_01_matriz_exacta_sin_factor_inventado(self) -> None:
        m = self.matriz
        self.assertEqual(m["schema_version"], 1)
        self.assertEqual(m["campaign"], "CAMP_002_W03")
        self.assertEqual(m["phase"], "01_provenance")
        self.assertEqual(set(m["ids"]), IDS)
        self.assertEqual({x["id"] for x in m["records"]}, IDS)
        self.assertEqual(len(m["records"]), 3)
        self.assertIsNone(m["policy"]["multiplier_at_this_phase"])
        self.assertTrue(m["policy"]["selected_not_enabled"])
        self.assertTrue(m["policy"]["no_production_edits"])
        self.assertTrue(m["policy"]["no_fake_rng_or_clock"])
        self.assertEqual(m["result_interpretation"], "STATIC_CONTRACT_ONLY_NOT_FUNCTIONAL_PASS")
        for row in m["records"]:
            with self.subTest(id=row["id"]):
                self.assertEqual(row["status"], "DEPENDENCIA_DE_CONTEXTO")
                self.assertGreaterEqual(len(row["evidence"]), 3)
                self.assertGreaterEqual(len(row["false_positive_rejections"]), 3)
                self.assertGreaterEqual(len(row["forbidden_assumed_context_fields"]), 5)
                self.assertTrue(row["source_owner"])

    def test_02_tres_seleccionadas_no_son_tres_implementadas(self) -> None:
        path = self.raiz / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv"
        with path.open(encoding="utf-8-sig", newline="") as entrada:
            rows = {row["id"]: row for row in csv.DictReader(entrada)}
        for id_ in IDS:
            with self.subTest(id=id_):
                self.assertIn(id_, rows)
                self.assertEqual(rows[id_]["familia"], "CAPTURE_BALL")
                self.assertEqual(rows[id_]["estado_contenido"], "SELECCIONADO")

    def test_03_entrada_nativa_no_prueba_multiplicador(self) -> None:
        path = self.raiz / "docs/current/ITEM_INVENTORY.csv"
        with path.open(encoding="utf-8-sig", newline="") as entrada:
            rows = {row["id"]: row for row in csv.DictReader(entrada)}
        for id_ in IDS:
            with self.subTest(id=id_):
                self.assertIn(id_, rows)
                self.assertEqual(rows[id_]["family"], "CAPTURE_BALL")
                self.assertEqual(rows[id_]["connection"], "NATIVE_ENTRY_REQUIRES_EFFECT_CASE")
                self.assertEqual(rows[id_]["native_entry"], "True")

    def test_04_contexto_real_carece_de_disparadores(self) -> None:
        fuente = self.leer("modules/capture/capture_battle_context.gd")
        actual = campos_gd(fuente)
        esperado = set(self.matriz["required_context_schema"])
        self.assertEqual(actual, esperado, "Cambió CaptureBattleContext: IA6 debe reauditar")
        for row in self.matriz["records"]:
            with self.subTest(ball=row["id"]):
                self.assertFalse(actual.intersection(row["forbidden_assumed_context_fields"]))
        self.assertIn("var completed_turns:", fuente)
        self.assertIn("var catcher_level:", fuente)

    def test_05_constructores_proceden_de_sesiones_fiables(self) -> None:
        wild = metodo_gd(self.leer("modules/gameplay/wild_adventure_session.gd"), "capture_current")
        native = metodo_gd(self.leer("modules/gameplay/showdown_adventure_session.gd"), "capture")
        permitidas = set(self.matriz["required_context_schema"])
        for label, body in (("WildAdventureSession", wild), ("ShowdownAdventureSession", native)):
            with self.subTest(sesion=label):
                self.assertTrue(body, "No existe constructor de captura conocido")
                self.assertIn("CaptureBattleContext.new()", body)
                self.assertIn("CaptureInventoryService.resolve(", body)
                asignadas = asignaciones_contexto(body)
                self.assertTrue({"is_wild", "target_side_id", "completed_turns", "catcher_level"}.issubset(asignadas))
                self.assertTrue(asignadas.issubset(permitidas),
                                "Nueva señal de sesión: necesita reauditoría, no multiplicador asumido")
                for row in self.matriz["records"]:
                    self.assertFalse(asignadas.intersection(row["forbidden_assumed_context_fields"]))

    def test_06_ninguna_bola_registrada_en_adaptadores_actuales(self) -> None:
        basico = self.leer("modules/capture/capture_ball_effects.gd")
        contextual = self.leer("modules/capture/capture_context_ball_effects.gd")
        reglas = self.leer("modules/capture/capture_ruleset.gd")
        self.assertFalse(IDS.intersection(ids_adaptador(basico)))
        self.assertFalse(IDS.intersection(ids_adaptador(contextual)))
        self.assertIn('for id: StringName in BallEffects.IDS:', reglas)
        self.assertIn('for id: StringName in ContextBallEffects.IDS:', reglas)
        tabla = reglas.split("var BALLS :=", 1)[1].split("# --- Status", 1)[0]
        for id_ in IDS:
            self.assertNotIn(f'&"{id_}"', tabla)
        self.assertIn('&"net_ball"', basico, "Net CAMP_001 no debe perderse")

    def test_07_propiedad_actual_no_equivale_a_historial_de_captura(self) -> None:
        player = self.leer("modules/creatures/storage/player_collection.gd")
        campos = campos_gd(player)
        self.assertEqual(campos, {"party", "storage", "inventory"},
                         "PlayerCollection cambió: revisar contrato de Repeat")
        self.assertIn("func owned_creature(", player)
        save = self.leer("modules/save/save_game_data.gd")
        snapshot = metodo_gd(save, "to_dict")
        for campo in ('"creatures"', '"party"', '"storage"', '"inventory"'):
            self.assertIn(campo, snapshot)
        for supuesto in ('"caught_species"', '"pokedex"', '"caught_history"'):
            self.assertNotIn(supuesto, snapshot)
        self.assertIn("func save_collection(", self.leer("modules/save/save_game_repository.gd"))
        self.assertIn("current_owned_creature_not_prior_capture",
                      self.matriz["records"][1]["false_positive_rejections"])

    def test_08_zona_cueva_es_dato_de_mapa_no_contexto(self) -> None:
        field = self.leer("scenes/visual/field_demo.gd")
        self.assertIn('var cave := region == &"cave"', field)
        self.assertIn('"region": String(technical_region_id())', field)
        self.assertIn("world_cave_region_not_forwarded_to_capture",
                      self.matriz["records"][0]["false_positive_rejections"])
        self.assertIn("cave_not_underwater", self.matriz["records"][2]["false_positive_rejections"])

    def test_09_sistema_y_guardado_no_deben_ser_reescritos_por_test(self) -> None:
        system = self.leer("modules/capture/capture_system.gd")
        service = self.leer("modules/inventory/capture_inventory_service.gd")
        self.assertIn("CaptureSystem.validate_attempt(", service)
        self.assertIn("inventory.remove(attempt.ball_id, 1)", service)
        self.assertIn("get_by_id(target.base_species_id())", system)
        self.assertIn("ContextBallEffects.multiplier(", system)
        self.assertIn("BallEffects.multiplier(", system)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    ContratoContextoW03.raiz = args.root.resolve()
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ContratoContextoW03)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print(f"CAMP_002_W03_STATIC_CONTRACT_PASS tests={result.testsRun}; NO_FUNCIONAL_PASS")
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
