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
    return set(re.findall(r"(?m)^var\s+([A-Za-z_]\w*)\s*:", fuente))


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


    def test_10_referencia_essentials_fijada_sin_activacion(self) -> None:
        referencia = self.matriz["reference_profile"]
        self.assertEqual(referencia["commit"], "8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b")
        self.assertEqual(referencia["source_blob_sha"], "3deb95a4d4a38e51bf6950a4702f73e06a806c6f")
        self.assertEqual(referencia["settings_blob_sha"], "550a358751fba061adf3978460382de3dc3ab556")
        self.assertEqual(referencia["modern_generation_minimum"], 7)
        self.assertIn("MECHANICS_GENERATION >= 7", referencia["generation_switch"])
        expected = {
            "dusk_ball": ("battle.time == 2", 3.0, 3.5),
            "repeat_ball": ("battle.pbPlayer.owned?(battler.species)", 3.5, 3.0),
            "dive_ball": ("battle.environment == :Underwater", 3.5, 3.5),
        }
        for item in self.matriz["records"]:
            with self.subTest(id=item["id"]):
                rule = item["pinned_reference"]
                match, modern, old = expected[item["id"]]
                self.assertEqual(rule["trigger_code"], match)
                self.assertEqual(rule["multiplier_gen7_plus"], modern)
                self.assertEqual(rule["multiplier_before_gen7"], old)
                self.assertEqual(rule["nontrigger_multiplier"], 1.0)
                self.assertFalse(item["functional_implementation_authorized"])
                self.assertEqual(item["current_expected_status"], "unknown_ball")
        self.assertEqual(self.matriz["phase_02"]["status"], "NEGATIVE_CHARACTERIZATION_ONLY")

    def test_11_godot_rechazos_sin_factores_ni_contexto_inventado(self) -> None:
        ruta = "tests/gameplay/parallel_items_w03_campaign_002.gd"
        self.assertEqual(self.matriz["phase_02"]["godot_path"], ruta)
        codigo = self.leer(ruta)
        for marca in (
            'CaptureRuleset.new()', 'CaptureRuleset.ordered_ball_ids()',
            'CaptureSystem.validate_attempt(', 'CaptureInventoryService.resolve(',
            'unknown_ball', 'CaptureResult.INVALID', 'not resultado.result.consume_item',
            'mochila.to_dict() == antes_mochila', 'rng.state == antes_rng',
            'objetivo.to_dict() == antes_objetivo', 'equipo.is_empty()',
            'trainer_battle_not_capturable', 'battle_finished', 'target_knocked_out',
            'new_balls_functional": false', 'NEGATIVE_CURRENT_BEHAVIOR_ONLY',
        ):
            with self.subTest(marca=marca):
                self.assertIn(marca, codigo)
        for prohibido in (
            "contexto.is_night", "contexto.is_cave", "contexto.is_underwater",
            "contexto.already_caught", 'multiplier(&"dusk_ball"',
            'multiplier(&"repeat_ball"', 'multiplier(&"dive_ball"',
        ):
            self.assertNotIn(prohibido, codigo)



    def test_12_regresiones_historicas_net_v11_v15_conservadas(self) -> None:
        v11 = self.leer("tests/gameplay/item_capture_v11.gd")
        v15 = self.leer("tests/gameplay/item_capture_v15.gd")
        net = self.leer("tests/gameplay/parallel_items_w03_net_campaign_001.gd")
        effects = self.leer("modules/capture/capture_ball_effects.gd")
        negativos = (
            next((line for line in v11.splitlines()
                  if "for unsupported:" in line), ""),
            next((line for line in v15.splitlines()
                  if "for unsupported:" in line), ""),
        )
        for line in negativos:
            self.assertTrue(line, "Se perdió el bucle histórico de bolas no conectadas")
            self.assertNotIn('&"net_ball"', line, "Regresión Net pasó a no implementada")
            self.assertIn('&"luxury_ball"', line)
        self.assertIn('&"repeat_ball"', negativos[1],
                      "Acopio sigue pendiente: no quitar la expectativa negativa de V15")
        self.assertIn("Net registered through shared ball adapter", v11)
        self.assertIn("Net trainer rejection preserves ball and RNG", v11)
        self.assertIn("Net species-based probability", v15)
        self.assertIn("Net uses one ball and preserves ownership", v15)
        for required in (
            "func _probar_doble_tipo()", "func _probar_net_equipo_pc_guardado()",
            "func _probar_net_fallo_y_rechazos()", "func _probar_selector_y_descriptor()",
        ):
            self.assertIn(required, net)
        self.assertIn('&"net_ball"', ids_adaptador(effects))
        self.assertIn('species.has_type(&"water")', effects)
        self.assertIn('species.has_type(&"bug")', effects)
        self.assertIn('3.5 if species.has_type(', effects)

    def test_13_decisiones_por_bola_sin_permisos_nuevos(self) -> None:
        stage = self.matriz["phase_03"]
        self.assertEqual(stage["scope"],
                         "decision_per_ball_and_Net_V11_V15_regression_only")
        self.assertEqual(stage["permission"], "NO_PRODUCTION_CHANGES_NO_NEW_CAPTURE_CONTEXT")
        expected = {
            "dusk_ball": "night_or_cave_authoritative",
            "repeat_ball": "species_previously_caught_authoritative",
            "dive_ball": "encounter_is_underwater_authoritative",
        }
        self.assertEqual(set(expected), {r["id"] for r in self.matriz["records"]})
        for row in self.matriz["records"]:
            with self.subTest(id=row["id"]):
                decision = row["decision_03"]
                self.assertEqual(decision["state"], "DEPENDENCIA_DE_CONTEXTO")
                self.assertFalse(decision["implementation_authorized"])
                self.assertEqual(decision["allowed_work"], "tests contracts reports only")
                self.assertEqual(decision["required_signal"], expected[row["id"]])
                self.assertGreaterEqual(len(decision["test_cases"]), 5)
                for field in ("owner", "source_proof", "missing_in_current",
                              "persistence_contract", "request_to_ia6"):
                    self.assertTrue(decision[field])
        if any(r["decision_03"]["implementation_authorized"]
               for r in self.matriz["records"]):
            self.fail("El fixture intenta autorizar implementación sin gate IA6")

    def test_14_regresion_net_viva_sin_volver_a_ejecutar_v11_v15(self) -> None:
        script = self.leer("tests/gameplay/parallel_items_w03_campaign_002.gd")
        for token in (
            "_test_regresiones_net_v11_v15(reglas, fixture)",
            "func _test_regresiones_net_v11_v15(",
            "CAMP_002_W03_BALL_EFFECTS.multiplier(",
            "reglas.catch_probability(",
            'CaptureAttempt.new(objetivo, &"net_ball"',
            "CaptureInventoryService.resolve(",
            "CaptureResult.INVALID",
            "mochila.quantity(&\"net_ball\") == 1",
            "FileAccess.get_file_as_string(\"res://tests/gameplay/item_capture_v11.gd\")",
            "FileAccess.get_file_as_string(\"res://tests/gameplay/item_capture_v15.gd\")",
            "NEGATIVE_CURRENT_BEHAVIOR_ONLY",
            '"new_balls_functional": false',
        ):
            with self.subTest(token=token):
                self.assertIn(token, script)
        for token in ("contexto.is_night", "contexto.is_underwater",
                      "contexto.already_caught", 'multiplier(&"dusk_ball"',
                      'multiplier(&"repeat_ball"', 'multiplier(&"dive_ball"'):
            self.assertNotIn(token, script)
        expected = self.matriz["phase_03"]["regression_cases"]
        self.assertEqual({row["species_id"] for row in expected},
                         {"magikarp", "caterpie", "pidgey", "surskit"})
        self.assertEqual({row["species_id"]: row["expected_factor"] for row in expected},
                         {"magikarp": 3.5, "caterpie": 3.5, "pidgey": 1.0,
                          "surskit": 3.5})


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
